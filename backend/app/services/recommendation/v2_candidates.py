"""
Recommendation Engine V2 — eligible dish loading from PostgreSQL.

All V2 strategies must use ``load_eligible_dishes`` so results never include
Swagger/API placeholder rows (e.g. name="string", "Test Dish").
"""

import logging
import re

from sqlalchemy.orm import Session, joinedload

from app.models.dish import Dish
from app.services.recommendation.market_filter import filter_dishes_for_market
from app.services.recommendation.v2_debug import log_pipeline_stage

logger = logging.getLogger("popal.recommendations.v2")

# Common OpenAPI/Swagger and manual test placeholders (lowercase).
_PLACEHOLDER_EXACT = frozenset(
    {
        "string",
        "test",
        "test dish",
        "dish",
        "name",
        "food",
        "item",
        "restaurant",
        "sample",
        "example",
        "title",
    }
)

_TEST_NAME_PATTERN = re.compile(r"^test[\s_-]", re.IGNORECASE)


_RESTAURANT_PLACEHOLDER_EXACT = frozenset({"pizza", "restaurant", "string"})


def is_placeholder_name(name: str | None, *, entity: str = "dish") -> bool:
    """True when a dish or restaurant name looks like test/placeholder data."""
    if name is None:
        return True
    stripped = name.strip()
    if len(stripped) < 2:
        return True
    lowered = stripped.lower()
    if lowered in _PLACEHOLDER_EXACT:
        return True
    if entity == "restaurant" and lowered in _RESTAURANT_PLACEHOLDER_EXACT:
        return True
    if _TEST_NAME_PATTERN.match(stripped):
        return True
    return False


def is_eligible_dish(dish: Dish) -> bool:
    """
    Dish must be available, from an open restaurant, with real names.
    Names are read from ``dishes`` / ``restaurants`` tables only.
    """
    if not dish.is_available:
        return False
    restaurant = dish.restaurant
    if restaurant is None or not restaurant.is_open:
        return False
    if is_placeholder_name(dish.name, entity="dish"):
        return False
    if is_placeholder_name(restaurant.name, entity="restaurant"):
        return False
    return True


def load_eligible_dishes(db: Session, *, user_id: int | None = None) -> list[Dish]:
    """
    Load candidate dishes joined with restaurant (+ category) from the database.

    Filters out placeholder/test menu rows. Logs excluded ids for debugging.
    """
    dishes = (
        db.query(Dish)
        .join(Dish.restaurant)
        .options(joinedload(Dish.restaurant), joinedload(Dish.category))
        .filter(Dish.is_available.is_(True))
        .filter(Dish.restaurant.has(is_open=True))
        .all()
    )

    eligible: list[Dish] = []
    excluded: list[tuple[int, str, str, str]] = []

    for dish in dishes:
        restaurant = dish.restaurant
        if is_eligible_dish(dish):
            eligible.append(dish)
        else:
            reason = _exclusion_reason(dish)
            excluded.append(
                (
                    dish.id,
                    dish.name,
                    restaurant.name if restaurant else "",
                    reason,
                )
            )

    uid = f" user_id={user_id}" if user_id is not None else ""
    foodpanda_eligible = sum(1 for dish in eligible if dish.source == "foodpanda")
    log_pipeline_stage(
        "candidates_filtered",
        user_id=user_id,
        total_loaded=len(dishes),
        eligible=len(eligible),
        excluded=len(excluded),
        foodpanda_eligible=foodpanda_eligible,
    )
    logger.info(
        "V2 candidate dishes%s: %d eligible of %d total (%d excluded)",
        uid,
        len(eligible),
        len(dishes),
        len(excluded),
    )
    for dish_id, dish_name, restaurant_name, reason in excluded[:25]:
        logger.debug(
            "V2 excluded dish_id=%s name=%r restaurant=%r reason=%s",
            dish_id,
            dish_name,
            restaurant_name,
            reason,
        )
    if len(excluded) > 25:
        logger.debug("V2 excluded %d more placeholder dishes (truncated log)", len(excluded) - 25)

    if dishes and not eligible:
        logger.warning(
            "V2 no eligible dishes after filtering placeholders (%d rows in DB). "
            "Create real menu data via POST /restaurants and POST /dishes — "
            "avoid Swagger default values like name='string'.",
            len(dishes),
        )

    for dish in eligible[:30]:
        restaurant = dish.restaurant
        category = dish.category.name if dish.category else None
        logger.debug(
            "V2 candidate dish_id=%s name=%r restaurant=%r category=%r price=%s",
            dish.id,
            dish.name,
            restaurant.name if restaurant else "",
            category,
            dish.price,
        )
    if len(eligible) > 30:
        logger.debug("V2 logged 30 of %d eligible candidates (truncated)", len(eligible))

    market_filtered = filter_dishes_for_market(eligible)
    if eligible and not market_filtered:
        logger.warning(
            "V2 Lahore market filter removed all %d eligible dishes — check restaurant.city values",
            len(eligible),
        )
    logger.info(
        "V2 Lahore market filter: %d of %d eligible dishes",
        len(market_filtered),
        len(eligible),
    )
    return market_filtered


def _exclusion_reason(dish: Dish) -> str:
    if not dish.is_available:
        return "not_available"
    restaurant = dish.restaurant
    if restaurant is None:
        return "no_restaurant"
    if not restaurant.is_open:
        return "restaurant_closed"
    if is_placeholder_name(dish.name, entity="dish"):
        return "placeholder_dish_name"
    if is_placeholder_name(restaurant.name, entity="restaurant"):
        return "placeholder_restaurant_name"
    return "ineligible"
