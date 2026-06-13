"""Admin catalog enrichment endpoints."""

from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session

from app.core.rbac import require_admin
from app.database import get_db
from app.models.user import User
from app.services.catalog_enrichment_service import CatalogEnrichmentService

router = APIRouter(prefix="/catalog", tags=["admin-catalog"])


@router.post("/enrich")
def enrich_catalog(
    dry_run: bool = Query(False, description="Compute changes without persisting"),
    source: str = Query("foodpanda", description="Restaurant/dish source filter"),
    limit: int | None = Query(None, ge=1, description="Max restaurants to enrich"),
    db: Session = Depends(get_db),
    _: User = Depends(require_admin),
):
    """
    Enrich restaurant and dish tags from cuisines, categories, names, and descriptions.

    Normalizes tags into a controlled taxonomy for recommendation matching.
    """
    service = CatalogEnrichmentService()
    stats = service.enrich(db, dry_run=dry_run, source=source, limit=limit)
    return stats.to_dict()
