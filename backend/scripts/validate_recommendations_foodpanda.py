#!/usr/bin/env python
"""Validate that Foodpanda-imported dishes appear in recommendation candidate pools."""

from __future__ import annotations

import sys
from pathlib import Path

_BACKEND = Path(__file__).resolve().parent.parent
if str(_BACKEND) not in sys.path:
    sys.path.insert(0, str(_BACKEND))

from app.core.logging_config import setup_logging
from app.database import SessionLocal
from app.models.dish import Dish
from app.models.restaurant import Restaurant
from app.models.user import User
from app.services.recommendation.v2_catalog import (
    FOODPANDA_SOURCE,
    get_catalog_stats,
    get_candidate_pool_stats,
    load_tag_maps,
)
from app.services.recommendation.v2_content import get_content_recommendations
from app.services.recommendation.v2_hybrid import get_hybrid_recommendations


def _dish_source(db, dish_id: int) -> str | None:
    dish = db.get(Dish, dish_id)
    return dish.source if dish else None


def main() -> int:
    setup_logging("INFO")
    db = SessionLocal()
    failures: list[str] = []

    try:
        stats = get_catalog_stats(db)
        pool = get_candidate_pool_stats(db)
        print("=== Catalog stats ===")
        for key, value in stats.items():
            print(f"  {key}: {value}")
        print("=== Candidate pool ===")
        for key, value in pool.items():
            print(f"  {key}: {value}")

        if stats["foodpanda_dishes"] == 0:
            failures.append("No Foodpanda dishes in database")
        if pool["foodpanda_candidates"] == 0 and stats["foodpanda_dishes"] > 0:
            failures.append(
                "Foodpanda dishes exist but none are eligible candidates "
                "(check is_available / restaurant.is_open / placeholder names)"
            )

        _, restaurant_tags = load_tag_maps(db)
        fp_with_tags = sum(
            1
            for rid, tags in restaurant_tags.items()
            if tags
            and db.query(Restaurant.id)
            .filter(Restaurant.id == rid, Restaurant.source == FOODPANDA_SOURCE)
            .first()
        )
        print(f"  foodpanda_restaurants_with_cuisine_tags: {fp_with_tags}")

        user = db.query(User).order_by(User.id).first()
        if not user:
            failures.append("No users in database — cannot test personalized recommendations")
            print("\nFAIL")
            for msg in failures:
                print(f"  - {msg}")
            return 1

        print(f"\n=== Recommendations for user_id={user.id} ===")
        content = get_content_recommendations(db, user.id, limit=10)
        hybrid = get_hybrid_recommendations(db, user.id, limit=10)

        content_fp_ids = {
            item.dish_id for item in content if _dish_source(db, item.dish_id) == FOODPANDA_SOURCE
        }
        hybrid_fp_ids = {
            item.dish_id for item in hybrid if _dish_source(db, item.dish_id) == FOODPANDA_SOURCE
        }

        print(f"  content results: {len(content)} (foodpanda: {len(content_fp_ids)})")
        print(f"  hybrid results:  {len(hybrid)} (foodpanda: {len(hybrid_fp_ids)})")

        if pool["foodpanda_candidates"] > 0 and not content_fp_ids and not hybrid_fp_ids:
            failures.append(
                "Foodpanda dishes are in candidate pool but none ranked in top 10 "
                "(may need matching user_preferences favorite_cuisines)"
            )

        if content_fp_ids or hybrid_fp_ids:
            sample_id = next(iter(content_fp_ids or hybrid_fp_ids))
            dish = db.get(Dish, sample_id)
            print(f"  sample foodpanda dish in results: id={sample_id} name={dish.name!r}")

        if failures:
            print("\nWARNINGS / FAILURES")
            for msg in failures:
                print(f"  - {msg}")
            hard_fail = any(
                "No Foodpanda" in f or "none are eligible" in f or "No users" in f for f in failures
            )
            return 1 if hard_fail else 0

        print("\nOK — Foodpanda catalog is integrated into recommendation candidates")
        return 0
    finally:
        db.close()


if __name__ == "__main__":
    raise SystemExit(main())
