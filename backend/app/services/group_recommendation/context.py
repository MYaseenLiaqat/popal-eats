"""Batch loading of group session context for recommendations."""

from __future__ import annotations

from dataclasses import dataclass, field
from datetime import datetime, timedelta, timezone
from decimal import Decimal

from sqlalchemy.orm import Session

from app.models.group_member_location import GroupMemberLocation
from app.models.group_session import GroupSession
from app.models.group_session_member import GroupSessionMember
from app.models.order import Order
from app.models.order_item import OrderItem
from app.models.recommendation_event import RecommendationEvent
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
    nutrition_goal: str | None = None
    budget_level: str | None = None
    budget_min: Decimal | None = None
    budget_max: Decimal | None = None
    ordered_dish_ids: set[int] = field(default_factory=set)
    ordered_restaurant_ids: set[int] = field(default_factory=set)
    viewed_dish_ids: set[int] = field(default_factory=set)
    feedback_dish_ids: set[int] = field(default_factory=set)

    def as_scoring_dict(self) -> dict:
        return {
            "favorite_cuisines": self.favorite_cuisines,
            "dietary": set(self.dietary_preferences),
            "allergies": set(self.allergies),
            "disliked_categories": self.disliked_categories,
            "nutrition_goal": self.nutrition_goal,
            "budget_level": self.budget_level,
            "ordered_dish_ids": self.ordered_dish_ids,
            "ordered_restaurant_ids": self.ordered_restaurant_ids,
            "viewed_dish_ids": self.viewed_dish_ids,
            "feedback_dish_ids": self.feedback_dish_ids,
        }


@dataclass
class GroupRecommendationContext:
    session: GroupSession
    members: list[MemberPreferenceContext]
    active_locations: list[tuple[float, float]]
    group_allergies: set[str] = field(default_factory=set)
    group_dietary: set[str] = field(default_factory=set)
    group_cuisines: list[str] = field(default_factory=list)

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


def _load_member_order_history(
    db: Session, member_ids: list[int]
) -> dict[int, tuple[set[int], set[int]]]:
    if not member_ids:
        return {}
    out: dict[int, tuple[set[int], set[int]]] = {
        uid: (set(), set()) for uid in member_ids
    }
    rows = (
        db.query(Order.user_id, Order.restaurant_id, OrderItem.dish_id)
        .join(OrderItem, OrderItem.order_id == Order.id)
        .filter(Order.user_id.in_(member_ids))
        .all()
    )
    for user_id, restaurant_id, dish_id in rows:
        dishes, restaurants = out.setdefault(user_id, (set(), set()))
        if dish_id:
            dishes.add(int(dish_id))
        if restaurant_id:
            restaurants.add(int(restaurant_id))
    return out


def _load_member_recommendation_events(
    db: Session, member_ids: list[int]
) -> dict[int, tuple[set[int], set[int]]]:
    """Return per-user (viewed_dish_ids, feedback_dish_ids)."""
    if not member_ids:
        return {}
    out: dict[int, tuple[set[int], set[int]]] = {
        uid: (set(), set()) for uid in member_ids
    }
    rows = (
        db.query(RecommendationEvent.user_id, RecommendationEvent.dish_id, RecommendationEvent.event_type)
        .filter(RecommendationEvent.user_id.in_(member_ids))
        .all()
    )
    for user_id, dish_id, event_type in rows:
        viewed, feedback = out.setdefault(user_id, (set(), set()))
        did = int(dish_id)
        if event_type in {"impression", "click"}:
            viewed.add(did)
        if event_type in {"click", "order"}:
            feedback.add(did)
    return out


def load_group_context(db: Session, session: GroupSession) -> GroupRecommendationContext:
    """Batch-load member preferences, history, and fresh locations for a session."""
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

    order_history = _load_member_order_history(db, member_ids)
    event_history = _load_member_recommendation_events(db, member_ids)

    members: list[MemberPreferenceContext] = []
    group_allergies: set[str] = set()
    group_dietary: set[str] = set()
    cuisine_counter: dict[str, int] = {}

    for user_id in member_ids:
        pref = prefs_by_user.get(user_id)
        dietary = _normalize_list(pref.dietary_preferences if pref else None)
        if pref and pref.dietary_preference and not dietary:
            dietary = [str(pref.dietary_preference).strip().lower()]
        allergies = _normalize_list(pref.allergies if pref else None)
        cuisines = _normalize_list(pref.favorite_cuisines if pref else None)
        for cuisine in cuisines:
            cuisine_counter[cuisine] = cuisine_counter.get(cuisine, 0) + 1

        ordered_dishes, ordered_restaurants = order_history.get(user_id, (set(), set()))
        viewed_dishes, feedback_dishes = event_history.get(user_id, (set(), set()))

        nutrition_goal = None
        if pref and pref.nutrition_goal:
            nutrition_goal = str(pref.nutrition_goal).strip().lower()

        member = MemberPreferenceContext(
            user_id=user_id,
            favorite_cuisines=cuisines,
            dietary_preferences=dietary,
            allergies=allergies,
            disliked_categories=_normalize_list(pref.disliked_categories if pref else None),
            nutrition_goal=nutrition_goal,
            budget_level=infer_budget_level(
                pref.budget_min if pref else None,
                pref.budget_max if pref else None,
                pref.budget_level if pref else None,
            ),
            budget_min=pref.budget_min if pref else None,
            budget_max=pref.budget_max if pref else None,
            ordered_dish_ids=ordered_dishes,
            ordered_restaurant_ids=ordered_restaurants,
            viewed_dish_ids=viewed_dishes,
            feedback_dish_ids=feedback_dishes,
        )
        members.append(member)
        group_allergies.update(allergies)
        group_dietary.update(dietary)

    group_cuisines = sorted(cuisine_counter.keys(), key=lambda c: (-cuisine_counter[c], c))

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
        group_cuisines=group_cuisines,
    )
