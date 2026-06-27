"""Recommender-system metric helpers (Phase 13 — evaluation only)."""

from __future__ import annotations

import math
from collections.abc import Iterable, Sequence


def precision_at_k(recommended: Sequence[int], relevant: set[int], k: int) -> float:
    if k <= 0:
        return 0.0
    top = recommended[:k]
    if not top:
        return 0.0
    hits = sum(1 for dish_id in top if dish_id in relevant)
    return hits / k


def recall_at_k(recommended: Sequence[int], relevant: set[int], k: int) -> float:
    if not relevant or k <= 0:
        return 0.0
    top = recommended[:k]
    hits = sum(1 for dish_id in top if dish_id in relevant)
    return hits / len(relevant)


def hit_rate(recommended: Sequence[int], relevant: set[int], k: int) -> float:
    if not relevant:
        return 0.0
    top = set(recommended[:k])
    return 1.0 if top & relevant else 0.0


def catalog_coverage(all_recommended: Iterable[Iterable[int]], catalog_size: int) -> float:
    if catalog_size <= 0:
        return 0.0
    unique: set[int] = set()
    for recs in all_recommended:
        unique.update(recs)
    return len(unique) / catalog_size


def intra_list_diversity(cuisine_tags: Sequence[set[str]]) -> float:
    """1 - mean pairwise Jaccard similarity of cuisine tag sets (higher = more diverse)."""
    if len(cuisine_tags) < 2:
        return 1.0
    similarities: list[float] = []
    for i in range(len(cuisine_tags)):
        for j in range(i + 1, len(cuisine_tags)):
            a, b = cuisine_tags[i], cuisine_tags[j]
            if not a and not b:
                similarities.append(1.0)
                continue
            union = a | b
            if not union:
                similarities.append(0.0)
                continue
            similarities.append(len(a & b) / len(union))
    if not similarities:
        return 1.0
    return 1.0 - (sum(similarities) / len(similarities))


def novelty_score(order_count: int, max_order_count: int) -> float:
    """Popularity-based novelty: higher for less popular dishes."""
    if max_order_count <= 0:
        return 1.0
    popularity = (order_count + 1) / (max_order_count + 1)
    return -math.log2(max(popularity, 1e-9))


def percentile(values: Sequence[float], p: float) -> float:
    if not values:
        return 0.0
    sorted_vals = sorted(values)
    idx = min(len(sorted_vals) - 1, max(0, int(math.ceil(p / 100 * len(sorted_vals))) - 1))
    return sorted_vals[idx]


def mean(values: Sequence[float]) -> float:
    return sum(values) / len(values) if values else 0.0
