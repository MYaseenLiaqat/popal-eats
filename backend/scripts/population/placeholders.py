"""Shared placeholder detection for FYP population scripts."""

from __future__ import annotations

import re

from app.services.recommendation.v2_placeholders import is_placeholder_name

_PLACEHOLDER_SUBSTRINGS = (
    "lorem ipsum",
    "dummy",
    "placeholder",
    "test restaurant",
    "sample restaurant",
    "unknown restaurant",
    "todo",
    "fixme",
    "xxx",
)

_R_CODE_PATTERN = re.compile(r"^r[\s\-_]?\d", re.IGNORECASE)


def is_bad_text(value: str | None) -> bool:
    if value is None:
        return True
    text = value.strip()
    if not text:
        return True
    lower = text.lower()
    if lower in {"string", "unknown", "null", "none", "n/a", "na", "test"}:
        return True
    for token in _PLACEHOLDER_SUBSTRINGS:
        if token in lower:
            return True
    return False


def is_bad_restaurant_name(name: str | None) -> bool:
    if is_placeholder_name(name, entity="restaurant"):
        return True
    if name and _R_CODE_PATTERN.match(name.strip()):
        return True
    return is_bad_text(name)


def is_bad_dish_name(name: str | None) -> bool:
    if is_placeholder_name(name, entity="dish"):
        return True
    return is_bad_text(name)
