#!/usr/bin/env python
"""Seed demo accounts and social content for FYP presentation.

Creates stable demo users, friendship, posts, stories, and restaurant announcements.
Idempotent — safe to re-run (skips existing demo emails).

Usage:
  cd backend && python scripts/seed_demo_content.py
  python scripts/seed_demo_content.py --reset-posts   # delete prior demo posts first
"""

from __future__ import annotations

import argparse
import sys
from datetime import datetime, timedelta, timezone
from pathlib import Path

_backend = Path(__file__).resolve().parent.parent
if str(_backend) not in sys.path:
    sys.path.insert(0, str(_backend))

from sqlalchemy.orm import Session

from app.core.restaurant_constants import APPROVED
from app.core.roles import ADMIN, CUSTOMER, RESTAURANT_OWNER
from app.core.security import hash_password
from app.database import SessionLocal
from app.models.dish import Dish
from app.models.friend_request import FriendRequest
from app.models.friendship import Friendship
from app.models.post import Post
from app.models.restaurant import Restaurant
from app.models.story import Story
from app.models.user import User

DEMO_PASSWORD = "Demo1234!"

DEMO_USERS = [
    {
        "email": "demo.host@example.com",
        "full_name": "Demo Host",
        "username": "demohost",
        "role": CUSTOMER,
    },
    {
        "email": "demo.friend@example.com",
        "full_name": "Demo Friend",
        "username": "demofriend",
        "role": CUSTOMER,
    },
    {
        "email": "demo.owner@example.com",
        "full_name": "Demo Owner",
        "username": "demoowner",
        "role": RESTAURANT_OWNER,
    },
    {
        "email": "demo.admin@example.com",
        "full_name": "Demo Admin",
        "username": "demoadmin",
        "role": ADMIN,
    },
]

FOOD_POSTS = [
    ("Late-night biryani run 🍚", "Best decision after group voting session."),
    ("Karahi with fresh naan — unbeatable combo.", None),
    ("Found this gem near Johar Town. Highly recommend!", None),
    ("Weekend cheat meal done right.", "Tag your lunch squad."),
    ("Smoky BBQ platter — sharing is caring.", None),
]

RECIPES = [
    {
        "title": "Quick Chicken Tikka Bowls",
        "caption": "Weeknight-friendly Lahore classic.",
        "description": "Marinated chicken with charred edges and fresh salad.",
        "ingredients": ["500g chicken", "yogurt", "tikka masala", "onion", "lemon"],
        "steps": ["Marinate 30 min", "Grill until charred", "Serve over rice with salad"],
    },
    {
        "title": "Daal Chawal for Two",
        "caption": "Comfort food in under 40 minutes.",
        "description": "Minimal ingredients, maximum flavor.",
        "ingredients": ["masoor daal", "rice", "turmeric", "cumin", "garlic"],
        "steps": ["Boil daal with spices", "Temper with garlic", "Serve with steamed rice"],
    },
    {
        "title": "Street-Style Bun Kabab",
        "caption": "Crispy patty, chutney, soft bun.",
        "description": "A Lahore street food favorite at home.",
        "ingredients": ["beef patty", "egg", "bun", "imli chutney", "onion"],
        "steps": ["Fry patty", "Toast bun", "Assemble with chutney"],
    },
]

RESTAURANT_ANNOUNCEMENTS = [
    ("promotion", "Weekend Special", "20% off on all combos this Friday–Sunday!"),
    ("new_dish", "New on the menu", "Try our loaded fries — now available for delivery."),
    ("announcement", "Extended hours", "We're open until 2 AM during Ramadan season."),
]


def _now() -> datetime:
    return datetime.now(timezone.utc)


def _get_or_create_user(db: Session, spec: dict) -> User:
    email = spec["email"].lower()
    username = spec.get("username")
    user = db.query(User).filter(User.email == email).first()
    if user is None and username:
        user = db.query(User).filter(User.username == username).first()
    if user:
        user.full_name = spec["full_name"]
        user.email = email
        user.username = username
        user.role = spec["role"]
        user.onboarding_completed = True
        if not user.password_hash:
            user.password_hash = hash_password(DEMO_PASSWORD)
        else:
            user.password_hash = hash_password(DEMO_PASSWORD)
        return user

    user = User(
        full_name=spec["full_name"],
        email=email,
        username=spec.get("username"),
        password_hash=hash_password(DEMO_PASSWORD),
        role=spec["role"],
        city="Lahore",
        onboarding_completed=True,
        bio=f"Popal Eats demo account — {spec['full_name']}",
    )
    db.add(user)
    db.flush()
    return user


def _ensure_friendship(db: Session, a: User, b: User) -> None:
    pair = sorted([a.id, b.id])
    existing = (
        db.query(Friendship)
        .filter(Friendship.user_id == pair[0], Friendship.friend_id == pair[1])
        .first()
    )
    if existing:
        return

    db.add(Friendship(user_id=a.id, friend_id=b.id))
    db.add(Friendship(user_id=b.id, friend_id=a.id))

    pending = (
        db.query(FriendRequest)
        .filter(
            FriendRequest.sender_id == a.id,
            FriendRequest.receiver_id == b.id,
            FriendRequest.status == "pending",
        )
        .first()
    )
    if pending is None:
        db.add(
            FriendRequest(
                sender_id=a.id,
                receiver_id=b.id,
                status="accepted",
            )
        )


def _sample_dish_images(db: Session, limit: int = 12) -> list[str]:
    rows = (
        db.query(Dish.image)
        .filter(Dish.image.isnot(None), Dish.image != "")
        .limit(limit * 3)
        .all()
    )
    urls = [r[0] for r in rows if r[0]]
    return urls[:limit]


def _sample_restaurant(db: Session) -> Restaurant | None:
    return (
        db.query(Restaurant)
        .filter(Restaurant.approval_status == APPROVED, Restaurant.source == "foodpanda")
        .order_by(Restaurant.average_rating.desc())
        .first()
    )


def _sample_dish(db: Session, restaurant_id: int | None) -> Dish | None:
    q = db.query(Dish).filter(Dish.image.isnot(None))
    if restaurant_id:
        q = q.filter(Dish.restaurant_id == restaurant_id)
    return q.first()


def _delete_demo_posts(db: Session, user_ids: list[int]) -> int:
    deleted = (
        db.query(Post)
        .filter(Post.author_id.in_(user_ids))
        .delete(synchronize_session=False)
    )
    db.query(Story).filter(Story.user_id.in_(user_ids)).delete(synchronize_session=False)
    return deleted


def seed(db: Session, *, reset_posts: bool = False) -> dict:
    users = {spec["email"]: _get_or_create_user(db, spec) for spec in DEMO_USERS}
    host = users["demo.host@example.com"]
    friend = users["demo.friend@example.com"]
    owner = users["demo.owner@example.com"]

    _ensure_friendship(db, host, friend)
    db.flush()

    user_ids = [u.id for u in users.values()]
    if reset_posts:
        _delete_demo_posts(db, user_ids)

    images = _sample_dish_images(db)
    if not images:
        images = ["/uploads/dishes/placeholder.jpg"]

    restaurant = _sample_restaurant(db)
    dish = _sample_dish(db, restaurant.id if restaurant else None)

    stats = {"users": len(users), "food_posts": 0, "recipes": 0, "stories": 0, "restaurant_posts": 0}

    existing_food = (
        db.query(Post)
        .filter(Post.author_id == host.id, Post.post_type == "food_post")
        .count()
    )
    if existing_food == 0:
        for i, (caption, extra) in enumerate(FOOD_POSTS):
            text = caption if extra is None else f"{caption} {extra}"
            db.add(
                Post(
                    author_id=host.id if i % 2 == 0 else friend.id,
                    post_type="food_post",
                    caption=text,
                    images=[images[i % len(images)]],
                    restaurant_id=restaurant.id if restaurant and i == 0 else None,
                    dish_id=dish.id if dish and i == 1 else None,
                )
            )
            stats["food_posts"] += 1

    existing_recipes = db.query(Post).filter(Post.post_type == "recipe").count()
    if existing_recipes < len(RECIPES):
        for i, recipe in enumerate(RECIPES):
            if db.query(Post).filter(Post.title == recipe["title"]).first():
                continue
            db.add(
                Post(
                    author_id=host.id,
                    post_type="recipe",
                    title=recipe["title"],
                    caption=recipe["caption"],
                    recipe_description=recipe["description"],
                    recipe_ingredients=recipe["ingredients"],
                    recipe_steps=recipe["steps"],
                    images=[images[(i + 2) % len(images)]],
                )
            )
            stats["recipes"] += 1

    existing_stories = db.query(Story).filter(Story.user_id.in_([host.id, friend.id])).count()
    if existing_stories < 4:
        expires = _now() + timedelta(hours=20)
        for i, user in enumerate([host, friend, host, friend]):
            db.add(
                Story(
                    user_id=user.id,
                    image_url=images[(i + 3) % len(images)],
                    expires_at=expires,
                )
            )
            stats["stories"] += 1

    if restaurant:
        owner_restaurant = (
            db.query(Restaurant)
            .filter(Restaurant.owner_id == owner.id)
            .first()
        )
        if owner_restaurant is None:
            owner_restaurant = restaurant
            owner_restaurant.owner_id = owner.id

        existing_rp = (
            db.query(Post)
            .filter(Post.post_type == "restaurant_post", Post.restaurant_id == owner_restaurant.id)
            .count()
        )
        if existing_rp == 0:
            for subtype, title, caption in RESTAURANT_ANNOUNCEMENTS:
                db.add(
                    Post(
                        author_id=owner.id,
                        post_type="restaurant_post",
                        restaurant_id=owner_restaurant.id,
                        restaurant_content_subtype=subtype,
                        title=title,
                        caption=caption,
                        images=[images[0]],
                    )
                )
                stats["restaurant_posts"] += 1

    db.commit()
    return stats


def main() -> int:
    parser = argparse.ArgumentParser(description="Seed demo accounts and social content")
    parser.add_argument("--reset-posts", action="store_true", help="Delete demo users' posts/stories first")
    args = parser.parse_args()

    db = SessionLocal()
    try:
        stats = seed(db, reset_posts=args.reset_posts)
    finally:
        db.close()

    print("=" * 60)
    print("DEMO CONTENT SEEDED")
    print("=" * 60)
    print(f"Demo password (all accounts): {DEMO_PASSWORD}")
    print()
    for spec in DEMO_USERS:
        print(f"  {spec['role']:18} {spec['email']}")
    print()
    print("Created this run:")
    for key, val in stats.items():
        if key != "users":
            print(f"  {key}: {val}")
    print("=" * 60)
    return 0


if __name__ == "__main__":
    sys.exit(main())
