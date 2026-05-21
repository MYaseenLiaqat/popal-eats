"""
Reusable ownership checks for restaurants and dishes.

Only the restaurant owner (user who created it) may update/delete the restaurant
or manage its dishes.
"""

from fastapi import HTTPException, status
from sqlalchemy.orm import Session

from app.models.dish import Dish
from app.models.restaurant import Restaurant
from app.models.user import User


def get_restaurant_or_404(db: Session, restaurant_id: int) -> Restaurant:
    """Load a restaurant by id or return 404."""
    restaurant = db.query(Restaurant).filter(Restaurant.id == restaurant_id).first()
    if not restaurant:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Restaurant not found",
        )
    return restaurant


def assert_restaurant_owner(restaurant: Restaurant, current_user: User) -> None:
    """Raise 403 if the logged-in user is not the restaurant owner."""
    if restaurant.owner_id != current_user.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="You do not have permission to modify this restaurant",
        )


def get_dish_or_404(db: Session, dish_id: int) -> Dish:
    """Load a dish by id or return 404."""
    dish = db.query(Dish).filter(Dish.id == dish_id).first()
    if not dish:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Dish not found",
        )
    return dish


def assert_dish_owner(dish: Dish, current_user: User, db: Session) -> None:
    """Raise 403 if the user does not own the restaurant that owns this dish."""
    restaurant = get_restaurant_or_404(db, dish.restaurant_id)
    assert_restaurant_owner(restaurant, current_user)
