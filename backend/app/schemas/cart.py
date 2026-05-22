"""Pydantic schemas for cart and cart items."""

from datetime import datetime
from decimal import Decimal

from pydantic import BaseModel, ConfigDict, Field

from app.schemas.dish import DishResponse


class CartItemAdd(BaseModel):
    dish_id: int
    quantity: int = Field(..., ge=1, le=99)


class CartItemUpdate(BaseModel):
    quantity: int = Field(..., ge=1, le=99)


class CartItemResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    cart_id: int
    dish_id: int
    quantity: int
    created_at: datetime | None = None
    dish: DishResponse | None = None


class CartResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    user_id: int
    created_at: datetime | None = None
    items: list[CartItemResponse] = []
    restaurant_id: int | None = None
    subtotal: Decimal = Decimal("0.00")
