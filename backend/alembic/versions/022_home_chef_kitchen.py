"""Home chef kitchen restaurant link and biography.

Revision ID: 022_home_chef_kitchen
Revises: 021_account_rejection_reason
Create Date: 2026-06-27
"""

from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op

revision: str = "022_home_chef_kitchen"
down_revision: Union[str, None] = "021_account_rejection_reason"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column("home_chef_profiles", sa.Column("biography", sa.Text(), nullable=True))
    op.add_column(
        "home_chef_profiles",
        sa.Column("kitchen_restaurant_id", sa.Integer(), nullable=True),
    )
    op.create_foreign_key(
        "fk_home_chef_profiles_kitchen_restaurant_id",
        "home_chef_profiles",
        "restaurants",
        ["kitchen_restaurant_id"],
        ["id"],
        ondelete="SET NULL",
    )
    op.create_index(
        "ix_home_chef_profiles_kitchen_restaurant_id",
        "home_chef_profiles",
        ["kitchen_restaurant_id"],
        unique=True,
    )


def downgrade() -> None:
    op.drop_index("ix_home_chef_profiles_kitchen_restaurant_id", table_name="home_chef_profiles")
    op.drop_constraint(
        "fk_home_chef_profiles_kitchen_restaurant_id",
        "home_chef_profiles",
        type_="foreignkey",
    )
    op.drop_column("home_chef_profiles", "kitchen_restaurant_id")
    op.drop_column("home_chef_profiles", "biography")
