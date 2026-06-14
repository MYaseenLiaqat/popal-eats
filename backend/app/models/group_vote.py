"""Member vote on a group recommendation snapshot."""

from sqlalchemy import Column, DateTime, ForeignKey, Integer, String, UniqueConstraint
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func

from app.database import Base

LIKE = "LIKE"
LOVE = "LOVE"
DISLIKE = "DISLIKE"

VOTE_TYPES = frozenset({LIKE, LOVE, DISLIKE})


class GroupVote(Base):
    __tablename__ = "group_votes"
    __table_args__ = (
        UniqueConstraint(
            "recommendation_id",
            "user_id",
            name="uq_group_votes_recommendation_user",
        ),
    )

    id = Column(Integer, primary_key=True, index=True)
    recommendation_id = Column(
        Integer,
        ForeignKey("group_recommendations.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    vote_type = Column(String(16), nullable=False, index=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)

    recommendation = relationship("GroupRecommendation", back_populates="votes")
    user = relationship("User", back_populates="group_votes")
