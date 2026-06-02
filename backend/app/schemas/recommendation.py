"""Pydantic schemas for Recommendation Engine V1.1."""

from decimal import Decimal

from pydantic import BaseModel, ConfigDict, Field


class ScoreBreakdown(BaseModel):
    cuisine_score: float = Field(0, ge=0, le=40, description="Cuisine match (max 40)")
    nutrition_score: float = Field(0, ge=0, le=25, description="Nutrition goal match (max 25)")
    budget_score: float = Field(0, ge=0, le=20, description="Budget range match (max 20)")
    rating_score: float = Field(0, ge=0, le=15, description="Restaurant rating (max 15)")
    total_score: float = Field(0, ge=0, le=100, description="Sum of component scores")


class DishRecommendationItem(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    dish_id: int = Field(..., description="Dish primary key")
    dish_name: str = Field(..., description="Menu item name")
    restaurant_name: str = Field(..., description="Restaurant serving this dish")
    price: Decimal = Field(..., description="Current dish price")
    calories: int | None = Field(None, description="Calories per serving, if known")
    recommendation_score: float = Field(
        ...,
        ge=0,
        le=100,
        description="Total score (same as score_breakdown.total_score)",
    )
    score_breakdown: ScoreBreakdown = Field(
        ...,
        description="Per-component scores for transparency",
    )
    explanation: str = Field(
        ...,
        description="Human-readable breakdown, e.g. 'Matched Pakistani cuisine (+40), ...'",
    )


class RecommendationsResponse(BaseModel):
    items: list[DishRecommendationItem] = Field(
        default_factory=list,
        description="Top dishes sorted by recommendation_score (descending)",
    )
    count: int = Field(..., description="Number of recommendations returned (max 10)")
    engine_version: str = Field(
        default="1.1",
        description="Recommendation engine version",
    )
