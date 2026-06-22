"""Pydantic schemas for Review CRUD and AI pipeline status."""

from datetime import datetime

from pydantic import BaseModel, ConfigDict, Field


class ReviewCreate(BaseModel):
    restaurant_id: int
    rating: int = Field(..., ge=1, le=5)
    comment: str | None = Field(None, max_length=2000)


class ReviewUpdate(BaseModel):
    rating: int | None = Field(None, ge=1, le=5)
    comment: str | None = Field(None, max_length=2000)


class ReviewResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    user_id: int
    restaurant_id: int
    rating: int
    comment: str | None = None
    detected_language: str | None = None
    translated_text: str | None = None
    sentiment: str | None = None
    sentiment_score: float | None = None
    processing_status: str = "pending"
    created_at: datetime | None = None
    processed_at: datetime | None = None
    author_name: str | None = None
    author_username: str | None = None


class ReviewProcessingStatus(BaseModel):
    review_id: int
    processing_status: str
    detected_language: str | None = None
    sentiment: str | None = None
    sentiment_score: float | None = None
    processed_at: datetime | None = None
