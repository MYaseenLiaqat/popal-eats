"""Pydantic schemas for Restaurant CRUD."""

from datetime import datetime, time

from pydantic import BaseModel, ConfigDict, Field


class RestaurantCreate(BaseModel):
    """Owner is set from the logged-in user — do not send owner_id."""

    name: str = Field(..., min_length=1, max_length=200)
    description: str | None = None
    address: str | None = Field(None, max_length=300)
    city: str | None = Field(None, max_length=100)
    phone_number: str | None = Field(None, max_length=30)
    image: str | None = Field(None, max_length=500)
    opening_time: time | None = None
    closing_time: time | None = None
    is_open: bool = True
    rating: float = Field(0.0, ge=0, le=5)


class RestaurantUpdate(BaseModel):
    name: str | None = Field(None, min_length=1, max_length=200)
    description: str | None = None
    address: str | None = Field(None, max_length=300)
    city: str | None = Field(None, max_length=100)
    phone_number: str | None = Field(None, max_length=30)
    image: str | None = Field(None, max_length=500)
    opening_time: time | None = None
    closing_time: time | None = None
    is_open: bool | None = None
    rating: float | None = Field(None, ge=0, le=5)


class RestaurantResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    owner_id: int
    name: str
    description: str | None = None
    address: str | None = None
    city: str | None = None
    phone_number: str | None = None
    image: str | None = None
    opening_time: time | None = None
    closing_time: time | None = None
    is_open: bool
    rating: float
    created_at: datetime | None = None
