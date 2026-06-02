"""Pydantic schemas for Recommendation Engine V2 (Phase 0 contract)."""

from decimal import Decimal
from typing import Literal

from pydantic import BaseModel, Field

EngineStrategy = Literal["content", "collaborative", "hybrid"]


class V2ScoreBreakdown(BaseModel):
    """Component scores for V2 (0–1 normalized). Populated in later phases."""

    content_score: float = Field(0.0, ge=0, le=1)
    collaborative_score: float = Field(0.0, ge=0, le=1)
    popularity_score: float = Field(0.0, ge=0, le=1)
    sentiment_score: float = Field(0.0, ge=0, le=1)
    total_score: float = Field(0.0, ge=0, le=1)


class V2DishRecommendationItem(BaseModel):
    dish_id: int
    dish_name: str
    restaurant_name: str
    price: Decimal
    calories: int | None = None
    recommendation_score: float = Field(..., ge=0, le=1)
    score_breakdown: V2ScoreBreakdown
    explanation: str
    signals_used: list[str] = Field(default_factory=list)


class RecommendationsV2Response(BaseModel):
    engine_version: str = Field(
        default="2.0",
        description="Recommendation engine version",
    )
    strategy: EngineStrategy = Field(
        ...,
        description="Scoring strategy requested (Phase 0: content returns empty items)",
    )
    items: list[V2DishRecommendationItem] = Field(
        default_factory=list,
        description="Ranked dish recommendations (empty in Phase 0)",
    )
    count: int = Field(..., description="Number of items returned")
