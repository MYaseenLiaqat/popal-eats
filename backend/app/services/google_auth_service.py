"""Verify Google ID tokens and map to local users."""

from __future__ import annotations

import logging

import httpx
from fastapi import HTTPException, status
from sqlalchemy.orm import Session

from app.config import get_settings
from app.core.roles import CUSTOMER
from app.models.user import User
from app.utils.username import suggest_username_from_email, validate_username

logger = logging.getLogger(__name__)


def _verify_google_id_token(id_token: str) -> dict:
    settings = get_settings()
    if not settings.google_client_id:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Google Sign-In is not configured on the server",
        )

    try:
        response = httpx.get(
            "https://oauth2.googleapis.com/tokeninfo",
            params={"id_token": id_token},
            timeout=10.0,
        )
    except httpx.HTTPError as exc:
        logger.warning("Google token verification failed: %s", exc)
        raise HTTPException(
            status_code=status.HTTP_502_BAD_GATEWAY,
            detail="Could not verify Google token",
        ) from exc

    if response.status_code != 200:
        raise HTTPException(status_code=401, detail="Invalid Google token")

    payload = response.json()
    audience = payload.get("aud") or payload.get("azp")
    if audience != settings.google_client_id:
        raise HTTPException(status_code=401, detail="Google token audience mismatch")

    email = (payload.get("email") or "").lower().strip()
    google_id = payload.get("sub")
    if not email or not google_id:
        raise HTTPException(status_code=401, detail="Google token missing required claims")
    if payload.get("email_verified") not in (True, "true", "1", 1):
        raise HTTPException(status_code=401, detail="Google email is not verified")

    return {
        "email": email,
        "google_id": str(google_id),
        "full_name": (payload.get("name") or email.split("@")[0]).strip(),
        "profile_image": payload.get("picture"),
    }


def _unique_username(db: Session, base: str) -> str:
    try:
        candidate = validate_username(base)
    except ValueError:
        candidate = validate_username(suggest_username_from_email(f"{base}@example.com"))

    if not db.query(User).filter(User.username == candidate).first():
        return candidate

    for suffix in range(2, 100):
        trimmed = candidate[: max(1, 32 - len(str(suffix)) - 1)]
        attempt = f"{trimmed}_{suffix}"
        try:
            attempt = validate_username(attempt)
        except ValueError:
            continue
        if not db.query(User).filter(User.username == attempt).first():
            return attempt

    raise HTTPException(status_code=409, detail="Could not allocate username")


def authenticate_google_user(db: Session, id_token: str) -> User:
    profile = _verify_google_id_token(id_token)

    user = db.query(User).filter(User.google_id == profile["google_id"]).first()
    if user:
        return user

    user = db.query(User).filter(User.email == profile["email"]).first()
    if user:
        if user.google_id and user.google_id != profile["google_id"]:
            raise HTTPException(status_code=409, detail="Email linked to another Google account")
        user.google_id = profile["google_id"]
        if profile["profile_image"] and not user.profile_image:
            user.profile_image = profile["profile_image"]
        if not user.username:
            user.username = _unique_username(
                db, suggest_username_from_email(profile["email"])
            )
        db.commit()
        db.refresh(user)
        return user

    username = _unique_username(db, suggest_username_from_email(profile["email"]))
    user = User(
        full_name=profile["full_name"],
        email=profile["email"],
        password_hash=None,
        role=CUSTOMER,
        username=username,
        google_id=profile["google_id"],
        profile_image=profile.get("profile_image"),
    )
    db.add(user)
    db.commit()
    db.refresh(user)
    return user
