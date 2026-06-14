"""Group consensus decision for a session."""

from sqlalchemy import Column, DateTime, ForeignKey, Integer, String, UniqueConstraint
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func

from app.database import Base

PENDING = "pending"
CONSIDERING = "considering"
AGREED = "agreed"
ORDERED = "ordered"

DECISION_STATUSES = frozenset({PENDING, CONSIDERING, AGREED, ORDERED})


class GroupDecision(Base):
    __tablename__ = "group_decisions"
    __table_args__ = (UniqueConstraint("session_id", name="uq_group_decisions_session"),)

    id = Column(Integer, primary_key=True, index=True)
    session_id = Column(
        Integer, ForeignKey("group_sessions.id", ondelete="CASCADE"), nullable=False, index=True
    )
    recommendation_id = Column(
        Integer,
        ForeignKey("group_recommendations.id", ondelete="SET NULL"),
        nullable=True,
        index=True,
    )
    status = Column(String(16), nullable=False, default=PENDING, index=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    updated_at = Column(
        DateTime(timezone=True),
        server_default=func.now(),
        onupdate=func.now(),
        nullable=False,
    )

    session = relationship("GroupSession", back_populates="group_decision")
    recommendation = relationship("GroupRecommendation", back_populates="decisions")
