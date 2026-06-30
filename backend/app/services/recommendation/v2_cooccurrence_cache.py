"""TTL cache for order-item co-occurrence data (read-only, no scoring changes)."""

from __future__ import annotations

import threading
import time
from collections import defaultdict

from sqlalchemy.orm import Session

from app.models.order_item import OrderItem

_CACHE_TTL_SECONDS = 300
_lock = threading.Lock()
_cache_expires_at: float = 0.0
_order_dishes: dict[int, set[int]] | None = None
_cooccurrence: dict[int, dict[int, int]] | None = None
_dish_order_counts: dict[int, int] | None = None


def _build_order_dish_sets(db: Session) -> dict[int, set[int]]:
    order_dishes: dict[int, set[int]] = defaultdict(set)
    for order_id, dish_id in db.query(OrderItem.order_id, OrderItem.dish_id).all():
        order_dishes[order_id].add(dish_id)
    return order_dishes


def _build_cooccurrence_from_sets(
    order_dishes: dict[int, set[int]],
) -> dict[int, dict[int, int]]:
    cooccurrence: dict[int, dict[int, int]] = defaultdict(lambda: defaultdict(int))
    for dishes in order_dishes.values():
        dish_list = sorted(dishes)
        for i, dish_a in enumerate(dish_list):
            for dish_b in dish_list[i + 1 :]:
                cooccurrence[dish_a][dish_b] += 1
                cooccurrence[dish_b][dish_a] += 1
    return cooccurrence


def _build_dish_order_counts(order_dishes: dict[int, set[int]]) -> dict[int, int]:
    counts: dict[int, int] = defaultdict(int)
    for dishes in order_dishes.values():
        for dish_id in dishes:
            counts[dish_id] += 1
    return counts


def get_cooccurrence_bundle(
    db: Session,
) -> tuple[dict[int, set[int]], dict[int, dict[int, int]], dict[int, int]]:
    """Return cached (order_dishes, cooccurrence, dish_order_counts)."""
    global _cache_expires_at, _order_dishes, _cooccurrence, _dish_order_counts

    now = time.monotonic()
    with _lock:
        if (
            _order_dishes is not None
            and _cooccurrence is not None
            and _dish_order_counts is not None
            and now < _cache_expires_at
        ):
            return _order_dishes, _cooccurrence, _dish_order_counts

    order_dishes = _build_order_dish_sets(db)
    cooccurrence = _build_cooccurrence_from_sets(order_dishes)
    dish_counts = _build_dish_order_counts(order_dishes)

    with _lock:
        _order_dishes = order_dishes
        _cooccurrence = cooccurrence
        _dish_order_counts = dish_counts
        _cache_expires_at = now + _CACHE_TTL_SECONDS

    return order_dishes, cooccurrence, dish_counts


def invalidate_cooccurrence_cache() -> None:
    """Clear cache after new orders (optional hook)."""
    global _cache_expires_at, _order_dishes, _cooccurrence, _dish_order_counts
    with _lock:
        _cache_expires_at = 0.0
        _order_dishes = None
        _cooccurrence = None
        _dish_order_counts = None
