"""Group session lifecycle — create, invite, join, leave."""

from __future__ import annotations

from datetime import datetime, timedelta, timezone

from fastapi import HTTPException, status
from sqlalchemy.orm import Session, joinedload

from app.models.group_invitation import ACCEPTED, PENDING, REJECTED, GroupInvitation
from app.models.group_session import ACTIVE, CLOSED, GroupSession
from app.models.group_session_member import GroupSessionMember
from app.models.user import User
from app.schemas.friend import UserPublicProfile
from app.schemas.group_session import (
    GroupInvitationResponse,
    GroupSessionCreate,
    GroupSessionListResponse,
    GroupSessionMemberResponse,
    GroupSessionResponse,
)
from app.services.friends_service import are_friends

DEFAULT_SESSION_HOURS = 24


class GroupSessionError(ValueError):
    """Domain validation error for group sessions."""


def validate_group_invite(
    *,
    sender_id: int,
    receiver_id: int,
    is_friend: bool,
    is_member: bool,
    pending_invitation: bool,
    session_active: bool,
) -> None:
    """Pure rule check for whether an invitation is allowed."""
    if sender_id == receiver_id:
        raise GroupSessionError("Cannot invite yourself to a group session")
    if not session_active:
        raise GroupSessionError("Invitations are only allowed for active group sessions")
    if not is_friend:
        raise GroupSessionError("You can only invite friends to a group session")
    if is_member:
        raise GroupSessionError("User is already a member of this group session")
    if pending_invitation:
        raise GroupSessionError("A pending invitation already exists for this user")


def _utcnow() -> datetime:
    return datetime.now(timezone.utc)


def _default_expires_at() -> datetime:
    return _utcnow() + timedelta(hours=DEFAULT_SESSION_HOURS)


def _to_profile(user: User | None) -> UserPublicProfile | None:
    return UserPublicProfile.model_validate(user) if user else None


def _session_query(db: Session):
    return db.query(GroupSession).options(
        joinedload(GroupSession.host),
        joinedload(GroupSession.members).joinedload(GroupSessionMember.user),
    )


def _to_session_response(session: GroupSession) -> GroupSessionResponse:
    members = sorted(session.members or [], key=lambda m: m.joined_at)
    return GroupSessionResponse(
        id=session.id,
        name=session.name,
        host_user_id=session.host_user_id,
        status=session.status,
        created_at=session.created_at,
        expires_at=session.expires_at,
        host=_to_profile(session.host),
        members=[
            GroupSessionMemberResponse(
                id=member.id,
                session_id=member.session_id,
                user_id=member.user_id,
                joined_at=member.joined_at,
                user=_to_profile(member.user),
            )
            for member in members
        ],
    )


def _to_invitation_response(invitation: GroupInvitation) -> GroupInvitationResponse:
    return GroupInvitationResponse(
        id=invitation.id,
        session_id=invitation.session_id,
        sender_id=invitation.sender_id,
        receiver_id=invitation.receiver_id,
        status=invitation.status,
        created_at=invitation.created_at,
        sender=_to_profile(invitation.sender),
        receiver=_to_profile(invitation.receiver),
    )


def _get_session_or_404(db: Session, session_id: int) -> GroupSession:
    session = _session_query(db).filter(GroupSession.id == session_id).first()
    if not session:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Group session not found")
    return session


def _get_user_or_404(db: Session, user_id: int) -> User:
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="User not found")
    return user


def _is_member(db: Session, session_id: int, user_id: int) -> bool:
    return (
        db.query(GroupSessionMember.id)
        .filter(
            GroupSessionMember.session_id == session_id,
            GroupSessionMember.user_id == user_id,
        )
        .first()
        is not None
    )


def _is_session_active(session: GroupSession) -> bool:
    if session.status != ACTIVE:
        return False
    expires_at = session.expires_at
    if expires_at.tzinfo is None:
        expires_at = expires_at.replace(tzinfo=timezone.utc)
    return expires_at > _utcnow()


def _require_member(session: GroupSession, user_id: int) -> None:
    if not any(member.user_id == user_id for member in session.members):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="You are not a member of this group session",
        )


def create_group_session(
    db: Session, host_user_id: int, payload: GroupSessionCreate
) -> GroupSessionResponse:
    expires_at = payload.expires_at or _default_expires_at()
    if expires_at.tzinfo is None:
        expires_at = expires_at.replace(tzinfo=timezone.utc)
    if expires_at <= _utcnow():
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="expires_at must be in the future",
        )

    session = GroupSession(
        name=payload.name.strip(),
        host_user_id=host_user_id,
        status=ACTIVE,
        expires_at=expires_at,
    )
    db.add(session)
    db.flush()

    db.add(GroupSessionMember(session_id=session.id, user_id=host_user_id))
    db.commit()

    return _to_session_response(_get_session_or_404(db, session.id))


def list_group_sessions(db: Session, user_id: int) -> GroupSessionListResponse:
    session_ids = [
        row.session_id
        for row in db.query(GroupSessionMember.session_id)
        .filter(GroupSessionMember.user_id == user_id)
        .all()
    ]
    if not session_ids:
        return GroupSessionListResponse(groups=[])

    sessions = (
        _session_query(db)
        .filter(GroupSession.id.in_(session_ids))
        .order_by(GroupSession.created_at.desc())
        .all()
    )
    return GroupSessionListResponse(groups=[_to_session_response(session) for session in sessions])


def get_group_session(db: Session, user_id: int, session_id: int) -> GroupSessionResponse:
    session = _get_session_or_404(db, session_id)
    _require_member(session, user_id)
    return _to_session_response(session)


def invite_to_group_session(
    db: Session, sender_id: int, session_id: int, receiver_id: int
) -> GroupInvitationResponse:
    session = _get_session_or_404(db, session_id)
    _require_member(session, sender_id)
    _get_user_or_404(db, receiver_id)

    pending = (
        db.query(GroupInvitation)
        .filter(
            GroupInvitation.session_id == session_id,
            GroupInvitation.receiver_id == receiver_id,
            GroupInvitation.status == PENDING,
        )
        .first()
        is not None
    )

    try:
        validate_group_invite(
            sender_id=sender_id,
            receiver_id=receiver_id,
            is_friend=are_friends(db, sender_id, receiver_id),
            is_member=_is_member(db, session_id, receiver_id),
            pending_invitation=pending,
            session_active=_is_session_active(session),
        )
    except GroupSessionError as exc:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(exc)) from exc

    existing = (
        db.query(GroupInvitation)
        .filter(
            GroupInvitation.session_id == session_id,
            GroupInvitation.receiver_id == receiver_id,
            GroupInvitation.status.in_([REJECTED, ACCEPTED]),
        )
        .first()
    )
    if existing:
        existing.sender_id = sender_id
        existing.status = PENDING
        db.commit()
        db.refresh(existing)
        existing.sender = db.query(User).filter(User.id == sender_id).first()
        existing.receiver = db.query(User).filter(User.id == receiver_id).first()
        return _to_invitation_response(existing)

    invitation = GroupInvitation(
        session_id=session_id,
        sender_id=sender_id,
        receiver_id=receiver_id,
        status=PENDING,
    )
    db.add(invitation)
    db.commit()
    db.refresh(invitation)
    invitation.sender = db.query(User).filter(User.id == sender_id).first()
    invitation.receiver = db.query(User).filter(User.id == receiver_id).first()
    return _to_invitation_response(invitation)


def accept_group_invitation(
    db: Session, user_id: int, invitation_id: int
) -> GroupInvitationResponse:
    invitation = (
        db.query(GroupInvitation)
        .options(joinedload(GroupInvitation.sender), joinedload(GroupInvitation.receiver))
        .filter(GroupInvitation.id == invitation_id)
        .first()
    )
    if not invitation:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Invitation not found")
    if invitation.receiver_id != user_id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only the invited user can accept this invitation",
        )
    if invitation.status != PENDING:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invitation is no longer pending",
        )

    session = _get_session_or_404(db, invitation.session_id)
    if not _is_session_active(session):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="This group session is no longer active",
        )
    if _is_member(db, session.id, user_id):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="You are already a member of this group session",
        )

    invitation.status = ACCEPTED
    db.add(GroupSessionMember(session_id=session.id, user_id=user_id))
    db.commit()
    db.refresh(invitation)
    return _to_invitation_response(invitation)


def reject_group_invitation(
    db: Session, user_id: int, invitation_id: int
) -> GroupInvitationResponse:
    invitation = (
        db.query(GroupInvitation)
        .options(joinedload(GroupInvitation.sender), joinedload(GroupInvitation.receiver))
        .filter(GroupInvitation.id == invitation_id)
        .first()
    )
    if not invitation:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Invitation not found")
    if invitation.receiver_id != user_id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only the invited user can reject this invitation",
        )
    if invitation.status != PENDING:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invitation is no longer pending",
        )

    invitation.status = REJECTED
    db.commit()
    db.refresh(invitation)
    return _to_invitation_response(invitation)


def leave_group_session(db: Session, user_id: int, session_id: int) -> None:
    session = _get_session_or_404(db, session_id)
    if not _is_member(db, session_id, user_id):
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="You are not a member of this group session",
        )

    db.query(GroupSessionMember).filter(
        GroupSessionMember.session_id == session_id,
        GroupSessionMember.user_id == user_id,
    ).delete(synchronize_session=False)

    if session.host_user_id == user_id:
        session.status = CLOSED

    db.commit()
