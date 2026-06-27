"""Phone number normalization and validation."""

from __future__ import annotations

import re

_DIGITS_ONLY = re.compile(r"\D+")


def normalize_phone(value: str) -> str:
    """Normalize to E.164-style +{country}{number} when possible."""
    trimmed = value.strip()
    if not trimmed:
        raise ValueError("Phone number is required.")

    has_plus = trimmed.startswith("+")
    digits = _DIGITS_ONLY.sub("", trimmed)
    if len(digits) < 8 or len(digits) > 15:
        raise ValueError("Enter a valid international phone number.")

    if has_plus:
        return f"+{digits}"
    return f"+{digits}"


def phones_equivalent(a: str | None, b: str | None) -> bool:
    if not a or not b:
        return False
    try:
        return normalize_phone(a) == normalize_phone(b)
    except ValueError:
        return False
