"""User preference endpoints — GET/PUT /preferences and onboarding."""

from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session

from app.core.dependencies import get_current_user
from app.database import get_db
from app.models.user import User
from app.schemas.preference_onboarding import (
    OnboardingCompleteRequest,
    OnboardingCompleteResponse,
    OnboardingOptionsResponse,
    OnboardingStatusResponse,
)
from app.schemas.user_preference import UserPreferencesResponse, UserPreferencesUpdate
from app.services.preference_onboarding_service import (
    complete_onboarding,
    get_onboarding_options,
    get_onboarding_status,
    skip_onboarding,
)
from app.services.user_preferences_service import get_user_preferences, upsert_user_preferences

router = APIRouter(tags=["preferences"])


@router.get(
    "/preferences/onboarding/options",
    response_model=OnboardingOptionsResponse,
    summary="List food interest and allergy options for onboarding",
)
def read_onboarding_options(
    _: User = Depends(get_current_user),
) -> OnboardingOptionsResponse:
    return get_onboarding_options()


@router.get(
    "/preferences/onboarding/status",
    response_model=OnboardingStatusResponse,
    summary="Check whether preference onboarding is completed",
)
def read_onboarding_status(
    current_user: User = Depends(get_current_user),
) -> OnboardingStatusResponse:
    return get_onboarding_status(current_user)


@router.post(
    "/preferences/onboarding",
    response_model=OnboardingCompleteResponse,
    status_code=status.HTTP_200_OK,
    summary="Complete preference onboarding after signup",
)
def submit_onboarding(
    body: OnboardingCompleteRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> OnboardingCompleteResponse:
    return complete_onboarding(db, current_user, body)


@router.post(
    "/preferences/onboarding/skip",
    response_model=OnboardingStatusResponse,
    summary="Skip preference onboarding",
)
def skip_onboarding_endpoint(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> OnboardingStatusResponse:
    return skip_onboarding(db, current_user)


@router.get(
    "/preferences",
    response_model=UserPreferencesResponse,
    summary="Get current user food preferences",
)
def read_preferences(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> UserPreferencesResponse:
    return get_user_preferences(db, current_user.id)


@router.put(
    "/preferences",
    response_model=UserPreferencesResponse,
    summary="Update current user food preferences",
)
def update_preferences(
    body: UserPreferencesUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> UserPreferencesResponse:
    return upsert_user_preferences(db, current_user.id, body)
