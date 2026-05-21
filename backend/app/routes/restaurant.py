"""
Restaurant CRUD routes.

Create: logged-in user becomes owner (owner_id = current_user.id).
Update/Delete: only the owner.
List/Detail: public (browse restaurants).
"""

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.core.dependencies import get_current_user
from app.core.permissions import assert_restaurant_owner, get_restaurant_or_404
from app.database import get_db
from app.models.restaurant import Restaurant
from app.models.user import User
from app.schemas.restaurant import (
    RestaurantCreate,
    RestaurantResponse,
    RestaurantUpdate,
)

router = APIRouter(prefix="/restaurants", tags=["restaurants"])


@router.post(
    "",
    response_model=RestaurantResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Create a restaurant (authenticated — you become owner)",
)
def create_restaurant(
    body: RestaurantCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    restaurant = Restaurant(owner_id=current_user.id, **body.model_dump())
    db.add(restaurant)
    db.commit()
    db.refresh(restaurant)
    return restaurant


@router.get("", response_model=list[RestaurantResponse], summary="List restaurants")
def list_restaurants(
    skip: int = 0,
    limit: int = 100,
    city: str | None = None,
    db: Session = Depends(get_db),
):
    query = db.query(Restaurant)
    if city:
        query = query.filter(Restaurant.city.ilike(f"%{city}%"))
    return query.offset(skip).limit(limit).all()


@router.get("/{restaurant_id}", response_model=RestaurantResponse, summary="Get restaurant by id")
def get_restaurant(restaurant_id: int, db: Session = Depends(get_db)):
    return get_restaurant_or_404(db, restaurant_id)


@router.put(
    "/{restaurant_id}",
    response_model=RestaurantResponse,
    summary="Update restaurant (owner only)",
)
def update_restaurant(
    restaurant_id: int,
    body: RestaurantUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    restaurant = get_restaurant_or_404(db, restaurant_id)
    assert_restaurant_owner(restaurant, current_user)

    for key, value in body.model_dump(exclude_unset=True).items():
        setattr(restaurant, key, value)

    db.commit()
    db.refresh(restaurant)
    return restaurant


@router.delete(
    "/{restaurant_id}",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Delete restaurant (owner only)",
)
def delete_restaurant(
    restaurant_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    restaurant = get_restaurant_or_404(db, restaurant_id)
    assert_restaurant_owner(restaurant, current_user)
    db.delete(restaurant)
    db.commit()
    return None
