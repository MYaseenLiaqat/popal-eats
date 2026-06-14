"""Pydantic schemas for group member location sharing."""

from datetime import datetime
from decimal import Decimal

from pydantic import BaseModel, ConfigDict, Field

from app.schemas.friend import UserPublicProfile


class GroupMemberLocationUpdate(BaseModel):
    """Body for POST /groups/{id}/location."""

    latitude: Decimal = Field(..., ge=Decimal("-90"), le=Decimal("90"))
    longitude: Decimal = Field(..., ge=Decimal("-180"), le=Decimal("180"))


class GroupMemberLocationResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    session_id: int
    user_id: int
    latitude: Decimal
    longitude: Decimal
    updated_at: datetime
    user: UserPublicProfile | None = None


class GroupMemberLocationListResponse(BaseModel):
    locations: list[GroupMemberLocationResponse]
