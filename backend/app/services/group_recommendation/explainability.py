"""Explainability metadata for group recommendations — no scoring changes."""

from __future__ import annotations

from dataclasses import dataclass

from app.services.group_recommendation.context import GroupRecommendationContext

_MAX_BULLETS = 5


@dataclass(frozen=True)
class GroupScoreSignals:
    cuisine_score: float
    agreement_score: float
    distance_score: float
    budget_score: float
    popularity_score: float
    nutrition_score: float
    order_similarity_score: float
    matching_members: int
    total_members: int
    cuisine_member_matches: int
    cuisine_label: str | None = None


def group_match_percent(score: float) -> int:
    return int(round(max(0.0, min(100.0, score))))


def _title_cuisine(value: str) -> str:
    return value.replace("_", " ").replace("-", " ").strip().title()


def build_group_explanation_bullets(
    signals: GroupScoreSignals,
    context: GroupRecommendationContext,
) -> list[str]:
    ranked: list[tuple[float, str]] = []

    if signals.cuisine_member_matches > 0 and signals.total_members > 0:
        label = _title_cuisine(signals.cuisine_label) if signals.cuisine_label else "group"
        if signals.cuisine_member_matches == signals.total_members:
            ranked.append(
                (
                    signals.cuisine_score,
                    f"Matches {label} cuisine preferences of all members",
                )
            )
        else:
            ranked.append(
                (
                    signals.cuisine_score,
                    f"Matches {label} cuisine preferences of "
                    f"{signals.cuisine_member_matches} members",
                )
            )

    if signals.budget_score >= 70:
        ranked.append((signals.budget_score, "Fits everyone's budget"))
    elif signals.budget_score >= 50:
        ranked.append((signals.budget_score, "Works within the group's budget range"))

    if context.group_allergies:
        ranked.append((95.0, "Safe for all selected allergies"))

    if signals.nutrition_score >= 50:
        ranked.append((signals.nutrition_score, "Supports group nutrition preferences"))

    if signals.order_similarity_score >= 50:
        ranked.append(
            (
                signals.order_similarity_score,
                "Similar to restaurants previously ordered by the group",
            )
        )
    elif signals.order_similarity_score >= 25:
        ranked.append(
            (
                signals.order_similarity_score,
                "Related to dishes your group has explored before",
            )
        )

    if signals.distance_score >= 70:
        ranked.append((signals.distance_score, "Highly rated nearby"))
    elif signals.distance_score >= 50:
        ranked.append((signals.distance_score, "Popular nearby"))

    if signals.agreement_score >= 60 and signals.matching_members > 0:
        if signals.matching_members == signals.total_members:
            ranked.append((signals.agreement_score, "Works for everyone in your group"))
        else:
            ranked.append(
                (
                    signals.agreement_score,
                    f"Works for {signals.matching_members} of {signals.total_members} friends",
                )
            )

    if signals.popularity_score >= 60:
        ranked.append((signals.popularity_score, "Highly rated restaurant"))

    ranked.sort(key=lambda row: (-row[0], row[1]))
    bullets: list[str] = []
    seen: set[str] = set()
    for _, bullet in ranked:
        if bullet in seen:
            continue
        bullets.append(bullet)
        seen.add(bullet)
        if len(bullets) >= _MAX_BULLETS:
            break

    if not bullets:
        if context.group_cuisines:
            top = _title_cuisine(context.group_cuisines[0])
            bullets.append(f"Balanced pick for your group's {top} fans")
        else:
            bullets.append("A solid pick for the group")

    return bullets[:_MAX_BULLETS]
