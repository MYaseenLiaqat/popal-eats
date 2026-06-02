"""
Recommendation Engine V1.1 — rule-based scoring from user preferences.

Score weights (max 100):
  Cuisine 40 | Nutrition 25 | Budget 20 | Restaurant rating 15
"""

from dataclasses import dataclass
from decimal import Decimal
from typing import Literal

from sqlalchemy.orm import Session, joinedload

from app.models.dish import Dish
from app.models.user_preference import UserPreference
from app.services.user_preference_service import get_or_create_preferences

SCORE_CUISINE = 40
SCORE_NUTRITION = 25
SCORE_BUDGET = 20
SCORE_RATING = 15
TOP_N = 10

BudgetStatus = Literal["none", "below", "within", "slightly_above", "above"]

_GOAL_HIGH_PROTEIN = frozenset({"muscle_gain", "high_protein", "high-protein", "muscle gain"})
_GOAL_LOW_CARB = frozenset({"low_carb", "low-carb", "keto"})
_GOAL_WEIGHT_LOSS = frozenset({"weight_loss", "weight-loss", "weight loss", "lose_weight"})
_GOAL_BALANCED = frozenset({"balanced", "maintain", "general"})


@dataclass
class ScoreBreakdown:
    cuisine_score: float
    nutrition_score: float
    budget_score: float
    rating_score: float
    total_score: float


@dataclass
class ScoredDish:
    dish_id: int
    dish_name: str
    restaurant_name: str
    price: Decimal
    calories: int | None
    recommendation_score: float
    explanation: str
    score_breakdown: ScoreBreakdown


def _normalize_list(values: list | None) -> list[str]:
    if not values:
        return []
    return [str(v).strip().lower() for v in values if v and str(v).strip()]


def _normalize_tags(tags: list | None) -> list[str]:
    if not tags:
        return []
    return [str(t).strip().lower() for t in tags if t and str(t).strip()]


def _text_blob(dish: Dish) -> str:
    parts = [
        dish.name or "",
        dish.description or "",
        dish.restaurant.name if dish.restaurant else "",
        dish.restaurant.description if dish.restaurant and dish.restaurant.description else "",
    ]
    return " ".join(parts).lower()


def _match_cuisine_in_tags(tags: list[str], favorite_cuisines: list[str]) -> str | None:
    for cuisine in favorite_cuisines:
        for tag in tags:
            if cuisine in tag or tag in cuisine:
                return cuisine
    return None


def _score_cuisine(dish: Dish, favorite_cuisines: list[str]) -> tuple[float, str | None]:
    """
    Cuisine match with fallback order: dish tags → restaurant tags → category name → text blob.
    """
    if not favorite_cuisines:
        return 0.0, None

    dish_tags = _normalize_tags(getattr(dish, "tags", None))
    restaurant_tags = _normalize_tags(
        getattr(dish.restaurant, "tags", None) if dish.restaurant else None
    )

    matched = _match_cuisine_in_tags(dish_tags, favorite_cuisines)
    if matched:
        return float(SCORE_CUISINE), matched

    matched = _match_cuisine_in_tags(restaurant_tags, favorite_cuisines)
    if matched:
        return float(SCORE_CUISINE), matched

    if dish.category and dish.category.name:
        category_lower = dish.category.name.lower()
        for cuisine in favorite_cuisines:
            if cuisine in category_lower or category_lower in cuisine:
                return float(SCORE_CUISINE), cuisine

    blob = _text_blob(dish)
    if dish.category and dish.category.name:
        blob = f"{blob} {dish.category.name.lower()}"

    for cuisine in favorite_cuisines:
        if cuisine in blob:
            return float(SCORE_CUISINE), cuisine

    return 0.0, None


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

    if any(v is not None for v in (protein, carbs, calories)):
        return float(SCORE_NUTRITION) * 0.3, True
    return 0.0, False


def _score_budget(
    price: Decimal,
    budget_min: Decimal | None,
    budget_max: Decimal | None,
) -> tuple[float, BudgetStatus]:
    if budget_min is None and budget_max is None:
        return 0.0, "none"

    p = float(price)
    has_min = budget_min is not None
    has_max = budget_max is not None
    min_val = float(budget_min) if has_min else None
    max_val = float(budget_max) if has_max else None

    if has_min and p < min_val:
        return 0.0, "below"

    if has_max and p > max_val:
        if p <= max_val * 1.1:
            return float(SCORE_BUDGET) * 0.5, "slightly_above"
        return 0.0, "above"

    if (not has_min or p >= min_val) and (not has_max or p <= max_val):
        return float(SCORE_BUDGET), "within"

    return 0.0, "below"


def _score_restaurant_rating(average_rating: float) -> float:
    rating = max(0.0, min(float(average_rating or 0.0), 5.0))
    return round((rating / 5.0) * SCORE_RATING, 2)


def _nutrition_label(nutrition_goal: str | None) -> str:
    if not nutrition_goal:
        return "Nutrition"
    goal = nutrition_goal.strip().lower()
    if goal in _GOAL_HIGH_PROTEIN:
        return "High Protein"
    if goal in _GOAL_LOW_CARB:
        return "Low Carb"
    if goal in _GOAL_WEIGHT_LOSS:
        return "Weight Loss"
    if goal in _GOAL_BALANCED:
        return "Balanced Nutrition"
    return nutrition_goal.replace("_", " ").title()


def _format_points(value: float) -> int:
    return int(round(value))


def _build_explanation(
    *,
    cuisine_pts: float,
    matched_cuisine: str | None,
    nutrition_pts: float,
    nutrition_goal: str | None,
    budget_pts: float,
    budget_status: BudgetStatus,
    rating_pts: float,
    has_budget_prefs: bool,
) -> str:
    parts: list[str] = []

    if cuisine_pts > 0:
        label = matched_cuisine.title() if matched_cuisine else "your cuisine"
        parts.append(f"Matched {label} cuisine (+{_format_points(cuisine_pts)})")

    if nutrition_pts > 0:
        parts.append(f"{_nutrition_label(nutrition_goal)} goal (+{_format_points(nutrition_pts)})")

    if budget_pts > 0:
        if budget_status == "within":
            parts.append(f"Within budget range (+{_format_points(budget_pts)})")
        elif budget_status == "slightly_above":
            parts.append(f"Slightly above budget (+{_format_points(budget_pts)})")
        else:
            parts.append(f"Budget range (+{_format_points(budget_pts)})")
    elif has_budget_prefs:
        if budget_status == "below":
            parts.append("Below your budget range")
        elif budget_status == "above":
            parts.append("Above your budget range")

    if rating_pts > 0:
        parts.append(f"Restaurant rating (+{_format_points(rating_pts)})")

    if not parts:
        return "No strong preference match; ranked by availability and restaurant data."

    return ", ".join(parts) + "."


def _score_dish(dish: Dish, prefs: UserPreference) -> ScoredDish:
    cuisines = _normalize_list(prefs.favorite_cuisines)
    cuisine_pts, matched_cuisine = _score_cuisine(dish, cuisines)
    nutrition_pts, _ = _score_nutrition(dish, prefs.nutrition_goal)
    budget_pts, budget_status = _score_budget(dish.price, prefs.budget_min, prefs.budget_max)
    rating_pts = _score_restaurant_rating(
        dish.restaurant.average_rating if dish.restaurant else 0.0
    )

    total = round(cuisine_pts + nutrition_pts + budget_pts + rating_pts, 1)
    breakdown = ScoreBreakdown(
        cuisine_score=round(cuisine_pts, 1),
        nutrition_score=round(nutrition_pts, 1),
        budget_score=round(budget_pts, 1),
        rating_score=round(rating_pts, 1),
        total_score=round(total, 1),
    )

    has_budget_prefs = prefs.budget_min is not None or prefs.budget_max is not None
    explanation = _build_explanation(
        cuisine_pts=cuisine_pts,
        matched_cuisine=matched_cuisine,
        nutrition_pts=nutrition_pts,
        nutrition_goal=prefs.nutrition_goal,
        budget_pts=budget_pts,
        budget_status=budget_status,
        rating_pts=rating_pts,
        has_budget_prefs=has_budget_prefs,
    )

    return ScoredDish(
        dish_id=dish.id,
        dish_name=dish.name,
        restaurant_name=dish.restaurant.name if dish.restaurant else "",
        price=dish.price,
        calories=dish.calories,
        recommendation_score=total,
        explanation=explanation,
        score_breakdown=breakdown,
    )


def get_recommendations(db: Session, user_id: int, *, limit: int = TOP_N) -> list[ScoredDish]:
    """Score available dishes and return the top N by total score."""
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
