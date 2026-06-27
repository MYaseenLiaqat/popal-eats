"""Scoring helpers for group recommendations."""

from __future__ import annotations

import math
from decimal import Decimal

from app.models.dish import Dish
from app.services.group_recommendation.filters import (
    is_dish_dietary_compatible,
    is_dish_safe_for_group,
)
from app.services.recommendation.preference_scoring import is_disliked_category
from app.services.user_preferences_service import budget_bounds_for_level

from app.services.recommendation.v2_content import _score_nutrition

WEIGHT_CUISINE = 0.36
WEIGHT_AGREEMENT = 0.20
WEIGHT_DISTANCE = 0.14
WEIGHT_BUDGET = 0.14
WEIGHT_POPULARITY = 0.08
WEIGHT_NUTRITION = 0.04
WEIGHT_ORDER_SIMILARITY = 0.04

MAX_DISTANCE_KM = 10.0


def compute_group_centroid(
    locations: list[tuple[float, float]],
) -> tuple[float, float] | None:
    """Average latitude/longitude of active member locations."""
    if not locations:
        return None
    lat_sum = sum(lat for lat, _ in locations)
    lng_sum = sum(lng for _, lng in locations)
    count = len(locations)
    return lat_sum / count, lng_sum / count


def haversine_km(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
    radius_km = 6371.0
    phi1, phi2 = math.radians(lat1), math.radians(lat2)
    d_phi = math.radians(lat2 - lat1)
    d_lambda = math.radians(lon2 - lon1)
    a = math.sin(d_phi / 2) ** 2 + math.cos(phi1) * math.cos(phi2) * math.sin(d_lambda / 2) ** 2
    return radius_km * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))


def score_distance(
    *,
    centroid: tuple[float, float] | None,
    restaurant_coords: tuple[float, float] | None,
) -> float:
    """0–100 score; higher when closer to group centroid."""
    if centroid is None or restaurant_coords is None:
        return 50.0
    distance = haversine_km(centroid[0], centroid[1], restaurant_coords[0], restaurant_coords[1])
    if distance <= 0.5:
        return 100.0
    if distance >= MAX_DISTANCE_KM:
        return 0.0
    return max(0.0, 100.0 * (1.0 - distance / MAX_DISTANCE_KM))


def _match_cuisine(cuisines: list[str], dish_tags: list[str], restaurant_tags: list[str]) -> bool:
    if not cuisines:
        return False
    for cuisine in cuisines:
        for tag in dish_tags + restaurant_tags:
            if cuisine in tag or tag in cuisine:
                return True
    return False


def _member_enjoys_dish(
    *,
    member_cuisines: list[str],
    member_dietary: set[str],
    member_allergies: set[str],
    member_disliked: list[str],
    dish: Dish,
    dish_tags: list[str],
    restaurant_tags: list[str],
) -> bool:
    if not is_dish_safe_for_group(
        dish,
        member_allergies,
        dish_tags=dish_tags,
        restaurant_tags=restaurant_tags,
    ):
        return False
    if member_dietary and not is_dish_dietary_compatible(
        dish,
        member_dietary,
        dish_tags=dish_tags,
        restaurant_tags=restaurant_tags,
    ):
        return False
    if is_disliked_category(dish, member_disliked):
        return False
    if _match_cuisine(member_cuisines, dish_tags, restaurant_tags):
        return True
    if member_cuisines:
        return False
    return True


def score_group_agreement(
    dish: Dish,
    members: list[dict],
    *,
    dish_tags: list[str],
    restaurant_tags: list[str],
) -> tuple[float, int, int]:
    """
    Return (agreement_pct 0–100, matching_members, total_members).
    """
    if not members:
        return 0.0, 0, 0

    matching = 0
    for member in members:
        if _member_enjoys_dish(
            member_cuisines=member["favorite_cuisines"],
            member_dietary=member["dietary"],
            member_allergies=member["allergies"],
            member_disliked=member["disliked_categories"],
            dish=dish,
            dish_tags=dish_tags,
            restaurant_tags=restaurant_tags,
        ):
            matching += 1

    total = len(members)
    pct = round(100.0 * matching / total, 2)
    return pct, matching, total


def score_cuisine_match(
    dish: Dish,
    members: list[dict],
    *,
    dish_tags: list[str],
    restaurant_tags: list[str],
) -> tuple[float, int, str | None]:
    """
    Return (score 0–100, matching_member_count, primary_matched_cuisine_label).

  Rewards dishes that satisfy multiple members' cuisines (conflict handling).
    """
    if not members:
        return 0.0, 0, None

    matching_members = 0
    matched_cuisines: set[str] = set()
    for member in members:
        member_cuisines = member.get("favorite_cuisines") or []
        if not member_cuisines:
            continue
        for cuisine in member_cuisines:
            if _match_cuisine([cuisine], dish_tags, restaurant_tags):
                matching_members += 1
                matched_cuisines.add(cuisine)
                break

    members_with_cuisines = sum(1 for member in members if member.get("favorite_cuisines"))
    if members_with_cuisines == 0:
        return 50.0, 0, None

    base = 100.0 * matching_members / members_with_cuisines
    diversity_bonus = min(15.0, max(0, len(matched_cuisines) - 1) * 5.0)
    score = round(min(100.0, base + diversity_bonus), 2)
    primary = next(iter(sorted(matched_cuisines)), None)
    return score, matching_members, primary


def _price_in_budget(price: Decimal, budget_level: str | None) -> bool:
    if not budget_level:
        return True
    low, high = budget_bounds_for_level(budget_level)
    if low is not None and price < low:
        return False
    if high is not None and price > high:
        return False
    return True


def score_budget_compatibility(dish: Dish, members: list[dict]) -> float:
    if not members:
        return 50.0
    levels = [member["budget_level"] for member in members if member.get("budget_level")]
    if not levels:
        return 50.0
    fits = sum(1 for level in levels if _price_in_budget(dish.price, level))
    return round(100.0 * fits / len(levels), 2)


def score_popularity(dish: Dish, order_count: int, max_orders: int) -> float:
    restaurant = dish.restaurant
    rating_score = 0.0
    if restaurant and restaurant.average_rating:
        rating_score = min(100.0, (float(restaurant.average_rating) / 5.0) * 100.0)
    order_score = 0.0
    if max_orders > 0:
        order_score = min(100.0, (order_count / max_orders) * 100.0)
    return round((rating_score * 0.6) + (order_score * 0.4), 2)


def score_nutrition_compatibility(dish: Dish, members: list[dict]) -> float:
    goals = [m.get("nutrition_goal") for m in members if m.get("nutrition_goal")]
    if not goals:
        return 50.0
    total = 0.0
    for goal in goals:
        pts, _ = _score_nutrition(dish, goal)
        total += min(100.0, (pts / 25.0) * 100.0) if pts else 0.0
    return round(total / len(goals), 2)


def score_order_similarity(dish: Dish, members: list[dict]) -> float:
    if not members:
        return 0.0
    restaurant_id = dish.restaurant_id
    hits = 0
    for member in members:
        if dish.id in member.get("ordered_dish_ids", set()):
            return 100.0
        if restaurant_id and restaurant_id in member.get("ordered_restaurant_ids", set()):
            hits += 1
            continue
        if dish.id in member.get("feedback_dish_ids", set()):
            hits += 1
        elif dish.id in member.get("viewed_dish_ids", set()):
            hits += 0.5
    if hits <= 0:
        return 0.0
    return round(min(100.0, (hits / len(members)) * 100.0), 2)


def compute_group_score(
    *,
    cuisine_score: float,
    agreement_score: float,
    distance_score: float,
    budget_score: float,
    popularity_score: float,
    nutrition_score: float = 50.0,
    order_similarity_score: float = 0.0,
) -> float:
    total = (
        cuisine_score * WEIGHT_CUISINE
        + agreement_score * WEIGHT_AGREEMENT
        + distance_score * WEIGHT_DISTANCE
        + budget_score * WEIGHT_BUDGET
        + popularity_score * WEIGHT_POPULARITY
        + nutrition_score * WEIGHT_NUTRITION
        + order_similarity_score * WEIGHT_ORDER_SIMILARITY
    )
    return round(min(100.0, max(0.0, total)), 2)


def build_reasons(
    *,
    matching_members: int,
    total_members: int,
    budget_score: float,
    distance_score: float,
    cuisine_score: float,
) -> list[str]:
    reasons: list[str] = []
    if total_members > 0 and matching_members > 0:
        if matching_members == total_members:
            reasons.append("Works for everyone in your group")
        else:
            reasons.append(f"Works for {matching_members} of {total_members} friends")
    if budget_score >= 70:
        reasons.append("Matches your group budget")
    if distance_score >= 70:
        reasons.append("Near your group")
    elif distance_score >= 50:
        reasons.append("Popular nearby")
    if cuisine_score >= 70 and len(reasons) < 3:
        reasons.append("Matches your group's tastes")
    if not reasons:
        reasons.append("A solid pick for the group")
    return reasons
