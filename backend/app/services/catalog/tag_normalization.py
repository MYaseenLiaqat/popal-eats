"""Controlled cuisine/tag taxonomy and normalization for catalog enrichment."""

from __future__ import annotations

import re
from typing import Iterable

# Canonical tags used across restaurants and dishes.
CANONICAL_TAGS: frozenset[str] = frozenset(
    {
        "american",
        "arabic",
        "asian",
        "bakery",
        "bbq",
        "beverages",
        "biryani",
        "breakfast",
        "broast",
        "burger",
        "cafe",
        "chinese",
        "continental",
        "desserts",
        "fast_food",
        "healthy",
        "ice_cream",
        "indian",
        "italian",
        "japanese",
        "korean",
        "lebanese",
        "mexican",
        "middle_eastern",
        "pakistani",
        "pizza",
        "sandwich",
        "seafood",
        "shawarma",
        "soup",
        "steak",
        "sushi",
        "thai",
        "turkish",
        "vegan",
        "vegetarian",
        "wings",
        "wraps",
    }
)

# Alias → canonical slug (keys are pre-slugified lookup tokens).
TAG_ALIASES: dict[str, str] = {
    "burger": "burger",
    "burgers": "burger",
    "beef burger": "burger",
    "beef burgers": "burger",
    "zinger": "burger",
    "fast food": "fast_food",
    "fast_food": "fast_food",
    "fastfood": "fast_food",
    "bbq": "bbq",
    "bar b q": "bbq",
    "bar bq": "bbq",
    "barbecue": "bbq",
    "barbeque": "bbq",
    "pizza": "pizza",
    "pizzas": "pizza",
    "chinese": "chinese",
    "chinese food": "chinese",
    "pakistani": "pakistani",
    "desi": "pakistani",
    "local": "pakistani",
    "dessert": "desserts",
    "desserts": "desserts",
    "sweet": "desserts",
    "sweets": "desserts",
    "biryani": "biryani",
    "biryanis": "biryani",
    "broast": "broast",
    "fried chicken": "broast",
    "cafe": "cafe",
    "coffee": "cafe",
    "beverages": "beverages",
    "beverage": "beverages",
    "drinks": "beverages",
    "italian": "italian",
    "american": "american",
    "continental": "continental",
    "indian": "indian",
    "thai": "thai",
    "japanese": "japanese",
    "korean": "korean",
    "mexican": "mexican",
    "turkish": "turkish",
    "lebanese": "lebanese",
    "arabic": "arabic",
    "middle eastern": "middle_eastern",
    "middle_eastern": "middle_eastern",
    "seafood": "seafood",
    "fish": "seafood",
    "shawarma": "shawarma",
    "wraps": "wraps",
    "wrap": "wraps",
    "sandwich": "sandwich",
    "sandwiches": "sandwich",
    "breakfast": "breakfast",
    "healthy": "healthy",
    "salad": "healthy",
    "vegetarian": "vegetarian",
    "vegan": "vegan",
    "ice cream": "ice_cream",
    "ice_cream": "ice_cream",
    "bakery": "bakery",
    "cakes and bakery": "bakery",
    "cakes & bakery": "bakery",
    "wings": "wings",
    "chicken wings": "wings",
    "steak": "steak",
    "sushi": "sushi",
    "soup": "soup",
    "soups": "soup",
    "asian": "asian",
}

# Keyword hints in free text (dish/restaurant names).
KEYWORD_HINTS: tuple[tuple[str, str], ...] = (
    ("pizza", "pizza"),
    ("burger", "burger"),
    ("biryani", "biryani"),
    ("broast", "broast"),
    ("shawarma", "shawarma"),
    ("bbq", "bbq"),
    ("barbecue", "bbq"),
    ("chinese", "chinese"),
    ("sushi", "sushi"),
    ("pasta", "italian"),
    ("lasagna", "italian"),
    ("karahi", "pakistani"),
    ("nihari", "pakistani"),
    ("halwa", "desserts"),
    ("brownie", "desserts"),
    ("cake", "desserts"),
    ("ice cream", "ice_cream"),
    ("coffee", "cafe"),
    ("tea", "beverages"),
    ("shake", "beverages"),
    ("wings", "wings"),
    ("steak", "steak"),
    ("fish", "seafood"),
    ("prawn", "seafood"),
    ("wrap", "wraps"),
    ("sandwich", "sandwich"),
    ("salad", "healthy"),
    ("vegan", "vegan"),
    ("vegetarian", "vegetarian"),
)


def slugify_token(value: str) -> str:
    """Lowercase slug: spaces/hyphens → underscore, strip punctuation."""
    text = str(value or "").strip().lower()
    text = re.sub(r"[&/]", " and ", text)
    text = re.sub(r"[^a-z0-9\s_-]", "", text)
    text = re.sub(r"[\s-]+", " ", text).strip()
    return text


def normalize_tag(raw: str) -> str | None:
    """Map a raw cuisine/category string to a canonical tag slug."""
    if not raw or not str(raw).strip():
        return None

    lowered = slugify_token(str(raw))
    if not lowered:
        return None

    if lowered in TAG_ALIASES:
        return TAG_ALIASES[lowered]

    underscored = lowered.replace(" ", "_")
    if underscored in TAG_ALIASES:
        return TAG_ALIASES[underscored]
    if underscored in CANONICAL_TAGS:
        return underscored

    # Try alias keys with spaces instead of underscores.
    spaced = lowered.replace("_", " ")
    if spaced in TAG_ALIASES:
        return TAG_ALIASES[spaced]

    # Accept unknown slugs that look like clean single tokens (category passthrough).
    if re.fullmatch(r"[a-z0-9_]+", underscored) and len(underscored) >= 3:
        return underscored
    return None


def normalize_tags(values: Iterable[str]) -> list[str]:
    """Normalize, deduplicate, and sort tag list."""
    seen: set[str] = set()
    result: list[str] = []
    for raw in values:
        canonical = normalize_tag(raw)
        if canonical and canonical not in seen:
            seen.add(canonical)
            result.append(canonical)
    return sorted(result)


def extract_keyword_tags(*texts: str | None) -> list[str]:
    """Infer canonical tags from free-text fields (names, descriptions)."""
    blob = slugify_token(" ".join(t for t in texts if t))
    if not blob:
        return []
    found: list[str] = []
    seen: set[str] = set()
    for needle, canonical in KEYWORD_HINTS:
        if needle in blob and canonical not in seen:
            seen.add(canonical)
            found.append(canonical)
    return found
