"""Group voting, consensus, and decision tables.

Revision ID: 012_group_voting
Revises: 011_group_recommendations_prep
Create Date: 2026-06-13
"""

from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op

revision: str = "012_group_voting"
down_revision: Union[str, None] = "011_group_recommendations_prep"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        "group_recommendations",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("session_id", sa.Integer(), nullable=False),
        sa.Column("dish_id", sa.Integer(), nullable=False),
        sa.Column("recommendation_score", sa.Numeric(precision=5, scale=2), nullable=False),
        sa.Column("consensus_score", sa.Numeric(precision=5, scale=2), nullable=False, server_default="0"),
        sa.Column("final_score", sa.Numeric(precision=5, scale=2), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=False),
        sa.ForeignKeyConstraint(["dish_id"], ["dishes.id"], ondelete="CASCADE"),
        sa.ForeignKeyConstraint(["session_id"], ["group_sessions.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index("ix_group_recommendations_id", "group_recommendations", ["id"], unique=False)
    op.create_index(
        "ix_group_recommendations_session_id", "group_recommendations", ["session_id"], unique=False
    )
    op.create_index("ix_group_recommendations_dish_id", "group_recommendations", ["dish_id"], unique=False)

    op.create_table(
        "group_votes",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("recommendation_id", sa.Integer(), nullable=False),
        sa.Column("user_id", sa.Integer(), nullable=False),
        sa.Column("vote_type", sa.String(length=16), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=False),
        sa.ForeignKeyConstraint(["recommendation_id"], ["group_recommendations.id"], ondelete="CASCADE"),
        sa.ForeignKeyConstraint(["user_id"], ["users.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint(
            "recommendation_id", "user_id", name="uq_group_votes_recommendation_user"
        ),
    )
    op.create_index("ix_group_votes_id", "group_votes", ["id"], unique=False)
    op.create_index(
        "ix_group_votes_recommendation_id", "group_votes", ["recommendation_id"], unique=False
    )
    op.create_index("ix_group_votes_user_id", "group_votes", ["user_id"], unique=False)
    op.create_index("ix_group_votes_vote_type", "group_votes", ["vote_type"], unique=False)

    op.create_table(
        "group_decisions",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("session_id", sa.Integer(), nullable=False),
        sa.Column("recommendation_id", sa.Integer(), nullable=True),
        sa.Column("status", sa.String(length=16), nullable=False, server_default="pending"),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=False),
        sa.ForeignKeyConstraint(["recommendation_id"], ["group_recommendations.id"], ondelete="SET NULL"),
        sa.ForeignKeyConstraint(["session_id"], ["group_sessions.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("session_id", name="uq_group_decisions_session"),
    )
    op.create_index("ix_group_decisions_id", "group_decisions", ["id"], unique=False)
    op.create_index("ix_group_decisions_session_id", "group_decisions", ["session_id"], unique=False)
    op.create_index(
        "ix_group_decisions_recommendation_id", "group_decisions", ["recommendation_id"], unique=False
    )
    op.create_index("ix_group_decisions_status", "group_decisions", ["status"], unique=False)


def downgrade() -> None:
    op.drop_index("ix_group_decisions_status", table_name="group_decisions")
    op.drop_index("ix_group_decisions_recommendation_id", table_name="group_decisions")
    op.drop_index("ix_group_decisions_session_id", table_name="group_decisions")
    op.drop_index("ix_group_decisions_id", table_name="group_decisions")
    op.drop_table("group_decisions")

    op.drop_index("ix_group_votes_vote_type", table_name="group_votes")
    op.drop_index("ix_group_votes_user_id", table_name="group_votes")
    op.drop_index("ix_group_votes_recommendation_id", table_name="group_votes")
    op.drop_index("ix_group_votes_id", table_name="group_votes")
    op.drop_table("group_votes")

    op.drop_index("ix_group_recommendations_dish_id", table_name="group_recommendations")
    op.drop_index("ix_group_recommendations_session_id", table_name="group_recommendations")
    op.drop_index("ix_group_recommendations_id", table_name="group_recommendations")
    op.drop_table("group_recommendations")
