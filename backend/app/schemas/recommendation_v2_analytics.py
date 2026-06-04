"""Pydantic schemas for Recommendation Engine V2 Phase 4 (trending, popular, analytics)."""

from decimal import Decimal

from pydantic import BaseModel, Field


class TrendingDish(BaseModel):
    dish_id: int
    dish_name: str
    restaurant_name: str
    price: Decimal
    average_rating: float = Field(..., ge=0, description="Parent restaurant average_rating (0–5)")
    order_count: int = Field(..., ge=0, description="Total units ordered (sum of order_items.quantity)")
    review_count: int = Field(..., ge=0, description="Parent restaurant total_reviews")
    trending_score: float = Field(
        ...,
        ge=0,
        description="order_count×0.5 + review_count×0.3 + average_rating×0.2",
    )


class TrendingResponse(BaseModel):
    engine_version: str = Field(default="2.1")
    items: list[TrendingDish] = Field(default_factory=list)
    count: int
    limit: int


class PopularDish(BaseModel):
    dish_id: int
    dish_name: str
    restaurant_name: str
    price: Decimal
    total_orders: int = Field(..., ge=0, description="Total units ordered (sum of order_items.quantity)")


class PopularResponse(BaseModel):
    engine_version: str = Field(default="2.1")
    items: list[PopularDish] = Field(default_factory=list)
    count: int
    limit: int


class AnalyticsResponse(BaseModel):
    engine_version: str = Field(default="2.1")
    total_dishes: int = Field(..., ge=0)
    total_restaurants: int = Field(..., ge=0)
    total_orders: int = Field(..., ge=0)
    total_reviews: int = Field(..., ge=0)
    avg_restaurant_rating: float = Field(..., ge=0)
    total_impressions: int = Field(
        ...,
        ge=0,
        description="Count of recommendation_events where event_type is impression",
    )
    total_clicks: int = Field(
        ...,
        ge=0,
        description="Count of recommendation_events where event_type is click",
    )
    click_through_rate: float = Field(
        ...,
        ge=0,
        description="total_clicks / total_impressions (0 when impressions are 0); rounded to 4 decimals",
    )
