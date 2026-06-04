"""Recommendation Engine V2 API."""

from typing import Literal

from fastapi import APIRouter, Depends, Query, status
from sqlalchemy.orm import Session

from app.core.dependencies import get_current_user
from app.core.permissions import get_dish_or_404
from app.database import get_db
from app.models.user import User
from app.schemas.recommendation_v2 import RecommendationsV2Response, SimilarDishesResponse
from app.schemas.recommendation_v2_analytics import (
    AnalyticsResponse,
    PopularResponse,
    TrendingResponse,
)
from app.schemas.recommendation_v2_metrics import (
    RecommendationEventCreate,
    RecommendationEventResponse,
)
from app.schemas.recommendation_v2_profile import FeedbackProfileResponse
from app.services.recommendation.v2_feedback import get_user_feedback_profile
from app.services.recommendation.v2_collaborative import get_similar_dishes
from app.services.recommendation.v2_hybrid import get_v2_recommendations
from app.services.recommendation.v2_metrics import log_recommendation_event
from app.services.recommendation.v2_trending import (
    get_popular_dishes,
    get_recommendation_analytics,
    get_trending_dishes,
)

router = APIRouter(tags=["recommendations-v2"])

StrategyQuery = Literal["content", "collaborative", "hybrid"]


@router.get(
    "/recommendations/v2",
    response_model=RecommendationsV2Response,
    summary="Get personalized recommendations (Engine V2)",
    description=(
        "**Recommendation Engine V2** — choose a `strategy`:\n\n"
        "| Strategy | Description |\n"
        "|----------|-------------|\n"
        "| `content` | Phase 1 rule-based (cuisine 50 + nutrition 25 + budget 15 + popularity 10) |\n"
        "| `collaborative` | Phase 2 order co-occurrence from `orders` / `order_items` |\n"
        "| `hybrid` | Phase 5.4 **weighted fusion** (see formula below) |\n\n"
        "**Hybrid fusion** (`strategy=hybrid` only):\n\n"
        "`final_score = content×0.45 + collaborative×0.25 + feedback×0.15 + popularity×0.15`\n\n"
        "All four inputs use a **0–100** scale. `score_breakdown` includes "
        "`content_score`, `collaborative_score`, `feedback_score`, `popularity_score`, "
        "and `hybrid_score`. Explanations include the fusion weight lines.\n\n"
        "Returns top **10** dishes with `score`, `score_breakdown`, and `explanation`.\n\n"
        "Related: `/recommendations/v2/trending`, `/popular`, `/analytics`, "
        "`/similar/{dish_id}`.\n\n"
        "Does **not** replace `GET /recommendations` (V1.1).\n\n"
        "Requires JWT Bearer token from `POST /login`."
    ),
)
def list_recommendations_v2(
    strategy: StrategyQuery = Query(
        "content",
        description="content (default) | collaborative | hybrid (weighted fusion 45/25/15/15)",
    ),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    items = get_v2_recommendations(db, current_user.id, strategy=strategy)
    return RecommendationsV2Response(
        engine_version="2.0",
        strategy=strategy,
        items=items,
        count=len(items),
    )


@router.get(
    "/recommendations/v2/similar/{dish_id}",
    response_model=SimilarDishesResponse,
    summary="Similar dishes (item-based collaborative filtering)",
    description=(
        "**Phase 2 — item-based collaborative filtering**\n\n"
        "Finds dishes frequently ordered in the **same order** as `{dish_id}` "
        "using co-occurrence counts from `orders` + `order_items`.\n\n"
        "No ML libraries — pure co-occurrence + Jaccard similarity.\n\n"
        "Requires JWT Bearer token."
    ),
)
def similar_dishes_v2(
    dish_id: int,
    limit: int = Query(10, ge=1, le=50, description="Max similar dishes to return"),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    _ = current_user
    similar = get_similar_dishes(db, dish_id, limit=limit)
    return SimilarDishesResponse(
        dish_id=dish_id,
        similar_dishes=similar,
        count=len(similar),
        engine_version="2.0",
    )


@router.get(
    "/recommendations/v2/trending",
    response_model=TrendingResponse,
    summary="Trending dishes (engagement score)",
    description=(
        "**Phase 4 — trending dishes**\n\n"
        "Ranks available dishes from open restaurants by:\n\n"
        "`trending_score = order_count×0.5 + review_count×0.3 + average_rating×0.2`\n\n"
        "- `order_count` — sum of `order_items.quantity` for the dish\n"
        "- `review_count` — parent `restaurants.total_reviews`\n"
        "- `average_rating` — parent `restaurants.average_rating` (0–5)\n\n"
        "Query: `limit` (default 10, max 50). Requires JWT."
    ),
)
def trending_dishes_v2(
    limit: int = Query(10, ge=1, le=50, description="Max trending dishes to return"),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    _ = current_user
    return get_trending_dishes(db, limit=limit)


@router.get(
    "/recommendations/v2/popular",
    response_model=PopularResponse,
    summary="Most ordered dishes",
    description=(
        "**Phase 4 — popular dishes**\n\n"
        "Returns dishes with the highest `total_orders` "
        "(sum of `order_items.quantity`), descending.\n\n"
        "Only includes dishes with at least one order. "
        "Query: `limit` (default 10, max 50). Requires JWT."
    ),
)
def popular_dishes_v2(
    limit: int = Query(10, ge=1, le=50, description="Max popular dishes to return"),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    _ = current_user
    return get_popular_dishes(db, limit=limit)


@router.get(
    "/recommendations/v2/analytics",
    response_model=AnalyticsResponse,
    summary="Recommendation platform analytics",
    description=(
        "**Phase 4 + 5.2 — platform analytics and CTR**\n\n"
        "Returns aggregate counts: dishes, restaurants, orders, reviews, "
        "and average restaurant rating.\n\n"
        "**CTR metrics** (from `recommendation_events`, Phase 5.1):\n\n"
        "| Field | Definition |\n"
        "|-------|------------|\n"
        "| `total_impressions` | Events with `event_type` = `impression` |\n"
        "| `total_clicks` | Events with `event_type` = `click` |\n"
        "| `click_through_rate` | `total_clicks / total_impressions` "
        "(**0** when impressions are 0; rounded to 4 decimals) |\n\n"
        "**Example response**\n\n"
        "```json\n"
        "{\n"
        '  "engine_version": "2.1",\n'
        '  "total_dishes": 25,\n'
        '  "total_restaurants": 5,\n'
        '  "total_orders": 100,\n'
        '  "total_reviews": 50,\n'
        '  "avg_restaurant_rating": 4.2,\n'
        '  "total_impressions": 120,\n'
        '  "total_clicks": 15,\n'
        '  "click_through_rate": 0.125\n'
        "}\n"
        "```\n\n"
        "`engine_version`: **2.1**. Requires JWT."
    ),
)
def recommendation_analytics_v2(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    _ = current_user
    return get_recommendation_analytics(db)


@router.get(
    "/recommendations/v2/profile",
    response_model=FeedbackProfileResponse,
    summary="Learned feedback profile for the current user",
    description=(
        "**Phase 5.3 — feedback learning layer**\n\n"
        "Builds an implicit taste profile from `recommendation_events` "
        "(logged via `POST /recommendations/v2/event`).\n\n"
        "**Weight rules**\n\n"
        "| `event_type` | Feedback weight |\n"
        "|--------------|------------------|\n"
        "| `impression` | **0** (CTR only) |\n"
        "| `click` | **+1** |\n"
        "| `order` | **+3** |\n\n"
        "Weights are aggregated by **dish id** and **category name** (from the dish's category).\n\n"
        "When `strategy=hybrid`, recommendations apply a bonus:\n\n"
        "`feedback_bonus = min(weight × 2, 15)` using the stronger dish vs category signal, "
        "added to the hybrid score (capped at **100**). Explanations include e.g. "
        "`Learned preference: Italian (+10)`.\n\n"
        "**Example response**\n\n"
        "```json\n"
        "{\n"
        '  "user_id": 1,\n'
        '  "preferred_categories": {"Italian": 8, "Pakistani": 3},\n'
        '  "preferred_dishes": {"12": 5, "24": 2},\n'
        '  "engine_version": "2.2"\n'
        "}\n"
        "```\n\n"
        "`engine_version`: **2.2**. Requires JWT."
    ),
)
def recommendation_feedback_profile_v2(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    profile = get_user_feedback_profile(db, current_user.id)
    return FeedbackProfileResponse(
        user_id=current_user.id,
        preferred_categories=profile.preferred_categories,
        preferred_dishes=profile.preferred_dishes,
        engine_version="2.2",
    )


@router.post(
    "/recommendations/v2/event",
    response_model=RecommendationEventResponse,
    status_code=status.HTTP_200_OK,
    summary="Log recommendation impression, click, or order",
    description=(
        "**Phase 5.1 + 5.3 — metrics and feedback events**\n\n"
        "Records a recommendation interaction for the authenticated user in "
        "`recommendation_events`.\n\n"
        "**Request body**\n\n"
        "| Field | Type | Description |\n"
        "|-------|------|-------------|\n"
        "| `dish_id` | integer | Dish that was shown, clicked, or ordered |\n"
        "| `event_type` | string | `impression`, `click`, or `order` |\n"
        "| `strategy` | string | Strategy active when the event occurred "
        "(e.g. `content`, `collaborative`, `hybrid`) |\n\n"
        "**Feedback weights** (profile / hybrid bonus; impressions are CTR-only):\n\n"
        "| `event_type` | Weight |\n"
        "|--------------|--------|\n"
        "| `impression` | 0 |\n"
        "| `click` | 1 |\n"
        "| `order` | 3 |\n\n"
        "**Examples**\n\n"
        "```json\n"
        "{\n"
        '  "dish_id": 1,\n'
        '  "event_type": "click",\n'
        '  "strategy": "hybrid"\n'
        "}\n"
        "```\n\n"
        "```json\n"
        "{\n"
        '  "dish_id": 2,\n'
        '  "event_type": "order",\n'
        '  "strategy": "hybrid"\n'
        "}\n"
        "```\n\n"
        "**Response**\n\n"
        "```json\n"
        '{ "status": "ok" }\n'
        "```\n\n"
        "Requires JWT Bearer token. Returns **404** if `dish_id` does not exist."
    ),
    responses={
        200: {"description": "Event stored successfully"},
        404: {"description": "Dish not found"},
        422: {"description": "Validation error (invalid event_type or body)"},
    },
)
def log_recommendation_event_v2(
    body: RecommendationEventCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    get_dish_or_404(db, body.dish_id)
    log_recommendation_event(db, user_id=current_user.id, payload=body)
    return RecommendationEventResponse()
