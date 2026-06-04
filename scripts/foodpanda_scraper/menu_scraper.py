"""
Foodpanda menu (dish) scraper — Phase 2.

Fetches per-vendor menus from api/v5, saves raw JSON under raw/menus/,
and exports output/dishes.xlsx plus menu_scraper_report.md.
"""

from __future__ import annotations

import json
import logging
import os
import sys
import time
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any

import pandas as pd
import requests

from config import (
    BROWSER_HEADERS,
    DEFAULT_LATITUDE,
    DEFAULT_LONGITUDE,
    DISHES_EXCEL,
    LOG_LEVEL,
    MENU_API_V5_BASE,
    OUTPUT_DIR,
    PERSEUS_HEADERS,
    RAW_DIR,
    REQUEST_TIMEOUT_SECONDS,
    RESTAURANTS_EXCEL,
    SITE_ORIGIN,
)
from export_excel import save_dataframe_excel

logger = logging.getLogger(__name__)

MENUS_RAW_DIR: Path = RAW_DIR / "menus"
REPORT_PATH: Path = Path(__file__).resolve().parent / "menu_scraper_report.md"

REQUEST_DELAY_SECONDS: float = float(os.getenv("FOODPANDA_MENU_DELAY", "0.4"))
MAX_RETRIES: int = int(os.getenv("FOODPANDA_MENU_MAX_RETRIES", "3"))
RETRY_BACKOFF_SECONDS: float = float(os.getenv("FOODPANDA_MENU_RETRY_BACKOFF", "2.0"))

DISH_COLUMNS: list[str] = [
    "vendor_id",
    "vendor_code",
    "vendor_name",
    "category_name",
    "product_id",
    "dish_name",
    "description",
    "price",
    "discounted_price",
    "image_url",
]

RESTAURANT_COLUMNS: list[str] = [
    "vendor_id",
    "vendor_code",
    "vendor_name",
    "url_key",
]


@dataclass
class RestaurantRow:
    vendor_id: str
    vendor_code: str
    vendor_name: str
    url_key: str = ""


@dataclass
class ScrapeStats:
    processed: int = 0
    failed: int = 0
    total_dishes: int = 0
    categories: set[str] = field(default_factory=set)
    failed_vendors: list[dict[str, str]] = field(default_factory=list)


def setup_logging(level: str | None = None) -> None:
    logging.basicConfig(
        level=getattr(logging, (level or LOG_LEVEL).upper(), logging.INFO),
        format="%(asctime)s | %(levelname)s | %(name)s | %(message)s",
        datefmt="%Y-%m-%d %H:%M:%S",
    )


def ensure_directories() -> None:
    RAW_DIR.mkdir(parents=True, exist_ok=True)
    MENUS_RAW_DIR.mkdir(parents=True, exist_ok=True)
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)


def load_restaurants(excel_path: Path) -> list[RestaurantRow]:
    if not excel_path.is_file():
        raise FileNotFoundError(
            f"Missing {excel_path}. Run vendor_scraper.py first."
        )
    df = pd.read_excel(excel_path)
    required = {"vendor_id", "vendor_code", "vendor_name"}
    missing = required - set(df.columns)
    if missing:
        raise ValueError(f"restaurants.xlsx missing columns: {sorted(missing)}")

    rows: list[RestaurantRow] = []
    for _, record in df.iterrows():
        code = str(record["vendor_code"]).strip()
        if not code or code.lower() == "nan":
            continue
        url_key = ""
        if "url_key" in df.columns and pd.notna(record.get("url_key")):
            url_key = str(record["url_key"]).strip()
        rows.append(
            RestaurantRow(
                vendor_id=str(record["vendor_id"]).strip(),
                vendor_code=code,
                vendor_name=str(record["vendor_name"]).strip(),
                url_key=url_key,
            )
        )
    logger.info("Loaded %d restaurant(s) from %s", len(rows), excel_path)
    return rows


def build_menu_query_params(
    latitude: float | None = None,
    longitude: float | None = None,
) -> dict[str, Any]:
    lat = latitude if latitude is not None else DEFAULT_LATITUDE
    lon = longitude if longitude is not None else DEFAULT_LONGITUDE
    return {
        "latitude": lat,
        "longitude": lon,
        "language_id": 1,
        "country": "pk",
        "opening_type": "delivery",
        "include": "menus",
    }


def restaurant_referer(restaurant: RestaurantRow) -> str:
    if restaurant.url_key:
        return (
            f"{SITE_ORIGIN}/restaurant/"
            f"{restaurant.vendor_code}/{restaurant.url_key}"
        )
    return f"{SITE_ORIGIN}/restaurant/{restaurant.vendor_code}"


def build_menu_headers(restaurant: RestaurantRow) -> dict[str, str]:
    headers = dict(BROWSER_HEADERS)
    headers.update(PERSEUS_HEADERS)
    headers["Referer"] = restaurant_referer(restaurant)
    return headers


def fetch_menu(
    restaurant: RestaurantRow,
    *,
    latitude: float | None = None,
    longitude: float | None = None,
) -> dict[str, Any]:
    """
    Fetch menu JSON for a single vendor (api/v5 + Perseus headers).

    Retries on network errors and non-200 responses.
    """
    url = f"{MENU_API_V5_BASE}/vendors/{restaurant.vendor_code}"
    params = build_menu_query_params(latitude=latitude, longitude=longitude)
    headers = build_menu_headers(restaurant)
    last_error: str | None = None

    for attempt in range(1, MAX_RETRIES + 1):
        try:
            logger.debug(
                "GET %s (attempt %d/%d)",
                url,
                attempt,
                MAX_RETRIES,
            )
            response = requests.get(
                url,
                headers=headers,
                params=params,
                timeout=REQUEST_TIMEOUT_SECONDS,
            )
            if response.status_code != 200:
                last_error = f"HTTP {response.status_code}: {response.text[:200]}"
                logger.warning(
                    "%s | %s — attempt %d/%d",
                    restaurant.vendor_code,
                    last_error,
                    attempt,
                    MAX_RETRIES,
                )
            else:
                payload = response.json()
                if not isinstance(payload, dict):
                    last_error = "Response is not a JSON object"
                elif payload.get("status_code") not in (None, 200):
                    last_error = f"API status_code={payload.get('status_code')}"
                else:
                    return payload
        except requests.RequestException as exc:
            last_error = str(exc)
            logger.warning(
                "%s | request error: %s — attempt %d/%d",
                restaurant.vendor_code,
                exc,
                attempt,
                MAX_RETRIES,
            )
        except json.JSONDecodeError as exc:
            last_error = f"Invalid JSON: {exc}"
            logger.warning(
                "%s | %s — attempt %d/%d",
                restaurant.vendor_code,
                last_error,
                attempt,
                MAX_RETRIES,
            )

        if attempt < MAX_RETRIES:
            time.sleep(RETRY_BACKOFF_SECONDS * attempt)

    raise RuntimeError(last_error or "Unknown fetch error")


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
                return str(item["image_url"])
    for key in ("file_path", "logo_path", "image_url"):
        value = product.get(key)
        if value:
            url = str(value)
            return url.replace("?width=%s", "").replace("?width={width}", "")
    return None


def _extract_prices(product: dict[str, Any]) -> tuple[float | None, float | None]:
    variation = _first_variation(product)
    sale = variation.get("price")
    before = variation.get("price_before_discount")

    sale_f = float(sale) if sale is not None and sale != "" else None
    before_f = float(before) if before is not None and before != "" else None

    if before_f is not None and sale_f is not None and before_f > sale_f:
        return before_f, sale_f
    return sale_f, None


def parse_menu(
    payload: dict[str, Any],
    restaurant: RestaurantRow,
) -> pd.DataFrame:
    """
    Parse api/v5 menu payload into dish rows.

    Response: data.menus[].menu_categories[].products[]
    """
    data = payload.get("data")
    if not isinstance(data, dict):
        logger.warning("%s | missing data object in payload", restaurant.vendor_code)
        return pd.DataFrame(columns=DISH_COLUMNS)

    menus = data.get("menus")
    if not isinstance(menus, list) or not menus:
        logger.warning("%s | no menus in response", restaurant.vendor_code)
        return pd.DataFrame(columns=DISH_COLUMNS)

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
            category_name = str(category.get("name") or "").strip()
            if not category_name and menu_name:
                category_name = menu_name

            products = category.get("products")
            if not isinstance(products, list):
                continue

            for product in products:
                if not isinstance(product, dict):
                    continue
                price, discounted = _extract_prices(product)
                rows.append(
                    {
                        "vendor_id": restaurant.vendor_id,
                        "vendor_code": restaurant.vendor_code,
                        "vendor_name": restaurant.vendor_name,
                        "category_name": category_name,
                        "product_id": product.get("id"),
                        "dish_name": product.get("name"),
                        "description": product.get("description") or "",
                        "price": price,
                        "discounted_price": discounted,
                        "image_url": _extract_image_url(product),
                    }
                )

    if not rows:
        return pd.DataFrame(columns=DISH_COLUMNS)

    df = pd.DataFrame(rows)
    for col in DISH_COLUMNS:
        if col not in df.columns:
            df[col] = None
    return df[DISH_COLUMNS]


def save_menu_json(payload: dict[str, Any], vendor_code: str) -> Path:
    path = MENUS_RAW_DIR / f"{vendor_code}.json"
    with path.open("w", encoding="utf-8") as fh:
        json.dump(payload, fh, ensure_ascii=False, indent=2)
    logger.info("Saved raw menu -> %s", path)
    return path


def save_dishes_excel(df: pd.DataFrame, path: Path) -> Path:
    path.parent.mkdir(parents=True, exist_ok=True)
    if df.empty:
        empty = pd.DataFrame(columns=DISH_COLUMNS)
        with pd.ExcelWriter(path.resolve(), engine="openpyxl") as writer:
            empty.to_excel(writer, sheet_name="dishes", index=False)
        logger.warning("Saved empty dishes Excel -> %s", path)
        return path.resolve()
    return save_dataframe_excel(df, path, sheet_name="dishes")


def write_report(
    stats: ScrapeStats,
    total_restaurants: int,
    report_path: Path,
) -> None:
    lines = [
        "# Foodpanda Menu Scraper Report",
        "",
        "## Summary",
        "",
        f"| Metric | Value |",
        f"|--------|------:|",
        f"| Restaurants in Excel | {total_restaurants} |",
        f"| Restaurants processed | {stats.processed} |",
        f"| Restaurants failed | {stats.failed} |",
        f"| Total dishes extracted | {stats.total_dishes} |",
        f"| Unique categories | {len(stats.categories)} |",
        "",
        "## Endpoint",
        "",
        f"`GET {MENU_API_V5_BASE}/vendors/{{vendor_code}}`",
        "",
        "Query: `latitude`, `longitude`, `language_id=1`, `country=pk`, "
        "`opening_type=delivery`, `include=menus`",
        "",
        "## Failed restaurants",
        "",
    ]
    if stats.failed_vendors:
        lines.append("| vendor_code | vendor_name | error |")
        lines.append("|-------------|-------------|-------|")
        for item in stats.failed_vendors:
            err = item.get("error", "").replace("|", "\\|")[:120]
            lines.append(
                f"| {item.get('vendor_code', '')} | "
                f"{item.get('vendor_name', '')} | {err} |"
            )
    else:
        lines.append("_None._")
    lines.append("")

    if stats.categories:
        lines.extend(["## Categories found", ""])
        for name in sorted(stats.categories):
            lines.append(f"- {name}")
        lines.append("")

    report_path.write_text("\n".join(lines), encoding="utf-8")
    logger.info("Wrote report -> %s", report_path)


def scrape_all(
    restaurants: list[RestaurantRow],
    *,
    latitude: float | None = None,
    longitude: float | None = None,
) -> tuple[pd.DataFrame, ScrapeStats]:
    stats = ScrapeStats()
    frames: list[pd.DataFrame] = []

    for index, restaurant in enumerate(restaurants, start=1):
        logger.info(
            "[%d/%d] %s (%s)",
            index,
            len(restaurants),
            restaurant.vendor_name,
            restaurant.vendor_code,
        )
        try:
            payload = fetch_menu(
                restaurant,
                latitude=latitude,
                longitude=longitude,
            )
            save_menu_json(payload, restaurant.vendor_code)
            df = parse_menu(payload, restaurant)
            stats.processed += 1
            stats.total_dishes += len(df)
            for cat in df["category_name"].dropna().unique():
                stats.categories.add(str(cat))
            if not df.empty:
                frames.append(df)
            logger.info(
                "  OK — %d dish(es), %d categor(ies)",
                len(df),
                df["category_name"].nunique() if not df.empty else 0,
            )
        except Exception as exc:
            stats.failed += 1
            stats.failed_vendors.append(
                {
                    "vendor_code": restaurant.vendor_code,
                    "vendor_name": restaurant.vendor_name,
                    "error": str(exc),
                }
            )
            logger.error(
                "  FAILED %s (%s): %s",
                restaurant.vendor_code,
                restaurant.vendor_name,
                exc,
            )

        if index < len(restaurants):
            time.sleep(REQUEST_DELAY_SECONDS)

    if frames:
        combined = pd.concat(frames, ignore_index=True)
        combined = combined[DISH_COLUMNS]
    else:
        combined = pd.DataFrame(columns=DISH_COLUMNS)

    return combined, stats


def main() -> int:
    setup_logging()
    ensure_directories()

    excel_path = OUTPUT_DIR / RESTAURANTS_EXCEL
    restaurants = load_restaurants(excel_path)
    if not restaurants:
        logger.error("No restaurants to scrape.")
        return 1

    dishes_df, stats = scrape_all(restaurants)
    out_excel = OUTPUT_DIR / DISHES_EXCEL
    save_dishes_excel(dishes_df, out_excel)
    write_report(stats, len(restaurants), REPORT_PATH)

    print()
    print("Menu scrape complete")
    print(f"  Restaurants processed : {stats.processed}")
    print(f"  Restaurants failed    : {stats.failed}")
    print(f"  Total dishes          : {stats.total_dishes}")
    print(f"  Categories            : {len(stats.categories)}")
    print(f"  Output                : {out_excel}")
    print(f"  Raw menus             : {MENUS_RAW_DIR}")
    print(f"  Report                : {REPORT_PATH}")

    return 0 if stats.processed > 0 else 1


if __name__ == "__main__":
    sys.exit(main())
