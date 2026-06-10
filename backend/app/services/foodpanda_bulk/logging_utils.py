"""Structured logging for Foodpanda bulk import jobs."""

from __future__ import annotations

import json
import logging
from datetime import datetime, timezone
from typing import Any

logger = logging.getLogger("foodpanda.bulk")


def _utc_now() -> str:
    return datetime.now(timezone.utc).isoformat()


def log_event(event: str, **fields: Any) -> None:
    """Emit a structured JSON log line for bulk import operations."""
    payload = {"event": event, "timestamp": _utc_now(), **fields}
    logger.info(json.dumps(payload, default=str, ensure_ascii=False))


def log_metrics(run_id: str, metrics: dict[str, Any]) -> None:
    log_event("METRICS", run_id=run_id, **metrics)
