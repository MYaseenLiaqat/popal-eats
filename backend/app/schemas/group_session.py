"""Pydantic schemas for group recommendation sessions."""

from datetime import datetime

from pydantic import BaseModel, ConfigDict, Field

from app.schemas.friend import UserPublicProfile


class GroupSessionCreate(BaseModel):
    """Body for POST /groups."""

    name: str = Field(..., min_length=1, max_length=120)
    expires_at: datetime | None = Field(
        None,
        description="Optional expiry; defaults to 24 hours from creation",
    )


class GroupInviteCreate(BaseModel):
    """Body for POST /groups/{id}/invite."""

    receiver_id: int = Field(..., gt=0)


class GroupSessionMemberResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    session_id: int
    user_id: int
    joined_at: datetime
    user: UserPublicProfile | None = None


class GroupInvitationResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    session_id: int
    sender_id: int
    receiver_id: int
    status: str
    created_at: datetime
    sender: UserPublicProfile | None = None
    receiver: UserPublicProfile | None = None


class GroupSessionResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    name: str
    host_user_id: int
    status: str
    created_at: datetime
    expires_at: datetime
    host: UserPublicProfile | None = None
    members: list[GroupSessionMemberResponse] = Field(default_factory=list)


class GroupSessionListResponse(BaseModel):
    groups: list[GroupSessionResponse]
