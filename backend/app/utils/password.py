"""Password strength validation."""

from __future__ import annotations

import re

_MIN_LEN = 8
_MAX_LEN = 128

_UPPER = re.compile(r"[A-Z]")
_LOWER = re.compile(r"[a-z]")
_DIGIT = re.compile(r"\d")
_SPECIAL = re.compile(r"[^A-Za-z0-9]")


def validate_password(password: str) -> str:
    if len(password) < _MIN_LEN:
        raise ValueError("Password must be at least 8 characters.")
    if len(password) > _MAX_LEN:
        raise ValueError("Password must be at most 128 characters.")
    if not _UPPER.search(password):
        raise ValueError("Password must include at least one uppercase letter.")
    if not _LOWER.search(password):
        raise ValueError("Password must include at least one lowercase letter.")
    if not _DIGIT.search(password):
        raise ValueError("Password must include at least one number.")
    if not _SPECIAL.search(password):
        raise ValueError("Password must include at least one special character.")
    return password
