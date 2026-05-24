"""
Role-based access control dependencies.

Roles: admin, restaurant_owner, customer
"""

from collections.abc import Callable

from fastapi import Depends, HTTPException, status

from app.core.dependencies import get_current_user
from app.core.roles import (
    ADMIN,
    CUSTOMER,
    RESTAURANT_OWNER,
    normalize_role,
)
from app.models.restaurant import Restaurant
from app.models.user import User


def require_roles(*allowed_roles: str) -> Callable:
    """Factory: dependency that requires the current user to have one of the allowed roles."""

    normalized_allowed = {normalize_role(r) for r in allowed_roles}

    def _checker(current_user: User = Depends(get_current_user)) -> User:
        role = normalize_role(current_user.role)
        if role not in normalized_allowed:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail=f"Requires role: {', '.join(sorted(normalized_allowed))}",
            )
        return current_user

    return _checker


require_admin = require_roles(ADMIN)
require_restaurant_owner = require_roles(ADMIN, RESTAURANT_OWNER)
require_customer = require_roles(CUSTOMER)
# Customers and owners may leave reviews (owner promoted from customer).
require_reviewer = require_roles(CUSTOMER, RESTAURANT_OWNER)


def assert_restaurant_owner_or_admin(restaurant: Restaurant, user: User) -> None:
    role = normalize_role(user.role)
    if role == ADMIN:
        return
    if role == RESTAURANT_OWNER and restaurant.owner_id == user.id:
        return
    raise HTTPException(
        status_code=status.HTTP_403_FORBIDDEN,
        detail="You do not have permission to modify this restaurant",
    )


def promote_to_restaurant_owner(user: User) -> None:
    """Upgrade customer to restaurant_owner when they create their first restaurant."""
    if normalize_role(user.role) == CUSTOMER:
        user.role = RESTAURANT_OWNER
