"""Tests for dish-level cuisine classification."""

from app.services.recommendation.cuisine_classifier import (
    INTERNATIONAL,
    classify_dish,
    classify_dish_cuisine_cached,
)


class _Category:
    def __init__(self, name: str):
        self.name = name


class _Restaurant:
    def __init__(self, *, name: str = "", description: str | None = None, tags=None):
        self.name = name
        self.description = description
        self.tags = tags


class _Dish:
    def __init__(
        self,
        *,
        name: str,
        description: str = "",
        cuisine: str | None = None,
        category_name: str | None = None,
        restaurant: _Restaurant | None = None,
        tags=None,
    ):
        self.id = id(self)
        self.name = name
        self.description = description
        self.cuisine = cuisine
        self.category = _Category(category_name) if category_name else None
        self.restaurant = restaurant or _Restaurant()
        self.tags = tags


def test_classify_pakistani_biryani():
    dish = _Dish(name="Chicken Biryani", category_name="Rice")
    assert classify_dish(dish) == "pakistani"


def test_classify_italian_pizza():
    dish = _Dish(name="Margherita Pizza", category_name="Pizza")
    assert classify_dish(dish) == "italian"


def test_classify_japanese_sushi():
    dish = _Dish(name="Salmon Sushi Roll", category_name="Sushi")
    assert classify_dish(dish) == "japanese"


def test_classify_unknown_becomes_international():
    dish = _Dish(name="Mystery Box Special", category_name="Misc")
    assert classify_dish(dish) == INTERNATIONAL


def test_classifier_is_cached():
    classify_dish_cuisine_cached.cache_clear()
    first = classify_dish_cuisine_cached(
        dish_name="Chicken Karahi",
        dish_description="",
        dish_cuisine="",
        category_name="Curry",
        restaurant_name="Desi Kitchen",
        restaurant_description="",
        restaurant_tags_key="pakistani",
    )
    second = classify_dish_cuisine_cached(
        dish_name="Chicken Karahi",
        dish_description="",
        dish_cuisine="",
        category_name="Curry",
        restaurant_name="Desi Kitchen",
        restaurant_description="",
        restaurant_tags_key="pakistani",
    )
    assert first == second == "pakistani"
    assert classify_dish_cuisine_cached.cache_info().hits >= 1
