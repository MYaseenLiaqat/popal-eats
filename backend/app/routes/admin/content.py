"""Admin content moderation."""

from fastapi import APIRouter, Depends, Query, status
from sqlalchemy.orm import Session

from app.core.rbac import require_admin
from app.database import get_db
from app.models.user import User
from app.services.admin_platform_service import list_admin_content, list_admin_stories
from app.services.content_service import delete_post
from app.utils.pagination import build_paginated_response

router = APIRouter(prefix="/content", tags=["admin-content"])


@router.get("/posts")
def admin_list_posts(
    content_type: str = Query("all", description="all|food_posts|recipes|reels|restaurant_posts|chef_posts"),
    page: int = Query(1, ge=1),
    limit: int = Query(20, ge=1, le=100),
    db: Session = Depends(get_db),
    _: User = Depends(require_admin),
):
    items, total = list_admin_content(db, content_type=content_type, page=page, limit=limit)
    return build_paginated_response(items, page=page, limit=limit, total_count=total)


@router.get("/stories")
def admin_list_stories(
    page: int = Query(1, ge=1),
    limit: int = Query(20, ge=1, le=100),
    db: Session = Depends(get_db),
    _: User = Depends(require_admin),
):
    items, total = list_admin_stories(db, page=page, limit=limit)
    return build_paginated_response(items, page=page, limit=limit, total_count=total)


@router.delete("/posts/{post_id}", status_code=status.HTTP_204_NO_CONTENT)
def admin_delete_post(
    post_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_admin),
) -> None:
    delete_post(db, current_user, post_id)
