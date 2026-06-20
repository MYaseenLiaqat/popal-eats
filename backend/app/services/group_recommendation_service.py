"""Dedicated group recommendation engine orchestrator."""

from __future__ import annotations

import heapq
import logging

from fastapi import HTTPException, status
from sqlalchemy import func
from sqlalchemy.orm import Session

from app.models.dish import Dish
from app.models.order_item import OrderItem
from app.schemas.group_recommendation import GroupDishRecommendation, GroupRecommendationsResponse
from app.services.group_recommendation.context import GroupRecommendationContext, load_group_context
from app.services.group_recommendation.coordinates import build_restaurant_coordinate_map
from app.services.group_recommendation.filters import (
    is_dish_dietary_compatible,
    is_dish_safe_for_group,
)
from app.services.group_recommendation.scoring import (
    build_reasons,
    compute_group_centroid,
    compute_group_score,
    score_budget_compatibility,
    score_cuisine_match,
    score_distance,
    score_group_agreement,
    score_popularity,
)
from app.services.group_session_service import _get_session_or_404, _is_session_active, _require_member
from app.services.recommendation.market_filter import filter_dishes_for_market
from app.services.recommendation.price_adjustment import apply_price_outlier_penalty
from app.services.recommendation.v2_candidates import load_eligible_dishes
from app.services.recommendation.v2_catalog import build_tag_maps_from_dishes

logger = logging.getLogger("popal.group_recommendations")

TOP_N = 20


def _load_order_counts(db: Session, dish_ids: list[int] | None = None) -> dict[int, int]:
    query = db.query(OrderItem.dish_id, func.count(OrderItem.id)).group_by(OrderItem.dish_id)
    if dish_ids:
        query = query.filter(OrderItem.dish_id.in_(dish_ids))
    rows = query.all()
    return {dish_id: int(count) for dish_id, count in rows}


def _filter_candidates(
    dishes: list[Dish],
    context: GroupRecommendationContext,
    dish_tags_map: dict[int, list[str]],
    restaurant_tags_map: dict[int, list[str]],
) -> list[Dish]:
    filtered: list[Dish] = []
    for dish in dishes:
        dish_tags = dish_tags_map.get(dish.id, [])
        restaurant_tags = (
            restaurant_tags_map.get(dish.restaurant_id, []) if dish.restaurant_id else []
        )
        if not is_dish_safe_for_group(
            dish,
            context.group_allergies,
            dish_tags=dish_tags,
            restaurant_tags=restaurant_tags,
        ):
            continue
        if not is_dish_dietary_compatible(
            dish,
            context.group_dietary,
            dish_tags=dish_tags,
            restaurant_tags=restaurant_tags,
        ):
            continue
        filtered.append(dish)
    return filtered


def _score_dishes(
    dishes: list[Dish],
    context: GroupRecommendationContext,
    *,
    dish_tags_map: dict[int, list[str]],
    restaurant_tags_map: dict[int, list[str]],
    restaurant_coords: dict[int, tuple[float, float]],
    order_counts: dict[int, int],
    centroid: tuple[float, float] | None,
) -> list[GroupDishRecommendation]:
    members = context.member_scoring_dicts
    max_orders = max(order_counts.values()) if order_counts else 0
    scored: list[GroupDishRecommendation] = []

    for dish in dishes:
        dish_tags = dish_tags_map.get(dish.id, [])
        restaurant_tags = (
            restaurant_tags_map.get(dish.restaurant_id, []) if dish.restaurant_id else []
        )
        restaurant = dish.restaurant
        rest_coords = restaurant_coords.get(restaurant.id) if restaurant else None

        cuisine_score = score_cuisine_match(
            dish,
            members,
            dish_tags=dish_tags,
            restaurant_tags=restaurant_tags,
        )
        agreement_score, matching, total = score_group_agreement(
            dish,
            members,
            dish_tags=dish_tags,
            restaurant_tags=restaurant_tags,
        )
        distance_score = score_distance(centroid=centroid, restaurant_coords=rest_coords)
        budget_score = score_budget_compatibility(dish, members)
        popularity_score = score_popularity(dish, order_counts.get(dish.id, 0), max_orders)

        final_score = compute_group_score(
            cuisine_score=cuisine_score,
            agreement_score=agreement_score,
            distance_score=distance_score,
            budget_score=budget_score,
            popularity_score=popularity_score,
        )
        final_score = apply_price_outlier_penalty(final_score, dish.price)
        reasons = build_reasons(
            matching_members=matching,
            total_members=total,
            budget_score=budget_score,
            distance_score=distance_score,
            cuisine_score=cuisine_score,
        )
        scored.append(
            GroupDishRecommendation(
                dish_id=dish.id,
                dish_name=dish.name,
                restaurant_name=restaurant.name if restaurant else "",
                price=dish.price,
                score=final_score,
                reasons=reasons,
            )
        )

    return heapq.nlargest(TOP_N, scored, key=lambda item: (item.score, item.dish_id))


def get_group_recommendations(
    db: Session,
    user_id: int,
    session_id: int,
) -> GroupRecommendationsResponse:
    logger.info("GROUP_RECOMMENDATION_START session_id=%s user_id=%s", session_id, user_id)

    session = _get_session_or_404(db, session_id)
    _require_member(session, user_id)
    if not _is_session_active(session):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Group session is not active",
        )

    context = load_group_context(db, session)
    centroid = compute_group_centroid(context.active_locations)
    logger.info(
        "GROUP_CONTEXT_LOADED session_id=%s members=%d active_locations=%d allergies=%d dietary=%d",
        session_id,
        context.member_count,
        len(context.active_locations),
        len(context.group_allergies),
        len(context.group_dietary),
    )

    candidates = load_eligible_dishes(db, user_id=user_id)
    dish_tags_map, restaurant_tags_map = build_tag_maps_from_dishes(candidates)
    filtered = _filter_candidates(candidates, context, dish_tags_map, restaurant_tags_map)
    market_filtered = filter_dishes_for_market(filtered)
    logger.info(
        "GROUP_FILTERING_COMPLETE session_id=%s candidates=%d after_filter=%d lahore=%d",
        session_id,
        len(candidates),
        len(filtered),
        len(market_filtered),
    )

    restaurants = [dish.restaurant for dish in market_filtered if dish.restaurant]
    restaurant_coords = build_restaurant_coordinate_map(restaurants)
    candidate_ids = [dish.id for dish in market_filtered]
    order_counts = _load_order_counts(db, candidate_ids)

    recommendations = _score_dishes(
        market_filtered,
        context,
        dish_tags_map=dish_tags_map,
        restaurant_tags_map=restaurant_tags_map,
        restaurant_coords=restaurant_coords,
        order_counts=order_counts,
        centroid=centroid,
    )
    logger.info(
        "GROUP_SCORING_COMPLETE session_id=%s ranked=%d",
        session_id,
        len(recommendations),
    )

    response = GroupRecommendationsResponse(
        group_id=session_id,
        member_count=context.member_count,
        group_latitude=centroid[0] if centroid else None,
        group_longitude=centroid[1] if centroid else None,
        recommendations=recommendations,
    )
    logger.info(
        "GROUP_RECOMMENDATION_COMPLETE session_id=%s returned=%d",
        session_id,
        len(recommendations),
    )
    return response
