"""User preferences table (1:1 with users).

Revision ID: 008_preference_fields
Revises: 007_foodpanda_source
Create Date: 2026-06-11

Adds API-facing preference fields. Existing columns from 004 are retained.
"""

from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op
from sqlalchemy.dialects import postgresql

revision: str = "008_preference_fields"
down_revision: Union[str, None] = "007_foodpanda_source"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column(
        "user_preferences",
        sa.Column("dietary_preferences", postgresql.JSON(astext_type=sa.Text()), nullable=True),
    )
    op.add_column(
        "user_preferences",
        sa.Column("budget_level", sa.String(length=16), nullable=True),
    )
    op.add_column(
        "user_preferences",
        sa.Column("disliked_categories", postgresql.JSON(astext_type=sa.Text()), nullable=True),
    )


def downgrade() -> None:
    op.drop_column("user_preferences", "disliked_categories")
    op.drop_column("user_preferences", "budget_level")
    op.drop_column("user_preferences", "dietary_preferences")
