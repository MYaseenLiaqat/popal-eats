"""User preference endpoints — GET/PUT /preferences."""

from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.core.dependencies import get_current_user
from app.database import get_db
from app.models.user import User
from app.schemas.user_preference import UserPreferencesResponse, UserPreferencesUpdate
from app.services.user_preferences_service import get_user_preferences, upsert_user_preferences

router = APIRouter(tags=["preferences"])


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
