"""Pydantic schemas for friends and user search."""

from datetime import datetime

from pydantic import BaseModel, ConfigDict, Field


class UserPublicProfile(BaseModel):
    """Public user profile for friends and search results."""

    model_config = ConfigDict(from_attributes=True)

    id: int
    full_name: str
    username: str | None = None
    bio: str | None = None
    profile_image: str | None = None


class FriendRequestCreate(BaseModel):
    """Body for POST /friends/request."""

    receiver_id: int = Field(..., gt=0)


class FriendRequestResponse(BaseModel):
    """Friend request with optional embedded user profiles."""

    model_config = ConfigDict(from_attributes=True)

    id: int
    sender_id: int
    receiver_id: int
    status: str
    created_at: datetime
    updated_at: datetime
    sender: UserPublicProfile | None = None
    receiver: UserPublicProfile | None = None


class FriendRequestsListResponse(BaseModel):
    """Incoming and outgoing pending friend requests."""

    incoming: list[FriendRequestResponse]
    outgoing: list[FriendRequestResponse]


class FriendsListResponse(BaseModel):
    """Current user's friends."""

    friends: list[UserPublicProfile]


class UserSearchResponse(BaseModel):
    """User search results."""

    results: list[UserPublicProfile]
