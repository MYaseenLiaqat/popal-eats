"""Admin restaurant approval and moderation."""

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.orm import Session

from app.core.rbac import require_admin
from app.core.permissions import get_restaurant_or_404
from app.core.restaurant_constants import ALL_STATUSES, APPROVED, PENDING, REJECTED
from app.database import get_db
from app.models.restaurant import Restaurant
from app.models.user import User
from app.schemas.pagination import PaginatedResponse
from app.schemas.restaurant import RestaurantApprovalUpdate, RestaurantResponse
from app.utils.pagination import build_paginated_response, paginate_query

router = APIRouter(tags=["admin-restaurants"])


@router.get(
    "/restaurants",
    response_model=PaginatedResponse[RestaurantResponse],
    summary="List restaurants for admin moderation",
)
def list_restaurants_admin(
    page: int = Query(1, ge=1),
    limit: int = Query(20, ge=1, le=100),
    approval_status: str | None = Query(None, description="pending | approved | rejected"),
    db: Session = Depends(get_db),
    _: User = Depends(require_admin),
):
    query = db.query(Restaurant).order_by(Restaurant.created_at.desc())
    if approval_status:
        status_value = approval_status.strip().lower()
        if status_value not in ALL_STATUSES:
            raise HTTPException(status_code=400, detail="Invalid approval_status")
        query = query.filter(Restaurant.approval_status == status_value)

    items, total = paginate_query(query, page=page, limit=limit)
    return build_paginated_response(items, page=page, limit=limit, total_count=total)


@router.patch(
    "/restaurants/{restaurant_id}/approval",
    response_model=RestaurantResponse,
    summary="Approve or reject a restaurant",
)
def update_restaurant_approval(
    restaurant_id: int,
    body: RestaurantApprovalUpdate,
    db: Session = Depends(get_db),
    _: User = Depends(require_admin),
):
    restaurant = get_restaurant_or_404(db, restaurant_id)
    restaurant.approval_status = body.approval_status
    if body.approval_status == REJECTED:
        restaurant.rejection_reason = body.rejection_reason or "Rejected by admin"
    else:
        restaurant.rejection_reason = None
    db.commit()
    db.refresh(restaurant)
    return restaurant


@router.get(
    "/restaurants/pending/count",
    summary="Count of restaurants awaiting approval",
)
def pending_restaurant_count(
    db: Session = Depends(get_db),
    _: User = Depends(require_admin),
):
    count = (
        db.query(Restaurant).filter(Restaurant.approval_status == PENDING).count()
    )
    return {"pending_count": count}
