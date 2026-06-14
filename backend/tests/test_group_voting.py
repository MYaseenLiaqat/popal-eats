"""Tests for group voting and consensus calculations."""

import pytest
from pydantic import ValidationError

from app.models.group_vote import DISLIKE, LIKE, LOVE
from app.schemas.group_voting import GroupVoteCreate
from app.services.group_recommendation.consensus import (
    compute_consensus_score,
    compute_final_score,
    count_positive_voters,
    should_mark_agreed,
    summarize_votes,
)


def test_compute_consensus_all_love():
    votes = [LOVE, LOVE, LOVE, LOVE]
    assert compute_consensus_score(votes, member_count=4) == 100.0


def test_compute_consensus_all_dislike():
    votes = [DISLIKE, DISLIKE, DISLIKE, DISLIKE]
    assert compute_consensus_score(votes, member_count=4) == 0.0


def test_compute_consensus_mixed_votes():
    votes = [LIKE, LOVE, DISLIKE, LIKE]
    score = compute_consensus_score(votes, member_count=4)
    assert 0.0 < score < 100.0


def test_compute_final_score_weighted():
    assert compute_final_score(80.0, 100.0) == round(80 * 0.70 + 100 * 0.30, 2)


def test_should_mark_agreed_at_sixty_percent():
    assert should_mark_agreed(positive_voters=3, member_count=4) is True
    assert should_mark_agreed(positive_voters=2, member_count=4) is False


def test_count_positive_voters():
    votes = [LIKE, LOVE, DISLIKE, LIKE]
    assert count_positive_voters(votes) == 3


def test_summarize_votes():
    summary = summarize_votes([LIKE, LOVE, DISLIKE, LIKE])
    assert summary == {"likes": 2, "loves": 1, "dislikes": 1, "total_votes": 4}


def test_vote_create_schema_normalizes_type():
    payload = GroupVoteCreate(vote_type="love")
    assert payload.vote_type == LOVE

    with pytest.raises(ValidationError):
        GroupVoteCreate(vote_type="MAYBE")


def test_recommendation_ranking_by_final_score():
    rows = [
        {"recommendation_id": 1, "final_score": 75.0},
        {"recommendation_id": 2, "final_score": 91.0},
        {"recommendation_id": 3, "final_score": 88.0},
    ]
    ranked = sorted(rows, key=lambda row: (-row["final_score"], row["recommendation_id"]))
    assert [row["recommendation_id"] for row in ranked] == [2, 3, 1]
