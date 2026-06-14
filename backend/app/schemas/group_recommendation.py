"""Pydantic schemas for group recommendations."""

from decimal import Decimal

from pydantic import BaseModel, Field


class GroupDishRecommendation(BaseModel):
    dish_id: int
    dish_name: str
    restaurant_name: str
    price: Decimal
    score: float = Field(..., ge=0, le=100)
    reasons: list[str] = Field(default_factory=list)


class GroupRecommendationsResponse(BaseModel):
    group_id: int
    member_count: int
    group_latitude: float | None = None
    group_longitude: float | None = None
    recommendations: list[GroupDishRecommendation] = Field(default_factory=list)
