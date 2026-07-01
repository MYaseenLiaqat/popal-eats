"""Restaurant follow table for social discovery.

Revision ID: 024_restaurant_follows
Revises: 023_cart_and_orders
Create Date: 2026-07-01
"""

from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op

revision: str = "024_restaurant_follows"
down_revision: Union[str, None] = "023_cart_and_orders"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        "restaurant_follows",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("user_id", sa.Integer(), nullable=False),
        sa.Column("restaurant_id", sa.Integer(), nullable=False),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.ForeignKeyConstraint(["restaurant_id"], ["restaurants.id"], ondelete="CASCADE"),
        sa.ForeignKeyConstraint(["user_id"], ["users.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint(
            "user_id", "restaurant_id", name="uq_restaurant_follows_user_restaurant"
        ),
    )
    op.create_index("ix_restaurant_follows_id", "restaurant_follows", ["id"], unique=False)
    op.create_index(
        "ix_restaurant_follows_user_id", "restaurant_follows", ["user_id"], unique=False
    )
    op.create_index(
        "ix_restaurant_follows_restaurant_id",
        "restaurant_follows",
        ["restaurant_id"],
        unique=False,
    )


def downgrade() -> None:
    op.drop_index("ix_restaurant_follows_restaurant_id", table_name="restaurant_follows")
    op.drop_index("ix_restaurant_follows_user_id", table_name="restaurant_follows")
    op.drop_index("ix_restaurant_follows_id", table_name="restaurant_follows")
    op.drop_table("restaurant_follows")
