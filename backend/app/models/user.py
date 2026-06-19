"""SQLAlchemy ORM model for the `users` table."""

from sqlalchemy import Boolean, Column, DateTime, Integer, String, Text
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func

from app.core.roles import CUSTOMER
from app.database import Base


class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    full_name = Column(String, nullable=False)
    email = Column(String(255), unique=True, index=True, nullable=False)
    password_hash = Column(String, nullable=True)
    role = Column(String(32), default=CUSTOMER, nullable=False, index=True)
    username = Column(String(32), unique=True, index=True, nullable=True)
    phone = Column(String(20), nullable=True)
    city = Column(String(100), nullable=True)
    google_id = Column(String(128), unique=True, index=True, nullable=True)
    bio = Column(Text, nullable=True)
    profile_image = Column(String(500), nullable=True)
    onboarding_completed = Column(Boolean, default=False, nullable=False, server_default="false")
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    restaurants = relationship("Restaurant", back_populates="owner")
    reviews = relationship("Review", back_populates="user", cascade="all, delete-orphan")
    cart = relationship("Cart", back_populates="user", uselist=False, cascade="all, delete-orphan")
    orders = relationship("Order", back_populates="user")
    preferences = relationship(
        "UserPreference",
        back_populates="user",
        uselist=False,
        cascade="all, delete-orphan",
    )
    sent_friend_requests = relationship(
        "FriendRequest",
        foreign_keys="FriendRequest.sender_id",
        back_populates="sender",
        cascade="all, delete-orphan",
    )
    received_friend_requests = relationship(
        "FriendRequest",
        foreign_keys="FriendRequest.receiver_id",
        back_populates="receiver",
        cascade="all, delete-orphan",
    )
    friendships = relationship(
        "Friendship",
        foreign_keys="Friendship.user_id",
        back_populates="user",
        cascade="all, delete-orphan",
    )
    hosted_group_sessions = relationship(
        "GroupSession",
        foreign_keys="GroupSession.host_user_id",
        back_populates="host",
        cascade="all, delete-orphan",
    )
    group_session_memberships = relationship(
        "GroupSessionMember",
        back_populates="user",
        cascade="all, delete-orphan",
    )
    sent_group_invitations = relationship(
        "GroupInvitation",
        foreign_keys="GroupInvitation.sender_id",
        back_populates="sender",
        cascade="all, delete-orphan",
    )
    received_group_invitations = relationship(
        "GroupInvitation",
        foreign_keys="GroupInvitation.receiver_id",
        back_populates="receiver",
        cascade="all, delete-orphan",
    )
    group_member_locations = relationship(
        "GroupMemberLocation",
        back_populates="user",
        cascade="all, delete-orphan",
    )
    group_votes = relationship(
        "GroupVote",
        back_populates="user",
        cascade="all, delete-orphan",
    )
    posts = relationship("Post", back_populates="author", cascade="all, delete-orphan")
    stories = relationship("Story", back_populates="user", cascade="all, delete-orphan")
    post_likes = relationship("PostLike", back_populates="user", cascade="all, delete-orphan")
    post_comments = relationship(
        "PostComment", back_populates="user", cascade="all, delete-orphan"
    )
    post_saves = relationship("PostSave", back_populates="user", cascade="all, delete-orphan")
