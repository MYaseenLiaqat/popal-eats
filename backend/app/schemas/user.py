"""Pydantic schemas: validate request/response JSON (separate from SQLAlchemy models)."""

from datetime import date, datetime
from typing import Literal

from pydantic import BaseModel, ConfigDict, EmailStr, Field, field_validator, model_validator

from app.core.account_status import normalize_account_status
from app.core.roles import CUSTOMER, HOME_CHEF, RESTAURANT, SIGNUP_ROLES, normalize_role
from app.utils.password import validate_password
from app.utils.phone import normalize_phone
from app.utils.username import validate_username

SignupRole = Literal["customer", "restaurant", "home_chef"]


class RestaurantRegistrationProfile(BaseModel):
    restaurant_name: str = Field(..., min_length=1, max_length=200)
    restaurant_address: str = Field(..., min_length=1, max_length=300)
    cuisine_type: str = Field(..., min_length=1, max_length=100)
    business_registration_number: str | None = Field(None, max_length=100)
    logo_url: str | None = Field(None, max_length=500)
    cover_image_url: str | None = Field(None, max_length=500)


class HomeChefRegistrationProfile(BaseModel):
    chef_display_name: str = Field(..., min_length=1, max_length=200)
    cuisine_specialty: str = Field(..., min_length=1, max_length=100)
    kitchen_address: str = Field(..., min_length=1, max_length=300)
    food_license: str | None = Field(None, max_length=100)
    profile_image_url: str | None = Field(None, max_length=500)


class UserRegister(BaseModel):
    """Body for POST /register — universal role-based signup."""

    role: SignupRole = CUSTOMER
    first_name: str = Field(..., min_length=1, max_length=100)
    last_name: str = Field(..., min_length=1, max_length=100)
    username: str = Field(..., min_length=3, max_length=30)
    email: EmailStr
    phone: str = Field(..., min_length=8, max_length=20)
    date_of_birth: date
    password: str = Field(..., min_length=8, max_length=128)
    confirm_password: str = Field(..., min_length=8, max_length=128)
    city: str | None = Field(None, max_length=100)
    restaurant_profile: RestaurantRegistrationProfile | None = None
    home_chef_profile: HomeChefRegistrationProfile | None = None

    # Backward-compatible alias for legacy clients sending full_name.
    full_name: str | None = Field(None, max_length=200)

    @field_validator("username")
    @classmethod
    def _validate_username(cls, value: str) -> str:
        return validate_username(value)

    @field_validator("email")
    @classmethod
    def _normalize_email(cls, value: str) -> str:
        return value.strip().lower()

    @model_validator(mode="before")
    @classmethod
    def _legacy_defaults(cls, data: object) -> object:
        if not isinstance(data, dict):
            return data
        payload = dict(data)
        if not payload.get("first_name") and payload.get("full_name"):
            parts = str(payload["full_name"]).strip().split(None, 1)
            payload["first_name"] = parts[0]
            payload["last_name"] = parts[1] if len(parts) > 1 else parts[0]
        if not payload.get("confirm_password") and payload.get("password"):
            payload["confirm_password"] = payload["password"]
        if not payload.get("date_of_birth"):
            payload["date_of_birth"] = "1990-01-01"
        if not payload.get("phone"):
            email = str(payload.get("email", "legacy"))
            suffix = abs(hash(email.lower())) % 10_000_000
            payload["phone"] = f"+199{suffix:07d}"
        return payload

    @field_validator("phone")
    @classmethod
    def _normalize_phone(cls, value: str) -> str:
        return normalize_phone(value)

    @field_validator("password")
    @classmethod
    def _validate_password(cls, value: str) -> str:
        return validate_password(value)

    @field_validator("first_name", "last_name")
    @classmethod
    def _strip_names(cls, value: str) -> str:
        trimmed = value.strip()
        if not trimmed:
            raise ValueError("Name fields cannot be empty.")
        return trimmed

    @field_validator("date_of_birth")
    @classmethod
    def _validate_dob(cls, value: date) -> date:
        today = date.today()
        age = today.year - value.year - ((today.month, today.day) < (value.month, value.day))
        if age < 13:
            raise ValueError("You must be at least 13 years old to register.")
        if age > 120:
            raise ValueError("Enter a valid date of birth.")
        if value > today:
            raise ValueError("Date of birth cannot be in the future.")
        return value

    @field_validator("city")
    @classmethod
    def _normalize_city(cls, value: str | None) -> str | None:
        if value is None:
            return None
        trimmed = value.strip()
        return trimmed or None

    @model_validator(mode="after")
    def _validate_role_profiles(self) -> "UserRegister":
        role = normalize_role(self.role)
        if role not in SIGNUP_ROLES:
            raise ValueError("Invalid registration role.")

        if self.password != self.confirm_password:
            raise ValueError("Passwords do not match.")

        if role == RESTAURANT and self.restaurant_profile is None:
            raise ValueError("Restaurant registration requires restaurant details.")
        if role == HOME_CHEF and self.home_chef_profile is None:
            raise ValueError("Home chef registration requires chef profile details.")
        if role == CUSTOMER and (self.restaurant_profile or self.home_chef_profile):
            raise ValueError("Customer registration cannot include business profiles.")

        return self

    @property
    def resolved_full_name(self) -> str:
        if self.full_name and self.full_name.strip():
            return self.full_name.strip()
        return f"{self.first_name} {self.last_name}".strip()


class UserLogin(BaseModel):
    """Body for POST /login."""

    email: EmailStr
    password: str

    @field_validator("email")
    @classmethod
    def _normalize_email(cls, value: str) -> str:
        return value.strip().lower()


class GoogleAuthRequest(BaseModel):
    """Body for POST /auth/google — Firebase / Google ID token."""

    id_token: str = Field(..., min_length=20)


class UserResponse(BaseModel):
    """Safe user data returned to clients (no password)."""

    model_config = ConfigDict(from_attributes=True)

    id: int
    full_name: str
    first_name: str | None = None
    last_name: str | None = None
    username: str | None = None
    email: EmailStr
    phone: str | None = None
    city: str | None = None
    role: str
    account_status: str
    email_verified: bool = False
    date_of_birth: date | None = None
    profile_image: str | None = None
    rejection_reason: str | None = None
    created_at: datetime | None = None
    updated_at: datetime | None = None


class UsernameAvailabilityResponse(BaseModel):
    username: str
    available: bool


class Token(BaseModel):
    """JWT returned after successful login."""

    access_token: str
    token_type: str = "bearer"
    role: str
    account_status: str
    refresh_token: str | None = None
    expires_in_minutes: int = 30


class RefreshTokenRequest(BaseModel):
    refresh_token: str


class LogoutRequest(BaseModel):
    refresh_token: str | None = None
