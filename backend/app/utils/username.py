"""Username validation helpers."""

from __future__ import annotations

import re

USERNAME_PATTERN = re.compile(r"^[a-z][a-z0-9_]{2,31}$")
RESERVED = frozenset(
    {
        "admin",
        "api",
        "help",
        "popal",
        "popaleats",
        "root",
        "support",
        "system",
        "user",
    }
)


def normalize_username(value: str) -> str:
    return value.strip().lower()


def validate_username(value: str) -> str:
    username = normalize_username(value)
    if not USERNAME_PATTERN.match(username):
        raise ValueError(
            "Username must be 3–32 characters, start with a letter, "
            "and use only lowercase letters, numbers, and underscores."
        )
    if username in RESERVED:
        raise ValueError("That username is reserved.")
    return username


def suggest_username_from_email(email: str) -> str:
    local = email.split("@", 1)[0].lower()
    cleaned = re.sub(r"[^a-z0-9_]", "_", local).strip("_")
    if not cleaned or not cleaned[0].isalpha():
        cleaned = f"user_{cleaned or 'new'}"
    return cleaned[:32]
