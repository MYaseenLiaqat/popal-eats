"""Group member location sharing for recommendation sessions."""

from __future__ import annotations

from fastapi import HTTPException, status
from sqlalchemy.orm import Session, joinedload

from app.models.group_member_location import GroupMemberLocation
from app.models.group_session_member import GroupSessionMember
from app.models.user import User
from app.schemas.friend import UserPublicProfile
from app.schemas.group_location import (
    GroupMemberLocationListResponse,
    GroupMemberLocationResponse,
    GroupMemberLocationUpdate,
)
from app.services.group_session_service import _get_session_or_404, _require_member


def _to_location_response(location: GroupMemberLocation) -> GroupMemberLocationResponse:
    return GroupMemberLocationResponse(
        id=location.id,
        session_id=location.session_id,
        user_id=location.user_id,
        latitude=location.latitude,
        longitude=location.longitude,
        updated_at=location.updated_at,
        user=UserPublicProfile.model_validate(location.user) if location.user else None,
    )


def upsert_group_member_location(
    db: Session,
    user_id: int,
    session_id: int,
    payload: GroupMemberLocationUpdate,
) -> GroupMemberLocationResponse:
    session = _get_session_or_404(db, session_id)
    _require_member(session, user_id)

    location = (
        db.query(GroupMemberLocation)
        .options(joinedload(GroupMemberLocation.user))
        .filter(
            GroupMemberLocation.session_id == session_id,
            GroupMemberLocation.user_id == user_id,
        )
        .first()
    )

    if location is None:
        location = GroupMemberLocation(
            session_id=session_id,
            user_id=user_id,
            latitude=payload.latitude,
            longitude=payload.longitude,
        )
        db.add(location)
    else:
        location.latitude = payload.latitude
        location.longitude = payload.longitude

    db.commit()
    db.refresh(location)
    if location.user is None:
        location.user = db.query(User).filter(User.id == user_id).first()
    return _to_location_response(location)


def list_group_member_locations(
    db: Session,
    user_id: int,
    session_id: int,
) -> GroupMemberLocationListResponse:
    session = _get_session_or_404(db, session_id)
    _require_member(session, user_id)

    locations = (
        db.query(GroupMemberLocation)
        .options(joinedload(GroupMemberLocation.user))
        .filter(GroupMemberLocation.session_id == session_id)
        .order_by(GroupMemberLocation.updated_at.desc())
        .all()
    )
    return GroupMemberLocationListResponse(
        locations=[_to_location_response(row) for row in locations]
    )


def is_group_member(db: Session, session_id: int, user_id: int) -> bool:
    """Public helper for membership checks."""
    return (
        db.query(GroupSessionMember.id)
        .filter(
            GroupSessionMember.session_id == session_id,
            GroupSessionMember.user_id == user_id,
        )
        .first()
        is not None
    )
