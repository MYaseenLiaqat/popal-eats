"""
ORM models — import all models so Base.metadata registers tables for create_all.
"""

from app.models.category import Category
from app.models.dish import Dish
from app.models.restaurant import Restaurant
from app.models.user import User

__all__ = ["User", "Category", "Restaurant", "Dish"]
