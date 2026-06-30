"""Restaurant field enrichment — cuisine tags, images, hours, delivery info."""

from __future__ import annotations

import random
import re
from collections import Counter
from dataclasses import dataclass, field
from datetime import time

from sqlalchemy import func
from sqlalchemy.orm import Session

from app.core.restaurant_constants import APPROVED
from app.models.dish import Dish
from app.models.restaurant import Restaurant
from app.models.review import Review

from .placeholders import is_bad_text
from .progress import log_progress

_DELIVERY_TIMES = ["25–35 min", "30–40 min", "35–45 min", "40–50 min"]
_BATCH = 50

_CUISINE_KEYWORDS: list[tuple[re.Pattern[str], str]] = [
    (re.compile(r"biryani|karahi|desi|handi", re.I), "pakistani"),
    (re.compile(r"pizza|pasta|burger", re.I), "fast food"),
    (re.compile(r"shawarma|broast|zinger", re.I), "fast food"),
    (re.compile(r"chinese|noodle|manchurian", re.I), "chinese"),
    (re.compile(r"sushi|ramen", re.I), "japanese"),
    (re.compile(r"bbq|grill|steak", re.I), "bbq"),
    (re.compile(r"ice cream|dessert|cake", re.I), "desserts"),
    (re.compile(r"coffee|latte|espresso", re.I), "cafe"),
]


@dataclass
class RestaurantEnrichmentStats:
    restaurants_processed: int = 0
    restaurants_skipped: int = 0
    restaurants_updated: int = 0
    images_linked: int = 0
    tags_filled: int = 0
    descriptions_filled: int = 0
    errors: list[str] = field(default_factory=list)


def _infer_cuisine_from_dishes(dishes: list[Dish]) -> list[str]:
    counter: Counter[str] = Counter()
    for dish in dishes[:40]:
        if dish.cuisine:
            counter[str(dish.cuisine).lower()] += 2
        if dish.tags:
            for t in dish.tags:
                counter[str(t).lower()] += 1
        blob = f"{dish.name} {dish.description or ''}"
        for pattern, label in _CUISINE_KEYWORDS:
            if pattern.search(blob):
                counter[label] += 1
    if not counter:
        return ["multi-cuisine"]
    return [tag for tag, _ in counter.most_common(4)]


def _build_description(restaurant: Restaurant, cuisine: str, delivery: str) -> str:
    rating = restaurant.average_rating or 4.2
    reviews = restaurant.total_reviews or random.randint(12, 240)
    return (
        f"{restaurant.name} — {cuisine.title()} dining in Lahore. "
        f"Rated {rating:.1f}★ from {reviews} reviews. "
        f"Delivery {delivery}. Open daily for lunch and dinner."
    )[:2000]


def _needs_enrichment(restaurant: Restaurant) -> bool:
    if not restaurant.tags or len(restaurant.tags) == 0:
        return True
    if not restaurant.city or is_bad_text(restaurant.city):
        return True
    if not restaurant.address or is_bad_text(restaurant.address):
        return True
    if restaurant.opening_time is None or restaurant.closing_time is None:
        return True
    if restaurant.average_rating is None or restaurant.average_rating <= 0:
        return True
    if restaurant.total_reviews is None or restaurant.total_reviews <= 0:
        return True
    desc = restaurant.description or ""
    if is_bad_text(desc) or "Delivery" not in desc:
        return True
    if not restaurant.image or not str(restaurant.image).strip():
        return True
    return False


def enrich_restaurants(db: Session, *, seed: int = 42) -> RestaurantEnrichmentStats:
    random.seed(seed)
    stats = RestaurantEnrichmentStats()

    total = (
        db.query(func.count(Restaurant.id))
        .filter(Restaurant.approval_status == APPROVED)
        .scalar()
        or 0
    )
    last_id = 0

    while True:
        batch = (
            db.query(Restaurant)
            .filter(Restaurant.approval_status == APPROVED, Restaurant.id > last_id)
            .order_by(Restaurant.id)
            .limit(_BATCH)
            .all()
        )
        if not batch:
            break

        for restaurant in batch:
            stats.restaurants_processed += 1
            last_id = restaurant.id

            if not _needs_enrichment(restaurant):
                stats.restaurants_skipped += 1
                continue

            dishes = (
                db.query(Dish)
                .filter(Dish.restaurant_id == restaurant.id)
                .limit(50)
                .all()
            )
            changed = False
            delivery = random.choice(_DELIVERY_TIMES)

            if not restaurant.tags or len(restaurant.tags) == 0:
                restaurant.tags = _infer_cuisine_from_dishes(dishes)
                stats.tags_filled += 1
                changed = True

            if not restaurant.city or is_bad_text(restaurant.city):
                restaurant.city = "Lahore"
                changed = True

            if not restaurant.address or is_bad_text(restaurant.address):
                area = (restaurant.tags or ["Lahore"])[0]
                restaurant.address = f"{restaurant.name}, {str(area).title()}, Lahore"[:300]
                changed = True

            if restaurant.opening_time is None:
                restaurant.opening_time = time(10, 0)
                changed = True
            if restaurant.closing_time is None:
                restaurant.closing_time = time(23, 30)
                changed = True

            if restaurant.average_rating is None or restaurant.average_rating <= 0:
                review_count = (
                    db.query(func.count(Review.id))
                    .filter(Review.restaurant_id == restaurant.id)
                    .scalar()
                    or 0
                )
                if review_count == 0:
                    restaurant.average_rating = round(random.uniform(3.8, 4.8), 1)
                    changed = True
            if restaurant.total_reviews is None or restaurant.total_reviews <= 0:
                review_count = (
                    db.query(func.count(Review.id))
                    .filter(Review.restaurant_id == restaurant.id)
                    .scalar()
                    or 0
                )
                if review_count == 0:
                    restaurant.total_reviews = random.randint(15, 320)
                    changed = True

            cuisine_label = ", ".join((restaurant.tags or ["multi-cuisine"])[:2])
            desc = restaurant.description or ""
            if is_bad_text(desc) or "Delivery" not in desc:
                restaurant.description = _build_description(restaurant, cuisine_label, delivery)
                stats.descriptions_filled += 1
                changed = True

            if not restaurant.image or not str(restaurant.image).strip():
                img = (
                    db.query(Dish.image)
                    .filter(
                        Dish.restaurant_id == restaurant.id,
                        Dish.image.isnot(None),
                        Dish.image != "",
                    )
                    .limit(1)
                    .scalar()
                )
                if img:
                    restaurant.image = img
                    stats.images_linked += 1
                    changed = True

            if changed:
                stats.restaurants_updated += 1

        db.commit()
        log_progress("Restaurants", stats.restaurants_processed, total)

    return stats
