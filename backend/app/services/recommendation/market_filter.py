"""Market scoping helpers — Lahore-first catalog filtering."""

from __future__ import annotations

from app.models.restaurant import Restaurant
from app.services.recommendation.v2_catalog import FOODPANDA_SOURCE

LAHORE_MARKET = "lahore"


def normalize_city(city: str | None) -> str:
    return (city or "").strip().lower()


def is_lahore_market_restaurant(restaurant: Restaurant | None) -> bool:
    """
    Include Lahore vendors; exclude known other-city imports (e.g. Karachi).

    Foodpanda Lahore catalog rows without city are treated as Lahore.
    """
    if restaurant is None:
        return False

    try:
        city = normalize_city(restaurant.city)
    except Exception:
        city = ""

    if city and ("karachi" in city or city == "khi"):
        return False
    if city and ("lahore" in city or city == "lhr"):
        return True
    if getattr(restaurant, "source", None) == FOODPANDA_SOURCE:
        return True
    return False


def filter_dishes_for_market(dishes: list, *, market: str = LAHORE_MARKET) -> list:
    if market != LAHORE_MARKET:
        return dishes
    return [d for d in dishes if is_lahore_market_restaurant(d.restaurant)]
