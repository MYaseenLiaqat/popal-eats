"""FastAPI authentication dependencies."""

from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from sqlalchemy.orm import Session

from app.core.security import (
    TokenExpiredError,
    TokenValidationError,
    decode_access_token,
    get_token_role,
    get_token_subject,
)
from app.database import get_db
from app.models.user import User

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
    token = credentials.credentials

    try:
        payload = decode_access_token(token)
        email = get_token_subject(payload)
        get_token_role(payload)  # validate claim exists
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
