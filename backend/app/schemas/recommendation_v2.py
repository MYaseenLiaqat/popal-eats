"""Pydantic schemas for Recommendation Engine V2."""

from decimal import Decimal
from typing import Literal

from pydantic import BaseModel, Field

EngineStrategy = Literal["content", "collaborative", "hybrid"]


class V2ScoreBreakdown(BaseModel):
    """Content-based component scores (Phase 1), max total 100."""

    cuisine_score: float = Field(0, ge=0, le=50, description="Cuisine match (max 50)")
    nutrition_score: float = Field(0, ge=0, le=25, description="Nutrition goal match (max 25)")
    budget_score: float = Field(0, ge=0, le=15, description="Budget match (max 15)")
    popularity_score: float = Field(0, ge=0, le=10, description="Popularity bonus (max 10)")
    total_score: float = Field(0, ge=0, le=100, description="Sum of components")


class V2DishRecommendationItem(BaseModel):
    dish_id: int
    dish_name: str
    restaurant_name: str
    price: Decimal
    calories: int | None = None
    score: float = Field(..., ge=0, le=100, description="Total content-based score (0–100)")
    score_breakdown: V2ScoreBreakdown
    explanation: str
    signals_used: list[str] = Field(default_factory=list)


class RecommendationsV2Response(BaseModel):
    engine_version: str = Field(default="2.0")
    strategy: EngineStrategy
    items: list[V2DishRecommendationItem] = Field(default_factory=list)
    count: int
