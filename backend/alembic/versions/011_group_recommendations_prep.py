"""Phase 3 prep — user allergies and group member locations.

Revision ID: 011_group_recommendations_prep
Revises: 010_group_sessions
Create Date: 2026-06-13
"""

from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op
from sqlalchemy.dialects import postgresql

revision: str = "011_group_recommendations_prep"
down_revision: Union[str, None] = "010_group_sessions"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column(
        "user_preferences",
        sa.Column("allergies", postgresql.JSON(astext_type=sa.Text()), nullable=True),
    )

    op.create_table(
        "group_member_locations",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("session_id", sa.Integer(), nullable=False),
        sa.Column("user_id", sa.Integer(), nullable=False),
        sa.Column("latitude", sa.Numeric(precision=10, scale=7), nullable=False),
        sa.Column("longitude", sa.Numeric(precision=10, scale=7), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=False),
        sa.ForeignKeyConstraint(["session_id"], ["group_sessions.id"], ondelete="CASCADE"),
        sa.ForeignKeyConstraint(["user_id"], ["users.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("session_id", "user_id", name="uq_group_member_locations_session_user"),
    )
    op.create_index("ix_group_member_locations_id", "group_member_locations", ["id"], unique=False)
    op.create_index(
        "ix_group_member_locations_session_id", "group_member_locations", ["session_id"], unique=False
    )
    op.create_index(
        "ix_group_member_locations_user_id", "group_member_locations", ["user_id"], unique=False
    )


def downgrade() -> None:
    op.drop_index("ix_group_member_locations_user_id", table_name="group_member_locations")
    op.drop_index("ix_group_member_locations_session_id", table_name="group_member_locations")
    op.drop_index("ix_group_member_locations_id", table_name="group_member_locations")
    op.drop_table("group_member_locations")

    op.drop_column("user_preferences", "allergies")
