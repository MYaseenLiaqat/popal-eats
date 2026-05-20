"""
Authentication routes: register and login.

Register: create user row with hashed password.
Login: verify password, return JWT access_token for the client to store.
"""

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.core.security import create_access_token, hash_password, verify_password
from app.database import get_db
from app.models.user import User
from app.schemas.user import Token, UserLogin, UserRegister, UserResponse

router = APIRouter(tags=["auth"])


@router.post(
    "/register",
    response_model=UserResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Create a new account",
)
def register(body: UserRegister, db: Session = Depends(get_db)):
    # 1) Reject duplicate email
    existing = db.query(User).filter(User.email == body.email).first()
    if existing:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Email already registered",
        )

    # 2) Hash password — never save plain text
    user = User(
        full_name=body.full_name,
        email=body.email.lower(),
        password_hash=hash_password(body.password),
        role="user",
    )

    # 3) Persist to PostgreSQL via SQLAlchemy session
    db.add(user)
    db.commit()
    db.refresh(user)
    return user


@router.post(
    "/login",
    response_model=Token,
    summary="Login and receive JWT access token",
)
def login(body: UserLogin, db: Session = Depends(get_db)):
    # 1) Find user by email
    user = db.query(User).filter(User.email == body.email.lower()).first()
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid email or password",
        )

    # 2) Verify password against stored hash
    if not verify_password(body.password, user.password_hash):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid email or password",
        )

    # 3) Issue JWT — client uses this on protected routes later
    access_token = create_access_token(subject=user.email)
    return Token(access_token=access_token, token_type="bearer")
