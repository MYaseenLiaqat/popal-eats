"""Recommendation Engine V2 API (Phase 0 — contract stub)."""

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
    summary="Get personalized recommendations (Engine V2)",
    description=(
        "**Recommendation Engine V2** — Phase 0 contract stub.\n\n"
        "Returns `engine_version: \"2.0\"` and an empty `items` list. "
        "Scoring logic will be added in later phases.\n\n"
        "**Query:** `strategy` — `content` (default), `collaborative`, or `hybrid` "
        "(only `content` is wired in Phase 0; others return empty).\n\n"
        "Does **not** replace `GET /recommendations` (V1.1).\n\n"
        "Requires JWT Bearer token from `POST /login`."
    ),
)
def list_recommendations_v2(
    strategy: StrategyQuery = Query(
        "content",
        description="Recommendation strategy (Phase 0: content only, empty results)",
    ),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    raw_items = get_v2_recommendations(db, current_user.id, strategy=strategy)
    return RecommendationsV2Response(
        engine_version="2.0",
        strategy=strategy,
        items=raw_items,
        count=len(raw_items),
    )
