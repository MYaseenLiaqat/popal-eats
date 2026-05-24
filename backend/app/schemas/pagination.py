"""Paginated API response wrapper."""

from typing import Generic, TypeVar

from pydantic import BaseModel, Field

T = TypeVar("T")


class PaginatedResponse(BaseModel, Generic[T]):
    items: list[T]
    page: int = Field(..., ge=1)
    limit: int = Field(..., ge=1)
    total_count: int = Field(..., ge=0)
    total_pages: int = Field(..., ge=1)
