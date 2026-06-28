"""User registration orchestration for role-based signup."""

from __future__ import annotations

from sqlalchemy.orm import Session

from app.core.account_status import ACTIVE, PENDING, normalize_account_status
from app.core.restaurant_constants import PENDING as RESTAURANT_PENDING
from app.core.roles import CUSTOMER, HOME_CHEF, RESTAURANT, normalize_role
from app.core.security import hash_password
from app.models.home_chef_profile import HomeChefProfile
from app.models.restaurant import Restaurant
from app.models.user import User
from app.schemas.user import UserRegister
from app.utils.phone import normalize_phone


def register_user(db: Session, body: UserRegister) -> User:
    email = body.email.lower()
    username = body.username.strip().lower()
    phone = normalize_phone(body.phone)
    role = normalize_role(body.role)

    if db.query(User).filter(User.email == email).first():
        raise ValueError("Email already registered")
    if db.query(User).filter(User.username == username).first():
        raise ValueError("Username is already taken")
    if db.query(User).filter(User.phone == phone).first():
        raise ValueError("Phone number is already registered")

    account_status = ACTIVE if role == CUSTOMER else PENDING

    user = User(
        full_name=body.resolved_full_name,
        first_name=body.first_name,
        last_name=body.last_name,
        username=username,
        email=email,
        password_hash=hash_password(body.password),
        phone=phone,
        date_of_birth=body.date_of_birth,
        city=body.city,
        role=role,
        account_status=account_status,
        email_verified=False,
    )
    db.add(user)
    db.flush()

    if role == RESTAURANT and body.restaurant_profile:
        profile = body.restaurant_profile
        tags = [profile.cuisine_type.strip()]
        if profile.business_registration_number:
            tags.append(f"reg:{profile.business_registration_number.strip()}")

        restaurant = Restaurant(
            owner_id=user.id,
            name=profile.restaurant_name.strip(),
            address=profile.restaurant_address.strip(),
            image=profile.cover_image_url or profile.logo_url,
            tags=tags,
            approval_status=RESTAURANT_PENDING,
        )
        db.add(restaurant)

    if role == HOME_CHEF and body.home_chef_profile:
        chef = body.home_chef_profile
        profile = HomeChefProfile(
            user_id=user.id,
            display_name=chef.chef_display_name.strip(),
            cuisine_specialty=chef.cuisine_specialty.strip(),
            kitchen_address=chef.kitchen_address.strip(),
            food_license=chef.food_license.strip() if chef.food_license else None,
            profile_image=chef.profile_image_url,
        )
        db.add(profile)
        db.flush()

        kitchen = Restaurant(
            owner_id=user.id,
            name=chef.chef_display_name.strip(),
            address=chef.kitchen_address.strip(),
            image=chef.profile_image_url,
            tags=[chef.cuisine_specialty.strip()],
            source="home_chef",
            approval_status=RESTAURANT_PENDING,
        )
        db.add(kitchen)
        db.flush()
        profile.kitchen_restaurant_id = kitchen.id
        db.add(profile)

        if chef.profile_image_url:
            user.profile_image = chef.profile_image_url

    db.commit()
    db.refresh(user)
    return user


def login_status_message(user: User) -> str | None:
    status = normalize_account_status(user.account_status)
    if status == PENDING:
        if normalize_role(user.role) == RESTAURANT:
            return "Your restaurant account is pending admin approval."
        if normalize_role(user.role) == HOME_CHEF:
            return "Your home chef account is pending admin approval."
    return None
