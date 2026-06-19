"""Social content — posts, stories, likes, comments, saves.

Revision ID: 016_social_content
Revises: 015_restaurant_management
Create Date: 2026-06-19
"""

from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op
from sqlalchemy.dialects.postgresql import JSON

revision: str = "016_social_content"
down_revision: Union[str, None] = "015_restaurant_management"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        "posts",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("author_id", sa.Integer(), nullable=False),
        sa.Column("post_type", sa.String(32), nullable=False),
        sa.Column("caption", sa.Text(), nullable=True),
        sa.Column("title", sa.String(200), nullable=True),
        sa.Column("images", JSON, nullable=True),
        sa.Column("video_url", sa.String(500), nullable=True),
        sa.Column("restaurant_id", sa.Integer(), nullable=True),
        sa.Column("dish_id", sa.Integer(), nullable=True),
        sa.Column("restaurant_content_subtype", sa.String(32), nullable=True),
        sa.Column("recipe_description", sa.Text(), nullable=True),
        sa.Column("recipe_ingredients", JSON, nullable=True),
        sa.Column("recipe_steps", JSON, nullable=True),
        sa.Column("like_count", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("comment_count", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("save_count", sa.Integer(), nullable=False, server_default="0"),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.Column(
            "updated_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.ForeignKeyConstraint(["author_id"], ["users.id"], ondelete="CASCADE"),
        sa.ForeignKeyConstraint(["dish_id"], ["dishes.id"], ondelete="SET NULL"),
        sa.ForeignKeyConstraint(["restaurant_id"], ["restaurants.id"], ondelete="SET NULL"),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index("ix_posts_id", "posts", ["id"], unique=False)
    op.create_index("ix_posts_author_id", "posts", ["author_id"], unique=False)
    op.create_index("ix_posts_post_type", "posts", ["post_type"], unique=False)
    op.create_index("ix_posts_restaurant_id", "posts", ["restaurant_id"], unique=False)
    op.create_index("ix_posts_created_at", "posts", ["created_at"], unique=False)

    op.create_table(
        "stories",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("user_id", sa.Integer(), nullable=False),
        sa.Column("image_url", sa.String(500), nullable=False),
        sa.Column("expires_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.ForeignKeyConstraint(["user_id"], ["users.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index("ix_stories_id", "stories", ["id"], unique=False)
    op.create_index("ix_stories_user_id", "stories", ["user_id"], unique=False)
    op.create_index("ix_stories_expires_at", "stories", ["expires_at"], unique=False)

    op.create_table(
        "story_views",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("story_id", sa.Integer(), nullable=False),
        sa.Column("viewer_id", sa.Integer(), nullable=False),
        sa.Column(
            "viewed_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.ForeignKeyConstraint(["story_id"], ["stories.id"], ondelete="CASCADE"),
        sa.ForeignKeyConstraint(["viewer_id"], ["users.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("story_id", "viewer_id", name="uq_story_views_story_viewer"),
    )
    op.create_index("ix_story_views_story_id", "story_views", ["story_id"], unique=False)

    op.create_table(
        "post_likes",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("post_id", sa.Integer(), nullable=False),
        sa.Column("user_id", sa.Integer(), nullable=False),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.ForeignKeyConstraint(["post_id"], ["posts.id"], ondelete="CASCADE"),
        sa.ForeignKeyConstraint(["user_id"], ["users.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("post_id", "user_id", name="uq_post_likes_post_user"),
    )
    op.create_index("ix_post_likes_post_id", "post_likes", ["post_id"], unique=False)

    op.create_table(
        "post_comments",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("post_id", sa.Integer(), nullable=False),
        sa.Column("user_id", sa.Integer(), nullable=False),
        sa.Column("body", sa.Text(), nullable=False),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.ForeignKeyConstraint(["post_id"], ["posts.id"], ondelete="CASCADE"),
        sa.ForeignKeyConstraint(["user_id"], ["users.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index("ix_post_comments_post_id", "post_comments", ["post_id"], unique=False)

    op.create_table(
        "post_saves",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("post_id", sa.Integer(), nullable=False),
        sa.Column("user_id", sa.Integer(), nullable=False),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.ForeignKeyConstraint(["post_id"], ["posts.id"], ondelete="CASCADE"),
        sa.ForeignKeyConstraint(["user_id"], ["users.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("post_id", "user_id", name="uq_post_saves_post_user"),
    )
    op.create_index("ix_post_saves_user_id", "post_saves", ["user_id"], unique=False)


def downgrade() -> None:
    op.drop_index("ix_post_saves_user_id", table_name="post_saves")
    op.drop_table("post_saves")
    op.drop_index("ix_post_comments_post_id", table_name="post_comments")
    op.drop_table("post_comments")
    op.drop_index("ix_post_likes_post_id", table_name="post_likes")
    op.drop_table("post_likes")
    op.drop_index("ix_story_views_story_id", table_name="story_views")
    op.drop_table("story_views")
    op.drop_index("ix_stories_expires_at", table_name="stories")
    op.drop_index("ix_stories_user_id", table_name="stories")
    op.drop_index("ix_stories_id", table_name="stories")
    op.drop_table("stories")
    op.drop_index("ix_posts_created_at", table_name="posts")
    op.drop_index("ix_posts_restaurant_id", table_name="posts")
    op.drop_index("ix_posts_post_type", table_name="posts")
    op.drop_index("ix_posts_author_id", table_name="posts")
    op.drop_index("ix_posts_id", table_name="posts")
    op.drop_table("posts")
