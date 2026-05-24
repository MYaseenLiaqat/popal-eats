"""
Category CRUD routes.

List/detail are public; create/update/delete require JWT (any authenticated user in dev).
TODO(production): restore require_admin on POST, PUT, DELETE category endpoints.
"""

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.orm import Session

from app.core.dependencies import get_current_user
from app.database import get_db
from app.models.category import Category
from app.models.dish import Dish
from app.models.user import User
from app.schemas.category import CategoryCreate, CategoryResponse, CategoryUpdate
from app.schemas.pagination import PaginatedResponse
from app.utils.pagination import apply_sort, build_paginated_response, paginate_query

router = APIRouter(prefix="/categories", tags=["categories"])


@router.post(
    "",
    response_model=CategoryResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Create a category (authenticated — dev)",
)
def create_category(
    body: CategoryCreate,
    db: Session = Depends(get_db),
    # TODO(production): replace with Depends(require_admin)
    current_user: User = Depends(get_current_user),
):
    if db.query(Category).filter(Category.name == body.name).first():
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Category name already exists",
        )
    category = Category(**body.model_dump())
    db.add(category)
    db.commit()
    db.refresh(category)
    return category


@router.get("", response_model=PaginatedResponse[CategoryResponse], summary="List categories")
def list_categories(
    page: int = Query(1, ge=1),
    limit: int = Query(20, ge=1, le=100),
    search: str | None = Query(None, description="Search by name"),
    sort: str | None = Query(None, description="asc or desc by name"),
    db: Session = Depends(get_db),
):
    query = db.query(Category)
    if search:
        query = query.filter(Category.name.ilike(f"%{search}%"))
    query = apply_sort(query, Category.name, sort, default_desc=False)
    items, total = paginate_query(query, page=page, limit=limit)
    return build_paginated_response(items, page=page, limit=limit, total_count=total)


@router.get("/{category_id}", response_model=CategoryResponse)
def get_category(category_id: int, db: Session = Depends(get_db)):
    category = db.query(Category).filter(Category.id == category_id).first()
    if not category:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Category not found")
    return category


@router.put(
    "/{category_id}",
    response_model=CategoryResponse,
    summary="Update category (authenticated — dev)",
)
def update_category(
    category_id: int,
    body: CategoryUpdate,
    db: Session = Depends(get_db),
    # TODO(production): replace with Depends(require_admin)
    current_user: User = Depends(get_current_user),
):
    category = db.query(Category).filter(Category.id == category_id).first()
    if not category:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Category not found")

    data = body.model_dump(exclude_unset=True)
    if "name" in data and data["name"] != category.name:
        if db.query(Category).filter(Category.name == data["name"]).first():
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Category name already exists",
            )

    for key, value in data.items():
        setattr(category, key, value)

    db.commit()
    db.refresh(category)
    return category


@router.delete(
    "/{category_id}",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Delete category (authenticated — dev)",
)
def delete_category(
    category_id: int,
    db: Session = Depends(get_db),
    # TODO(production): replace with Depends(require_admin)
    current_user: User = Depends(get_current_user),
):
    category = db.query(Category).filter(Category.id == category_id).first()
    if not category:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Category not found")

    if db.query(Dish).filter(Dish.category_id == category_id).first():
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Cannot delete category that has dishes. Remove dishes first.",
        )

    db.delete(category)
    db.commit()
    return None
