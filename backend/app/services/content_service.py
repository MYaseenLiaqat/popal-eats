"""Post CRUD, home feed, and discover reels."""

from datetime import datetime, timezone

from fastapi import HTTPException, status
from sqlalchemy import and_, func, or_
from sqlalchemy.orm import Session, joinedload

from app.core.content_constants import (
    CHEF_POST,
    DISCOVER_POST_TYPES,
    FOOD_POST,
    RECIPE,
    RESTAURANT_POST,
)
from app.core.restaurant_constants import APPROVED
from app.core.rbac import assert_active_business_account
from app.core.roles import ADMIN, CUSTOMER, HOME_CHEF, RESTAURANT, normalize_role
from app.models.dish import Dish
from app.models.friendship import Friendship
from app.models.post import Post
from app.models.post_interaction import PostLike, PostSave
from app.models.restaurant import Restaurant
from app.models.user import User
from app.schemas.content import (
    DiscoverReelResponse,
    PostCreate,
    PostResponse,
    PostUpdate,
)
from app.schemas.friend import UserPublicProfile


def _friend_ids(db: Session, user_id: int) -> set[int]:
    rows = (
        db.query(Friendship.friend_id)
        .filter(Friendship.user_id == user_id)
        .all()
    )
    return {row[0] for row in rows}


def _viewer_interaction_ids(
    db: Session, viewer_id: int, post_ids: list[int]
) -> tuple[set[int], set[int]]:
    """Batch-load liked/saved post ids for a viewer (avoids N+1 per post)."""
    if not post_ids:
        return set(), set()
    liked_rows = (
        db.query(PostLike.post_id)
        .filter(PostLike.user_id == viewer_id, PostLike.post_id.in_(post_ids))
        .all()
    )
    saved_rows = (
        db.query(PostSave.post_id)
        .filter(PostSave.user_id == viewer_id, PostSave.post_id.in_(post_ids))
        .all()
    )
    return {row[0] for row in liked_rows}, {row[0] for row in saved_rows}


def _serialize_post(
    post: Post,
    viewer_id: int | None,
    db: Session,
    *,
    liked_ids: set[int] | None = None,
    saved_ids: set[int] | None = None,
) -> PostResponse:
    liked = False
    saved = False
    if viewer_id is not None:
        if liked_ids is not None:
            liked = post.id in liked_ids
        else:
            liked = (
                db.query(PostLike.id)
                .filter(PostLike.post_id == post.id, PostLike.user_id == viewer_id)
                .first()
                is not None
            )
        if saved_ids is not None:
            saved = post.id in saved_ids
        else:
            saved = (
                db.query(PostSave.id)
                .filter(PostSave.post_id == post.id, PostSave.user_id == viewer_id)
                .first()
                is not None
            )

    author_profile = None
    if post.author is not None:
        author_profile = UserPublicProfile.model_validate(post.author)

    return PostResponse(
        id=post.id,
        author_id=post.author_id,
        post_type=post.post_type,
        caption=post.caption,
        title=post.title,
        images=post.images,
        video_url=post.video_url,
        restaurant_id=post.restaurant_id,
        dish_id=post.dish_id,
        restaurant_content_subtype=post.restaurant_content_subtype,
        recipe_description=post.recipe_description,
        recipe_ingredients=post.recipe_ingredients,
        recipe_steps=post.recipe_steps,
        like_count=post.like_count or 0,
        comment_count=post.comment_count or 0,
        save_count=post.save_count or 0,
        created_at=post.created_at,
        updated_at=post.updated_at,
        author=author_profile,
        restaurant_name=post.restaurant.name if post.restaurant else None,
        dish_name=post.dish.name if post.dish else None,
        liked_by_me=liked,
        saved_by_me=saved,
    )


def _assert_can_create_post(body: PostCreate, user: User, db: Session) -> None:
    role = normalize_role(user.role)
    post_type = body.post_type

    if post_type == FOOD_POST:
        if role not in (CUSTOMER, ADMIN):
            raise HTTPException(
                status_code=403,
                detail="Only customers can create community food posts",
            )
        return

    if post_type == RESTAURANT_POST:
        if role not in (RESTAURANT, ADMIN):
            raise HTTPException(
                status_code=403,
                detail="Only restaurants can create restaurant posts",
            )
        if role != ADMIN:
            assert_active_business_account(user)
        if body.restaurant_id is None:
            raise HTTPException(status_code=400, detail="restaurant_id required for restaurant_post")
        if body.restaurant_content_subtype is None:
            raise HTTPException(
                status_code=400,
                detail="restaurant_content_subtype required (promotion, new_dish, announcement)",
            )
        restaurant = db.query(Restaurant).filter(Restaurant.id == body.restaurant_id).first()
        if restaurant is None:
            raise HTTPException(status_code=404, detail="Restaurant not found")
        if role != ADMIN and restaurant.owner_id != user.id:
            raise HTTPException(status_code=403, detail="Not the restaurant owner")
        if restaurant.approval_status != APPROVED:
            raise HTTPException(status_code=400, detail="Restaurant must be approved before posting")
        return

    if post_type == CHEF_POST:
        if role not in (HOME_CHEF, ADMIN):
            raise HTTPException(status_code=403, detail="Only home chefs can create chef posts")
        if role != ADMIN:
            assert_active_business_account(user)
        return

    if post_type == RECIPE:
        if role not in (RESTAURANT, HOME_CHEF, CUSTOMER, ADMIN):
            raise HTTPException(
                status_code=403,
                detail="Only restaurants, home chefs, and customers can create recipe posts",
            )
        if role not in (CUSTOMER, ADMIN):
            assert_active_business_account(user)
        if not body.title or not str(body.title).strip():
            raise HTTPException(status_code=400, detail="title required for recipe posts")
        return

    if body.restaurant_id is not None:
        restaurant = db.query(Restaurant).filter(Restaurant.id == body.restaurant_id).first()
        if restaurant is None:
            raise HTTPException(status_code=404, detail="Tagged restaurant not found")
        if restaurant.approval_status != APPROVED:
            raise HTTPException(status_code=400, detail="Can only tag approved restaurants")

    if body.dish_id is not None:
        dish = db.query(Dish).filter(Dish.id == body.dish_id).first()
        if dish is None:
            raise HTTPException(status_code=404, detail="Tagged dish not found")


def create_post(db: Session, user: User, body: PostCreate) -> PostResponse:
    _assert_can_create_post(body, user, db)

    post = Post(
        author_id=user.id,
        post_type=body.post_type,
        caption=body.caption,
        title=body.title,
        images=body.images or [],
        video_url=body.video_url,
        restaurant_id=body.restaurant_id,
        dish_id=body.dish_id,
        restaurant_content_subtype=body.restaurant_content_subtype,
        recipe_description=body.recipe_description,
        recipe_ingredients=body.recipe_ingredients or [],
        recipe_steps=body.recipe_steps or [],
    )
    db.add(post)
    db.commit()
    db.refresh(post)
    post = _load_post(db, post.id)
    return _serialize_post(post, user.id, db)


def _load_post(db: Session, post_id: int) -> Post:
    post = (
        db.query(Post)
        .options(
            joinedload(Post.author),
            joinedload(Post.restaurant),
            joinedload(Post.dish),
        )
        .filter(Post.id == post_id)
        .first()
    )
    if post is None:
        raise HTTPException(status_code=404, detail="Post not found")
    return post


def get_post(db: Session, post_id: int, viewer_id: int | None) -> PostResponse:
    post = _load_post(db, post_id)
    return _serialize_post(post, viewer_id, db)


def update_post(db: Session, user: User, post_id: int, body: PostUpdate) -> PostResponse:
    post = _load_post(db, post_id)
    role = normalize_role(user.role)
    if role != ADMIN and post.author_id != user.id:
        raise HTTPException(status_code=403, detail="Not the post author")

    data = body.model_dump(exclude_unset=True)
    for key, value in data.items():
        setattr(post, key, value)
    post.updated_at = datetime.now(timezone.utc)
    db.commit()
    db.refresh(post)
    post = _load_post(db, post.id)
    return _serialize_post(post, user.id, db)


def delete_post(db: Session, user: User, post_id: int) -> None:
    post = _load_post(db, post_id)
    role = normalize_role(user.role)
    if role != ADMIN and post.author_id != user.id:
        raise HTTPException(status_code=403, detail="Not the post author")
    db.delete(post)
    db.commit()


def _is_seed_post(post: Post) -> bool:
    caption = (post.caption or "") + (post.title or "")
    return "fyp_seed" in caption.lower()


def _has_food_content(post: Post) -> bool:
    images = post.images if isinstance(post.images, list) else []
    has_media = bool(images) or bool(post.video_url and str(post.video_url).strip())
    has_dish = post.dish_id is not None
    has_text = bool((post.caption or post.title or "").strip())
    return has_media or has_dish or has_text


def _home_feed_priority(post: Post, user_id: int, friends: set[int]) -> int:
    """Lower values appear first: friend food, friend other, restaurant dish, chef recipe."""
    author = post.author_id
    if author in friends and post.post_type == FOOD_POST:
        return 0
    if author in friends:
        return 1
    if post.post_type == RESTAURANT_POST:
        return 2
    if post.post_type in (RECIPE, CHEF_POST):
        return 3
    return 4


def list_home_feed(
    db: Session,
    user_id: int,
    *,
    page: int = 1,
    limit: int = 20,
) -> tuple[list[PostResponse], int]:
    from app.core.account_status import ACTIVE

    friends = _friend_ids(db, user_id)
    visible_authors = friends | {user_id}

    social_filter = and_(
        Post.author_id.in_(visible_authors),
        Post.post_type.in_((FOOD_POST, RECIPE, CHEF_POST)),
    )
    restaurant_filter = and_(
        Post.post_type == RESTAURANT_POST,
        Restaurant.approval_status == APPROVED,
    )
    chef_filter = and_(
        Post.post_type.in_((RECIPE, CHEF_POST)),
        User.role == HOME_CHEF,
        User.account_status == ACTIVE,
    )

    posts = (
        db.query(Post)
        .outerjoin(Restaurant, Post.restaurant_id == Restaurant.id)
        .outerjoin(User, Post.author_id == User.id)
        .options(
            joinedload(Post.author),
            joinedload(Post.restaurant),
            joinedload(Post.dish),
        )
        .filter(
            or_(
                social_filter,
                restaurant_filter,
                chef_filter,
            )
        )
        .order_by(Post.created_at.desc())
        .all()
    )

    posts = [
        p
        for p in posts
        if not _is_seed_post(p)
        and _has_food_content(p)
        and (p.post_type != RESTAURANT_POST or p.restaurant is not None)
    ]
    posts.sort(
        key=lambda p: (
            _home_feed_priority(p, user_id, friends),
            -(p.created_at.timestamp() if p.created_at else 0),
        )
    )
    total = len(posts)
    start = (page - 1) * limit
    posts = posts[start : start + limit]
    post_ids = [p.id for p in posts]
    liked_ids, saved_ids = _viewer_interaction_ids(db, user_id, post_ids)
    return [
        _serialize_post(p, user_id, db, liked_ids=liked_ids, saved_ids=saved_ids) for p in posts
    ], total


def list_discover_reels(db: Session, *, limit: int = 30) -> list[DiscoverReelResponse]:
    customer_reel_filter = and_(
        Post.post_type == FOOD_POST,
        Post.video_url.isnot(None),
        Post.video_url != "",
    )
    posts = (
        db.query(Post)
        .options(joinedload(Post.author), joinedload(Post.restaurant), joinedload(Post.dish))
        .outerjoin(Post.restaurant)
        .filter(
            or_(
                Post.post_type.in_(DISCOVER_POST_TYPES),
                customer_reel_filter,
            )
        )
        .filter(
            or_(
                Post.post_type != RESTAURANT_POST,
                Restaurant.approval_status == APPROVED,
            )
        )
        .order_by(Post.created_at.desc())
        .limit(limit)
        .all()
    )

    reels: list[DiscoverReelResponse] = []
    for post in posts:
        if post.post_type == RESTAURANT_POST and post.restaurant is not None:
            creator = post.restaurant.name
        elif post.author is not None:
            creator = post.author.full_name
        else:
            creator = "Popal Eats"

        images = post.images if isinstance(post.images, list) else []
        thumb = images[0] if images else None
        title = post.title or post.caption or "Untitled"
        caption = post.caption or post.recipe_description or ""

        kind_label = post.post_type.replace("_", " ").title()
        ingredients = post.recipe_ingredients if isinstance(post.recipe_ingredients, list) else None
        dish = post.dish
        reels.append(
            DiscoverReelResponse(
                id=post.id,
                post_id=post.id,
                post_type=post.post_type,
                title=title[:200],
                creator_name=creator,
                caption=caption[:500],
                thumbnail_url=thumb,
                video_url=post.video_url,
                duration_label=kind_label,
                recipe_ingredients=ingredients,
                recipe_description=post.recipe_description,
                calories=dish.calories if dish else None,
                protein=float(dish.protein) if dish and dish.protein is not None else None,
                carbs=float(dish.carbs) if dish and dish.carbs is not None else None,
                fats=float(dish.fats) if dish and dish.fats is not None else None,
            )
        )
    return reels


def append_post_image(db: Session, user: User, post_id: int, public_url: str) -> PostResponse:
    post = _load_post(db, post_id)
    role = normalize_role(user.role)
    if role != ADMIN and post.author_id != user.id:
        raise HTTPException(status_code=403, detail="Not the post author")
    images = list(post.images or [])
    if public_url not in images:
        images.append(public_url)
    post.images = images
    db.commit()
    db.refresh(post)
    post = _load_post(db, post.id)
    return _serialize_post(post, user.id, db)


def set_post_video(db: Session, user: User, post_id: int, public_url: str) -> PostResponse:
    post = _load_post(db, post_id)
    role = normalize_role(user.role)
    if role != ADMIN and post.author_id != user.id:
        raise HTTPException(status_code=403, detail="Not the post author")
    post.video_url = public_url
    db.commit()
    db.refresh(post)
    post = _load_post(db, post.id)
    return _serialize_post(post, user.id, db)
