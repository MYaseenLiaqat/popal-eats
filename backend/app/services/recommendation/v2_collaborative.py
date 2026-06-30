"""
Recommendation Engine V2 — item-based collaborative filtering (Phase 2).

Uses dish co-occurrence within the same order (no ML libraries).
"""

from collections import defaultdict
from decimal import Decimal

from fastapi import HTTPException, status
from sqlalchemy.orm import Session, joinedload

from app.models.dish import Dish
from app.models.order import Order
from app.models.order_item import OrderItem
from app.schemas.recommendation_v2 import (
    V2DishRecommendationItem,
    V2ScoreBreakdown,
    V2SimilarDishItem,
)
from app.services.recommendation.allergy_filter import filter_dishes_for_user_allergies
from app.services.recommendation.market_filter import filter_dishes_for_market
from app.services.recommendation.price_adjustment import apply_price_outlier_penalty
from app.services.recommendation.v2_candidates import is_eligible_dish
from app.services.recommendation.v2_catalog import build_tag_maps_from_dishes
from app.services.recommendation.v2_cooccurrence_cache import get_cooccurrence_bundle
from app.services.recommendation.v2_debug import log_ranked_recommendations
from app.services.user_preferences_service import load_recommendation_preferences

TOP_N = 10
SIMILAR_DEFAULT_LIMIT = 10


def _jaccard_similarity(co_count: int, count_a: int, count_b: int) -> float:
    """Jaccard-like similarity from co-occurrence and individual order frequencies."""
    if co_count <= 0 or count_a <= 0 or count_b <= 0:
        return 0.0
    union = count_a + count_b - co_count
    if union <= 0:
        return 0.0
    return co_count / union


def get_similar_dishes(
    db: Session,
    dish_id: int,
    *,
    limit: int = SIMILAR_DEFAULT_LIMIT,
) -> list[V2SimilarDishItem]:
    """
    Return dishes most frequently ordered together with ``dish_id``.
    """
    source = (
        db.query(Dish)
        .options(joinedload(Dish.restaurant))
        .filter(Dish.id == dish_id)
        .first()
    )
    if not source:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Dish not found")

    _order_dishes, cooccurrence, dish_counts = get_cooccurrence_bundle(db)

    neighbors = cooccurrence.get(dish_id, {})
    if not neighbors:
        return []

    ranked = sorted(
        neighbors.items(),
        key=lambda item: (
            item[1],
            _jaccard_similarity(item[1], dish_counts.get(dish_id, 0), dish_counts.get(item[0], 0)),
        ),
        reverse=True,
    )[:limit]

    neighbor_ids = [neighbor_id for neighbor_id, _ in ranked]
    dishes_by_id = {
        d.id: d
        for d in db.query(Dish)
        .options(joinedload(Dish.restaurant))
        .filter(Dish.id.in_(neighbor_ids), Dish.is_available.is_(True))
        .all()
    }

    results: list[V2SimilarDishItem] = []
    for other_id, co_count in ranked:
        dish = dishes_by_id.get(other_id)
        if not dish or not is_eligible_dish(dish):
            continue
        sim = _jaccard_similarity(
            co_count,
            dish_counts.get(dish_id, 0),
            dish_counts.get(other_id, 0),
        )
        results.append(
            V2SimilarDishItem(
                dish_id=dish.id,
                dish_name=dish.name,
                restaurant_name=dish.restaurant.name,
                price=dish.price,
                co_occurrence_count=co_count,
                similarity_score=round(sim, 4),
            )
        )

    return results


def _collaborative_scores_for_user(
    db: Session,
    user_id: int,
    *,
    cooccurrence: dict[int, dict[int, int]] | None = None,
) -> dict[int, float]:
    ordered_dish_ids = {
        row[0]
        for row in db.query(OrderItem.dish_id)
        .join(Order, OrderItem.order_id == Order.id)
        .filter(Order.user_id == user_id)
        .distinct()
        .all()
    }
    if not ordered_dish_ids:
        return {}

    if cooccurrence is None:
        _, cooccurrence, _ = get_cooccurrence_bundle(db)

    candidate_scores: dict[int, float] = defaultdict(float)
    for source_id in ordered_dish_ids:
        for neighbor_id, co_count in cooccurrence.get(source_id, {}).items():
            if neighbor_id in ordered_dish_ids:
                continue
            candidate_scores[neighbor_id] += co_count

    if not candidate_scores:
        return {}

    max_score = max(candidate_scores.values())
    return {
        dish_id: round((raw / max_score) * 100, 1) if max_score > 0 else 0.0
        for dish_id, raw in candidate_scores.items()
    }


def get_collaborative_recommendations(
    db: Session,
    user_id: int,
    *,
    limit: int = TOP_N,
    cooccurrence: dict[int, dict[int, int]] | None = None,
) -> list[V2DishRecommendationItem]:
    """
    Recommend dishes based on co-occurrence with the user's past orders.
    """
    if cooccurrence is None:
        _, cooccurrence, _ = get_cooccurrence_bundle(db)

    candidate_scores_raw: dict[int, float] = defaultdict(float)
    ordered_dish_ids = {
        row[0]
        for row in db.query(OrderItem.dish_id)
        .join(Order, OrderItem.order_id == Order.id)
        .filter(Order.user_id == user_id)
        .distinct()
        .all()
    }

    if not ordered_dish_ids:
        return []

    for source_id in ordered_dish_ids:
        for neighbor_id, co_count in cooccurrence.get(source_id, {}).items():
            if neighbor_id in ordered_dish_ids:
                continue
            candidate_scores_raw[neighbor_id] += co_count

    if not candidate_scores_raw:
        return []

    max_score = max(candidate_scores_raw.values())
    ranked_ids = sorted(
        candidate_scores_raw.keys(),
        key=lambda did: candidate_scores_raw[did],
        reverse=True,
    )[: limit * 2]

    dishes = (
        db.query(Dish)
        .join(Dish.restaurant)
        .options(joinedload(Dish.restaurant))
        .filter(Dish.id.in_(ranked_ids))
        .filter(Dish.is_available.is_(True))
        .filter(Dish.restaurant.has(is_open=True))
        .all()
    )
    dishes = filter_dishes_for_market(dishes)
    prefs = load_recommendation_preferences(db, user_id)
    dish_tags_map, restaurant_tags_map = build_tag_maps_from_dishes(dishes)
    dishes = filter_dishes_for_user_allergies(
        dishes,
        prefs.allergies,
        dish_tags_map=dish_tags_map,
        restaurant_tags_map=restaurant_tags_map,
        user_id=user_id,
    )
    dishes_by_id = {d.id: d for d in dishes}

    items: list[V2DishRecommendationItem] = []
    for dish_id in ranked_ids:
        if len(items) >= limit:
            break
        dish = dishes_by_id.get(dish_id)
        if not dish or not is_eligible_dish(dish):
            continue

        raw = candidate_scores_raw[dish_id]
        normalized = round((raw / max_score) * 100, 1) if max_score > 0 else 0.0
        normalized = apply_price_outlier_penalty(normalized, dish.price)
        breakdown = V2ScoreBreakdown(
            cuisine_score=0.0,
            nutrition_score=0.0,
            budget_score=0.0,
            popularity_score=0.0,
            collaborative_score=normalized,
            total_score=normalized,
        )
        items.append(
            V2DishRecommendationItem(
                dish_id=dish.id,
                dish_name=dish.name,
                restaurant_name=dish.restaurant.name if dish.restaurant else "",
                price=dish.price,
                calories=dish.calories,
                score=normalized,
                score_breakdown=breakdown,
                explanation="Recommended because it pairs well with what you've ordered before",
                signals_used=["collaborative"],
            )
        )

    log_ranked_recommendations("collaborative_ranked", items, user_id=user_id)
    return items
