"""
SQLAlchemy ORM model for the `users` table.

Maps Python classes to PostgreSQL rows (Object-Relational Mapping).
"""

from sqlalchemy import Column, DateTime, Integer, String
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func

from app.database import Base


class User(Base):
    """Registered Popal Eats user."""

    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    full_name = Column(String, nullable=False)
    email = Column(String, unique=True, index=True, nullable=False)
    password_hash = Column(String, nullable=False)
    role = Column(String, default="user", nullable=False)
    profile_image = Column(String, nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    # One user (owner) can own many restaurants
    restaurants = relationship("Restaurant", back_populates="owner")
