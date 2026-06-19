"""Restaurant owner dashboard statistics."""

from __future__ import annotations

from sqlalchemy import func
from sqlalchemy.orm import Session

from app.core.restaurant_constants import APPROVED
from app.models.dish import Dish
from app.models.order import Order
from app.models.order_item import OrderItem
from app.models.restaurant import Restaurant
from app.schemas.restaurant import PopularDishStat, RestaurantDashboardResponse


def build_restaurant_dashboard(db: Session, restaurant: Restaurant) -> RestaurantDashboardResponse:
    total_dishes = (
        db.query(func.count(Dish.id)).filter(Dish.restaurant_id == restaurant.id).scalar() or 0
    )
    available_dishes = (
        db.query(func.count(Dish.id))
        .filter(Dish.restaurant_id == restaurant.id, Dish.is_available.is_(True))
        .scalar()
        or 0
    )
    total_orders = (
        db.query(func.count(Order.id)).filter(Order.restaurant_id == restaurant.id).scalar() or 0
    )

    popular_rows = (
        db.query(
            Dish.id,
            Dish.name,
            func.count(OrderItem.id).label("order_count"),
        )
        .join(OrderItem, OrderItem.dish_id == Dish.id)
        .join(Order, Order.id == OrderItem.order_id)
        .filter(Dish.restaurant_id == restaurant.id)
        .group_by(Dish.id, Dish.name)
        .order_by(func.count(OrderItem.id).desc())
        .limit(5)
        .all()
    )

    if not popular_rows:
        fallback_dishes = (
            db.query(Dish)
            .filter(Dish.restaurant_id == restaurant.id)
            .order_by(Dish.name)
            .limit(5)
            .all()
        )
        popular_dishes = [
            PopularDishStat(dish_id=d.id, dish_name=d.name, order_count=0)
            for d in fallback_dishes
        ]
    else:
        popular_dishes = [
            PopularDishStat(
                dish_id=row.id,
                dish_name=row.name,
                order_count=int(row.order_count or 0),
            )
            for row in popular_rows
        ]

    return RestaurantDashboardResponse(
        restaurant_id=restaurant.id,
        restaurant_name=restaurant.name,
        approval_status=restaurant.approval_status or APPROVED,
        total_dishes=int(total_dishes),
        available_dishes=int(available_dishes),
        average_rating=float(restaurant.average_rating or 0),
        total_reviews=int(restaurant.total_reviews or 0),
        total_orders=int(total_orders),
        popular_dishes=popular_dishes,
    )
