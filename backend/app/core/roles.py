"""Role constants and normalization for RBAC."""

ADMIN = "admin"
RESTAURANT_OWNER = "restaurant_owner"
CUSTOMER = "customer"

ALL_ROLES = frozenset({ADMIN, RESTAURANT_OWNER, CUSTOMER})

# Legacy registrations used "user" — treat as customer.
_LEGACY_ROLE_MAP = {"user": CUSTOMER}


def normalize_role(role: str | None) -> str:
    if not role:
        return CUSTOMER
    role = role.strip().lower()
    return _LEGACY_ROLE_MAP.get(role, role)


def is_valid_role(role: str) -> bool:
    return normalize_role(role) in ALL_ROLES
