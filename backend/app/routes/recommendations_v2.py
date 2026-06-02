"""Recommendation Engine V2 API."""

from typing import Literal

from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session

from app.core.dependencies import get_current_user
from app.database import get_db
from app.models.user import User
from app.schemas.recommendation_v2 import RecommendationsV2Response
from app.services.recommendation.v2_hybrid import get_v2_recommendations

router = APIRouter(tags=["recommendations-v2"])

StrategyQuery = Literal["content", "collaborative", "hybrid"]


@router.get(
    "/recommendations/v2",
    response_model=RecommendationsV2Response,
    summary="Get personalized recommendations (Engine V2 — content)",
    description=(
        "**Recommendation Engine V2 — Phase 1 (content-based)**\n\n"
        "Scores eligible dishes (max **100** points):\n"
        "- **Cuisine** — 50 (dish tags → restaurant tags → category → text)\n"
        "- **Nutrition** — 25 (`nutrition_goal` vs macros/calories)\n"
        "- **Budget** — 15 (`budget_min` / `budget_max` vs price)\n"
        "- **Popularity** — 10 (rating, review count, order count)\n\n"
        "Returns top **10** dishes with `score`, `score_breakdown`, and `explanation`.\n\n"
        "**Query:** `strategy` — `content` (default) or `hybrid` (same as content in Phase 1). "
        "`collaborative` returns empty until Phase 2.\n\n"
        "Uses `user_preferences` when present; falls back to popularity-only ranking.\n\n"
        "Does **not** replace `GET /recommendations` (V1.1).\n\n"
        "Requires JWT Bearer token from `POST /login`."
    ),
)
def list_recommendations_v2(
    strategy: StrategyQuery = Query(
        "content",
        description="content | hybrid (Phase 1 scoring), collaborative (Phase 2)",
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
