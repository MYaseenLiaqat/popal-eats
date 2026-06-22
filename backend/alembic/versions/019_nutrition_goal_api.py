"""Expose nutrition_goal via preferences API (column exists since 004).

Revision ID: 019_nutrition_goal_api
Revises: 018_dish_ingredient_allergen
Create Date: 2026-06-05
"""

from typing import Sequence, Union

from alembic import op

revision: str = "019_nutrition_goal_api"
down_revision: Union[str, None] = "018_dish_ingredient_allergen"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # nutrition_goal column added in 004_user_preferences — no schema change required.
    # This revision documents API exposure and recommendation-engine goal scoring.
    pass


def downgrade() -> None:
    pass
