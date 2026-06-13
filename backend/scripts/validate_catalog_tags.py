#!/usr/bin/env python
"""Validate catalog tag coverage, restaurant inference, and confidence levels."""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

_BACKEND = Path(__file__).resolve().parent.parent
if str(_BACKEND) not in sys.path:
    sys.path.insert(0, str(_BACKEND))

from app.database import SessionLocal
from app.services.catalog_enrichment_service import CatalogEnrichmentService


def _pct(numerator: int, denominator: int) -> float:
    return round(100 * numerator / denominator, 1) if denominator else 0.0


def main() -> int:
    parser = argparse.ArgumentParser(description="Validate catalog tags and restaurant inference")
    parser.add_argument(
        "--apply-inference",
        action="store_true",
        help="Persist inferred restaurant tags for untagged Foodpanda restaurants",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="With --apply-inference, compute without persisting",
    )
    args = parser.parse_args()

    db = SessionLocal()
    try:
        service = CatalogEnrichmentService()

        if args.apply_inference:
            stats = service.infer_untagged_restaurant_tags(
                db,
                dry_run=args.dry_run,
                source="foodpanda",
            )
            before = stats.coverage_before
            after = stats.coverage_after
            print("=== Restaurant inference enrichment ===")
            print(f"  dry_run: {stats.dry_run}")
            print(f"  restaurants_inferred: {stats.restaurants_inferred}")
            print(f"  restaurants_updated: {stats.restaurants_updated}")
            print(
                f"  foodpanda coverage: "
                f"{before.foodpanda_restaurants_with_tags}/{before.foodpanda_restaurants} "
                f"({_pct(before.foodpanda_restaurants_with_tags, before.foodpanda_restaurants)}%) "
                f"-> "
                f"{after.foodpanda_restaurants_with_tags}/{after.foodpanda_restaurants} "
                f"({_pct(after.foodpanda_restaurants_with_tags, after.foodpanda_restaurants)}%)"
            )
            if stats.inference_samples:
                print("\n=== Inferred restaurants (sample) ===")
                for row in stats.inference_samples[:15]:
                    print(
                        f"  id={row['restaurant_id']} "
                        f"confidence={row['confidence']:.2f} "
                        f"tags={row['inferred_tags']} "
                        f"name={row['name']!r}"
                    )
            print("\n=== JSON ===")
            print(json.dumps(stats.to_dict(), indent=2))
            return 0

        report = service.inference_validation_report(db)
        coverage = report["coverage_before"]

        print("=== Tag coverage (current) ===")
        for key, value in coverage.items():
            print(f"  {key}: {value}")
        print(
            f"  foodpanda_restaurant_coverage_pct: "
            f"{report['foodpanda_coverage_pct_before']}%"
        )

        print("\n=== Inference projection (untagged restaurants) ===")
        print(f"  untagged_foodpanda_restaurants: {report['untagged_foodpanda_restaurants']}")
        print(f"  would_infer_tags: {report['would_infer_tags']}")
        print(f"  still_untagged_after_inference: {report['still_untagged_after_inference']}")
        print(
            f"  projected_foodpanda_coverage_pct: "
            f"{report['foodpanda_coverage_pct_after_projected']}%"
        )

        print("\n=== Inferred tags & confidence (sample) ===")
        for row in report["inferences"][:20]:
            if row["inferred_tags"]:
                print(
                    f"  id={row['restaurant_id']} "
                    f"confidence={row['confidence']:.2f} "
                    f"tags={row['inferred_tags']} "
                    f"dishes={row['dish_count']} "
                    f"name={row['name']!r}"
                )
            else:
                print(
                    f"  id={row['restaurant_id']} NO_INFERENCE "
                    f"dishes={row['dish_count']} name={row['name']!r}"
                )

        tag_report = service.tag_report(db)
        print("\n=== Top restaurant tags ===")
        for row in tag_report["top_restaurant_tags"][:10]:
            print(f"  {row['tag']}: {row['count']}")

        print("\n=== JSON ===")
        print(json.dumps(report, indent=2))
        return 0
    finally:
        db.close()


if __name__ == "__main__":
    raise SystemExit(main())
