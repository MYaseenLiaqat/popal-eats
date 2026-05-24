"""Review model with AI processing fields."""

from sqlalchemy import Column, DateTime, Float, ForeignKey, Integer, String, Text, UniqueConstraint
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func

from app.database import Base


class Review(Base):
    __tablename__ = "reviews"
    __table_args__ = (
        UniqueConstraint("user_id", "restaurant_id", name="uq_review_user_restaurant"),
    )

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(
        Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True
    )
    restaurant_id = Column(
        Integer,
        ForeignKey("restaurants.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    rating = Column(Integer, nullable=False)
    comment = Column(Text, nullable=True)

    # AI pipeline outputs
    detected_language = Column(String(16), nullable=True, index=True)
    translated_text = Column(Text, nullable=True)
    sentiment = Column(String(32), nullable=True, index=True)
    sentiment_score = Column(Float, nullable=True)
    processing_status = Column(String(32), default="pending", nullable=False, index=True)
    processing_error = Column(Text, nullable=True)

    created_at = Column(DateTime(timezone=True), server_default=func.now())
    processed_at = Column(DateTime(timezone=True), nullable=True)

    user = relationship("User", back_populates="reviews")
    restaurant = relationship("Restaurant", back_populates="reviews")
