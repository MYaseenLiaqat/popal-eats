"""Group recommendation session endpoints."""

from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session

from app.core.dependencies import get_current_user
from app.database import get_db
from app.models.user import User
from app.schemas.group_recommendation import GroupRecommendationsResponse
from app.schemas.group_location import (
    GroupMemberLocationListResponse,
    GroupMemberLocationResponse,
    GroupMemberLocationUpdate,
)
from app.schemas.group_session import (
    GroupInvitationResponse,
    GroupInviteCreate,
    GroupSessionCreate,
    GroupSessionListResponse,
    GroupSessionResponse,
)
from app.services.group_location_service import (
    list_group_member_locations,
    upsert_group_member_location,
)
from app.services.group_recommendation_service import get_group_recommendations
from app.services.group_session_service import (
    accept_group_invitation,
    create_group_session,
    get_group_session,
    invite_to_group_session,
    leave_group_session,
    list_group_sessions,
    reject_group_invitation,
)

router = APIRouter(tags=["groups"])


@router.post(
    "/groups",
    response_model=GroupSessionResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Create a group session",
)
def create_group(
    body: GroupSessionCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> GroupSessionResponse:
    return create_group_session(db, current_user.id, body)


@router.get("/groups", response_model=GroupSessionListResponse, summary="List my group sessions")
def list_groups(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> GroupSessionListResponse:
    return list_group_sessions(db, current_user.id)


@router.get("/groups/{session_id}", response_model=GroupSessionResponse, summary="Get group session")
def read_group(
    session_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> GroupSessionResponse:
    return get_group_session(db, current_user.id, session_id)


@router.post(
    "/groups/{session_id}/invite",
    response_model=GroupInvitationResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Invite a friend to a group session",
)
def invite_to_group(
    session_id: int,
    body: GroupInviteCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> GroupInvitationResponse:
    return invite_to_group_session(db, current_user.id, session_id, body.receiver_id)


@router.post(
    "/groups/invitations/{invitation_id}/accept",
    response_model=GroupInvitationResponse,
    summary="Accept a group session invitation",
)
def accept_invitation(
    invitation_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> GroupInvitationResponse:
    return accept_group_invitation(db, current_user.id, invitation_id)


@router.post(
    "/groups/invitations/{invitation_id}/reject",
    response_model=GroupInvitationResponse,
    summary="Reject a group session invitation",
)
def reject_invitation(
    invitation_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> GroupInvitationResponse:
    return reject_group_invitation(db, current_user.id, invitation_id)


@router.post(
    "/groups/{session_id}/leave",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Leave a group session",
)
def leave_group(
    session_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> None:
    leave_group_session(db, current_user.id, session_id)


@router.post(
    "/groups/{session_id}/location",
    response_model=GroupMemberLocationResponse,
    summary="Share or update your location in a group session",
)
def update_group_location(
    session_id: int,
    body: GroupMemberLocationUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> GroupMemberLocationResponse:
    return upsert_group_member_location(db, current_user.id, session_id, body)


@router.get(
    "/groups/{session_id}/location",
    response_model=GroupMemberLocationListResponse,
    summary="List member locations for a group session",
)
def get_group_locations(
    session_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> GroupMemberLocationListResponse:
    return list_group_member_locations(db, current_user.id, session_id)


@router.get(
    "/groups/{session_id}/recommendations",
    response_model=GroupRecommendationsResponse,
    summary="Get ranked dish recommendations for a group session",
)
def read_group_recommendations(
    session_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> GroupRecommendationsResponse:
    return get_group_recommendations(db, current_user.id, session_id)
