"""User search for social discovery."""

import re

from fastapi import HTTPException, status
from sqlalchemy import String, and_, cast, or_
from sqlalchemy.orm import Session

from app.core.roles import ADMIN, normalize_role
from app.models.user import User
from app.schemas.friend import UserPublicProfile, UserSearchResponse
from app.services.content_service import _friend_ids


def _profile(row: User) -> UserPublicProfile:
    return UserPublicProfile(
        id=row.id,
        full_name=row.full_name or "",
        username=row.username,
        bio=row.bio,
        profile_image=row.profile_image,
        role=normalize_role(row.role),
    )


def search_users(
    db: Session,
    *,
    current_user_id: int,
    query: str,
    limit: int = 20,
) -> UserSearchResponse:
    """Search users by username, full name, email, or role (case-insensitive, partial match)."""
    normalized = query.strip().lstrip("@")
    if len(normalized) < 2:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Search query must be at least 2 characters",
        )

    pattern = f"%{normalized}%"
    filters = [
        User.username.ilike(pattern),
        User.full_name.ilike(pattern),
        User.email.ilike(pattern),
        cast(User.role, String).ilike(pattern),
    ]

    # Partial handles like yaseen96 -> yaseenliaqat96 (ordered token match).
    chunks = [
        c
        for c in re.findall(r"[a-z]+|\d+", normalized.lower())
        if len(c) >= 2
    ]
    if len(chunks) > 1:
        filters.append(
            and_(*[User.username.ilike(f"%{chunk}%") for chunk in chunks])
        )

    rows = (
        db.query(User)
        .filter(
            User.id != current_user_id,
            User.role != ADMIN,
            or_(*filters),
        )
        .order_by(User.full_name.asc(), User.username.asc().nullslast())
        .limit(min(limit, 50))
        .all()
    )
    return UserSearchResponse(results=[_profile(row) for row in rows])


def list_suggested_users(
    db: Session,
    *,
    current_user_id: int,
    limit: int = 20,
) -> UserSearchResponse:
    """Customers, restaurants, and home chefs the user may want to follow."""
    friends = _friend_ids(db, current_user_id)
    exclude = friends | {current_user_id}

    rows = (
        db.query(User)
        .filter(
            User.id.notin_(exclude) if exclude else True,
            User.role != ADMIN,
        )
        .order_by(User.created_at.desc())
        .limit(min(limit, 30))
        .all()
    )
    return UserSearchResponse(results=[_profile(row) for row in rows])
