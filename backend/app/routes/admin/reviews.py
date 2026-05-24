"""Admin review moderation."""

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session

from app.core.rbac import require_admin
from app.database import get_db
from app.models.review import Review
from app.models.user import User
from app.schemas.pagination import PaginatedResponse
from app.schemas.review import ReviewResponse
from app.services.review_processing import review_processing_service
from app.utils.pagination import build_paginated_response, paginate_query

router = APIRouter(prefix="/reviews", tags=["admin-reviews"])


@router.get("", response_model=PaginatedResponse[ReviewResponse])
def admin_list_reviews(
    page: int = Query(1, ge=1),
    limit: int = Query(20, ge=1, le=100),
    processing_status: str | None = None,
    db: Session = Depends(get_db),
    _: User = Depends(require_admin),
):
    query = db.query(Review).order_by(Review.created_at.desc())
    if processing_status:
        query = query.filter(Review.processing_status == processing_status)
    items, total = paginate_query(query, page=page, limit=limit)
    return build_paginated_response(items, page=page, limit=limit, total_count=total)


@router.delete("/{review_id}", status_code=204)
def admin_delete_review(
    review_id: int,
    db: Session = Depends(get_db),
    _: User = Depends(require_admin),
):
    review = db.query(Review).filter(Review.id == review_id).first()
    if not review:
        raise HTTPException(status_code=404, detail="Review not found")
    restaurant_id = review.restaurant_id
    db.delete(review)
    db.commit()
    from app.services.rating_service import refresh_restaurant_rating

    refresh_restaurant_rating(db, restaurant_id)
    db.commit()
    return None


@router.post("/{review_id}/reprocess")
def admin_reprocess_review(
    review_id: int,
    db: Session = Depends(get_db),
    _: User = Depends(require_admin),
):
    review = db.query(Review).filter(Review.id == review_id).first()
    if not review:
        raise HTTPException(status_code=404, detail="Review not found")
    review.processing_status = "pending"
    db.commit()
    job_id = review_processing_service.enqueue_analysis(review_id)
    return {"review_id": review_id, "job_id": job_id, "status": "queued"}
