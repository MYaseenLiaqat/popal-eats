"""
Recommendation Engine V2 — trending, popular, and analytics (Phase 4).
"""

from sqlalchemy import func
from sqlalchemy.orm import Session, joinedload

from app.models.dish import Dish
from app.models.order import Order
from app.models.order_item import OrderItem
from app.models.recommendation_event import RecommendationEvent
from app.models.restaurant import Restaurant
from app.models.review import Review
from app.schemas.recommendation_v2_analytics import (
    AnalyticsResponse,
    PopularDish,
    PopularResponse,
    TrendingDish,
    TrendingResponse,
)

ENGINE_VERSION = "2.1"
TRENDING_ORDER_WEIGHT = 0.5
TRENDING_REVIEW_WEIGHT = 0.3
TRENDING_RATING_WEIGHT = 0.2


def _dish_order_totals(db: Session) -> dict[int, int]:
    """Sum order_items.quantity per dish_id (0 if never ordered)."""
    rows = (
        db.query(
            OrderItem.dish_id,
            func.coalesce(func.sum(OrderItem.quantity), 0),
        )
        .group_by(OrderItem.dish_id)
        .all()
    )
    return {int(dish_id): int(total or 0) for dish_id, total in rows}


def _compute_trending_score(order_count: int, review_count: int, average_rating: float) -> float:
    return round(
        order_count * TRENDING_ORDER_WEIGHT
        + review_count * TRENDING_REVIEW_WEIGHT
        + float(average_rating or 0.0) * TRENDING_RATING_WEIGHT,
        4,
    )


def _eligible_dishes_query(db: Session):
    return (
        db.query(Dish)
        .join(Dish.restaurant)
        .options(joinedload(Dish.restaurant))
        .filter(Dish.is_available.is_(True))
        .filter(Restaurant.is_open.is_(True))
    )


def get_trending_dishes(db: Session, *, limit: int = 10) -> TrendingResponse:
    """
    Trending dishes by engagement:

    trending_score = order_count×0.5 + review_count×0.3 + average_rating×0.2

    ``review_count`` and ``average_rating`` come from the parent restaurant.
    """
    limit = max(1, min(limit, 50))
    order_totals = _dish_order_totals(db)
    dishes = _eligible_dishes_query(db).all()

    ranked: list[TrendingDish] = []
    for dish in dishes:
        restaurant = dish.restaurant
        if not restaurant:
            continue
        order_count = order_totals.get(dish.id, 0)
        review_count = int(restaurant.total_reviews or 0)
        average_rating = float(restaurant.average_rating or 0.0)
        trending_score = _compute_trending_score(order_count, review_count, average_rating)

        ranked.append(
            TrendingDish(
                dish_id=dish.id,
                dish_name=dish.name,
                restaurant_name=restaurant.name,
                price=dish.price,
                average_rating=round(average_rating, 2),
                order_count=order_count,
                review_count=review_count,
                trending_score=trending_score,
            )
        )

    ranked.sort(key=lambda row: row.trending_score, reverse=True)
    items = ranked[:limit]

    return TrendingResponse(
        engine_version=ENGINE_VERSION,
        items=items,
        count=len(items),
        limit=limit,
    )


def get_popular_dishes(db: Session, *, limit: int = 10) -> PopularResponse:
    """Most ordered dishes by total order_items.quantity (descending)."""
    limit = max(1, min(limit, 50))
    order_totals = _dish_order_totals(db)
    dishes = _eligible_dishes_query(db).all()

    ranked: list[PopularDish] = []
    for dish in dishes:
        total_orders = order_totals.get(dish.id, 0)
        if total_orders <= 0:
            continue
        restaurant = dish.restaurant
        ranked.append(
            PopularDish(
                dish_id=dish.id,
                dish_name=dish.name,
                restaurant_name=restaurant.name if restaurant else "",
                price=dish.price,
                total_orders=total_orders,
            )
        )

    ranked.sort(key=lambda row: row.total_orders, reverse=True)
    items = ranked[:limit]

    return PopularResponse(
        engine_version=ENGINE_VERSION,
        items=items,
        count=len(items),
        limit=limit,
    )


def _count_recommendation_events(db: Session, event_type: str) -> int:
    return int(
        db.query(func.count(RecommendationEvent.id))
        .filter(RecommendationEvent.event_type == event_type)
        .scalar()
        or 0
    )


def get_recommendation_analytics(db: Session) -> AnalyticsResponse:
    """Platform-wide counts for recommendation dashboards."""
    total_dishes = db.query(func.count(Dish.id)).scalar() or 0
    total_restaurants = db.query(func.count(Restaurant.id)).scalar() or 0
    total_orders = db.query(func.count(Order.id)).scalar() or 0
    total_reviews = db.query(func.count(Review.id)).scalar() or 0
    avg_rating = db.query(func.coalesce(func.avg(Restaurant.average_rating), 0.0)).scalar()

    total_impressions = _count_recommendation_events(db, "impression")
    total_clicks = _count_recommendation_events(db, "click")
    if total_impressions == 0:
        click_through_rate = 0.0
    else:
        click_through_rate = round(total_clicks / total_impressions, 4)

    return AnalyticsResponse(
        engine_version=ENGINE_VERSION,
        total_dishes=int(total_dishes),
        total_restaurants=int(total_restaurants),
        total_orders=int(total_orders),
        total_reviews=int(total_reviews),
        avg_restaurant_rating=round(float(avg_rating or 0.0), 2),
        total_impressions=total_impressions,
        total_clicks=total_clicks,
        click_through_rate=click_through_rate,
    )
