"""Preference-aware scoring helpers for Recommendation Engine V2."""

from __future__ import annotations

import re

from app.models.dish import Dish

_MEAT_KEYWORDS = frozenset(
    {
        "chicken",
        "beef",
        "mutton",
        "lamb",
        "pork",
        "bacon",
        "ham",
        "sausage",
        "pepperoni",
        "fish",
        "shrimp",
        "prawn",
    }
)

_DIETARY_KEYWORDS: dict[str, tuple[str, ...]] = {
    "vegetarian": ("vegetarian", "veg ", " paneer", "dal ", "veggie"),
    "vegan": ("vegan", "plant-based", "plant based"),
    "halal": ("halal",),
    "gluten_free": ("gluten free", "gluten-free"),
    "dairy_free": ("dairy free", "dairy-free", "lactose free"),
    "nut_free": ("nut free", "nut-free"),
    "pescatarian": ("pescatarian", "seafood"),
    "keto": ("keto", "low carb"),
    "low_carb": ("low carb", "keto"),
}


def normalize_preference_token(value: str) -> str:
    return re.sub(r"\s+", " ", str(value).strip().lower())


def is_disliked_category(dish: Dish, disliked_categories: list[str]) -> bool:
    if not disliked_categories or not dish.category or not dish.category.name:
        return False
    category_name = normalize_preference_token(dish.category.name)
    for disliked in disliked_categories:
        token = normalize_preference_token(disliked)
        if token and (token in category_name or category_name in token):
            return True
    return False


def _text_blob(dish: Dish, dish_tags: list[str], restaurant_tags: list[str]) -> str:
    parts = [
        dish.name or "",
        dish.description or "",
        dish.restaurant.name if dish.restaurant else "",
        dish.restaurant.description if dish.restaurant and dish.restaurant.description else "",
        dish.category.name if dish.category and dish.category.name else "",
        " ".join(dish_tags),
        " ".join(restaurant_tags),
    ]
    return normalize_preference_token(" ".join(parts))


def score_dietary_preferences(
    dish: Dish,
    dietary_preferences: list[str],
    *,
    dish_tags: list[str],
    restaurant_tags: list[str],
    max_points: float = 15.0,
) -> tuple[float, str | None]:
    """
    Award nutrition-slot points when menu text/tags align with dietary preferences.
    Apply a penalty when preferences strongly conflict (e.g. vegan + chicken).
    """
    if not dietary_preferences:
        return 0.0, None

    blob = _text_blob(dish, dish_tags, restaurant_tags)
    matched: str | None = None
    for pref in dietary_preferences:
        keywords = _DIETARY_KEYWORDS.get(pref, (pref.replace("_", " "), pref))
        if any(keyword in blob for keyword in keywords):
            matched = pref
            break

    if matched:
        return min(max_points, 12.0), matched

    if "vegan" in dietary_preferences or "vegetarian" in dietary_preferences:
        if any(keyword in blob for keyword in _MEAT_KEYWORDS):
            return -20.0, None

    return 0.0, None
