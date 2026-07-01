"""User follows a restaurant (one-way, Instagram-style)."""

from sqlalchemy import Column, DateTime, ForeignKey, Integer, UniqueConstraint
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func

from app.database import Base


class RestaurantFollow(Base):
    __tablename__ = "restaurant_follows"
    __table_args__ = (
        UniqueConstraint("user_id", "restaurant_id", name="uq_restaurant_follows_user_restaurant"),
    )

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    restaurant_id = Column(
        Integer, ForeignKey("restaurants.id", ondelete="CASCADE"), nullable=False, index=True
    )
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)

    user = relationship("User", back_populates="restaurant_follows")
    restaurant = relationship("Restaurant", back_populates="followers")
