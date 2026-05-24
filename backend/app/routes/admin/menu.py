"""Admin menu upload management."""

from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session

from app.core.rbac import require_admin
from app.database import get_db
from app.models.menu_upload import MenuUpload
from app.models.user import User
from app.schemas.menu import MenuUploadResponse
from app.schemas.pagination import PaginatedResponse
from app.utils.pagination import build_paginated_response, paginate_query

router = APIRouter(prefix="/menu", tags=["admin-menu"])


@router.get("/uploads", response_model=PaginatedResponse[MenuUploadResponse])
def admin_list_uploads(
    page: int = Query(1, ge=1),
    limit: int = Query(20, ge=1, le=100),
    status: str | None = None,
    db: Session = Depends(get_db),
    _: User = Depends(require_admin),
):
    query = db.query(MenuUpload).order_by(MenuUpload.created_at.desc())
    if status:
        query = query.filter(MenuUpload.status == status)
    items, total = paginate_query(query, page=page, limit=limit)
    return build_paginated_response(items, page=page, limit=limit, total_count=total)
