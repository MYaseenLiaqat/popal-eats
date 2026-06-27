"""Authentication: register, login, refresh, logout, profile."""

from fastapi import APIRouter, Depends, HTTPException, Query, status
from pydantic import ValidationError
from sqlalchemy.orm import Session

from app.config import ACCESS_TOKEN_EXPIRE_MINUTES
from app.core.account_status import blocks_login, normalize_account_status
from app.core.dependencies import get_current_user
from app.core.roles import normalize_role
from app.core.security import (
    create_access_token,
    create_refresh_token,
    revoke_refresh_token,
    verify_password,
    verify_refresh_token,
)
from app.database import get_db
from app.models.user import User
from app.schemas.user import (
    GoogleAuthRequest,
    LogoutRequest,
    RefreshTokenRequest,
    Token,
    UserLogin,
    UserRegister,
    UserResponse,
    UsernameAvailabilityResponse,
)
from app.services.auth_registration_service import register_user
from app.services.google_auth_service import authenticate_google_user
from app.utils.username import validate_username

router = APIRouter(tags=["auth"])


def _issue_tokens(db: Session, user: User) -> Token:
    role = normalize_role(user.role)
    access = create_access_token(user.email, role, user_id=user.id)
    refresh = create_refresh_token(db, user.id)
    return Token(
        access_token=access,
        token_type="bearer",
        role=role,
        account_status=normalize_account_status(user.account_status),
        refresh_token=refresh,
        expires_in_minutes=ACCESS_TOKEN_EXPIRE_MINUTES,
    )


def _ensure_can_login(user: User) -> None:
    if blocks_login(user.account_status):
        status_label = normalize_account_status(user.account_status)
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail=f"Account is {status_label}. Contact support.",
        )


@router.get(
    "/auth/username-available",
    response_model=UsernameAvailabilityResponse,
    summary="Check whether a username is available",
)
def check_username_available(
    username: str = Query(..., min_length=3, max_length=30),
    db: Session = Depends(get_db),
) -> UsernameAvailabilityResponse:
    try:
        normalized = validate_username(username)
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc

    taken = db.query(User).filter(User.username == normalized).first() is not None
    return UsernameAvailabilityResponse(username=normalized, available=not taken)


@router.post("/register", response_model=UserResponse, status_code=status.HTTP_201_CREATED)
def register(body: UserRegister, db: Session = Depends(get_db)):
    try:
        user = register_user(db, body)
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc
    except ValidationError as exc:
        raise HTTPException(status_code=422, detail=exc.errors()) from exc
    return user


@router.post("/login", response_model=Token)
def login(body: UserLogin, db: Session = Depends(get_db)):
    user = db.query(User).filter(User.email == body.email.lower()).first()
    if not user or not user.password_hash or not verify_password(body.password, user.password_hash):
        raise HTTPException(status_code=401, detail="Invalid email or password")
    _ensure_can_login(user)
    return _issue_tokens(db, user)


@router.post("/auth/google", response_model=Token, summary="Sign in with Google ID token")
def google_auth(body: GoogleAuthRequest, db: Session = Depends(get_db)):
    user = authenticate_google_user(db, body.id_token)
    _ensure_can_login(user)
    return _issue_tokens(db, user)


@router.post("/refresh", response_model=Token)
def refresh_tokens(body: RefreshTokenRequest, db: Session = Depends(get_db)):
    record = verify_refresh_token(db, body.refresh_token)
    if not record:
        raise HTTPException(status_code=401, detail="Invalid or expired refresh token")
    user = db.query(User).filter(User.id == record.user_id).first()
    if not user:
        raise HTTPException(status_code=401, detail="User not found")
    _ensure_can_login(user)
    revoke_refresh_token(db, body.refresh_token)
    return _issue_tokens(db, user)


@router.post("/logout", status_code=status.HTTP_204_NO_CONTENT)
def logout(body: LogoutRequest, db: Session = Depends(get_db)):
    if body.refresh_token:
        revoke_refresh_token(db, body.refresh_token)
    return None


@router.get("/me", response_model=UserResponse)
def read_current_user(current_user: User = Depends(get_current_user)):
    return current_user
