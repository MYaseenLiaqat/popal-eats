"""
Cart API — add/update/remove items, view cart, clear cart.
All routes require authentication (JWT).
"""

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.core.dependencies import get_current_user
from app.core.rbac import require_customer
from app.database import get_db
from app.models.cart import Cart
from app.models.cart_item import CartItem
from app.models.user import User
from app.schemas.cart import CartItemAdd, CartItemResponse, CartItemUpdate, CartResponse
from app.schemas.dish import DishResponse
from app.services.cart_service import (
    add_dish_to_cart,
    cart_restaurant_id,
    cart_subtotal,
    clear_cart,
    get_or_create_cart,
    get_user_cart_with_items,
)

router = APIRouter(prefix="/cart", tags=["cart"])


def _build_cart_response(cart: Cart) -> CartResponse:
    rid = cart_restaurant_id(cart)
    if rid == -1:
        rid = None
    items_out: list[CartItemResponse] = []
    for item in cart.items:
        row = CartItemResponse.model_validate(item)
        if item.dish:
            row.dish = DishResponse.model_validate(item.dish)
        items_out.append(row)
    return CartResponse(
        id=cart.id,
        user_id=cart.user_id,
        created_at=cart.created_at,
        items=items_out,
        restaurant_id=rid,
        subtotal=cart_subtotal(cart),
    )


def _get_cart_item_for_user(db: Session, user: User, item_id: int) -> CartItem:
    item = (
        db.query(CartItem)
        .join(Cart)
        .filter(CartItem.id == item_id, Cart.user_id == user.id)
        .first()
    )
    if not item:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=(
                f"Cart item id {item_id} not found. "
                "Use GET /cart to see valid item ids after POST /cart/add."
            ),
        )
    return item


@router.post("/add", response_model=CartItemResponse, summary="Add dish to cart")
def cart_add(
    body: CartItemAdd,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_customer),
):
    item = add_dish_to_cart(db, current_user, body.dish_id, body.quantity)
    db.refresh(item)
    return CartItemResponse.model_validate(item)


@router.get("", response_model=CartResponse, summary="View current user's cart")
def cart_get(
    db: Session = Depends(get_db),
    current_user: User = Depends(require_customer),
):
    cart = get_user_cart_with_items(db, current_user)
    return _build_cart_response(cart)


@router.put("/items/{item_id}", response_model=CartItemResponse, summary="Update cart item quantity")
def cart_update_item(
    item_id: int,
    body: CartItemUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_customer),
):
    item = _get_cart_item_for_user(db, current_user, item_id)
    item.quantity = body.quantity
    db.commit()
    db.refresh(item)
    return CartItemResponse.model_validate(item)


@router.delete("/items/{item_id}", status_code=status.HTTP_204_NO_CONTENT, summary="Remove cart item")
def cart_delete_item(
    item_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_customer),
):
    item = _get_cart_item_for_user(db, current_user, item_id)
    db.delete(item)
    db.commit()
    return None


@router.delete("/clear", status_code=status.HTTP_204_NO_CONTENT, summary="Clear all cart items")
def cart_clear(
    db: Session = Depends(get_db),
    current_user: User = Depends(require_customer),
):
    clear_cart(db, current_user)
    return None
