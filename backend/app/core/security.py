"""
Password hashing and JWT (JSON Web Token) helpers.

Flow:
  Register → hash_password() → store password_hash in DB
  Login    → verify_password() → create_access_token() → client sends token on later requests
  Protected routes → decode_access_token() → read email from token → load user from DB
"""

from datetime import datetime, timedelta, timezone

from jose import ExpiredSignatureError, JWTError, jwt
from passlib.context import CryptContext

from app.config import ALGORITHM, SECRET_KEY, ACCESS_TOKEN_EXPIRE_MINUTES

# bcrypt via passlib — one-way hashing (cannot recover original password)
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")


class TokenValidationError(Exception):
    """Raised when a JWT is invalid, malformed, or missing required claims."""


class TokenExpiredError(Exception):
    """Raised when a JWT has passed its expiration time (`exp` claim)."""


def hash_password(plain_password: str) -> str:
    """Convert a plain password into a bcrypt hash for database storage."""
    return pwd_context.hash(plain_password)


def verify_password(plain_password: str, password_hash: str) -> bool:
    """Check login password against the stored hash."""
    return pwd_context.verify(plain_password, password_hash)


def create_access_token(subject: str) -> str:
    """
    Build a signed JWT.

    `subject` is usually the user's email (claim `sub` in the token).
    Client sends: Authorization: Bearer <token>
    """
    if not SECRET_KEY:
        raise ValueError("SECRET_KEY is missing. Set it in backend/.env")

    expire = datetime.now(timezone.utc) + timedelta(
        minutes=ACCESS_TOKEN_EXPIRE_MINUTES
    )
    payload = {
        "sub": subject,
        "exp": expire,
    }
    return jwt.encode(payload, SECRET_KEY, algorithm=ALGORITHM)


def decode_access_token(token: str) -> dict:
    """
    Decode and validate a JWT using SECRET_KEY and ALGORITHM.

    Returns the token payload (dict) if valid.
    Raises TokenExpiredError or TokenValidationError otherwise.
    """
    if not SECRET_KEY:
        raise ValueError("SECRET_KEY is missing. Set it in backend/.env")

    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        return payload
    except ExpiredSignatureError as exc:
        raise TokenExpiredError("Token has expired") from exc
    except JWTError as exc:
        raise TokenValidationError("Invalid or malformed token") from exc


def get_token_subject(payload: dict) -> str:
    """
    Extract the user identifier from JWT payload.

    We store the user's email in the `sub` (subject) claim at login time.
    """
    subject = payload.get("sub")
    if not subject or not isinstance(subject, str):
        raise TokenValidationError("Token is missing a valid subject (sub)")
    return subject
