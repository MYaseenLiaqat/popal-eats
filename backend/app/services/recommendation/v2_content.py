"""
Recommendation Engine V2 — content-based module (Phase 0 stub).

Phase 1 will implement feature extraction and scoring from user preferences
and dish/restaurant attributes.
"""

from sqlalchemy.orm import Session


def get_content_recommendations(db: Session, user_id: int, *, limit: int = 10) -> list:
    """
    Return content-based dish recommendations for a user.

    Phase 0: no scoring logic — returns an empty list.
    """
    _ = db, user_id, limit
    return []
