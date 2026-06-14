"""Preference onboarding schemas and static option catalogs."""

from pydantic import BaseModel, Field, field_validator

from app.schemas.user_preference import ALLOWED_ALLERGIES, UserPreferencesResponse

MAX_ONBOARDING_CUISINES = 10
MAX_ONBOARDING_ALLERGIES = 20

FOOD_INTEREST_OPTIONS: tuple[dict[str, str], ...] = (
    {"key": "burger", "display_name": "Burger"},
    {"key": "pizza", "display_name": "Pizza"},
    {"key": "biryani", "display_name": "Biryani"},
    {"key": "bbq", "display_name": "BBQ"},
    {"key": "chinese", "display_name": "Chinese"},
    {"key": "italian", "display_name": "Italian"},
    {"key": "shawarma", "display_name": "Shawarma"},
    {"key": "desserts", "display_name": "Desserts"},
    {"key": "healthy", "display_name": "Healthy"},
    {"key": "cafe", "display_name": "Cafe"},
    {"key": "sushi", "display_name": "Sushi"},
    {"key": "pakistani", "display_name": "Pakistani"},
    {"key": "fast_food", "display_name": "Fast Food"},
    {"key": "seafood", "display_name": "Seafood"},
    {"key": "sandwiches", "display_name": "Sandwiches"},
)

FOOD_INTEREST_KEYS = frozenset(option["key"] for option in FOOD_INTEREST_OPTIONS)

ALLERGY_DISPLAY_NAMES: dict[str, str] = {
    "peanuts": "Peanuts",
    "tree_nuts": "Tree Nuts",
    "shellfish": "Shellfish",
    "fish": "Fish",
    "eggs": "Eggs",
    "milk": "Milk",
    "dairy": "Dairy",
    "soy": "Soy",
    "wheat": "Wheat",
    "gluten": "Gluten",
    "sesame": "Sesame",
    "mustard": "Mustard",
    "celery": "Celery",
    "sulphites": "Sulphites",
    "lupin": "Lupin",
    "molluscs": "Molluscs",
    "lactose": "Lactose",
    "nuts": "Nuts",
}


class FoodInterestOption(BaseModel):
    key: str
    display_name: str


class AllergyOption(BaseModel):
    key: str
    display_name: str


class OnboardingOptionsResponse(BaseModel):
    food_interests: list[FoodInterestOption]
    allergies: list[AllergyOption]


class OnboardingStatusResponse(BaseModel):
    completed: bool


class OnboardingCompleteRequest(BaseModel):
    favorite_cuisines: list[str] = Field(default_factory=list)
    allergies: list[str] = Field(default_factory=list)

    @field_validator("favorite_cuisines")
    @classmethod
    def validate_favorite_cuisines(cls, value: list[str]) -> list[str]:
        if len(value) > MAX_ONBOARDING_CUISINES:
            raise ValueError(f"At most {MAX_ONBOARDING_CUISINES} food interests allowed")
        normalized: list[str] = []
        seen: set[str] = set()
        for raw in value:
            key = str(raw).strip().lower().replace(" ", "_").replace("-", "_")
            if not key:
                continue
            if key not in FOOD_INTEREST_KEYS:
                allowed = ", ".join(sorted(FOOD_INTEREST_KEYS))
                raise ValueError(f"Invalid food interest '{raw}'. Allowed: {allowed}")
            if key not in seen:
                seen.add(key)
                normalized.append(key)
        return normalized

    @field_validator("allergies")
    @classmethod
    def validate_allergies(cls, value: list[str]) -> list[str]:
        if len(value) > MAX_ONBOARDING_ALLERGIES:
            raise ValueError(f"At most {MAX_ONBOARDING_ALLERGIES} allergies allowed")
        normalized: list[str] = []
        seen: set[str] = set()
        for raw in value:
            key = str(raw).strip().lower().replace(" ", "_").replace("-", "_")
            if not key:
                continue
            if key not in ALLOWED_ALLERGIES:
                allowed = ", ".join(sorted(ALLOWED_ALLERGIES))
                raise ValueError(f"Invalid allergy '{raw}'. Allowed: {allowed}")
            if key not in seen:
                seen.add(key)
                normalized.append(key)
        return normalized


class OnboardingCompleteResponse(BaseModel):
    completed: bool = True
    preferences: UserPreferencesResponse
