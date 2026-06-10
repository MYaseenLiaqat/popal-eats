"""Restaurant model — owned by a user (restaurant owner)."""

from sqlalchemy import Boolean, Column, DateTime, Float, ForeignKey, Integer, String, Text, Time
from sqlalchemy.dialects.postgresql import JSON
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func

from app.database import Base


class Restaurant(Base):
    __tablename__ = "restaurants"

    id = Column(Integer, primary_key=True, index=True)
    owner_id = Column(Integer, ForeignKey("users.id"), nullable=False, index=True)
    name = Column(String(200), nullable=False, index=True)
    description = Column(Text, nullable=True)
    address = Column(String(300), nullable=True)
    city = Column(String(100), nullable=True, index=True)
    phone_number = Column(String(30), nullable=True)
    image = Column(String(500), nullable=True)
    opening_time = Column(Time, nullable=True)
    closing_time = Column(Time, nullable=True)
    is_open = Column(Boolean, default=True, nullable=False)
    average_rating = Column(Float, default=0.0, nullable=False)
    total_reviews = Column(Integer, default=0, nullable=False)
    source = Column(String(32), nullable=True, index=True)
    external_id = Column(String(64), nullable=True)
    external_code = Column(String(64), nullable=True, index=True)
    tags = Column(JSON, nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    owner = relationship("User", back_populates="restaurants")
    dishes = relationship(
        "Dish",
        back_populates="restaurant",
        cascade="all, delete-orphan",
    )
    reviews = relationship(
        "Review",
        back_populates="restaurant",
        cascade="all, delete-orphan",
    )
    menu_uploads = relationship("MenuUpload", back_populates="restaurant")
    orders = relationship("Order", back_populates="restaurant")
