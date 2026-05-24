"""Dish CRUD with pagination, filtering, and owner RBAC."""

from decimal import Decimal

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.orm import Session

from app.core.dependencies import get_current_user
from app.core.permissions import (
    assert_dish_owner,
    assert_restaurant_owner,
    get_dish_or_404,
    get_restaurant_or_404,
)
from app.database import get_db
from app.models.category import Category
from app.models.dish import Dish
from app.models.user import User
from app.schemas.dish import DishCreate, DishResponse, DishUpdate
from app.schemas.pagination import PaginatedResponse
from app.utils.pagination import apply_sort, build_paginated_response, paginate_query

router = APIRouter(prefix="/dishes", tags=["dishes"])


def _validate_category_exists(db: Session, category_id: int) -> Category:
    category = db.query(Category).filter(Category.id == category_id).first()
    if not category:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Category id {category_id} not found. Create one with POST /categories first.",
        )
    return category


@router.post("", response_model=DishResponse, status_code=status.HTTP_201_CREATED)
def create_dish(
    body: DishCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    restaurant = get_restaurant_or_404(db, body.restaurant_id)
    assert_restaurant_owner(restaurant, current_user)
    _validate_category_exists(db, body.category_id)

    dish = Dish(**body.model_dump())
    db.add(dish)
    db.commit()
    db.refresh(dish)
    return dish


@router.get("", response_model=PaginatedResponse[DishResponse], summary="List dishes")
def list_dishes(
    page: int = Query(1, ge=1),
    limit: int = Query(20, ge=1, le=100),
    search: str | None = Query(None, description="Search dish name"),
    restaurant_id: int | None = None,
    category_id: int | None = None,
    is_available: bool | None = None,
    min_price: Decimal | None = Query(None, ge=0),
    max_price: Decimal | None = Query(None, ge=0),
    sort: str | None = Query(None, description="asc or desc by price"),
    db: Session = Depends(get_db),
):
    query = db.query(Dish)
    if search:
        query = query.filter(Dish.name.ilike(f"%{search}%"))
    if restaurant_id is not None:
        query = query.filter(Dish.restaurant_id == restaurant_id)
    if category_id is not None:
        query = query.filter(Dish.category_id == category_id)
    if is_available is not None:
        query = query.filter(Dish.is_available == is_available)
    if min_price is not None:
        query = query.filter(Dish.price >= min_price)
    if max_price is not None:
        query = query.filter(Dish.price <= max_price)

    query = apply_sort(query, Dish.price, sort)
    items, total = paginate_query(query, page=page, limit=limit)
    return build_paginated_response(items, page=page, limit=limit, total_count=total)


@router.get("/{dish_id}", response_model=DishResponse)
def get_dish(dish_id: int, db: Session = Depends(get_db)):
    return get_dish_or_404(db, dish_id)


@router.put("/{dish_id}", response_model=DishResponse)
def update_dish(
    dish_id: int,
    body: DishUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    dish = get_dish_or_404(db, dish_id)
    assert_dish_owner(dish, current_user, db)

    data = body.model_dump(exclude_unset=True)
    if "category_id" in data:
        _validate_category_exists(db, data["category_id"])

    for key, value in data.items():
        setattr(dish, key, value)

    db.commit()
    db.refresh(dish)
    return dish


@router.delete("/{dish_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_dish(
    dish_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    dish = get_dish_or_404(db, dish_id)
    assert_dish_owner(dish, current_user, db)
    db.delete(dish)
    db.commit()
    return None
