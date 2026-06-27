"""Admin business account approval (restaurant & home chef)."""

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.orm import Session

from app.core.rbac import require_admin
from app.core.roles import HOME_CHEF, RESTAURANT, normalize_role
from app.database import get_db
from app.models.user import User
from app.schemas.business_account import (
    BusinessAccountResponse,
    RejectAccountRequest,
    SuspendAccountRequest,
)
from app.schemas.user import UserResponse
from app.services.account_approval_service import (
    approve_business_account,
    business_profile_summary,
    get_business_user_or_404,
    list_business_accounts,
    reactivate_business_account,
    reject_business_account,
    suspend_business_account,
)

router = APIRouter(prefix="/business-accounts", tags=["admin-business-accounts"])


def _to_response(summary: dict) -> BusinessAccountResponse:
    restaurant = summary.get("restaurant")
    home_chef = summary.get("home_chef")
    return BusinessAccountResponse(
        user_id=summary["user_id"],
        role=summary["role"],
        account_status=summary["account_status"],
        full_name=summary["full_name"],
        first_name=summary.get("first_name"),
        last_name=summary.get("last_name"),
        email=summary["email"],
        phone=summary.get("phone"),
        username=summary.get("username"),
        date_of_birth=summary.get("date_of_birth"),
        created_at=summary.get("created_at"),
        rejection_reason=summary.get("rejection_reason"),
        restaurant=restaurant,
        home_chef=home_chef,
    )


@router.get("", response_model=list[BusinessAccountResponse], summary="List business accounts")
def list_accounts(
    account_status: str | None = Query(None, description="pending | active | rejected | suspended"),
    role: str | None = Query(None, description="restaurant | home_chef"),
    db: Session = Depends(get_db),
    _: User = Depends(require_admin),
):
    users = list_business_accounts(db, account_status=account_status, role=role)
    return [_to_response(business_profile_summary(user)) for user in users]


@router.get(
    "/pending",
    response_model=list[BusinessAccountResponse],
    summary="List pending business accounts",
)
def list_pending_accounts(
    role: str | None = Query(None, description="restaurant | home_chef"),
    db: Session = Depends(get_db),
    _: User = Depends(require_admin),
):
    users = list_business_accounts(db, account_status="pending", role=role)
    return [_to_response(business_profile_summary(user)) for user in users]


@router.get(
    "/{user_id}",
    response_model=BusinessAccountResponse,
    summary="View business account registration details",
)
def get_account_detail(
    user_id: int,
    db: Session = Depends(get_db),
    _: User = Depends(require_admin),
):
    try:
        user = get_business_user_or_404(db, user_id)
    except ValueError as exc:
        raise HTTPException(status_code=404, detail=str(exc)) from exc
    return _to_response(business_profile_summary(user))


@router.post(
    "/{user_id}/approve",
    response_model=UserResponse,
    summary="Approve a business account",
)
def approve_account(
    user_id: int,
    db: Session = Depends(get_db),
    _: User = Depends(require_admin),
):
    try:
        user = get_business_user_or_404(db, user_id)
        return approve_business_account(db, user)
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc


@router.post(
    "/{user_id}/reject",
    response_model=UserResponse,
    summary="Reject a business account",
)
def reject_account(
    user_id: int,
    body: RejectAccountRequest,
    db: Session = Depends(get_db),
    _: User = Depends(require_admin),
):
    try:
        user = get_business_user_or_404(db, user_id)
        return reject_business_account(db, user, body.reason)
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc


@router.post(
    "/{user_id}/suspend",
    response_model=UserResponse,
    summary="Suspend a business account",
)
def suspend_account(
    user_id: int,
    body: SuspendAccountRequest,
    db: Session = Depends(get_db),
    _: User = Depends(require_admin),
):
    try:
        user = get_business_user_or_404(db, user_id)
        return suspend_business_account(db, user, body.reason)
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc


@router.post(
    "/{user_id}/reactivate",
    response_model=UserResponse,
    summary="Reactivate a suspended or rejected business account",
)
def reactivate_account(
    user_id: int,
    db: Session = Depends(get_db),
    _: User = Depends(require_admin),
):
    try:
        user = get_business_user_or_404(db, user_id)
        return reactivate_business_account(db, user)
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc
