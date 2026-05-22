"""
Order access control and status transitions.
"""

from fastapi import HTTPException, status
from sqlalchemy.orm import Session, joinedload

from app.core.constants import ORDER_STATUS_TRANSITIONS, ORDER_STATUSES
from app.core.permissions import assert_restaurant_owner, get_restaurant_or_404
from app.models.order import Order
from app.models.user import User


def get_order_or_404(db: Session, order_id: int) -> Order:
    order = (
        db.query(Order)
        .options(joinedload(Order.items))
        .filter(Order.id == order_id)
        .first()
    )
    if not order:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Order not found")
    return order


def assert_order_customer(order: Order, user: User) -> None:
    if order.user_id != user.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="You can only access your own orders",
        )


def assert_order_customer_or_restaurant_owner(order: Order, user: User, db: Session) -> None:
    if order.user_id == user.id:
        return
    restaurant = get_restaurant_or_404(db, order.restaurant_id)
    if restaurant.owner_id == user.id:
        return
    raise HTTPException(
        status_code=status.HTTP_403_FORBIDDEN,
        detail="You do not have permission to view this order",
    )


def validate_status_transition(current: str, new_status: str) -> None:
    if new_status not in ORDER_STATUSES:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Invalid status. Allowed: {', '.join(sorted(ORDER_STATUSES))}",
        )
    allowed = ORDER_STATUS_TRANSITIONS.get(current, set())
    if new_status not in allowed:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Cannot change status from '{current}' to '{new_status}'",
        )


def update_order_status(
    db: Session,
    order: Order,
    new_status: str,
    rider_name: str | None,
    current_user: User,
) -> Order:
    restaurant = get_restaurant_or_404(db, order.restaurant_id)
    assert_restaurant_owner(restaurant, current_user)
    validate_status_transition(order.status, new_status)
    order.status = new_status
    if rider_name is not None:
        order.rider_name = rider_name
    db.commit()
    db.refresh(order)
    return order
