"""Infer restaurant cuisine tags from menu composition when primary metadata is missing."""

from __future__ import annotations

from collections import Counter
from dataclasses import asdict, dataclass, field
from typing import Any

from app.models.dish import Dish
from app.services.catalog.tag_normalization import CANONICAL_TAGS, extract_keyword_tags, normalize_tags

# Generic menu tags/categories that rarely describe restaurant cuisine on their own.
INFERENCE_NOISE_TAGS: frozenset[str] = frozenset(
    {
        "beverages",
        "sides",
        "deals",
        "combos",
        "addons",
        "extras",
        "misc",
        "other",
        "popular",
        "new",
    }
)

MIN_TAG_SHARE = 0.08
MAX_INFERRED_TAGS = 5


@dataclass
class CuisineInferenceResult:
    inferred_tags: list[str] = field(default_factory=list)
    confidence: float = 0.0
    tag_scores: dict[str, float] = field(default_factory=dict)

    def to_dict(self) -> dict[str, Any]:
        return asdict(self)


def collect_dish_tag_signals(dish: Dish) -> list[str]:
    """Collect normalized tag signals from a single dish (no restaurant inheritance)."""
    raw_sources: list[str] = []

    if isinstance(dish.tags, list) and dish.tags:
        raw_sources.extend(str(t) for t in dish.tags)

    if dish.category and dish.category.name:
        raw_sources.append(dish.category.name)

    raw_sources.extend(extract_keyword_tags(dish.name, dish.description))

    return normalize_tags(raw_sources)


class RestaurantCuisineInferenceService:
    """Secondary classification layer — dominant cuisines from dish distribution."""

    def infer_from_dishes(self, dishes: list[Dish]) -> CuisineInferenceResult:
        """
        Infer restaurant tags from dish names, categories, and menu composition.

        Each dish contributes at most one count per tag. Confidence is the share of
        the dominant selected tag (0–1).
        """
        if not dishes:
            return CuisineInferenceResult()

        tag_counter: Counter[str] = Counter()
        for dish in dishes:
            for tag in set(collect_dish_tag_signals(dish)):
                tag_counter[tag] += 1

        total_dishes = len(dishes)
        shares = {
            tag: count / total_dishes
            for tag, count in tag_counter.items()
            if tag not in INFERENCE_NOISE_TAGS
        }

        if not shares and tag_counter:
            shares = {tag: count / total_dishes for tag, count in tag_counter.items()}

        ranked = sorted(shares.items(), key=lambda x: (-x[1], x[0]))
        canonical_ranked = [(tag, share) for tag, share in ranked if tag in CANONICAL_TAGS]
        passthrough_ranked = [(tag, share) for tag, share in ranked if tag not in CANONICAL_TAGS]

        selected = [
            (tag, share) for tag, share in canonical_ranked if share >= MIN_TAG_SHARE
        ][:MAX_INFERRED_TAGS]

        if not selected and canonical_ranked:
            selected = [canonical_ranked[0]]

        if not selected and passthrough_ranked:
            selected = [passthrough_ranked[0]]

        if not selected and ranked:
            selected = [ranked[0]]

        inferred_tags = [tag for tag, _ in selected]
        confidence = round(selected[0][1], 2) if selected else 0.0
        tag_scores = {tag: round(share, 3) for tag, share in selected}

        return CuisineInferenceResult(
            inferred_tags=inferred_tags,
            confidence=confidence,
            tag_scores=tag_scores,
        )
