"""Authentication: register, login, refresh, logout, profile."""

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.config import ACCESS_TOKEN_EXPIRE_MINUTES
from app.core.dependencies import get_current_user
from app.core.roles import CUSTOMER, normalize_role
from app.core.security import (
    create_access_token,
    create_refresh_token,
    hash_password,
    revoke_refresh_token,
    verify_password,
    verify_refresh_token,
)
from app.database import get_db
from app.models.user import User
from app.schemas.user import (
    LogoutRequest,
    RefreshTokenRequest,
    Token,
    UserLogin,
    UserRegister,
    UserResponse,
)

router = APIRouter(tags=["auth"])


def _issue_tokens(db: Session, user: User) -> Token:
    role = normalize_role(user.role)
    access = create_access_token(user.email, role)
    refresh = create_refresh_token(db, user.id)
    return Token(
        access_token=access,
        token_type="bearer",
        role=role,
        refresh_token=refresh,
        expires_in_minutes=ACCESS_TOKEN_EXPIRE_MINUTES,
    )


@router.post("/register", response_model=UserResponse, status_code=status.HTTP_201_CREATED)
def register(body: UserRegister, db: Session = Depends(get_db)):
    email = body.email.lower()
    if db.query(User).filter(User.email == email).first():
        raise HTTPException(status_code=400, detail="Email already registered")

    user = User(
        full_name=body.full_name,
        email=email,
        password_hash=hash_password(body.password),
        role=CUSTOMER,
    )
    db.add(user)
    db.commit()
    db.refresh(user)
    return user


@router.post("/login", response_model=Token)
def login(body: UserLogin, db: Session = Depends(get_db)):
    user = db.query(User).filter(User.email == body.email.lower()).first()
    if not user or not verify_password(body.password, user.password_hash):
        raise HTTPException(status_code=401, detail="Invalid email or password")
    return _issue_tokens(db, user)


@router.post("/refresh", response_model=Token)
def refresh_tokens(body: RefreshTokenRequest, db: Session = Depends(get_db)):
    record = verify_refresh_token(db, body.refresh_token)
    if not record:
        raise HTTPException(status_code=401, detail="Invalid or expired refresh token")
    user = db.query(User).filter(User.id == record.user_id).first()
    if not user:
        raise HTTPException(status_code=401, detail="User not found")
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
