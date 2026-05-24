"""RQ worker tasks — run: .\\scripts\\run_worker.ps1"""

import logging

from app.database import SessionLocal
from app.services.review_processing import ReviewProcessingService

logger = logging.getLogger(__name__)
_service = ReviewProcessingService()


def process_review_task(review_id: int) -> dict:
    """RQ entrypoint with retries — delegates to process_next_review()."""
    logger.info("Worker started review_id=%s", review_id)
    db = SessionLocal()
    try:
        review = _service.process_next_review(review_id, db=db)
        if not review:
            logger.error("Worker review not found review_id=%s", review_id)
            return {"ok": False, "review_id": review_id, "error": "not_found"}
        logger.info(
            "Worker completed review_id=%s status=%s lang=%s sentiment=%s",
            review_id,
            review.processing_status,
            review.detected_language,
            review.sentiment,
        )
        return {
            "ok": True,
            "review_id": review_id,
            "language": review.detected_language,
            "sentiment": review.sentiment,
            "sentiment_score": review.sentiment_score,
            "status": review.processing_status,
        }
    finally:
        db.close()


# Alias expected by some worker configurations
process_next_review = process_review_task
