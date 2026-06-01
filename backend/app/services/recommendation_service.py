"""
Recommendation Engine V1 — rule-based scoring from user preferences.

Score weights (max 100):
  Cuisine 40 | Nutrition 25 | Budget 20 | Restaurant rating 15
"""

from dataclasses import dataclass
from decimal import Decimal

from sqlalchemy.orm import Session, joinedload

from app.models.dish import Dish
from app.models.user_preference import UserPreference
from app.services.user_preference_service import get_or_create_preferences

SCORE_CUISINE = 40
SCORE_NUTRITION = 25
SCORE_BUDGET = 20
SCORE_RATING = 15
TOP_N = 10

# Nutrition goal aliases (normalized lowercase)
_GOAL_HIGH_PROTEIN = frozenset({"muscle_gain", "high_protein", "high-protein", "muscle gain"})
_GOAL_LOW_CARB = frozenset({"low_carb", "low-carb", "keto"})
_GOAL_WEIGHT_LOSS = frozenset({"weight_loss", "weight-loss", "weight loss", "lose_weight"})
_GOAL_BALANCED = frozenset({"balanced", "maintain", "general"})


@dataclass
class ScoredDish:
    dish_id: int
    dish_name: str
    restaurant_name: str
    price: Decimal
    calories: int | None
    recommendation_score: float
    explanation: str


def _normalize_list(values: list | None) -> list[str]:
    if not values:
        return []
    return [str(v).strip().lower() for v in values if v and str(v).strip()]


def _text_blob(dish: Dish) -> str:
    parts = [
        dish.name or "",
        dish.description or "",
        dish.category.name if dish.category else "",
        dish.restaurant.name if dish.restaurant else "",
        dish.restaurant.description if dish.restaurant and dish.restaurant.description else "",
    ]
    return " ".join(parts).lower()


def _score_cuisine(dish: Dish, favorite_cuisines: list[str]) -> tuple[float, bool]:
    if not favorite_cuisines:
        return 0.0, False
    blob = _text_blob(dish)
    matched = any(cuisine in blob for cuisine in favorite_cuisines)
    return (float(SCORE_CUISINE) if matched else 0.0, matched)


def _score_nutrition(dish: Dish, nutrition_goal: str | None) -> tuple[float, bool]:
    if not nutrition_goal:
        return 0.0, False

    goal = nutrition_goal.strip().lower()
    protein = float(dish.protein) if dish.protein is not None else None
    carbs = float(dish.carbs) if dish.carbs is not None else None
    calories = dish.calories

    if goal in _GOAL_HIGH_PROTEIN:
        if protein is not None and protein >= 20:
            return float(SCORE_NUTRITION), True
        if protein is not None and protein >= 12:
            return float(SCORE_NUTRITION) * 0.6, True
        return 0.0, False

    if goal in _GOAL_LOW_CARB:
        if carbs is not None and carbs <= 25:
            return float(SCORE_NUTRITION), True
        if carbs is not None and carbs <= 40:
            return float(SCORE_NUTRITION) * 0.6, True
        return 0.0, False

    if goal in _GOAL_WEIGHT_LOSS:
        if calories is not None and calories <= 450:
            return float(SCORE_NUTRITION), True
        if calories is not None and calories <= 600:
            return float(SCORE_NUTRITION) * 0.6, True
        return 0.0, False

    if goal in _GOAL_BALANCED:
        if calories is not None and 300 <= calories <= 750:
            return float(SCORE_NUTRITION), True
        if protein is not None and carbs is not None and calories is not None:
            return float(SCORE_NUTRITION) * 0.5, True
        return float(SCORE_NUTRITION) * 0.25, True

    # Unknown goal — light credit if any macro data exists
    if any(v is not None for v in (protein, carbs, calories)):
        return float(SCORE_NUTRITION) * 0.3, True
    return 0.0, False


def _score_budget(price: Decimal, budget_min: Decimal | None, budget_max: Decimal | None) -> tuple[float, bool]:
    if budget_min is None and budget_max is None:
        return 0.0, False

    p = float(price)
    min_ok = budget_min is None or p >= float(budget_min)
    max_ok = budget_max is None or p <= float(budget_max)

    if min_ok and max_ok:
        return float(SCORE_BUDGET), True
    if budget_max is not None and p <= float(budget_max) * 1.1:
        return float(SCORE_BUDGET) * 0.5, True
    return 0.0, False


def _score_restaurant_rating(average_rating: float) -> float:
    rating = max(0.0, min(float(average_rating or 0.0), 5.0))
    return round((rating / 5.0) * SCORE_RATING, 2)


def _nutrition_phrase(nutrition_goal: str | None) -> str | None:
    if not nutrition_goal:
        return None
    goal = nutrition_goal.strip().lower()
    if goal in _GOAL_HIGH_PROTEIN:
        return "high-protein goal"
    if goal in _GOAL_LOW_CARB:
        return "low-carb goal"
    if goal in _GOAL_WEIGHT_LOSS:
        return "weight-loss goal"
    if goal in _GOAL_BALANCED:
        return "balanced nutrition goal"
    return f"{nutrition_goal} goal"


def _build_explanation(
    *,
    cuisine_matched: bool,
    nutrition_matched: bool,
    budget_matched: bool,
    rating_score: float,
    nutrition_goal: str | None,
) -> str:
    parts: list[str] = []

    if cuisine_matched:
        parts.append("matches your cuisine preferences")
    if nutrition_matched:
        phrase = _nutrition_phrase(nutrition_goal)
        if phrase:
            parts.append(phrase)
    if budget_matched:
        parts.append("fits your budget")
    if rating_score >= SCORE_RATING * 0.6:
        parts.append("from a highly rated restaurant")

    if not parts:
        return "Popular dish based on restaurant rating and availability."

    sentence = " and ".join(parts)
    return sentence[0].upper() + sentence[1:] + "."


def _score_dish(dish: Dish, prefs: UserPreference) -> ScoredDish:
    cuisines = _normalize_list(prefs.favorite_cuisines)
    cuisine_pts, cuisine_ok = _score_cuisine(dish, cuisines)
    nutrition_pts, nutrition_ok = _score_nutrition(dish, prefs.nutrition_goal)
    budget_pts, budget_ok = _score_budget(dish.price, prefs.budget_min, prefs.budget_max)
    rating_pts = _score_restaurant_rating(
        dish.restaurant.average_rating if dish.restaurant else 0.0
    )

    total = round(cuisine_pts + nutrition_pts + budget_pts + rating_pts, 1)
    explanation = _build_explanation(
        cuisine_matched=cuisine_ok,
        nutrition_matched=nutrition_ok,
        budget_matched=budget_ok,
        rating_score=rating_pts,
        nutrition_goal=prefs.nutrition_goal,
    )

    return ScoredDish(
        dish_id=dish.id,
        dish_name=dish.name,
        restaurant_name=dish.restaurant.name if dish.restaurant else "",
        price=dish.price,
        calories=dish.calories,
        recommendation_score=total,
        explanation=explanation,
    )


def get_recommendations(db: Session, user_id: int, *, limit: int = TOP_N) -> list[ScoredDish]:
    """
    Score all available dishes for the user and return the top N by recommendation_score.
    """
    prefs = get_or_create_preferences(db, user_id)

    dishes = (
        db.query(Dish)
        .join(Dish.restaurant)
        .options(joinedload(Dish.restaurant), joinedload(Dish.category))
        .filter(Dish.is_available.is_(True))
        .filter(Dish.restaurant.has(is_open=True))
        .all()
    )

    scored = [_score_dish(dish, prefs) for dish in dishes]
    scored.sort(key=lambda x: x.recommendation_score, reverse=True)
    return scored[:limit]
