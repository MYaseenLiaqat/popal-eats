"""Generate lightweight restaurant feed posts and stories (first 10 restaurants)."""

from __future__ import annotations

import random
from dataclasses import dataclass, field
from datetime import datetime, timedelta, timezone

from sqlalchemy import func
from sqlalchemy.orm import Session

from app.core.restaurant_constants import APPROVED
from app.models.dish import Dish
from app.models.post import Post
from app.models.restaurant import Restaurant
from app.models.story import Story

from .progress import log_progress

FYP_MARKER = "fyp_seed_v1"
_SOCIAL_RESTAURANT_LIMIT = 10

POST_TEMPLATES: list[tuple[str, str, str]] = [
    ("announcement", "Freshly Cooked", "Hot & fresh {dish} straight from our kitchen. Order now on Popal Eats."),
    ("new_dish", "Chef Special", "Our chefs recommend {dish} — a house favourite you have to try."),
    ("announcement", "Customer Favourite", "{dish} is one of our most ordered items — see why Lahore loves it."),
]


@dataclass
class SocialStats:
    posts_created: int = 0
    stories_created: int = 0
    restaurants_processed: int = 0
    restaurants_skipped: int = 0
    target_restaurant_ids: list[int] = field(default_factory=list)


def _now() -> datetime:
    return datetime.now(timezone.utc)


def _marker(text: str) -> str:
    return f"{text}\n<!-- {FYP_MARKER} -->"


def _dishes_with_images(db: Session, restaurant_id: int, limit: int = 5) -> list[Dish]:
    return (
        db.query(Dish)
        .filter(
            Dish.restaurant_id == restaurant_id,
            Dish.image.isnot(None),
            Dish.image != "",
        )
        .order_by(Dish.price.desc())
        .limit(limit)
        .all()
    )


def _has_feed_post(db: Session, restaurant_id: int) -> bool:
    return (
        db.query(func.count(Post.id))
        .filter(
            Post.restaurant_id == restaurant_id,
            Post.post_type == "restaurant_post",
        )
        .scalar()
        or 0
    ) > 0


def _has_story(db: Session, owner_id: int) -> bool:
    return (
        db.query(func.count(Story.id))
        .filter(Story.user_id == owner_id)
        .scalar()
        or 0
    ) > 0


def generate_social_content(
    db: Session,
    *,
    restaurant_limit: int = _SOCIAL_RESTAURANT_LIMIT,
    seed: int = 42,
) -> SocialStats:
    random.seed(seed)
    stats = SocialStats()

    restaurants = (
        db.query(Restaurant)
        .filter(Restaurant.approval_status == APPROVED)
        .order_by(Restaurant.average_rating.desc())
        .limit(restaurant_limit)
        .all()
    )

    for restaurant in restaurants:
        stats.restaurants_processed += 1
        stats.target_restaurant_ids.append(restaurant.id)

        has_post = _has_feed_post(db, restaurant.id)
        has_story = _has_story(db, restaurant.owner_id)
        if has_post and has_story:
            stats.restaurants_skipped += 1
            continue

        dishes = _dishes_with_images(db, restaurant.id)
        if not dishes:
            stats.restaurants_skipped += 1
            continue

        dish = dishes[0]

        if not has_post:
            subtype, title, template = random.choice(POST_TEMPLATES)
            db.add(
                Post(
                    author_id=restaurant.owner_id,
                    post_type="restaurant_post",
                    restaurant_id=restaurant.id,
                    dish_id=dish.id,
                    restaurant_content_subtype=subtype,
                    title=title,
                    caption=_marker(template.format(dish=dish.name, restaurant=restaurant.name)),
                    images=[dish.image],
                    created_at=_now() - timedelta(hours=random.randint(2, 72)),
                )
            )
            stats.posts_created += 1

        if not has_story:
            db.add(
                Story(
                    user_id=restaurant.owner_id,
                    image_url=dish.image,
                    expires_at=_now() + timedelta(hours=random.randint(6, 22)),
                    created_at=_now() - timedelta(hours=random.randint(1, 12)),
                )
            )
            stats.stories_created += 1

    db.commit()
    log_progress("Social content", stats.restaurants_processed, len(restaurants))

    return stats
