"""Admin notification feed."""

from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session

from app.core.rbac import require_admin
from app.database import get_db
from app.models.user import User
from app.services.admin_platform_service import build_admin_notifications

router = APIRouter(prefix="/notifications", tags=["admin-notifications"])


@router.get("")
def admin_notifications(
    limit: int = Query(20, ge=1, le=50),
    db: Session = Depends(get_db),
    _: User = Depends(require_admin),
):
    return {"items": build_admin_notifications(db, limit=limit)}
