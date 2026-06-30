"""
Recommendation Engine V2 — feedback learning from recommendation_events (Phase 5.3).

Event weights (feedback profile only; impressions still count in CTR analytics):
  impression → 0
  click      → 1
  order      → 3
"""

from collections import defaultdict
from dataclasses import dataclass

from sqlalchemy.orm import Session

from app.models.category import Category
from app.models.dish import Dish
from app.models.recommendation_event import RecommendationEvent
from app.schemas.recommendation_v2 import V2DishRecommendationItem
from app.schemas.recommendation_v2_metrics import EVENT_FEEDBACK_WEIGHTS
FEEDBACK_MULTIPLIER = 2
FEEDBACK_BONUS_CAP = 15
MAX_SCORE = 100


@dataclass(frozen=True)
class UserFeedbackProfile:
    preferred_categories: dict[str, int]
    preferred_dishes: dict[int, int]


def load_dish_category_names(
    db: Session,
    dish_ids: list[int] | None = None,
) -> dict[int, str]:
    query = db.query(Dish.id, Category.name).join(Category, Dish.category_id == Category.id)
    if dish_ids:
        query = query.filter(Dish.id.in_(dish_ids))
    rows = query.all()
    return {dish_id: name for dish_id, name in rows}


def get_user_feedback_profile(db: Session, user_id: int) -> UserFeedbackProfile:
    """
    Implicit preference weights from recommendation_events.

    Returns category names and dish ids mapped to accumulated weights.
    """
    dish_weights: dict[int, int] = defaultdict(int)
    category_weights: dict[str, int] = defaultdict(int)

    event_rows = (
        db.query(RecommendationEvent.dish_id, RecommendationEvent.event_type)
        .filter(RecommendationEvent.user_id == user_id)
        .all()
    )
    event_dish_ids = [dish_id for dish_id, _ in event_rows]
    dish_to_category = load_dish_category_names(db, dish_ids=event_dish_ids or None)

    for dish_id, event_type in event_rows:
        weight = EVENT_FEEDBACK_WEIGHTS.get(event_type, 0)
        if weight <= 0:
            continue
        dish_weights[dish_id] += weight
        category = dish_to_category.get(dish_id)
        if category:
            category_weights[category] += weight

    return UserFeedbackProfile(
        preferred_categories=dict(category_weights),
        preferred_dishes=dict(dish_weights),
    )


def compute_feedback_bonus(
    *,
    dish_id: int,
    dish_name: str,
    category_name: str | None,
    profile: UserFeedbackProfile,
) -> tuple[float, str | None]:
    """
    feedback_bonus = min(weight * 2, 15) using the stronger dish vs category signal.
    """
    dish_weight = profile.preferred_dishes.get(dish_id, 0)
    category_weight = profile.preferred_categories.get(category_name, 0) if category_name else 0

    if dish_weight <= 0 and category_weight <= 0:
        return 0.0, None

    if dish_weight >= category_weight:
        weight = dish_weight
        label = dish_name
    else:
        weight = category_weight
        label = category_name or dish_name

    bonus = min(weight * FEEDBACK_MULTIPLIER, FEEDBACK_BONUS_CAP)
    return bonus, f"Learned preference: {label} (+{int(bonus)})"


def apply_feedback_to_item(
    item: V2DishRecommendationItem,
    profile: UserFeedbackProfile,
    category_name: str | None,
) -> V2DishRecommendationItem:
    """Add feedback bonus to score (cap 100) and append explainability text."""
    bonus, feedback_line = compute_feedback_bonus(
        dish_id=item.dish_id,
        dish_name=item.dish_name,
        category_name=category_name,
        profile=profile,
    )
    if bonus <= 0 or not feedback_line:
        return item

    new_score = min(MAX_SCORE, round(item.score + bonus, 1))
    explanation = item.explanation.rstrip(".")
    explanation = f"{explanation}. {feedback_line}." if explanation else f"{feedback_line}."

    signals = list(item.signals_used)
    if "feedback" not in signals:
        signals.append("feedback")

    breakdown = item.score_breakdown.model_copy(
        update={
            "feedback_score": bonus,
            "total_score": new_score,
        }
    )

    return item.model_copy(
        update={
            "score": new_score,
            "score_breakdown": breakdown,
            "explanation": explanation,
            "signals_used": signals,
        }
    )


def apply_feedback_to_items(
    db: Session,
    user_id: int,
    items: list[V2DishRecommendationItem],
) -> list[V2DishRecommendationItem]:
    """Apply feedback bonuses and re-rank by updated score."""
    if not items:
        return items

    profile = get_user_feedback_profile(db, user_id)
    if not profile.preferred_dishes and not profile.preferred_categories:
        return items

    dish_to_category = load_dish_category_names(db, dish_ids=[item.dish_id for item in items])
    boosted = [
        apply_feedback_to_item(item, profile, dish_to_category.get(item.dish_id))
        for item in items
    ]
    boosted.sort(key=lambda row: row.score, reverse=True)
    return boosted
