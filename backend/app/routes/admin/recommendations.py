"""Admin recommendation inspection endpoints."""

from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session

from app.core.rbac import require_admin
from app.database import get_db
from app.models.user import User
from app.services.admin_platform_service import build_platform_overview
from app.services.recommendation.v2_catalog import get_recommendation_debug_snapshot

router = APIRouter(prefix="/recommendations", tags=["admin-recommendations"])


@router.get("/metrics")
def recommendations_metrics(
    db: Session = Depends(get_db),
    _: User = Depends(require_admin),
):
    data = build_platform_overview(db)
    return {
        "recommendations": data["recommendations"],
        "top_entities": data["top_entities"],
        "debug": get_recommendation_debug_snapshot(db, user_id=None),
    }


@router.get("/debug")
def recommendations_debug(
    db: Session = Depends(get_db),
    _: User = Depends(require_admin),
    user_id: int | None = Query(
        None,
        description="Optional user id for candidate pool stats (same filters as V2 engine)",
    ),
):
    """
    Catalog and candidate-pool snapshot for recommendation integration diagnostics.

    Includes Foodpanda import counts and eligible candidate totals.
    """
    return get_recommendation_debug_snapshot(db, user_id=user_id)
