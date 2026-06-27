"""Pydantic schemas for user preference management."""

from decimal import Decimal
from typing import Literal

from pydantic import BaseModel, ConfigDict, Field, field_validator

BudgetLevel = Literal["low", "medium", "high", "premium"]
NutritionGoal = Literal["maintain", "weight_loss", "bulking", "muscle_gain", "high_protein"]

ALLOWED_NUTRITION_GOALS = frozenset(
    {"maintain", "weight_loss", "bulking", "muscle_gain", "high_protein"}
)

ALLOWED_DIETARY_PREFERENCES = frozenset(
    {
        "vegetarian",
        "vegan",
        "halal",
        "gluten_free",
        "dairy_free",
        "nut_free",
        "pescatarian",
        "keto",
        "low_carb",
    }
)

ALLOWED_ALLERGIES = frozenset(
    {
        "peanuts",
        "tree_nuts",
        "shellfish",
        "fish",
        "eggs",
        "milk",
        "dairy",
        "soy",
        "wheat",
        "gluten",
        "sesame",
        "mustard",
        "celery",
        "sulphites",
        "lupin",
        "molluscs",
        "lactose",
        "nuts",
    }
)

MAX_FAVORITE_CUISINES = 15
MAX_DISLIKED_CATEGORIES = 20
MAX_ALLERGIES = 20
MAX_CUISINE_LENGTH = 50
MAX_CATEGORY_LENGTH = 80


def _normalize_string_list(values: list[str] | None, *, max_items: int, max_len: int) -> list[str]:
    if not values:
        return []
    cleaned: list[str] = []
    seen: set[str] = set()
    for raw in values[:max_items]:
        text = str(raw).strip()
        if not text:
            continue
        if len(text) > max_len:
            raise ValueError(f"Each entry must be at most {max_len} characters")
        key = text.lower()
        if key in seen:
            continue
        seen.add(key)
        cleaned.append(key)
    return cleaned


class UserPreferencesResponse(BaseModel):
    favorite_cuisines: list[str] = Field(default_factory=list)
    dietary_preferences: list[str] = Field(default_factory=list)
    nutrition_goal: NutritionGoal | None = None
    budget_level: BudgetLevel | None = None
    disliked_categories: list[str] = Field(default_factory=list)
    allergies: list[str] = Field(default_factory=list)


class UserPreferencesUpdate(BaseModel):
    favorite_cuisines: list[str] | None = None
    dietary_preferences: list[str] | None = None
    nutrition_goal: NutritionGoal | None = None
    budget_level: BudgetLevel | None = None
    disliked_categories: list[str] | None = None
    allergies: list[str] | None = None

    @field_validator("nutrition_goal", mode="before")
    @classmethod
    def validate_nutrition_goal(cls, value: str | None) -> str | None:
        if value is None:
            return None
        normalized = str(value).strip().lower().replace(" ", "_").replace("-", "_")
        aliases = {
            "weightloss": "weight_loss",
            "lose_weight": "weight_loss",
            "muscle": "muscle_gain",
            "highprotein": "high_protein",
            "bulk": "bulking",
            "balanced": "maintain",
        }
        normalized = aliases.get(normalized, normalized)
        if normalized not in ALLOWED_NUTRITION_GOALS:
            allowed = ", ".join(sorted(ALLOWED_NUTRITION_GOALS))
            raise ValueError(f"nutrition_goal must be one of: {allowed}")
        return normalized

    @field_validator("favorite_cuisines")
    @classmethod
    def validate_favorite_cuisines(cls, value: list[str] | None) -> list[str] | None:
        if value is None:
            return None
        return _normalize_string_list(
            value,
            max_items=MAX_FAVORITE_CUISINES,
            max_len=MAX_CUISINE_LENGTH,
        )

    @field_validator("disliked_categories")
    @classmethod
    def validate_disliked_categories(cls, value: list[str] | None) -> list[str] | None:
        if value is None:
            return None
        return _normalize_string_list(
            value,
            max_items=MAX_DISLIKED_CATEGORIES,
            max_len=MAX_CATEGORY_LENGTH,
        )

    @field_validator("dietary_preferences")
    @classmethod
    def validate_dietary_preferences(cls, value: list[str] | None) -> list[str] | None:
        if value is None:
            return None
        normalized: list[str] = []
        seen: set[str] = set()
        for raw in value[:MAX_FAVORITE_CUISINES]:
            key = str(raw).strip().lower().replace(" ", "_").replace("-", "_")
            if not key:
                continue
            if key not in ALLOWED_DIETARY_PREFERENCES:
                allowed = ", ".join(sorted(ALLOWED_DIETARY_PREFERENCES))
                raise ValueError(f"Invalid dietary preference '{raw}'. Allowed: {allowed}")
            if key not in seen:
                seen.add(key)
                normalized.append(key)
        return normalized

    @field_validator("allergies")
    @classmethod
    def validate_allergies(cls, value: list[str] | None) -> list[str] | None:
        if value is None:
            return None
        normalized: list[str] = []
        seen: set[str] = set()
        for raw in value[:MAX_ALLERGIES]:
            key = str(raw).strip().lower().replace(" ", "_").replace("-", "_")
            if not key:
                continue
            if key not in ALLOWED_ALLERGIES:
                allowed = ", ".join(sorted(ALLOWED_ALLERGIES))
                raise ValueError(f"Invalid allergy '{raw}'. Allowed: {allowed}")
            if key not in seen:
                seen.add(key)
                normalized.append(key)
        return normalized


class RecommendationPreferences(BaseModel):
    """Normalized preferences consumed by the recommendation engine."""

    model_config = ConfigDict(arbitrary_types_allowed=True)

    favorite_cuisines: list[str] = Field(default_factory=list)
    dietary_preferences: list[str] = Field(default_factory=list)
    disliked_categories: list[str] = Field(default_factory=list)
    allergies: list[str] = Field(default_factory=list)
    nutrition_goal: str | None = None
    budget_min: Decimal | None = None
    budget_max: Decimal | None = None
    budget_level: BudgetLevel | None = None
