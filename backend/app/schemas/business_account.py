"""Schemas for admin business account approval."""

from datetime import date, datetime

from pydantic import BaseModel, ConfigDict, Field


class RestaurantRegistrationDetail(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    name: str
    address: str | None = None
    cuisine_type: str | None = None
    approval_status: str | None = None
    image: str | None = None


class HomeChefRegistrationDetail(BaseModel):
    display_name: str
    cuisine_specialty: str
    kitchen_address: str
    food_license: str | None = None
    profile_image: str | None = None


class BusinessAccountResponse(BaseModel):
    user_id: int
    role: str
    account_status: str
    full_name: str
    first_name: str | None = None
    last_name: str | None = None
    email: str
    phone: str | None = None
    username: str | None = None
    date_of_birth: date | None = None
    created_at: datetime | None = None
    rejection_reason: str | None = None
    restaurant: RestaurantRegistrationDetail | None = None
    home_chef: HomeChefRegistrationDetail | None = None


class RejectAccountRequest(BaseModel):
    reason: str | None = Field(None, max_length=1000)


class SuspendAccountRequest(BaseModel):
    reason: str | None = Field(None, max_length=1000)
