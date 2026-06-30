"""Placeholder name detection shared by candidate loading and caches."""

import re

_PLACEHOLDER_EXACT = frozenset(
    {
        "string",
        "test",
        "test dish",
        "dish",
        "name",
        "food",
        "item",
        "restaurant",
        "sample",
        "example",
        "title",
    }
)

_TEST_NAME_PATTERN = re.compile(r"^test[\s_-]", re.IGNORECASE)

_RESTAURANT_PLACEHOLDER_EXACT = frozenset({"pizza", "restaurant", "string"})


def is_placeholder_name(name: str | None, *, entity: str = "dish") -> bool:
    """True when a dish or restaurant name looks like test/placeholder data."""
    if name is None:
        return True
    stripped = name.strip()
    if len(stripped) < 2:
        return True
    lowered = stripped.lower()
    if lowered in _PLACEHOLDER_EXACT:
        return True
    if entity == "restaurant" and lowered in _RESTAURANT_PLACEHOLDER_EXACT:
        return True
    if _TEST_NAME_PATTERN.match(stripped):
        return True
    return False
