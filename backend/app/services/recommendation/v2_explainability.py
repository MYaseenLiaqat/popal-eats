"""Explainable AI layer for Recommendation Engine V2 — metadata only, no scoring changes."""

from __future__ import annotations

import re
from dataclasses import dataclass

from app.schemas.recommendation_v2 import (
    V2DishRecommendationItem,
    V2ScoreBreakdown,
    V2SignalContribution,
)
from app.schemas.user_preference import RecommendationPreferences
from app.services.recommendation.v2_fusion import (
    COLLABORATIVE_FUSION_WEIGHT,
    CONTENT_FUSION_WEIGHT,
    FEEDBACK_FUSION_WEIGHT,
    POPULARITY_FUSION_WEIGHT,
)

_MAX_BULLETS = 5
_MIN_BULLETS = 3
_MATCHED_CUISINE_RE = re.compile(r"Matched\s+(.+?)\s+cuisine", re.IGNORECASE)
_LEARNED_PREF_RE = re.compile(r"Learned preference:\s*(.+?)(?:\s*\(|\.|$)", re.IGNORECASE)


@dataclass(frozen=True)
class _RankedReason:
    key: str
    points: float
    bullet: str
    priority: int = 0


def confidence_percent_from_score(score: float) -> int:
    """Map pipeline score (0–100, or 0–10 legacy) to match percentage."""
    if score <= 10:
        return int(round(max(0.0, min(100.0, score * 10))))
    return int(round(max(0.0, min(100.0, score))))


def _title_cuisine(value: str) -> str:
    return value.replace("_", " ").replace("-", " ").strip().title()


def _matched_cuisine_label(explanation: str, prefs: RecommendationPreferences) -> str | None:
    match = _MATCHED_CUISINE_RE.search(explanation or "")
    if match:
        return _title_cuisine(match.group(1))
    if prefs.favorite_cuisines:
        return _title_cuisine(prefs.favorite_cuisines[0])
    return None


def _content_weight(strategy: str) -> float:
    return CONTENT_FUSION_WEIGHT if strategy == "hybrid" else 1.0


def _collaborative_weight(strategy: str) -> float:
    return COLLABORATIVE_FUSION_WEIGHT if strategy == "hybrid" else 1.0


def _feedback_weight(strategy: str) -> float:
    return FEEDBACK_FUSION_WEIGHT if strategy == "hybrid" else 0.0


def _popularity_fusion_weight(strategy: str) -> float:
    return POPULARITY_FUSION_WEIGHT if strategy == "hybrid" else 0.0


def _raw_popularity_points(bd: V2ScoreBreakdown) -> float:
    if bd.popularity_score <= 10:
        return bd.popularity_score
    return bd.popularity_score / 10.0


def _compute_ranked_reasons(
    item: V2DishRecommendationItem,
    prefs: RecommendationPreferences,
    *,
    strategy: str,
) -> list[_RankedReason]:
    bd = item.score_breakdown
    cw = _content_weight(strategy)
    reasons: list[_RankedReason] = []

    cuisine_pts = bd.cuisine_score * cw
    if cuisine_pts > 0:
        label = _matched_cuisine_label(item.explanation, prefs)
        if label:
            bullet = f"Matches your {label} cuisine preference"
        elif prefs.favorite_cuisines:
            bullet = "Matches your selected cuisine preferences"
        else:
            bullet = "Matches your selected cuisine preferences"
        reasons.append(_RankedReason("cuisine", cuisine_pts, bullet))

    nutrition_pts = bd.nutrition_score * cw
    if nutrition_pts > 0:
        goal = (prefs.nutrition_goal or "").replace("_", " ").strip()
        if goal in {"", "maintain", "balanced", "general"}:
            bullet = "Supports your nutrition preference"
        else:
            bullet = f"Supports your {goal} nutrition preference"
        reasons.append(_RankedReason("nutrition", nutrition_pts, bullet))

    budget_pts = bd.budget_score * cw
    if budget_pts > 0:
        reasons.append(
            _RankedReason("budget", budget_pts, "Fits your preferred budget")
        )

    pop_raw = _raw_popularity_points(bd)
    pop_content_pts = pop_raw * cw
    if pop_content_pts >= 0.5:
        reasons.append(
            _RankedReason(
                "popularity",
                pop_content_pts,
                "Highly rated restaurant" if pop_raw >= 4 else "Popular in your city",
            )
        )

    collab_pts = bd.collaborative_score * _collaborative_weight(strategy)
    if collab_pts >= 1.0 or "collaborative" in item.signals_used:
        if strategy == "collaborative" or collab_pts >= 5.0:
            bullet = "Similar to dishes you previously ordered"
        else:
            bullet = "Frequently ordered by similar users"
        reasons.append(_RankedReason("collaborative", max(collab_pts, 1.0), bullet))

    feedback_pts = bd.feedback_score * _feedback_weight(strategy)
    if feedback_pts >= 1.0 or (
        strategy == "hybrid" and "feedback" in item.signals_used and bd.feedback_score > 0
    ):
        learned = _LEARNED_PREF_RE.search(item.explanation or "")
        if learned:
            bullet = f"Similar to {learned.group(1).strip()} dishes you engage with"
        else:
            bullet = "Similar to dishes you recently viewed"
        reasons.append(_RankedReason("feedback", max(feedback_pts, 1.0), bullet))

    pop_fusion_pts = 0.0
    if strategy == "hybrid" and bd.popularity_score > 10:
        pop_fusion_pts = bd.popularity_score * _popularity_fusion_weight(strategy)
        if pop_fusion_pts >= 1.0:
            reasons.append(
                _RankedReason(
                    "popularity_fusion",
                    pop_fusion_pts,
                    "Popular among similar users",
                )
            )

    if prefs.allergies:
        reasons.append(
            _RankedReason(
                "allergy_safe",
                0.0,
                "Safe for your selected allergies",
                priority=90,
            )
        )

    if not reasons:
        if pop_raw > 0 or "popularity" in item.signals_used:
            reasons.append(
                _RankedReason("trending", 1.0, "Popular in your city")
            )
        elif prefs.favorite_cuisines:
            reasons.append(
                _RankedReason(
                    "cuisine_cold",
                    0.5,
                    "Matches your selected cuisine preferences",
                )
            )
        else:
            reasons.append(_RankedReason("trending", 0.5, "Trending this week"))

    return reasons


def _build_contributions(
    item: V2DishRecommendationItem,
    *,
    strategy: str,
) -> list[V2SignalContribution]:
    bd = item.score_breakdown
    cw = _content_weight(strategy)
    out: list[V2SignalContribution] = []

    def add(signal: str, label: str, points: float) -> None:
        if points > 0:
            out.append(
                V2SignalContribution(signal=signal, label=label, points=round(points, 1))
            )

    add("cuisine", "Cuisine", bd.cuisine_score * cw)
    add("nutrition", "Nutrition", bd.nutrition_score * cw)
    add("budget", "Budget", bd.budget_score * cw)
    add("popularity", "Popularity", _raw_popularity_points(bd) * cw)
    add("collaborative", "Collaborative", bd.collaborative_score * _collaborative_weight(strategy))
    add("feedback", "Feedback", bd.feedback_score * _feedback_weight(strategy))

    if strategy == "hybrid" and bd.popularity_score > 10:
        add(
            "popularity_fusion",
            "Popularity",
            bd.popularity_score * _popularity_fusion_weight(strategy),
        )

    if strategy == "hybrid" and bd.hybrid_score > 0:
        add("final", "Final", bd.hybrid_score)
    elif item.score > 0:
        add("final", "Final", item.score)

    return out


def build_explanation_bullets(
    item: V2DishRecommendationItem,
    prefs: RecommendationPreferences,
    *,
    strategy: str,
) -> list[str]:
    """Top 3–5 consumer bullets ordered by signal contribution."""
    ranked = _compute_ranked_reasons(item, prefs, strategy=strategy)
    ranked.sort(key=lambda r: (-r.priority, -r.points, r.key))

    bullets: list[str] = []
    seen: set[str] = set()
    for reason in ranked:
        if reason.bullet in seen:
            continue
        bullets.append(reason.bullet)
        seen.add(reason.bullet)
        if len(bullets) >= _MAX_BULLETS:
            break

    while len(bullets) < _MIN_BULLETS and len(bullets) < len(ranked):
        for reason in ranked:
            if reason.bullet not in bullets:
                bullets.append(reason.bullet)
            if len(bullets) >= _MIN_BULLETS:
                break

    return bullets[:_MAX_BULLETS]


def enrich_recommendation_item(
    item: V2DishRecommendationItem,
    prefs: RecommendationPreferences,
    *,
    strategy: str,
) -> V2DishRecommendationItem:
    """Attach explainability metadata without changing score or ranking."""
    bullets = build_explanation_bullets(item, prefs, strategy=strategy)
    contributions = _build_contributions(item, strategy=strategy)
    confidence = confidence_percent_from_score(item.score)

    return item.model_copy(
        update={
            "confidence_percent": confidence,
            "explanation_bullets": bullets,
            "contributions": contributions,
        }
    )


def enrich_recommendation_items(
    items: list[V2DishRecommendationItem],
    prefs: RecommendationPreferences,
    *,
    strategy: str,
) -> list[V2DishRecommendationItem]:
    """Enrich a ranked list in place order — no re-scoring or re-sorting."""
    return [enrich_recommendation_item(item, prefs, strategy=strategy) for item in items]
