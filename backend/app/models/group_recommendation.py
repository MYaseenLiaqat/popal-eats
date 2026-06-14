"""Persisted group recommendation snapshot for voting."""

from sqlalchemy import Column, DateTime, ForeignKey, Integer, Numeric
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func

from app.database import Base


class GroupRecommendation(Base):
    __tablename__ = "group_recommendations"

    id = Column(Integer, primary_key=True, index=True)
    session_id = Column(
        Integer, ForeignKey("group_sessions.id", ondelete="CASCADE"), nullable=False, index=True
    )
    dish_id = Column(Integer, ForeignKey("dishes.id", ondelete="CASCADE"), nullable=False, index=True)
    recommendation_score = Column(Numeric(5, 2), nullable=False)
    consensus_score = Column(Numeric(5, 2), nullable=False, default=0)
    final_score = Column(Numeric(5, 2), nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)

    session = relationship("GroupSession", back_populates="group_recommendations")
    dish = relationship("Dish")
    votes = relationship(
        "GroupVote",
        back_populates="recommendation",
        cascade="all, delete-orphan",
    )
    decisions = relationship(
        "GroupDecision",
        back_populates="recommendation",
        cascade="all, delete-orphan",
    )
