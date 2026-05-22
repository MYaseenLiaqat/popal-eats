"""ORM models — import all so Base.metadata registers tables for create_all."""

from app.models.cart import Cart
from app.models.cart_item import CartItem
from app.models.category import Category
from app.models.dish import Dish
from app.models.order import Order
from app.models.order_item import OrderItem
from app.models.restaurant import Restaurant
from app.models.user import User

__all__ = [
    "User",
    "Category",
    "Restaurant",
    "Dish",
    "Cart",
    "CartItem",
    "Order",
    "OrderItem",
]
