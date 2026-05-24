"""Migrate legacy DB (rating column, user role) to v2 schema.

Revision ID: 002_legacy
Revises: 001_initial
Create Date: 2026-05-22

"""
from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op

revision: str = "002_legacy"
down_revision: Union[str, None] = "001_initial"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def _column_exists(table: str, column: str) -> bool:
    bind = op.get_bind()
    result = bind.execute(
        sa.text(
            "SELECT 1 FROM information_schema.columns "
            "WHERE table_name = :t AND column_name = :c"
        ),
        {"t": table, "c": column},
    )
    return result.first() is not None


def _table_exists(table: str) -> bool:
    bind = op.get_bind()
    result = bind.execute(
        sa.text(
            "SELECT 1 FROM information_schema.tables "
            "WHERE table_name = :t AND table_schema = 'public'"
        ),
        {"t": table},
    )
    return result.first() is not None


def upgrade() -> None:
    # Skip if fresh install already has 001 applied with new columns only
    if not _table_exists("restaurants"):
        return

    if _column_exists("restaurants", "rating") and not _column_exists("restaurants", "average_rating"):
        op.add_column(
            "restaurants",
            sa.Column("average_rating", sa.Float(), nullable=False, server_default="0"),
        )
        op.add_column(
            "restaurants",
            sa.Column("total_reviews", sa.Integer(), nullable=False, server_default="0"),
        )
        op.execute("UPDATE restaurants SET average_rating = COALESCE(rating, 0)")
        op.execute(
            "UPDATE restaurants SET total_reviews = ("
            "  SELECT COUNT(*) FROM reviews WHERE reviews.restaurant_id = restaurants.id"
            ")"
        )
        op.drop_column("restaurants", "rating")

    if not _table_exists("menu_uploads"):
        op.create_table(
            "menu_uploads",
            sa.Column("id", sa.Integer(), nullable=False),
            sa.Column("restaurant_id", sa.Integer(), nullable=False),
            sa.Column("uploaded_by", sa.Integer(), nullable=False),
            sa.Column("file_path", sa.String(length=500), nullable=False),
            sa.Column("original_filename", sa.String(length=255), nullable=True),
            sa.Column("status", sa.String(length=32), nullable=False, server_default="pending"),
            sa.Column("extracted_json", sa.Text(), nullable=True),
            sa.Column("error_message", sa.Text(), nullable=True),
            sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=True),
            sa.Column("processed_at", sa.DateTime(timezone=True), nullable=True),
            sa.ForeignKeyConstraint(["restaurant_id"], ["restaurants.id"], ondelete="CASCADE"),
            sa.ForeignKeyConstraint(["uploaded_by"], ["users.id"]),
            sa.PrimaryKeyConstraint("id"),
        )

    op.execute("UPDATE users SET role = 'customer' WHERE role = 'user'")


def downgrade() -> None:
    pass
