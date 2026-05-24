"""
ReviewProcessingService — facade for queue + worker pipeline.

Flow: create review → enqueue_analysis() → worker process_next_review()
"""

import logging

from sqlalchemy.orm import Session

from app.database import SessionLocal
from app.models.review import Review
from app.services.review_processing.processor import process_review
from app.services.review_processing.queue import enqueue_review_processing

logger = logging.getLogger(__name__)


class ReviewProcessingService:
    """Orchestrates async review AI pipeline (RQ or inline fallback)."""

    def enqueue_analysis(self, review_id: int, comment: str | None = None) -> str:
        """
        Queue review for background processing after create/update.
        Returns RQ job id, 'inline', or 'inline-fallback'.
        """
        logger.info(
            "Enqueue review analysis review_id=%s has_comment=%s",
            review_id,
            bool(comment),
        )
        return enqueue_review_processing(review_id)

    def process_next_review(self, review_id: int, db: Session | None = None) -> Review | None:
        """
        Run full pipeline for one review (worker entrypoint).

        Detect language → translate → sentiment → persist to reviews table.
        """
        own_session = db is None
        session = db or SessionLocal()
        try:
            return process_review(session, review_id)
        finally:
            if own_session:
                session.close()


# Singleton used by routes
review_processing_service = ReviewProcessingService()
