"""SQLAlchemy ORM model for user_preferences (1:1 with users)."""

from sqlalchemy import Column, DateTime, ForeignKey, Integer, Numeric, String
from sqlalchemy.dialects.postgresql import JSON
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func

from app.database import Base


class UserPreference(Base):
    __tablename__ = "user_preferences"

    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), primary_key=True)
    favorite_cuisines = Column(JSON, nullable=True)
    dietary_preference = Column(String(64), nullable=True)
    dietary_preferences = Column(JSON, nullable=True)
    nutrition_goal = Column(String(64), nullable=True)
    budget_min = Column(Numeric(10, 2), nullable=True)
    budget_max = Column(Numeric(10, 2), nullable=True)
    budget_level = Column(String(16), nullable=True)
    disliked_categories = Column(JSON, nullable=True)
    allergies = Column(JSON, nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    updated_at = Column(
        DateTime(timezone=True),
        server_default=func.now(),
        onupdate=func.now(),
        nullable=False,
    )

    user = relationship("User", back_populates="preferences")
