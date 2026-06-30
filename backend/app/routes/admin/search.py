"""Admin global search."""

from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session

from app.core.rbac import require_admin
from app.database import get_db
from app.models.user import User
from app.services.admin_platform_service import admin_global_search

router = APIRouter(prefix="/search", tags=["admin-search"])


@router.get("")
def admin_search(
    q: str = Query(..., min_length=2),
    limit: int = Query(10, ge=1, le=30),
    db: Session = Depends(get_db),
    _: User = Depends(require_admin),
):
    return admin_global_search(db, q, limit=limit)
