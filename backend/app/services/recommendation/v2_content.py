"""
Recommendation Engine V2 — content-based module (Phase 1).

Scoring (max 100):
  Cuisine 50 | Nutrition 25 | Budget 15 | Popularity 10
"""

from dataclasses import dataclass, field
from decimal import Decimal
from typing import Any

from sqlalchemy import func, text
from sqlalchemy.orm import Session, joinedload

from app.models.dish import Dish
from app.models.order_item import OrderItem
from app.schemas.recommendation_v2 import V2DishRecommendationItem, V2ScoreBreakdown

SCORE_CUISINE = 50
SCORE_NUTRITION = 25
SCORE_BUDGET = 15
SCORE_POPULARITY = 10
TOP_N = 10

_GOAL_HIGH_PROTEIN = frozenset({"muscle_gain", "high_protein", "high-protein", "muscle gain"})
_GOAL_LOW_CARB = frozenset({"low_carb", "low-carb", "keto"})
_GOAL_WEIGHT_LOSS = frozenset({"weight_loss", "weight-loss", "weight loss", "lose_weight"})
_GOAL_BALANCED = frozenset({"balanced", "maintain", "general", "balanced nutrition"})


@dataclass
class _Preferences:
    favorite_cuisines: list[str] = field(default_factory=list)
    dietary_preference: str | None = None
    nutrition_goal: str | None = None
    budget_min: Decimal | None = None
    budget_max: Decimal | None = None


def _normalize_list(values: list | None) -> list[str]:
    if not values:
        return []
    return [str(v).strip().lower() for v in values if v and str(v).strip()]


def _normalize_tags(raw: Any) -> list[str]:
    if not raw:
        return []
    if isinstance(raw, list):
        return [str(t).strip().lower() for t in raw if t and str(t).strip()]
    return []


def _load_preferences(db: Session, user_id: int) -> _Preferences:
    """Load user_preferences row; empty defaults if missing (no crash)."""
    try:
        row = db.execute(
            text(
                """
                SELECT favorite_cuisines, dietary_preference, nutrition_goal,
                       budget_min, budget_max
                FROM user_preferences
                WHERE user_id = :uid
                """
            ),
            {"uid": user_id},
        ).mappings().first()
    except Exception:
        return _Preferences()

    if not row:
        return _Preferences()

    cuisines = row.get("favorite_cuisines")
    if cuisines is None:
        cuisines = []
    elif not isinstance(cuisines, list):
        cuisines = []

    return _Preferences(
        favorite_cuisines=_normalize_list(cuisines),
        dietary_preference=row.get("dietary_preference"),
        nutrition_goal=row.get("nutrition_goal"),
        budget_min=row.get("budget_min"),
        budget_max=row.get("budget_max"),
    )


def _load_tags_maps(db: Session) -> tuple[dict[int, list[str]], dict[int, list[str]]]:
    """Load dish/restaurant tags from DB (columns may exist before ORM models do)."""
    dish_tags: dict[int, list[str]] = {}
    restaurant_tags: dict[int, list[str]] = {}
    try:
        for row in db.execute(text("SELECT id, tags FROM dishes")).mappings():
            dish_tags[row["id"]] = _normalize_tags(row.get("tags"))
        for row in db.execute(text("SELECT id, tags FROM restaurants")).mappings():
            restaurant_tags[row["id"]] = _normalize_tags(row.get("tags"))
    except Exception:
        pass
    return dish_tags, restaurant_tags


def _load_order_counts(db: Session) -> dict[int, int]:
    try:
        rows = (
            db.query(OrderItem.dish_id, func.count(OrderItem.id))
            .group_by(OrderItem.dish_id)
            .all()
        )
        return {dish_id: int(count) for dish_id, count in rows}
    except Exception:
        return {}


def _match_cuisine_in_tags(tags: list[str], cuisines: list[str]) -> str | None:
    for cuisine in cuisines:
        for tag in tags:
            if cuisine in tag or tag in cuisine:
                return cuisine
    return None


def _text_blob(dish: Dish) -> str:
    parts = [
        dish.name or "",
        dish.description or "",
        dish.restaurant.name if dish.restaurant else "",
        dish.restaurant.description if dish.restaurant and dish.restaurant.description else "",
    ]
    return " ".join(parts).lower()


def _score_cuisine(
    dish: Dish,
    cuisines: list[str],
    dish_tags: list[str],
    restaurant_tags: list[str],
) -> tuple[float, str | None]:
    if not cuisines:
        return 0.0, None

    matched = _match_cuisine_in_tags(dish_tags, cuisines)
    if matched:
        return float(SCORE_CUISINE), matched

    matched = _match_cuisine_in_tags(restaurant_tags, cuisines)
    if matched:
        return float(SCORE_CUISINE), matched

    if dish.category and dish.category.name:
        cat = dish.category.name.lower()
        for cuisine in cuisines:
            if cuisine in cat or cat in cuisine:
                return float(SCORE_CUISINE), cuisine

    blob = _text_blob(dish)
    if dish.category and dish.category.name:
        blob = f"{blob} {dish.category.name.lower()}"

    for cuisine in cuisines:
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
            return float(SCORE_NUTRITION) * 0.8, True
        return 0.0, False

    if goal in _GOAL_LOW_CARB:
        if carbs is not None and carbs <= 25:
            return float(SCORE_NUTRITION), True
        if carbs is not None and carbs <= 40:
            return float(SCORE_NUTRITION) * 0.8, True
        return 0.0, False

    if goal in _GOAL_WEIGHT_LOSS:
        if calories is not None and calories <= 450:
            return float(SCORE_NUTRITION), True
        if calories is not None and calories <= 600:
            return float(SCORE_NUTRITION) * 0.8, True
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
) -> tuple[float, str]:
    """Returns (points, status) where status is within|below|slightly_above|above|none."""
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


def _score_popularity(
    average_rating: float,
    total_reviews: int,
    order_count: int,
) -> float:
    rating_part = (max(0.0, min(float(average_rating or 0.0), 5.0)) / 5.0) * 4.0
    review_part = min(total_reviews / 10.0, 1.0) * 3.0
    order_part = min(order_count / 5.0, 1.0) * 3.0
    return round(min(float(SCORE_POPULARITY), rating_part + review_part + order_part), 1)


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


def _format_pts(value: float) -> int:
    return int(round(value))


def _build_explanation(
    *,
    matched_cuisine: str | None,
    cuisine_pts: float,
    nutrition_pts: float,
    nutrition_goal: str | None,
    budget_pts: float,
    budget_status: str,
    popularity_pts: float,
    has_budget_prefs: bool,
) -> tuple[str, list[str]]:
    parts: list[str] = []
    signals: list[str] = []

    if cuisine_pts > 0:
        label = matched_cuisine.title() if matched_cuisine else "your cuisine"
        parts.append(f"Matched {label} cuisine (+{_format_pts(cuisine_pts)})")
        signals.append("cuisine")

    if nutrition_pts > 0:
        parts.append(f"{_nutrition_label(nutrition_goal)} goal match (+{_format_pts(nutrition_pts)})")
        signals.append("nutrition")

    if budget_pts > 0:
        if budget_status == "within":
            parts.append(f"within budget (+{_format_pts(budget_pts)})")
        elif budget_status == "slightly_above":
            parts.append(f"slightly above budget (+{_format_pts(budget_pts)})")
        else:
            parts.append(f"budget match (+{_format_pts(budget_pts)})")
        signals.append("budget")
    elif has_budget_prefs:
        if budget_status == "below":
            parts.append("below your budget range")
        elif budget_status == "above":
            parts.append("above your budget range")

    if popularity_pts >= 1.0:
        parts.append(f"popularity bonus (+{_format_pts(popularity_pts)})")
        signals.append("popularity")

    if not parts:
        return "Available dish ranked by restaurant popularity and menu availability.", signals

    return ", ".join(parts) + ".", signals


def _score_dish(
    dish: Dish,
    prefs: _Preferences,
    dish_tags_map: dict[int, list[str]],
    restaurant_tags_map: dict[int, list[str]],
    order_counts: dict[int, int],
) -> V2DishRecommendationItem:
    dish_tags = dish_tags_map.get(dish.id, [])
    restaurant_tags = restaurant_tags_map.get(dish.restaurant_id, []) if dish.restaurant_id else []

    cuisine_pts, matched_cuisine = _score_cuisine(
        dish, prefs.favorite_cuisines, dish_tags, restaurant_tags
    )
    nutrition_pts, _ = _score_nutrition(dish, prefs.nutrition_goal)
    budget_pts, budget_status = _score_budget(dish.price, prefs.budget_min, prefs.budget_max)

    restaurant = dish.restaurant
    popularity_pts = _score_popularity(
        restaurant.average_rating if restaurant else 0.0,
        restaurant.total_reviews if restaurant else 0,
        order_counts.get(dish.id, 0),
    )

    total = round(cuisine_pts + nutrition_pts + budget_pts + popularity_pts, 1)
    has_budget_prefs = prefs.budget_min is not None or prefs.budget_max is not None
    explanation, signals = _build_explanation(
        matched_cuisine=matched_cuisine,
        cuisine_pts=cuisine_pts,
        nutrition_pts=nutrition_pts,
        nutrition_goal=prefs.nutrition_goal,
        budget_pts=budget_pts,
        budget_status=budget_status,
        popularity_pts=popularity_pts,
        has_budget_prefs=has_budget_prefs,
    )

    breakdown = V2ScoreBreakdown(
        cuisine_score=round(cuisine_pts, 1),
        nutrition_score=round(nutrition_pts, 1),
        budget_score=round(budget_pts, 1),
        popularity_score=round(popularity_pts, 1),
        total_score=total,
    )

    return V2DishRecommendationItem(
        dish_id=dish.id,
        dish_name=dish.name,
        restaurant_name=restaurant.name if restaurant else "",
        price=dish.price,
        calories=dish.calories,
        score=total,
        score_breakdown=breakdown,
        explanation=explanation,
        signals_used=signals,
    )


def get_content_recommendations(
    db: Session,
    user_id: int,
    *,
    limit: int = TOP_N,
) -> list[V2DishRecommendationItem]:
    """
    Content-based recommendations for a user (Phase 1).
    """
    prefs = _load_preferences(db, user_id)
    dish_tags_map, restaurant_tags_map = _load_tags_maps(db)
    order_counts = _load_order_counts(db)

    dishes = (
        db.query(Dish)
        .join(Dish.restaurant)
        .options(joinedload(Dish.restaurant), joinedload(Dish.category))
        .filter(Dish.is_available.is_(True))
        .filter(Dish.restaurant.has(is_open=True))
        .all()
    )

    if not dishes:
        return []

    scored = [
        _score_dish(dish, prefs, dish_tags_map, restaurant_tags_map, order_counts)
        for dish in dishes
    ]
    scored.sort(key=lambda item: item.score, reverse=True)
    return scored[:limit]
