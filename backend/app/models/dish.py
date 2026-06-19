"""
Dish model — menu item belonging to a restaurant and category.

ForeignKeys link restaurant_id and category_id.
"""

from sqlalchemy import Boolean, Column, DateTime, ForeignKey, Integer, Numeric, String, Text
from sqlalchemy.dialects.postgresql import JSON
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func

from app.database import Base


class Dish(Base):
    __tablename__ = "dishes"

    id = Column(Integer, primary_key=True, index=True)
    restaurant_id = Column(
        Integer, ForeignKey("restaurants.id", ondelete="CASCADE"), nullable=False, index=True
    )
    category_id = Column(
        Integer, ForeignKey("categories.id", ondelete="RESTRICT"), nullable=False, index=True
    )
    name = Column(String(200), nullable=False, index=True)
    description = Column(Text, nullable=True)
    # Numeric(10,2) for money — avoids float rounding issues
    price = Column(Numeric(10, 2), nullable=False)
    calories = Column(Integer, nullable=True)
    protein = Column(Numeric(8, 2), nullable=True)
    carbs = Column(Numeric(8, 2), nullable=True)
    fats = Column(Numeric(8, 2), nullable=True)
    fiber = Column(Numeric(8, 2), nullable=True)
    sugar = Column(Numeric(8, 2), nullable=True)
    sodium = Column(Numeric(8, 2), nullable=True)
    cuisine = Column(String(100), nullable=True)
    ingredients = Column(JSON, nullable=True)
    allergens = Column(JSON, nullable=True)
    image = Column(String(500), nullable=True)
    images = Column(JSON, nullable=True)
    is_available = Column(Boolean, default=True, nullable=False)
    source = Column(String(32), nullable=True, index=True)
    external_id = Column(String(64), nullable=True)
    tags = Column(JSON, nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    restaurant = relationship("Restaurant", back_populates="dishes")
    category = relationship("Category", back_populates="dishes")
    cart_items = relationship("CartItem", back_populates="dish")
    order_items = relationship("OrderItem", back_populates="dish")
    posts = relationship("Post", back_populates="dish")
