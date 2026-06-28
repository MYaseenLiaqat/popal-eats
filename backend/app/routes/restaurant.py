"""Restaurant CRUD with RBAC, approval workflow, and owner dashboard."""

import uuid
from pathlib import Path

from fastapi import APIRouter, Depends, File, HTTPException, Query, UploadFile, status
from sqlalchemy.orm import Session

from app.config import MAX_UPLOAD_MB, UPLOAD_DIR
from app.core.content_constants import CONTENT_IMAGE_EXTENSIONS
from app.core.dependencies import get_current_user, get_optional_current_user
from app.core.rbac import promote_to_restaurant_owner, require_restaurant
from app.core.roles import ADMIN, CUSTOMER, RESTAURANT, is_restaurant_role, normalize_role
from app.core.permissions import assert_restaurant_owner, get_restaurant_or_404
from app.core.restaurant_constants import APPROVED, PENDING
from app.database import get_db
from app.models.post import Post
from app.models.restaurant import Restaurant
from app.models.user import User
from app.schemas.content import PostListResponse, PostResponse
from app.schemas.pagination import PaginatedResponse
from app.schemas.restaurant import (
    RestaurantCreate,
    RestaurantDashboardResponse,
    RestaurantResponse,
    RestaurantUpdate,
)
from app.services.restaurant_dashboard_service import build_restaurant_dashboard
from app.utils.pagination import apply_sort, build_paginated_response, paginate_query

router = APIRouter(prefix="/restaurants", tags=["restaurants"])


def _public_restaurant_url(relative_path: str) -> str:
    return f"/uploads/{relative_path.replace(chr(92), '/')}"


def _can_view_restaurant(restaurant: Restaurant, user: User | None) -> bool:
    if restaurant.approval_status == APPROVED:
        return True
    if user is None:
        return False
    role = normalize_role(user.role)
    if role == ADMIN:
        return True
    return restaurant.owner_id == user.id


@router.post(
    "",
    response_model=RestaurantResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Create restaurant (restaurant_owner or admin)",
)
def create_restaurant(
    body: RestaurantCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    role = normalize_role(current_user.role)
    if role not in (ADMIN, CUSTOMER) and not is_restaurant_role(current_user.role):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only customers, restaurant owners, or admins can create restaurants",
        )
    if role == CUSTOMER:
        promote_to_restaurant_owner(current_user)

    approval_status = APPROVED if role == ADMIN else PENDING
    restaurant = Restaurant(
        owner_id=current_user.id,
        approval_status=approval_status,
        **body.model_dump(),
    )
    db.add(restaurant)
    db.add(current_user)
    db.commit()
    db.refresh(restaurant)
    return restaurant


@router.get("/mine", response_model=PaginatedResponse[RestaurantResponse], summary="My restaurants")
def list_my_restaurants(
    page: int = Query(1, ge=1),
    limit: int = Query(20, ge=1, le=100),
    db: Session = Depends(get_db),
    current_user: User = Depends(require_restaurant),
):
    query = (
        db.query(Restaurant)
        .filter(Restaurant.owner_id == current_user.id)
        .order_by(Restaurant.created_at.desc())
    )
    items, total = paginate_query(query, page=page, limit=limit)
    return build_paginated_response(items, page=page, limit=limit, total_count=total)


@router.get("", response_model=PaginatedResponse[RestaurantResponse], summary="List restaurants")
def list_restaurants(
    page: int = Query(1, ge=1),
    limit: int = Query(20, ge=1, le=100),
    search: str | None = Query(None, description="Search name, city, or address"),
    city: str | None = None,
    is_open: bool | None = None,
    min_rating: float | None = Query(None, ge=0, le=5),
    sort: str | None = Query(None, description="asc or desc by average_rating"),
    db: Session = Depends(get_db),
):
    query = db.query(Restaurant).filter(
        Restaurant.approval_status == APPROVED,
        (Restaurant.source.is_(None)) | (Restaurant.source != "home_chef"),
    )
    if search:
        pattern = f"%{search}%"
        query = query.filter(
            (Restaurant.name.ilike(pattern))
            | (Restaurant.city.ilike(pattern))
            | (Restaurant.address.ilike(pattern))
        )
    if city:
        query = query.filter(Restaurant.city.ilike(f"%{city}%"))
    if is_open is not None:
        query = query.filter(Restaurant.is_open == is_open)
    if min_rating is not None:
        query = query.filter(Restaurant.average_rating >= min_rating)

    query = apply_sort(query, Restaurant.average_rating, sort)
    items, total = paginate_query(query, page=page, limit=limit)
    return build_paginated_response(items, page=page, limit=limit, total_count=total)


@router.get("/{restaurant_id}", response_model=RestaurantResponse)
def get_restaurant(
    restaurant_id: int,
    db: Session = Depends(get_db),
    current_user: User | None = Depends(get_optional_current_user),
):
    restaurant = get_restaurant_or_404(db, restaurant_id)
    if not _can_view_restaurant(restaurant, current_user):
        raise HTTPException(status_code=404, detail="Restaurant not found")
    return restaurant


@router.get(
    "/{restaurant_id}/dashboard",
    response_model=RestaurantDashboardResponse,
    summary="Owner dashboard metrics",
)
def get_restaurant_dashboard(
    restaurant_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_restaurant),
):
    restaurant = get_restaurant_or_404(db, restaurant_id)
    assert_restaurant_owner(restaurant, current_user)
    return build_restaurant_dashboard(db, restaurant)


@router.get(
    "/{restaurant_id}/analytics",
    response_model=RestaurantDashboardResponse,
    summary="Owner analytics (same metrics as dashboard)",
)
def get_restaurant_analytics(
    restaurant_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_restaurant),
):
    restaurant = get_restaurant_or_404(db, restaurant_id)
    assert_restaurant_owner(restaurant, current_user)
    return build_restaurant_dashboard(db, restaurant)


@router.get(
    "/{restaurant_id}/posts",
    response_model=PostListResponse,
    summary="List restaurant content posts (owner only)",
)
def list_restaurant_posts(
    restaurant_id: int,
    page: int = Query(1, ge=1),
    limit: int = Query(20, ge=1, le=100),
    db: Session = Depends(get_db),
    current_user: User = Depends(require_restaurant),
):
    restaurant = get_restaurant_or_404(db, restaurant_id)
    assert_restaurant_owner(restaurant, current_user)
    query = (
        db.query(Post)
        .filter(Post.restaurant_id == restaurant_id)
        .order_by(Post.created_at.desc())
    )
    items, total = paginate_query(query, page=page, limit=limit)
    return PostListResponse(
        items=[PostResponse.model_validate(p) for p in items],
        page=page,
        limit=limit,
        total_count=total,
    )


@router.post(
    "/{restaurant_id}/image",
    response_model=RestaurantResponse,
    summary="Upload restaurant logo or cover image",
)
async def upload_restaurant_image(
    restaurant_id: int,
    file: UploadFile = File(...),
    db: Session = Depends(get_db),
    current_user: User = Depends(require_restaurant),
):
    restaurant = get_restaurant_or_404(db, restaurant_id)
    assert_restaurant_owner(restaurant, current_user)

    suffix = Path(file.filename or "").suffix.lower()
    if suffix not in CONTENT_IMAGE_EXTENSIONS:
        raise HTTPException(
            status_code=400,
            detail=f"Allowed types: {', '.join(sorted(CONTENT_IMAGE_EXTENSIONS))}",
        )

    content = await file.read()
    if len(content) > MAX_UPLOAD_MB * 1024 * 1024:
        raise HTTPException(status_code=400, detail=f"Max {MAX_UPLOAD_MB}MB")

    image_dir = UPLOAD_DIR / "restaurants"
    image_dir.mkdir(parents=True, exist_ok=True)
    filename = f"{restaurant_id}_{uuid.uuid4().hex}{suffix}"
    dest = image_dir / filename
    dest.write_bytes(content)

    restaurant.image = _public_restaurant_url(f"restaurants/{filename}")
    db.commit()
    db.refresh(restaurant)
    return restaurant


@router.put("/{restaurant_id}", response_model=RestaurantResponse, summary="Update (owner/admin)")
def update_restaurant(
    restaurant_id: int,
    body: RestaurantUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_restaurant),
):
    restaurant = get_restaurant_or_404(db, restaurant_id)
    assert_restaurant_owner(restaurant, current_user)

    for key, value in body.model_dump(exclude_unset=True).items():
        setattr(restaurant, key, value)

    db.commit()
    db.refresh(restaurant)
    return restaurant


@router.delete("/{restaurant_id}", status_code=status.HTTP_204_NO_CONTENT, summary="Delete (owner/admin)")
def delete_restaurant(
    restaurant_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_restaurant),
):
    restaurant = get_restaurant_or_404(db, restaurant_id)
    assert_restaurant_owner(restaurant, current_user)
    db.delete(restaurant)
    db.commit()
    return None
