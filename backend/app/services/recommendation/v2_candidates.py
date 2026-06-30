"""
Recommendation Engine V2 — eligible dish loading from PostgreSQL.

All V2 strategies must use ``load_eligible_dishes`` so results never include
Swagger/API placeholder rows (e.g. name="string", "Test Dish").
"""

import logging

from sqlalchemy.orm import Session, defer, joinedload, load_only

from app.core.restaurant_constants import APPROVED
from app.models.category import Category
from app.models.dish import Dish
from app.models.restaurant import Restaurant
from app.services.recommendation.v2_dish_pool_cache import get_cached_eligible_dishes
from app.services.recommendation.v2_eligible_cache import get_eligible_dish_ids
from app.services.recommendation.v2_debug import log_pipeline_stage
from app.services.recommendation.v2_placeholders import is_placeholder_name

logger = logging.getLogger("popal.recommendations.v2")


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
    if getattr(restaurant, "approval_status", APPROVED) != APPROVED:
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
    return get_cached_eligible_dishes(db, user_id=user_id)


def _load_eligible_dishes_uncached(db: Session, *, user_id: int | None = None) -> list[Dish]:
    """Internal uncached loader used by the dish pool cache."""
    eligible_ids = get_eligible_dish_ids(db)
    if not eligible_ids:
        log_pipeline_stage(
            "candidates_filtered",
            user_id=user_id,
            total_loaded=0,
            eligible=0,
            excluded=0,
            foodpanda_eligible=0,
        )
        return []

    dishes = (
        db.query(Dish)
        .join(Restaurant, Dish.restaurant_id == Restaurant.id)
        .options(
            load_only(
                Dish.id,
                Dish.name,
                Dish.price,
                Dish.calories,
                Dish.description,
                Dish.tags,
                Dish.source,
                Dish.cuisine,
                Dish.protein,
                Dish.carbs,
                Dish.is_available,
                Dish.restaurant_id,
                Dish.category_id,
                Dish.allergens,
                Dish.protein,
                Dish.carbs,
            ),
            joinedload(Dish.restaurant).load_only(
                Restaurant.id,
                Restaurant.name,
                Restaurant.description,
                Restaurant.tags,
                Restaurant.average_rating,
                Restaurant.total_reviews,
                Restaurant.source,
                Restaurant.is_open,
                Restaurant.approval_status,
                Restaurant.city,
                Restaurant.external_code,
            ),
            joinedload(Dish.category).load_only(Category.id, Category.name),
            defer(Dish.images),
            defer(Dish.ingredients),
        )
        .filter(Dish.id.in_(eligible_ids))
        .filter(Dish.is_available.is_(True))
        .filter(Restaurant.is_open.is_(True))
        .filter(Restaurant.approval_status == APPROVED)
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

    logger.info("V2 Lahore market filter: %d eligible dishes (cached id set)", len(eligible))
    return eligible


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
