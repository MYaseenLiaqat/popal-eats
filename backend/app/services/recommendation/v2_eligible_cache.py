"""TTL cache for eligible dish primary keys (avoids repeated full-catalog scans)."""

from __future__ import annotations

import threading
import time

from types import SimpleNamespace

from sqlalchemy.orm import Session
import logging

from app.core.restaurant_constants import APPROVED
from app.models.dish import Dish
from app.models.restaurant import Restaurant
from app.services.recommendation.market_filter import is_lahore_market_restaurant
from app.services.recommendation.v2_placeholders import is_placeholder_name
_CACHE_TTL_SECONDS = 120
_lock = threading.Lock()
_cache_expires_at: float = 0.0
_cached_ids: list[int] | None = None


def _compute_eligible_ids(db: Session) -> list[int]:
    rows = (
        db.query(
            Dish.id,
            Dish.name,
            Restaurant.name,
            Restaurant.city,
            Restaurant.source,
            Restaurant.is_open,
            Restaurant.approval_status,
        )
        .join(Restaurant, Dish.restaurant_id == Restaurant.id)
        .filter(Dish.is_available.is_(True))
        .filter(Restaurant.is_open.is_(True))
        .filter(Restaurant.approval_status == APPROVED)
        .all()
    )

    eligible: list[int] = []
    for dish_id, dish_name, restaurant_name, city, source, is_open, approval_status in rows:
        if is_placeholder_name(dish_name, entity="dish"):
            continue
        if is_placeholder_name(restaurant_name, entity="restaurant"):
            continue
        restaurant = SimpleNamespace(city=city, source=source)
        if not is_lahore_market_restaurant(restaurant):
            continue
        eligible.append(dish_id)
    return eligible


def get_eligible_dish_ids(db: Session) -> list[int]:
    global _cache_expires_at, _cached_ids

    now = time.monotonic()
    with _lock:
        if _cached_ids is not None and now < _cache_expires_at:
            return list(_cached_ids)

    ids = _compute_eligible_ids(db)
    with _lock:
        _cached_ids = ids
        _cache_expires_at = now + _CACHE_TTL_SECONDS
    return list(ids)


def invalidate_eligible_dish_cache() -> None:
    global _cache_expires_at, _cached_ids
    with _lock:
        _cache_expires_at = 0.0
        _cached_ids = None
