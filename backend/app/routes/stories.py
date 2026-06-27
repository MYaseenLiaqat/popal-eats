"""Story create, list, and view."""

import uuid
from pathlib import Path

from fastapi import APIRouter, Depends, File, HTTPException, UploadFile, status
from sqlalchemy.orm import Session

from app.config import MAX_UPLOAD_MB, UPLOAD_DIR
from app.core.content_constants import CONTENT_IMAGE_EXTENSIONS
from app.core.dependencies import get_current_user
from app.core.rbac import assert_active_business_account, require_roles
from app.core.roles import ADMIN, HOME_CHEF, RESTAURANT, normalize_role
from app.database import get_db
from app.models.user import User
from app.schemas.content import StoryListResponse, StoryResponse
from app.services.story_service import (
    create_story,
    get_user_stories,
    list_active_stories,
    mark_story_viewed,
)

require_story_creator = require_roles(ADMIN, RESTAURANT, HOME_CHEF)
router = APIRouter(prefix="/stories", tags=["stories"])


def _public_story_url(relative_path: str) -> str:
    return f"/uploads/{relative_path.replace(chr(92), '/')}"


@router.get("", response_model=StoryListResponse, summary="Active stories from friends")
def list_stories(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> StoryListResponse:
    return list_active_stories(db, current_user.id)


@router.post("", response_model=StoryResponse, status_code=status.HTTP_201_CREATED)
async def create_story_route(
    file: UploadFile = File(...),
    db: Session = Depends(get_db),
    current_user: User = Depends(require_story_creator),
) -> StoryResponse:
    if normalize_role(current_user.role) != ADMIN:
        assert_active_business_account(current_user)
    suffix = Path(file.filename or "").suffix.lower()
    if suffix not in CONTENT_IMAGE_EXTENSIONS:
        raise HTTPException(
            status_code=400,
            detail=f"Allowed types: {', '.join(sorted(CONTENT_IMAGE_EXTENSIONS))}",
        )

    content = await file.read()
    if len(content) > MAX_UPLOAD_MB * 1024 * 1024:
        raise HTTPException(status_code=400, detail=f"Max {MAX_UPLOAD_MB}MB")

    story_dir = UPLOAD_DIR / "stories"
    story_dir.mkdir(parents=True, exist_ok=True)
    filename = f"{current_user.id}_{uuid.uuid4().hex}{suffix}"
    dest = story_dir / filename
    dest.write_bytes(content)

    public_url = _public_story_url(f"stories/{filename}")
    return create_story(db, current_user, public_url)


@router.get("/user/{user_id}", response_model=list[StoryResponse])
def user_stories(
    user_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> list[StoryResponse]:
    return get_user_stories(db, user_id, current_user.id)


@router.post("/{story_id}/view", status_code=status.HTTP_204_NO_CONTENT)
def view_story(
    story_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> None:
    mark_story_viewed(db, current_user.id, story_id)
