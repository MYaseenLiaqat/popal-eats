"""Pydantic schemas for home chef business dashboard."""

from datetime import datetime

from pydantic import BaseModel, ConfigDict, Field

from app.schemas.restaurant import RestaurantDashboardResponse


class HomeChefProfileResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    user_id: int
    display_name: str
    cuisine_specialty: str
    kitchen_address: str
    food_license: str | None = None
    profile_image: str | None = None
    biography: str | None = None
    kitchen_restaurant_id: int | None = None
    phone: str | None = None
    created_at: datetime | None = None
    updated_at: datetime | None = None


class HomeChefProfileUpdate(BaseModel):
    display_name: str | None = Field(None, min_length=1, max_length=200)
    cuisine_specialty: str | None = Field(None, min_length=1, max_length=100)
    kitchen_address: str | None = Field(None, min_length=1, max_length=300)
    food_license: str | None = Field(None, max_length=100)
    biography: str | None = None
    phone: str | None = Field(None, max_length=30)


class HomeChefDashboardResponse(RestaurantDashboardResponse):
    kitchen_restaurant_id: int
    story_views: int = 0
