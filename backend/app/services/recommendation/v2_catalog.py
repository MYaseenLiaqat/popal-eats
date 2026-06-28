"""
Recommendation Engine V2 — catalog integration for imported and manual data.

Unifies tag loading from ORM columns and Foodpanda description metadata so
content scoring treats imported restaurants like manually-created ones.
"""

from __future__ import annotations

import logging
from typing import Any

from sqlalchemy import func
from sqlalchemy.orm import Session, joinedload

from app.models.category import Category
from app.models.dish import Dish
from app.models.restaurant import Restaurant
from app.services.recommendation.cuisine_classifier import cuisine_tags_for_dish

logger = logging.getLogger("popal.recommendations.v2")

FOODPANDA_SOURCE = "foodpanda"


def _normalize_tags(raw: Any) -> list[str]:
    if not raw:
        return []
    if isinstance(raw, list):
        return [str(t).strip().lower() for t in raw if t and str(t).strip()]
    return []


def cuisines_from_description(description: str | None) -> list[str]:
    """Parse 'Cuisines: a, b' lines from Foodpanda import descriptions."""
    if not description:
        return []
    for line in description.splitlines():
        stripped = line.strip()
        if stripped.startswith("Cuisines:"):
            payload = stripped.split(":", 1)[1]
            return [part.strip().lower() for part in payload.split(",") if part.strip()]
    return []


def load_tag_maps(db: Session) -> tuple[dict[int, list[str]], dict[int, list[str]]]:
    """
    Load dish and restaurant tag maps from ORM JSON columns.

    Falls back to cuisines parsed from restaurant description when tags are empty
    (common for Foodpanda imports before tag backfill).
    """
    dish_tags: dict[int, list[str]] = {}
    restaurant_tags: dict[int, list[str]] = {}

    restaurants = db.query(Restaurant).all()
    for restaurant in restaurants:
        tags = _normalize_tags(restaurant.tags)
        if not tags:
            tags = cuisines_from_description(restaurant.description)
        if tags:
            restaurant_tags[restaurant.id] = tags

    dishes = db.query(Dish).options(joinedload(Dish.category)).all()
    for dish in dishes:
        tags = _normalize_tags(dish.tags)
        if not tags and dish.category and dish.category.name:
            tags = [dish.category.name.strip().lower()]
        if tags:
            dish_tags[dish.id] = tags

    return dish_tags, restaurant_tags


def build_tag_maps_from_dishes(
    dishes: list[Dish],
) -> tuple[dict[int, list[str]], dict[int, list[str]]]:
    """
    Build tag maps from already-loaded Dish rows (no extra DB round-trip).

    Use in group recommendations after ``load_eligible_dishes`` which eager-loads
    restaurant + category.
    """
    dish_tags: dict[int, list[str]] = {}
    restaurant_tags: dict[int, list[str]] = {}

    for dish in dishes:
        tags = _normalize_tags(dish.tags)
        if not tags and dish.category and dish.category.name:
            tags = [dish.category.name.strip().lower()]
        for cuisine_tag in cuisine_tags_for_dish(dish):
            if cuisine_tag not in tags:
                tags.append(cuisine_tag)
        if tags:
            dish_tags[dish.id] = tags

        restaurant = dish.restaurant
        if restaurant is None or restaurant.id in restaurant_tags:
            continue
        rtags = _normalize_tags(restaurant.tags)
        if not rtags:
            rtags = cuisines_from_description(restaurant.description)
        if rtags:
            restaurant_tags[restaurant.id] = rtags

    return dish_tags, restaurant_tags


def get_catalog_stats(db: Session) -> dict[str, int]:
    """Aggregate restaurant/dish counts including Foodpanda imports."""
    total_restaurants = db.query(func.count(Restaurant.id)).scalar() or 0
    total_dishes = db.query(func.count(Dish.id)).scalar() or 0
    foodpanda_restaurants = (
        db.query(func.count(Restaurant.id))
        .filter(Restaurant.source == FOODPANDA_SOURCE)
        .scalar()
        or 0
    )
    foodpanda_dishes = (
        db.query(func.count(Dish.id)).filter(Dish.source == FOODPANDA_SOURCE).scalar() or 0
    )
    return {
        "total_restaurants": int(total_restaurants),
        "total_dishes": int(total_dishes),
        "foodpanda_restaurants": int(foodpanda_restaurants),
        "foodpanda_dishes": int(foodpanda_dishes),
    }


def get_candidate_pool_stats(db: Session, *, user_id: int | None = None) -> dict[str, int]:
    """Eligible recommendation candidates and Foodpanda share."""
    from app.services.recommendation.v2_candidates import load_eligible_dishes

    eligible = load_eligible_dishes(db, user_id=user_id)
    foodpanda_in_pool = sum(1 for dish in eligible if dish.source == FOODPANDA_SOURCE)
    return {
        "recommendation_candidates": len(eligible),
        "foodpanda_candidates": foodpanda_in_pool,
        "manual_candidates": len(eligible) - foodpanda_in_pool,
    }


def get_top_categories(db: Session, *, limit: int = 10) -> list[dict[str, Any]]:
    """Top categories by dish count (eligible dishes only)."""
    rows = (
        db.query(Category.name, func.count(Dish.id).label("dish_count"))
        .join(Dish, Dish.category_id == Category.id)
        .join(Dish.restaurant)
        .filter(Dish.is_available.is_(True))
        .filter(Restaurant.is_open.is_(True))
        .group_by(Category.name)
        .order_by(func.count(Dish.id).desc())
        .limit(limit)
        .all()
    )
    return [{"name": name, "dish_count": int(count)} for name, count in rows]


def get_recommendation_debug_snapshot(db: Session, *, user_id: int | None = None) -> dict[str, Any]:
    """Admin/debug snapshot of catalog and candidate pool."""
    stats = get_catalog_stats(db)
    pool = get_candidate_pool_stats(db, user_id=user_id)
    return {
        **stats,
        **pool,
        "top_categories": get_top_categories(db),
    }
