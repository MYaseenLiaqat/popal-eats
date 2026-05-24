"""
Pydantic schemas: validate request/response JSON (separate from SQLAlchemy models).

Schemas describe API shape; models describe database tables.
"""

from datetime import datetime

from pydantic import BaseModel, ConfigDict, EmailStr, Field


class UserRegister(BaseModel):
    """Body for POST /register."""

    full_name: str = Field(..., min_length=1, max_length=200)
    email: EmailStr
    password: str = Field(..., min_length=6, max_length=128)


class UserLogin(BaseModel):
    """Body for POST /login."""

    email: EmailStr
    password: str


class UserResponse(BaseModel):
    """Safe user data returned to clients (no password)."""

    model_config = ConfigDict(from_attributes=True)

    id: int
    full_name: str
    email: EmailStr
    role: str
    profile_image: str | None = None
    created_at: datetime | None = None


class Token(BaseModel):
    """JWT returned after successful login."""

    access_token: str
    token_type: str = "bearer"
    role: str
    refresh_token: str | None = None
    expires_in_minutes: int = 30


class RefreshTokenRequest(BaseModel):
    refresh_token: str


class LogoutRequest(BaseModel):
    refresh_token: str | None = None
