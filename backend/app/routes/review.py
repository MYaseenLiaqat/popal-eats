"""Review CRUD with async AI processing queue."""

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session, joinedload

from app.core.dependencies import get_current_user
from app.core.permissions import assert_review_owner, get_restaurant_or_404, get_review_or_404
from app.core.rbac import require_reviewer
from app.database import get_db
from app.models.review import Review
from app.models.user import User
from app.schemas.pagination import PaginatedResponse
from app.schemas.review import (
    ReviewCreate,
    ReviewProcessingStatus,
    ReviewResponse,
    ReviewUpdate,
)
from app.services.rating_service import refresh_restaurant_rating
from app.services.review_processing import review_processing_service
from app.utils.pagination import apply_sort, build_paginated_response, paginate_query

router = APIRouter(prefix="/reviews", tags=["reviews"])
_processor = review_processing_service


def _review_to_response(review: Review) -> ReviewResponse:
    author = review.user
    return ReviewResponse(
        id=review.id,
        user_id=review.user_id,
        restaurant_id=review.restaurant_id,
        rating=review.rating,
        comment=review.comment,
        detected_language=review.detected_language,
        translated_text=review.translated_text,
        sentiment=review.sentiment,
        sentiment_score=review.sentiment_score,
        processing_status=review.processing_status,
        created_at=review.created_at,
        processed_at=review.processed_at,
        author_name=author.full_name if author else None,
        author_username=author.username if author else None,
    )


@router.post("", response_model=ReviewResponse, status_code=status.HTTP_201_CREATED)
def create_review(
    body: ReviewCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_reviewer),
):
    get_restaurant_or_404(db, body.restaurant_id)

    existing = (
        db.query(Review)
        .filter(
            Review.user_id == current_user.id,
            Review.restaurant_id == body.restaurant_id,
        )
        .first()
    )
    if existing:
        raise HTTPException(status_code=400, detail="You have already reviewed this restaurant")

    review = Review(
        user_id=current_user.id,
        restaurant_id=body.restaurant_id,
        rating=body.rating,
        comment=body.comment,
        processing_status="pending",
    )
    db.add(review)
    try:
        db.commit()
    except IntegrityError:
        db.rollback()
        raise HTTPException(status_code=400, detail="You have already reviewed this restaurant")
    db.refresh(review)
    refresh_restaurant_rating(db, body.restaurant_id)
    db.commit()

    _processor.enqueue_analysis(review.id, review.comment)
    review = (
        db.query(Review)
        .options(joinedload(Review.user))
        .filter(Review.id == review.id)
        .first()
    )
    return _review_to_response(review)


@router.get("", response_model=PaginatedResponse[ReviewResponse])
def list_reviews(
    page: int = Query(1, ge=1),
    limit: int = Query(20, ge=1, le=100),
    restaurant_id: int | None = None,
    user_id: int | None = None,
    processing_status: str | None = None,
    min_rating: int | None = Query(None, ge=1, le=5),
    max_rating: int | None = Query(None, ge=1, le=5),
    sort: str | None = None,
    db: Session = Depends(get_db),
):
    query = db.query(Review).options(joinedload(Review.user))
    if restaurant_id is not None:
        query = query.filter(Review.restaurant_id == restaurant_id)
    if user_id is not None:
        query = query.filter(Review.user_id == user_id)
    if processing_status:
        query = query.filter(Review.processing_status == processing_status)
    if min_rating is not None:
        query = query.filter(Review.rating >= min_rating)
    if max_rating is not None:
        query = query.filter(Review.rating <= max_rating)

    query = apply_sort(query, Review.created_at, sort)
    items, total = paginate_query(query, page=page, limit=limit)
    return build_paginated_response(
        [_review_to_response(item) for item in items],
        page=page,
        limit=limit,
        total_count=total,
    )


@router.get("/{review_id}", response_model=ReviewResponse)
def get_review(review_id: int, db: Session = Depends(get_db)):
    review = (
        db.query(Review)
        .options(joinedload(Review.user))
        .filter(Review.id == review_id)
        .first()
    )
    if review is None:
        get_review_or_404(db, review_id)
    return _review_to_response(review)


@router.get("/{review_id}/processing", response_model=ReviewProcessingStatus)
def get_review_processing(review_id: int, db: Session = Depends(get_db)):
    review = get_review_or_404(db, review_id)
    return ReviewProcessingStatus(
        review_id=review.id,
        processing_status=review.processing_status,
        detected_language=review.detected_language,
        sentiment=review.sentiment,
        sentiment_score=review.sentiment_score,
        processed_at=review.processed_at,
    )


@router.put("/{review_id}", response_model=ReviewResponse)
def update_review(
    review_id: int,
    body: ReviewUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    review = get_review_or_404(db, review_id)
    assert_review_owner(review, current_user)

    for key, value in body.model_dump(exclude_unset=True).items():
        setattr(review, key, value)
    review.processing_status = "pending"

    db.commit()
    db.refresh(review)
    refresh_restaurant_rating(db, review.restaurant_id)
    db.commit()

    _processor.enqueue_analysis(review.id, review.comment)
    review = (
        db.query(Review)
        .options(joinedload(Review.user))
        .filter(Review.id == review.id)
        .first()
    )
    return _review_to_response(review)


@router.delete("/{review_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_review(
    review_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    review = get_review_or_404(db, review_id)
    assert_review_owner(review, current_user)
    restaurant_id = review.restaurant_id
    db.delete(review)
    db.commit()
    refresh_restaurant_rating(db, restaurant_id)
    db.commit()
    return None
