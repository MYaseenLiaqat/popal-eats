"""
Recommendation Engine V2 - strategy router and weighted hybrid fusion (Phase 5.4).

Pipeline: content (DB dishes + preferences + reviews/orders) -> collaborative (orders)
-> feedback (recommendation_events) -> fusion -> ranked top-N.

Hybrid fusion (0-100 inputs):
    content*0.45 + collaborative*0.25 + feedback*0.15 + popularity*0.15

Users with no order history use fusion with collaborative_score = 0.
"""

import logging
from typing import Literal

from sqlalchemy import func
from sqlalchemy.orm import Session, joinedload

logger = logging.getLogger("popal.recommendations.v2")

from app.models.dish import Dish
from app.models.order import Order
from app.models.order_item import OrderItem
from app.schemas.recommendation_v2 import V2DishRecommendationItem, V2ScoreBreakdown
from app.services.recommendation.allergy_filter import filter_dishes_for_user_allergies
from app.services.recommendation.price_adjustment import apply_price_outlier_penalty
from app.services.recommendation.v2_collaborative import (
    _collaborative_scores_for_user,
    get_collaborative_recommendations,
)
from app.services.recommendation.v2_cooccurrence_cache import get_cooccurrence_bundle
from app.services.recommendation.v2_content import get_content_recommendations
from app.services.recommendation.v2_feedback import (
    UserFeedbackProfile,
    compute_feedback_bonus,
    get_user_feedback_profile,
    load_dish_category_names,
)
from app.services.recommendation.v2_candidates import is_eligible_dish
from app.services.recommendation.v2_catalog import FOODPANDA_SOURCE, build_tag_maps_from_dishes
from app.services.recommendation.v2_debug import log_pipeline_stage, log_ranked_recommendations
from app.services.recommendation.v2_fusion import (
    build_fusion_explanation,
    compute_hybrid_score,
    normalize_feedback_for_fusion,
    normalize_popularity_for_fusion,
)
from app.services.recommendation.v2_explainability import enrich_recommendation_items
from app.services.user_preferences_service import load_recommendation_preferences

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


def _collaborative_score_map(
    db: Session,
    user_id: int,
    *,
    cooccurrence: dict[int, dict[int, int]] | None = None,
) -> dict[int, float]:
    """Normalized 0–100 collaborative scores from order co-occurrence."""
    return _collaborative_scores_for_user(db, user_id, cooccurrence=cooccurrence)


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
    prefs = load_recommendation_preferences(db, user_id)

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
    cooccurrence: dict[int, dict[int, int]] | None = None

    if _user_has_order_history(db, user_id):
        _, cooccurrence, _ = get_cooccurrence_bundle(db)
        cf_items = get_collaborative_recommendations(
            db, user_id, limit=HYBRID_POOL_SIZE, cooccurrence=cooccurrence
        )
        cf_by_id = {item.dish_id: item for item in cf_items}
        cf_map = _collaborative_score_map(db, user_id, cooccurrence=cooccurrence)
        log_pipeline_stage(
            "hybrid_cf_pool",
            user_id=user_id,
            cf_items=len(cf_items),
            cf_score_entries=len(cf_map),
        )

    cf_top_ids = set(
        sorted(cf_map.keys(), key=lambda d: cf_map.get(d, 0.0), reverse=True)[:HYBRID_POOL_SIZE]
    )
    all_dish_ids = set(content_by_id) | cf_top_ids | set(cf_by_id.keys())

    if prefs.allergies and all_dish_ids:
        pool_dishes = (
            db.query(Dish)
            .options(joinedload(Dish.restaurant), joinedload(Dish.category))
            .filter(Dish.id.in_(all_dish_ids), Dish.is_available.is_(True))
            .all()
        )
        dish_tags_map, restaurant_tags_map = build_tag_maps_from_dishes(pool_dishes)
        safe_ids = {
            d.id
            for d in filter_dishes_for_user_allergies(
                pool_dishes,
                prefs.allergies,
                dish_tags_map=dish_tags_map,
                restaurant_tags_map=restaurant_tags_map,
                user_id=user_id,
            )
        }
        all_dish_ids = all_dish_ids & safe_ids
        content_by_id = {k: v for k, v in content_by_id.items() if k in safe_ids}
        cf_by_id = {k: v for k, v in cf_by_id.items() if k in safe_ids}
        cf_map = {k: v for k, v in cf_map.items() if k in safe_ids}

    dish_to_category = load_dish_category_names(db, dish_ids=list(all_dish_ids))

    log_pipeline_stage(
        "hybrid_fusion_union",
        user_id=user_id,
        candidate_ids=len(all_dish_ids),
    )
    hybrid_rows: list[tuple[float, V2DishRecommendationItem]] = []

    missing_ids = [
        dish_id
        for dish_id in all_dish_ids
        if dish_id not in content_by_id and dish_id not in cf_by_id
    ]
    extra_dishes_by_id: dict[int, Dish] = {}
    if missing_ids:
        extra_dishes_by_id = {
            d.id: d
            for d in db.query(Dish)
            .options(joinedload(Dish.restaurant))
            .filter(Dish.id.in_(missing_ids), Dish.is_available.is_(True))
            .all()
        }

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
            dish = extra_dishes_by_id.get(dish_id)
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
    prefs = load_recommendation_preferences(db, user_id)

    if strategy == "collaborative":
        items = get_collaborative_recommendations(db, user_id, limit=limit)
    elif strategy == "hybrid":
        items = get_hybrid_recommendations(db, user_id, limit=limit)
    elif strategy == "content":
        items = get_content_recommendations(db, user_id, limit=limit)
    else:
        items = []

    return enrich_recommendation_items(items, prefs, strategy=strategy)
