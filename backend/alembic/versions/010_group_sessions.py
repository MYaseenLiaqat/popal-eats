"""Group recommendation sessions — members and invitations.

Revision ID: 010_group_sessions
Revises: 009_social_foundation
Create Date: 2026-06-13
"""

from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op

revision: str = "010_group_sessions"
down_revision: Union[str, None] = "009_social_foundation"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        "group_sessions",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("name", sa.String(length=120), nullable=False),
        sa.Column("host_user_id", sa.Integer(), nullable=False),
        sa.Column("status", sa.String(length=16), nullable=False, server_default="active"),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=False),
        sa.Column("expires_at", sa.DateTime(timezone=True), nullable=False),
        sa.ForeignKeyConstraint(["host_user_id"], ["users.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index("ix_group_sessions_id", "group_sessions", ["id"], unique=False)
    op.create_index("ix_group_sessions_host_user_id", "group_sessions", ["host_user_id"], unique=False)
    op.create_index("ix_group_sessions_status", "group_sessions", ["status"], unique=False)

    op.create_table(
        "group_session_members",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("session_id", sa.Integer(), nullable=False),
        sa.Column("user_id", sa.Integer(), nullable=False),
        sa.Column("joined_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=False),
        sa.ForeignKeyConstraint(["session_id"], ["group_sessions.id"], ondelete="CASCADE"),
        sa.ForeignKeyConstraint(["user_id"], ["users.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("session_id", "user_id", name="uq_group_session_members_session_user"),
    )
    op.create_index("ix_group_session_members_id", "group_session_members", ["id"], unique=False)
    op.create_index("ix_group_session_members_session_id", "group_session_members", ["session_id"], unique=False)
    op.create_index("ix_group_session_members_user_id", "group_session_members", ["user_id"], unique=False)

    op.create_table(
        "group_invitations",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("session_id", sa.Integer(), nullable=False),
        sa.Column("sender_id", sa.Integer(), nullable=False),
        sa.Column("receiver_id", sa.Integer(), nullable=False),
        sa.Column("status", sa.String(length=16), nullable=False, server_default="pending"),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=False),
        sa.ForeignKeyConstraint(["receiver_id"], ["users.id"], ondelete="CASCADE"),
        sa.ForeignKeyConstraint(["sender_id"], ["users.id"], ondelete="CASCADE"),
        sa.ForeignKeyConstraint(["session_id"], ["group_sessions.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("session_id", "receiver_id", name="uq_group_invitations_session_receiver"),
    )
    op.create_index("ix_group_invitations_id", "group_invitations", ["id"], unique=False)
    op.create_index("ix_group_invitations_session_id", "group_invitations", ["session_id"], unique=False)
    op.create_index("ix_group_invitations_sender_id", "group_invitations", ["sender_id"], unique=False)
    op.create_index("ix_group_invitations_receiver_id", "group_invitations", ["receiver_id"], unique=False)
    op.create_index("ix_group_invitations_status", "group_invitations", ["status"], unique=False)


def downgrade() -> None:
    op.drop_index("ix_group_invitations_status", table_name="group_invitations")
    op.drop_index("ix_group_invitations_receiver_id", table_name="group_invitations")
    op.drop_index("ix_group_invitations_sender_id", table_name="group_invitations")
    op.drop_index("ix_group_invitations_session_id", table_name="group_invitations")
    op.drop_index("ix_group_invitations_id", table_name="group_invitations")
    op.drop_table("group_invitations")

    op.drop_index("ix_group_session_members_user_id", table_name="group_session_members")
    op.drop_index("ix_group_session_members_session_id", table_name="group_session_members")
    op.drop_index("ix_group_session_members_id", table_name="group_session_members")
    op.drop_table("group_session_members")

    op.drop_index("ix_group_sessions_status", table_name="group_sessions")
    op.drop_index("ix_group_sessions_host_user_id", table_name="group_sessions")
    op.drop_index("ix_group_sessions_id", table_name="group_sessions")
    op.drop_table("group_sessions")
