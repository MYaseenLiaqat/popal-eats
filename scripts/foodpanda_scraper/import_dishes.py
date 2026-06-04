"""
Import Foodpanda dishes from output/dishes.xlsx into PostgreSQL.

Requires restaurants to exist (run import_restaurants.py first).

Usage:
  python import_dishes.py
  python import_dishes.py --dry-run

Run with backend venv:
  backend\\venv\\Scripts\\python.exe scripts\\foodpanda_scraper\\import_dishes.py
"""

from __future__ import annotations

import argparse
import json
import logging
import sys

import pandas as pd

from import_common import (
    BATCH_SIZE,
    DISHES_EXCEL,
    IMPORT_MAP_JSON,
    ImportStats,
    append_report,
    dish_price,
    find_existing_restaurant_id,
    get_or_create_category,
    get_session,
    load_backend_env,
    load_existing_restaurant_indexes,
    load_vendor_restaurant_map,
    normalize_name,
    setup_backend_path,
    setup_logging,
    write_report_header,
)

logger = logging.getLogger(__name__)


def load_dishes_excel() -> pd.DataFrame:
    if not DISHES_EXCEL.is_file():
        raise FileNotFoundError(f"Missing {DISHES_EXCEL}. Run menu_scraper.py first.")
    df = pd.read_excel(DISHES_EXCEL)
    required = {"vendor_code", "dish_name", "category_name"}
    missing = required - set(df.columns)
    if missing:
        raise ValueError(f"dishes.xlsx missing columns: {sorted(missing)}")
    return df


def load_vendor_map(session) -> dict[str, int]:
    """Merge JSON map from restaurant import with live DB lookups."""
    vendor_map: dict[str, int] = load_vendor_restaurant_map(session)

    if IMPORT_MAP_JSON.is_file():
        try:
            file_map = json.loads(IMPORT_MAP_JSON.read_text(encoding="utf-8"))
            for code, rid in file_map.items():
                if isinstance(rid, int) and rid > 0:
                    vendor_map[str(code).lower()] = rid
        except json.JSONDecodeError as exc:
            logger.warning("Could not parse %s: %s", IMPORT_MAP_JSON, exc)

    return vendor_map


def resolve_restaurant_id(
    vendor_code: str,
    vendor_name: str,
    vendor_map: dict[str, int],
    by_name: dict[str, int],
    by_vendor_code: dict[str, int],
) -> int | None:
    code_key = vendor_code.strip().lower()
    if code_key in vendor_map and vendor_map[code_key] > 0:
        return vendor_map[code_key]

    return find_existing_restaurant_id(
        by_name,
        by_vendor_code,
        vendor_code=vendor_code,
        vendor_name=vendor_name,
    )


def import_dishes(*, dry_run: bool = False) -> ImportStats:
    setup_backend_path()
    load_backend_env()

    from app.models.dish import Dish

    df = load_dishes_excel()
    stats = ImportStats()
    pending = 0
    categories_found: set[str] = set()

    session = get_session()
    try:
        vendor_map = load_vendor_map(session)
        by_name, by_vendor_code = load_existing_restaurant_indexes(session)
        category_cache: dict[str, int] = {}

        # Preload existing dish keys per restaurant for duplicate detection
        existing_dish_keys: set[tuple[int, str]] = set()
        for restaurant_id, dish_name in session.query(Dish.restaurant_id, Dish.name).all():
            existing_dish_keys.add((restaurant_id, normalize_name(dish_name)))

        for index, row in df.iterrows():
            vendor_code = str(row["vendor_code"]).strip()
            vendor_name = str(row.get("vendor_name", "")).strip()
            dish_name = str(row["dish_name"]).strip()

            if not vendor_code or not dish_name:
                stats.skipped += 1
                continue

            restaurant_id = resolve_restaurant_id(
                vendor_code,
                vendor_name,
                vendor_map,
                by_name,
                by_vendor_code,
            )
            if not restaurant_id or restaurant_id < 0:
                stats.skipped += 1
                msg = f"No restaurant for vendor_code={vendor_code} ({vendor_name}), dish={dish_name}"
                if len(stats.errors) < 200:
                    stats.add_error(msg)
                continue

            dish_key = (restaurant_id, normalize_name(dish_name))
            if dish_key in existing_dish_keys:
                stats.skipped += 1
                continue

            category_name = str(row.get("category_name", "")).strip() or "Uncategorized"
            categories_found.add(category_name)

            category_id = get_or_create_category(
                session,
                category_name,
                dry_run=dry_run,
                cache=category_cache,
                stats=stats,
            )
            if category_id is None or category_id < 0:
                if dry_run:
                    # Category would be created on live run; still count dish
                    category_id = 0
                else:
                    stats.skipped += 1
                    stats.add_error(f"Could not resolve category: {category_name}")
                    continue

            price = dish_price(row.get("discounted_price"), row.get("price"))
            if price is None or price <= 0:
                stats.skipped += 1
                stats.add_error(
                    f"Invalid price for {dish_name} @ {vendor_code}: "
                    f"price={row.get('price')} discounted={row.get('discounted_price')}"
                )
                continue

            description = row.get("description")
            image = row.get("image_url")

            if dry_run:
                stats.inserted += 1
                existing_dish_keys.add(dish_key)
                if (index + 1) % 500 == 0:
                    logger.info("[dry-run] Processed %d rows...", index + 1)
                continue

            dish = Dish(
                restaurant_id=restaurant_id,
                category_id=category_id,
                name=dish_name[:200],
                description=(
                    str(description)[:5000]
                    if pd.notna(description) and str(description).strip()
                    else None
                ),
                price=price,
                image=(
                    str(image)[:500]
                    if pd.notna(image) and str(image).strip()
                    else None
                ),
                is_available=True,
            )
            session.add(dish)
            pending += 1
            stats.inserted += 1
            existing_dish_keys.add(dish_key)

            if pending >= BATCH_SIZE:
                try:
                    session.commit()
                    logger.info("Committed batch (%d dishes)", pending)
                    pending = 0
                except Exception as exc:
                    session.rollback()
                    pending = 0
                    stats.add_error(f"Batch commit failed: {exc}")

        if not dry_run:
            if pending:
                session.commit()
                logger.info("Committed final batch (%d dishes)", pending)
        else:
            session.rollback()

    except Exception:
        session.rollback()
        raise
    finally:
        session.close()

    stats.categories_found = categories_found  # type: ignore[attr-defined]
    return stats


def write_dishes_report(stats: ImportStats, *, dry_run: bool) -> None:
    write_report_header()
    category_count = len(getattr(stats, "categories_found", set()))
    lines = [
        f"**Mode:** {'dry-run' if dry_run else 'live'}",
        "",
        "| Metric | Count |",
        "|--------|------:|",
        f"| Dishes inserted | {stats.inserted} |",
        f"| Dishes skipped | {stats.skipped} |",
        f"| Categories found | {category_count} |",
        f"| Errors | {len(stats.errors)} |",
        "",
    ]
    if stats.errors:
        lines.append("### Errors (sample)")
        lines.append("")
        for err in stats.errors[:30]:
            lines.append(f"- {err}")
        if len(stats.errors) > 30:
            lines.append(f"- ... and {len(stats.errors) - 30} more")
        lines.append("")

    append_report("Dishes import", lines)


def main() -> int:
    parser = argparse.ArgumentParser(description="Import Foodpanda dishes into PostgreSQL")
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("-v", "--verbose", action="store_true")
    args = parser.parse_args()

    setup_logging(verbose=args.verbose)

    try:
        stats = import_dishes(dry_run=args.dry_run)
    except Exception as exc:
        logger.exception("Dish import failed: %s", exc)
        write_report_header()
        append_report("Dishes import", [f"**Status:** FAILED", "", f"Error: {exc}", ""])
        return 1

    write_dishes_report(stats, dry_run=args.dry_run)

    category_count = len(getattr(stats, "categories_found", set()))
    print()
    print("Dish import complete" + (" (dry-run)" if args.dry_run else ""))
    print(f"  Inserted   : {stats.inserted}")
    print(f"  Skipped    : {stats.skipped}")
    print(f"  Categories : {category_count}")
    print(f"  Errors     : {len(stats.errors)}")

    return 0 if not stats.errors else 2


if __name__ == "__main__":
    sys.exit(main())
