"""Add phone, city, google_id; allow OAuth users without password.

Revision ID: 014_user_auth_enhancements
Revises: 013_preference_onboarding
Create Date: 2026-06-18
"""

from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op

revision: str = "014_user_auth_enhancements"
down_revision: Union[str, None] = "013_preference_onboarding"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.alter_column("users", "password_hash", existing_type=sa.String(), nullable=True)
    op.add_column("users", sa.Column("phone", sa.String(20), nullable=True))
    op.add_column("users", sa.Column("city", sa.String(100), nullable=True))
    op.add_column("users", sa.Column("google_id", sa.String(128), nullable=True))
    op.create_index("ix_users_google_id", "users", ["google_id"], unique=True)


def downgrade() -> None:
    op.drop_index("ix_users_google_id", table_name="users")
    op.drop_column("users", "google_id")
    op.drop_column("users", "city")
    op.drop_column("users", "phone")
    op.alter_column("users", "password_hash", existing_type=sa.String(), nullable=False)
