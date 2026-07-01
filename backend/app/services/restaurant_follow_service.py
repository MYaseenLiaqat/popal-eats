"""Follow / unfollow restaurants and list followed accounts."""

from fastapi import HTTPException, status
from sqlalchemy.orm import Session

from app.core.restaurant_constants import APPROVED
from app.models.restaurant import Restaurant
from app.models.restaurant_follow import RestaurantFollow
from app.schemas.restaurant import RestaurantFollowListResponse, RestaurantResponse


def followed_restaurant_ids(db: Session, user_id: int) -> set[int]:
    rows = (
        db.query(RestaurantFollow.restaurant_id)
        .filter(RestaurantFollow.user_id == user_id)
        .all()
    )
    return {row[0] for row in rows}


def list_followed_restaurants(db: Session, user_id: int) -> RestaurantFollowListResponse:
    rows = (
        db.query(Restaurant)
        .join(RestaurantFollow, RestaurantFollow.restaurant_id == Restaurant.id)
        .filter(
            RestaurantFollow.user_id == user_id,
            Restaurant.approval_status == APPROVED,
        )
        .order_by(RestaurantFollow.created_at.desc())
        .all()
    )
    ids = [r.id for r in rows]
    return RestaurantFollowListResponse(
        restaurant_ids=ids,
        restaurants=[RestaurantResponse.model_validate(r) for r in rows],
        total=len(ids),
    )


def follow_restaurant(db: Session, user_id: int, restaurant_id: int) -> RestaurantFollowListResponse:
    restaurant = db.query(Restaurant).filter(Restaurant.id == restaurant_id).first()
    if restaurant is None or restaurant.approval_status != APPROVED:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Restaurant not found")

    existing = (
        db.query(RestaurantFollow)
        .filter(
            RestaurantFollow.user_id == user_id,
            RestaurantFollow.restaurant_id == restaurant_id,
        )
        .first()
    )
    if existing is None:
        db.add(RestaurantFollow(user_id=user_id, restaurant_id=restaurant_id))
        db.commit()

    return list_followed_restaurants(db, user_id)


def unfollow_restaurant(db: Session, user_id: int, restaurant_id: int) -> RestaurantFollowListResponse:
    row = (
        db.query(RestaurantFollow)
        .filter(
            RestaurantFollow.user_id == user_id,
            RestaurantFollow.restaurant_id == restaurant_id,
        )
        .first()
    )
    if row is not None:
        db.delete(row)
        db.commit()
    return list_followed_restaurants(db, user_id)
