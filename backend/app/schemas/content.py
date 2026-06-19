"""Pydantic schemas for posts, stories, feed, and interactions."""

from datetime import datetime

from pydantic import BaseModel, ConfigDict, Field, field_validator

from app.core.content_constants import (
    POST_TYPES,
    RESTAURANT_CONTENT_SUBTYPES,
    RESTAURANT_POST,
)
from app.schemas.friend import UserPublicProfile


class PostCreate(BaseModel):
    post_type: str
    caption: str | None = None
    title: str | None = Field(None, max_length=200)
    images: list[str] | None = None
    video_url: str | None = Field(None, max_length=500)
    restaurant_id: int | None = Field(None, gt=0)
    dish_id: int | None = Field(None, gt=0)
    restaurant_content_subtype: str | None = None
    recipe_description: str | None = None
    recipe_ingredients: list[str] | None = None
    recipe_steps: list[str] | None = None

    @field_validator("post_type")
    @classmethod
    def validate_post_type(cls, v: str) -> str:
        normalized = v.strip().lower()
        if normalized not in POST_TYPES:
            raise ValueError(f"post_type must be one of: {', '.join(sorted(POST_TYPES))}")
        return normalized

    @field_validator("restaurant_content_subtype")
    @classmethod
    def validate_subtype(cls, v: str | None) -> str | None:
        if v is None:
            return None
        normalized = v.strip().lower()
        if normalized not in RESTAURANT_CONTENT_SUBTYPES:
            raise ValueError(
                f"restaurant_content_subtype must be one of: "
                f"{', '.join(sorted(RESTAURANT_CONTENT_SUBTYPES))}"
            )
        return normalized


class PostUpdate(BaseModel):
    caption: str | None = None
    title: str | None = Field(None, max_length=200)
    images: list[str] | None = None
    video_url: str | None = Field(None, max_length=500)
    dish_id: int | None = Field(None, gt=0)
    restaurant_content_subtype: str | None = None
    recipe_description: str | None = None
    recipe_ingredients: list[str] | None = None
    recipe_steps: list[str] | None = None


class PostResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    author_id: int
    post_type: str
    caption: str | None = None
    title: str | None = None
    images: list[str] | None = None
    video_url: str | None = None
    restaurant_id: int | None = None
    dish_id: int | None = None
    restaurant_content_subtype: str | None = None
    recipe_description: str | None = None
    recipe_ingredients: list[str] | None = None
    recipe_steps: list[str] | None = None
    like_count: int = 0
    comment_count: int = 0
    save_count: int = 0
    created_at: datetime
    updated_at: datetime
    author: UserPublicProfile | None = None
    restaurant_name: str | None = None
    dish_name: str | None = None
    liked_by_me: bool = False
    saved_by_me: bool = False


class PostListResponse(BaseModel):
    items: list[PostResponse]
    total_count: int
    page: int
    limit: int


class CommentCreate(BaseModel):
    body: str = Field(..., min_length=1, max_length=2000)


class CommentResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    post_id: int
    user_id: int
    body: str
    created_at: datetime
    author: UserPublicProfile | None = None


class CommentListResponse(BaseModel):
    items: list[CommentResponse]
    total_count: int


class StoryResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    user_id: int
    image_url: str
    expires_at: datetime
    created_at: datetime
    user: UserPublicProfile | None = None
    viewed_by_me: bool = False


class StoryGroupResponse(BaseModel):
    user: UserPublicProfile
    stories: list[StoryResponse]
    has_unviewed: bool = False


class StoryListResponse(BaseModel):
    groups: list[StoryGroupResponse]


class DiscoverReelResponse(BaseModel):
    id: int
    post_type: str
    title: str
    creator_name: str
    caption: str
    thumbnail_url: str | None = None
    video_url: str | None = None
    duration_label: str | None = None
    post_id: int


class DiscoverReelsListResponse(BaseModel):
    items: list[DiscoverReelResponse]
