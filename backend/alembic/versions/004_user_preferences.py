"""User preferences table (one-to-one with users).

Revision ID: 004_user_preferences
Revises: 003_ai_pipeline
Create Date: 2026-05-22

"""
from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op

revision: str = "004_user_preferences"
down_revision: Union[str, None] = "003_ai_pipeline"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        "user_preferences",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("user_id", sa.Integer(), nullable=False),
        sa.Column(
            "favorite_cuisines",
            sa.JSON(),
            server_default=sa.text("'[]'::json"),
            nullable=False,
        ),
        sa.Column("dietary_preference", sa.String(length=64), nullable=True),
        sa.Column("nutrition_goal", sa.String(length=64), nullable=True),
        sa.Column("budget_min", sa.Numeric(10, 2), nullable=True),
        sa.Column("budget_max", sa.Numeric(10, 2), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=True),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=True),
        sa.ForeignKeyConstraint(["user_id"], ["users.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("user_id", name="uq_user_preferences_user_id"),
    )
    op.create_index("ix_user_preferences_id", "user_preferences", ["id"], unique=False)
    op.create_index("ix_user_preferences_user_id", "user_preferences", ["user_id"], unique=True)


def downgrade() -> None:
    op.drop_index("ix_user_preferences_user_id", table_name="user_preferences")
    op.drop_index("ix_user_preferences_id", table_name="user_preferences")
    op.drop_table("user_preferences")
