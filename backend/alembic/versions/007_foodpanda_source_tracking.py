"""Foodpanda source-tracking columns on restaurants and dishes.

Revision ID: 007_foodpanda_source
Revises: 006_recommendation_events
Create Date: 2026-06-09

Note: tags columns already added in 005_tags — not recreated here.
"""

from __future__ import annotations

from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op

revision: str = "007_foodpanda_source"
down_revision: Union[str, None] = "006_recommendation_events"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None

VENDOR_CODE_PREFIX = "Foodpanda vendor_code:"
VENDOR_ID_PREFIX = "Foodpanda vendor_id:"


def _parse_description(description: str | None) -> tuple[str | None, str | None]:
    """Extract (external_code, external_id) from legacy Foodpanda description lines."""
    if not description:
        return None, None
    code: str | None = None
    ext_id: str | None = None
    for line in description.splitlines():
        line = line.strip()
        if line.startswith(VENDOR_CODE_PREFIX):
            code = line[len(VENDOR_CODE_PREFIX) :].strip() or None
        elif line.startswith(VENDOR_ID_PREFIX):
            ext_id = line[len(VENDOR_ID_PREFIX) :].strip() or None
    return code, ext_id


def upgrade() -> None:
    op.add_column("restaurants", sa.Column("source", sa.String(length=32), nullable=True))
    op.add_column("restaurants", sa.Column("external_id", sa.String(length=64), nullable=True))
    op.add_column("restaurants", sa.Column("external_code", sa.String(length=64), nullable=True))
    op.create_index("ix_restaurants_source", "restaurants", ["source"], unique=False)
    op.create_index("ix_restaurants_external_code", "restaurants", ["external_code"], unique=False)
    op.create_index(
        "uq_restaurants_source_external_code",
        "restaurants",
        ["source", "external_code"],
        unique=True,
        postgresql_where=sa.text("source IS NOT NULL AND external_code IS NOT NULL"),
    )

    op.add_column("dishes", sa.Column("source", sa.String(length=32), nullable=True))
    op.add_column("dishes", sa.Column("external_id", sa.String(length=64), nullable=True))
    op.create_index("ix_dishes_source", "dishes", ["source"], unique=False)
    op.create_index(
        "uq_dishes_restaurant_source_external_id",
        "dishes",
        ["restaurant_id", "source", "external_id"],
        unique=True,
        postgresql_where=sa.text("source IS NOT NULL AND external_id IS NOT NULL"),
    )

    conn = op.get_bind()
    rows = conn.execute(
        sa.text(
            "SELECT id, description FROM restaurants "
            "WHERE description IS NOT NULL AND description LIKE :pattern"
        ),
        {"pattern": "%Imported from Foodpanda.%"},
    ).fetchall()

    for row_id, description in rows:
        code, ext_id = _parse_description(description)
        if not code and not ext_id:
            continue
        conn.execute(
            sa.text(
                "UPDATE restaurants SET source = :source, external_code = :code, external_id = :ext_id "
                "WHERE id = :id"
            ),
            {
                "source": "foodpanda",
                "code": code,
                "ext_id": ext_id,
                "id": row_id,
            },
        )


def downgrade() -> None:
    op.drop_index("uq_dishes_restaurant_source_external_id", table_name="dishes")
    op.drop_index("ix_dishes_source", table_name="dishes")
    op.drop_column("dishes", "external_id")
    op.drop_column("dishes", "source")

    op.drop_index("uq_restaurants_source_external_code", table_name="restaurants")
    op.drop_index("ix_restaurants_external_code", table_name="restaurants")
    op.drop_index("ix_restaurants_source", table_name="restaurants")
    op.drop_column("restaurants", "external_code")
    op.drop_column("restaurants", "external_id")
    op.drop_column("restaurants", "source")
