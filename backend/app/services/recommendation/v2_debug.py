"""Debug logging helpers for Recommendation Engine V2."""

import logging

from app.schemas.recommendation_v2 import V2DishRecommendationItem

logger = logging.getLogger("popal.recommendations.v2")


def log_pipeline_stage(stage: str, *, user_id: int | None = None, **metrics: object) -> None:
    """Log a recommendation pipeline stage with structured counters."""
    uid = f" user_id={user_id}" if user_id is not None else ""
    parts = " ".join(f"{key}={value}" for key, value in metrics.items())
    logger.info("V2 pipeline stage=%s%s %s", stage, uid, parts)


def log_ranked_recommendations(
    label: str,
    items: list[V2DishRecommendationItem],
    *,
    user_id: int | None = None,
    max_rows: int = 15,
) -> None:
    """Log final or intermediate ranked lists with score breakdown."""
    uid = f" user_id={user_id}" if user_id is not None else ""
    logger.info("V2 %s%s: %d items", label, uid, len(items))
    for rank, item in enumerate(items[:max_rows], start=1):
        bd = item.score_breakdown
        logger.info(
            "V2 %s #%d dish_id=%s dish=%r restaurant=%r score=%.2f "
            "breakdown={content:%.1f collab:%.1f feedback:%.1f pop:%.1f hybrid:%.1f "
            "cuisine:%.1f nutrition:%.1f budget:%.1f} signals=%s",
            label,
            rank,
            item.dish_id,
            item.dish_name,
            item.restaurant_name,
            item.score,
            bd.content_score,
            bd.collaborative_score,
            bd.feedback_score,
            bd.popularity_score,
            bd.hybrid_score,
            bd.cuisine_score,
            bd.nutrition_score,
            bd.budget_score,
            item.signals_used,
        )
    if len(items) > max_rows:
        logger.debug("V2 %s: logged %d of %d items", label, max_rows, len(items))
