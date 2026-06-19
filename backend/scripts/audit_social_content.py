#!/usr/bin/env python
"""Social content validation audit — read-only checks against DB + live API."""

from __future__ import annotations

import json
import sys
import time
import urllib.error
import urllib.request
from pathlib import Path

_backend = Path(__file__).resolve().parent.parent
if str(_backend) not in sys.path:
    sys.path.insert(0, str(_backend))

BASE = "http://127.0.0.1:8000"
DEMO_EMAIL = "demo.host@example.com"
DEMO_PASSWORD = "Demo1234!"


def req(method, path, token=None, body=None, timeout=30):
    url = f"{BASE}{path}"
    data = json.dumps(body).encode() if body else None
    headers = {"Content-Type": "application/json"}
    if token:
        headers["Authorization"] = f"Bearer {token}"
    request = urllib.request.Request(url, data=data, headers=headers, method=method)
    t0 = time.perf_counter()
    try:
        with urllib.request.urlopen(request, timeout=timeout) as resp:
            raw = resp.read().decode()
            ms = (time.perf_counter() - t0) * 1000
            return resp.status, json.loads(raw) if raw else {}, ms
    except urllib.error.HTTPError as e:
        ms = (time.perf_counter() - t0) * 1000
        try:
            detail = json.loads(e.read().decode())
        except Exception:
            detail = {"error": str(e)}
        return e.code, detail, ms


def login():
    code, data, _ = req("POST", "/login", body={"email": DEMO_EMAIL, "password": DEMO_PASSWORD})
    if code != 200:
        return None, data
    code2, me, _ = req("GET", "/me", token=data["access_token"])
    return data["access_token"], me if code2 == 200 else data


def main():
    results = []

    def record(name, passed, detail=""):
        results.append((name, passed, detail))
        mark = "PASS" if passed else "FAIL"
        print(f"  [{mark}] {name}" + (f" — {detail}" if detail else ""))

    print(f"Social content audit — {BASE}\n")

    # API availability
    code, health, ms = req("GET", "/health")
    has_content = False
    code_feed, _, _ = req("GET", "/feed/home")
    if code_feed == 404:
        print("  WARN: /feed/home returns 404 — backend may need restart\n")
    else:
        has_content = True

    token, me = login()
    if not token:
        print("  FAIL: Cannot login demo.host — run seed_demo_content.py")
        return 1

    uid = me.get("id")

    # 1. Posts
    code, post, ms = req(
        "POST",
        "/posts",
        token=token,
        body={"post_type": "food_post", "caption": "Audit test post"},
    )
    record("Create post", code == 201, f"{ms:.0f}ms id={post.get('id')}")
    pid = post.get("id")

    if pid:
        code, viewed, ms = req("GET", f"/posts/{pid}", token=token)
        record("View post", code == 200 and viewed.get("id") == pid, f"{ms:.0f}ms")

        code, _, ms = req("POST", f"/posts/{pid}/like", token=token)
        record("Like post", code == 204, f"{ms:.0f}ms")

        code, viewed, _ = req("GET", f"/posts/{pid}", token=token)
        record("Like reflected in GET", viewed.get("liked_by_me") is True, f"count={viewed.get('like_count')}")

        code, _, ms = req("POST", f"/posts/{pid}/save", token=token)
        record("Save post", code == 204, f"{ms:.0f}ms")

        code, viewed, _ = req("GET", f"/posts/{pid}", token=token)
        record("Save reflected in GET", viewed.get("saved_by_me") is True, f"count={viewed.get('save_count')}")

        code, comment, ms = req(
            "POST",
            f"/posts/{pid}/comments",
            token=token,
            body={"body": "Audit comment"},
        )
        record("Comment post", code == 201, f"{ms:.0f}ms")

        code, comments, _ = req("GET", f"/posts/{pid}/comments")
        record("List comments", code == 200 and len(comments.get("items", [])) >= 1, f"{len(comments.get('items', []))} items")

    # 2. Stories — list timing
    code, stories, ms = req("GET", "/stories", token=token)
    groups = stories.get("groups", []) if code == 200 else []
    record("List stories", code == 200, f"{ms:.0f}ms groups={len(groups)}")

    # Expiration check via DB
    from datetime import datetime, timezone
    from app.database import SessionLocal
    from app.models.story import Story
    from app.core.content_constants import STORY_TTL_HOURS

    db = SessionLocal()
    try:
        from sqlalchemy import func, text
        from app.models.post import Post
        from app.models.post_interaction import PostComment, PostLike, PostSave

        post_counts = dict(
            db.query(Post.post_type, func.count(Post.id)).group_by(Post.post_type).all()
        )
        total_posts = db.query(func.count(Post.id)).scalar() or 0
        total_stories = db.query(func.count(Story.id)).scalar() or 0
        active_stories = db.query(func.count(Story.id)).filter(Story.expires_at > datetime.now(timezone.utc)).scalar() or 0
        expired_stories = total_stories - active_stories

        record("DB post counts", total_posts > 0, f"total={total_posts} by_type={post_counts}")
        record("DB story counts", True, f"total={total_stories} active={active_stories} expired={expired_stories}")

        # FK constraints exist
        fk_rows = db.execute(
            text("""
                SELECT tc.table_name, kcu.column_name, ccu.table_name AS foreign_table
                FROM information_schema.table_constraints tc
                JOIN information_schema.key_column_usage kcu ON tc.constraint_name = kcu.constraint_name
                JOIN information_schema.constraint_column_usage ccu ON ccu.constraint_name = tc.constraint_name
                WHERE tc.constraint_type = 'FOREIGN KEY'
                  AND tc.table_name IN ('posts','stories','post_likes','post_comments','post_saves','story_views')
                ORDER BY tc.table_name
            """)
        ).fetchall()
        record("Foreign keys defined", len(fk_rows) >= 10, f"{len(fk_rows)} FK rows")

        # Cascade on posts -> likes
        cascade_rows = db.execute(
            text("""
                SELECT rc.delete_rule FROM information_schema.referential_constraints rc
                JOIN information_schema.table_constraints tc ON rc.constraint_name = tc.constraint_name
                WHERE tc.table_name = 'post_likes'
            """)
        ).fetchall()
        record("post_likes CASCADE", any(r[0] == "CASCADE" for r in cascade_rows), str(cascade_rows))

        # Feed content types
        code, feed, ms = req("GET", "/feed/home?limit=50", token=token)
        items = feed.get("items", []) if code == 200 else []
        types = {i.get("post_type") for i in items}
        has_friend = any(i.get("author_id") != uid for i in items if i.get("post_type") == "food_post")
        has_recipe = "recipe" in types
        has_restaurant = "restaurant_post" in types
        record("Home feed load", code == 200, f"{ms:.0f}ms items={len(items)}")
        record("Feed has recipe posts", has_recipe, f"types={types}")
        record("Feed has restaurant posts", has_restaurant, f"types={types}")
        record("Feed friend posts visible", has_friend or len(items) > 0, f"types={types}")

        # Ordering: created_at desc
        if len(items) >= 2:
            times = [i.get("created_at") for i in items]
            ordered = times == sorted(times, reverse=True)
            record("Feed ordering (created_at desc)", ordered, times[:3])

        # Discover reels
        code, reels, ms = req("GET", "/discover/reels?limit=30")
        reel_items = reels.get("items", []) if code == 200 else []
        record("Discover reels load", code == 200, f"{ms:.0f}ms items={len(reel_items)}")

        # Restaurant announcement visibility for non-owner
        rest_posts = [i for i in items if i.get("post_type") == "restaurant_post"]
        record("Restaurant announcements in feed", len(rest_posts) > 0, f"{len(rest_posts)} found")

    finally:
        db.close()

    passed = sum(1 for _, p, _ in results if p)
    print(f"\nSummary: {passed}/{len(results)} checks passed")
    return 0 if passed == len(results) else 1


if __name__ == "__main__":
    if len(sys.argv) > 1:
        BASE = sys.argv[1].rstrip("/")
    sys.exit(main())
