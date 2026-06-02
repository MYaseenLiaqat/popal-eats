"""Recommendation Engine V2 API."""

from typing import Literal

from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session

from app.core.dependencies import get_current_user
from app.database import get_db
from app.models.user import User
from app.schemas.recommendation_v2 import RecommendationsV2Response, SimilarDishesResponse
from app.services.recommendation.v2_collaborative import get_similar_dishes
from app.services.recommendation.v2_hybrid import get_v2_recommendations

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
        "| `hybrid` | Phase 3 blend: **0.7 × content + 0.3 × collaborative**; "
        "falls back to content if user has no orders |\n\n"
        "Returns top **10** dishes with `score`, `score_breakdown`, and `explanation`.\n\n"
        "Related: `GET /recommendations/v2/similar/{dish_id}` for item-based similar dishes.\n\n"
        "Does **not** replace `GET /recommendations` (V1.1).\n\n"
        "Requires JWT Bearer token from `POST /login`."
    ),
)
def list_recommendations_v2(
    strategy: StrategyQuery = Query(
        "content",
        description="content (default) | collaborative | hybrid (0.7 content + 0.3 CF)",
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
