"""Member of a group recommendation session."""

from sqlalchemy import Column, DateTime, ForeignKey, Integer, UniqueConstraint
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func

from app.database import Base


class GroupSessionMember(Base):
    __tablename__ = "group_session_members"
    __table_args__ = (
        UniqueConstraint("session_id", "user_id", name="uq_group_session_members_session_user"),
    )

    id = Column(Integer, primary_key=True, index=True)
    session_id = Column(
        Integer, ForeignKey("group_sessions.id", ondelete="CASCADE"), nullable=False, index=True
    )
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    joined_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)

    session = relationship("GroupSession", back_populates="members")
    user = relationship("User", back_populates="group_session_memberships")
