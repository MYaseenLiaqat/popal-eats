"""Posts, feed, discover reels, and interactions."""

import uuid
from pathlib import Path

from fastapi import APIRouter, Depends, File, HTTPException, Query, UploadFile, status
from sqlalchemy.orm import Session

from app.config import MAX_UPLOAD_MB, UPLOAD_DIR
from app.core.content_constants import CONTENT_IMAGE_EXTENSIONS, CONTENT_VIDEO_EXTENSIONS
from app.core.dependencies import get_current_user, get_optional_current_user
from app.database import get_db
from app.models.user import User
from app.schemas.content import (
    CommentCreate,
    CommentListResponse,
    CommentResponse,
    DiscoverReelsListResponse,
    PostCreate,
    PostListResponse,
    PostResponse,
    PostUpdate,
)
from app.services.content_service import (
    append_post_image,
    create_post,
    delete_post,
    get_post,
    list_discover_reels,
    list_home_feed,
    set_post_video,
    update_post,
)
from app.services.post_interaction_service import (
    add_comment,
    like_post,
    list_comments,
    save_post,
    unlike_post,
    unsave_post,
)

router = APIRouter(tags=["content"])


def _public_content_url(relative_path: str) -> str:
    return f"/uploads/{relative_path.replace(chr(92), '/')}"


@router.get("/feed/home", response_model=PostListResponse, summary="Home feed posts")
def home_feed(
    page: int = Query(1, ge=1),
    limit: int = Query(20, ge=1, le=50),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> PostListResponse:
    items, total = list_home_feed(db, current_user.id, page=page, limit=limit)
    return PostListResponse(items=items, total_count=total, page=page, limit=limit)


@router.get(
    "/discover/reels",
    response_model=DiscoverReelsListResponse,
    summary="Discover vertical content",
)
def discover_reels(
    limit: int = Query(30, ge=1, le=50),
    db: Session = Depends(get_db),
    _user: User | None = Depends(get_optional_current_user),
) -> DiscoverReelsListResponse:
    items = list_discover_reels(db, limit=limit)
    return DiscoverReelsListResponse(items=items)


@router.post("/posts", response_model=PostResponse, status_code=status.HTTP_201_CREATED)
def create_post_route(
    body: PostCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> PostResponse:
    return create_post(db, current_user, body)


@router.get("/posts/{post_id}", response_model=PostResponse)
def get_post_route(
    post_id: int,
    db: Session = Depends(get_db),
    current_user: User | None = Depends(get_optional_current_user),
) -> PostResponse:
    viewer_id = current_user.id if current_user else None
    return get_post(db, post_id, viewer_id)


@router.put("/posts/{post_id}", response_model=PostResponse)
def update_post_route(
    post_id: int,
    body: PostUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> PostResponse:
    return update_post(db, current_user, post_id, body)


@router.delete("/posts/{post_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_post_route(
    post_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> None:
    delete_post(db, current_user, post_id)


@router.post("/posts/{post_id}/image", response_model=PostResponse, summary="Upload post image")
async def upload_post_image(
    post_id: int,
    file: UploadFile = File(...),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> PostResponse:
    suffix = Path(file.filename or "").suffix.lower()
    if suffix not in CONTENT_IMAGE_EXTENSIONS:
        raise HTTPException(
            status_code=400,
            detail=f"Allowed types: {', '.join(sorted(CONTENT_IMAGE_EXTENSIONS))}",
        )

    content = await file.read()
    if len(content) > MAX_UPLOAD_MB * 1024 * 1024:
        raise HTTPException(status_code=400, detail=f"Max {MAX_UPLOAD_MB}MB")

    post_dir = UPLOAD_DIR / "posts"
    post_dir.mkdir(parents=True, exist_ok=True)
    filename = f"{post_id}_{uuid.uuid4().hex}{suffix}"
    dest = post_dir / filename
    dest.write_bytes(content)

    public_url = _public_content_url(f"posts/{filename}")
    return append_post_image(db, current_user, post_id, public_url)


@router.post("/posts/{post_id}/video", response_model=PostResponse, summary="Upload post video")
async def upload_post_video(
    post_id: int,
    file: UploadFile = File(...),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> PostResponse:
    suffix = Path(file.filename or "").suffix.lower()
    if suffix not in CONTENT_VIDEO_EXTENSIONS:
        raise HTTPException(
            status_code=400,
            detail=f"Allowed types: {', '.join(sorted(CONTENT_VIDEO_EXTENSIONS))}",
        )

    content = await file.read()
    if len(content) > MAX_UPLOAD_MB * 1024 * 1024:
        raise HTTPException(status_code=400, detail=f"Max {MAX_UPLOAD_MB}MB")

    post_dir = UPLOAD_DIR / "posts"
    post_dir.mkdir(parents=True, exist_ok=True)
    filename = f"{post_id}_{uuid.uuid4().hex}{suffix}"
    dest = post_dir / filename
    dest.write_bytes(content)

    public_url = _public_content_url(f"posts/{filename}")
    return set_post_video(db, current_user, post_id, public_url)


@router.post("/posts/{post_id}/like", status_code=status.HTTP_204_NO_CONTENT)
def like_post_route(
    post_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> None:
    like_post(db, current_user, post_id)


@router.delete("/posts/{post_id}/like", status_code=status.HTTP_204_NO_CONTENT)
def unlike_post_route(
    post_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> None:
    unlike_post(db, current_user, post_id)


@router.post("/posts/{post_id}/save", status_code=status.HTTP_204_NO_CONTENT)
def save_post_route(
    post_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> None:
    save_post(db, current_user, post_id)


@router.delete("/posts/{post_id}/save", status_code=status.HTTP_204_NO_CONTENT)
def unsave_post_route(
    post_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> None:
    unsave_post(db, current_user, post_id)


@router.get("/posts/{post_id}/comments", response_model=CommentListResponse)
def list_comments_route(
    post_id: int,
    db: Session = Depends(get_db),
) -> CommentListResponse:
    return list_comments(db, post_id)


@router.post(
    "/posts/{post_id}/comments",
    response_model=CommentResponse,
    status_code=status.HTTP_201_CREATED,
)
def add_comment_route(
    post_id: int,
    body: CommentCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> CommentResponse:
    return add_comment(db, current_user, post_id, body)
