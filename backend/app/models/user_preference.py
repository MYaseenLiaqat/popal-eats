"""User preferences — one-to-one with users for recommendation and filtering."""

from sqlalchemy import JSON, Column, DateTime, ForeignKey, Integer, Numeric, String, UniqueConstraint
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func

from app.database import Base


class UserPreference(Base):
    __tablename__ = "user_preferences"
    __table_args__ = (UniqueConstraint("user_id", name="uq_user_preferences_user_id"),)

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(
        Integer,
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False,
        unique=True,
        index=True,
    )
    favorite_cuisines = Column(JSON, nullable=False, default=list)
    dietary_preference = Column(String(64), nullable=True)
    nutrition_goal = Column(String(64), nullable=True)
    budget_min = Column(Numeric(10, 2), nullable=True)
    budget_max = Column(Numeric(10, 2), nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(
        DateTime(timezone=True),
        server_default=func.now(),
        onupdate=func.now(),
    )

    user = relationship("User", back_populates="preferences")
