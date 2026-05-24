"""Enqueue review processing — RQ with Redis, inline fallback."""

import logging

from app.config import get_settings

logger = logging.getLogger(__name__)


def enqueue_review_processing(review_id: int) -> str:
    """
    Queue review for async processing. Returns job id or 'inline'.
    """
    settings = get_settings()

    if settings.process_reviews_inline:
        from app.workers.tasks import process_review_task  # noqa: PLC0415

        process_review_task(review_id)
        return "inline"

    try:
        from redis import Redis  # noqa: PLC0415
        from rq import Queue, Retry  # noqa: PLC0415

        conn = Redis.from_url(settings.redis_url)
        conn.ping()
        queue = Queue(settings.rq_queue_name, connection=conn)
        job = queue.enqueue(
            "app.workers.tasks.process_review_task",
            review_id,
            job_timeout=300,
            retry=Retry(max=3, interval=[10, 30, 60]),
        )
        logger.info("RQ job enqueued review_id=%s job_id=%s", review_id, job.id)
        return job.id
    except Exception as exc:
        logger.warning("RQ unavailable (%s), processing inline", exc)
        from app.workers.tasks import process_review_task  # noqa: PLC0415

        process_review_task(review_id)
        return "inline-fallback"
