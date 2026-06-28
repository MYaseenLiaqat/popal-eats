"""Add rejection_reason to users for business account review.

Revision ID: 021_account_rejection_reason
Revises: 020_role_auth_foundation
Create Date: 2026-06-27
"""

from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op

revision: str = "021_account_rejection_reason"
down_revision: Union[str, None] = "020_role_auth_foundation"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column("users", sa.Column("rejection_reason", sa.Text(), nullable=True))


def downgrade() -> None:
    op.drop_column("users", "rejection_reason")
