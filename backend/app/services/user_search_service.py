"""User search for social discovery."""

from fastapi import HTTPException, status
from sqlalchemy import or_
from sqlalchemy.orm import Session

from app.models.user import User
from app.schemas.friend import UserPublicProfile, UserSearchResponse


def search_users(
    db: Session,
    *,
    current_user_id: int,
    query: str,
    limit: int = 20,
) -> UserSearchResponse:
    """Search users by username or full name (case-insensitive)."""
    normalized = query.strip()
    if len(normalized) < 2:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Search query must be at least 2 characters",
        )

    pattern = f"%{normalized}%"
    rows = (
        db.query(User)
        .filter(
            User.id != current_user_id,
            or_(
                User.username.ilike(pattern),
                User.full_name.ilike(pattern),
            ),
        )
        .order_by(User.username.asc().nullslast(), User.full_name.asc())
        .limit(min(limit, 50))
        .all()
    )
    return UserSearchResponse(results=[UserPublicProfile.model_validate(row) for row in rows])
