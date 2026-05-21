"""
FastAPI dependencies for authentication (dependency injection).

Protected route flow:
  1. Client sends header: Authorization: Bearer <access_token>
  2. HTTPBearer extracts the token from that header
  3. decode_access_token() validates JWT signature and expiry
  4. get_token_subject() reads email from `sub` claim
  5. Database lookup returns the User row
  6. Route handler receives `current_user` via Depends(get_current_user)
"""

from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from sqlalchemy.orm import Session

from app.core.security import (
    TokenExpiredError,
    TokenValidationError,
    decode_access_token,
    get_token_subject,
)
from app.database import get_db
from app.models.user import User

# HTTPBearer: reads "Authorization: Bearer <token>" and shows a clear
# "Authorize" button in Swagger (paste token from POST /login).
http_bearer = HTTPBearer(
    scheme_name="BearerAuth",
    description="Paste access_token from POST /login",
    auto_error=True,
)

_UNAUTHORIZED_HEADERS = {"WWW-Authenticate": "Bearer"}


def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(http_bearer),
    db: Session = Depends(get_db),
) -> User:
    """
    Dependency: resolve the authenticated user from a JWT Bearer token.

    Used on protected routes, e.g. GET /me.
    """
    token = credentials.credentials

    try:
        payload = decode_access_token(token)
        email = get_token_subject(payload)
    except TokenExpiredError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token has expired. Please log in again.",
            headers=_UNAUTHORIZED_HEADERS,
        )
    except TokenValidationError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or malformed token",
            headers=_UNAUTHORIZED_HEADERS,
        )

    user = db.query(User).filter(User.email == email.lower()).first()
    if user is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="User not found for this token",
            headers=_UNAUTHORIZED_HEADERS,
        )

    return user
