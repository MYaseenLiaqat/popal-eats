"""Admin approval workflow for restaurant and home chef business accounts."""

from __future__ import annotations

from sqlalchemy.orm import Session, joinedload

from app.core.account_status import ACTIVE, PENDING, REJECTED, SUSPENDED, normalize_account_status
from app.core.restaurant_constants import APPROVED, PENDING as RESTAURANT_PENDING, REJECTED as RESTAURANT_REJECTED
from app.core.roles import HOME_CHEF, RESTAURANT, is_home_chef_role, is_restaurant_role, normalize_role
from app.models.home_chef_profile import HomeChefProfile
from app.models.restaurant import Restaurant
from app.models.user import User

BUSINESS_ROLES = frozenset({RESTAURANT, HOME_CHEF, "restaurant_owner"})


def is_business_account(user: User) -> bool:
    role = normalize_role(user.role)
    return is_restaurant_role(user.role) or is_home_chef_role(user.role) or role in BUSINESS_ROLES


def get_business_user_or_404(db: Session, user_id: int) -> User:
    user = (
        db.query(User)
        .options(joinedload(User.restaurants), joinedload(User.home_chef_profile))
        .filter(User.id == user_id)
        .first()
    )
    if not user or not is_business_account(user):
        raise ValueError("Business account not found")
    return user


def approve_business_account(db: Session, user: User) -> User:
    if not is_business_account(user):
        raise ValueError("User is not a business account")
    user.account_status = ACTIVE
    user.rejection_reason = None
    if is_restaurant_role(user.role):
        for restaurant in user.restaurants:
            restaurant.approval_status = APPROVED
            restaurant.rejection_reason = None
    if is_home_chef_role(user.role):
        for restaurant in user.restaurants:
            if restaurant.source == "home_chef":
                restaurant.approval_status = APPROVED
                restaurant.rejection_reason = None
    db.commit()
    db.refresh(user)
    return user


def reject_business_account(db: Session, user: User, reason: str | None = None) -> User:
    if not is_business_account(user):
        raise ValueError("User is not a business account")
    message = (reason or "Application rejected by admin").strip()
    user.account_status = REJECTED
    user.rejection_reason = message
    if is_restaurant_role(user.role):
        for restaurant in user.restaurants:
            restaurant.approval_status = RESTAURANT_REJECTED
            restaurant.rejection_reason = message
    if is_home_chef_role(user.role):
        for restaurant in user.restaurants:
            if restaurant.source == "home_chef":
                restaurant.approval_status = RESTAURANT_REJECTED
                restaurant.rejection_reason = message
    db.commit()
    db.refresh(user)
    return user


def suspend_business_account(db: Session, user: User, reason: str | None = None) -> User:
    if not is_business_account(user):
        raise ValueError("User is not a business account")
    user.account_status = SUSPENDED
    if reason:
        user.rejection_reason = reason.strip()
    db.commit()
    db.refresh(user)
    return user


def reactivate_business_account(db: Session, user: User) -> User:
    if not is_business_account(user):
        raise ValueError("User is not a business account")
    current = normalize_account_status(user.account_status)
    if current not in {SUSPENDED, REJECTED}:
        raise ValueError("Only suspended or rejected accounts can be reactivated")
    user.account_status = ACTIVE
    user.rejection_reason = None
    if is_restaurant_role(user.role):
        for restaurant in user.restaurants:
            restaurant.approval_status = APPROVED
            restaurant.rejection_reason = None
    if is_home_chef_role(user.role):
        for restaurant in user.restaurants:
            if restaurant.source == "home_chef":
                restaurant.approval_status = APPROVED
                restaurant.rejection_reason = None
    db.commit()
    db.refresh(user)
    return user


def list_business_accounts(
    db: Session,
    *,
    account_status: str | None = None,
    role: str | None = None,
) -> list[User]:
    query = (
        db.query(User)
        .options(joinedload(User.restaurants), joinedload(User.home_chef_profile))
        .filter(User.role.in_([RESTAURANT, HOME_CHEF, "restaurant_owner"]))
        .order_by(User.created_at.desc())
    )
    if account_status:
        query = query.filter(User.account_status == normalize_account_status(account_status))
    if role:
        normalized = normalize_role(role)
        if normalized == RESTAURANT:
            query = query.filter(User.role.in_([RESTAURANT, "restaurant_owner"]))
        else:
            query = query.filter(User.role == normalized)
    return query.all()


def business_profile_summary(user: User) -> dict:
    """Serialize registration details for admin review."""
    data = {
        "user_id": user.id,
        "role": normalize_role(user.role),
        "account_status": normalize_account_status(user.account_status),
        "full_name": user.full_name,
        "first_name": user.first_name,
        "last_name": user.last_name,
        "email": user.email,
        "phone": user.phone,
        "username": user.username,
        "date_of_birth": user.date_of_birth,
        "created_at": user.created_at,
        "rejection_reason": user.rejection_reason,
    }
    if is_restaurant_role(user.role) and user.restaurants:
        restaurant = user.restaurants[0]
        tags = restaurant.tags or []
        cuisine = tags[0] if tags else None
        data["restaurant"] = {
            "id": restaurant.id,
            "name": restaurant.name,
            "address": restaurant.address,
            "cuisine_type": cuisine,
            "approval_status": restaurant.approval_status,
            "image": restaurant.image,
        }
    if is_home_chef_role(user.role) and user.home_chef_profile:
        chef: HomeChefProfile = user.home_chef_profile
        data["home_chef"] = {
            "display_name": chef.display_name,
            "cuisine_specialty": chef.cuisine_specialty,
            "kitchen_address": chef.kitchen_address,
            "food_license": chef.food_license,
            "profile_image": chef.profile_image,
        }
    return data
