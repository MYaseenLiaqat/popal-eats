"""
Foodpanda → Popal Eats PostgreSQL import service.

Maps Foodpanda API JSON onto existing Restaurant, Category, and Dish models.
Idempotent: match restaurants by (source, external_code) / (source, external_id),
with legacy description and name fallbacks; dishes by (restaurant_id, source, external_id)
with name fallback.
"""

from __future__ import annotations

import ast
import logging
import os
import re
from dataclasses import asdict, dataclass, field
from decimal import Decimal, InvalidOperation
from typing import Any

from sqlalchemy import func
from sqlalchemy.orm import Session

from app.core.roles import ADMIN, RESTAURANT_OWNER
from app.integrations.foodpanda.foodpanda_client import FoodpandaAPIError, FoodpandaClient
from app.models.category import Category
from app.models.dish import Dish
from app.models.restaurant import Restaurant
from app.models.user import User

logger = logging.getLogger(__name__)

FOODPANDA_SOURCE = "foodpanda"
VENDOR_CODE_PREFIX = "Foodpanda vendor_code:"


@dataclass
class FoodpandaImportStats:
    restaurants_created: int = 0
    restaurants_updated: int = 0
    categories_created: int = 0
    dishes_created: int = 0
    dishes_updated: int = 0
    errors: list[str] = field(default_factory=list)

    def to_dict(self) -> dict[str, Any]:
        return asdict(self)

    def add_error(self, message: str) -> None:
        self.errors.append(message)
        logger.error("Foodpanda import: %s", message)


# ---------------------------------------------------------------------------
# Parsing helpers (aligned with scripts/foodpanda_scraper)
# ---------------------------------------------------------------------------


def normalize_name(value: str | None) -> str:
    if not value:
        return ""
    return re.sub(r"\s+", " ", str(value).strip()).lower()


def extract_vendor_code(description: str | None) -> str | None:
    if not description:
        return None
    for line in description.splitlines():
        line = line.strip()
        if line.startswith(VENDOR_CODE_PREFIX):
            return line[len(VENDOR_CODE_PREFIX) :].strip()
    return None


def build_restaurant_description(
    *,
    vendor_code: str,
    vendor_id: str,
    cuisines: str | None = None,
    url_key: str | None = None,
) -> str:
    """Human-readable metadata only; deduplication uses structured source fields."""
    lines = ["Imported from Foodpanda."]
    if url_key:
        lines.append(f"Foodpanda url_key: {url_key}")
    if cuisines and str(cuisines).strip() and str(cuisines).lower() != "nan":
        lines.append(f"Cuisines: {cuisines}")
    return "\n".join(lines)


def cuisines_to_tags(cuisines: str | None) -> list[str] | None:
    if not cuisines or str(cuisines).strip().lower() == "nan":
        return None
    tags = [part.strip().lower() for part in str(cuisines).split(",") if part.strip()]
    return tags or None


def parse_city(value: object) -> str | None:
    if value is None:
        return None
    text = str(value).strip()
    if not text or text.lower() == "nan":
        return None
    if text.startswith("{") and "name" in text:
        try:
            parsed = ast.literal_eval(text)
            if isinstance(parsed, dict) and parsed.get("name"):
                return str(parsed["name"])[:100]
        except (SyntaxError, ValueError):
            pass
    return text[:100]


def _first(*values: Any) -> Any:
    for value in values:
        if value is not None:
            return value
    return None


def _as_list_join(value: Any, sep: str = ", ") -> str | None:
    if value is None:
        return None
    if isinstance(value, str):
        return value
    if isinstance(value, list):
        parts: list[str] = []
        for item in value:
            if isinstance(item, dict):
                parts.append(
                    str(_first(item.get("name"), item.get("title"), item.get("locale")) or item)
                )
            else:
                parts.append(str(item))
        return sep.join(parts) if parts else None
    return str(value)


def extract_vendor_list(payload: dict[str, Any]) -> list[dict[str, Any]]:
    data = payload.get("data", payload)
    if isinstance(data, dict):
        for key in ("data", "items", "vendors", "restaurants"):
            inner = data.get(key)
            if isinstance(inner, list):
                return [v for v in inner if isinstance(v, dict)]
        if data.get("id") or data.get("vendor_id") or data.get("code"):
            return [data]
    if isinstance(data, list):
        return [v for v in data if isinstance(v, dict)]
    if isinstance(payload.get("items"), list):
        return [v for v in payload["items"] if isinstance(v, dict)]
    return []


def parse_vendor(vendor: dict[str, Any]) -> dict[str, Any]:
    address = vendor.get("address") or vendor.get("address_line") or {}
    if isinstance(address, dict):
        address_text = _first(
            address.get("address_line_1"),
            address.get("formatted_address"),
            address.get("street"),
        )
        city = _first(address.get("city"), vendor.get("city"))
    else:
        address_text = str(address) if address else None
        city = vendor.get("city")

    rating_block = vendor.get("rating") or {}
    if isinstance(rating_block, dict):
        rating = _first(rating_block.get("value"), rating_block.get("average"))
        review_count = _first(
            rating_block.get("count"),
            rating_block.get("review_count"),
            vendor.get("review_count"),
        )
    else:
        rating = rating_block or vendor.get("average_rating")
        review_count = vendor.get("review_count")

    cuisines = _as_list_join(
        _first(
            vendor.get("cuisines"),
            vendor.get("cuisine_types"),
            vendor.get("tags"),
            vendor.get("characteristics"),
        )
    )

    is_open = _first(vendor.get("is_open"), vendor.get("open"), vendor.get("is_active"))
    if isinstance(is_open, bool):
        is_open_val: bool | None = is_open
    else:
        status = str(vendor.get("status", "")).lower()
        is_open_val = status in {"open", "active", "online"} if status else None

    return {
        "vendor_id": str(_first(vendor.get("id"), vendor.get("vendor_id")) or ""),
        "vendor_code": str(_first(vendor.get("code"), vendor.get("vendor_code")) or "").strip(),
        "vendor_name": str(
            _first(vendor.get("name"), vendor.get("vendor_name"), vendor.get("title")) or ""
        ).strip(),
        "url_key": str(_first(vendor.get("url_key"), vendor.get("slug"), vendor.get("key")) or ""),
        "rating": rating,
        "review_count": review_count,
        "cuisines": cuisines,
        "address": address_text,
        "city": city,
        "is_open": is_open_val,
    }


def parse_vendor_from_menu_payload(
    menu_payload: dict[str, Any],
    *,
    vendor_code: str,
) -> dict[str, Any]:
    """Build vendor dict from api/v5 menu ``data`` when listing search is unavailable."""
    data = menu_payload.get("data")
    if not isinstance(data, dict):
        return parse_vendor({"code": vendor_code, "name": vendor_code})
    merged = dict(data)
    merged.setdefault("code", vendor_code)
    return parse_vendor(merged)


def _first_variation(product: dict[str, Any]) -> dict[str, Any]:
    variations = product.get("product_variations")
    if isinstance(variations, list) and variations:
        first = variations[0]
        if isinstance(first, dict):
            return first
    return {}


def _extract_image_url(product: dict[str, Any]) -> str | None:
    images = product.get("images")
    if isinstance(images, list):
        for item in images:
            if isinstance(item, dict) and item.get("image_url"):
                return str(item["image_url"])[:500]
    for key in ("file_path", "logo_path", "image_url"):
        value = product.get(key)
        if value:
            return str(value).replace("?width=%s", "").replace("?width={width}", "")[:500]
    return None


def _to_decimal(value: object) -> Decimal | None:
    if value is None or value == "":
        return None
    try:
        return Decimal(str(value)).quantize(Decimal("0.01"))
    except (InvalidOperation, ValueError):
        return None


def _extract_prices(product: dict[str, Any]) -> Decimal | None:
    variation = _first_variation(product)
    sale = _to_decimal(variation.get("price"))
    before = _to_decimal(variation.get("price_before_discount"))
    if before is not None and sale is not None and before > sale:
        return sale
    return sale or before


def parse_menu_dishes(menu_payload: dict[str, Any]) -> list[dict[str, Any]]:
    """Parse api/v5 menu: data.menus[].menu_categories[].products[]"""
    data = menu_payload.get("data")
    if not isinstance(data, dict):
        return []

    menus = data.get("menus")
    if not isinstance(menus, list):
        return []

    rows: list[dict[str, Any]] = []
    for menu in menus:
        if not isinstance(menu, dict):
            continue
        menu_name = str(menu.get("name") or "").strip()
        categories = menu.get("menu_categories")
        if not isinstance(categories, list):
            continue

        for category in categories:
            if not isinstance(category, dict):
                continue
            category_name = str(category.get("name") or "").strip() or menu_name or "Uncategorized"
            products = category.get("products")
            if not isinstance(products, list):
                continue

            for product in products:
                if not isinstance(product, dict):
                    continue
                dish_name = str(product.get("name") or "").strip()
                if not dish_name:
                    continue
                price = _extract_prices(product)
                product_id = product.get("id")
                rows.append(
                    {
                        "category_name": category_name[:120],
                        "dish_name": dish_name[:200],
                        "product_id": str(product_id) if product_id is not None else None,
                        "description": str(product.get("description") or "").strip() or None,
                        "price": price,
                        "image_url": _extract_image_url(product),
                    }
                )
    return rows


# ---------------------------------------------------------------------------
# In-memory indexes (built once per import chunk, not per vendor)
# ---------------------------------------------------------------------------


@dataclass
class RestaurantImportIndex:
    by_external_code: dict[str, int]
    by_external_id: dict[str, int]
    by_legacy_vendor_code: dict[str, int]
    by_name: dict[str, int]


@dataclass
class DishImportIndex:
    by_external_id: dict[tuple[int, str], Dish]
    by_name: dict[tuple[int, str], Dish]


@dataclass
class ImportIndexes:
    restaurants: RestaurantImportIndex
    dishes: DishImportIndex
    categories: dict[str, int]


# ---------------------------------------------------------------------------
# Import service
# ---------------------------------------------------------------------------


class FoodpandaImportService:
    """Fetch from FoodpandaClient and persist via injected SQLAlchemy Session."""

    def __init__(self, db: Session, client: FoodpandaClient) -> None:
        self._db = db
        self._client = client

    def import_restaurants(
        self,
        latitude: float,
        longitude: float,
        *,
        limit: int = 1,
        offset: int = 0,
    ) -> FoodpandaImportStats:
        """
        Search vendors near coordinates and import up to ``limit`` restaurants + menus.
        """
        stats = FoodpandaImportStats()
        try:
            payload = self._client.search_restaurants(latitude, longitude, limit=limit, offset=offset)
        except FoodpandaAPIError as exc:
            stats.add_error(f"Vendor search failed: {exc}")
            return stats

        vendors = extract_vendor_list(payload)[:limit]
        logger.info(
            "Foodpanda import search: %d vendor(s) at lat=%s lon=%s",
            len(vendors),
            latitude,
            longitude,
        )

        for raw in vendors:
            parsed = parse_vendor(raw)
            code = parsed.get("vendor_code") or ""
            if not code:
                stats.add_error(f"Vendor missing code: {parsed.get('vendor_name')}")
                continue
            vendor_stats = self.import_vendor(
                code,
                latitude,
                longitude,
                vendor_hint=parsed,
            )
            self._merge_stats(stats, vendor_stats)

        return stats

    def build_import_indexes(self) -> ImportIndexes:
        """Load restaurant, dish, and category indexes in one pass (chunk scope)."""
        return ImportIndexes(
            restaurants=self._load_restaurant_indexes(),
            dishes=self._load_dish_index(),
            categories=self._load_category_cache(),
        )

    def import_vendor(
        self,
        vendor_code: str,
        latitude: float,
        longitude: float,
        *,
        vendor_hint: dict[str, Any] | None = None,
        indexes: ImportIndexes | None = None,
        owner_id: int | None = None,
    ) -> FoodpandaImportStats:
        """
        Import one restaurant and its full menu (atomic transaction per vendor).
        """
        stats = FoodpandaImportStats()
        code = vendor_code.strip()
        if not code:
            stats.add_error("vendor_code is required")
            return stats

        try:
            menu_payload = self._client.get_restaurant_menu(code, latitude, longitude)
        except (FoodpandaAPIError, ValueError) as exc:
            stats.add_error(f"Menu fetch failed for {code}: {exc}")
            return stats

        parsed = vendor_hint or parse_vendor_from_menu_payload(menu_payload, vendor_code=code)

        try:
            resolved_owner_id = owner_id if owner_id is not None else self._resolve_import_owner_id()
            import_indexes = indexes if indexes is not None else self.build_import_indexes()

            restaurant, created, updated = self._upsert_restaurant(
                parsed,
                owner_id=resolved_owner_id,
                indexes=import_indexes.restaurants,
            )
            if created:
                stats.restaurants_created = 1
                logger.info("Created restaurant id=%s code=%s", restaurant.id, code)
            elif updated:
                stats.restaurants_updated = 1
                logger.info("Updated restaurant id=%s code=%s", restaurant.id, code)

            dish_stats = self._import_dishes(
                restaurant=restaurant,
                menu_payload=menu_payload,
                category_cache=import_indexes.categories,
                dish_index=import_indexes.dishes,
            )
            stats.categories_created = dish_stats["categories_created"]
            stats.dishes_created = dish_stats["dishes_created"]
            stats.dishes_updated = dish_stats["dishes_updated"]
            stats.errors.extend(dish_stats["errors"])

            self._db.commit()
            logger.info(
                "Committed vendor import code=%s restaurant_id=%s dishes +%d ~%d",
                code,
                restaurant.id,
                stats.dishes_created,
                stats.dishes_updated,
            )
        except Exception as exc:
            self._db.rollback()
            stats.add_error(f"Rollback for vendor {code}: {exc}")
            logger.exception("Foodpanda import rolled back for vendor %s", code)

        return stats

    @staticmethod
    def _merge_stats(target: FoodpandaImportStats, source: FoodpandaImportStats) -> None:
        target.restaurants_created += source.restaurants_created
        target.restaurants_updated += source.restaurants_updated
        target.categories_created += source.categories_created
        target.dishes_created += source.dishes_created
        target.dishes_updated += source.dishes_updated
        target.errors.extend(source.errors)

    def _resolve_import_owner_id(self) -> int:
        owner_id_raw = os.getenv("FOODPANDA_IMPORT_OWNER_ID")
        if owner_id_raw:
            owner_id = int(owner_id_raw)
            if not self._db.get(User, owner_id):
                raise ValueError(f"FOODPANDA_IMPORT_OWNER_ID={owner_id} not found")
            return owner_id

        email = os.getenv("FOODPANDA_IMPORT_OWNER_EMAIL", "").strip().lower()
        if email:
            user = self._db.query(User).filter(func.lower(User.email) == email).first()
            if user:
                return user.id
            raise ValueError(f"FOODPANDA_IMPORT_OWNER_EMAIL={email} not found")

        for role in (RESTAURANT_OWNER, ADMIN):
            user = self._db.query(User).filter(User.role == role).order_by(User.id).first()
            if user:
                logger.info("Import owner user id=%s role=%s", user.id, user.role)
                return user.id

        raise ValueError(
            "No import owner. Set FOODPANDA_IMPORT_OWNER_ID or FOODPANDA_IMPORT_OWNER_EMAIL."
        )

    def _load_restaurant_indexes(self) -> RestaurantImportIndex:
        by_external_code: dict[str, int] = {}
        by_external_id: dict[str, int] = {}
        by_legacy_vendor_code: dict[str, int] = {}
        by_name: dict[str, int] = {}

        for restaurant in self._db.query(Restaurant).all():
            by_name[normalize_name(restaurant.name)] = restaurant.id

            if restaurant.source == FOODPANDA_SOURCE:
                if restaurant.external_code:
                    by_external_code[restaurant.external_code.lower()] = restaurant.id
                if restaurant.external_id:
                    by_external_id[restaurant.external_id] = restaurant.id
            else:
                stored_code = extract_vendor_code(restaurant.description)
                if stored_code:
                    by_legacy_vendor_code[stored_code.lower()] = restaurant.id

        return RestaurantImportIndex(
            by_external_code=by_external_code,
            by_external_id=by_external_id,
            by_legacy_vendor_code=by_legacy_vendor_code,
            by_name=by_name,
        )

    def _load_dish_index(self) -> DishImportIndex:
        by_external_id: dict[tuple[int, str], Dish] = {}
        by_name: dict[tuple[int, str], Dish] = {}

        for dish in self._db.query(Dish).all():
            name_key = (dish.restaurant_id, normalize_name(dish.name))
            by_name[name_key] = dish
            if dish.source == FOODPANDA_SOURCE and dish.external_id:
                by_external_id[(dish.restaurant_id, dish.external_id)] = dish

        return DishImportIndex(by_external_id=by_external_id, by_name=by_name)

    def _load_category_cache(self) -> dict[str, int]:
        return {normalize_name(c.name): c.id for c in self._db.query(Category).all()}

    def load_imported_external_codes(self) -> set[str]:
        """Foodpanda vendor codes already present in the database."""
        rows = (
            self._db.query(Restaurant.external_code)
            .filter(
                Restaurant.source == FOODPANDA_SOURCE,
                Restaurant.external_code.isnot(None),
            )
            .all()
        )
        return {str(code).lower() for (code,) in rows if code}

    def _find_existing_restaurant_id(
        self,
        indexes: RestaurantImportIndex,
        *,
        vendor_code: str,
        vendor_id: str,
        vendor_name: str,
    ) -> int | None:
        code_key = vendor_code.strip().lower()
        if code_key and code_key in indexes.by_external_code:
            return indexes.by_external_code[code_key]

        ext_id = vendor_id.strip()
        if ext_id and ext_id in indexes.by_external_id:
            return indexes.by_external_id[ext_id]

        if code_key and code_key in indexes.by_legacy_vendor_code:
            return indexes.by_legacy_vendor_code[code_key]

        name_key = normalize_name(vendor_name)
        if name_key and name_key in indexes.by_name:
            return indexes.by_name[name_key]
        return None

    def _upsert_restaurant(
        self,
        parsed: dict[str, Any],
        *,
        owner_id: int,
        indexes: RestaurantImportIndex,
    ) -> tuple[Restaurant, bool, bool]:
        vendor_code = parsed["vendor_code"] or parsed.get("vendor_name", "")
        vendor_id = parsed.get("vendor_id") or ""
        vendor_name = parsed["vendor_name"] or vendor_code
        existing_id = self._find_existing_restaurant_id(
            indexes,
            vendor_code=vendor_code,
            vendor_id=vendor_id,
            vendor_name=vendor_name,
        )

        description = build_restaurant_description(
            vendor_code=vendor_code,
            vendor_id=vendor_id,
            cuisines=parsed.get("cuisines"),
            url_key=(parsed.get("url_key") or None),
        )
        tags = cuisines_to_tags(parsed.get("cuisines"))
        rating = parsed.get("rating")
        review_count = parsed.get("review_count")
        average_rating = float(rating) if rating is not None else 0.0
        total_reviews = int(review_count) if review_count is not None else 0
        is_open = parsed.get("is_open") if parsed.get("is_open") is not None else True

        if existing_id:
            restaurant = self._db.get(Restaurant, existing_id)
            if not restaurant:
                raise ValueError(f"Restaurant id={existing_id} not found")
            restaurant.name = vendor_name[:200]
            restaurant.description = description
            restaurant.source = FOODPANDA_SOURCE
            restaurant.external_id = vendor_id or None
            restaurant.external_code = vendor_code or None
            if tags is not None:
                restaurant.tags = tags
            if parsed.get("address"):
                restaurant.address = str(parsed["address"])[:300]
            city = parse_city(parsed.get("city"))
            if city:
                restaurant.city = city
            restaurant.is_open = bool(is_open)
            restaurant.average_rating = average_rating
            restaurant.total_reviews = total_reviews
            self._db.flush()
            self._register_restaurant_indexes(restaurant, indexes)
            return restaurant, False, True

        restaurant = Restaurant(
            owner_id=owner_id,
            name=vendor_name[:200],
            description=description,
            address=str(parsed["address"])[:300] if parsed.get("address") else None,
            city=parse_city(parsed.get("city")),
            is_open=bool(is_open),
            average_rating=average_rating,
            total_reviews=total_reviews,
            source=FOODPANDA_SOURCE,
            external_id=vendor_id or None,
            external_code=vendor_code or None,
            tags=tags,
        )
        self._db.add(restaurant)
        self._db.flush()
        self._register_restaurant_indexes(restaurant, indexes)
        return restaurant, True, False

    @staticmethod
    def _register_restaurant_indexes(
        restaurant: Restaurant,
        indexes: RestaurantImportIndex,
    ) -> None:
        indexes.by_name[normalize_name(restaurant.name)] = restaurant.id
        if restaurant.source == FOODPANDA_SOURCE:
            if restaurant.external_code:
                indexes.by_external_code[restaurant.external_code.lower()] = restaurant.id
            if restaurant.external_id:
                indexes.by_external_id[restaurant.external_id] = restaurant.id

    def _get_or_create_category(
        self,
        category_name: str,
        *,
        cache: dict[str, int],
    ) -> tuple[int, bool]:
        name = str(category_name or "").strip()[:120] or "Uncategorized"
        key = normalize_name(name)
        if key in cache:
            return cache[key], False

        existing = (
            self._db.query(Category).filter(func.lower(Category.name) == key).first()
        )
        if existing:
            cache[key] = existing.id
            return existing.id, False

        category = Category(name=name, description="Imported from Foodpanda menus")
        self._db.add(category)
        self._db.flush()
        cache[key] = category.id
        logger.info("Created category id=%s name=%s", category.id, name)
        return category.id, True

    def _import_dishes(
        self,
        *,
        restaurant: Restaurant,
        menu_payload: dict[str, Any],
        category_cache: dict[str, int],
        dish_index: DishImportIndex,
    ) -> dict[str, Any]:
        result = {
            "categories_created": 0,
            "dishes_created": 0,
            "dishes_updated": 0,
            "errors": [],
        }

        rows = parse_menu_dishes(menu_payload)
        logger.info("Importing %d dish row(s) for restaurant id=%s", len(rows), restaurant.id)

        for row in rows:
            dish_name = row["dish_name"]
            price = row.get("price")
            if price is None or price <= 0:
                result["errors"].append(f"Invalid price for {dish_name}: {price}")
                continue

            category_id, cat_created = self._get_or_create_category(
                row["category_name"],
                cache=category_cache,
            )
            if cat_created:
                result["categories_created"] += 1

            product_id = row.get("product_id")
            existing: Dish | None = None
            if product_id:
                existing = dish_index.by_external_id.get((restaurant.id, product_id))
            if existing is None:
                existing = dish_index.by_name.get((restaurant.id, normalize_name(dish_name)))

            if existing:
                existing.description = row.get("description")
                existing.price = price
                existing.image = row.get("image_url")
                existing.category_id = category_id
                existing.is_available = True
                existing.source = FOODPANDA_SOURCE
                if product_id:
                    existing.external_id = product_id
                result["dishes_updated"] += 1
                if product_id:
                    dish_index.by_external_id[(restaurant.id, product_id)] = existing
                dish_index.by_name[(restaurant.id, normalize_name(dish_name))] = existing
                logger.debug("Updated dish id=%s name=%s", existing.id, dish_name)
                continue

            dish = Dish(
                restaurant_id=restaurant.id,
                category_id=category_id,
                name=dish_name,
                description=row.get("description"),
                price=price,
                image=row.get("image_url"),
                is_available=True,
                source=FOODPANDA_SOURCE,
                external_id=product_id,
            )
            self._db.add(dish)
            self._db.flush()
            if product_id:
                dish_index.by_external_id[(restaurant.id, product_id)] = dish
            dish_index.by_name[(restaurant.id, normalize_name(dish_name))] = dish
            result["dishes_created"] += 1
            logger.debug("Created dish id=%s name=%s", dish.id, dish_name)

        return result
