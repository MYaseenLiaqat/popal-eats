"""Pure consensus and ranking calculations for group voting."""

from __future__ import annotations

import math

from app.models.group_vote import DISLIKE, LIKE, LOVE

VOTE_WEIGHTS: dict[str, int] = {
    LIKE: 1,
    LOVE: 2,
    DISLIKE: -1,
}

RECOMMENDATION_WEIGHT = 0.70
CONSENSUS_WEIGHT = 0.30
AGREEMENT_THRESHOLD = 0.60


def compute_weighted_vote_sum(vote_types: list[str]) -> int:
    return sum(VOTE_WEIGHTS.get(vote_type, 0) for vote_type in vote_types)


def compute_consensus_score(vote_types: list[str], member_count: int) -> float:
    """
    Normalize weighted votes to 0–100.

    All LOVE → 100, all DISLIKE → 0 (for a given member_count).
    """
    if member_count <= 0:
        return 0.0

    weighted = compute_weighted_vote_sum(vote_types)
    max_weighted = member_count * VOTE_WEIGHTS[LOVE]
    min_weighted = member_count * VOTE_WEIGHTS[DISLIKE]
    span = max_weighted - min_weighted
    if span <= 0:
        return 50.0

    normalized = ((weighted - min_weighted) / span) * 100.0
    return round(max(0.0, min(100.0, normalized)), 2)


def compute_final_score(recommendation_score: float, consensus_score: float) -> float:
    final = (recommendation_score * RECOMMENDATION_WEIGHT) + (consensus_score * CONSENSUS_WEIGHT)
    return round(max(0.0, min(100.0, final)), 2)


def count_positive_voters(vote_types: list[str]) -> int:
    return sum(1 for vote_type in vote_types if vote_type in {LIKE, LOVE})


def should_mark_agreed(positive_voters: int, member_count: int) -> bool:
    if member_count <= 0:
        return False
    required = math.ceil(AGREEMENT_THRESHOLD * member_count)
    return positive_voters >= required


def summarize_votes(vote_types: list[str]) -> dict[str, int]:
    likes = sum(1 for vote in vote_types if vote == LIKE)
    loves = sum(1 for vote in vote_types if vote == LOVE)
    dislikes = sum(1 for vote in vote_types if vote == DISLIKE)
    return {
        "likes": likes,
        "loves": loves,
        "dislikes": dislikes,
        "total_votes": len(vote_types),
    }
