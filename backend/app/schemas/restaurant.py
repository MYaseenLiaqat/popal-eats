"""Pydantic schemas for Restaurant CRUD."""

from datetime import datetime, time

from pydantic import BaseModel, ConfigDict, Field, computed_field


class RestaurantCreate(BaseModel):
    name: str = Field(..., min_length=1, max_length=200)
    description: str | None = None
    address: str | None = Field(None, max_length=300)
    city: str | None = Field(None, max_length=100)
    phone_number: str | None = Field(None, max_length=30)
    image: str | None = Field(None, max_length=500)
    opening_time: time | None = None
    closing_time: time | None = None
    is_open: bool = True


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
    average_rating: float = 0.0
    total_reviews: int = 0
    approval_status: str = "approved"
    rejection_reason: str | None = None
    created_at: datetime | None = None

    @computed_field
    @property
    def rating(self) -> float:
        """Backward-compatible alias for average_rating."""
        return self.average_rating


class RestaurantApprovalUpdate(BaseModel):
    approval_status: str = Field(..., pattern="^(approved|rejected)$")
    rejection_reason: str | None = Field(None, max_length=500)


class PopularDishStat(BaseModel):
    dish_id: int
    dish_name: str
    order_count: int


class RestaurantDashboardResponse(BaseModel):
    restaurant_id: int
    restaurant_name: str
    approval_status: str
    total_dishes: int
    available_dishes: int
    average_rating: float
    total_reviews: int
    total_orders: int
    popular_dishes: list[PopularDishStat]
