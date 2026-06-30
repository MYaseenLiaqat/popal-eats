"""Admin order management."""

from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session

from app.core.rbac import require_admin
from app.database import get_db
from app.models.user import User
from app.services.admin_platform_service import list_admin_orders
from app.utils.pagination import build_paginated_response

router = APIRouter(prefix="/orders", tags=["admin-orders"])


@router.get("")
def admin_list_orders(
    page: int = Query(1, ge=1),
    limit: int = Query(20, ge=1, le=100),
    status: str | None = None,
    search: str | None = None,
    db: Session = Depends(get_db),
    _: User = Depends(require_admin),
):
    items, total = list_admin_orders(db, page=page, limit=limit, status=status, search=search)
    return build_paginated_response(items, page=page, limit=limit, total_count=total)
