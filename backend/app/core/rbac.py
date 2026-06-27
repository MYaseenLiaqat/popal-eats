"""
Role-based access control dependencies.

Roles: admin, customer, restaurant, home_chef (restaurant_owner is legacy alias).
"""

from collections.abc import Callable

from fastapi import Depends, HTTPException, status

from app.core.account_status import ACTIVE, normalize_account_status
from app.core.dependencies import get_current_user
from app.core.roles import (
    ADMIN,
    CUSTOMER,
    HOME_CHEF,
    RESTAURANT,
    RESTAURANT_OWNER,
    is_home_chef_role,
    is_restaurant_role,
    normalize_role,
)
from app.models.restaurant import Restaurant
from app.models.user import User

_BLOCKED_API_STATUSES = frozenset({"suspended"})


def assert_active_business_account(user: User) -> None:
    """Restaurant and home chef owners must be ACTIVE for business operations."""
    if normalize_role(user.role) == ADMIN:
        return
    if not (is_restaurant_role(user.role) or is_home_chef_role(user.role)):
        return
    status_value = normalize_account_status(user.account_status)
    if status_value == ACTIVE:
        return
    if status_value == "pending":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Your business account is pending admin approval.",
        )
    if status_value == "rejected":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail=user.rejection_reason or "Your business application was rejected.",
        )
    if status_value == "suspended":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Your business account has been suspended.",
        )
    raise HTTPException(
        status_code=status.HTTP_403_FORBIDDEN,
        detail=f"Account is {status_value}.",
    )


def _assert_account_active(user: User) -> None:
    status_value = normalize_account_status(user.account_status)
    if status_value in _BLOCKED_API_STATUSES:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail=f"Account is {status_value}.",
        )


def require_roles(*allowed_roles: str) -> Callable:
    """Factory: dependency that requires the current user to have one of the allowed roles."""

    normalized_allowed = {normalize_role(r) for r in allowed_roles}
    # Legacy restaurant_owner maps to restaurant.
    if RESTAURANT in normalized_allowed:
        normalized_allowed.add(RESTAURANT_OWNER)

    def _checker(current_user: User = Depends(get_current_user)) -> User:
        _assert_account_active(current_user)
        role = normalize_role(current_user.role)
        if role not in normalized_allowed and not (
            RESTAURANT in normalized_allowed and is_restaurant_role(current_user.role)
        ):
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail=f"Requires role: {', '.join(sorted(normalized_allowed))}",
            )
        return current_user

    return _checker


require_admin = require_roles(ADMIN)
require_customer = require_roles(CUSTOMER)
require_restaurant = require_roles(ADMIN, RESTAURANT)
require_restaurant_owner = require_restaurant  # backward-compatible alias
require_home_chef = require_roles(ADMIN, HOME_CHEF)
require_reviewer = require_roles(CUSTOMER, RESTAURANT, RESTAURANT_OWNER)


def assert_restaurant_owner_or_admin(restaurant: Restaurant, user: User) -> None:
    role = normalize_role(user.role)
    if role == ADMIN:
        return
    assert_active_business_account(user)
    if is_restaurant_role(user.role) and restaurant.owner_id == user.id:
        return
    raise HTTPException(
        status_code=status.HTTP_403_FORBIDDEN,
        detail="You do not have permission to modify this restaurant",
    )


def promote_to_restaurant_owner(user: User) -> None:
    """Upgrade customer to restaurant when they create their first restaurant."""
    if normalize_role(user.role) == CUSTOMER:
        user.role = RESTAURANT


# Spec-aligned aliases for route dependencies (Phase 12A).
RequireAdmin = require_admin
RequireCustomer = require_customer
RequireRestaurant = require_restaurant
RequireHomeChef = require_home_chef
