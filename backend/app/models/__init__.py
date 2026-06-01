"""ORM models — import all for Alembic metadata and table registration."""

from app.models.cart import Cart
from app.models.cart_item import CartItem
from app.models.category import Category
from app.models.dish import Dish
from app.models.menu_upload import MenuUpload
from app.models.order import Order
from app.models.order_item import OrderItem
from app.models.restaurant import Restaurant
from app.models.refresh_token import RefreshToken
from app.models.review import Review
from app.models.user import User
from app.models.user_preference import UserPreference

__all__ = [
    "User",
    "UserPreference",
    "Category",
    "Restaurant",
    "Dish",
    "Review",
    "MenuUpload",
    "RefreshToken",
    "Cart",
    "CartItem",
    "Order",
    "OrderItem",
]
