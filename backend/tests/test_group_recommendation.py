"""Tests for group recommendation filters and scoring."""

from decimal import Decimal

from app.models.dish import Dish
from app.services.group_recommendation.filters import (
    is_dish_dietary_compatible,
    is_dish_safe_for_group,
)
from app.services.group_recommendation.scoring import (
    compute_group_centroid,
    compute_group_score,
    score_group_agreement,
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
        *,
        name: str,
        description: str = "",
        category_name: str | None = None,
        allergens: list[str] | None = None,
    ):
        self.id = 1
        self.name = name
        self.description = description
        self.allergens = allergens
        self.price = Decimal("500")
        self.category = _Category(category_name) if category_name else None
        self.restaurant = _Restaurant()


def test_is_dish_safe_for_group_rejects_peanut_allergy():
    dish = _Dish(name="Peanut Butter Shake", description="Rich peanut butter blend")
    assert is_dish_safe_for_group(dish, {"peanuts"}) is False
    assert is_dish_safe_for_group(_Dish(name="Vanilla Shake"), {"peanuts"}) is True


def test_dietary_filter_excludes_meat_for_vegetarian_group():
    dish = _Dish(name="Chicken Biryani", category_name="Biryani")
    assert is_dish_dietary_compatible(dish, {"vegetarian"}) is False
    assert is_dish_dietary_compatible(_Dish(name="Paneer Handi"), {"vegetarian"}) is True


def test_compute_group_centroid_averages_coordinates():
    centroid = compute_group_centroid([(31.0, 74.0), (31.2, 74.4)])
    assert centroid is not None
    assert round(centroid[0], 2) == 31.1
    assert round(centroid[1], 2) == 74.2


def test_group_agreement_score():
    dish = _Dish(name="Beef Burger", category_name="Burgers")
    members = [
        {
            "favorite_cuisines": ["burger"],
            "dietary": set(),
            "allergies": set(),
            "disliked_categories": [],
            "budget_level": "medium",
        },
        {
            "favorite_cuisines": ["pizza"],
            "dietary": set(),
            "allergies": set(),
            "disliked_categories": [],
            "budget_level": "medium",
        },
    ]
    score, matching, total = score_group_agreement(
        dish,
        members,
        dish_tags=["burger", "fast_food"],
        restaurant_tags=["burger"],
    )
    assert total == 2
    assert matching == 1
    assert score == 50.0


def test_compute_group_score_weighted():
    score = compute_group_score(
        cuisine_score=100.0,
        agreement_score=75.0,
        distance_score=80.0,
        budget_score=90.0,
        popularity_score=60.0,
        nutrition_score=70.0,
        order_similarity_score=40.0,
    )
    expected = (
        100 * 0.36
        + 75 * 0.20
        + 80 * 0.14
        + 90 * 0.14
        + 60 * 0.08
        + 70 * 0.04
        + 40 * 0.04
    )
    assert score == round(expected, 2)


def test_recommendation_ranking_order():
    items = [
        {"dish_id": 1, "score": 70.0},
        {"dish_id": 2, "score": 92.0},
        {"dish_id": 3, "score": 85.0},
    ]
    ranked = sorted(items, key=lambda row: (-row["score"], row["dish_id"]))
    assert [row["dish_id"] for row in ranked] == [2, 3, 1]
