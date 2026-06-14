"""Friends and friend-request business logic."""

from __future__ import annotations

from fastapi import HTTPException, status
from sqlalchemy.orm import Session, joinedload

from app.models.friend_request import ACCEPTED, PENDING, REJECTED, FriendRequest
from app.models.friendship import Friendship
from app.models.user import User
from app.schemas.friend import (
    FriendRequestResponse,
    FriendRequestsListResponse,
    FriendsListResponse,
    UserPublicProfile,
)


class FriendRequestError(ValueError):
    """Domain validation error for friend requests."""


def validate_friend_request_pair(*, sender_id: int, receiver_id: int) -> None:
    """Pure validation — raises FriendRequestError when request is invalid."""
    if sender_id == receiver_id:
        raise FriendRequestError("Cannot send a friend request to yourself")


def can_send_friend_request(
    *,
    sender_id: int,
    receiver_id: int,
    are_friends: bool,
    pending_exists: bool,
) -> None:
    """Pure rule check for whether a new request is allowed."""
    validate_friend_request_pair(sender_id=sender_id, receiver_id=receiver_id)
    if are_friends:
        raise FriendRequestError("You are already friends with this user")
    if pending_exists:
        raise FriendRequestError("A pending friend request already exists between these users")


def _to_profile(user: User) -> UserPublicProfile:
    return UserPublicProfile.model_validate(user)


def _to_request_response(request: FriendRequest) -> FriendRequestResponse:
    return FriendRequestResponse(
        id=request.id,
        sender_id=request.sender_id,
        receiver_id=request.receiver_id,
        status=request.status,
        created_at=request.created_at,
        updated_at=request.updated_at,
        sender=_to_profile(request.sender) if request.sender else None,
        receiver=_to_profile(request.receiver) if request.receiver else None,
    )


def _get_user_or_404(db: Session, user_id: int) -> User:
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="User not found")
    return user


def are_friends(db: Session, user_a_id: int, user_b_id: int) -> bool:
    """Return True when two users have an accepted friendship."""
    return _are_friends(db, user_a_id, user_b_id)


def _are_friends(db: Session, user_a_id: int, user_b_id: int) -> bool:
    return (
        db.query(Friendship.id)
        .filter(
            Friendship.user_id == user_a_id,
            Friendship.friend_id == user_b_id,
        )
        .first()
        is not None
    )


def _pending_request_exists(db: Session, user_a_id: int, user_b_id: int) -> bool:
    return (
        db.query(FriendRequest.id)
        .filter(
            FriendRequest.status == PENDING,
            (
                (FriendRequest.sender_id == user_a_id)
                & (FriendRequest.receiver_id == user_b_id)
            )
            | (
                (FriendRequest.sender_id == user_b_id)
                & (FriendRequest.receiver_id == user_a_id)
            ),
        )
        .first()
        is not None
    )


def _create_symmetric_friendship(db: Session, user_a_id: int, user_b_id: int) -> None:
    db.add(Friendship(user_id=user_a_id, friend_id=user_b_id))
    db.add(Friendship(user_id=user_b_id, friend_id=user_a_id))


def list_friends(db: Session, user_id: int) -> FriendsListResponse:
    friendships = (
        db.query(Friendship)
        .options(joinedload(Friendship.friend))
        .filter(Friendship.user_id == user_id)
        .order_by(Friendship.created_at.desc())
        .all()
    )
    friends = [_to_profile(row.friend) for row in friendships if row.friend]
    return FriendsListResponse(friends=friends)


def list_friend_requests(db: Session, user_id: int) -> FriendRequestsListResponse:
    incoming = (
        db.query(FriendRequest)
        .options(joinedload(FriendRequest.sender))
        .filter(FriendRequest.receiver_id == user_id, FriendRequest.status == PENDING)
        .order_by(FriendRequest.created_at.desc())
        .all()
    )
    outgoing = (
        db.query(FriendRequest)
        .options(joinedload(FriendRequest.receiver))
        .filter(FriendRequest.sender_id == user_id, FriendRequest.status == PENDING)
        .order_by(FriendRequest.created_at.desc())
        .all()
    )
    return FriendRequestsListResponse(
        incoming=[_to_request_response(row) for row in incoming],
        outgoing=[_to_request_response(row) for row in outgoing],
    )


def send_friend_request(db: Session, sender_id: int, receiver_id: int) -> FriendRequestResponse:
    try:
        can_send_friend_request(
            sender_id=sender_id,
            receiver_id=receiver_id,
            are_friends=_are_friends(db, sender_id, receiver_id),
            pending_exists=_pending_request_exists(db, sender_id, receiver_id),
        )
    except FriendRequestError as exc:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(exc)) from exc

    receiver = _get_user_or_404(db, receiver_id)

    existing = (
        db.query(FriendRequest)
        .filter(
            FriendRequest.sender_id == sender_id,
            FriendRequest.receiver_id == receiver_id,
            FriendRequest.status.in_([REJECTED, ACCEPTED]),
        )
        .first()
    )
    if existing:
        existing.status = PENDING
        existing.sender = db.query(User).filter(User.id == sender_id).first()
        existing.receiver = receiver
        db.commit()
        db.refresh(existing)
        return _to_request_response(existing)

    request = FriendRequest(sender_id=sender_id, receiver_id=receiver_id, status=PENDING)
    db.add(request)
    db.commit()
    db.refresh(request)
    request.sender = db.query(User).filter(User.id == sender_id).first()
    request.receiver = receiver
    return _to_request_response(request)


def accept_friend_request(db: Session, user_id: int, request_id: int) -> FriendRequestResponse:
    request = (
        db.query(FriendRequest)
        .options(joinedload(FriendRequest.sender), joinedload(FriendRequest.receiver))
        .filter(FriendRequest.id == request_id)
        .first()
    )
    if not request:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Friend request not found")
    if request.receiver_id != user_id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only the receiver can accept this request",
        )
    if request.status != PENDING:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Friend request is no longer pending",
        )

    request.status = ACCEPTED
    if not _are_friends(db, request.sender_id, request.receiver_id):
        _create_symmetric_friendship(db, request.sender_id, request.receiver_id)
    db.commit()
    db.refresh(request)
    return _to_request_response(request)


def reject_friend_request(db: Session, user_id: int, request_id: int) -> FriendRequestResponse:
    request = (
        db.query(FriendRequest)
        .options(joinedload(FriendRequest.sender), joinedload(FriendRequest.receiver))
        .filter(FriendRequest.id == request_id)
        .first()
    )
    if not request:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Friend request not found")
    if request.receiver_id != user_id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only the receiver can reject this request",
        )
    if request.status != PENDING:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Friend request is no longer pending",
        )

    request.status = REJECTED
    db.commit()
    db.refresh(request)
    return _to_request_response(request)


def remove_friend(db: Session, user_id: int, friend_id: int) -> None:
    if user_id == friend_id:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Cannot remove yourself as a friend",
        )

    _get_user_or_404(db, friend_id)

    deleted = (
        db.query(Friendship)
        .filter(
            (
                (Friendship.user_id == user_id)
                & (Friendship.friend_id == friend_id)
            )
            | (
                (Friendship.user_id == friend_id)
                & (Friendship.friend_id == user_id)
            )
        )
        .delete(synchronize_session=False)
    )
    if deleted == 0:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Friendship not found")
    db.commit()
