"""Restaurant approval status constants."""

PENDING = "pending"
APPROVED = "approved"
REJECTED = "rejected"

ALL_STATUSES = frozenset({PENDING, APPROVED, REJECTED})

# Standard dish allergen tags (stored on dish.allergens JSON array).
DISH_ALLERGENS = frozenset(
    {
        "peanut",
        "dairy",
        "gluten",
        "soy",
        "egg",
        "shellfish",
        "tree_nut",
    }
)

# Map user preference allergy keys → dish allergen tags.
USER_ALLERGY_TO_DISH_TAG: dict[str, str] = {
    "peanuts": "peanut",
    "peanut": "peanut",
    "tree_nuts": "tree_nut",
    "tree_nut": "tree_nut",
    "shellfish": "shellfish",
    "fish": "shellfish",
    "eggs": "egg",
    "egg": "egg",
    "milk": "dairy",
    "dairy": "dairy",
    "lactose": "dairy",
    "gluten": "gluten",
    "wheat": "gluten",
    "soy": "soy",
    "soya": "soy",
}
