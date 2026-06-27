"""Personal V2 allergy hard-filter — reuses group recommendation filter logic."""

from __future__ import annotations

from app.models.dish import Dish
from app.services.group_recommendation.filters import is_dish_safe_for_group
from app.services.recommendation.v2_debug import log_pipeline_stage

__all__ = [
    "filter_dishes_for_user_allergies",
    "is_dish_safe_for_user_allergies",
]


def _allergy_set(allergies: list[str] | set[str] | None) -> set[str]:
    if not allergies:
        return set()
    return {str(a).strip().lower() for a in allergies if a and str(a).strip()}


def is_dish_safe_for_user_allergies(
    dish: Dish,
    allergies: list[str] | set[str] | None,
    *,
    dish_tags: list[str] | None = None,
    restaurant_tags: list[str] | None = None,
) -> bool:
    """Return True when dish is safe for the user's declared allergies."""
    allergy_set = _allergy_set(allergies)
    if not allergy_set:
        return True
    return is_dish_safe_for_group(
        dish,
        allergy_set,
        dish_tags=dish_tags or [],
        restaurant_tags=restaurant_tags or [],
    )


def filter_dishes_for_user_allergies(
    dishes: list[Dish],
    allergies: list[str] | set[str] | None,
    *,
    dish_tags_map: dict[int, list[str]],
    restaurant_tags_map: dict[int, list[str]],
    user_id: int | None = None,
) -> list[Dish]:
    """
    Hard-filter unsafe dishes before scoring. O(n) over ``dishes``.

    Reuses ``is_dish_safe_for_group`` from group recommendations.
    """
    allergy_set = _allergy_set(allergies)
    if not allergy_set:
        return dishes

    safe: list[Dish] = []
    for dish in dishes:
        dish_tags = dish_tags_map.get(dish.id, [])
        restaurant_tags = (
            restaurant_tags_map.get(dish.restaurant_id, []) if dish.restaurant_id else []
        )
        if is_dish_safe_for_group(
            dish,
            allergy_set,
            dish_tags=dish_tags,
            restaurant_tags=restaurant_tags,
        ):
            safe.append(dish)

    log_pipeline_stage(
        "allergy_filter",
        user_id=user_id,
        before=len(dishes),
        after=len(safe),
        excluded=len(dishes) - len(safe),
        allergies=len(allergy_set),
    )
    return safe
