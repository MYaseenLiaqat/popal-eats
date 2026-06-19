"""Pydantic schemas for Dish CRUD."""

from datetime import datetime
from decimal import Decimal

from pydantic import BaseModel, ConfigDict, Field, field_validator

from app.core.restaurant_constants import DISH_ALLERGENS


def _normalize_allergens(value: list[str] | None) -> list[str] | None:
    if value is None:
        return None
    normalized: list[str] = []
    for item in value:
        tag = item.strip().lower().replace(" ", "_").replace("-", "_")
        if tag in DISH_ALLERGENS and tag not in normalized:
            normalized.append(tag)
    return normalized


class DishCreate(BaseModel):
    restaurant_id: int
    category_id: int
    name: str = Field(..., min_length=1, max_length=200)
    description: str | None = None
    price: Decimal = Field(..., gt=0, max_digits=10, decimal_places=2)
    cuisine: str | None = Field(None, max_length=100)
    calories: int | None = Field(None, ge=0)
    protein: Decimal | None = Field(None, ge=0)
    carbs: Decimal | None = Field(None, ge=0)
    fats: Decimal | None = Field(None, ge=0)
    fiber: Decimal | None = Field(None, ge=0)
    sugar: Decimal | None = Field(None, ge=0)
    sodium: Decimal | None = Field(None, ge=0)
    ingredients: list[str] | None = None
    allergens: list[str] | None = None
    image: str | None = Field(None, max_length=500)
    images: list[str] | None = None
    is_available: bool = True

    @field_validator("allergens")
    @classmethod
    def validate_allergens(cls, value: list[str] | None) -> list[str] | None:
        return _normalize_allergens(value)

    @field_validator("ingredients")
    @classmethod
    def validate_ingredients(cls, value: list[str] | None) -> list[str] | None:
        if value is None:
            return None
        return [item.strip() for item in value if item and item.strip()]


class DishUpdate(BaseModel):
    category_id: int | None = None
    name: str | None = Field(None, min_length=1, max_length=200)
    description: str | None = None
    price: Decimal | None = Field(None, gt=0, max_digits=10, decimal_places=2)
    cuisine: str | None = Field(None, max_length=100)
    calories: int | None = Field(None, ge=0)
    protein: Decimal | None = Field(None, ge=0)
    carbs: Decimal | None = Field(None, ge=0)
    fats: Decimal | None = Field(None, ge=0)
    fiber: Decimal | None = Field(None, ge=0)
    sugar: Decimal | None = Field(None, ge=0)
    sodium: Decimal | None = Field(None, ge=0)
    ingredients: list[str] | None = None
    allergens: list[str] | None = None
    image: str | None = Field(None, max_length=500)
    images: list[str] | None = None
    is_available: bool | None = None

    @field_validator("allergens")
    @classmethod
    def validate_allergens(cls, value: list[str] | None) -> list[str] | None:
        return _normalize_allergens(value)

    @field_validator("ingredients")
    @classmethod
    def validate_ingredients(cls, value: list[str] | None) -> list[str] | None:
        if value is None:
            return None
        return [item.strip() for item in value if item and item.strip()]


class DishResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    restaurant_id: int
    category_id: int
    name: str
    description: str | None = None
    price: Decimal
    cuisine: str | None = None
    calories: int | None = None
    protein: Decimal | None = None
    carbs: Decimal | None = None
    fats: Decimal | None = None
    fiber: Decimal | None = None
    sugar: Decimal | None = None
    sodium: Decimal | None = None
    ingredients: list[str] | None = None
    allergens: list[str] | None = None
    image: str | None = None
    images: list[str] | None = None
    is_available: bool
    created_at: datetime | None = None
