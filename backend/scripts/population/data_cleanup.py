"""Database cleanup — placeholders, duplicates, missing images (batched)."""

from __future__ import annotations

import random
import re
from collections import defaultdict
from dataclasses import dataclass, field
from datetime import time

from sqlalchemy import func
from sqlalchemy.orm import Session

from app.core.restaurant_constants import APPROVED
from app.models.dish import Dish
from app.models.order_item import OrderItem
from app.models.restaurant import Restaurant

from .placeholders import is_bad_dish_name, is_bad_restaurant_name, is_bad_text

_DELIVERY_BLURB = "Delivery in 30–45 min · Fee from Rs 99 on Foodpanda orders."
_BATCH = 50


@dataclass
class CleanupStats:
    placeholder_restaurants_removed: int = 0
    placeholder_dishes_removed: int = 0
    duplicate_restaurants_removed: int = 0
    restaurants_renamed: int = 0
    restaurants_enriched: int = 0
    dishes_image_linked: int = 0
    restaurants_image_linked: int = 0
    dishes_description_filled: int = 0
    errors: list[str] = field(default_factory=list)


def _humanize_restaurant_name(raw: str) -> str:
    text = re.sub(r"^r[\s\-_]?(\d+)$", r"Restaurant \1", raw.strip(), flags=re.IGNORECASE)
    return re.sub(r"\s+", " ", text)[:200] or "Local Eatery"


def _humanize_dish_name(raw: str) -> str:
    return f"House Special {random.randint(100, 999)}"


def _referenced_dish_ids(db: Session) -> set[int]:
    return {row[0] for row in db.query(OrderItem.dish_id).distinct().all() if row[0]}


def cleanup_and_enrich(db: Session, *, seed: int = 42) -> CleanupStats:
    random.seed(seed)
    stats = CleanupStats()
    referenced = _referenced_dish_ids(db)

    # Placeholder dishes
    for dish in db.query(Dish.id, Dish.name).all():
        if not is_bad_dish_name(dish.name):
            continue
        row = db.get(Dish, dish.id)
        if not row:
            continue
        if dish.id in referenced:
            row.name = _humanize_dish_name(dish.name)
            row.is_available = False
        else:
            db.delete(row)
            stats.placeholder_dishes_removed += 1
    db.commit()

    # Placeholder restaurants
    for restaurant in db.query(Restaurant).all():
        if not is_bad_restaurant_name(restaurant.name):
            continue
        dish_count = (
            db.query(func.count(Dish.id)).filter(Dish.restaurant_id == restaurant.id).scalar() or 0
        )
        if dish_count == 0:
            db.delete(restaurant)
            stats.placeholder_restaurants_removed += 1
        else:
            restaurant.name = _humanize_restaurant_name(restaurant.name)
            stats.restaurants_renamed += 1
    db.commit()

    # Dedupe empty duplicate vendors only
    by_code: dict[str, list[Restaurant]] = defaultdict(list)
    for r in db.query(Restaurant).filter(Restaurant.external_code.isnot(None)).all():
        if r.external_code:
            by_code[r.external_code.lower()].append(r)
    for group in by_code.values():
        if len(group) < 2:
            continue
        for dup in group[1:]:
            if (
                db.query(func.count(Dish.id)).filter(Dish.restaurant_id == dup.id).scalar() or 0
            ) == 0:
                db.delete(dup)
                stats.duplicate_restaurants_removed += 1
    db.commit()

    # Restaurant enrichment — only rows missing key fields
    last_id = 0
    while True:
        batch = (
            db.query(Restaurant)
            .filter(
                Restaurant.approval_status == APPROVED,
                Restaurant.id > last_id,
                (
                    (Restaurant.image.is_(None))
                    | (Restaurant.image == "")
                    | (Restaurant.city.is_(None))
                    | (Restaurant.address.is_(None))
                    | (Restaurant.opening_time.is_(None))
                ),
            )
            .order_by(Restaurant.id)
            .limit(_BATCH)
            .all()
        )
        if not batch:
            break

        for restaurant in batch:
            sample_img = (
                db.query(Dish.image)
                .filter(
                    Dish.restaurant_id == restaurant.id,
                    Dish.image.isnot(None),
                    Dish.image != "",
                )
                .limit(1)
                .scalar()
            )
            changed = False
            if not restaurant.city or is_bad_text(restaurant.city):
                restaurant.city = "Lahore"
                changed = True
            if not restaurant.address or is_bad_text(restaurant.address):
                area = (restaurant.tags or ["Lahore"])[0]
                restaurant.address = f"{restaurant.name}, {str(area).title()}, Lahore"[:300]
                changed = True
            if restaurant.opening_time is None:
                restaurant.opening_time = time(10, 0)
                changed = True
            if restaurant.closing_time is None:
                restaurant.closing_time = time(23, 0)
                changed = True
            if _DELIVERY_BLURB not in (restaurant.description or ""):
                cuisine = ", ".join((restaurant.tags or ["Multi-cuisine"])[:3])
                restaurant.description = (
                    f"{restaurant.name} serves authentic {cuisine} in Lahore. "
                    f"Rated {restaurant.average_rating:.1f}★ with {restaurant.total_reviews} reviews. "
                    f"{_DELIVERY_BLURB}"
                )[:2000]
                changed = True
            if (not restaurant.image or not str(restaurant.image).strip()) and sample_img:
                restaurant.image = sample_img
                stats.restaurants_image_linked += 1
                changed = True
            if changed:
                stats.restaurants_enriched += 1
            last_id = restaurant.id

        db.commit()

    # Dish image + description — only missing rows, batched
    last_dish_id = 0
    while True:
        dishes = (
            db.query(Dish)
            .filter(
                Dish.id > last_dish_id,
                (
                    (Dish.image.is_(None))
                    | (Dish.image == "")
                    | (Dish.description.is_(None))
                    | (Dish.description == "")
                ),
            )
            .order_by(Dish.id)
            .limit(_BATCH)
            .all()
        )
        if not dishes:
            break

        restaurant_names = {
            r.id: r.name
            for r in db.query(Restaurant.id, Restaurant.name)
            .filter(Restaurant.id.in_({d.restaurant_id for d in dishes}))
            .all()
        }
        fallback_images: dict[int, str | None] = {}
        for rid in {d.restaurant_id for d in dishes}:
            fallback_images[rid] = (
                db.query(Dish.image)
                .filter(Dish.restaurant_id == rid, Dish.image.isnot(None), Dish.image != "")
                .limit(1)
                .scalar()
            )

        for dish in dishes:
            if not dish.image or not str(dish.image).strip():
                fb = fallback_images.get(dish.restaurant_id)
                if fb:
                    dish.image = fb
                    stats.dishes_image_linked += 1
            if not dish.description or is_bad_text(dish.description):
                rname = restaurant_names.get(dish.restaurant_id, "our kitchen")
                dish.description = (
                    f"Fresh {dish.name} prepared to order at {rname}. "
                    f"A customer favourite in Lahore."
                )[:500]
                stats.dishes_description_filled += 1
            last_dish_id = dish.id

        db.commit()

    return stats
