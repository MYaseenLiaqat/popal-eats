"""Tags JSON columns on dishes and restaurants.

Revision ID: 005_tags
Revises: 004_user_preferences
Create Date: 2026-05-22

"""
from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op
from sqlalchemy.dialects import postgresql

revision: str = "005_tags"
down_revision: Union[str, None] = "004_user_preferences"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column(
        "dishes",
        sa.Column("tags", postgresql.JSON(astext_type=sa.Text()), nullable=True),
    )
    op.add_column(
        "restaurants",
        sa.Column("tags", postgresql.JSON(astext_type=sa.Text()), nullable=True),
    )


def downgrade() -> None:
    op.drop_column("restaurants", "tags")
    op.drop_column("dishes", "tags")
