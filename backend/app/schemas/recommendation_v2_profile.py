"""Pydantic schemas for Recommendation Engine V2 feedback profile (Phase 5.3)."""

from pydantic import BaseModel, Field


class FeedbackProfileResponse(BaseModel):
    user_id: int = Field(..., description="Authenticated user id")
    preferred_categories: dict[str, int] = Field(
        default_factory=dict,
        description="Category name → accumulated weight (impression 0, click +1, order +3)",
        json_schema_extra={"example": {"Italian": 8, "Pakistani": 3}},
    )
    preferred_dishes: dict[int, int] = Field(
        default_factory=dict,
        description="Dish id → accumulated weight (impression 0, click +1, order +3)",
        json_schema_extra={"example": {12: 5, 24: 2}},
    )
    engine_version: str = Field(default="2.2")
