"""Pydantic schemas for user preferences."""

from datetime import datetime
from decimal import Decimal

from pydantic import BaseModel, ConfigDict, Field, field_validator


class UserPreferencesUpdate(BaseModel):
    favorite_cuisines: list[str] | None = Field(
        None,
        description="Cuisine tags, e.g. ['italian', 'pakistani', 'chinese']",
    )
    dietary_preference: str | None = Field(
        None,
        max_length=64,
        description="e.g. vegetarian, vegan, halal, kosher, none",
    )
    nutrition_goal: str | None = Field(
        None,
        max_length=64,
        description="e.g. weight_loss, muscle_gain, balanced, low_carb",
    )
    budget_min: Decimal | None = Field(None, ge=0, max_digits=10, decimal_places=2)
    budget_max: Decimal | None = Field(None, ge=0, max_digits=10, decimal_places=2)

    @field_validator("favorite_cuisines")
    @classmethod
    def normalize_cuisines(cls, value: list[str] | None) -> list[str] | None:
        if value is None:
            return None
        return [c.strip().lower() for c in value if c and c.strip()]

    @field_validator("budget_max")
    @classmethod
    def budget_max_gte_min(cls, budget_max: Decimal | None, info) -> Decimal | None:
        budget_min = info.data.get("budget_min")
        if budget_max is not None and budget_min is not None and budget_max < budget_min:
            raise ValueError("budget_max must be greater than or equal to budget_min")
        return budget_max


class UserPreferencesResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    user_id: int
    favorite_cuisines: list[str] = Field(default_factory=list)
    dietary_preference: str | None = None
    nutrition_goal: str | None = None
    budget_min: Decimal | None = None
    budget_max: Decimal | None = None
    created_at: datetime | None = None
    updated_at: datetime | None = None
