"""
Order & checkout APIs.

Checkout: POST /checkout (cart → order).
Orders: history, detail, status updates, restaurant owner dashboard.
"""

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.orm import Session, joinedload

from app.core.dependencies import get_current_user
from app.core.rbac import assert_active_business_account, require_customer, require_restaurant, require_roles
from app.core.roles import ADMIN, HOME_CHEF, RESTAURANT
from app.core.permissions import assert_restaurant_owner, get_restaurant_or_404
from app.database import get_db
from app.models.order import Order
from app.models.user import User
from app.schemas.order import (
    CheckoutCreate,
    OrderResponse,
    OrderStatusUpdate,
)
from app.services.checkout_service import checkout
from app.services.order_service import (
    assert_order_customer,
    assert_order_customer_or_restaurant_owner,
    get_order_or_404,
    update_order_status,
)

# --- Checkout (no prefix) ---
checkout_router = APIRouter(tags=["checkout"])


@checkout_router.post(
    "/checkout",
    response_model=OrderResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Checkout — convert cart to order (mock payment)",
)
def checkout_order(
    body: CheckoutCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_customer),
):
    order = checkout(db, current_user, body.delivery_address)
    order = get_order_or_404(db, order.id)
    return OrderResponse.model_validate(order)


# --- Orders under /orders ---
router = APIRouter(prefix="/orders", tags=["orders"])
require_order_manager = require_roles(ADMIN, RESTAURANT, HOME_CHEF)


@router.get("/my-orders", response_model=list[OrderResponse], summary="List my orders")
def my_orders(
    skip: int = 0,
    limit: int = 50,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_customer),
):
    orders = (
        db.query(Order)
        .options(joinedload(Order.items))
        .filter(Order.user_id == current_user.id)
        .order_by(Order.created_at.desc())
        .offset(skip)
        .limit(limit)
        .all()
    )
    return [OrderResponse.model_validate(o) for o in orders]


@router.get("/{order_id}", response_model=OrderResponse, summary="Get order by id")
def get_order(
    order_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    order = get_order_or_404(db, order_id)
    assert_order_customer_or_restaurant_owner(order, current_user, db)
    return OrderResponse.model_validate(order)


@router.put("/{order_id}/status", response_model=OrderResponse, summary="Update order status (restaurant owner)")
def update_status(
    order_id: int,
    body: OrderStatusUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_order_manager),
):
    order = get_order_or_404(db, order_id)
    order = update_order_status(db, order, body.status, body.rider_name, current_user)
    order = get_order_or_404(db, order.id)
    return OrderResponse.model_validate(order)


# --- Restaurant orders: GET /restaurants/{id}/orders ---
restaurant_orders_router = APIRouter(prefix="/restaurants", tags=["orders"])


@restaurant_orders_router.get(
    "/{restaurant_id}/orders",
    response_model=list[OrderResponse],
    summary="List orders for a restaurant (owner only)",
)
def restaurant_orders(
    restaurant_id: int,
    skip: int = 0,
    limit: int = 50,
    status: str | None = Query(None, description="Filter by order status"),
    db: Session = Depends(get_db),
    current_user: User = Depends(require_restaurant),
):
    restaurant = get_restaurant_or_404(db, restaurant_id)
    assert_restaurant_owner(restaurant, current_user)
    query = (
        db.query(Order)
        .options(joinedload(Order.items))
        .filter(Order.restaurant_id == restaurant_id)
    )
    if status:
        query = query.filter(Order.status == status.strip().lower())
    orders = query.order_by(Order.created_at.desc()).offset(skip).limit(limit).all()
    return [OrderResponse.model_validate(o) for o in orders]
