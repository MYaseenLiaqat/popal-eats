"""SQLAlchemy ORM model for the `users` table."""

from sqlalchemy import Column, DateTime, Integer, String
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func

from app.core.roles import CUSTOMER
from app.database import Base


class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    full_name = Column(String, nullable=False)
    email = Column(String(255), unique=True, index=True, nullable=False)
    password_hash = Column(String, nullable=False)
    role = Column(String(32), default=CUSTOMER, nullable=False, index=True)
    profile_image = Column(String(500), nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    restaurants = relationship("Restaurant", back_populates="owner")
    reviews = relationship("Review", back_populates="user", cascade="all, delete-orphan")
    cart = relationship("Cart", back_populates="user", uselist=False, cascade="all, delete-orphan")
    orders = relationship("Order", back_populates="user")
    preferences = relationship(
        "UserPreference",
        back_populates="user",
        uselist=False,
        cascade="all, delete-orphan",
    )
