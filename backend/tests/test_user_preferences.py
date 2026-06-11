"""Tests for user preferences and recommendation personalization."""

from decimal import Decimal

import pytest
from pydantic import ValidationError

from app.schemas.user_preference import UserPreferencesUpdate
from app.services.recommendation.preference_scoring import (
    is_disliked_category,
    score_dietary_preferences,
)
from app.services.user_preferences_service import budget_bounds_for_level, infer_budget_level


class _Category:
    def __init__(self, name: str):
        self.name = name


class _Dish:
    def __init__(self, *, name: str, category_name: str | None = None, description: str = ""):
        self.name = name
        self.description = description
        self.category = _Category(category_name) if category_name else None
        self.restaurant = None


def test_budget_level_mapping():
    low_min, low_max = budget_bounds_for_level("low")
    assert low_min is None
    assert low_max == Decimal("800")

    high_min, high_max = budget_bounds_for_level("high")
    assert high_min == Decimal("2000")
    assert high_max == Decimal("5000")

    assert infer_budget_level(Decimal("800"), Decimal("2000"), "medium") == "medium"


def test_preferences_update_validation():
    payload = UserPreferencesUpdate(
        favorite_cuisines=["Biryani", "bbq"],
        dietary_preferences=["halal", "vegetarian"],
        budget_level="medium",
        disliked_categories=["Desserts"],
    )
    assert payload.favorite_cuisines == ["biryani", "bbq"]
    assert payload.dietary_preferences == ["halal", "vegetarian"]

    with pytest.raises(ValidationError):
        UserPreferencesUpdate(dietary_preferences=["not_a_diet"])


def test_disliked_category_filtering():
    dish = _Dish(name="Chocolate Cake", category_name="Desserts")
    assert is_disliked_category(dish, ["desserts"]) is True
    assert is_disliked_category(dish, ["burgers"]) is False


def test_dietary_halal_bonus():
    dish = _Dish(name="Chicken Biryani", description="Certified halal", category_name="Biryani")
    points, matched = score_dietary_preferences(
        dish,
        ["halal"],
        dish_tags=[],
        restaurant_tags=[],
    )
    assert matched == "halal"
    assert points > 0


def test_dietary_vegan_penalty():
    dish = _Dish(name="Chicken Karahi", category_name="BBQ")
    points, matched = score_dietary_preferences(
        dish,
        ["vegan"],
        dish_tags=[],
        restaurant_tags=[],
    )
    assert matched is None
    assert points < 0
