"""
Review processing pipeline — detect → translate → sentiment → persist.

Called by RQ worker or inline fallback.
"""

import logging
from datetime import datetime, timezone

from sqlalchemy.orm import Session

from app.models.review import Review
from app.services.nlp.sentiment_service import SentimentService
from app.services.review_processing.language_detection import detect_language
from app.services.review_processing.translation import translate_text

logger = logging.getLogger(__name__)
_sentiment = SentimentService()


def process_review(db: Session, review_id: int) -> Review | None:
    """
    Full pipeline for one review. Safe to retry — idempotent writes.
    """
    review = db.query(Review).filter(Review.id == review_id).first()
    if not review:
        logger.error("Review %s not found for processing", review_id)
        return None

    review.processing_status = "processing"
    review.processing_error = None
    db.commit()

    try:
        comment = review.comment
        lang = detect_language(comment)
        review.detected_language = lang

        translated = None
        if comment and lang and lang not in ("en",):
            translated = translate_text(comment, lang)
            review.translated_text = translated

        analysis_text = translated or comment
        sentiment = _sentiment.analyze(analysis_text)
        if sentiment:
            review.sentiment = sentiment.label
            review.sentiment_score = sentiment.score

        review.processing_status = "completed"
        review.processed_at = datetime.now(timezone.utc)
        review.processing_error = None
        db.commit()
        db.refresh(review)
        logger.info(
            "Review %s processed lang=%s sentiment=%s",
            review_id,
            lang,
            review.sentiment,
        )
        return review
    except Exception as exc:
        logger.exception("Review processing failed review_id=%s", review_id)
        db.rollback()
        review = db.query(Review).filter(Review.id == review_id).first()
        if review:
            review.processing_status = "failed"
            review.processing_error = str(exc)[:2000]
            db.commit()
        raise
