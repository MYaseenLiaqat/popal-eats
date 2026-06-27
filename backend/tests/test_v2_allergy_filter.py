"""Tests for personal V2 allergy hard-filtering."""

from decimal import Decimal

from app.schemas.user_preference import RecommendationPreferences
from app.services.recommendation.allergy_filter import (
    filter_dishes_for_user_allergies,
    is_dish_safe_for_user_allergies,
)


class _Category:
    def __init__(self, name: str):
        self.name = name


class _Restaurant:
    def __init__(self, name: str = "Test Restaurant"):
        self.name = name
        self.description = None


class _Dish:
    def __init__(
        self,
        dish_id: int,
        *,
        name: str,
        description: str = "",
        allergens: list[str] | None = None,
        restaurant_id: int = 1,
    ):
        self.id = dish_id
        self.restaurant_id = restaurant_id
        self.name = name
        self.description = description
        self.price = Decimal("500")
        self.allergens = allergens
        self.category = None
        self.restaurant = _Restaurant()


def test_peanut_allergy_excludes_peanut_dishes():
    peanut = _Dish(1, name="Peanut Nimko", allergens=["peanut"])
    safe_dish = _Dish(2, name="Chicken Biryani")
    dishes = [peanut, safe_dish]
    tags = {1: ["snacks"], 2: ["biryani", "pakistani"]}
    rest_tags = {1: [], 2: ["pakistani"]}

    filtered = filter_dishes_for_user_allergies(
        dishes,
        ["peanuts"],
        dish_tags_map=tags,
        restaurant_tags_map=rest_tags,
    )
    assert [d.id for d in filtered] == [2]
    assert is_dish_safe_for_user_allergies(peanut, ["peanuts"]) is False


def test_milk_allergy_excludes_dairy_dishes():
    milkshake = _Dish(1, name="Chocolate Milkshake", description="creamy milk blend")
    salad = _Dish(2, name="Garden Salad")
    filtered = filter_dishes_for_user_allergies(
        [milkshake, salad],
        ["milk"],
        dish_tags_map={1: [], 2: ["salad"]},
        restaurant_tags_map={1: [], 2: []},
    )
    assert [d.id for d in filtered] == [2]


def test_multiple_allergies_exclude_all_unsafe_dishes():
    dishes = [
        _Dish(1, name="Peanut Curry", allergens=["peanut"]),
        _Dish(2, name="Shrimp Fried Rice", description="fresh prawns"),
        _Dish(3, name="Plain Rice"),
    ]
    filtered = filter_dishes_for_user_allergies(
        dishes,
        ["peanuts", "shellfish"],
        dish_tags_map={1: [], 2: ["chinese"], 3: []},
        restaurant_tags_map={1: [], 2: [], 3: []},
    )
    assert [d.id for d in filtered] == [3]


def test_no_allergies_leaves_dishes_unchanged():
    dishes = [
        _Dish(1, name="Peanut Butter Shake"),
        _Dish(2, name="Vanilla Shake"),
    ]
    filtered = filter_dishes_for_user_allergies(
        dishes,
        [],
        dish_tags_map={1: [], 2: []},
        restaurant_tags_map={1: [], 2: []},
    )
    assert len(filtered) == 2


def test_recommendation_preferences_includes_allergies():
    prefs = RecommendationPreferences(
        favorite_cuisines=["pakistani"],
        allergies=["peanuts", "milk"],
    )
    assert prefs.allergies == ["peanuts", "milk"]


def test_structured_allergen_tags_used_when_present():
    dish = _Dish(1, name="House Special", allergens=["dairy"])
    assert is_dish_safe_for_user_allergies(dish, ["milk"]) is False
    assert is_dish_safe_for_user_allergies(dish, ["peanuts"]) is True
