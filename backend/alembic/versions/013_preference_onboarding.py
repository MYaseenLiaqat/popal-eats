"""Add onboarding_completed flag to users.

Revision ID: 013_preference_onboarding
Revises: 012_group_voting
Create Date: 2026-06-13
"""

from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op

revision: str = "013_preference_onboarding"
down_revision: Union[str, None] = "012_group_voting"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column(
        "users",
        sa.Column("onboarding_completed", sa.Boolean(), nullable=False, server_default="false"),
    )


def downgrade() -> None:
    op.drop_column("users", "onboarding_completed")
