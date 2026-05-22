"""
Cart business logic — get/create cart, add items, same-restaurant rule.
"""

from decimal import Decimal

from fastapi import HTTPException, status
from sqlalchemy.orm import Session, joinedload

from app.models.cart import Cart
from app.models.cart_item import CartItem
from app.models.dish import Dish
from app.models.user import User


def get_or_create_cart(db: Session, user: User) -> Cart:
    """One active cart per user (enforced by unique user_id on carts table)."""
    cart = db.query(Cart).filter(Cart.user_id == user.id).first()
    if not cart:
        cart = Cart(user_id=user.id)
        db.add(cart)
        db.commit()
        db.refresh(cart)
    return cart


def get_user_cart_with_items(db: Session, user: User) -> Cart:
    cart = (
        db.query(Cart)
        .options(joinedload(Cart.items).joinedload(CartItem.dish))
        .filter(Cart.user_id == user.id)
        .first()
    )
    if not cart:
        cart = get_or_create_cart(db, user)
        cart = (
            db.query(Cart)
            .options(joinedload(Cart.items).joinedload(CartItem.dish))
            .filter(Cart.id == cart.id)
            .first()
        )
    return cart


def cart_subtotal(cart: Cart) -> Decimal:
    total = Decimal("0.00")
    for item in cart.items:
        if item.dish:
            total += Decimal(str(item.dish.price)) * item.quantity
    return total


def cart_restaurant_id(cart: Cart) -> int | None:
    """All items must be from one restaurant; return that id or None if empty."""
    restaurant_ids = set()
    for item in cart.items:
        if item.dish:
            restaurant_ids.add(item.dish.restaurant_id)
    if len(restaurant_ids) > 1:
        return -1  # signal multiple restaurants
    return next(iter(restaurant_ids)) if restaurant_ids else None


def validate_single_restaurant(cart: Cart) -> int:
    rid = cart_restaurant_id(cart)
    if rid == -1:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Cart can only contain dishes from one restaurant. Clear cart or remove other items.",
        )
    return rid


def add_dish_to_cart(db: Session, user: User, dish_id: int, quantity: int) -> CartItem:
    dish = db.query(Dish).filter(Dish.id == dish_id).first()
    if not dish:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=(
                f"Dish id {dish_id} not found. "
                "Create a dish with POST /dishes first (use ids from that response)."
            ),
        )
    if not dish.is_available:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Dish is not available")

    cart = get_or_create_cart(db, user)

    existing_items = (
        db.query(CartItem)
        .options(joinedload(CartItem.dish))
        .filter(CartItem.cart_id == cart.id)
        .all()
    )
    if existing_items:
        cart.items = existing_items
        existing_rid = validate_single_restaurant(cart)
        if existing_rid and existing_rid != dish.restaurant_id:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="All cart items must be from the same restaurant",
            )

    existing_item = (
        db.query(CartItem)
        .filter(CartItem.cart_id == cart.id, CartItem.dish_id == dish_id)
        .first()
    )
    if existing_item:
        existing_item.quantity += quantity
        db.commit()
        db.refresh(existing_item)
        return existing_item

    item = CartItem(cart_id=cart.id, dish_id=dish_id, quantity=quantity)
    db.add(item)
    db.commit()
    db.refresh(item)
    return item


def clear_cart(db: Session, user: User) -> None:
    cart = db.query(Cart).filter(Cart.user_id == user.id).first()
    if cart:
        db.query(CartItem).filter(CartItem.cart_id == cart.id).delete()
        db.commit()
