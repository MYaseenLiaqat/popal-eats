"""Market scoping helpers — Lahore-first catalog filtering."""

from __future__ import annotations

from app.models.restaurant import Restaurant

LAHORE_MARKET = "lahore"


def normalize_city(city: str | None) -> str:
    return (city or "").strip().lower()


def is_lahore_market_restaurant(restaurant: Restaurant | None) -> bool:
    """
    Include Lahore vendors; exclude known other-city imports (e.g. Karachi).

    Dishes with missing city are excluded unless clearly Lahore-tagged.
    """
    if restaurant is None:
        return False

    city = normalize_city(restaurant.city)
    if not city:
        return False
    if "karachi" in city or city == "khi":
        return False
    if "lahore" in city or city == "lhr":
        return True
    return False


def filter_dishes_for_market(dishes: list, *, market: str = LAHORE_MARKET) -> list:
    if market != LAHORE_MARKET:
        return dishes
    return [d for d in dishes if is_lahore_market_restaurant(d.restaurant)]
