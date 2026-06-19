"""Like, comment, and save interactions on posts."""

from fastapi import HTTPException
from sqlalchemy.orm import Session, joinedload

from app.models.post import Post
from app.models.post_interaction import PostComment, PostLike, PostSave
from app.models.user import User
from app.schemas.content import CommentCreate, CommentListResponse, CommentResponse
from app.schemas.friend import UserPublicProfile


def like_post(db: Session, user: User, post_id: int) -> None:
    post = db.query(Post).filter(Post.id == post_id).first()
    if post is None:
        raise HTTPException(status_code=404, detail="Post not found")

    existing = (
        db.query(PostLike)
        .filter(PostLike.post_id == post_id, PostLike.user_id == user.id)
        .first()
    )
    if existing is not None:
        return

    db.add(PostLike(post_id=post_id, user_id=user.id))
    post.like_count = (post.like_count or 0) + 1
    db.commit()


def unlike_post(db: Session, user: User, post_id: int) -> None:
    post = db.query(Post).filter(Post.id == post_id).first()
    if post is None:
        raise HTTPException(status_code=404, detail="Post not found")

    deleted = (
        db.query(PostLike)
        .filter(PostLike.post_id == post_id, PostLike.user_id == user.id)
        .delete(synchronize_session=False)
    )
    if deleted:
        post.like_count = max(0, (post.like_count or 0) - 1)
        db.commit()


def save_post(db: Session, user: User, post_id: int) -> None:
    post = db.query(Post).filter(Post.id == post_id).first()
    if post is None:
        raise HTTPException(status_code=404, detail="Post not found")

    existing = (
        db.query(PostSave)
        .filter(PostSave.post_id == post_id, PostSave.user_id == user.id)
        .first()
    )
    if existing is not None:
        return

    db.add(PostSave(post_id=post_id, user_id=user.id))
    post.save_count = (post.save_count or 0) + 1
    db.commit()


def unsave_post(db: Session, user: User, post_id: int) -> None:
    post = db.query(Post).filter(Post.id == post_id).first()
    if post is None:
        raise HTTPException(status_code=404, detail="Post not found")

    deleted = (
        db.query(PostSave)
        .filter(PostSave.post_id == post_id, PostSave.user_id == user.id)
        .delete(synchronize_session=False)
    )
    if deleted:
        post.save_count = max(0, (post.save_count or 0) - 1)
        db.commit()


def add_comment(db: Session, user: User, post_id: int, body: CommentCreate) -> CommentResponse:
    post = db.query(Post).filter(Post.id == post_id).first()
    if post is None:
        raise HTTPException(status_code=404, detail="Post not found")

    comment = PostComment(post_id=post_id, user_id=user.id, body=body.body.strip())
    db.add(comment)
    post.comment_count = (post.comment_count or 0) + 1
    db.commit()
    db.refresh(comment)
    comment = (
        db.query(PostComment)
        .options(joinedload(PostComment.user))
        .filter(PostComment.id == comment.id)
        .first()
    )
    author = UserPublicProfile.model_validate(comment.user) if comment.user else None
    return CommentResponse(
        id=comment.id,
        post_id=comment.post_id,
        user_id=comment.user_id,
        body=comment.body,
        created_at=comment.created_at,
        author=author,
    )


def list_comments(db: Session, post_id: int) -> CommentListResponse:
    post = db.query(Post).filter(Post.id == post_id).first()
    if post is None:
        raise HTTPException(status_code=404, detail="Post not found")

    comments = (
        db.query(PostComment)
        .options(joinedload(PostComment.user))
        .filter(PostComment.post_id == post_id)
        .order_by(PostComment.created_at.asc())
        .all()
    )
    items = [
        CommentResponse(
            id=c.id,
            post_id=c.post_id,
            user_id=c.user_id,
            body=c.body,
            created_at=c.created_at,
            author=UserPublicProfile.model_validate(c.user) if c.user else None,
        )
        for c in comments
    ]
    return CommentListResponse(items=items, total_count=len(items))
