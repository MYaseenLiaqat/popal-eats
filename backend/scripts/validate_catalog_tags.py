#!/usr/bin/env python
"""Validate catalog tag coverage and report top/missing tags."""

from __future__ import annotations

import json
import sys
from pathlib import Path

_BACKEND = Path(__file__).resolve().parent.parent
if str(_BACKEND) not in sys.path:
    sys.path.insert(0, str(_BACKEND))

from app.database import SessionLocal
from app.services.catalog_enrichment_service import CatalogEnrichmentService


def main() -> int:
    db = SessionLocal()
    try:
        service = CatalogEnrichmentService()
        report = service.tag_report(db)
        coverage = report["coverage"]

        print("=== Tag coverage ===")
        for key, value in coverage.items():
            print(f"  {key}: {value}")

        print("\n=== Top restaurant tags ===")
        for row in report["top_restaurant_tags"][:15]:
            print(f"  {row['tag']}: {row['count']}")

        print("\n=== Top dish tags ===")
        for row in report["top_dish_tags"][:15]:
            print(f"  {row['tag']}: {row['count']}")

        missing = report["missing_tags"]
        print(f"\n=== Missing tags ===")
        print(f"  foodpanda_dishes_without_tags: {missing['foodpanda_dishes_without_tags']}")
        if missing["foodpanda_restaurants_sample"]:
            print("  sample restaurants without tags:")
            for row in missing["foodpanda_restaurants_sample"][:5]:
                print(f"    id={row['id']} name={row['name']!r}")

        print("\n=== JSON ===")
        print(json.dumps(report, indent=2))
        return 0
    finally:
        db.close()


if __name__ == "__main__":
    raise SystemExit(main())
