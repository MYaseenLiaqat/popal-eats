"""Initial schema — all core tables.

Revision ID: 001_initial
Revises:
Create Date: 2026-05-22

"""
from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op

revision: str = "001_initial"
down_revision: Union[str, None] = None
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        "users",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("full_name", sa.String(), nullable=False),
        sa.Column("email", sa.String(length=255), nullable=False),
        sa.Column("password_hash", sa.String(), nullable=False),
        sa.Column("role", sa.String(length=32), nullable=False, server_default="customer"),
        sa.Column("profile_image", sa.String(length=500), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=True),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index("ix_users_email", "users", ["email"], unique=True)
    op.create_index("ix_users_id", "users", ["id"], unique=False)
    op.create_index("ix_users_role", "users", ["role"], unique=False)

    op.create_table(
        "categories",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("name", sa.String(length=120), nullable=False),
        sa.Column("description", sa.Text(), nullable=True),
        sa.Column("image", sa.String(length=500), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=True),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index("ix_categories_id", "categories", ["id"], unique=False)
    op.create_index("ix_categories_name", "categories", ["name"], unique=True)

    op.create_table(
        "restaurants",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("owner_id", sa.Integer(), nullable=False),
        sa.Column("name", sa.String(length=200), nullable=False),
        sa.Column("description", sa.Text(), nullable=True),
        sa.Column("address", sa.String(length=300), nullable=True),
        sa.Column("city", sa.String(length=100), nullable=True),
        sa.Column("phone_number", sa.String(length=30), nullable=True),
        sa.Column("image", sa.String(length=500), nullable=True),
        sa.Column("opening_time", sa.Time(), nullable=True),
        sa.Column("closing_time", sa.Time(), nullable=True),
        sa.Column("is_open", sa.Boolean(), nullable=False, server_default=sa.text("true")),
        sa.Column("average_rating", sa.Float(), nullable=False, server_default="0"),
        sa.Column("total_reviews", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=True),
        sa.ForeignKeyConstraint(["owner_id"], ["users.id"]),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index("ix_restaurants_city", "restaurants", ["city"], unique=False)
    op.create_index("ix_restaurants_id", "restaurants", ["id"], unique=False)
    op.create_index("ix_restaurants_name", "restaurants", ["name"], unique=False)
    op.create_index("ix_restaurants_owner_id", "restaurants", ["owner_id"], unique=False)

    op.create_table(
        "dishes",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("restaurant_id", sa.Integer(), nullable=False),
        sa.Column("category_id", sa.Integer(), nullable=False),
        sa.Column("name", sa.String(length=200), nullable=False),
        sa.Column("description", sa.Text(), nullable=True),
        sa.Column("price", sa.Numeric(10, 2), nullable=False),
        sa.Column("calories", sa.Integer(), nullable=True),
        sa.Column("protein", sa.Numeric(8, 2), nullable=True),
        sa.Column("carbs", sa.Numeric(8, 2), nullable=True),
        sa.Column("fats", sa.Numeric(8, 2), nullable=True),
        sa.Column("image", sa.String(length=500), nullable=True),
        sa.Column("is_available", sa.Boolean(), nullable=False, server_default=sa.text("true")),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=True),
        sa.ForeignKeyConstraint(["category_id"], ["categories.id"], ondelete="RESTRICT"),
        sa.ForeignKeyConstraint(["restaurant_id"], ["restaurants.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index("ix_dishes_category_id", "dishes", ["category_id"], unique=False)
    op.create_index("ix_dishes_id", "dishes", ["id"], unique=False)
    op.create_index("ix_dishes_name", "dishes", ["name"], unique=False)
    op.create_index("ix_dishes_restaurant_id", "dishes", ["restaurant_id"], unique=False)

    op.create_table(
        "reviews",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("user_id", sa.Integer(), nullable=False),
        sa.Column("restaurant_id", sa.Integer(), nullable=False),
        sa.Column("rating", sa.Integer(), nullable=False),
        sa.Column("comment", sa.Text(), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=True),
        sa.ForeignKeyConstraint(["restaurant_id"], ["restaurants.id"], ondelete="CASCADE"),
        sa.ForeignKeyConstraint(["user_id"], ["users.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("user_id", "restaurant_id", name="uq_review_user_restaurant"),
    )
    op.create_index("ix_reviews_id", "reviews", ["id"], unique=False)
    op.create_index("ix_reviews_restaurant_id", "reviews", ["restaurant_id"], unique=False)
    op.create_index("ix_reviews_user_id", "reviews", ["user_id"], unique=False)

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
    op.create_index("ix_menu_uploads_id", "menu_uploads", ["id"], unique=False)
    op.create_index("ix_menu_uploads_restaurant_id", "menu_uploads", ["restaurant_id"], unique=False)
    op.create_index("ix_menu_uploads_status", "menu_uploads", ["status"], unique=False)
    op.create_index("ix_menu_uploads_uploaded_by", "menu_uploads", ["uploaded_by"], unique=False)


def downgrade() -> None:
    op.drop_table("menu_uploads")
    op.drop_table("reviews")
    op.drop_table("dishes")
    op.drop_table("restaurants")
    op.drop_table("categories")
    op.drop_table("users")
