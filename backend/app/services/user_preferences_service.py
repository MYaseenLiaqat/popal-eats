"""User preference persistence and budget-level mapping."""

from __future__ import annotations

from decimal import Decimal

from sqlalchemy.orm import Session

from app.models.user_preference import UserPreference
from app.schemas.user_preference import (
    BudgetLevel,
    RecommendationPreferences,
    UserPreferencesResponse,
    UserPreferencesUpdate,
)

# PKR dish price bands (typical Foodpanda Lahore/Karachi ranges).
BUDGET_LEVEL_BOUNDS: dict[str, tuple[Decimal | None, Decimal | None]] = {
    "low": (None, Decimal("800")),
    "medium": (Decimal("800"), Decimal("2000")),
    "high": (Decimal("2000"), Decimal("5000")),
    "premium": (Decimal("5000"), None),
}


def budget_bounds_for_level(level: str | None) -> tuple[Decimal | None, Decimal | None]:
    if not level:
        return None, None
    return BUDGET_LEVEL_BOUNDS.get(level, (None, None))


def infer_budget_level(
    budget_min: Decimal | None,
    budget_max: Decimal | None,
    stored_level: str | None = None,
) -> BudgetLevel | None:
    if stored_level in BUDGET_LEVEL_BOUNDS:
        return stored_level  # type: ignore[return-value]
    if budget_min is None and budget_max is None:
        return None
    for level, (low, high) in BUDGET_LEVEL_BOUNDS.items():
        if low == budget_min and high == budget_max:
            return level  # type: ignore[return-value]
    if budget_max is not None and budget_max <= Decimal("800"):
        return "low"
    if budget_min is not None and budget_min >= Decimal("5000"):
        return "premium"
    if budget_min is not None and budget_min >= Decimal("2000"):
        return "high"
    return "medium"


def _normalize_json_list(raw) -> list[str]:
    if not raw or not isinstance(raw, list):
        return []
    return [str(item).strip().lower() for item in raw if item and str(item).strip()]


def _dietary_preferences_list(row: UserPreference | None) -> list[str]:
    if row is None:
        return []
    if row.dietary_preferences:
        return _normalize_json_list(row.dietary_preferences)
    if row.dietary_preference:
        return [str(row.dietary_preference).strip().lower()]
    return []


def _to_response(row: UserPreference | None) -> UserPreferencesResponse:
    if row is None:
        return UserPreferencesResponse()
    goal = row.nutrition_goal.strip().lower() if row.nutrition_goal else None
    if goal and goal not in {"maintain", "weight_loss", "bulking", "muscle_gain", "high_protein"}:
        goal = None
    return UserPreferencesResponse(
        favorite_cuisines=_normalize_json_list(row.favorite_cuisines),
        dietary_preferences=_dietary_preferences_list(row),
        nutrition_goal=goal,  # type: ignore[arg-type]
        budget_level=infer_budget_level(row.budget_min, row.budget_max, row.budget_level),
        disliked_categories=_normalize_json_list(row.disliked_categories),
        allergies=_normalize_json_list(row.allergies),
    )


def get_user_preferences(db: Session, user_id: int) -> UserPreferencesResponse:
    row = db.get(UserPreference, user_id)
    return _to_response(row)


def upsert_user_preferences(
    db: Session,
    user_id: int,
    payload: UserPreferencesUpdate,
) -> UserPreferencesResponse:
    row = db.get(UserPreference, user_id)
    if row is None:
        row = UserPreference(user_id=user_id)
        db.add(row)

    if payload.favorite_cuisines is not None:
        row.favorite_cuisines = payload.favorite_cuisines
    if payload.dietary_preferences is not None:
        row.dietary_preferences = payload.dietary_preferences
        row.dietary_preference = payload.dietary_preferences[0] if payload.dietary_preferences else None
    if payload.disliked_categories is not None:
        row.disliked_categories = payload.disliked_categories
    if payload.allergies is not None:
        row.allergies = payload.allergies
    if payload.budget_level is not None:
        row.budget_level = payload.budget_level
        row.budget_min, row.budget_max = budget_bounds_for_level(payload.budget_level)
    if payload.nutrition_goal is not None:
        row.nutrition_goal = payload.nutrition_goal

    db.commit()
    db.refresh(row)
    return _to_response(row)


def load_recommendation_preferences(db: Session, user_id: int) -> RecommendationPreferences:
    row = db.get(UserPreference, user_id)
    if row is None:
        return RecommendationPreferences()

    budget_min = row.budget_min
    budget_max = row.budget_max
    level = infer_budget_level(budget_min, budget_max, row.budget_level)
    if level and (budget_min is None and budget_max is None):
        budget_min, budget_max = budget_bounds_for_level(level)

    dietary = _normalize_json_list(row.dietary_preferences)
    if not dietary and row.dietary_preference:
        dietary = [str(row.dietary_preference).strip().lower()]

    return RecommendationPreferences(
        favorite_cuisines=_normalize_json_list(row.favorite_cuisines),
        dietary_preferences=dietary,
        disliked_categories=_normalize_json_list(row.disliked_categories),
        allergies=_normalize_json_list(row.allergies),
        nutrition_goal=row.nutrition_goal,
        budget_min=budget_min,
        budget_max=budget_max,
        budget_level=level,
    )
