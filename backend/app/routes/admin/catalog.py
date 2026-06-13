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


@router.post("/infer-restaurants")
def infer_restaurant_tags(
    dry_run: bool = Query(False, description="Compute inference without persisting"),
    source: str = Query("foodpanda", description="Restaurant source filter"),
    limit: int | None = Query(None, ge=1, description="Max untagged restaurants to infer"),
    db: Session = Depends(get_db),
    _: User = Depends(require_admin),
):
    """
    Infer restaurant tags from menu composition for restaurants missing primary metadata.

    Uses dish names, categories, and dominant cuisine signals with confidence scores.
    """
    service = CatalogEnrichmentService()
    stats = service.infer_untagged_restaurant_tags(
        db, dry_run=dry_run, source=source, limit=limit
    )
    return stats.to_dict()


@router.get("/inference-report")
def catalog_inference_report(
    db: Session = Depends(get_db),
    _: User = Depends(require_admin),
):
    """Project restaurant tag inference outcomes without persisting changes."""
    service = CatalogEnrichmentService()
    return service.inference_validation_report(db)
