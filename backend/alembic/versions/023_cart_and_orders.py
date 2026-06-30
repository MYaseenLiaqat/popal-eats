"""Cart and order commerce tables (checkout flow).

Revision ID: 023_cart_and_orders
Revises: 022_home_chef_kitchen
Create Date: 2026-06-05

Creates carts, cart_items, orders, and order_items to match ORM models in
app.models.cart, cart_item, order, and order_item.

Skips creation when a table already exists (e.g. manually created on legacy DBs).
"""

from __future__ import annotations

from typing import Sequence, Union

import sqlalchemy as sa
from alembic import context, op
from sqlalchemy import inspect

revision: str = "023_cart_and_orders"
down_revision: Union[str, None] = "022_home_chef_kitchen"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def _table_exists(name: str, *, for_downgrade: bool = False) -> bool:
    """Return whether `name` is present. Offline SQL mode always emits DDL."""
    if context.is_offline_mode():
        return for_downgrade
    bind = op.get_bind()
    return name in inspect(bind).get_table_names()


def upgrade() -> None:
    if not _table_exists("carts"):
        op.create_table(
            "carts",
            sa.Column("id", sa.Integer(), nullable=False),
            sa.Column("user_id", sa.Integer(), nullable=False),
            sa.Column(
                "created_at",
                sa.DateTime(timezone=True),
                server_default=sa.text("now()"),
                nullable=True,
            ),
            sa.ForeignKeyConstraint(["user_id"], ["users.id"], ondelete="CASCADE"),
            sa.PrimaryKeyConstraint("id"),
            sa.UniqueConstraint("user_id", name="uq_carts_user_id"),
        )
        op.create_index("ix_carts_id", "carts", ["id"], unique=False)
        op.create_index("ix_carts_user_id", "carts", ["user_id"], unique=False)

    if not _table_exists("cart_items"):
        op.create_table(
            "cart_items",
            sa.Column("id", sa.Integer(), nullable=False),
            sa.Column("cart_id", sa.Integer(), nullable=False),
            sa.Column("dish_id", sa.Integer(), nullable=False),
            sa.Column("quantity", sa.Integer(), nullable=False),
            sa.Column(
                "created_at",
                sa.DateTime(timezone=True),
                server_default=sa.text("now()"),
                nullable=True,
            ),
            sa.ForeignKeyConstraint(["cart_id"], ["carts.id"], ondelete="CASCADE"),
            sa.ForeignKeyConstraint(["dish_id"], ["dishes.id"], ondelete="CASCADE"),
            sa.PrimaryKeyConstraint("id"),
            sa.UniqueConstraint("cart_id", "dish_id", name="uq_cart_items_cart_dish"),
        )
        op.create_index("ix_cart_items_id", "cart_items", ["id"], unique=False)
        op.create_index("ix_cart_items_cart_id", "cart_items", ["cart_id"], unique=False)
        op.create_index("ix_cart_items_dish_id", "cart_items", ["dish_id"], unique=False)

    if not _table_exists("orders"):
        op.create_table(
            "orders",
            sa.Column("id", sa.Integer(), nullable=False),
            sa.Column("user_id", sa.Integer(), nullable=False),
            sa.Column("restaurant_id", sa.Integer(), nullable=False),
            sa.Column("total_price", sa.Numeric(precision=10, scale=2), nullable=False),
            sa.Column("status", sa.String(length=30), nullable=False),
            sa.Column("payment_status", sa.String(length=30), nullable=False),
            sa.Column("delivery_address", sa.String(length=500), nullable=False),
            sa.Column("rider_name", sa.String(length=120), nullable=True),
            sa.Column(
                "created_at",
                sa.DateTime(timezone=True),
                server_default=sa.text("now()"),
                nullable=True,
            ),
            sa.ForeignKeyConstraint(["user_id"], ["users.id"], ondelete="CASCADE"),
            sa.ForeignKeyConstraint(["restaurant_id"], ["restaurants.id"], ondelete="CASCADE"),
            sa.PrimaryKeyConstraint("id"),
        )
        op.create_index("ix_orders_id", "orders", ["id"], unique=False)
        op.create_index("ix_orders_user_id", "orders", ["user_id"], unique=False)
        op.create_index("ix_orders_restaurant_id", "orders", ["restaurant_id"], unique=False)
        op.create_index("ix_orders_status", "orders", ["status"], unique=False)

    if not _table_exists("order_items"):
        op.create_table(
            "order_items",
            sa.Column("id", sa.Integer(), nullable=False),
            sa.Column("order_id", sa.Integer(), nullable=False),
            sa.Column("dish_id", sa.Integer(), nullable=False),
            sa.Column("quantity", sa.Integer(), nullable=False),
            sa.Column("price", sa.Numeric(precision=10, scale=2), nullable=False),
            sa.Column(
                "created_at",
                sa.DateTime(timezone=True),
                server_default=sa.text("now()"),
                nullable=True,
            ),
            sa.ForeignKeyConstraint(["order_id"], ["orders.id"], ondelete="CASCADE"),
            sa.ForeignKeyConstraint(["dish_id"], ["dishes.id"], ondelete="RESTRICT"),
            sa.PrimaryKeyConstraint("id"),
        )
        op.create_index("ix_order_items_id", "order_items", ["id"], unique=False)
        op.create_index("ix_order_items_order_id", "order_items", ["order_id"], unique=False)
        op.create_index("ix_order_items_dish_id", "order_items", ["dish_id"], unique=False)


def downgrade() -> None:
    if _table_exists("order_items", for_downgrade=True):
        op.drop_index("ix_order_items_dish_id", table_name="order_items")
        op.drop_index("ix_order_items_order_id", table_name="order_items")
        op.drop_index("ix_order_items_id", table_name="order_items")
        op.drop_table("order_items")

    if _table_exists("orders", for_downgrade=True):
        op.drop_index("ix_orders_status", table_name="orders")
        op.drop_index("ix_orders_restaurant_id", table_name="orders")
        op.drop_index("ix_orders_user_id", table_name="orders")
        op.drop_index("ix_orders_id", table_name="orders")
        op.drop_table("orders")

    if _table_exists("cart_items", for_downgrade=True):
        op.drop_index("ix_cart_items_dish_id", table_name="cart_items")
        op.drop_index("ix_cart_items_cart_id", table_name="cart_items")
        op.drop_index("ix_cart_items_id", table_name="cart_items")
        op.drop_table("cart_items")

    if _table_exists("carts", for_downgrade=True):
        op.drop_index("ix_carts_user_id", table_name="carts")
        op.drop_index("ix_carts_id", table_name="carts")
        op.drop_table("carts")
