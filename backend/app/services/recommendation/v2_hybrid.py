"""
Recommendation Engine V2 — hybrid fusion module.

Phase 1: ``content`` and ``hybrid`` delegate to content-based engine.
Collaborative filtering arrives in Phase 2.
"""

from typing import Literal

from sqlalchemy.orm import Session

from app.schemas.recommendation_v2 import V2DishRecommendationItem
from app.services.recommendation.v2_content import get_content_recommendations

Strategy = Literal["content", "collaborative", "hybrid"]


def get_v2_recommendations(
    db: Session,
    user_id: int,
    *,
    strategy: Strategy = "content",
    limit: int = 10,
) -> list[V2DishRecommendationItem]:
    if strategy in ("content", "hybrid"):
        return get_content_recommendations(db, user_id, limit=limit)
    # collaborative — Phase 2
    return []
