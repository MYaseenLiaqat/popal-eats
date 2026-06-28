"""Repair migration — restores Alembic chain for databases stamped at this revision.

Revision ID: 018_ingredient_allergen
Revises: 016_social_content
Create Date: 2026-06-27
"""

from typing import Sequence, Union

from alembic import op

revision: str = "018_ingredient_allergen"
down_revision: Union[str, None] = "016_social_content"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    pass


def downgrade() -> None:
    pass
