"""Admin analytics endpoints."""

from fastapi import APIRouter, Depends
from sqlalchemy import func
from sqlalchemy.orm import Session

from app.core.rbac import require_admin
from app.database import get_db
from app.models.dish import Dish
from app.models.menu_upload import MenuUpload
from app.models.restaurant import Restaurant
from app.models.review import Review
from app.models.user import User  # noqa: F401 — used by Depends

router = APIRouter(prefix="/analytics", tags=["admin-analytics"])


@router.get("/overview")
def analytics_overview(
    db: Session = Depends(get_db),
    _: User = Depends(require_admin),
):
    return {
        "users": db.query(func.count(User.id)).scalar() or 0,
        "restaurants": db.query(func.count(Restaurant.id)).scalar() or 0,
        "dishes": db.query(func.count(Dish.id)).scalar() or 0,
        "reviews": db.query(func.count(Review.id)).scalar() or 0,
        "reviews_pending_processing": db.query(func.count(Review.id))
        .filter(Review.processing_status == "pending")
        .scalar()
        or 0,
        "reviews_failed_processing": db.query(func.count(Review.id))
        .filter(Review.processing_status == "failed")
        .scalar()
        or 0,
        "menu_uploads": db.query(func.count(MenuUpload.id)).scalar() or 0,
        "sentiment_breakdown": [
            {"sentiment": row[0], "count": row[1]}
            for row in db.query(Review.sentiment, func.count(Review.id))
            .filter(Review.sentiment.isnot(None))
            .group_by(Review.sentiment)
            .all()
        ],
    }
