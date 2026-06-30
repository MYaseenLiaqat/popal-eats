"""Lightweight reviews and post engagement for FYP demo."""

from __future__ import annotations

import random
from dataclasses import dataclass

from sqlalchemy import func, or_
from sqlalchemy.orm import Session

from app.core.restaurant_constants import APPROVED
from app.core.roles import CUSTOMER
from app.core.security import hash_password
from app.models.post import Post
from app.models.post_interaction import PostComment, PostLike, PostSave
from app.models.restaurant import Restaurant
from app.models.review import Review
from app.models.user import User

from app.services.rating_service import refresh_restaurant_rating

from .progress import log_progress

FYP_USER_MARKER = "fyp.community"
_REVIEWS_PER_RESTAURANT = 2
_TARGET_LIKES = 100
_TARGET_COMMENTS = 40
_TARGET_SAVES = 25

COMMUNITY_USERS = [
    ("Ayesha Khan", "ayesha.khan"),
    ("Bilal Ahmed", "bilal.ahmed"),
    ("Sana Malik", "sana.malik"),
    ("Hassan Raza", "hassan.raza"),
    ("Fatima Ali", "fatima.ali"),
    ("Usman Sheikh", "usman.sheikh"),
    ("Zainab Hussain", "zainab.hussain"),
    ("Omar Farooq", "omar.farooq"),
    ("Hira Shah", "hira.shah"),
    ("Ali Haider", "ali.haider"),
    ("Mariam Noor", "mariam.noor"),
    ("Saad Iqbal", "saad.iqbal"),
    ("Nida Aslam", "nida.aslam"),
    ("Hamza Butt", "hamza.butt"),
    ("Rabia Tariq", "rabia.tariq"),
]

REVIEW_SNIPPETS = [
    "Fast delivery and generous portions. Will order again!",
    "Authentic flavours — tasted just like dining in.",
    "Great value for money. Packaging was neat and hot.",
    "Our go-to spot for weekend family dinners.",
    "The biryani was perfectly spiced. Highly recommended.",
    "Quick rider and friendly service. Five stars.",
    "Fresh ingredients and consistent quality every time.",
    "Best karahi in the area — friends loved it.",
    "Portions are huge! Perfect for sharing.",
    "Reliable delivery even during peak hours.",
]

COMMENT_SNIPPETS = [
    "Looks amazing 😍",
    "Need to try this!",
    "Ordered this last night — so good.",
    "Adding to my favourites.",
    "My favourite from this place!",
    "That presentation 🔥",
    "Saving this for later.",
    "Best deal this week.",
]


@dataclass
class CommunityStats:
    reviews_created: int = 0
    likes_created: int = 0
    comments_created: int = 0
    saves_created: int = 0


def _get_or_create_community_users(db: Session) -> list[User]:
    users: list[User] = []
    for full_name, username in COMMUNITY_USERS:
        email = f"{username}@{FYP_USER_MARKER}"
        user = (
            db.query(User)
            .filter(or_(User.email == email, User.username == username))
            .first()
        )
        if user is None:
            user = User(
                full_name=full_name,
                email=email,
                username=username,
                password_hash=hash_password("Community123!"),
                role=CUSTOMER,
                city="Lahore",
                onboarding_completed=True,
                bio=f"Lahore food lover — {full_name}",
            )
            db.add(user)
            db.flush()
        users.append(user)
    db.commit()
    return users


def _target_restaurant_ids(db: Session, restaurant_ids: list[int] | None) -> list[int]:
    if restaurant_ids:
        return restaurant_ids
    return [
        r.id
        for r in (
            db.query(Restaurant.id)
            .filter(Restaurant.approval_status == APPROVED)
            .order_by(Restaurant.average_rating.desc())
            .limit(10)
            .all()
        )
    ]


def _seed_post_ids(db: Session, restaurant_ids: list[int]) -> list[int]:
    if not restaurant_ids:
        return []
    return [
        p.id
        for p in (
            db.query(Post.id)
            .filter(
                Post.restaurant_id.in_(restaurant_ids),
                Post.post_type == "restaurant_post",
            )
            .order_by(Post.id)
            .all()
        )
    ]


def populate_community(
    db: Session,
    *,
    restaurant_ids: list[int] | None = None,
    seed: int = 42,
) -> CommunityStats:
    random.seed(seed)
    stats = CommunityStats()

    users = _get_or_create_community_users(db)
    target_ids = _target_restaurant_ids(db, restaurant_ids)

    restaurants = (
        db.query(Restaurant)
        .filter(Restaurant.id.in_(target_ids), Restaurant.approval_status == APPROVED)
        .all()
    )

    for restaurant in restaurants:
        existing = (
            db.query(func.count(Review.id))
            .filter(Review.restaurant_id == restaurant.id)
            .scalar()
            or 0
        )
        needed = max(0, _REVIEWS_PER_RESTAURANT - existing)
        if needed == 0:
            continue

        candidates = [u for u in users if u.id != restaurant.owner_id]
        reviewers = random.sample(candidates, k=min(needed, len(candidates)))
        for user in reviewers:
            if db.query(Review).filter(
                Review.user_id == user.id, Review.restaurant_id == restaurant.id
            ).first():
                continue
            rating = random.choice([4, 4, 5, 5, 3])
            db.add(
                Review(
                    user_id=user.id,
                    restaurant_id=restaurant.id,
                    rating=rating,
                    comment=random.choice(REVIEW_SNIPPETS),
                    processing_status="completed",
                    sentiment="positive" if rating >= 4 else "neutral",
                    sentiment_score=0.75 if rating >= 4 else 0.2,
                )
            )
            stats.reviews_created += 1

    db.commit()
    for restaurant in restaurants:
        refresh_restaurant_rating(db, restaurant.id)
    db.commit()

    post_ids = _seed_post_ids(db, target_ids)
    if not post_ids:
        return stats

    existing_likes = {
        (r.post_id, r.user_id) for r in db.query(PostLike.post_id, PostLike.user_id).all()
    }
    existing_saves = {
        (r.post_id, r.user_id) for r in db.query(PostSave.post_id, PostSave.user_id).all()
    }
    existing_comments = {
        (r.post_id, r.user_id)
        for r in db.query(PostComment.post_id, PostComment.user_id).all()
    }

    existing_like_count = int(
        db.query(func.count(PostLike.id)).filter(PostLike.post_id.in_(post_ids)).scalar() or 0
    )
    existing_comment_count = int(
        db.query(func.count(PostComment.id)).filter(PostComment.post_id.in_(post_ids)).scalar() or 0
    )
    existing_save_count = int(
        db.query(func.count(PostSave.id)).filter(PostSave.post_id.in_(post_ids)).scalar() or 0
    )

    likes_needed = max(0, _TARGET_LIKES - existing_like_count)
    comments_needed = max(0, _TARGET_COMMENTS - existing_comment_count)
    saves_needed = max(0, _TARGET_SAVES - existing_save_count)

    like_deltas: dict[int, int] = {}
    comment_deltas: dict[int, int] = {}
    save_deltas: dict[int, int] = {}

    attempts = 0
    while stats.likes_created < likes_needed and attempts < likes_needed * 5:
        post_id = random.choice(post_ids)
        user = random.choice(users)
        key = (post_id, user.id)
        if key not in existing_likes:
            db.add(PostLike(post_id=post_id, user_id=user.id))
            existing_likes.add(key)
            stats.likes_created += 1
            like_deltas[post_id] = like_deltas.get(post_id, 0) + 1
        attempts += 1

    for _ in range(comments_needed):
        post_id = random.choice(post_ids)
        user = random.choice(users)
        key = (post_id, user.id)
        if key in existing_comments:
            continue
        db.add(
            PostComment(
                post_id=post_id,
                user_id=user.id,
                body=random.choice(COMMENT_SNIPPETS),
            )
        )
        existing_comments.add(key)
        stats.comments_created += 1
        comment_deltas[post_id] = comment_deltas.get(post_id, 0) + 1

    attempts = 0
    while stats.saves_created < saves_needed and attempts < saves_needed * 5:
        post_id = random.choice(post_ids)
        user = random.choice(users)
        key = (post_id, user.id)
        if key not in existing_saves:
            db.add(PostSave(post_id=post_id, user_id=user.id))
            existing_saves.add(key)
            stats.saves_created += 1
            save_deltas[post_id] = save_deltas.get(post_id, 0) + 1
        attempts += 1

    touched_ids = set(like_deltas) | set(comment_deltas) | set(save_deltas)
    if touched_ids:
        posts = db.query(Post).filter(Post.id.in_(touched_ids)).all()
        for post in posts:
            post.like_count = (post.like_count or 0) + like_deltas.get(post.id, 0)
            post.comment_count = (post.comment_count or 0) + comment_deltas.get(post.id, 0)
            post.save_count = (post.save_count or 0) + save_deltas.get(post.id, 0)

    db.commit()
    log_progress("Engagement", stats.likes_created + stats.comments_created + stats.saves_created, 165)

    return stats
