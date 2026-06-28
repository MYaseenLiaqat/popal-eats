"""Pydantic schemas for group recommendations."""

from decimal import Decimal

from pydantic import BaseModel, Field


class GroupDishRecommendation(BaseModel):
    recommendation_id: int | None = None
    dish_id: int
    dish_name: str
    restaurant_name: str
    price: Decimal
    score: float = Field(..., ge=0, le=100, description="Engine recommendation score")
    consensus_score: float = Field(0, ge=0, le=100)
    final_score: float | None = Field(None, ge=0, le=100, description="70% recommendation + 30% consensus")
    group_match_percent: int | None = Field(
        None,
        ge=0,
        le=100,
        description="Group compatibility match from engine score",
    )
    reasons: list[str] = Field(default_factory=list)
    explanation_bullets: list[str] = Field(
        default_factory=list,
        description="Top consumer-facing group recommendation reasons",
    )


class GroupRecommendationsResponse(BaseModel):
    group_id: int
    member_count: int
    group_latitude: float | None = None
    group_longitude: float | None = None
    recommendations: list[GroupDishRecommendation] = Field(default_factory=list)
