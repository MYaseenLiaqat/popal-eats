#!/usr/bin/env python
"""Import Lahore Foodpanda vendors from a discovery manifest in chunks."""

from __future__ import annotations

import argparse
import sys
from pathlib import Path

_BACKEND = Path(__file__).resolve().parent.parent
if str(_BACKEND) not in sys.path:
    sys.path.insert(0, str(_BACKEND))

from app.config import get_settings
from app.core.logging_config import setup_logging
from app.database import SessionLocal
from app.integrations.foodpanda.foodpanda_client import FoodpandaClient
from app.services.foodpanda_bulk.bulk_import import FoodpandaBulkImportRunner


def main() -> int:
    settings = get_settings()
    setup_logging(settings.log_level)

    default_manifest = settings.foodpanda_bulk_data_path / "lahore" / "latest" / "manifest.json"

    parser = argparse.ArgumentParser(description="Chunked Lahore Foodpanda menu import")
    parser.add_argument("--manifest", type=Path, default=default_manifest)
    parser.add_argument("--checkpoint", type=Path, default=None)
    parser.add_argument("--chunk-size", type=int, default=settings.foodpanda_bulk_chunk_size)
    parser.add_argument("--menu-delay", type=float, default=settings.foodpanda_bulk_menu_delay_seconds)
    parser.add_argument("--no-resume", action="store_true", help="Start fresh (ignore checkpoint)")
    parser.add_argument(
        "--reimport-existing",
        action="store_true",
        help="Re-import vendors already in DB (updates menus)",
    )
    parser.add_argument(
        "--limit",
        type=int,
        default=None,
        metavar="N",
        help="Import only the first N vendors from the manifest",
    )
    args = parser.parse_args()

    if args.limit is not None and args.limit < 1:
        print("--limit must be a positive integer", file=sys.stderr)
        return 1

    if not args.manifest.exists():
        print(f"Manifest not found: {args.manifest}", file=sys.stderr)
        print("Run: python scripts/foodpanda_discover_lahore.py", file=sys.stderr)
        return 1

    checkpoint_path = args.checkpoint or args.manifest.parent / "checkpoint.json"

    db = SessionLocal()
    try:
        with FoodpandaClient(settings) as client:
            runner = FoodpandaBulkImportRunner(
                db,
                client,
                chunk_size=args.chunk_size,
                menu_delay_seconds=args.menu_delay,
                skip_existing=not args.reimport_existing,
            )
            result = runner.run(
                args.manifest,
                checkpoint_path=checkpoint_path,
                resume=not args.no_resume,
                limit=args.limit,
            )
    finally:
        db.close()

    cp = result.checkpoint
    print(f"Status:            {cp.status}")
    if cp.vendor_limit is not None:
        print(f"Vendor limit:      {cp.vendor_limit}")
    print(f"vendors_imported:  {cp.vendors_imported}")
    print(f"vendors_failed:    {cp.vendors_failed}")
    print(f"vendors_skipped:   {cp.vendors_skipped}")
    print(f"dishes_created:    {cp.dishes_created}")
    print(f"dishes_updated:    {cp.dishes_updated}")
    print(f"categories_created:{cp.categories_created}")
    print(f"Checkpoint:        {result.checkpoint_path}")
    if result.errors:
        print(f"Errors ({len(result.errors)}):")
        for err in result.errors[:10]:
            print(f"  - {err}")
    return 0 if cp.vendors_failed == 0 else 1


if __name__ == "__main__":
    raise SystemExit(main())
