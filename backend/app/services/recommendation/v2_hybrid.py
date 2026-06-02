"""
Recommendation Engine V2 — strategy router and hybrid fusion (Phase 3).

Hybrid formula:
    final_score = 0.7 * content_score + 0.3 * collaborative_score

Users with no order history fall back to content-only scoring.
"""

from collections import defaultdict
from typing import Literal

from sqlalchemy.orm import Session, joinedload

from app.models.dish import Dish
from app.models.order import Order
from app.models.order_item import OrderItem
from app.schemas.recommendation_v2 import V2DishRecommendationItem, V2ScoreBreakdown
from app.services.recommendation.v2_collaborative import (
    build_cooccurrence_matrix,
    get_collaborative_recommendations,
)
from app.services.recommendation.v2_content import get_content_recommendations

Strategy = Literal["content", "collaborative", "hybrid"]

CONTENT_WEIGHT = 0.7
COLLABORATIVE_WEIGHT = 0.3
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
    """
    Normalized 0–100 collaborative scores from order co-occurrence (same logic as Phase 2).
    Does not modify the collaborative service module.
    """
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


def _hybrid_explanation(
    content_score: float,
    collaborative_score: float,
    final_score: float,
    content_explanation: str,
) -> str:
    parts: list[str] = []
    if content_score > 0:
        parts.append(f"content ({content_score:.0f} × {CONTENT_WEIGHT})")
    if collaborative_score > 0:
        parts.append(f"collaborative ({collaborative_score:.0f} × {COLLABORATIVE_WEIGHT})")
    blend = f"Hybrid score {final_score:.0f}"
    if parts:
        return f"{blend}: {' + '.join(parts)}. {content_explanation}"
    return content_explanation


def _merge_hybrid_item(
    content_item: V2DishRecommendationItem,
    collaborative_score: float,
    final_score: float,
) -> V2DishRecommendationItem:
    content_score = content_item.score
    breakdown = content_item.score_breakdown.model_copy(
        update={
            "collaborative_score": collaborative_score,
            "total_score": final_score,
        }
    )
    signals = list(content_item.signals_used)
    if collaborative_score > 0 and "collaborative" not in signals:
        signals.append("collaborative")
    if content_score > 0 and "content" not in signals:
        signals.insert(0, "content")

    return V2DishRecommendationItem(
        dish_id=content_item.dish_id,
        dish_name=content_item.dish_name,
        restaurant_name=content_item.restaurant_name,
        price=content_item.price,
        calories=content_item.calories,
        score=final_score,
        score_breakdown=breakdown,
        explanation=_hybrid_explanation(
            content_score,
            collaborative_score,
            final_score,
            content_item.explanation,
        ),
        signals_used=signals,
    )


def _build_cf_only_hybrid_item(
    cf_item: V2DishRecommendationItem,
    content_score: float,
    final_score: float,
) -> V2DishRecommendationItem:
    collaborative_score = cf_item.score
    breakdown = V2ScoreBreakdown(
        cuisine_score=0.0,
        nutrition_score=0.0,
        budget_score=0.0,
        popularity_score=0.0,
        collaborative_score=collaborative_score,
        total_score=final_score,
    )
    return V2DishRecommendationItem(
        dish_id=cf_item.dish_id,
        dish_name=cf_item.dish_name,
        restaurant_name=cf_item.restaurant_name,
        price=cf_item.price,
        calories=cf_item.calories,
        score=final_score,
        score_breakdown=breakdown,
        explanation=_hybrid_explanation(
            content_score,
            collaborative_score,
            final_score,
            cf_item.explanation,
        ),
        signals_used=["collaborative", "hybrid"],
    )


def get_hybrid_recommendations(
    db: Session,
    user_id: int,
    *,
    limit: int = TOP_N,
) -> list[V2DishRecommendationItem]:
    """
    Fuse content (70%) and collaborative (30%) scores.

    Falls back to content-only when the user has no order history.
    """
    if not _user_has_order_history(db, user_id):
        return get_content_recommendations(db, user_id, limit=limit)

    content_items = get_content_recommendations(db, user_id, limit=HYBRID_POOL_SIZE)
    cf_items = get_collaborative_recommendations(db, user_id, limit=HYBRID_POOL_SIZE)
    cf_map = _collaborative_score_map(db, user_id)

    content_by_id = {item.dish_id: item for item in content_items}
    cf_by_id = {item.dish_id: item for item in cf_items}
    for dish_id, score in cf_map.items():
        cf_map[dish_id] = max(score, cf_map.get(dish_id, 0.0))

    all_dish_ids = set(content_by_id) | set(cf_map.keys()) | set(cf_by_id.keys())
    hybrid_rows: list[tuple[float, V2DishRecommendationItem]] = []

    for dish_id in all_dish_ids:
        content_item = content_by_id.get(dish_id)
        content_score = content_item.score if content_item else 0.0
        collaborative_score = cf_map.get(dish_id, 0.0)
        if collaborative_score == 0.0 and dish_id in cf_by_id:
            collaborative_score = cf_by_id[dish_id].score

        final_score = round(
            CONTENT_WEIGHT * content_score + COLLABORATIVE_WEIGHT * collaborative_score,
            1,
        )
        if final_score <= 0:
            continue

        if content_item:
            merged = _merge_hybrid_item(content_item, collaborative_score, final_score)
        elif dish_id in cf_by_id:
            merged = _build_cf_only_hybrid_item(cf_by_id[dish_id], content_score, final_score)
        else:
            dish = (
                db.query(Dish)
                .options(joinedload(Dish.restaurant))
                .filter(Dish.id == dish_id, Dish.is_available.is_(True))
                .first()
            )
            if not dish or not dish.restaurant or not dish.restaurant.is_open:
                continue
            cf_stub = V2DishRecommendationItem(
                dish_id=dish.id,
                dish_name=dish.name,
                restaurant_name=dish.restaurant.name,
                price=dish.price,
                calories=dish.calories,
                score=collaborative_score,
                score_breakdown=V2ScoreBreakdown(collaborative_score=collaborative_score),
                explanation=f"Order co-occurrence match (score {collaborative_score:.0f}).",
                signals_used=["collaborative"],
            )
            merged = _build_cf_only_hybrid_item(cf_stub, content_score, final_score)

        hybrid_rows.append((final_score, merged))

    hybrid_rows.sort(key=lambda row: row[0], reverse=True)
    return [item for _, item in hybrid_rows[:limit]]


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
