"""Role constants and normalization for RBAC."""

ADMIN = "admin"
CUSTOMER = "customer"
RESTAURANT = "restaurant"
HOME_CHEF = "home_chef"

# Legacy alias — treated as RESTAURANT everywhere.
RESTAURANT_OWNER = "restaurant_owner"

ALL_ROLES = frozenset({ADMIN, CUSTOMER, RESTAURANT, HOME_CHEF, RESTAURANT_OWNER})

# Roles allowed during public self-registration (admin is seed-only).
SIGNUP_ROLES = frozenset({CUSTOMER, RESTAURANT, HOME_CHEF})

_LEGACY_ROLE_MAP = {
    "user": CUSTOMER,
    RESTAURANT_OWNER: RESTAURANT,
}


def normalize_role(role: str | None) -> str:
    if not role:
        return CUSTOMER
    role = role.strip().lower()
    return _LEGACY_ROLE_MAP.get(role, role)


def is_valid_role(role: str) -> bool:
    return normalize_role(role) in {ADMIN, CUSTOMER, RESTAURANT, HOME_CHEF}


def is_restaurant_role(role: str | None) -> bool:
    normalized = normalize_role(role)
    return normalized in {RESTAURANT, RESTAURANT_OWNER}


def is_home_chef_role(role: str | None) -> bool:
    return normalize_role(role) == HOME_CHEF
