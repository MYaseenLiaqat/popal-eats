"""Catalog tag enrichment for imported and manual restaurants/dishes."""

from __future__ import annotations

import logging
from collections import Counter
from dataclasses import asdict, dataclass, field
from typing import Any

from sqlalchemy import func
from sqlalchemy.orm import Session, joinedload

from app.models.dish import Dish
from app.models.restaurant import Restaurant
from app.services.catalog.tag_normalization import (
    extract_keyword_tags,
    normalize_tag,
    normalize_tags,
)
from app.services.recommendation.v2_catalog import cuisines_from_description

logger = logging.getLogger(__name__)

FOODPANDA_SOURCE = "foodpanda"


def _has_nonempty_tags(tags: Any) -> bool:
    return isinstance(tags, list) and len(tags) > 0


@dataclass
class TagCoverageStats:
    total_restaurants: int = 0
    restaurants_with_tags: int = 0
    foodpanda_restaurants: int = 0
    foodpanda_restaurants_with_tags: int = 0
    total_dishes: int = 0
    dishes_with_tags: int = 0
    foodpanda_dishes: int = 0
    foodpanda_dishes_with_tags: int = 0

    def to_dict(self) -> dict[str, int]:
        return asdict(self)


@dataclass
class EnrichmentStats:
    dry_run: bool = False
    source: str = FOODPANDA_SOURCE
    limit: int | None = None
    restaurants_processed: int = 0
    restaurants_updated: int = 0
    dishes_processed: int = 0
    dishes_updated: int = 0
    coverage_before: TagCoverageStats = field(default_factory=TagCoverageStats)
    coverage_after: TagCoverageStats = field(default_factory=TagCoverageStats)
    top_tags_restaurants: list[dict[str, Any]] = field(default_factory=list)
    top_tags_dishes: list[dict[str, Any]] = field(default_factory=list)
    errors: list[str] = field(default_factory=list)

    def to_dict(self) -> dict[str, Any]:
        payload = asdict(self)
        payload["coverage_before"] = self.coverage_before.to_dict()
        payload["coverage_after"] = self.coverage_after.to_dict()
        return payload


class CatalogEnrichmentService:
    """Derive and persist normalized tags without changing import pipeline behavior."""

    def audit_coverage(self, db: Session) -> TagCoverageStats:
        stats = TagCoverageStats(
            total_restaurants=int(db.query(func.count(Restaurant.id)).scalar() or 0),
            total_dishes=int(db.query(func.count(Dish.id)).scalar() or 0),
            foodpanda_restaurants=int(
                db.query(func.count(Restaurant.id))
                .filter(Restaurant.source == FOODPANDA_SOURCE)
                .scalar()
                or 0
            ),
            foodpanda_dishes=int(
                db.query(func.count(Dish.id)).filter(Dish.source == FOODPANDA_SOURCE).scalar() or 0
            ),
        )

        for _id, tags, source in db.query(Restaurant.id, Restaurant.tags, Restaurant.source).all():
            if _has_nonempty_tags(tags):
                stats.restaurants_with_tags += 1
                if source == FOODPANDA_SOURCE:
                    stats.foodpanda_restaurants_with_tags += 1

        for _id, tags, source in db.query(Dish.id, Dish.tags, Dish.source).all():
            if _has_nonempty_tags(tags):
                stats.dishes_with_tags += 1
                if source == FOODPANDA_SOURCE:
                    stats.foodpanda_dishes_with_tags += 1

        return stats

    def enrich(
        self,
        db: Session,
        *,
        dry_run: bool = False,
        source: str = FOODPANDA_SOURCE,
        limit: int | None = None,
    ) -> EnrichmentStats:
        stats = EnrichmentStats(dry_run=dry_run, source=source, limit=limit)
        stats.coverage_before = self.audit_coverage(db)

        restaurant_query = db.query(Restaurant).filter(Restaurant.source == source)
        if limit is not None:
            restaurant_query = restaurant_query.order_by(Restaurant.id).limit(limit)
        restaurants = restaurant_query.all()
        restaurant_ids = [r.id for r in restaurants]

        dishes_by_restaurant: dict[int, list[Dish]] = {rid: [] for rid in restaurant_ids}
        if restaurant_ids:
            all_dishes = (
                db.query(Dish)
                .options(joinedload(Dish.category))
                .filter(Dish.restaurant_id.in_(restaurant_ids))
                .all()
            )
            for dish in all_dishes:
                dishes_by_restaurant.setdefault(dish.restaurant_id, []).append(dish)

        restaurant_tag_counter: Counter[str] = Counter()
        dish_tag_counter: Counter[str] = Counter()
        projected_restaurants_with_tags = stats.coverage_before.restaurants_with_tags
        projected_fp_restaurants_with_tags = stats.coverage_before.foodpanda_restaurants_with_tags
        projected_dishes_with_tags = stats.coverage_before.dishes_with_tags
        projected_fp_dishes_with_tags = stats.coverage_before.foodpanda_dishes_with_tags

        for restaurant in restaurants:
            stats.restaurants_processed += 1
            had_tags = _has_nonempty_tags(restaurant.tags)
            new_tags = self.derive_restaurant_tags(restaurant)
            restaurant_tag_counter.update(new_tags)
            if new_tags != (restaurant.tags or []):
                stats.restaurants_updated += 1
                if not dry_run:
                    restaurant.tags = new_tags
            if new_tags and not had_tags:
                projected_restaurants_with_tags += 1
                if restaurant.source == source:
                    projected_fp_restaurants_with_tags += 1

            dishes = dishes_by_restaurant.get(restaurant.id, [])
            for dish in dishes:
                stats.dishes_processed += 1
                had_dish_tags = _has_nonempty_tags(dish.tags)
                new_dish_tags = self.derive_dish_tags(dish, restaurant_tags=new_tags)
                dish_tag_counter.update(new_dish_tags)
                if new_dish_tags != (dish.tags or []):
                    stats.dishes_updated += 1
                    if not dry_run:
                        dish.tags = new_dish_tags
                if new_dish_tags and not had_dish_tags:
                    projected_dishes_with_tags += 1
                    if dish.source == source:
                        projected_fp_dishes_with_tags += 1

        if not dry_run:
            db.commit()
            stats.coverage_after = self.audit_coverage(db)
        else:
            db.rollback()
            stats.coverage_after = TagCoverageStats(
                total_restaurants=stats.coverage_before.total_restaurants,
                restaurants_with_tags=projected_restaurants_with_tags,
                foodpanda_restaurants=stats.coverage_before.foodpanda_restaurants,
                foodpanda_restaurants_with_tags=projected_fp_restaurants_with_tags,
                total_dishes=stats.coverage_before.total_dishes,
                dishes_with_tags=projected_dishes_with_tags,
                foodpanda_dishes=stats.coverage_before.foodpanda_dishes,
                foodpanda_dishes_with_tags=projected_fp_dishes_with_tags,
            )
        stats.top_tags_restaurants = [
            {"tag": tag, "count": count} for tag, count in restaurant_tag_counter.most_common(20)
        ]
        stats.top_tags_dishes = [
            {"tag": tag, "count": count} for tag, count in dish_tag_counter.most_common(20)
        ]

        logger.info(
            "Catalog enrichment dry_run=%s source=%s restaurants_updated=%d dishes_updated=%d",
            dry_run,
            source,
            stats.restaurants_updated,
            stats.dishes_updated,
        )
        return stats

    @staticmethod
    def derive_restaurant_tags(restaurant: Restaurant) -> list[str]:
        raw_sources: list[str] = []

        if isinstance(restaurant.tags, list):
            raw_sources.extend(str(t) for t in restaurant.tags)

        raw_sources.extend(cuisines_from_description(restaurant.description))
        raw_sources.extend(extract_keyword_tags(restaurant.name))

        return normalize_tags(raw_sources)

    @staticmethod
    def derive_dish_tags(dish: Dish, *, restaurant_tags: list[str] | None = None) -> list[str]:
        raw_sources: list[str] = []

        if isinstance(dish.tags, list):
            raw_sources.extend(str(t) for t in dish.tags)

        if dish.category and dish.category.name:
            raw_sources.append(dish.category.name)

        raw_sources.extend(extract_keyword_tags(dish.name, dish.description))

        # Inherit high-level cuisine tags from restaurant (limit to 5 to avoid noise).
        if restaurant_tags:
            raw_sources.extend(restaurant_tags[:5])

        return normalize_tags(raw_sources)

    def tag_report(self, db: Session, *, top_n: int = 25) -> dict[str, Any]:
        """Coverage summary, top tags, and entities missing tags."""
        coverage = self.audit_coverage(db)
        restaurant_tags: Counter[str] = Counter()
        dish_tags: Counter[str] = Counter()
        missing_restaurants: list[dict[str, Any]] = []
        missing_dishes = 0

        for restaurant in db.query(Restaurant).filter(Restaurant.source == FOODPANDA_SOURCE).all():
            tags = restaurant.tags if _has_nonempty_tags(restaurant.tags) else []
            if tags:
                restaurant_tags.update(tags)
            elif len(missing_restaurants) < 20:
                missing_restaurants.append(
                    {"id": restaurant.id, "name": restaurant.name, "reason": "no_tags"}
                )

        for dish in (
            db.query(Dish)
            .filter(Dish.source == FOODPANDA_SOURCE)
            .options(joinedload(Dish.category))
            .all()
        ):
            if _has_nonempty_tags(dish.tags):
                dish_tags.update(dish.tags)
            else:
                missing_dishes += 1

        return {
            "coverage": coverage.to_dict(),
            "top_restaurant_tags": [
                {"tag": t, "count": c} for t, c in restaurant_tags.most_common(top_n)
            ],
            "top_dish_tags": [{"tag": t, "count": c} for t, c in dish_tags.most_common(top_n)],
            "missing_tags": {
                "foodpanda_restaurants_sample": missing_restaurants,
                "foodpanda_dishes_without_tags": missing_dishes,
            },
        }
