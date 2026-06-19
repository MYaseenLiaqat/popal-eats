"""Dish CRUD with pagination, filtering, owner RBAC, and image upload."""

import uuid
from decimal import Decimal
from pathlib import Path

from fastapi import APIRouter, Depends, File, HTTPException, Query, UploadFile, status
from sqlalchemy.orm import Session

from app.config import MAX_UPLOAD_MB, UPLOAD_DIR
from app.core.dependencies import get_current_user, get_optional_current_user
from app.core.permissions import (
    assert_dish_owner,
    assert_restaurant_owner,
    get_dish_or_404,
    get_restaurant_or_404,
)
from app.core.restaurant_constants import APPROVED
from app.core.roles import ADMIN, normalize_role
from app.database import get_db
from app.models.category import Category
from app.models.dish import Dish
from app.models.restaurant import Restaurant
from app.models.user import User
from app.schemas.dish import DishCreate, DishResponse, DishUpdate
from app.schemas.pagination import PaginatedResponse
from app.utils.pagination import apply_sort, build_paginated_response, paginate_query

router = APIRouter(prefix="/dishes", tags=["dishes"])

DISH_IMAGE_EXTENSIONS = {".jpg", ".jpeg", ".png", ".webp"}


def _validate_category_exists(db: Session, category_id: int) -> Category:
    category = db.query(Category).filter(Category.id == category_id).first()
    if not category:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Category id {category_id} not found. Create one with POST /categories first.",
        )
    return category


def _dish_visible_to_public(dish: Dish) -> bool:
    restaurant = dish.restaurant
    if restaurant is None:
        return False
    return restaurant.approval_status == APPROVED


def _public_dish_url(relative_path: str) -> str:
    return f"/uploads/{relative_path.replace(chr(92), '/')}"


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
    current_user: User | None = Depends(get_optional_current_user),
):
    query = db.query(Dish).join(Dish.restaurant)

    role = normalize_role(current_user.role) if current_user else None
    owner_filter = False
    if restaurant_id is not None and current_user is not None:
        restaurant = get_restaurant_or_404(db, restaurant_id)
        if role == ADMIN or restaurant.owner_id == current_user.id:
            owner_filter = True

    if not owner_filter:
        query = query.filter(Restaurant.approval_status == APPROVED)

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
def get_dish(
    dish_id: int,
    db: Session = Depends(get_db),
    current_user: User | None = Depends(get_optional_current_user),
):
    dish = get_dish_or_404(db, dish_id)
    if _dish_visible_to_public(dish):
        return dish

    if current_user is None:
        raise HTTPException(status_code=404, detail="Dish not found")

    restaurant = get_restaurant_or_404(db, dish.restaurant_id)
    role = normalize_role(current_user.role)
    if role == ADMIN or restaurant.owner_id == current_user.id:
        return dish
    raise HTTPException(status_code=404, detail="Dish not found")


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


@router.post("/{dish_id}/image", response_model=DishResponse, summary="Upload dish image")
async def upload_dish_image(
    dish_id: int,
    file: UploadFile = File(...),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    dish = get_dish_or_404(db, dish_id)
    assert_dish_owner(dish, current_user, db)

    suffix = Path(file.filename or "").suffix.lower()
    if suffix not in DISH_IMAGE_EXTENSIONS:
        raise HTTPException(
            status_code=400,
            detail=f"Allowed types: {', '.join(sorted(DISH_IMAGE_EXTENSIONS))}",
        )

    content = await file.read()
    if len(content) > MAX_UPLOAD_MB * 1024 * 1024:
        raise HTTPException(status_code=400, detail=f"Max {MAX_UPLOAD_MB}MB")

    dish_dir = UPLOAD_DIR / "dishes"
    dish_dir.mkdir(parents=True, exist_ok=True)
    filename = f"{dish_id}_{uuid.uuid4().hex}{suffix}"
    dest = dish_dir / filename
    dest.write_bytes(content)

    public_url = _public_dish_url(f"dishes/{filename}")
    dish.image = public_url
    images = list(dish.images or [])
    if public_url not in images:
        images.append(public_url)
    dish.images = images

    db.commit()
    db.refresh(dish)
    return dish
