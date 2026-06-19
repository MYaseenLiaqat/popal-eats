"""Unified social post model."""

from sqlalchemy import Column, DateTime, ForeignKey, Integer, String, Text
from sqlalchemy.dialects.postgresql import JSON
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func

from app.database import Base


class Post(Base):
    __tablename__ = "posts"

    id = Column(Integer, primary_key=True, index=True)
    author_id = Column(
        Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True
    )
    post_type = Column(String(32), nullable=False, index=True)
    caption = Column(Text, nullable=True)
    title = Column(String(200), nullable=True)
    images = Column(JSON, nullable=True)
    video_url = Column(String(500), nullable=True)
    restaurant_id = Column(
        Integer, ForeignKey("restaurants.id", ondelete="SET NULL"), nullable=True, index=True
    )
    dish_id = Column(Integer, ForeignKey("dishes.id", ondelete="SET NULL"), nullable=True)
    restaurant_content_subtype = Column(String(32), nullable=True)
    recipe_description = Column(Text, nullable=True)
    recipe_ingredients = Column(JSON, nullable=True)
    recipe_steps = Column(JSON, nullable=True)
    like_count = Column(Integer, default=0, nullable=False, server_default="0")
    comment_count = Column(Integer, default=0, nullable=False, server_default="0")
    save_count = Column(Integer, default=0, nullable=False, server_default="0")
    created_at = Column(DateTime(timezone=True), server_default=func.now(), index=True)
    updated_at = Column(
        DateTime(timezone=True), server_default=func.now(), onupdate=func.now()
    )

    author = relationship("User", back_populates="posts")
    restaurant = relationship("Restaurant", back_populates="posts")
    dish = relationship("Dish", back_populates="posts")
    likes = relationship("PostLike", back_populates="post", cascade="all, delete-orphan")
    comments = relationship(
        "PostComment", back_populates="post", cascade="all, delete-orphan"
    )
    saves = relationship("PostSave", back_populates="post", cascade="all, delete-orphan")
