"""
Recommendation Engine V2 — hybrid fusion module (Phase 0 stub).

Phase 3 will combine content, collaborative, popularity, and sentiment signals.
"""

from typing import Literal

from sqlalchemy.orm import Session

from app.services.recommendation.v2_content import get_content_recommendations

Strategy = Literal["content", "collaborative", "hybrid"]


def get_v2_recommendations(
    db: Session,
    user_id: int,
    *,
    strategy: Strategy = "content",
    limit: int = 10,
) -> list:
    """
    Entry point for V2 recommendations by strategy.

    Phase 0: only ``content`` is recognized; returns an empty list.
    Other strategies are reserved for later phases.
    """
    if strategy == "content":
        return get_content_recommendations(db, user_id, limit=limit)
    # collaborative / hybrid — Phase 2–3
    _ = db, user_id, limit
    return []
