"""Friends and friend-request endpoints."""

from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session

from app.core.dependencies import get_current_user
from app.database import get_db
from app.models.user import User
from app.schemas.friend import (
    FriendRequestCreate,
    FriendRequestResponse,
    FriendRequestsListResponse,
    FriendsListResponse,
    UserSearchResponse,
)
from app.services.friends_service import (
    accept_friend_request,
    list_friend_requests,
    list_friends,
    reject_friend_request,
    remove_friend,
    send_friend_request,
)
from app.services.user_search_service import search_users

router = APIRouter(tags=["friends"])


@router.get("/friends", response_model=FriendsListResponse, summary="List current user's friends")
def get_friends(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> FriendsListResponse:
    return list_friends(db, current_user.id)


@router.get(
    "/friends/requests",
    response_model=FriendRequestsListResponse,
    summary="List pending friend requests",
)
def get_friend_requests(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> FriendRequestsListResponse:
    return list_friend_requests(db, current_user.id)


@router.post(
    "/friends/request",
    response_model=FriendRequestResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Send a friend request",
)
def create_friend_request(
    body: FriendRequestCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> FriendRequestResponse:
    return send_friend_request(db, current_user.id, body.receiver_id)


@router.post(
    "/friends/request/{request_id}/accept",
    response_model=FriendRequestResponse,
    summary="Accept a friend request",
)
def accept_request(
    request_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> FriendRequestResponse:
    return accept_friend_request(db, current_user.id, request_id)


@router.post(
    "/friends/request/{request_id}/reject",
    response_model=FriendRequestResponse,
    summary="Reject a friend request",
)
def reject_request(
    request_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> FriendRequestResponse:
    return reject_friend_request(db, current_user.id, request_id)


@router.delete(
    "/friends/{friend_id}",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Remove a friend",
)
def delete_friend(
    friend_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> None:
    remove_friend(db, current_user.id, friend_id)


@router.get("/users/search", response_model=UserSearchResponse, summary="Search users by username or name")
def search_users_endpoint(
    q: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> UserSearchResponse:
    return search_users(db, current_user_id=current_user.id, query=q)
