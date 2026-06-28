"""Home chef profile — references users.id (no separate auth table)."""

from sqlalchemy import Column, DateTime, ForeignKey, Integer, String, Text
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func

from app.database import Base


class HomeChefProfile(Base):
    __tablename__ = "home_chef_profiles"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False, unique=True, index=True)
    display_name = Column(String(200), nullable=False)
    cuisine_specialty = Column(String(100), nullable=False)
    kitchen_address = Column(String(300), nullable=False)
    food_license = Column(String(100), nullable=True)
    profile_image = Column(String(500), nullable=True)
    biography = Column(Text, nullable=True)
    kitchen_restaurant_id = Column(
        Integer,
        ForeignKey("restaurants.id", ondelete="SET NULL"),
        nullable=True,
        unique=True,
        index=True,
    )
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())

    user = relationship("User", back_populates="home_chef_profile")
    kitchen_restaurant = relationship("Restaurant", foreign_keys=[kitchen_restaurant_id])
