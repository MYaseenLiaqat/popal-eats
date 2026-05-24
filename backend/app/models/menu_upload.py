"""
Menu upload records for OCR pipeline (Phase 9 preparation).

Stores upload metadata and extraction status; dishes link after import.
"""

from sqlalchemy import Column, DateTime, ForeignKey, Integer, String, Text
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func

from app.database import Base


class MenuUpload(Base):
    __tablename__ = "menu_uploads"

    id = Column(Integer, primary_key=True, index=True)
    restaurant_id = Column(
        Integer, ForeignKey("restaurants.id", ondelete="CASCADE"), nullable=False, index=True
    )
    uploaded_by = Column(Integer, ForeignKey("users.id"), nullable=False, index=True)
    file_path = Column(String(500), nullable=False)
    original_filename = Column(String(255), nullable=True)
    status = Column(String(32), default="pending", nullable=False, index=True)
    # pending | processing | completed | failed
    extracted_json = Column(Text, nullable=True)
    error_message = Column(Text, nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    processed_at = Column(DateTime(timezone=True), nullable=True)

    restaurant = relationship("Restaurant", back_populates="menu_uploads")
