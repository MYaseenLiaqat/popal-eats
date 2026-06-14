"""Temporary group recommendation session."""

from sqlalchemy import Column, DateTime, ForeignKey, Integer, String
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func

from app.database import Base

ACTIVE = "active"
CLOSED = "closed"


class GroupSession(Base):
    __tablename__ = "group_sessions"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(120), nullable=False)
    host_user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    status = Column(String(16), nullable=False, default=ACTIVE, index=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    expires_at = Column(DateTime(timezone=True), nullable=False)

    host = relationship("User", foreign_keys=[host_user_id], back_populates="hosted_group_sessions")
    members = relationship(
        "GroupSessionMember",
        back_populates="session",
        cascade="all, delete-orphan",
    )
    invitations = relationship(
        "GroupInvitation",
        back_populates="session",
        cascade="all, delete-orphan",
    )
    member_locations = relationship(
        "GroupMemberLocation",
        back_populates="session",
        cascade="all, delete-orphan",
    )
