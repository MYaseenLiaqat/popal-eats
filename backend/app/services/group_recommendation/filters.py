"""Hard filters for group recommendation (allergies, dietary strict mode)."""

from __future__ import annotations

from app.models.dish import Dish
from app.services.recommendation.preference_scoring import normalize_preference_token

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
        "meat",
        "karahi",
        "nihari",
    }
)

_DAIRY_KEYWORDS = frozenset(
    {
        "cheese",
        "milk",
        "cream",
        "butter",
        "yogurt",
        "yoghurt",
        "paneer",
        "dairy",
        "mozzarella",
        "cheddar",
    }
)

_EGG_KEYWORDS = frozenset({"egg", "eggs", "omelette", "omelet"})

_GLUTEN_KEYWORDS = frozenset({"wheat", "gluten", "bread", "naan", "roti", "pasta"})

_NUT_KEYWORDS = frozenset(
    {
        "peanut",
        "peanuts",
        "almond",
        "walnut",
        "cashew",
        "pistachio",
        "hazelnut",
        "pecan",
        "tree nut",
        "nut ",
        " nuts",
    }
)

ALLERGY_SEARCH_TERMS: dict[str, tuple[str, ...]] = {
    "peanuts": ("peanut", "peanuts", "peanut butter"),
    "tree_nuts": ("almond", "walnut", "cashew", "pistachio", "hazelnut", "pecan", "tree nut"),
    "shellfish": ("shellfish", "shrimp", "prawn", "crab", "lobster"),
    "fish": ("fish", "salmon", "tuna", "cod"),
    "eggs": ("egg", "eggs", "omelette", "omelet"),
    "milk": ("milk", "dairy", "cheese", "cream", "butter", "yogurt", "paneer"),
    "dairy": ("milk", "dairy", "cheese", "cream", "butter", "yogurt", "paneer"),
    "soy": ("soy", "soya", "tofu", "edamame"),
    "wheat": ("wheat", "flour", "bread", "naan", "roti"),
    "gluten": ("gluten", "wheat", "bread", "pasta", "naan"),
    "sesame": ("sesame", "tahini"),
    "mustard": ("mustard",),
    "celery": ("celery",),
    "sulphites": ("sulphite", "sulfite"),
    "lupin": ("lupin",),
    "molluscs": ("mollusc", "mollusk", "clam", "oyster", "mussel"),
    "lactose": ("lactose", "milk", "cheese", "cream"),
    "nuts": ("nut", "nuts", "peanut", "almond", "walnut", "cashew"),
}


def _dish_text_blob(dish: Dish, dish_tags: list[str], restaurant_tags: list[str]) -> str:
    parts = [
        dish.name or "",
        dish.description or "",
        dish.restaurant.name if dish.restaurant else "",
        dish.category.name if dish.category and dish.category.name else "",
        " ".join(dish_tags),
        " ".join(restaurant_tags),
    ]
    return normalize_preference_token(" ".join(parts))


def _contains_any(blob: str, keywords: tuple[str, ...] | frozenset[str]) -> bool:
    return any(keyword in blob for keyword in keywords)


def is_dish_safe_for_group(
    dish: Dish,
    group_allergies: set[str],
    *,
    dish_tags: list[str] | None = None,
    restaurant_tags: list[str] | None = None,
) -> bool:
    """Hard filter — False when any group allergy appears in dish signals."""
    if not group_allergies:
        return True

    blob = _dish_text_blob(dish, dish_tags or [], restaurant_tags or [])
    for allergy in group_allergies:
        terms = ALLERGY_SEARCH_TERMS.get(allergy, (allergy.replace("_", " "),))
        if _contains_any(blob, terms):
            return False
    return True


def _satisfies_diet(
    dish: Dish,
    diet: str,
    blob: str,
    dish_tags: list[str],
    restaurant_tags: list[str],
) -> bool:
    tags_blob = normalize_preference_token(" ".join(dish_tags + restaurant_tags))

    if diet == "vegetarian":
        return not _contains_any(blob, _MEAT_KEYWORDS)

    if diet == "vegan":
        if _contains_any(blob, _MEAT_KEYWORDS | _DAIRY_KEYWORDS | _EGG_KEYWORDS):
            return False
        return "vegan" in tags_blob or "plant" in blob

    if diet == "halal":
        return "halal" in tags_blob or "halal" in blob

    if diet == "gluten_free":
        if "gluten_free" in tags_blob or "gluten free" in blob or "gluten-free" in blob:
            return True
        return not _contains_any(blob, _GLUTEN_KEYWORDS)

    if diet == "dairy_free":
        if "dairy_free" in tags_blob or "dairy free" in blob or "dairy-free" in blob:
            return True
        return not _contains_any(blob, _DAIRY_KEYWORDS)

    if diet == "nut_free":
        if "nut_free" in tags_blob or "nut free" in blob:
            return True
        return not _contains_any(blob, _NUT_KEYWORDS)

    if diet == "pescatarian":
        land_meat = _MEAT_KEYWORDS - {"fish", "shrimp", "prawn"}
        return not _contains_any(blob, land_meat)

    if diet in {"keto", "low_carb"}:
        return "keto" in tags_blob or "low carb" in blob or "low-carb" in blob or "keto" in blob

    keyword = diet.replace("_", " ")
    return keyword in blob or diet in tags_blob


def dietary_compatibility_score(
    dish: Dish,
    group_dietary: set[str],
    *,
    dish_tags: list[str] | None = None,
    restaurant_tags: list[str] | None = None,
) -> float:
    """
    Strict dietary compatibility score.

    Returns 100 when the dish satisfies every group dietary requirement, else 0.
    """
    if not group_dietary:
        return 100.0

    blob = _dish_text_blob(dish, dish_tags or [], restaurant_tags or [])
    tags = dish_tags or []
    rest_tags = restaurant_tags or []
    for diet in group_dietary:
        if not _satisfies_diet(dish, diet, blob, tags, rest_tags):
            return 0.0
    return 100.0


def is_dish_dietary_compatible(
    dish: Dish,
    group_dietary: set[str],
    *,
    dish_tags: list[str] | None = None,
    restaurant_tags: list[str] | None = None,
) -> bool:
    return dietary_compatibility_score(
        dish,
        group_dietary,
        dish_tags=dish_tags,
        restaurant_tags=restaurant_tags,
    ) >= 100.0
