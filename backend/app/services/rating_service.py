"""Aggregate restaurant ratings from reviews."""

from sqlalchemy import func
from sqlalchemy.orm import Session

from app.models.restaurant import Restaurant
from app.models.review import Review


def refresh_restaurant_rating(db: Session, restaurant_id: int) -> Restaurant:
    """
    Recompute average_rating and total_reviews from review rows.
    """
    stats = (
        db.query(
            func.coalesce(func.avg(Review.rating), 0.0),
            func.count(Review.id),
        )
        .filter(Review.restaurant_id == restaurant_id)
        .one()
    )
    average, total = stats
    restaurant = db.query(Restaurant).filter(Restaurant.id == restaurant_id).first()
    if not restaurant:
        return None  # type: ignore[return-value]

    restaurant.average_rating = round(float(average), 2)
    restaurant.total_reviews = int(total)
    db.add(restaurant)
    db.flush()
    return restaurant
