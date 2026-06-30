"""Admin analytics endpoints."""

from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.core.rbac import require_admin
from app.database import get_db
from app.models.user import User
from app.services.admin_platform_service import build_platform_overview, build_platform_health

router = APIRouter(prefix="/analytics", tags=["admin-analytics"])


@router.get("/overview")
def analytics_overview(
    db: Session = Depends(get_db),
    _: User = Depends(require_admin),
):
    """Full platform overview — KPIs, time series, recommendations, top entities."""
    return build_platform_overview(db)


@router.get("/health")
def platform_health(
    db: Session = Depends(get_db),
    _: User = Depends(require_admin),
):
    return build_platform_health(db)
