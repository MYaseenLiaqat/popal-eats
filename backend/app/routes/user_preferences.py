"""User preferences API — JWT-protected profile settings for recommendations."""

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.core.dependencies import get_current_user
from app.database import get_db
from app.models.user import User
from app.schemas.user_preference import UserPreferencesResponse, UserPreferencesUpdate
from app.services import user_preference_service as pref_service

router = APIRouter(prefix="/users", tags=["user-preferences"])


@router.get(
    "/preferences",
    response_model=UserPreferencesResponse,
    summary="Get current user preferences",
    description=(
        "Returns taste and budget preferences for the authenticated user. "
        "Creates an empty preference profile on first access if none exists."
    ),
)
def get_user_preferences(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    prefs = pref_service.get_or_create_preferences(db, current_user.id)
    return prefs


@router.put(
    "/preferences",
    response_model=UserPreferencesResponse,
    summary="Update current user preferences",
    description=(
        "Partially updates preferences for the authenticated user. "
        "Only fields sent in the body are changed; omitted fields are left unchanged."
    ),
)
def update_user_preferences(
    body: UserPreferencesUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    try:
        prefs = pref_service.update_preferences(db, current_user.id, body)
    except ValueError as exc:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(exc)) from exc
    return prefs
