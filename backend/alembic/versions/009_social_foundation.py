"""Social foundation — users profile fields, friendships, friend requests.

Revision ID: 009_social_foundation
Revises: 008_preference_fields
Create Date: 2026-06-13
"""

from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op

revision: str = "009_social_foundation"
down_revision: Union[str, None] = "008_preference_fields"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column("users", sa.Column("username", sa.String(length=32), nullable=True))
    op.add_column("users", sa.Column("bio", sa.Text(), nullable=True))
    op.create_index("ix_users_username", "users", ["username"], unique=True)

    op.create_table(
        "friend_requests",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("sender_id", sa.Integer(), nullable=False),
        sa.Column("receiver_id", sa.Integer(), nullable=False),
        sa.Column("status", sa.String(length=16), nullable=False, server_default="pending"),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=False),
        sa.ForeignKeyConstraint(["receiver_id"], ["users.id"], ondelete="CASCADE"),
        sa.ForeignKeyConstraint(["sender_id"], ["users.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("sender_id", "receiver_id", name="uq_friend_requests_sender_receiver"),
    )
    op.create_index("ix_friend_requests_id", "friend_requests", ["id"], unique=False)
    op.create_index("ix_friend_requests_sender_id", "friend_requests", ["sender_id"], unique=False)
    op.create_index("ix_friend_requests_receiver_id", "friend_requests", ["receiver_id"], unique=False)
    op.create_index("ix_friend_requests_status", "friend_requests", ["status"], unique=False)

    op.create_table(
        "friendships",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("user_id", sa.Integer(), nullable=False),
        sa.Column("friend_id", sa.Integer(), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=False),
        sa.ForeignKeyConstraint(["friend_id"], ["users.id"], ondelete="CASCADE"),
        sa.ForeignKeyConstraint(["user_id"], ["users.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("user_id", "friend_id", name="uq_friendships_user_friend"),
    )
    op.create_index("ix_friendships_id", "friendships", ["id"], unique=False)
    op.create_index("ix_friendships_user_id", "friendships", ["user_id"], unique=False)
    op.create_index("ix_friendships_friend_id", "friendships", ["friend_id"], unique=False)


def downgrade() -> None:
    op.drop_index("ix_friendships_friend_id", table_name="friendships")
    op.drop_index("ix_friendships_user_id", table_name="friendships")
    op.drop_index("ix_friendships_id", table_name="friendships")
    op.drop_table("friendships")

    op.drop_index("ix_friend_requests_status", table_name="friend_requests")
    op.drop_index("ix_friend_requests_receiver_id", table_name="friend_requests")
    op.drop_index("ix_friend_requests_sender_id", table_name="friend_requests")
    op.drop_index("ix_friend_requests_id", table_name="friend_requests")
    op.drop_table("friend_requests")

    op.drop_index("ix_users_username", table_name="users")
    op.drop_column("users", "bio")
    op.drop_column("users", "username")
