"""Preference onboarding flow after signup."""

from __future__ import annotations

from fastapi import HTTPException, status
from sqlalchemy.orm import Session

from app.models.user import User
from app.schemas.preference_onboarding import (
    ALLERGY_DISPLAY_NAMES,
    FOOD_INTEREST_OPTIONS,
    AllergyOption,
    FoodInterestOption,
    OnboardingCompleteRequest,
    OnboardingCompleteResponse,
    OnboardingOptionsResponse,
    OnboardingStatusResponse,
)
from app.schemas.user_preference import ALLOWED_ALLERGIES, UserPreferencesUpdate
from app.services.user_preferences_service import upsert_user_preferences


class OnboardingError(ValueError):
    """Domain error for onboarding state violations."""


def onboarding_already_completed(user: User) -> bool:
    return bool(getattr(user, "onboarding_completed", False))


def get_onboarding_options() -> OnboardingOptionsResponse:
    food_interests = [FoodInterestOption(**option) for option in FOOD_INTEREST_OPTIONS]
    allergies = [
        AllergyOption(
            key=key,
            display_name=ALLERGY_DISPLAY_NAMES.get(key, key.replace("_", " ").title()),
        )
        for key in sorted(ALLOWED_ALLERGIES)
    ]
    return OnboardingOptionsResponse(food_interests=food_interests, allergies=allergies)


def get_onboarding_status(user: User) -> OnboardingStatusResponse:
    return OnboardingStatusResponse(completed=onboarding_already_completed(user))


def _ensure_not_completed(user: User) -> None:
    if onboarding_already_completed(user):
        raise OnboardingError("Onboarding has already been completed")


def complete_onboarding(
    db: Session,
    user: User,
    payload: OnboardingCompleteRequest,
) -> OnboardingCompleteResponse:
    try:
        _ensure_not_completed(user)
    except OnboardingError as exc:
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail=str(exc)) from exc

    preferences = upsert_user_preferences(
        db,
        user.id,
        UserPreferencesUpdate(
            favorite_cuisines=payload.favorite_cuisines,
            allergies=payload.allergies,
        ),
    )

    user.onboarding_completed = True
    db.commit()
    db.refresh(user)

    return OnboardingCompleteResponse(completed=True, preferences=preferences)


def skip_onboarding(db: Session, user: User) -> OnboardingStatusResponse:
    try:
        _ensure_not_completed(user)
    except OnboardingError as exc:
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail=str(exc)) from exc

    user.onboarding_completed = True
    db.commit()
    db.refresh(user)
    return OnboardingStatusResponse(completed=True)
