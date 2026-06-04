"""Recommendation events table for Engine V2 metrics (Phase 5.1).

Revision ID: 006_recommendation_events
Revises: 005_tags
Create Date: 2026-05-22

"""
from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op

revision: str = "006_recommendation_events"
down_revision: Union[str, None] = "005_tags"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        "recommendation_events",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("user_id", sa.Integer(), nullable=False),
        sa.Column("dish_id", sa.Integer(), nullable=False),
        sa.Column("event_type", sa.String(length=32), nullable=False),
        sa.Column("strategy", sa.String(length=64), nullable=False),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.ForeignKeyConstraint(["dish_id"], ["dishes.id"], ondelete="CASCADE"),
        sa.ForeignKeyConstraint(["user_id"], ["users.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index("ix_recommendation_events_id", "recommendation_events", ["id"], unique=False)
    op.create_index(
        "ix_recommendation_events_user_id", "recommendation_events", ["user_id"], unique=False
    )
    op.create_index(
        "ix_recommendation_events_dish_id", "recommendation_events", ["dish_id"], unique=False
    )
    op.create_index(
        "ix_recommendation_events_event_type",
        "recommendation_events",
        ["event_type"],
        unique=False,
    )


def downgrade() -> None:
    op.drop_index("ix_recommendation_events_event_type", table_name="recommendation_events")
    op.drop_index("ix_recommendation_events_dish_id", table_name="recommendation_events")
    op.drop_index("ix_recommendation_events_user_id", table_name="recommendation_events")
    op.drop_index("ix_recommendation_events_id", table_name="recommendation_events")
    op.drop_table("recommendation_events")
