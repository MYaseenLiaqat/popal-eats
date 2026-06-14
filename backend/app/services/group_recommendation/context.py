"""Batch loading of group session context for recommendations."""

from __future__ import annotations

from dataclasses import dataclass, field
from datetime import datetime, timedelta, timezone
from decimal import Decimal

from sqlalchemy.orm import Session

from app.models.group_member_location import GroupMemberLocation
from app.models.group_session import GroupSession
from app.models.group_session_member import GroupSessionMember
from app.models.user_preference import UserPreference
from app.services.user_preferences_service import infer_budget_level

LOCATION_STALE_MINUTES = 30


@dataclass
class MemberPreferenceContext:
    user_id: int
    favorite_cuisines: list[str] = field(default_factory=list)
    dietary_preferences: list[str] = field(default_factory=list)
    allergies: list[str] = field(default_factory=list)
    disliked_categories: list[str] = field(default_factory=list)
    budget_level: str | None = None
    budget_min: Decimal | None = None
    budget_max: Decimal | None = None

    def as_scoring_dict(self) -> dict:
        return {
            "favorite_cuisines": self.favorite_cuisines,
            "dietary": set(self.dietary_preferences),
            "allergies": set(self.allergies),
            "disliked_categories": self.disliked_categories,
            "budget_level": self.budget_level,
        }


@dataclass
class GroupRecommendationContext:
    session: GroupSession
    members: list[MemberPreferenceContext]
    active_locations: list[tuple[float, float]]
    group_allergies: set[str] = field(default_factory=set)
    group_dietary: set[str] = field(default_factory=set)

    @property
    def member_count(self) -> int:
        return len(self.members)

    @property
    def member_scoring_dicts(self) -> list[dict]:
        return [member.as_scoring_dict() for member in self.members]


def _normalize_list(raw) -> list[str]:
    if not raw or not isinstance(raw, list):
        return []
    return [str(item).strip().lower() for item in raw if item and str(item).strip()]


def _utcnow() -> datetime:
    return datetime.now(timezone.utc)


def load_group_context(db: Session, session: GroupSession) -> GroupRecommendationContext:
    """Batch-load member preferences and fresh locations for a session."""
    member_rows = (
        db.query(GroupSessionMember.user_id)
        .filter(GroupSessionMember.session_id == session.id)
        .all()
    )
    member_ids = [row.user_id for row in member_rows]

    prefs_by_user: dict[int, UserPreference] = {}
    if member_ids:
        for pref in db.query(UserPreference).filter(UserPreference.user_id.in_(member_ids)).all():
            prefs_by_user[pref.user_id] = pref

    members: list[MemberPreferenceContext] = []
    group_allergies: set[str] = set()
    group_dietary: set[str] = set()

    for user_id in member_ids:
        pref = prefs_by_user.get(user_id)
        dietary = _normalize_list(pref.dietary_preferences if pref else None)
        if pref and pref.dietary_preference and not dietary:
            dietary = [str(pref.dietary_preference).strip().lower()]
        allergies = _normalize_list(pref.allergies if pref else None)
        member = MemberPreferenceContext(
            user_id=user_id,
            favorite_cuisines=_normalize_list(pref.favorite_cuisines if pref else None),
            dietary_preferences=dietary,
            allergies=allergies,
            disliked_categories=_normalize_list(pref.disliked_categories if pref else None),
            budget_level=infer_budget_level(
                pref.budget_min if pref else None,
                pref.budget_max if pref else None,
                pref.budget_level if pref else None,
            ),
            budget_min=pref.budget_min if pref else None,
            budget_max=pref.budget_max if pref else None,
        )
        members.append(member)
        group_allergies.update(allergies)
        group_dietary.update(dietary)

    cutoff = _utcnow() - timedelta(minutes=LOCATION_STALE_MINUTES)
    location_rows = (
        db.query(GroupMemberLocation)
        .filter(
            GroupMemberLocation.session_id == session.id,
            GroupMemberLocation.updated_at >= cutoff,
        )
        .all()
    )
    active_locations = [(float(row.latitude), float(row.longitude)) for row in location_rows]

    return GroupRecommendationContext(
        session=session,
        members=members,
        active_locations=active_locations,
        group_allergies=group_allergies,
        group_dietary=group_dietary,
    )
