"""Password hashing, JWT access tokens, and refresh tokens."""

import hashlib
import secrets
from datetime import datetime, timedelta, timezone

import bcrypt
from jose import ExpiredSignatureError, JWTError, jwt
from sqlalchemy.orm import Session

from app.config import (
    ACCESS_TOKEN_EXPIRE_MINUTES,
    ALGORITHM,
    REFRESH_TOKEN_EXPIRE_DAYS,
    SECRET_KEY,
    get_settings,
)
from app.core.roles import normalize_role
from app.models.refresh_token import RefreshToken


class TokenValidationError(Exception):
    pass


class TokenExpiredError(Exception):
    pass


def hash_password(plain_password: str) -> str:
    hashed = bcrypt.hashpw(plain_password.encode("utf-8"), bcrypt.gensalt())
    return hashed.decode("utf-8")


def verify_password(plain_password: str, password_hash: str) -> bool:
    try:
        return bcrypt.checkpw(
            plain_password.encode("utf-8"),
            password_hash.encode("utf-8"),
        )
    except (ValueError, TypeError):
        return False


def create_access_token(subject: str, role: str, user_id: int | None = None) -> str:
    if not SECRET_KEY:
        raise ValueError("SECRET_KEY is missing. Set it in backend/.env")

    now = datetime.now(timezone.utc)
    expire = now + timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    payload = {
        "sub": subject,
        "role": normalize_role(role),
        "iat": now,
        "exp": expire,
        "type": "access",
    }
    if user_id is not None:
        payload["uid"] = user_id
    return jwt.encode(payload, SECRET_KEY, algorithm=ALGORITHM)


def decode_access_token(token: str) -> dict:
    if not SECRET_KEY:
        raise ValueError("SECRET_KEY is missing. Set it in backend/.env")
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        if payload.get("type") == "refresh":
            raise TokenValidationError("Expected access token")
        return payload
    except ExpiredSignatureError as exc:
        raise TokenExpiredError("Token has expired") from exc
    except JWTError as exc:
        raise TokenValidationError("Invalid or malformed token") from exc


def get_token_subject(payload: dict) -> str:
    subject = payload.get("sub")
    if not subject or not isinstance(subject, str):
        raise TokenValidationError("Token is missing a valid subject (sub)")
    return subject


def get_token_role(payload: dict) -> str:
    role = payload.get("role")
    if not role or not isinstance(role, str):
        raise TokenValidationError("Token is missing a valid role claim")
    return normalize_role(role)


def _hash_refresh_token(raw: str) -> str:
    return hashlib.sha256(raw.encode()).hexdigest()


def create_refresh_token(db: Session, user_id: int) -> str:
    settings = get_settings()
    raw = secrets.token_urlsafe(48)
    token_hash = _hash_refresh_token(raw)
    expires = datetime.now(timezone.utc) + timedelta(days=settings.refresh_token_expire_days)

    db.add(
        RefreshToken(
            user_id=user_id,
            token_hash=token_hash,
            expires_at=expires,
            revoked=False,
        )
    )
    db.commit()
    return raw


def verify_refresh_token(db: Session, raw_token: str) -> RefreshToken | None:
    token_hash = _hash_refresh_token(raw_token)
    now = datetime.now(timezone.utc)
    record = (
        db.query(RefreshToken)
        .filter(
            RefreshToken.token_hash == token_hash,
            RefreshToken.revoked.is_(False),
            RefreshToken.expires_at > now,
        )
        .first()
    )
    return record


def revoke_refresh_token(db: Session, raw_token: str) -> None:
    token_hash = _hash_refresh_token(raw_token)
    record = db.query(RefreshToken).filter(RefreshToken.token_hash == token_hash).first()
    if record:
        record.revoked = True
        db.commit()
