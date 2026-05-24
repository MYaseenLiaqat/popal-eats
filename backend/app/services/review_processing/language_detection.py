"""Language detection: English, Urdu, Roman Urdu."""

import logging
import re

logger = logging.getLogger(__name__)

URDU_SCRIPT = re.compile(r"[\u0600-\u06FF]")
ROMAN_URDU_MARKERS = re.compile(
    r"\b(yeh|woh|kya|hai|nahi|acha|bohat|khana|zyada|masla|shukriya|bhai)\b",
    re.I,
)


def detect_language(text: str | None) -> str | None:
    """
    Returns: en | ur | roman_urdu | unknown
    """
    if not text or not text.strip():
        return None

    stripped = text.strip()

    if URDU_SCRIPT.search(stripped):
        logger.debug("Detected Urdu script")
        return "ur"

    if ROMAN_URDU_MARKERS.search(stripped):
        logger.debug("Detected Roman Urdu markers")
        return "roman_urdu"

    try:
        import langdetect  # noqa: PLC0415

        code = langdetect.detect(stripped)
        if code == "ur":
            return "ur"
        if code in ("en", "so"):  # sometimes roman urdu maps oddly
            if ROMAN_URDU_MARKERS.search(stripped):
                return "roman_urdu"
            return "en"
        return code
    except Exception as exc:
        logger.debug("langdetect fallback: %s", exc)
        return "en"
