"""Pydantic schemas for Recommendation Engine V1."""

from decimal import Decimal

from pydantic import BaseModel, ConfigDict, Field


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
        description="Weighted score: cuisine (40) + nutrition (25) + budget (20) + rating (15)",
    )
    explanation: str = Field(
        ...,
        description="Human-readable reason, e.g. 'Matches your cuisine preferences and high-protein goal.'",
    )


class RecommendationsResponse(BaseModel):
    items: list[DishRecommendationItem] = Field(
        default_factory=list,
        description="Top dishes sorted by recommendation_score (descending)",
    )
    count: int = Field(..., description="Number of recommendations returned (max 10)")
