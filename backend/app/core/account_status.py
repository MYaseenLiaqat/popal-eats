"""Account lifecycle status constants."""

ACTIVE = "active"
PENDING = "pending"
SUSPENDED = "suspended"
REJECTED = "rejected"

ALL_STATUSES = frozenset({ACTIVE, PENDING, SUSPENDED, REJECTED})

_LOGIN_BLOCKED = frozenset({SUSPENDED})


def blocks_business_access(status: str | None) -> bool:
    """Non-active business accounts cannot use owner/chef features."""
    return normalize_account_status(status) != ACTIVE


def normalize_account_status(status: str | None) -> str:
    if not status:
        return ACTIVE
    return status.strip().lower()


def is_valid_account_status(status: str) -> bool:
    return normalize_account_status(status) in ALL_STATUSES


def blocks_login(status: str | None) -> bool:
    return normalize_account_status(status) in _LOGIN_BLOCKED
