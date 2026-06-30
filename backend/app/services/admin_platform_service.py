"""Admin platform metrics, search, and operational snapshots."""

from __future__ import annotations

from datetime import datetime, timedelta, timezone

from sqlalchemy import func, or_
from sqlalchemy.orm import Session, joinedload

from app.core.account_status import ACTIVE, PENDING, SUSPENDED
from app.core.constants import (
    ORDER_STATUS_CANCELLED,
    ORDER_STATUS_DELIVERED,
    ORDER_STATUS_ON_THE_WAY,
    ORDER_STATUS_PENDING,
    ORDER_STATUS_PICKED_UP,
    ORDER_STATUS_PREPARING,
)
from app.core.content_constants import CHEF_POST, FOOD_POST, RECIPE, RESTAURANT_POST
from app.core.restaurant_constants import APPROVED
from app.core.roles import CUSTOMER, HOME_CHEF, RESTAURANT, normalize_role
from app.models.dish import Dish
from app.models.order import Order
from app.models.post import Post
from app.models.recommendation_event import RecommendationEvent
from app.models.restaurant import Restaurant
from app.models.review import Review
from app.models.story import Story
from app.models.user import User


def _day_key(dt: datetime | None) -> str | None:
    if dt is None:
        return None
    return dt.date().isoformat()


def _series_for_days(db: Session, model, days: int = 7) -> list[dict]:
    """Daily counts for the last N days (including zeros)."""
    cutoff = datetime.now(timezone.utc) - timedelta(days=days - 1)
    rows = (
        db.query(func.date(model.created_at).label("day"), func.count(model.id))
        .filter(model.created_at >= cutoff)
        .group_by(func.date(model.created_at))
        .order_by(func.date(model.created_at))
        .all()
    )
    counts = {str(row[0]): int(row[1]) for row in rows if row[0] is not None}
    result: list[dict] = []
    today = datetime.now(timezone.utc).date()
    for i in range(days - 1, -1, -1):
        day = (today - timedelta(days=i)).isoformat()
        result.append({"date": day, "count": counts.get(day, 0)})
    return result


def build_platform_overview(db: Session) -> dict:
    now = datetime.now(timezone.utc)
    week_ago = now - timedelta(days=7)

    total_posts = db.query(func.count(Post.id)).scalar() or 0
    total_stories = db.query(func.count(Story.id)).scalar() or 0
    total_recipes = (
        db.query(func.count(Post.id)).filter(Post.post_type == RECIPE).scalar() or 0
    )
    total_reels = (
        db.query(func.count(Post.id))
        .filter(
            or_(
                Post.video_url.isnot(None),
                Post.post_type.in_((RESTAURANT_POST, CHEF_POST)),
            )
        )
        .filter(Post.video_url.isnot(None))
        .scalar()
        or 0
    )

    customers = (
        db.query(func.count(User.id)).filter(User.role == CUSTOMER).scalar() or 0
    )
    restaurants_count = db.query(func.count(Restaurant.id)).scalar() or 0
    home_chefs = (
        db.query(func.count(User.id)).filter(User.role == HOME_CHEF).scalar() or 0
    )

    pending_restaurants = (
        db.query(func.count(Restaurant.id))
        .filter(Restaurant.approval_status == PENDING)
        .scalar()
        or 0
    )
    pending_home_chefs = (
        db.query(func.count(User.id))
        .filter(User.role == HOME_CHEF, User.account_status == PENDING)
        .scalar()
        or 0
    )

    active_orders = (
        db.query(func.count(Order.id))
        .filter(
            Order.status.notin_(
                (ORDER_STATUS_DELIVERED, ORDER_STATUS_CANCELLED)
            )
        )
        .scalar()
        or 0
    )

    pending_reviews = (
        db.query(func.count(Review.id))
        .filter(Review.processing_status == "pending")
        .scalar()
        or 0
    )
    failed_reviews = (
        db.query(func.count(Review.id))
        .filter(Review.processing_status == "failed")
        .scalar()
        or 0
    )

    active_deliveries = (
        db.query(func.count(Order.id))
        .filter(Order.status.in_((ORDER_STATUS_PICKED_UP, ORDER_STATUS_ON_THE_WAY)))
        .scalar()
        or 0
    )

    day_ago = now - timedelta(days=1)
    daily_active_users = (
        db.query(func.count(func.distinct(Order.user_id)))
        .filter(Order.created_at >= day_ago)
        .scalar()
        or 0
    )

    rec_events = db.query(func.count(RecommendationEvent.id)).scalar() or 0
    rec_week = (
        db.query(func.count(RecommendationEvent.id))
        .filter(RecommendationEvent.created_at >= week_ago)
        .scalar()
        or 0
    )
    rec_clicks = (
        db.query(func.count(RecommendationEvent.id))
        .filter(RecommendationEvent.event_type == "click")
        .scalar()
        or 0
    )
    rec_impressions = (
        db.query(func.count(RecommendationEvent.id))
        .filter(RecommendationEvent.event_type == "impression")
        .scalar()
        or 0
    )
    success_rate = (
        round(rec_clicks / rec_impressions * 100, 1) if rec_impressions > 0 else None
    )

    revenue_total = (
        db.query(func.coalesce(func.sum(Order.total_price), 0))
        .filter(Order.status == ORDER_STATUS_DELIVERED)
        .scalar()
    )

    top_cuisine_row = (
        db.query(Restaurant.tags)
        .filter(Restaurant.approval_status == APPROVED)
        .limit(200)
        .all()
    )
    cuisine_counts: dict[str, int] = {}
    for (tags,) in top_cuisine_row:
        if isinstance(tags, list) and tags:
            label = str(tags[0])
            cuisine_counts[label] = cuisine_counts.get(label, 0) + 1
    top_cuisine = max(cuisine_counts, key=cuisine_counts.get) if cuisine_counts else None

    top_restaurant = (
        db.query(Restaurant.name)
        .filter(Restaurant.approval_status == APPROVED)
        .order_by(Restaurant.average_rating.desc().nullslast())
        .first()
    )
    top_chef = (
        db.query(User.full_name)
        .filter(User.role == HOME_CHEF, User.account_status == ACTIVE)
        .order_by(User.created_at.desc())
        .first()
    )
    top_dish = (
        db.query(Dish.name)
        .order_by(Dish.id.desc())
        .first()
    )
    top_rec_dish = (
        db.query(RecommendationEvent.dish_id, func.count(RecommendationEvent.id).label("c"))
        .group_by(RecommendationEvent.dish_id)
        .order_by(func.count(RecommendationEvent.id).desc())
        .first()
    )
    top_rec_dish_name = None
    if top_rec_dish:
        dish = db.query(Dish).filter(Dish.id == top_rec_dish[0]).first()
        top_rec_dish_name = dish.name if dish else None

    return {
        "kpis": {
            "total_users": db.query(func.count(User.id)).scalar() or 0,
            "customers": customers,
            "restaurants": restaurants_count,
            "home_chefs": home_chefs,
            "active_orders": active_orders,
            "total_dishes": db.query(func.count(Dish.id)).scalar() or 0,
            "total_posts": total_posts,
            "total_stories": total_stories,
            "total_reels": total_reels,
            "total_recipes": total_recipes,
            "pending_restaurant_approvals": pending_restaurants,
            "pending_home_chef_approvals": pending_home_chefs,
            "pending_reports": failed_reviews,
            "pending_reviews": pending_reviews,
            "active_deliveries": active_deliveries,
            "daily_active_users": daily_active_users,
            "total_reviews": db.query(func.count(Review.id)).scalar() or 0,
            "revenue_total": float(revenue_total or 0),
        },
        "timeseries": {
            "new_users": _series_for_days(db, User, 7),
            "orders": _series_for_days(db, Order, 7),
            "posts": _series_for_days(db, Post, 7),
            "recipes": _recipe_daily_series(db, 7),
            "stories": _series_for_days(db, Story, 7),
            "reels": _reel_daily_series(db, 7),
        },
        "recommendations": {
            "total_requests": rec_events,
            "requests_7d": rec_week,
            "hybrid_calls": rec_week,
            "impressions": rec_impressions,
            "clicks": rec_clicks,
            "success_rate_percent": success_rate,
            "cache_hit_rate_percent": None,
            "avg_score": None,
        },
        "top_entities": {
            "cuisine": top_cuisine,
            "restaurant": top_restaurant[0] if top_restaurant else None,
            "home_chef": top_chef[0] if top_chef else None,
            "dish": top_dish[0] if top_dish else None,
            "ai_recommended_dish": top_rec_dish_name,
        },
        "order_status_counts": _order_status_counts(db),
        "sentiment_breakdown": [
            {"sentiment": row[0], "count": row[1]}
            for row in db.query(Review.sentiment, func.count(Review.id))
            .filter(Review.sentiment.isnot(None))
            .group_by(Review.sentiment)
            .all()
        ],
    }


def _order_status_counts(db: Session) -> dict[str, int]:
    rows = db.query(Order.status, func.count(Order.id)).group_by(Order.status).all()
    return {str(status): int(count) for status, count in rows}


def _recipe_daily_series(db: Session, days: int = 7) -> list[dict]:
    cutoff = datetime.now(timezone.utc) - timedelta(days=days - 1)
    rows = (
        db.query(func.date(Post.created_at).label("day"), func.count(Post.id))
        .filter(Post.post_type == RECIPE, Post.created_at >= cutoff)
        .group_by(func.date(Post.created_at))
        .all()
    )
    counts = {str(row[0]): int(row[1]) for row in rows if row[0] is not None}
    result: list[dict] = []
    today = datetime.now(timezone.utc).date()
    for i in range(days - 1, -1, -1):
        day = (today - timedelta(days=i)).isoformat()
        result.append({"date": day, "count": counts.get(day, 0)})
    return result


def _reel_daily_series(db: Session, days: int = 7) -> list[dict]:
    cutoff = datetime.now(timezone.utc) - timedelta(days=days - 1)
    rows = (
        db.query(func.date(Post.created_at).label("day"), func.count(Post.id))
        .filter(Post.video_url.isnot(None), Post.created_at >= cutoff)
        .group_by(func.date(Post.created_at))
        .all()
    )
    counts = {str(row[0]): int(row[1]) for row in rows if row[0] is not None}
    result: list[dict] = []
    today = datetime.now(timezone.utc).date()
    for i in range(days - 1, -1, -1):
        day = (today - timedelta(days=i)).isoformat()
        result.append({"date": day, "count": counts.get(day, 0)})
    return result


def list_admin_orders(
    db: Session,
    *,
    page: int = 1,
    limit: int = 20,
    status: str | None = None,
    search: str | None = None,
) -> tuple[list[dict], int]:
    query = (
        db.query(Order)
        .options(joinedload(Order.user), joinedload(Order.restaurant))
        .order_by(Order.created_at.desc())
    )
    if status:
        query = query.filter(Order.status == status.strip().lower())
    if search:
        pattern = f"%{search.strip()}%"
        query = query.join(Order.user).join(Order.restaurant).filter(
            or_(
                User.full_name.ilike(pattern),
                User.email.ilike(pattern),
                Restaurant.name.ilike(pattern),
            )
        )
    total = query.count()
    rows = query.offset((page - 1) * limit).limit(limit).all()
    items = [
        {
            "id": o.id,
            "user_id": o.user_id,
            "user_name": o.user.full_name if o.user else None,
            "user_email": o.user.email if o.user else None,
            "restaurant_id": o.restaurant_id,
            "restaurant_name": o.restaurant.name if o.restaurant else None,
            "total_price": float(o.total_price),
            "status": o.status,
            "payment_status": o.payment_status,
            "delivery_address": o.delivery_address,
            "created_at": o.created_at.isoformat() if o.created_at else None,
        }
        for o in rows
    ]
    return items, total


def list_admin_content(
    db: Session,
    *,
    content_type: str = "all",
    page: int = 1,
    limit: int = 20,
) -> tuple[list[dict], int]:
    query = (
        db.query(Post)
        .options(joinedload(Post.author), joinedload(Post.restaurant))
        .order_by(Post.created_at.desc())
    )
    ct = content_type.strip().lower()
    if ct == "food_posts":
        query = query.filter(Post.post_type == FOOD_POST)
    elif ct == "recipes":
        query = query.filter(Post.post_type == RECIPE)
    elif ct == "reels":
        query = query.filter(Post.video_url.isnot(None))
    elif ct == "restaurant_posts":
        query = query.filter(Post.post_type == RESTAURANT_POST)
    elif ct == "chef_posts":
        query = query.filter(Post.post_type == CHEF_POST)

    total = query.count()
    rows = query.offset((page - 1) * limit).limit(limit).all()
    items = [
        {
            "id": p.id,
            "post_type": p.post_type,
            "title": p.title,
            "caption": (p.caption or "")[:200],
            "author_id": p.author_id,
            "author_name": p.author.full_name if p.author else None,
            "author_username": p.author.username if p.author else None,
            "restaurant_name": p.restaurant.name if p.restaurant else None,
            "images": p.images if isinstance(p.images, list) else [],
            "video_url": p.video_url,
            "created_at": p.created_at.isoformat() if p.created_at else None,
            "reports_count": 0,
        }
        for p in rows
    ]
    return items, total


def list_admin_stories(db: Session, *, page: int = 1, limit: int = 20) -> tuple[list[dict], int]:
    query = (
        db.query(Story)
        .options(joinedload(Story.user))
        .order_by(Story.created_at.desc())
    )
    total = query.count()
    rows = query.offset((page - 1) * limit).limit(limit).all()
    items = [
        {
            "id": s.id,
            "user_id": s.user_id,
            "author_name": s.user.full_name if s.user else None,
            "author_username": s.user.username if s.user else None,
            "image_url": s.image_url,
            "expires_at": s.expires_at.isoformat() if s.expires_at else None,
            "created_at": s.created_at.isoformat() if s.created_at else None,
        }
        for s in rows
    ]
    return items, total


def admin_global_search(db: Session, query: str, *, limit: int = 10) -> dict:
    pattern = f"%{query.strip()}%"
    if len(query.strip()) < 2:
        return {"users": [], "restaurants": [], "orders": [], "posts": [], "reviews": []}

    users = (
        db.query(User)
        .filter(
            or_(
                User.full_name.ilike(pattern),
                User.username.ilike(pattern),
                User.email.ilike(pattern),
            )
        )
        .limit(limit)
        .all()
    )
    restaurants = (
        db.query(Restaurant).filter(Restaurant.name.ilike(pattern)).limit(limit).all()
    )
    orders = (
        db.query(Order)
        .join(User)
        .filter(
            or_(
                User.email.ilike(pattern),
                User.full_name.ilike(pattern),
            )
        )
        .order_by(Order.created_at.desc())
        .limit(limit)
        .all()
    )
    posts = (
        db.query(Post)
        .filter(or_(Post.caption.ilike(pattern), Post.title.ilike(pattern)))
        .limit(limit)
        .all()
    )
    reviews = (
        db.query(Review)
        .filter(Review.comment.ilike(pattern))
        .limit(limit)
        .all()
    )

    return {
        "users": [
            {
                "id": u.id,
                "full_name": u.full_name,
                "username": u.username,
                "email": u.email,
                "role": normalize_role(u.role),
            }
            for u in users
        ],
        "restaurants": [{"id": r.id, "name": r.name} for r in restaurants],
        "orders": [{"id": o.id, "status": o.status, "user_id": o.user_id} for o in orders],
        "posts": [{"id": p.id, "post_type": p.post_type, "title": p.title} for p in posts],
        "reviews": [{"id": r.id, "rating": r.rating, "body": (r.comment or "")[:120]} for r in reviews],
    }


def build_admin_notifications(db: Session, *, limit: int = 20) -> list[dict]:
    notifications: list[dict] = []
    pending_biz = (
        db.query(User)
        .filter(User.account_status == PENDING)
        .filter(User.role.in_((RESTAURANT, HOME_CHEF)))
        .order_by(User.created_at.desc())
        .limit(5)
        .all()
    )
    for u in pending_biz:
        notifications.append(
            {
                "type": "business_registration",
                "title": f"New {normalize_role(u.role)} registration",
                "subtitle": u.full_name or u.email,
                "created_at": u.created_at.isoformat() if u.created_at else None,
                "reference_id": u.id,
            }
        )

    failed = (
        db.query(Review)
        .filter(Review.processing_status == "failed")
        .order_by(Review.created_at.desc())
        .limit(5)
        .all()
    )
    for r in failed:
        notifications.append(
            {
                "type": "review_failed",
                "title": "Review processing failed",
                "subtitle": f"Review #{r.id}",
                "created_at": r.created_at.isoformat() if r.created_at else None,
                "reference_id": r.id,
            }
        )

    if (
        db.query(func.count(RecommendationEvent.id))
        .filter(RecommendationEvent.created_at >= datetime.now(timezone.utc) - timedelta(hours=24))
        .scalar()
        or 0
    ) == 0:
        notifications.append(
            {
                "type": "recommendation_idle",
                "title": "No recommendation events in 24h",
                "subtitle": "Hybrid engine may need traffic or monitoring",
                "created_at": datetime.now(timezone.utc).isoformat(),
                "reference_id": None,
            }
        )

    notifications.sort(key=lambda n: n.get("created_at") or "", reverse=True)
    return notifications[:limit]


def build_platform_health(db: Session) -> dict:
    try:
        db.query(User.id).limit(1).all()
        db_status = "connected"
    except Exception:
        db_status = "unavailable"

    rec_total = db.query(func.count(RecommendationEvent.id)).scalar() or 0
    return {
        "platform_version": "1.0.0",
        "database_status": db_status,
        "backend_status": "running",
        "recommendation_engine_status": "active" if rec_total >= 0 else "unknown",
        "recommendation_events_total": rec_total,
        "server_time": datetime.now(timezone.utc).isoformat(),
    }
