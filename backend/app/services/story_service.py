"""Story create, list, view, and expiration."""

from datetime import datetime, timedelta, timezone

from fastapi import HTTPException
from sqlalchemy.orm import Session, joinedload

from app.core.content_constants import STORY_TTL_HOURS
from app.models.friendship import Friendship
from app.models.story import Story, StoryView
from app.models.user import User
from app.schemas.content import StoryGroupResponse, StoryListResponse, StoryResponse
from app.schemas.friend import UserPublicProfile


def _now() -> datetime:
    return datetime.now(timezone.utc)


def _friend_ids(db: Session, user_id: int) -> set[int]:
    rows = db.query(Friendship.friend_id).filter(Friendship.user_id == user_id).all()
    return {row[0] for row in rows}


def create_story(db: Session, user: User, image_url: str) -> StoryResponse:
    expires = _now() + timedelta(hours=STORY_TTL_HOURS)
    story = Story(user_id=user.id, image_url=image_url, expires_at=expires)
    db.add(story)
    db.commit()
    db.refresh(story)
    story = (
        db.query(Story)
        .options(joinedload(Story.user))
        .filter(Story.id == story.id)
        .first()
    )
    return _serialize_story(story, user.id, db)


def _serialize_story(story: Story, viewer_id: int, db: Session) -> StoryResponse:
    viewed = (
        db.query(StoryView.id)
        .filter(StoryView.story_id == story.id, StoryView.viewer_id == viewer_id)
        .first()
        is not None
    )
    profile = UserPublicProfile.model_validate(story.user) if story.user else None
    return StoryResponse(
        id=story.id,
        user_id=story.user_id,
        image_url=story.image_url,
        expires_at=story.expires_at,
        created_at=story.created_at,
        user=profile,
        viewed_by_me=viewed,
    )


def list_active_stories(db: Session, user_id: int) -> StoryListResponse:
    now = _now()
    friends = _friend_ids(db, user_id)
    visible_users = friends | {user_id}

    stories = (
        db.query(Story)
        .options(joinedload(Story.user))
        .filter(Story.user_id.in_(visible_users), Story.expires_at > now)
        .order_by(Story.created_at.asc())
        .all()
    )

    grouped: dict[int, list[Story]] = {}
    users: dict[int, User] = {}
    for story in stories:
        grouped.setdefault(story.user_id, []).append(story)
        if story.user is not None:
            users[story.user_id] = story.user

    groups: list[StoryGroupResponse] = []
    for uid in sorted(grouped.keys(), key=lambda x: (0 if x == user_id else 1, x)):
        user_stories = grouped[uid]
        serialized = [_serialize_story(s, user_id, db) for s in user_stories]
        has_unviewed = any(not s.viewed_by_me for s in serialized)
        profile = UserPublicProfile.model_validate(users[uid]) if uid in users else None
        if profile is None:
            continue
        groups.append(
            StoryGroupResponse(
                user=profile,
                stories=serialized,
                has_unviewed=has_unviewed,
            )
        )

    return StoryListResponse(groups=groups)


def get_user_stories(db: Session, target_user_id: int, viewer_id: int) -> list[StoryResponse]:
    now = _now()
    friends = _friend_ids(db, viewer_id)
    if target_user_id != viewer_id and target_user_id not in friends:
        raise HTTPException(status_code=403, detail="Cannot view this user's stories")

    stories = (
        db.query(Story)
        .options(joinedload(Story.user))
        .filter(Story.user_id == target_user_id, Story.expires_at > now)
        .order_by(Story.created_at.asc())
        .all()
    )
    return [_serialize_story(s, viewer_id, db) for s in stories]


def mark_story_viewed(db: Session, viewer_id: int, story_id: int) -> None:
    story = db.query(Story).filter(Story.id == story_id).first()
    if story is None:
        raise HTTPException(status_code=404, detail="Story not found")
    if story.expires_at <= _now():
        raise HTTPException(status_code=410, detail="Story expired")

    existing = (
        db.query(StoryView)
        .filter(StoryView.story_id == story_id, StoryView.viewer_id == viewer_id)
        .first()
    )
    if existing is None:
        db.add(StoryView(story_id=story_id, viewer_id=viewer_id))
        db.commit()
