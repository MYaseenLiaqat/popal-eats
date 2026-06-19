"""
Recommendation Engine V2 - strategy router and weighted hybrid fusion (Phase 5.4).

Pipeline: content (DB dishes + preferences + reviews/orders) -> collaborative (orders)
-> feedback (recommendation_events) -> fusion -> ranked top-N.

Hybrid fusion (0-100 inputs):
    content*0.45 + collaborative*0.25 + feedback*0.15 + popularity*0.15

Users with no order history use fusion with collaborative_score = 0.
"""

import logging
from collections import defaultdict
from typing import Literal

from sqlalchemy import func
from sqlalchemy.orm import Session, joinedload

logger = logging.getLogger("popal.recommendations.v2")

from app.models.dish import Dish
from app.models.order import Order
from app.models.order_item import OrderItem
from app.schemas.recommendation_v2 import V2DishRecommendationItem, V2ScoreBreakdown
from app.services.recommendation.price_adjustment import apply_price_outlier_penalty
from app.services.recommendation.v2_collaborative import (
    build_cooccurrence_matrix,
    get_collaborative_recommendations,
)
from app.services.recommendation.v2_content import get_content_recommendations
from app.services.recommendation.v2_feedback import (
    UserFeedbackProfile,
    compute_feedback_bonus,
    get_user_feedback_profile,
    load_dish_category_names,
)
from app.services.recommendation.v2_candidates import is_eligible_dish
from app.services.recommendation.v2_catalog import FOODPANDA_SOURCE
from app.services.recommendation.v2_debug import log_pipeline_stage, log_ranked_recommendations
from app.services.recommendation.v2_fusion import (
    build_fusion_explanation,
    compute_hybrid_score,
    normalize_feedback_for_fusion,
    normalize_popularity_for_fusion,
)

Strategy = Literal["content", "collaborative", "hybrid"]

HYBRID_POOL_SIZE = 100
TOP_N = 10


def _user_has_order_history(db: Session, user_id: int) -> bool:
    return (
        db.query(OrderItem.id)
        .join(Order, OrderItem.order_id == Order.id)
        .filter(Order.user_id == user_id)
        .first()
        is not None
    )


def _collaborative_score_map(db: Session, user_id: int) -> dict[int, float]:
    """Normalized 0–100 collaborative scores from order co-occurrence."""
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

    cooccurrence = build_cooccurrence_matrix(db)
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


def _build_fused_item(
    *,
    dish_id: int,
    dish_name: str,
    restaurant_name: str,
    price,
    calories: int | None,
    content_item: V2DishRecommendationItem | None,
    collaborative_score: float,
    profile: UserFeedbackProfile,
    category_name: str | None,
) -> V2DishRecommendationItem | None:
    content_score = content_item.score if content_item else 0.0
    popularity_raw = (
        content_item.score_breakdown.popularity_score if content_item else 0.0
    )
    if content_item and content_item.score_breakdown.popularity_score <= 10:
        popularity_fusion = normalize_popularity_for_fusion(popularity_raw)
    else:
        popularity_fusion = min(100.0, float(popularity_raw))

    feedback_bonus, feedback_detail = compute_feedback_bonus(
        dish_id=dish_id,
        dish_name=dish_name,
        category_name=category_name,
        profile=profile,
    )
    feedback_fusion = normalize_feedback_for_fusion(feedback_bonus)

    hybrid_score = compute_hybrid_score(
        content_score,
        collaborative_score,
        feedback_fusion,
        popularity_fusion,
    )
    hybrid_score = apply_price_outlier_penalty(hybrid_score, price)
    if hybrid_score <= 0:
        return None

    base_breakdown = (
        content_item.score_breakdown
        if content_item
        else V2ScoreBreakdown()
    )
    breakdown = base_breakdown.model_copy(
        update={
            "content_score": round(content_score, 2),
            "collaborative_score": round(collaborative_score, 2),
            "feedback_score": feedback_fusion,
            "popularity_score": popularity_fusion,
            "hybrid_score": hybrid_score,
            "total_score": hybrid_score,
        }
    )

    detail = content_item.explanation if content_item else None
    explanation = build_fusion_explanation(
        feedback_detail=feedback_detail,
        detail=detail,
    )

    signals = ["hybrid", "fusion"]
    if content_score > 0:
        signals.append("content")
    if collaborative_score > 0:
        signals.append("collaborative")
    if feedback_fusion > 0:
        signals.append("feedback")
    if popularity_fusion > 0:
        signals.append("popularity")

    return V2DishRecommendationItem(
        dish_id=dish_id,
        dish_name=dish_name,
        restaurant_name=restaurant_name,
        price=price,
        calories=calories,
        score=hybrid_score,
        score_breakdown=breakdown,
        explanation=explanation,
        signals_used=signals,
    )


def get_hybrid_recommendations(
    db: Session,
    user_id: int,
    *,
    limit: int = TOP_N,
) -> list[V2DishRecommendationItem]:
    """
    Weighted hybrid fusion across content, collaborative, feedback, and popularity.
    """
    profile = get_user_feedback_profile(db, user_id)
    dish_to_category = load_dish_category_names(db)

    log_pipeline_stage("hybrid_start", user_id=user_id)

    content_items = get_content_recommendations(db, user_id, limit=HYBRID_POOL_SIZE)
    content_by_id = {item.dish_id: item for item in content_items}
    log_pipeline_stage(
        "hybrid_content_pool",
        user_id=user_id,
        pool_size=len(content_items),
    )

    cf_map: dict[int, float] = {}
    cf_by_id: dict[int, V2DishRecommendationItem] = {}

    if _user_has_order_history(db, user_id):
        cf_items = get_collaborative_recommendations(db, user_id, limit=HYBRID_POOL_SIZE)
        cf_by_id = {item.dish_id: item for item in cf_items}
        cf_map = _collaborative_score_map(db, user_id)
        for dish_id, score in cf_map.items():
            cf_map[dish_id] = max(score, cf_map.get(dish_id, 0.0))
        log_pipeline_stage(
            "hybrid_cf_pool",
            user_id=user_id,
            cf_items=len(cf_items),
            cf_score_entries=len(cf_map),
        )

    all_dish_ids = set(content_by_id) | set(cf_map.keys()) | set(cf_by_id.keys())
    log_pipeline_stage(
        "hybrid_fusion_union",
        user_id=user_id,
        candidate_ids=len(all_dish_ids),
    )
    hybrid_rows: list[tuple[float, V2DishRecommendationItem]] = []

    for dish_id in all_dish_ids:
        content_item = content_by_id.get(dish_id)
        collaborative_score = cf_map.get(dish_id, 0.0)
        if collaborative_score == 0.0 and dish_id in cf_by_id:
            collaborative_score = cf_by_id[dish_id].score

        if content_item:
            fused = _build_fused_item(
                dish_id=content_item.dish_id,
                dish_name=content_item.dish_name,
                restaurant_name=content_item.restaurant_name,
                price=content_item.price,
                calories=content_item.calories,
                content_item=content_item,
                collaborative_score=collaborative_score,
                profile=profile,
                category_name=dish_to_category.get(dish_id),
            )
        elif dish_id in cf_by_id:
            cf_item = cf_by_id[dish_id]
            fused = _build_fused_item(
                dish_id=cf_item.dish_id,
                dish_name=cf_item.dish_name,
                restaurant_name=cf_item.restaurant_name,
                price=cf_item.price,
                calories=cf_item.calories,
                content_item=None,
                collaborative_score=collaborative_score,
                profile=profile,
                category_name=dish_to_category.get(dish_id),
            )
        else:
            dish = (
                db.query(Dish)
                .options(joinedload(Dish.restaurant))
                .filter(Dish.id == dish_id, Dish.is_available.is_(True))
                .first()
            )
            if not dish or not is_eligible_dish(dish):
                continue
            fused = _build_fused_item(
                dish_id=dish.id,
                dish_name=dish.name,
                restaurant_name=dish.restaurant.name,
                price=dish.price,
                calories=dish.calories,
                content_item=None,
                collaborative_score=collaborative_score,
                profile=profile,
                category_name=dish_to_category.get(dish_id),
            )

        if fused:
            hybrid_rows.append((fused.score, fused))

    hybrid_rows.sort(key=lambda row: row[0], reverse=True)
    final = [item for _, item in hybrid_rows[:limit]]
    foodpanda_in_final = 0
    if final:
        final_ids = [item.dish_id for item in final]
        foodpanda_in_final = (
            db.query(func.count(Dish.id))
            .filter(Dish.id.in_(final_ids), Dish.source == FOODPANDA_SOURCE)
            .scalar()
            or 0
        )
    log_pipeline_stage(
        "hybrid_ranking_complete",
        user_id=user_id,
        fused=len(hybrid_rows),
        returned=len(final),
        foodpanda_in_final=foodpanda_in_final,
    )
    log_ranked_recommendations("hybrid_final", final, user_id=user_id)
    return final


def get_v2_recommendations(
    db: Session,
    user_id: int,
    *,
    strategy: Strategy = "content",
    limit: int = TOP_N,
) -> list[V2DishRecommendationItem]:
    if strategy == "collaborative":
        return get_collaborative_recommendations(db, user_id, limit=limit)
    if strategy == "hybrid":
        return get_hybrid_recommendations(db, user_id, limit=limit)
    if strategy == "content":
        return get_content_recommendations(db, user_id, limit=limit)
    return []
