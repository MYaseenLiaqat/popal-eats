"""
Recommendation Engine V2 — weighted hybrid fusion (Phase 5.4).

final_score =
    content_score × 0.45
  + collaborative_score × 0.25
  + feedback_score × 0.15
  + popularity_score × 0.15
"""

CONTENT_FUSION_WEIGHT = 0.45
COLLABORATIVE_FUSION_WEIGHT = 0.25
FEEDBACK_FUSION_WEIGHT = 0.15
POPULARITY_FUSION_WEIGHT = 0.15

FUSION_EXPLANATION_HEADER = (
    "Hybrid Fusion:\n"
    "Content (45%)\n"
    "Collaborative (25%)\n"
    "Feedback (15%)\n"
    "Popularity (15%)"
)


def compute_hybrid_score(
    content_score: float,
    collaborative_score: float,
    feedback_score: float,
    popularity_score: float,
) -> float:
    """
    Weighted fusion of four signals (each expected on a 0–100 scale).

    Result is rounded to 2 decimals and clamped to [0, 100].
    """
    raw = (
        content_score * CONTENT_FUSION_WEIGHT
        + collaborative_score * COLLABORATIVE_FUSION_WEIGHT
        + feedback_score * FEEDBACK_FUSION_WEIGHT
        + popularity_score * POPULARITY_FUSION_WEIGHT
    )
    return max(0.0, min(100.0, round(raw, 2)))


def normalize_feedback_for_fusion(feedback_bonus: float) -> float:
    """Map Phase 5.3 bonus (0–15) to a 0–100 fusion input."""
    if feedback_bonus <= 0:
        return 0.0
    return min(100.0, round((feedback_bonus / 15.0) * 100.0, 2))


def normalize_popularity_for_fusion(popularity_score: float) -> float:
    """Map content popularity component (0–10) to a 0–100 fusion input."""
    return min(100.0, round(max(0.0, popularity_score) * 10.0, 2))


def build_fusion_explanation(*, feedback_detail: str | None = None, detail: str | None = None) -> str:
    """Consumer-friendly explanation — no fusion/weight jargon."""
    parts: list[str] = []
    if detail and not _is_technical_explanation(detail):
        parts.append(detail.strip())
    if feedback_detail:
        parts.append(feedback_detail.strip())
    if parts:
        return " ".join(parts)
    return "Recommended based on your taste and what's popular nearby."


def _is_technical_explanation(text: str) -> bool:
    lower = text.lower()
    blocked = (
        "hybrid",
        "fusion",
        "collaborative",
        "content (",
        "feedback (",
        "popularity (",
        "co-occurrence",
        "signals",
    )
    return any(term in lower for term in blocked)
