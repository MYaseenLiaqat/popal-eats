"""Tests for intelligent group recommendation extensions."""

from decimal import Decimal

from app.services.group_recommendation.context import GroupRecommendationContext, MemberPreferenceContext
from app.services.group_recommendation.explainability import (
    GroupScoreSignals,
    build_group_explanation_bullets,
    group_match_percent,
)
from app.services.group_recommendation.scoring import (
    score_cuisine_match,
    score_order_similarity,
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
        dish_id: int = 1,
        restaurant_id: int = 10,
        name: str,
        description: str = "",
        category_name: str | None = None,
        allergens: list[str] | None = None,
    ):
        self.id = dish_id
        self.restaurant_id = restaurant_id
        self.name = name
        self.description = description
        self.allergens = allergens
        self.price = Decimal("500")
        self.category = _Category(category_name) if category_name else None
        self.restaurant = _Restaurant()
        self.calories = 400
        self.protein = 20
        self.carbs = 30


def _members_four_way_cuisine_conflict():
    return [
        {
            "favorite_cuisines": ["pakistani", "pakistani"],
            "dietary": set(),
            "allergies": set(),
            "disliked_categories": [],
            "nutrition_goal": None,
            "budget_level": "medium",
            "ordered_dish_ids": set(),
            "ordered_restaurant_ids": set(),
            "viewed_dish_ids": set(),
            "feedback_dish_ids": set(),
        },
        {
            "favorite_cuisines": ["pakistani"],
            "dietary": set(),
            "allergies": set(),
            "disliked_categories": [],
            "nutrition_goal": None,
            "budget_level": "medium",
            "ordered_dish_ids": set(),
            "ordered_restaurant_ids": set(),
            "viewed_dish_ids": set(),
            "feedback_dish_ids": set(),
        },
        {
            "favorite_cuisines": ["turkish"],
            "dietary": set(),
            "allergies": set(),
            "disliked_categories": [],
            "nutrition_goal": None,
            "budget_level": "low",
            "ordered_dish_ids": set(),
            "ordered_restaurant_ids": set(),
            "viewed_dish_ids": set(),
            "feedback_dish_ids": set(),
        },
        {
            "favorite_cuisines": ["italian"],
            "dietary": set(),
            "allergies": set(),
            "disliked_categories": [],
            "nutrition_goal": None,
            "budget_level": "high",
            "ordered_dish_ids": set(),
            "ordered_restaurant_ids": set(),
            "viewed_dish_ids": set(),
            "feedback_dish_ids": set(),
        },
    ]


def test_multi_cuisine_dish_scores_higher_than_single_match():
    members = _members_four_way_cuisine_conflict()
    multi = _Dish(name="Fusion Platter")
    single = _Dish(name="Margherita Pizza")

    multi_score, multi_matches, _ = score_cuisine_match(
        multi,
        members,
        dish_tags=["pakistani", "turkish", "multi_cuisine"],
        restaurant_tags=["multi_cuisine"],
    )
    single_score, single_matches, _ = score_cuisine_match(
        single,
        members,
        dish_tags=["italian", "pizza"],
        restaurant_tags=["italian"],
    )

    assert multi_matches >= single_matches
    assert multi_score >= single_score


def test_order_similarity_from_group_restaurant_history():
    dish = _Dish(dish_id=5, restaurant_id=99, name="House Biryani")
    members = [
        {
            "favorite_cuisines": ["pakistani"],
            "ordered_dish_ids": set(),
            "ordered_restaurant_ids": {99},
            "viewed_dish_ids": set(),
            "feedback_dish_ids": set(),
        },
        {
            "favorite_cuisines": ["pakistani"],
            "ordered_dish_ids": set(),
            "ordered_restaurant_ids": set(),
            "viewed_dish_ids": {5},
            "feedback_dish_ids": set(),
        },
    ]
    assert score_order_similarity(dish, members) >= 50.0


def test_group_explanation_includes_allergy_and_cuisine_bullets():
    from app.models.group_session import GroupSession

    context = GroupRecommendationContext(
        session=GroupSession(id=1, name="Test", host_user_id=1, status="active"),
        members=[
            MemberPreferenceContext(user_id=1, favorite_cuisines=["pakistani"], allergies=["peanuts"]),
            MemberPreferenceContext(user_id=2, favorite_cuisines=["pakistani"]),
        ],
        active_locations=[],
        group_allergies={"peanuts"},
        group_cuisines=["pakistani"],
    )
    signals = GroupScoreSignals(
        cuisine_score=90.0,
        agreement_score=100.0,
        distance_score=75.0,
        budget_score=85.0,
        popularity_score=70.0,
        nutrition_score=60.0,
        order_similarity_score=55.0,
        matching_members=2,
        total_members=2,
        cuisine_member_matches=2,
        cuisine_label="pakistani",
    )
    bullets = build_group_explanation_bullets(signals, context)
    assert any("Pakistani" in b for b in bullets)
    assert any("allerg" in b.lower() for b in bullets)
    assert len(bullets) <= 5


def test_group_match_percent_from_score():
    assert group_match_percent(94.2) == 94
