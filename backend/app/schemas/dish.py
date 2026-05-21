"""Pydantic schemas for Dish CRUD."""

from datetime import datetime
from decimal import Decimal

from pydantic import BaseModel, ConfigDict, Field


class DishCreate(BaseModel):
    restaurant_id: int
    category_id: int
    name: str = Field(..., min_length=1, max_length=200)
    description: str | None = None
    price: Decimal = Field(..., gt=0, max_digits=10, decimal_places=2)
    calories: int | None = Field(None, ge=0)
    protein: Decimal | None = Field(None, ge=0)
    carbs: Decimal | None = Field(None, ge=0)
    fats: Decimal | None = Field(None, ge=0)
    image: str | None = Field(None, max_length=500)
    is_available: bool = True


class DishUpdate(BaseModel):
    category_id: int | None = None
    name: str | None = Field(None, min_length=1, max_length=200)
    description: str | None = None
    price: Decimal | None = Field(None, gt=0, max_digits=10, decimal_places=2)
    calories: int | None = Field(None, ge=0)
    protein: Decimal | None = Field(None, ge=0)
    carbs: Decimal | None = Field(None, ge=0)
    fats: Decimal | None = Field(None, ge=0)
    image: str | None = Field(None, max_length=500)
    is_available: bool | None = None


class DishResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    restaurant_id: int
    category_id: int
    name: str
    description: str | None = None
    price: Decimal
    calories: int | None = None
    protein: Decimal | None = None
    carbs: Decimal | None = None
    fats: Decimal | None = None
    image: str | None = None
    is_available: bool
    created_at: datetime | None = None
