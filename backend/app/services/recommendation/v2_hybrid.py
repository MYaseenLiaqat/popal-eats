"""
Recommendation Engine V2 — strategy router.

- content / hybrid → Phase 1 content engine (unchanged)
- collaborative → Phase 2 item-based CF from order history
"""

from typing import Literal

from sqlalchemy.orm import Session

from app.schemas.recommendation_v2 import V2DishRecommendationItem
from app.services.recommendation.v2_collaborative import get_collaborative_recommendations
from app.services.recommendation.v2_content import get_content_recommendations

Strategy = Literal["content", "collaborative", "hybrid"]


def get_v2_recommendations(
    db: Session,
    user_id: int,
    *,
    strategy: Strategy = "content",
    limit: int = 10,
) -> list[V2DishRecommendationItem]:
    if strategy == "collaborative":
        return get_collaborative_recommendations(db, user_id, limit=limit)
    if strategy in ("content", "hybrid"):
        return get_content_recommendations(db, user_id, limit=limit)
    return []
