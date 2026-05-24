"""
Sentiment analysis abstraction with optional HuggingFace BERT integration.

Set ENABLE_HF_SENTIMENT=true and install transformers+torch to use the real model.
"""

import logging
import re
from dataclasses import dataclass

from app.config import get_settings
from app.services.nlp.cache import nlp_cache

logger = logging.getLogger(__name__)

_POSITIVE = re.compile(r"\b(great|excellent|amazing|love|good|best|delicious|awesome)\b", re.I)
_NEGATIVE = re.compile(r"\b(bad|terrible|awful|hate|worst|poor|disgusting|slow)\b", re.I)


@dataclass
class SentimentResult:
    label: str  # positive | negative | neutral
    score: float  # 0.0 - 1.0 confidence


class SentimentService:
    """Pluggable sentiment backend — heuristic default, BERT optional."""

    def __init__(self) -> None:
        self._settings = get_settings()
        self._hf_pipeline = None

    def _load_hf(self):
        if self._hf_pipeline is not None:
            return self._hf_pipeline
        if not self._settings.enable_hf_sentiment:
            return None
        try:
            from transformers import pipeline  # noqa: PLC0415

            logger.info("Loading HuggingFace model: %s", self._settings.sentiment_model_name)
            self._hf_pipeline = pipeline(
                "sentiment-analysis",
                model=self._settings.sentiment_model_name,
            )
            return self._hf_pipeline
        except ImportError:
            logger.warning("transformers not installed — using heuristic sentiment")
            return None

    def analyze(self, text: str | None) -> SentimentResult | None:
        if not text or not text.strip():
            return None

        cache_key = f"sentiment:{hash(text.strip())}"
        cached = nlp_cache.get(cache_key)
        if cached:
            return cached

        result = self._analyze_impl(text.strip())
        if result:
            nlp_cache.set(cache_key, result)
        return result

    def analyze_batch(self, texts: list[str]) -> list[SentimentResult | None]:
        """Batching hook for future GPU/throughput optimization."""
        return [self.analyze(t) for t in texts]

    def _analyze_impl(self, text: str) -> SentimentResult:
        pipe = self._load_hf()
        if pipe is not None:
            try:
                out = pipe(text[:512])[0]
                label_raw = out.get("label", "NEUTRAL").lower()
                score = float(out.get("score", 0.5))
                if "pos" in label_raw or label_raw.startswith("5") or label_raw.startswith("4"):
                    label = "positive"
                elif "neg" in label_raw or label_raw.startswith("1") or label_raw.startswith("2"):
                    label = "negative"
                else:
                    label = "neutral"
                return SentimentResult(label=label, score=score)
            except Exception as exc:
                logger.warning("HF sentiment failed, fallback heuristic: %s", exc)

        pos = len(_POSITIVE.findall(text))
        neg = len(_NEGATIVE.findall(text))
        if pos > neg:
            return SentimentResult(label="positive", score=min(0.6 + pos * 0.1, 0.95))
        if neg > pos:
            return SentimentResult(label="negative", score=min(0.6 + neg * 0.1, 0.95))
        return SentimentResult(label="neutral", score=0.5)
