"""Process-level TTL cache for eligible dish ORM rows (read-only scoring)."""

from __future__ import annotations

import threading
import time

from sqlalchemy.orm import Session, object_session

_CACHE_TTL_SECONDS = 120
_lock = threading.Lock()
_cache_expires_at: float = 0.0
_cached_dishes: list | None = None


def get_cached_eligible_dishes(db: Session, *, user_id: int | None = None) -> list:
    """Return detached eligible dishes; rebuilds pool when cache expires."""
    global _cache_expires_at, _cached_dishes

    now = time.monotonic()
    with _lock:
        if _cached_dishes is not None and now < _cache_expires_at:
            return list(_cached_dishes)

    from app.services.recommendation.v2_candidates import _load_eligible_dishes_uncached

    dishes = _load_eligible_dishes_uncached(db, user_id=user_id)
    for dish in dishes:
        for obj in (dish, dish.restaurant, dish.category):
            if obj is not None and object_session(obj) is db:
                db.expunge(obj)

    with _lock:
        _cached_dishes = dishes
        _cache_expires_at = now + _CACHE_TTL_SECONDS

    return list(dishes)


def invalidate_eligible_dish_pool_cache() -> None:
    global _cache_expires_at, _cached_dishes
    with _lock:
        _cache_expires_at = 0.0
        _cached_dishes = None
