"""Pydantic schemas for orders and checkout."""

from datetime import datetime
from decimal import Decimal

from pydantic import BaseModel, ConfigDict, Field

from app.core.constants import ORDER_STATUSES, PAYMENT_STATUSES


class CheckoutCreate(BaseModel):
    """Body for POST /checkout — converts cart to order."""

    delivery_address: str = Field(..., min_length=5, max_length=500)


class OrderItemResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    order_id: int
    dish_id: int
    quantity: int
    price: Decimal
    created_at: datetime | None = None


class OrderResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    user_id: int
    restaurant_id: int
    total_price: Decimal
    status: str
    payment_status: str
    delivery_address: str
    rider_name: str | None = None
    created_at: datetime | None = None
    items: list[OrderItemResponse] = []


class OrderStatusUpdate(BaseModel):
    status: str = Field(..., description=f"One of: {', '.join(sorted(ORDER_STATUSES))}")

    rider_name: str | None = Field(None, max_length=120)


class PaymentStatusUpdate(BaseModel):
    payment_status: str = Field(..., description=f"One of: {', '.join(sorted(PAYMENT_STATUSES))}")
