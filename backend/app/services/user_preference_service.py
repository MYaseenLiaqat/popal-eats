"""CRUD operations for user preferences."""

from datetime import datetime, timezone

from sqlalchemy.orm import Session

from app.models.user_preference import UserPreference
from app.schemas.user_preference import UserPreferencesUpdate


def _default_preferences(user_id: int) -> UserPreference:
    return UserPreference(
        user_id=user_id,
        favorite_cuisines=[],
        dietary_preference=None,
        nutrition_goal=None,
        budget_min=None,
        budget_max=None,
    )


def get_or_create_preferences(db: Session, user_id: int) -> UserPreference:
    """Return preferences for the user, creating an empty row if none exists."""
    prefs = db.query(UserPreference).filter(UserPreference.user_id == user_id).first()
    if prefs:
        return prefs

    prefs = _default_preferences(user_id)
    db.add(prefs)
    db.commit()
    db.refresh(prefs)
    return prefs


def get_preferences(db: Session, user_id: int) -> UserPreference | None:
    return db.query(UserPreference).filter(UserPreference.user_id == user_id).first()


def update_preferences(
    db: Session,
    user_id: int,
    body: UserPreferencesUpdate,
) -> UserPreference:
    """Upsert preferences — partial update via exclude_unset fields."""
    prefs = get_preferences(db, user_id)
    if not prefs:
        prefs = _default_preferences(user_id)
        db.add(prefs)
        db.flush()

    data = body.model_dump(exclude_unset=True)

    if "budget_min" in data or "budget_max" in data:
        new_min = data.get("budget_min", prefs.budget_min)
        new_max = data.get("budget_max", prefs.budget_max)
        if new_min is not None and new_max is not None and new_max < new_min:
            raise ValueError("budget_max must be greater than or equal to budget_min")

    for key, value in data.items():
        setattr(prefs, key, value)

    prefs.updated_at = datetime.now(timezone.utc)
    db.add(prefs)
    db.commit()
    db.refresh(prefs)
    return prefs
