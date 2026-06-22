"""
Recommendation Engine V2 — content-based module (Phase 1).

Scoring (max 100):
  Cuisine 50 | Nutrition 25 | Budget 15 | Popularity 10
"""

import heapq
from decimal import Decimal
from typing import Any

from sqlalchemy import func
from sqlalchemy.orm import Session

from app.models.dish import Dish
from app.models.order_item import OrderItem
from app.schemas.recommendation_v2 import V2DishRecommendationItem, V2ScoreBreakdown
from app.schemas.user_preference import RecommendationPreferences
from app.services.recommendation.preference_scoring import (
    is_disliked_category,
    score_dietary_preferences,
)
from app.services.recommendation.v2_candidates import load_eligible_dishes
from app.services.recommendation.price_adjustment import apply_price_outlier_penalty
from app.services.recommendation.v2_catalog import FOODPANDA_SOURCE, build_tag_maps_from_dishes
from app.services.recommendation.v2_debug import log_pipeline_stage, log_ranked_recommendations
from app.services.user_preferences_service import load_recommendation_preferences

SCORE_CUISINE = 50
SCORE_NUTRITION = 25
SCORE_BUDGET = 15
SCORE_POPULARITY = 10
TOP_N = 10

_GOAL_MUSCLE_GAIN = frozenset({"muscle_gain", "muscle gain", "muscle"})
_GOAL_HIGH_PROTEIN = frozenset({"high_protein", "high-protein", "high protein", "highprotein"})
_GOAL_BULKING = frozenset({"bulking", "bulk"})
_GOAL_LOW_CARB = frozenset({"low_carb", "low-carb", "keto"})
_GOAL_WEIGHT_LOSS = frozenset({"weight_loss", "weight-loss", "weight loss", "lose_weight"})
_GOAL_MAINTAIN = frozenset({"maintain", "balanced", "general", "balanced nutrition"})


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


def _load_tags_maps(dishes: list[Dish]) -> tuple[dict[int, list[str]], dict[int, list[str]]]:
    return build_tag_maps_from_dishes(dishes)


def _load_order_counts(db: Session, dish_ids: list[int] | None = None) -> dict[int, int]:
    try:
        query = db.query(OrderItem.dish_id, func.count(OrderItem.id)).group_by(OrderItem.dish_id)
        if dish_ids:
            query = query.filter(OrderItem.dish_id.in_(dish_ids))
        rows = query.all()
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


def _protein_density(protein: float | None, calories: int | None) -> float | None:
    if protein is None or calories is None or calories <= 0:
        return None
    return (protein / float(calories)) * 100.0


def _score_nutrition(dish: Dish, nutrition_goal: str | None) -> tuple[float, bool]:
    if not nutrition_goal:
        return 0.0, False

    goal = nutrition_goal.strip().lower().replace(" ", "_").replace("-", "_")
    protein = float(dish.protein) if dish.protein is not None else None
    carbs = float(dish.carbs) if dish.carbs is not None else None
    calories = dish.calories
    density = _protein_density(protein, calories)

    if goal in _GOAL_WEIGHT_LOSS:
        if calories is not None and calories <= 450 and protein is not None and protein >= 15:
            return float(SCORE_NUTRITION), True
        if calories is not None and calories <= 500:
            return float(SCORE_NUTRITION) * 0.85, True
        if calories is not None and calories <= 600 and protein is not None and protein >= 12:
            return float(SCORE_NUTRITION) * 0.7, True
        return 0.0, False

    if goal in _GOAL_BULKING:
        if calories is not None and calories >= 600 and protein is not None and protein >= 20:
            return float(SCORE_NUTRITION), True
        if calories is not None and calories >= 500 and protein is not None and protein >= 15:
            return float(SCORE_NUTRITION) * 0.8, True
        return 0.0, False

    if goal in _GOAL_MUSCLE_GAIN:
        if protein is not None and protein >= 28:
            return float(SCORE_NUTRITION), True
        if protein is not None and protein >= 22:
            return float(SCORE_NUTRITION) * 0.85, True
        if protein is not None and protein >= 18:
            return float(SCORE_NUTRITION) * 0.65, True
        return 0.0, False

    if goal in _GOAL_HIGH_PROTEIN:
        if density is not None and density >= 8.0:
            return float(SCORE_NUTRITION), True
        if protein is not None and protein >= 25:
            return float(SCORE_NUTRITION) * 0.9, True
        if density is not None and density >= 6.0:
            return float(SCORE_NUTRITION) * 0.75, True
        return 0.0, False

    if goal in _GOAL_LOW_CARB:
        if carbs is not None and carbs <= 25:
            return float(SCORE_NUTRITION), True
        if carbs is not None and carbs <= 40:
            return float(SCORE_NUTRITION) * 0.8, True
        return 0.0, False

    if goal in _GOAL_MAINTAIN:
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
    *,
    has_import_rating: bool = False,
) -> float:
    rating_part = (max(0.0, min(float(average_rating or 0.0), 5.0)) / 5.0) * 4.0
    review_part = min(total_reviews / 10.0, 1.0) * 3.0
    order_part = min(order_count / 5.0, 1.0) * 3.0
    base = rating_part + review_part + order_part
    # Imported Foodpanda ratings/reviews are a valid popularity signal without platform orders.
    if has_import_rating and order_count == 0 and (average_rating or total_reviews):
        base = max(base, rating_part + review_part)
    return round(min(float(SCORE_POPULARITY), base), 1)


def _nutrition_label(nutrition_goal: str | None) -> str:
    if not nutrition_goal:
        return "Nutrition"
    goal = nutrition_goal.strip().lower().replace(" ", "_").replace("-", "_")
    if goal in _GOAL_WEIGHT_LOSS:
        return "Weight Loss"
    if goal in _GOAL_BULKING:
        return "Bulking"
    if goal in _GOAL_MUSCLE_GAIN:
        return "Muscle Gain"
    if goal in _GOAL_HIGH_PROTEIN:
        return "High Protein"
    if goal in _GOAL_LOW_CARB:
        return "Low Carb"
    if goal in _GOAL_MAINTAIN:
        return "Maintain"
    return nutrition_goal.replace("_", " ").title()


def _format_pts(value: float) -> int:
    return int(round(value))


def _build_explanation(
    *,
    matched_cuisine: str | None,
    cuisine_pts: float,
    nutrition_pts: float,
    nutrition_goal: str | None,
    matched_dietary: str | None,
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

    if matched_dietary:
        parts.append(f"Matches {matched_dietary.replace('_', ' ')} preference")
        signals.append("dietary")

    if nutrition_pts > 0 and not matched_dietary:
        parts.append(f"{_nutrition_label(nutrition_goal)} goal match (+{_format_pts(nutrition_pts)})")
        signals.append("nutrition")
    elif nutrition_pts > 0 and matched_dietary:
        parts.append(f"Nutrition alignment (+{_format_pts(nutrition_pts)})")
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
    prefs: RecommendationPreferences,
    dish_tags_map: dict[int, list[str]],
    restaurant_tags_map: dict[int, list[str]],
    order_counts: dict[int, int],
) -> V2DishRecommendationItem | None:
    if is_disliked_category(dish, prefs.disliked_categories):
        return None

    dish_tags = dish_tags_map.get(dish.id, [])
    restaurant_tags = restaurant_tags_map.get(dish.restaurant_id, []) if dish.restaurant_id else []

    cuisine_pts, matched_cuisine = _score_cuisine(
        dish, prefs.favorite_cuisines, dish_tags, restaurant_tags
    )
    nutrition_pts, _ = _score_nutrition(dish, prefs.nutrition_goal)
    dietary_adj, matched_dietary = score_dietary_preferences(
        dish,
        prefs.dietary_preferences,
        dish_tags=dish_tags,
        restaurant_tags=restaurant_tags,
    )
    if dietary_adj > 0:
        nutrition_pts = min(float(SCORE_NUTRITION), nutrition_pts + dietary_adj)
    budget_pts, budget_status = _score_budget(dish.price, prefs.budget_min, prefs.budget_max)

    restaurant = dish.restaurant
    has_import_rating = bool(
        restaurant
        and restaurant.source == FOODPANDA_SOURCE
        and ((restaurant.average_rating or 0) > 0 or (restaurant.total_reviews or 0) > 0)
    )
    popularity_pts = _score_popularity(
        restaurant.average_rating if restaurant else 0.0,
        restaurant.total_reviews if restaurant else 0,
        order_counts.get(dish.id, 0),
        has_import_rating=has_import_rating,
    )

    total = round(cuisine_pts + nutrition_pts + budget_pts + popularity_pts, 1)
    if dietary_adj < 0:
        total = max(0.0, total + dietary_adj)
    total = apply_price_outlier_penalty(total, dish.price)
    has_budget_prefs = prefs.budget_min is not None or prefs.budget_max is not None
    explanation, signals = _build_explanation(
        matched_cuisine=matched_cuisine,
        cuisine_pts=cuisine_pts,
        nutrition_pts=nutrition_pts,
        nutrition_goal=prefs.nutrition_goal,
        matched_dietary=matched_dietary,
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
    prefs = load_recommendation_preferences(db, user_id)
    dishes = load_eligible_dishes(db, user_id=user_id)
    dish_tags_map, restaurant_tags_map = _load_tags_maps(dishes)
    candidate_ids = [d.id for d in dishes]
    order_counts = _load_order_counts(db, candidate_ids)
    log_pipeline_stage(
        "content_scoring_start",
        user_id=user_id,
        candidates=len(dishes),
        foodpanda_candidates=sum(1 for d in dishes if d.source == FOODPANDA_SOURCE),
        tagged_restaurants=len(restaurant_tags_map),
        tagged_dishes=len(dish_tags_map),
        favorite_cuisines=len(prefs.favorite_cuisines),
        dietary_preferences=len(prefs.dietary_preferences),
        disliked_categories=len(prefs.disliked_categories),
        budget_level=prefs.budget_level,
    )
    if not dishes:
        return []

    scored: list[V2DishRecommendationItem] = []
    for dish in dishes:
        item = _score_dish(dish, prefs, dish_tags_map, restaurant_tags_map, order_counts)
        if item is not None:
            scored.append(item)
    top = heapq.nlargest(limit, scored, key=lambda item: item.score)
    source_by_id = {d.id: d.source for d in dishes}
    log_pipeline_stage(
        "content_ranking_complete",
        user_id=user_id,
        scored=len(scored),
        returned=len(top),
        foodpanda_in_top=sum(
            1 for item in top if source_by_id.get(item.dish_id) == FOODPANDA_SOURCE
        ),
    )
    log_ranked_recommendations("content_ranked", top, user_id=user_id)
    return top
