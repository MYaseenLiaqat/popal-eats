#!/usr/bin/env python
"""Discover Lahore Foodpanda vendors and write a deduplicated manifest."""

from __future__ import annotations

import argparse
import sys
from pathlib import Path

# Allow running as: python scripts/foodpanda_discover_lahore.py
_BACKEND = Path(__file__).resolve().parent.parent
if str(_BACKEND) not in sys.path:
    sys.path.insert(0, str(_BACKEND))

from app.config import get_settings
from app.core.logging_config import setup_logging
from app.integrations.foodpanda.foodpanda_client import FoodpandaClient
from app.services.foodpanda_bulk.discovery import FoodpandaDiscoveryJob


def main() -> int:
    settings = get_settings()
    setup_logging(settings.log_level)

    parser = argparse.ArgumentParser(description="Discover Lahore Foodpanda vendors")
    parser.add_argument(
        "--output-dir",
        type=Path,
        default=None,
        help="Directory for manifest.json / manifest.jsonl",
    )
    parser.add_argument("--latitude", type=float, default=settings.foodpanda_lahore_latitude)
    parser.add_argument("--longitude", type=float, default=settings.foodpanda_lahore_longitude)
    parser.add_argument("--page-limit", type=int, default=settings.foodpanda_bulk_page_limit)
    parser.add_argument("--no-gap-fill", action="store_true", help="Skip suburban anchor scan")
    parser.add_argument("--run-id", type=str, default=None)
    args = parser.parse_args()

    output_dir = args.output_dir or (settings.foodpanda_bulk_data_path / "lahore" / "latest")
    if args.run_id:
        output_dir = settings.foodpanda_bulk_data_path / "lahore" / args.run_id

    with FoodpandaClient(settings) as client:
        job = FoodpandaDiscoveryJob(
            client,
            page_limit=args.page_limit,
            search_delay_seconds=settings.foodpanda_bulk_search_delay_seconds,
        )
        result = job.discover_lahore(
            output_dir=output_dir,
            latitude=args.latitude,
            longitude=args.longitude,
            run_id=args.run_id,
            gap_fill=not args.no_gap_fill,
        )

    print(f"Discovered {result.manifest.vendors_discovered} vendors")
    print(f"Manifest: {result.manifest_json_path}")
    print(f"JSONL:    {result.manifest_jsonl_path}")
    if result.errors:
        print(f"Errors:   {len(result.errors)}")
        for err in result.errors[:5]:
            print(f"  - {err}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
