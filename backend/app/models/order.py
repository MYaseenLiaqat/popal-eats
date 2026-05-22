"""
Order model — created at checkout from the user's cart.

Preserves total_price and links to restaurant for owner dashboards.
rider_name is a simple field until a full rider system exists.
"""

from sqlalchemy import Column, DateTime, ForeignKey, Integer, Numeric, String
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func

from app.core.constants import ORDER_STATUS_PENDING, PAYMENT_STATUS_PENDING
from app.database import Base


class Order(Base):
    __tablename__ = "orders"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    restaurant_id = Column(
        Integer, ForeignKey("restaurants.id", ondelete="CASCADE"), nullable=False, index=True
    )
    total_price = Column(Numeric(10, 2), nullable=False)
    status = Column(String(30), default=ORDER_STATUS_PENDING, nullable=False, index=True)
    payment_status = Column(String(30), default=PAYMENT_STATUS_PENDING, nullable=False)
    delivery_address = Column(String(500), nullable=False)
    rider_name = Column(String(120), nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    user = relationship("User", back_populates="orders")
    restaurant = relationship("Restaurant", back_populates="orders")
    items = relationship(
        "OrderItem",
        back_populates="order",
        cascade="all, delete-orphan",
    )
