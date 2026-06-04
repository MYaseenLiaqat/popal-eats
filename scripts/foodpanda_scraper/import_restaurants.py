"""
Import Foodpanda restaurants from output/restaurants.xlsx into PostgreSQL.

Usage:
  python import_restaurants.py
  python import_restaurants.py --dry-run

Run from repo root with backend dependencies:
  backend\\venv\\Scripts\\python.exe scripts\\foodpanda_scraper\\import_restaurants.py
"""

from __future__ import annotations

import argparse
import json
import logging
import sys
from typing import Any

import pandas as pd

from import_common import (
    BATCH_SIZE,
    IMPORT_MAP_JSON,
    OUTPUT_DIR,
    RESTAURANTS_EXCEL,
    ImportStats,
    append_report,
    build_restaurant_description,
    find_existing_restaurant_id,
    get_session,
    load_backend_env,
    load_existing_restaurant_indexes,
    normalize_name,
    parse_city,
    parse_decimal,
    resolve_import_owner_id,
    setup_backend_path,
    setup_logging,
    write_report_header,
)

logger = logging.getLogger(__name__)


def _safe_bool(value: object, default: bool = True) -> bool:
    if value is None or (isinstance(value, float) and str(value) == "nan"):
        return default
    if isinstance(value, bool):
        return value
    return str(value).strip().lower() in {"1", "true", "yes", "y"}


def _safe_int(value: object, default: int = 0) -> int:
    if value is None or (isinstance(value, float) and str(value) == "nan"):
        return default
    try:
        return int(float(value))
    except (TypeError, ValueError):
        return default


def load_restaurants_excel(path: Any) -> pd.DataFrame:
    if not path.is_file():
        raise FileNotFoundError(f"Missing {path}. Run vendor_scraper.py first.")
    df = pd.read_excel(path)
    required = {"vendor_code", "vendor_name"}
    missing = required - set(df.columns)
    if missing:
        raise ValueError(f"restaurants.xlsx missing columns: {sorted(missing)}")
    return df


def import_restaurants(*, dry_run: bool = False) -> tuple[ImportStats, dict[str, int]]:
    setup_backend_path()
    load_backend_env()

    from app.models.restaurant import Restaurant

    df = load_restaurants_excel(RESTAURANTS_EXCEL)
    stats = ImportStats()
    vendor_map: dict[str, int] = {}
    pending = 0

    session = get_session()
    try:
        owner_id = resolve_import_owner_id(session, dry_run=dry_run)
        by_name, by_vendor_code = load_existing_restaurant_indexes(session)

        for _, row in df.iterrows():
            vendor_code = str(row["vendor_code"]).strip()
            vendor_name = str(row["vendor_name"]).strip()
            if not vendor_code or not vendor_name:
                stats.skipped += 1
                stats.add_error(f"Skipped row with missing code/name: {row.to_dict()}")
                continue

            existing_id = find_existing_restaurant_id(
                by_name,
                by_vendor_code,
                vendor_code=vendor_code,
                vendor_name=vendor_name,
            )
            if existing_id:
                stats.skipped += 1
                vendor_map[vendor_code] = existing_id
                logger.debug(
                    "Skip duplicate %s (%s) -> restaurant id=%s",
                    vendor_name,
                    vendor_code,
                    existing_id,
                )
                continue

            vendor_id = str(row.get("vendor_id", "")).strip()
            cuisines = row.get("cuisines")
            url_key = str(row.get("url_key", "")).strip() if pd.notna(row.get("url_key")) else ""

            description = build_restaurant_description(
                vendor_code=vendor_code,
                vendor_id=vendor_id,
                cuisines=str(cuisines) if pd.notna(cuisines) else None,
                url_key=url_key or None,
            )

            rating = row.get("rating")
            review_count = row.get("review_count")

            restaurant = Restaurant(
                owner_id=owner_id,
                name=vendor_name[:200],
                description=description,
                address=(
                    str(row["address"])[:300]
                    if pd.notna(row.get("address"))
                    else None
                ),
                city=parse_city(row.get("city")),
                is_open=_safe_bool(row.get("is_open"), default=True),
                average_rating=float(rating) if pd.notna(rating) else 0.0,
                total_reviews=_safe_int(review_count, 0),
            )

            if dry_run:
                stats.inserted += 1
                vendor_map[vendor_code] = -1
                logger.info("[dry-run] Would insert: %s (%s)", vendor_name, vendor_code)
                by_name[normalize_name(vendor_name)] = -1
                by_vendor_code[vendor_code.lower()] = -1
                continue

            session.add(restaurant)
            pending += 1
            stats.inserted += 1

            try:
                session.flush()
                vendor_map[vendor_code] = restaurant.id
                by_name[normalize_name(vendor_name)] = restaurant.id
                by_vendor_code[vendor_code.lower()] = restaurant.id
                logger.info(
                    "Inserted restaurant id=%s %s (%s)",
                    restaurant.id,
                    vendor_name,
                    vendor_code,
                )
            except Exception as exc:
                session.rollback()
                stats.inserted -= 1
                pending = 0
                stats.add_error(f"Failed {vendor_name} ({vendor_code}): {exc}")
                by_name, by_vendor_code = load_existing_restaurant_indexes(session)
                continue

            if pending >= BATCH_SIZE:
                session.commit()
                logger.info("Committed batch (%d restaurants)", pending)
                pending = 0

        if not dry_run:
            if pending:
                session.commit()
                logger.info("Committed final batch (%d restaurants)", pending)
        else:
            session.rollback()

    except Exception:
        session.rollback()
        raise
    finally:
        session.close()

    if not dry_run and vendor_map:
        OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
        map_path = IMPORT_MAP_JSON
        # Only real ids
        serializable = {k: v for k, v in vendor_map.items() if v > 0}
        map_path.write_text(json.dumps(serializable, indent=2), encoding="utf-8")
        logger.info("Wrote vendor map -> %s", map_path)

    return stats, vendor_map


def write_restaurants_report(stats: ImportStats, *, dry_run: bool) -> None:
    write_report_header()
    lines = [
        f"**Mode:** {'dry-run' if dry_run else 'live'}",
        "",
        "| Metric | Count |",
        "|--------|------:|",
        f"| Restaurants inserted | {stats.inserted} |",
        f"| Restaurants skipped | {stats.skipped} |",
        f"| Errors | {len(stats.errors)} |",
        "",
    ]
    if stats.errors:
        lines.append("### Errors")
        lines.append("")
        for err in stats.errors[:50]:
            lines.append(f"- {err}")
        if len(stats.errors) > 50:
            lines.append(f"- ... and {len(stats.errors) - 50} more")
        lines.append("")

    append_report("Restaurants import", lines)


def main() -> int:
    parser = argparse.ArgumentParser(description="Import Foodpanda restaurants into PostgreSQL")
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Simulate import without committing changes",
    )
    parser.add_argument("-v", "--verbose", action="store_true")
    args = parser.parse_args()

    setup_logging(verbose=args.verbose)

    try:
        stats, _ = import_restaurants(dry_run=args.dry_run)
    except Exception as exc:
        logger.exception("Restaurant import failed: %s", exc)
        write_report_header()
        append_report(
            "Restaurants import",
            [f"**Status:** FAILED", "", f"Error: {exc}", ""],
        )
        return 1

    write_restaurants_report(stats, dry_run=args.dry_run)

    print()
    print("Restaurant import complete" + (" (dry-run)" if args.dry_run else ""))
    print(f"  Inserted : {stats.inserted}")
    print(f"  Skipped  : {stats.skipped}")
    print(f"  Errors   : {len(stats.errors)}")

    return 0 if not stats.errors else 2


if __name__ == "__main__":
    sys.exit(main())
