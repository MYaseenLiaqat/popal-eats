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
from app.utils.username import suggest_username_from_email, validate_username


def _allocate_unique_username(db: Session, base: str) -> str:
    try:
        candidate = validate_username(base)
    except ValueError:
        candidate = validate_username("biz_user")

    if not db.query(User).filter(User.username == candidate).first():
        return candidate

    stem = candidate[:26].rstrip("._") or "user"
    for suffix in range(2, 10_000):
        attempt = f"{stem}_{suffix}"[:30]
        try:
            normalized = validate_username(attempt)
        except ValueError:
            continue
        if not db.query(User).filter(User.username == normalized).first():
            return normalized

    raise ValueError("Unable to allocate a unique username. Try a different email.")


def register_user(db: Session, body: UserRegister) -> User:
    email = body.email.lower()
    phone = normalize_phone(body.phone or "")
    role = normalize_role(body.role)

    base_username = body.username or suggest_username_from_email(email)
    username = _allocate_unique_username(db, base_username)

    if db.query(User).filter(User.email == email).first():
        raise ValueError("Email already registered")
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
            description=profile.description.strip() if profile.description else None,
            address=profile.restaurant_address.strip(),
            phone_number=phone,
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
            biography=chef.biography.strip() if chef.biography else None,
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
