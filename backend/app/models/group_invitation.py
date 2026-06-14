"""Invitation to join a group recommendation session."""

from sqlalchemy import Column, DateTime, ForeignKey, Integer, String, UniqueConstraint
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func

from app.database import Base

PENDING = "pending"
ACCEPTED = "accepted"
REJECTED = "rejected"


class GroupInvitation(Base):
    __tablename__ = "group_invitations"
    __table_args__ = (
        UniqueConstraint("session_id", "receiver_id", name="uq_group_invitations_session_receiver"),
    )

    id = Column(Integer, primary_key=True, index=True)
    session_id = Column(
        Integer, ForeignKey("group_sessions.id", ondelete="CASCADE"), nullable=False, index=True
    )
    sender_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    receiver_id = Column(
        Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True
    )
    status = Column(String(16), nullable=False, default=PENDING, index=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)

    session = relationship("GroupSession", back_populates="invitations")
    sender = relationship("User", foreign_keys=[sender_id], back_populates="sent_group_invitations")
    receiver = relationship(
        "User", foreign_keys=[receiver_id], back_populates="received_group_invitations"
    )
