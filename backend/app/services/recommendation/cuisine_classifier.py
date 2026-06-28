"""
Dish-level cuisine classification for recommendation tag enrichment.

Maps dishes to preference-tier cuisine slugs (pakistani, turkish, italian, …)
using name, category, restaurant metadata, and keyword fuzzy matching.

Results are cached per dish signature — not recomputed on every request.
"""

from __future__ import annotations

import re
from functools import lru_cache
from typing import Any

from app.models.dish import Dish
from app.services.catalog.tag_normalization import (
    extract_keyword_tags,
    normalize_tag,
    normalize_tags,
    slugify_token,
)

INTERNATIONAL = "international"

PREFERENCE_CUISINES: frozenset[str] = frozenset(
    {
        "pakistani",
        "afghan",
        "turkish",
        "arabic",
        "chinese",
        "italian",
        "american",
        "indian",
        "thai",
        "japanese",
        "korean",
        "mexican",
        "fast_food",
        "seafood",
        "vegetarian",
        "desserts",
        INTERNATIONAL,
    }
)

# Canonical catalog tags → preference-tier cuisine.
_CANONICAL_TO_PREFERENCE: dict[str, str] = {
    "pakistani": "pakistani",
    "biryani": "pakistani",
    "indian": "indian",
    "afghan": "afghan",
    "turkish": "turkish",
    "arabic": "arabic",
    "middle_eastern": "arabic",
    "lebanese": "arabic",
    "shawarma": "arabic",
    "chinese": "chinese",
    "asian": "chinese",
    "italian": "italian",
    "pizza": "italian",
    "american": "american",
    "burger": "american",
    "steak": "american",
    "thai": "thai",
    "japanese": "japanese",
    "sushi": "japanese",
    "korean": "korean",
    "mexican": "mexican",
    "fast_food": "fast_food",
    "broast": "fast_food",
    "wings": "fast_food",
    "sandwich": "fast_food",
    "wraps": "fast_food",
    "seafood": "seafood",
    "vegetarian": "vegetarian",
    "vegan": "vegetarian",
    "healthy": "vegetarian",
    "desserts": "desserts",
    "bakery": "desserts",
    "ice_cream": "desserts",
    "cafe": "desserts",
}

# Preference cuisine → weighted keyword needles in slugified text.
_CUISINE_KEYWORDS: dict[str, tuple[tuple[str, int], ...]] = {
    "pakistani": (
        ("biryani", 4),
        ("karahi", 4),
        ("nihari", 4),
        ("pulao", 3),
        ("haleem", 4),
        ("chapli", 4),
        ("seekh kebab", 4),
        ("handi", 3),
        ("daal", 3),
        ("sajji", 4),
        ("pakistani", 5),
        ("desi", 2),
    ),
    "afghan": (
        ("kabuli pulao", 5),
        ("mantu", 5),
        ("bolani", 4),
        ("ashak", 4),
        ("afghan", 5),
        ("afghani", 4),
    ),
    "turkish": (
        ("doner", 5),
        ("iskender", 5),
        ("pide", 4),
        ("lahmacun", 5),
        ("adana", 4),
        ("kofte", 4),
        ("turkish", 5),
    ),
    "arabic": (
        ("shawarma", 5),
        ("falafel", 4),
        ("hummus", 4),
        ("kunafa", 4),
        ("mandi", 4),
        ("kabsa", 4),
        ("arabic", 5),
        ("middle eastern", 4),
        ("lebanese", 4),
    ),
    "chinese": (
        ("noodle", 3),
        ("fried rice", 4),
        ("dumpling", 4),
        ("manchurian", 4),
        ("chow mein", 5),
        ("chinese", 5),
    ),
    "italian": (
        ("pizza", 4),
        ("pasta", 4),
        ("lasagna", 5),
        ("risotto", 4),
        ("ravioli", 4),
        ("italian", 5),
    ),
    "american": (
        ("burger", 4),
        ("steak", 3),
        ("hot dog", 4),
        ("fried chicken", 3),
        ("american", 5),
    ),
    "indian": (
        ("butter chicken", 5),
        ("paneer", 3),
        ("tandoori", 4),
        ("masala", 3),
        ("dosa", 4),
        ("indian", 5),
    ),
    "thai": (
        ("pad thai", 5),
        ("green curry", 5),
        ("tom yum", 5),
        ("thai", 5),
    ),
    "japanese": (
        ("sushi", 5),
        ("ramen", 5),
        ("tempura", 4),
        ("udon", 4),
        ("japanese", 5),
    ),
    "korean": (
        ("bibimbap", 5),
        ("kimchi", 4),
        ("bulgogi", 5),
        ("tteokbokki", 5),
        ("korean", 5),
    ),
    "mexican": (
        ("taco", 5),
        ("burrito", 5),
        ("quesadilla", 5),
        ("nachos", 4),
        ("mexican", 5),
    ),
    "fast_food": (
        ("burger", 3),
        ("pizza", 2),
        ("fries", 4),
        ("sandwich", 3),
        ("wrap", 3),
        ("fried chicken", 3),
        ("broast", 4),
        ("zinger", 4),
        ("fast food", 5),
    ),
    "seafood": (
        ("fish", 3),
        ("prawn", 4),
        ("shrimp", 4),
        ("crab", 4),
        ("lobster", 4),
        ("salmon", 4),
        ("seafood", 5),
    ),
    "vegetarian": (
        ("salad", 3),
        ("veg curry", 4),
        ("paneer", 3),
        ("vegetable rice", 3),
        ("vegetarian", 5),
        ("vegan", 4),
    ),
    "desserts": (
        ("cake", 4),
        ("donut", 4),
        ("doughnut", 4),
        ("ice cream", 4),
        ("brownie", 4),
        ("baklava", 4),
        ("cookie", 3),
        ("dessert", 5),
        ("bakery", 4),
    ),
}


def _normalize_preference_slug(raw: str | None) -> str | None:
    if not raw:
        return None
    slug = normalize_tag(raw) or slugify_token(raw).replace(" ", "_")
    if slug in PREFERENCE_CUISINES:
        return slug
    if slug in _CANONICAL_TO_PREFERENCE:
        return _CANONICAL_TO_PREFERENCE[slug]
    if slug == "middle_eastern":
        return "arabic"
    return None


def _score_from_blob(blob: str) -> dict[str, int]:
    scores: dict[str, int] = {}
    for cuisine, needles in _CUISINE_KEYWORDS.items():
        total = 0
        for needle, weight in needles:
            if needle in blob:
                total += weight
        if total > 0:
            scores[cuisine] = total
    return scores


def _pick_strongest(scores: dict[str, int]) -> str | None:
    if not scores:
        return None
    best_score = max(scores.values())
    winners = sorted(c for c, s in scores.items() if s == best_score)
    return winners[0]


def _cuisines_from_description(description: str | None) -> list[str]:
    if not description:
        return []
    for line in description.splitlines():
        stripped = line.strip()
        if stripped.startswith("Cuisines:"):
            payload = stripped.split(":", 1)[1]
            return [part.strip().lower() for part in payload.split(",") if part.strip()]
    return []


def _restaurant_tag_list(restaurant: Any) -> list[str]:
    if restaurant is None:
        return []
    raw_tags = restaurant.tags if isinstance(getattr(restaurant, "tags", None), list) else []
    tags = normalize_tags(str(t) for t in raw_tags)
    if not tags:
        tags = _cuisines_from_description(getattr(restaurant, "description", None))
    return tags


@lru_cache(maxsize=65536)
def classify_dish_cuisine_cached(
    *,
    dish_name: str,
    dish_description: str,
    dish_cuisine: str,
    category_name: str,
    restaurant_name: str,
    restaurant_description: str,
    restaurant_tags_key: str,
) -> str:
    """Cached classifier keyed by dish/restaurant text fields (not ORM identity)."""
    scores: dict[str, int] = {}

    for source in (dish_cuisine, category_name):
        pref = _normalize_preference_slug(source)
        if pref and pref != INTERNATIONAL:
            scores[pref] = scores.get(pref, 0) + 6

    for tag in normalize_tags(restaurant_tags_key.split("|") if restaurant_tags_key else []):
        pref = _CANONICAL_TO_PREFERENCE.get(tag, _normalize_preference_slug(tag))
        if pref and pref != INTERNATIONAL:
            scores[pref] = scores.get(pref, 0) + 4

    for tag in extract_keyword_tags(dish_name, dish_description, category_name, restaurant_name):
        pref = _CANONICAL_TO_PREFERENCE.get(tag, _normalize_preference_slug(tag))
        if pref and pref != INTERNATIONAL:
            scores[pref] = scores.get(pref, 0) + 3

    blob = slugify_token(
        " ".join(
            part
            for part in (
                dish_name,
                dish_description,
                category_name,
                restaurant_name,
                restaurant_description,
                dish_cuisine,
            )
            if part
        )
    )
    for cuisine, amount in _score_from_blob(blob).items():
        scores[cuisine] = scores.get(cuisine, 0) + amount

    winner = _pick_strongest(scores)
    return winner or INTERNATIONAL


def classify_dish(dish: Dish) -> str:
    """Classify a dish ORM row into a preference-tier cuisine slug."""
    restaurant = dish.restaurant
    restaurant_tags = _restaurant_tag_list(restaurant)
    return classify_dish_cuisine_cached(
        dish_name=dish.name or "",
        dish_description=dish.description or "",
        dish_cuisine=dish.cuisine or "",
        category_name=dish.category.name if dish.category and dish.category.name else "",
        restaurant_name=restaurant.name if restaurant and restaurant.name else "",
        restaurant_description=restaurant.description if restaurant and restaurant.description else "",
        restaurant_tags_key="|".join(restaurant_tags),
    )


def cuisine_tags_for_dish(dish: Dish) -> list[str]:
    """
    Tags to inject for recommendation matching: primary cuisine + useful aliases.
    """
    primary = classify_dish(dish)
    tags = [primary]
    if primary == "arabic":
        tags.extend(["middle_eastern", "shawarma"])
    elif primary == "italian":
        tags.append("pizza")
    elif primary == "japanese":
        tags.append("sushi")
    elif primary == "fast_food":
        tags.extend(["burger", "fast_food"])
    elif primary == "desserts":
        tags.extend(["desserts", "bakery"])
    deduped: list[str] = []
    seen: set[str] = set()
    for tag in tags:
        if tag not in seen:
            seen.add(tag)
            deduped.append(tag)
    return deduped
