"""
Checkout — convert cart to order, snapshot prices, clear cart.

Mock payment: payment_status set to 'paid' on successful checkout.
"""

from decimal import Decimal

from fastapi import HTTPException, status
from sqlalchemy.orm import Session

from app.core.constants import ORDER_STATUS_PENDING, PAYMENT_STATUS_PAID
from app.models.order import Order
from app.models.order_item import OrderItem
from app.models.user import User
from app.services.cart_service import (
    cart_subtotal,
    clear_cart,
    get_user_cart_with_items,
    validate_single_restaurant,
)


def checkout(db: Session, user: User, delivery_address: str) -> Order:
    cart = get_user_cart_with_items(db, user)

    if not cart.items:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Cart is empty. Add dishes before checkout.",
        )

    restaurant_id = validate_single_restaurant(cart)
    if not restaurant_id:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Invalid cart")

    for item in cart.items:
        if not item.dish or not item.dish.is_available:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Dish id {item.dish_id} is no longer available",
            )

    total = cart_subtotal(cart)

    order = Order(
        user_id=user.id,
        restaurant_id=restaurant_id,
        total_price=total,
        status=ORDER_STATUS_PENDING,
        payment_status=PAYMENT_STATUS_PAID,  # mock payment success
        delivery_address=delivery_address,
    )
    db.add(order)
    db.flush()

    for item in cart.items:
        unit_price = Decimal(str(item.dish.price))
        db.add(
            OrderItem(
                order_id=order.id,
                dish_id=item.dish_id,
                quantity=item.quantity,
                price=unit_price,
            )
        )

    clear_cart(db, user)
    db.commit()
    db.refresh(order)
    return order
