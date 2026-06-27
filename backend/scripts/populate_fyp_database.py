#!/usr/bin/env python
"""Phase 9A (lightweight) — FYP database population for demo screens.

Usage:
  cd backend
  python scripts/populate_fyp_database.py --skip-import
  python scripts/populate_fyp_database.py --report-only
  python scripts/populate_fyp_database.py --only cleanup,restaurants,dishes,social,community
"""

from __future__ import annotations

import argparse
import sys
import time
from pathlib import Path

_BACKEND = Path(__file__).resolve().parent.parent
if str(_BACKEND) not in sys.path:
    sys.path.insert(0, str(_BACKEND))

if hasattr(sys.stdout, "reconfigure"):
    try:
        sys.stdout.reconfigure(line_buffering=True)
    except Exception:
        pass

from app.config import get_settings
from app.core.logging_config import setup_logging
from app.database import SessionLocal
from app.integrations.foodpanda.foodpanda_client import FoodpandaClient
from app.services.foodpanda_bulk.bulk_import import FoodpandaBulkImportRunner

from scripts.population.community_content import populate_community
from scripts.population.data_cleanup import cleanup_and_enrich
from scripts.population.dish_enrichment import enrich_dishes
from scripts.population.progress import log_done, log_step
from scripts.population.restaurant_enrichment import enrich_restaurants
from scripts.population.social_content import generate_social_content
from scripts.population.validation import build_fyp_report, build_report


def _run_import(*, limit: int | None, manifest: Path | None) -> None:
    settings = get_settings()
    default_manifest = settings.foodpanda_bulk_data_path / "lahore" / "latest" / "manifest.json"
    manifest_path = manifest or default_manifest
    if not manifest_path.exists():
        print(f"Manifest not found: {manifest_path}")
        return

    checkpoint_path = manifest_path.parent / "checkpoint.json"
    db = SessionLocal()
    try:
        with FoodpandaClient(settings) as client:
            runner = FoodpandaBulkImportRunner(
                db, client,
                chunk_size=settings.foodpanda_bulk_chunk_size,
                menu_delay_seconds=settings.foodpanda_bulk_menu_delay_seconds,
                skip_existing=True,
            )
            result = runner.run(
                manifest_path,
                checkpoint_path=checkpoint_path,
                resume=True,
                limit=limit,
            )
        cp = result.checkpoint
        print(f"  Import: {cp.status} | vendors +{cp.vendors_imported} | dishes +{cp.dishes_created}")
    finally:
        db.close()


def main() -> int:
    settings = get_settings()
    setup_logging(settings.log_level)

    parser = argparse.ArgumentParser(description="Phase 9A lightweight database population")
    parser.add_argument("--skip-import", action="store_true")
    parser.add_argument("--import-limit", type=int, default=None)
    parser.add_argument("--manifest", type=Path, default=None)
    parser.add_argument("--skip-cleanup", action="store_true")
    parser.add_argument("--skip-restaurants", action="store_true")
    parser.add_argument("--skip-dishes", action="store_true")
    parser.add_argument("--skip-social", action="store_true")
    parser.add_argument("--skip-community", action="store_true")
    parser.add_argument("--report-only", action="store_true")
    parser.add_argument(
        "--only",
        type=str,
        default=None,
        help="Comma-separated steps: cleanup,restaurants,dishes,social,community",
    )
    parser.add_argument("--seed", type=int, default=42)
    args = parser.parse_args()

    if args.report_only:
        db = SessionLocal()
        try:
            build_report(db).print_report()
        finally:
            db.close()
        return 0

    only = {s.strip() for s in args.only.split(",")} if args.only else None

    def run(name: str) -> bool:
        return only is None or name in only

    started = time.perf_counter()

    if not args.skip_import and run("import"):
        log_step("1/6 Foodpanda import")
        _run_import(limit=args.import_limit, manifest=args.manifest)

    db = SessionLocal()
    r_stats = None
    d_stats = None
    s_stats = None
    c_stats = None

    try:
        if not args.skip_cleanup and run("cleanup"):
            log_step("2/6 Placeholder cleanup")
            c = cleanup_and_enrich(db, seed=args.seed)
            log_done("Cleanup", removed_dishes=c.placeholder_dishes_removed, images=c.dishes_image_linked)

        if not args.skip_restaurants and run("restaurants"):
            log_step("3/6 Restaurant enrichment")
            r_stats = enrich_restaurants(db, seed=args.seed)
            log_done(
                "Restaurants",
                processed=r_stats.restaurants_processed,
                skipped=r_stats.restaurants_skipped,
                updated=r_stats.restaurants_updated,
            )

        if not args.skip_dishes and run("dishes"):
            log_step("4/6 Dish enrichment")
            d_stats = enrich_dishes(db, seed=args.seed)
            log_done("Dishes", updated=d_stats.dishes_updated, nutrition=d_stats.nutrition_filled)

        if not args.skip_social and run("social"):
            log_step("5/6 Social content (first 10 restaurants)")
            s_stats = generate_social_content(db, seed=args.seed)
            log_done(
                "Social",
                posts=s_stats.posts_created,
                stories=s_stats.stories_created,
                skipped=s_stats.restaurants_skipped,
            )

        if not args.skip_community and run("community"):
            log_step("6/6 Reviews and engagement")
            target_ids = s_stats.target_restaurant_ids if s_stats else None
            c_stats = populate_community(db, restaurant_ids=target_ids, seed=args.seed)
            log_done(
                "Community",
                reviews=c_stats.reviews_created,
                likes=c_stats.likes_created,
                comments=c_stats.comments_created,
                saves=c_stats.saves_created,
            )

        elapsed = time.perf_counter() - started
        build_fyp_report(
            db,
            restaurants_processed=r_stats.restaurants_processed if r_stats else 0,
            restaurants_skipped=r_stats.restaurants_skipped if r_stats else 0,
            dishes_updated=d_stats.dishes_updated if d_stats else 0,
            posts_created=s_stats.posts_created if s_stats else 0,
            stories_created=s_stats.stories_created if s_stats else 0,
            reviews_created=c_stats.reviews_created if c_stats else 0,
            likes_created=c_stats.likes_created if c_stats else 0,
            comments_created=c_stats.comments_created if c_stats else 0,
            saves_created=c_stats.saves_created if c_stats else 0,
            execution_seconds=elapsed,
        ).print_report()
    finally:
        db.close()

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
