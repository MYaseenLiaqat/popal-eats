"""
SQLAlchemy ORM model for the `users` table.

Maps Python classes to PostgreSQL rows (Object-Relational Mapping).
"""

from sqlalchemy import Column, DateTime, Integer, String
from sqlalchemy.sql import func

from app.database import Base


class User(Base):
    """Registered Popal Eats user."""

    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    full_name = Column(String, nullable=False)
    # unique=True prevents two accounts with the same email
    email = Column(String, unique=True, index=True, nullable=False)
    # Never store plain passwords — only password_hash (see core/security.py)
    password_hash = Column(String, nullable=False)
    role = Column(String, default="user", nullable=False)
    profile_image = Column(String, nullable=True)
    # server_default=func.now() sets timestamp when the row is inserted (DB side)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
