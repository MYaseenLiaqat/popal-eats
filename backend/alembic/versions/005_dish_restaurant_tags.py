"""Add JSON tags on dishes and restaurants for cuisine matching (V1.1).

Revision ID: 005_tags
Revises: 004_user_preferences
Create Date: 2026-06-01

"""
from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op

revision: str = "005_tags"
down_revision: Union[str, None] = "004_user_preferences"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column(
        "restaurants",
        sa.Column("tags", sa.JSON(), server_default=sa.text("'[]'::json"), nullable=False),
    )
    op.add_column(
        "dishes",
        sa.Column("tags", sa.JSON(), server_default=sa.text("'[]'::json"), nullable=False),
    )


def downgrade() -> None:
    op.drop_column("dishes", "tags")
    op.drop_column("restaurants", "tags")
