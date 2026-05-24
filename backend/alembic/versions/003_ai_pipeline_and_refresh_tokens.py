"""AI review fields, processing status, refresh tokens.

Revision ID: 003_ai_pipeline
Revises: 002_legacy
Create Date: 2026-05-22

"""
from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op

revision: str = "003_ai_pipeline"
down_revision: Union[str, None] = "002_legacy"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column("reviews", sa.Column("detected_language", sa.String(length=16), nullable=True))
    op.add_column("reviews", sa.Column("translated_text", sa.Text(), nullable=True))
    op.add_column("reviews", sa.Column("sentiment", sa.String(length=32), nullable=True))
    op.add_column("reviews", sa.Column("sentiment_score", sa.Float(), nullable=True))
    op.add_column(
        "reviews",
        sa.Column("processing_status", sa.String(length=32), server_default="pending", nullable=False),
    )
    op.add_column("reviews", sa.Column("processing_error", sa.Text(), nullable=True))
    op.add_column("reviews", sa.Column("processed_at", sa.DateTime(timezone=True), nullable=True))
    op.create_index("ix_reviews_detected_language", "reviews", ["detected_language"])
    op.create_index("ix_reviews_sentiment", "reviews", ["sentiment"])
    op.create_index("ix_reviews_processing_status", "reviews", ["processing_status"])

    op.create_table(
        "refresh_tokens",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("user_id", sa.Integer(), nullable=False),
        sa.Column("token_hash", sa.String(length=128), nullable=False),
        sa.Column("expires_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("revoked", sa.Boolean(), server_default=sa.text("false"), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=True),
        sa.ForeignKeyConstraint(["user_id"], ["users.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index("ix_refresh_tokens_token_hash", "refresh_tokens", ["token_hash"], unique=True)
    op.create_index("ix_refresh_tokens_user_id", "refresh_tokens", ["user_id"])


def downgrade() -> None:
    op.drop_table("refresh_tokens")
    op.drop_index("ix_reviews_processing_status", table_name="reviews")
    op.drop_index("ix_reviews_sentiment", table_name="reviews")
    op.drop_index("ix_reviews_detected_language", table_name="reviews")
    op.drop_column("reviews", "processed_at")
    op.drop_column("reviews", "processing_error")
    op.drop_column("reviews", "processing_status")
    op.drop_column("reviews", "sentiment_score")
    op.drop_column("reviews", "sentiment")
    op.drop_column("reviews", "translated_text")
    op.drop_column("reviews", "detected_language")
