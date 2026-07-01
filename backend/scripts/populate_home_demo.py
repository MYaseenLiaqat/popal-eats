"""Populate a demo-ready Home experience against the current database.

This is an OFFLINE DATA script only. It does NOT change any API, model, schema,
feed logic, or UI. It simply makes the already-imported content visible:

  1. Feed   — strips the ``fyp_seed`` marker from existing restaurant posts so
              they stop being filtered out of the home feed (backend + client).
  2. Reels  — attaches sample video URLs to a handful of restaurant posts so the
              discover reels row populates (restaurant_post is a discover type).
  3. Stories— creates fresh 24h stories from a few creator accounts and friends
              them to every other user so stories are visible (stories are
              friends-scoped by design).

Idempotent: safe to run multiple times.

Usage (from backend/):
    python -m scripts.populate_home_demo
"""

import re
from datetime import datetime, timedelta, timezone

from sqlalchemy import func

from app.core.content_constants import RESTAURANT_POST, STORY_TTL_HOURS
from app.database import SessionLocal
from app.models.friendship import Friendship
from app.models.post import Post
from app.models.restaurant import Restaurant
from app.models.story import Story
from app.models.user import User

# Public, browser-playable sample videos (used only for demo reels).
SAMPLE_VIDEOS = [
    "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4",
    "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4",
    "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerFun.mp4",
    "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerJoyrides.mp4",
    "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4",
]

REELS_TARGET = 12
STORIES_TARGET = 6

_SEED_MARKER = re.compile(r"<!--\s*fyp_seed[^>]*-->", re.IGNORECASE)
_SEED_TOKEN = re.compile(r"fyp_seed\w*", re.IGNORECASE)


def _clean(text: str | None) -> str | None:
    if not text:
        return text
    cleaned = _SEED_MARKER.sub("", text)
    cleaned = _SEED_TOKEN.sub("", cleaned)
    return cleaned.strip() or None


def unhide_feed_posts(db) -> int:
    """Remove the fyp_seed marker so restaurant posts appear in the feed."""
    blob = func.lower(func.coalesce(Post.caption, "") + func.coalesce(Post.title, ""))
    posts = db.query(Post).filter(blob.like("%fyp_seed%")).all()
    changed = 0
    for p in posts:
        new_caption = _clean(p.caption)
        new_title = _clean(p.title)
        if new_caption != p.caption or new_title != p.title:
            p.caption = new_caption
            p.title = new_title
            changed += 1
    db.commit()
    print(f"[feed]   unhid {changed} posts (removed fyp_seed marker)")
    return changed


def add_reels(db) -> int:
    """Attach sample videos to approved restaurant posts that have a thumbnail."""
    existing = (
        db.query(Post)
        .filter(Post.video_url.isnot(None), Post.video_url != "")
        .count()
    )
    if existing >= REELS_TARGET:
        print(f"[reels]  already have {existing} video posts; skipping")
        return 0

    approved_ids = {
        r.id
        for r in db.query(Restaurant.id).filter(
            Restaurant.approval_status == "approved"
        )
    }
    candidates = (
        db.query(Post)
        .filter(
            Post.post_type == RESTAURANT_POST,
            Post.restaurant_id.isnot(None),
            (Post.video_url.is_(None)) | (Post.video_url == ""),
        )
        .order_by(Post.id)
        .all()
    )
    added = 0
    for p in candidates:
        if added >= (REELS_TARGET - existing):
            break
        if p.restaurant_id not in approved_ids:
            continue
        images = p.images if isinstance(p.images, list) else []
        if not images:
            continue
        p.video_url = SAMPLE_VIDEOS[added % len(SAMPLE_VIDEOS)]
        added += 1
    db.commit()
    print(f"[reels]  added video to {added} restaurant posts")
    return added


def add_stories(db) -> int:
    """Create fresh stories from creator accounts and friend them to everyone."""
    now = datetime.now(timezone.utc)
    expires = now + timedelta(hours=STORY_TTL_HOURS)

    # Prefer restaurant / home-chef accounts as story authors, fall back to any.
    authors = (
        db.query(User)
        .filter(User.role.in_(("restaurant", "restaurant_owner", "home_chef")))
        .limit(STORIES_TARGET)
        .all()
    )
    if len(authors) < STORIES_TARGET:
        extra = (
            db.query(User)
            .filter(User.role == "customer")
            .limit(STORIES_TARGET - len(authors))
            .all()
        )
        authors = authors + extra

    if not authors:
        print("[stories] no candidate authors found; skipping")
        return 0

    # Reuse existing dish/restaurant imagery for story media.
    imgs = [
        r.image
        for r in db.query(Restaurant.image)
        .filter(Restaurant.image.isnot(None), Restaurant.image != "")
        .limit(STORIES_TARGET)
        .all()
    ]
    if not imgs:
        imgs = [
            "https://images.deliveryhero.io/image/fd-pk/products/7326302.jpg",
        ]

    author_ids = [a.id for a in authors]

    # Drop any stale demo stories from these authors so we don't pile up.
    created = 0
    for idx, author in enumerate(authors):
        has_active = (
            db.query(Story)
            .filter(Story.user_id == author.id, Story.expires_at > now)
            .count()
        )
        if has_active:
            continue
        db.add(
            Story(
                user_id=author.id,
                image_url=imgs[idx % len(imgs)],
                expires_at=expires,
            )
        )
        created += 1
    db.commit()
    print(f"[stories] created {created} active stories from {len(authors)} authors")

    # Friend the authors to every other user so their stories are visible.
    all_user_ids = [u.id for u in db.query(User.id)]
    existing_pairs = {
        (f.user_id, f.friend_id)
        for f in db.query(Friendship.user_id, Friendship.friend_id).all()
    }
    to_add: set[tuple[int, int]] = set()
    for viewer in all_user_ids:
        for author_id in author_ids:
            if viewer == author_id:
                continue
            # symmetric friendship (both directions) so stories AND friends
            # lists populate, deduped against DB and within this batch.
            for pair in ((viewer, author_id), (author_id, viewer)):
                if pair not in existing_pairs and pair not in to_add:
                    to_add.add(pair)
    for user_id, friend_id in to_add:
        db.add(Friendship(user_id=user_id, friend_id=friend_id))
    db.commit()
    print(f"[stories] linked {len(to_add)} friendship rows to story authors")
    return created


def main() -> None:
    db = SessionLocal()
    try:
        print("=== Populating demo Home ===")
        unhide_feed_posts(db)
        add_reels(db)
        add_stories(db)

        # Summary
        visible = (
            db.query(Post)
            .filter(Post.post_type == RESTAURANT_POST)
            .count()
        )
        vids = (
            db.query(Post)
            .filter(Post.video_url.isnot(None), Post.video_url != "")
            .count()
        )
        active_stories = (
            db.query(Story)
            .filter(Story.expires_at > datetime.now(timezone.utc))
            .count()
        )
        print("=== Done ===")
        print(f"  restaurant posts total: {visible}")
        print(f"  posts with video (reels): {vids}")
        print(f"  active stories: {active_stories}")
    except Exception:
        db.rollback()
        raise
    finally:
        db.close()


if __name__ == "__main__":
    main()
