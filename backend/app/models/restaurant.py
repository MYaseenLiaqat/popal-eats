"""
Restaurant model — owned by a user (restaurant owner).

ForeignKey owner_id links to users.id (ownership).
One restaurant can have many dishes.
"""

from sqlalchemy import Boolean, Column, DateTime, Float, ForeignKey, Integer, String, Text, Time
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func

from app.database import Base


class Restaurant(Base):
    __tablename__ = "restaurants"

    id = Column(Integer, primary_key=True, index=True)
    # owner_id: which user owns this restaurant (FK → users.id)
    owner_id = Column(Integer, ForeignKey("users.id"), nullable=False, index=True)
    name = Column(String(200), nullable=False, index=True)
    description = Column(Text, nullable=True)
    address = Column(String(300), nullable=True)
    city = Column(String(100), nullable=True)
    phone_number = Column(String(30), nullable=True)
    image = Column(String(500), nullable=True)
    opening_time = Column(Time, nullable=True)
    closing_time = Column(Time, nullable=True)
    is_open = Column(Boolean, default=True, nullable=False)
    rating = Column(Float, default=0.0, nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    # Many restaurants belong to one user (owner)
    owner = relationship("User", back_populates="restaurants")
    # One restaurant → many dishes
    dishes = relationship(
        "Dish",
        back_populates="restaurant",
        cascade="all, delete-orphan",
    )
