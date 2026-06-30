"""Admin user management."""

from fastapi import APIRouter, Depends, HTTPException, Query
from pydantic import BaseModel, Field
from sqlalchemy.orm import Session

from app.core.account_status import ACTIVE, SUSPENDED, is_valid_account_status, normalize_account_status
from app.core.rbac import require_admin
from app.core.roles import ALL_ROLES, normalize_role
from app.database import get_db
from app.models.user import User
from app.schemas.pagination import PaginatedResponse
from app.schemas.user import UserResponse
from app.utils.pagination import build_paginated_response, paginate_query

router = APIRouter(prefix="/users", tags=["admin-users"])


class UserRoleUpdate(BaseModel):
    role: str = Field(..., description="admin | customer | restaurant | home_chef | restaurant_owner")


class UserAccountStatusUpdate(BaseModel):
    account_status: str = Field(..., description="active | suspended | pending | rejected")


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


@router.patch("/{user_id}/account-status", response_model=UserResponse)
def admin_update_user_account_status(
    user_id: int,
    body: UserAccountStatusUpdate,
    db: Session = Depends(get_db),
    _: User = Depends(require_admin),
):
    status = normalize_account_status(body.account_status)
    if not is_valid_account_status(status):
        raise HTTPException(status_code=400, detail="Invalid account status")
    if status not in (ACTIVE, SUSPENDED):
        raise HTTPException(status_code=400, detail="Admin can only set active or suspended")

    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    user.account_status = status
    db.commit()
    db.refresh(user)
    return user
