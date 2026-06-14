"""Pydantic schemas for group voting and consensus."""

from datetime import datetime
from decimal import Decimal
from typing import Literal

from pydantic import BaseModel, ConfigDict, Field, field_validator

from app.models.group_vote import VOTE_TYPES

DecisionStatus = Literal["pending", "considering", "agreed", "ordered"]


class GroupVoteCreate(BaseModel):
    vote_type: str

    @field_validator("vote_type")
    @classmethod
    def validate_vote_type(cls, value: str) -> str:
        normalized = value.strip().upper()
        if normalized not in VOTE_TYPES:
            raise ValueError(f"vote_type must be one of: {', '.join(sorted(VOTE_TYPES))}")
        return normalized


class GroupVoteResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    recommendation_id: int
    user_id: int
    vote_type: str
    created_at: datetime


class GroupVoteSummaryResponse(BaseModel):
    likes: int = 0
    loves: int = 0
    dislikes: int = 0
    total_votes: int = 0
    consensus_score: float = Field(0, ge=0, le=100)
    final_score: float = Field(0, ge=0, le=100)


class GroupDecisionResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    session_id: int
    recommendation_id: int | None
    status: str
    created_at: datetime
    updated_at: datetime
    consensus_score: float | None = None
    final_score: float | None = None
    dish_id: int | None = None
    dish_name: str | None = None
    restaurant_name: str | None = None
    price: Decimal | None = None
