"""Add restaurant approval workflow and extended dish nutrition fields.

Revision ID: 015_restaurant_management
Revises: 014_user_auth_enhancements
Create Date: 2026-06-19
"""

from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op
from sqlalchemy.dialects.postgresql import JSON

revision: str = "015_restaurant_management"
down_revision: Union[str, None] = "014_user_auth_enhancements"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column(
        "restaurants",
        sa.Column(
            "approval_status",
            sa.String(20),
            nullable=False,
            server_default="approved",
        ),
    )
    op.add_column(
        "restaurants",
        sa.Column("rejection_reason", sa.Text(), nullable=True),
    )
    op.create_index("ix_restaurants_approval_status", "restaurants", ["approval_status"])

    op.add_column("dishes", sa.Column("cuisine", sa.String(100), nullable=True))
    op.add_column("dishes", sa.Column("fiber", sa.Numeric(8, 2), nullable=True))
    op.add_column("dishes", sa.Column("sugar", sa.Numeric(8, 2), nullable=True))
    op.add_column("dishes", sa.Column("sodium", sa.Numeric(8, 2), nullable=True))
    op.add_column("dishes", sa.Column("ingredients", JSON, nullable=True))
    op.add_column("dishes", sa.Column("allergens", JSON, nullable=True))
    op.add_column("dishes", sa.Column("images", JSON, nullable=True))


def downgrade() -> None:
    op.drop_column("dishes", "images")
    op.drop_column("dishes", "allergens")
    op.drop_column("dishes", "ingredients")
    op.drop_column("dishes", "sodium")
    op.drop_column("dishes", "sugar")
    op.drop_column("dishes", "fiber")
    op.drop_column("dishes", "cuisine")
    op.drop_index("ix_restaurants_approval_status", table_name="restaurants")
    op.drop_column("restaurants", "rejection_reason")
    op.drop_column("restaurants", "approval_status")
