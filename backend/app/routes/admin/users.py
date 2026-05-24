"""Admin user management."""

from fastapi import APIRouter, Depends, HTTPException, Query
from pydantic import BaseModel, Field
from sqlalchemy.orm import Session

from app.core.rbac import require_admin
from app.core.roles import ALL_ROLES, normalize_role
from app.database import get_db
from app.models.user import User
from app.schemas.pagination import PaginatedResponse
from app.schemas.user import UserResponse
from app.utils.pagination import build_paginated_response, paginate_query

router = APIRouter(prefix="/users", tags=["admin-users"])


class UserRoleUpdate(BaseModel):
    role: str = Field(..., description="admin | restaurant_owner | customer")


@router.get("", response_model=PaginatedResponse[UserResponse])
def admin_list_users(
    page: int = Query(1, ge=1),
    limit: int = Query(20, ge=1, le=100),
    role: str | None = None,
    db: Session = Depends(get_db),
    _: User = Depends(require_admin),
):
    query = db.query(User).order_by(User.created_at.desc())
    if role:
        query = query.filter(User.role == normalize_role(role))
    items, total = paginate_query(query, page=page, limit=limit)
    return build_paginated_response(items, page=page, limit=limit, total_count=total)


@router.patch("/{user_id}/role", response_model=UserResponse)
def admin_update_user_role(
    user_id: int,
    body: UserRoleUpdate,
    db: Session = Depends(get_db),
    _: User = Depends(require_admin),
):
    role = normalize_role(body.role)
    if role not in ALL_ROLES:
        raise HTTPException(status_code=400, detail=f"Invalid role. Use: {', '.join(ALL_ROLES)}")

    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    user.role = role
    db.commit()
    db.refresh(user)
    return user
