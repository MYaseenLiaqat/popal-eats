"""Home chef business operations — reuses kitchen restaurant for dishes/orders."""

from __future__ import annotations

from sqlalchemy import func
from sqlalchemy.orm import Session, joinedload

from app.core.content_constants import CHEF_POST, RECIPE
from app.core.restaurant_constants import APPROVED, PENDING as RESTAURANT_PENDING
from app.core.roles import is_home_chef_role
from app.models.home_chef_profile import HomeChefProfile
from app.models.post import Post
from app.models.restaurant import Restaurant
from app.models.story import Story, StoryView
from app.models.user import User
from app.services.restaurant_dashboard_service import build_restaurant_dashboard

HOME_CHEF_SOURCE = "home_chef"
CHEF_POST_TYPES = frozenset({CHEF_POST, RECIPE})


def get_home_chef_profile_or_404(db: Session, user: User) -> HomeChefProfile:
    if not is_home_chef_role(user.role):
        raise ValueError("User is not a home chef")
    profile = (
        db.query(HomeChefProfile)
        .options(joinedload(HomeChefProfile.kitchen_restaurant))
        .filter(HomeChefProfile.user_id == user.id)
        .first()
    )
    if not profile:
        raise ValueError("Home chef profile not found")
    return profile


def _create_kitchen_restaurant(db: Session, user: User, profile: HomeChefProfile) -> Restaurant:
    restaurant = Restaurant(
        owner_id=user.id,
        name=profile.display_name,
        address=profile.kitchen_address,
        image=profile.profile_image,
        tags=[profile.cuisine_specialty],
        source=HOME_CHEF_SOURCE,
        approval_status=RESTAURANT_PENDING,
    )
    db.add(restaurant)
    db.flush()
    profile.kitchen_restaurant_id = restaurant.id
    db.add(profile)
    db.commit()
    db.refresh(restaurant)
    return restaurant


def get_kitchen_restaurant(db: Session, user: User) -> Restaurant:
    profile = get_home_chef_profile_or_404(db, user)
    if profile.kitchen_restaurant_id:
        restaurant = db.query(Restaurant).filter(Restaurant.id == profile.kitchen_restaurant_id).first()
        if restaurant:
            return restaurant
    return _create_kitchen_restaurant(db, user, profile)


def build_home_chef_dashboard(db: Session, user: User) -> dict:
    kitchen = get_kitchen_restaurant(db, user)
    dashboard = build_restaurant_dashboard(db, kitchen).model_dump()
    story_views = (
        db.query(func.count(StoryView.id))
        .join(Story, Story.id == StoryView.story_id)
        .filter(Story.user_id == user.id)
        .scalar()
        or 0
    )
    dashboard["story_views"] = int(story_views)
    dashboard["kitchen_restaurant_id"] = kitchen.id
    return dashboard


def list_home_chef_posts(db: Session, user: User, *, page: int = 1, limit: int = 20) -> tuple[list[Post], int]:
    query = (
        db.query(Post)
        .filter(Post.author_id == user.id, Post.post_type.in_(CHEF_POST_TYPES))
        .order_by(Post.created_at.desc())
    )
    total = query.count()
    items = query.offset((page - 1) * limit).limit(limit).all()
    return items, total


def sync_kitchen_from_profile(db: Session, profile: HomeChefProfile) -> None:
    if not profile.kitchen_restaurant_id:
        return
    restaurant = db.query(Restaurant).filter(Restaurant.id == profile.kitchen_restaurant_id).first()
    if not restaurant:
        return
    restaurant.name = profile.display_name
    restaurant.address = profile.kitchen_address
    restaurant.image = profile.profile_image
    restaurant.tags = [profile.cuisine_specialty]
    db.add(restaurant)
