"""
Reusable ownership checks for restaurants, dishes, and reviews.
"""

from fastapi import HTTPException, status
from sqlalchemy.orm import Session

from app.core.rbac import assert_restaurant_owner_or_admin
from app.models.dish import Dish
from app.models.restaurant import Restaurant
from app.models.review import Review
from app.models.user import User


def get_restaurant_or_404(db: Session, restaurant_id: int) -> Restaurant:
    restaurant = db.query(Restaurant).filter(Restaurant.id == restaurant_id).first()
    if not restaurant:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Restaurant id {restaurant_id} not found. Create one with POST /restaurants first.",
        )
    return restaurant


def assert_restaurant_owner(restaurant: Restaurant, current_user: User) -> None:
    assert_restaurant_owner_or_admin(restaurant, current_user)


def get_dish_or_404(db: Session, dish_id: int) -> Dish:
    dish = db.query(Dish).filter(Dish.id == dish_id).first()
    if not dish:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Dish not found",
        )
    return dish


def assert_dish_owner(dish: Dish, current_user: User, db: Session) -> None:
    restaurant = get_restaurant_or_404(db, dish.restaurant_id)
    assert_restaurant_owner(restaurant, current_user)


def get_review_or_404(db: Session, review_id: int) -> Review:
    review = db.query(Review).filter(Review.id == review_id).first()
    if not review:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Review not found",
        )
    return review


def assert_review_owner(review: Review, current_user: User) -> None:
    if review.user_id != current_user.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="You do not have permission to modify this review",
        )
