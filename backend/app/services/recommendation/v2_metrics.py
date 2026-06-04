"""Recommendation Engine V2 — metrics logging (Phase 5.1)."""

from sqlalchemy.orm import Session

from app.models.recommendation_event import RecommendationEvent
from app.schemas.recommendation_v2_metrics import RecommendationEventCreate


def log_recommendation_event(
    db: Session,
    *,
    user_id: int,
    payload: RecommendationEventCreate,
) -> None:
    event = RecommendationEvent(
        user_id=user_id,
        dish_id=payload.dish_id,
        event_type=payload.event_type,
        strategy=payload.strategy,
    )
    db.add(event)
    db.commit()
