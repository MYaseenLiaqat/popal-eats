"""Tests for V2 explainability metadata (no scoring changes)."""

from decimal import Decimal

from app.schemas.recommendation_v2 import V2DishRecommendationItem, V2ScoreBreakdown
from app.schemas.user_preference import RecommendationPreferences
from app.services.recommendation.v2_explainability import (
    build_explanation_bullets,
    confidence_percent_from_score,
    enrich_recommendation_item,
)


def _item(
    *,
    score: float = 56.8,
    cuisine: float = 50.0,
    nutrition: float = 0.0,
    budget: float = 0.0,
    popularity: float = 6.8,
    collaborative: float = 0.0,
    feedback: float = 0.0,
    explanation: str = "Matched Pakistani cuisine (+50), popularity bonus (+7).",
    signals: list[str] | None = None,
) -> V2DishRecommendationItem:
    breakdown = V2ScoreBreakdown(
        cuisine_score=cuisine,
        nutrition_score=nutrition,
        budget_score=budget,
        popularity_score=popularity,
        collaborative_score=collaborative,
        feedback_score=feedback,
        total_score=score,
    )
    return V2DishRecommendationItem(
        dish_id=1,
        dish_name="Chicken Biryani",
        restaurant_name="Test Kitchen",
        price=Decimal("650"),
        score=score,
        score_breakdown=breakdown,
        explanation=explanation,
        signals_used=signals or ["cuisine", "popularity"],
    )


def test_confidence_from_existing_score():
    assert confidence_percent_from_score(56.8) == 57
    assert confidence_percent_from_score(94.2) == 94
    assert confidence_percent_from_score(5.6) == 56


def test_cuisine_user_gets_cuisine_bullet():
    prefs = RecommendationPreferences(favorite_cuisines=["pakistani"])
    bullets = build_explanation_bullets(_item(), prefs, strategy="content")
    assert any("Pakistani" in b for b in bullets)
    assert bullets[0].startswith("Matches your")


def test_allergy_user_gets_safety_bullet():
    prefs = RecommendationPreferences(allergies=["peanuts"])
    bullets = build_explanation_bullets(_item(), prefs, strategy="content")
    assert "Safe for your selected allergies" in bullets


def test_budget_user_gets_budget_bullet():
    prefs = RecommendationPreferences(budget_min=Decimal("500"), budget_max=Decimal("2000"))
    item = _item(budget=15.0, score=65.0)
    bullets = build_explanation_bullets(item, prefs, strategy="content")
    assert "Fits your preferred budget" in bullets


def test_cold_start_popularity_bullet():
    prefs = RecommendationPreferences()
    item = _item(cuisine=0.0, popularity=7.0, score=7.0, explanation="Available dish ranked by restaurant popularity.")
    bullets = build_explanation_bullets(item, prefs, strategy="content")
    assert len(bullets) >= 1
    assert any("Popular" in b or "Trending" in b or "rated" in b for b in bullets)


def test_collaborative_user_gets_order_similarity_bullet():
    prefs = RecommendationPreferences()
    item = _item(
        score=72.0,
        cuisine=0.0,
        popularity=0.0,
        collaborative=72.0,
        explanation="Recommended because it pairs well with what you've ordered before",
        signals=["collaborative"],
    )
    bullets = build_explanation_bullets(item, prefs, strategy="collaborative")
    assert any("ordered" in b.lower() for b in bullets)


def test_enrich_does_not_change_score():
    prefs = RecommendationPreferences(favorite_cuisines=["pakistani"], allergies=["peanuts"])
    original = _item()
    enriched = enrich_recommendation_item(original, prefs, strategy="content")
    assert enriched.score == original.score
    assert enriched.score_breakdown == original.score_breakdown
    assert enriched.confidence_percent == 57
    assert len(enriched.explanation_bullets) >= 1
    assert len(enriched.contributions) >= 1
    assert enriched.contributions[-1].signal == "final"
