"""
Category model — groups dishes (e.g. Pizza, Burgers, Drinks).

One category can have many dishes (one-to-many).
"""

from sqlalchemy import Column, DateTime, Integer, String, Text
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func

from app.database import Base


class Category(Base):
    __tablename__ = "categories"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(120), unique=True, nullable=False, index=True)
    description = Column(Text, nullable=True)
    # Image URL string (Firebase/cloud storage later)
    image = Column(String(500), nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    # One category → many dishes
    dishes = relationship("Dish", back_populates="category")
