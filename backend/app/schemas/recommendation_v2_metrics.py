"""Pydantic schemas for Recommendation Engine V2 metrics (Phase 5.1)."""

from typing import Literal

from pydantic import BaseModel, Field

EventType = Literal["impression", "click", "order"]

EVENT_FEEDBACK_WEIGHTS: dict[EventType, int] = {
    "impression": 0,
    "click": 1,
    "order": 3,
}


class RecommendationEventCreate(BaseModel):
    dish_id: int = Field(..., ge=1, description="Dish that was shown, clicked, or ordered")
    event_type: EventType = Field(
        ...,
        description=(
            "`impression` — recommendation displayed (CTR only, weight 0 for learning); "
            "`click` — user selected a recommendation (weight 1); "
            "`order` — user ordered the dish (weight 3)"
        ),
    )
    strategy: str = Field(
        ...,
        min_length=1,
        max_length=64,
        description="Engine strategy used (e.g. content, collaborative, hybrid)",
        examples=["hybrid"],
    )


class RecommendationEventResponse(BaseModel):
    status: Literal["ok"] = Field("ok", description="Event accepted and stored")
