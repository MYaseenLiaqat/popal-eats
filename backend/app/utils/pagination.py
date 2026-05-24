"""Reusable pagination helpers for SQLAlchemy queries."""

from typing import Any, TypeVar

from sqlalchemy import asc, desc, func
from sqlalchemy.orm import Query, Session

from app.schemas.pagination import PaginatedResponse

T = TypeVar("T")

SORT_DESC = "desc"
SORT_ASC = "asc"


def paginate_query(
    query: Query,
    *,
    page: int = 1,
    limit: int = 20,
    max_limit: int = 100,
) -> tuple[list[Any], int]:
    page = max(page, 1)
    limit = min(max(limit, 1), max_limit)
    total_count = query.order_by(None).count()
    items = query.offset((page - 1) * limit).limit(limit).all()
    return items, total_count


def build_paginated_response(
    items: list[T],
    *,
    page: int,
    limit: int,
    total_count: int,
) -> PaginatedResponse[T]:
    total_pages = max((total_count + limit - 1) // limit, 1) if limit else 1
    return PaginatedResponse(
        items=items,
        page=page,
        limit=limit,
        total_count=total_count,
        total_pages=total_pages,
    )


def apply_sort(query: Query, column, sort: str | None, default_desc: bool = True) -> Query:
    if sort == SORT_ASC:
        return query.order_by(asc(column))
    if sort == SORT_DESC:
        return query.order_by(desc(column))
    return query.order_by(desc(column) if default_desc else asc(column))
