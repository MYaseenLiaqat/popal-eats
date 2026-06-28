"""Restaurant owner dashboard statistics."""

from __future__ import annotations

from datetime import datetime, timezone

from sqlalchemy import func
from sqlalchemy.orm import Session, joinedload

from app.core.constants import ORDER_STATUS_CANCELLED, ORDER_STATUS_DELIVERED, ORDER_STATUS_PENDING
from app.core.restaurant_constants import APPROVED
from app.models.dish import Dish
from app.models.order import Order
from app.models.order_item import OrderItem
from app.models.post import Post
from app.models.restaurant import Restaurant
from app.models.review import Review
from app.schemas.restaurant import PopularDishStat, RestaurantDashboardResponse, ReviewBrief


def _start_of_today_utc() -> datetime:
    now = datetime.now(timezone.utc)
    return now.replace(hour=0, minute=0, second=0, microsecond=0)


def build_restaurant_dashboard(db: Session, restaurant: Restaurant) -> RestaurantDashboardResponse:
    today_start = _start_of_today_utc()
    rid = restaurant.id

    total_dishes = (
        db.query(func.count(Dish.id)).filter(Dish.restaurant_id == rid).scalar() or 0
    )
    available_dishes = (
        db.query(func.count(Dish.id))
        .filter(Dish.restaurant_id == rid, Dish.is_available.is_(True))
        .scalar()
        or 0
    )
    total_orders = (
        db.query(func.count(Order.id)).filter(Order.restaurant_id == rid).scalar() or 0
    )

    orders_today = (
        db.query(func.count(Order.id))
        .filter(Order.restaurant_id == rid, Order.created_at >= today_start)
        .scalar()
        or 0
    )
    pending_orders = (
        db.query(func.count(Order.id))
        .filter(Order.restaurant_id == rid, Order.status == ORDER_STATUS_PENDING)
        .scalar()
        or 0
    )
    completed_orders_today = (
        db.query(func.count(Order.id))
        .filter(
            Order.restaurant_id == rid,
            Order.status == ORDER_STATUS_DELIVERED,
            Order.created_at >= today_start,
        )
        .scalar()
        or 0
    )
    revenue_today_raw = (
        db.query(func.coalesce(func.sum(Order.total_price), 0))
        .filter(
            Order.restaurant_id == rid,
            Order.status != ORDER_STATUS_CANCELLED,
            Order.created_at >= today_start,
        )
        .scalar()
    )
    revenue_today = float(revenue_today_raw or 0)

    popular_rows = (
        db.query(
            Dish.id,
            Dish.name,
            func.count(OrderItem.id).label("order_count"),
        )
        .join(OrderItem, OrderItem.dish_id == Dish.id)
        .join(Order, Order.id == OrderItem.order_id)
        .filter(Dish.restaurant_id == rid)
        .group_by(Dish.id, Dish.name)
        .order_by(func.count(OrderItem.id).desc())
        .limit(5)
        .all()
    )

    if not popular_rows:
        fallback_dishes = (
            db.query(Dish)
            .filter(Dish.restaurant_id == rid)
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

    popular_dish = popular_dishes[0] if popular_dishes and popular_dishes[0].order_count > 0 else None

    review_rows = (
        db.query(Review)
        .options(joinedload(Review.user))
        .filter(Review.restaurant_id == rid)
        .order_by(Review.created_at.desc())
        .limit(5)
        .all()
    )
    recent_reviews = [
        ReviewBrief(
            id=r.id,
            rating=r.rating,
            comment=r.comment,
            author_name=(
                getattr(r.user, "full_name", None)
                or getattr(r.user, "username", None)
                if r.user
                else None
            ),
            created_at=r.created_at,
        )
        for r in review_rows
    ]

    post_stats = (
        db.query(
            func.count(Post.id),
            func.coalesce(func.sum(Post.like_count + Post.comment_count + Post.save_count), 0),
        )
        .filter(Post.restaurant_id == rid)
        .first()
    )
    total_posts = int(post_stats[0] or 0) if post_stats else 0
    post_engagement = int(post_stats[1] or 0) if post_stats else 0

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
        orders_today=int(orders_today),
        pending_orders=int(pending_orders),
        completed_orders_today=int(completed_orders_today),
        revenue_today=revenue_today,
        popular_dish=popular_dish,
        recent_reviews=recent_reviews,
        total_posts=total_posts,
        post_engagement=post_engagement,
    )
