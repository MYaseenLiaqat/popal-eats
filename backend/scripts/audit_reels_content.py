#!/usr/bin/env python
"""Audit discover reels content counts.

Usage:
  cd backend && python scripts/audit_reels_content.py
"""

from __future__ import annotations

import sys
from pathlib import Path

_backend = Path(__file__).resolve().parent.parent
if str(_backend) not in sys.path:
    sys.path.insert(0, str(_backend))

from sqlalchemy import func

from app.core.content_constants import DISCOVER_POST_TYPES, RECIPE, RESTAURANT_POST
from app.database import SessionLocal
from app.models.post import Post


def main() -> None:
    db = SessionLocal()
    try:
        total = db.query(func.count(Post.id)).filter(Post.post_type.in_(DISCOVER_POST_TYPES)).scalar()
        recipes = db.query(func.count(Post.id)).filter(Post.post_type == RECIPE).scalar()
        restaurant_posts = (
            db.query(func.count(Post.id)).filter(Post.post_type == RESTAURANT_POST).scalar()
        )
        with_thumb = (
            db.query(func.count(Post.id))
            .filter(Post.post_type.in_(DISCOVER_POST_TYPES))
            .filter(Post.images.isnot(None))
            .scalar()
        )
        print("Reels content audit")
        print("-------------------")
        print(f"Discover-eligible posts: {total}")
        print(f"Recipe posts:            {recipes}")
        print(f"Restaurant posts:        {restaurant_posts}")
        print(f"Posts with images:       {with_thumb}")
        if total == 0:
            print("\nNo reels content found. Run: python scripts/seed_demo_content.py")
    finally:
        db.close()


if __name__ == "__main__":
    main()
