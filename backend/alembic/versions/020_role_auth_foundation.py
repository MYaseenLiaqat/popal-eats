"""Role-based authentication foundation — account status, DOB, home chef profiles.

Revision ID: 020_role_auth_foundation
Revises: 019_nutrition_goal_api
Create Date: 2026-06-27
"""

from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op

revision: str = "020_role_auth_foundation"
down_revision: Union[str, None] = "019_nutrition_goal_api"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column("users", sa.Column("first_name", sa.String(100), nullable=True))
    op.add_column("users", sa.Column("last_name", sa.String(100), nullable=True))
    op.add_column("users", sa.Column("date_of_birth", sa.Date(), nullable=True))
    op.add_column(
        "users",
        sa.Column(
            "account_status",
            sa.String(20),
            nullable=False,
            server_default="active",
        ),
    )
    op.add_column(
        "users",
        sa.Column(
            "email_verified",
            sa.Boolean(),
            nullable=False,
            server_default=sa.text("false"),
        ),
    )
    op.add_column(
        "users",
        sa.Column(
            "updated_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=True,
        ),
    )
    op.create_index("ix_users_account_status", "users", ["account_status"])

    # Backfill names for existing rows.
    op.execute(
        """
        UPDATE users
        SET first_name = COALESCE(
                NULLIF(split_part(full_name, ' ', 1), ''),
                full_name
            ),
            last_name = CASE
                WHEN position(' ' in full_name) > 0
                THEN trim(substring(full_name from position(' ' in full_name) + 1))
                ELSE ''
            END
        WHERE first_name IS NULL
        """
    )

    # Unique phone when provided (nullable).
    op.create_index("ix_users_phone", "users", ["phone"], unique=True)

    op.create_table(
        "home_chef_profiles",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("user_id", sa.Integer(), sa.ForeignKey("users.id"), nullable=False),
        sa.Column("display_name", sa.String(200), nullable=False),
        sa.Column("cuisine_specialty", sa.String(100), nullable=False),
        sa.Column("kitchen_address", sa.String(300), nullable=False),
        sa.Column("food_license", sa.String(100), nullable=True),
        sa.Column("profile_image", sa.String(500), nullable=True),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=True,
        ),
        sa.Column(
            "updated_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=True,
        ),
    )
    op.create_index("ix_home_chef_profiles_user_id", "home_chef_profiles", ["user_id"], unique=True)


def downgrade() -> None:
    op.drop_index("ix_home_chef_profiles_user_id", table_name="home_chef_profiles")
    op.drop_table("home_chef_profiles")
    op.drop_index("ix_users_phone", table_name="users")
    op.drop_index("ix_users_account_status", table_name="users")
    op.drop_column("users", "updated_at")
    op.drop_column("users", "email_verified")
    op.drop_column("users", "account_status")
    op.drop_column("users", "date_of_birth")
    op.drop_column("users", "last_name")
    op.drop_column("users", "first_name")
