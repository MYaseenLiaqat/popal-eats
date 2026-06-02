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

TOP_N = 10
SIMILAR_DEFAULT_LIMIT = 10


def _build_order_dish_sets(db: Session) -> dict[int, set[int]]:
    """Map each order_id to the set of dish_ids in that order."""
    rows = db.query(OrderItem.order_id, OrderItem.dish_id).all()
    order_dishes: dict[int, set[int]] = defaultdict(set)
    for order_id, dish_id in rows:
        order_dishes[order_id].add(dish_id)
    return order_dishes


def build_cooccurrence_matrix(db: Session) -> dict[int, dict[int, int]]:
    """
    Build symmetric co-occurrence counts for dish pairs ordered together.

    If orders contain Dish A and Dish B, increment cooccurrence[A][B] and [B][A].
    """
    order_dishes = _build_order_dish_sets(db)
    cooccurrence: dict[int, dict[int, int]] = defaultdict(lambda: defaultdict(int))

    for dishes in order_dishes.values():
        dish_list = sorted(dishes)
        for i, dish_a in enumerate(dish_list):
            for dish_b in dish_list[i + 1 :]:
                cooccurrence[dish_a][dish_b] += 1
                cooccurrence[dish_b][dish_a] += 1

    return cooccurrence


def _jaccard_similarity(co_count: int, count_a: int, count_b: int) -> float:
    """Jaccard-like similarity from co-occurrence and individual order frequencies."""
    if co_count <= 0 or count_a <= 0 or count_b <= 0:
        return 0.0
    union = count_a + count_b - co_count
    if union <= 0:
        return 0.0
    return co_count / union


def _dish_order_counts(order_dishes: dict[int, set[int]]) -> dict[int, int]:
    counts: dict[int, int] = defaultdict(int)
    for dishes in order_dishes.values():
        for dish_id in dishes:
            counts[dish_id] += 1
    return counts


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

    order_dishes = _build_order_dish_sets(db)
    cooccurrence = build_cooccurrence_matrix(db)
    dish_counts = _dish_order_counts(order_dishes)

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

    neighbor_ids = [dish_id for dish_id, _ in ranked]
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
        if not dish or not dish.restaurant or not dish.restaurant.is_open:
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


def get_collaborative_recommendations(
    db: Session,
    user_id: int,
    *,
    limit: int = TOP_N,
) -> list[V2DishRecommendationItem]:
    """
    Recommend dishes based on co-occurrence with the user's past orders.
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
        return []

    cooccurrence = build_cooccurrence_matrix(db)
    candidate_scores: dict[int, float] = defaultdict(float)

    for source_id in ordered_dish_ids:
        for neighbor_id, co_count in cooccurrence.get(source_id, {}).items():
            if neighbor_id in ordered_dish_ids:
                continue
            candidate_scores[neighbor_id] += co_count

    if not candidate_scores:
        return []

    max_score = max(candidate_scores.values())
    ranked_ids = sorted(
        candidate_scores.keys(),
        key=lambda did: candidate_scores[did],
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
    dishes_by_id = {d.id: d for d in dishes}

    items: list[V2DishRecommendationItem] = []
    for dish_id in ranked_ids:
        if len(items) >= limit:
            break
        dish = dishes_by_id.get(dish_id)
        if not dish:
            continue

        raw = candidate_scores[dish_id]
        normalized = round((raw / max_score) * 100, 1) if max_score > 0 else 0.0
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
                explanation=(
                    f"Often ordered together with dishes you have bought "
                    f"(co-occurrence +{int(raw)})."
                ),
                signals_used=["collaborative"],
            )
        )

    return items
