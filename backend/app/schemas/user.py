"""
Pydantic schemas: validate request/response JSON (separate from SQLAlchemy models).

Schemas describe API shape; models describe database tables.
"""

from datetime import datetime

from pydantic import BaseModel, ConfigDict, EmailStr, Field, field_validator

from app.utils.username import validate_username


class UserRegister(BaseModel):
    """Body for POST /register."""

    full_name: str = Field(..., min_length=1, max_length=200)
    username: str = Field(..., min_length=3, max_length=32)
    email: EmailStr
    password: str = Field(..., min_length=6, max_length=128)
    phone: str | None = Field(None, max_length=20)
    city: str | None = Field(None, max_length=100)

    @field_validator("username")
    @classmethod
    def _validate_username(cls, value: str) -> str:
        return validate_username(value)

    @field_validator("phone")
    @classmethod
    def _normalize_phone(cls, value: str | None) -> str | None:
        if value is None:
            return None
        trimmed = value.strip()
        return trimmed or None

    @field_validator("city")
    @classmethod
    def _normalize_city(cls, value: str | None) -> str | None:
        if value is None:
            return None
        trimmed = value.strip()
        return trimmed or None


class UserLogin(BaseModel):
    """Body for POST /login."""

    email: EmailStr
    password: str


class GoogleAuthRequest(BaseModel):
    """Body for POST /auth/google — Firebase / Google ID token."""

    id_token: str = Field(..., min_length=20)


class UserResponse(BaseModel):
    """Safe user data returned to clients (no password)."""

    model_config = ConfigDict(from_attributes=True)

    id: int
    full_name: str
    username: str | None = None
    email: EmailStr
    phone: str | None = None
    city: str | None = None
    role: str
    profile_image: str | None = None
    created_at: datetime | None = None


class UsernameAvailabilityResponse(BaseModel):
    username: str
    available: bool


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
