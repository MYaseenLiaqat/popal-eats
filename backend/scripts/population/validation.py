"""Validation report for Phase 9A FYP population run."""

from __future__ import annotations

from dataclasses import dataclass, field

from sqlalchemy import func, or_
from sqlalchemy.orm import Session

from app.core.restaurant_constants import APPROVED
from app.models.dish import Dish
from app.models.friendship import Friendship
from app.models.group_session import GroupSession
from app.models.post import Post
from app.models.post_interaction import PostComment, PostLike, PostSave
from app.models.restaurant import Restaurant
from app.models.review import Review
from app.models.story import Story
from app.models.user import User

from .placeholders import is_bad_dish_name, is_bad_restaurant_name


@dataclass
class FypRunReport:
    restaurants_processed: int = 0
    restaurants_skipped: int = 0
    dishes_updated: int = 0
    posts_created: int = 0
    stories_created: int = 0
    reviews_created: int = 0
    likes_created: int = 0
    comments_created: int = 0
    saves_created: int = 0
    missing_restaurant_images: int = 0
    missing_dish_images: int = 0
    execution_seconds: float = 0.0

    def print_report(self) -> None:
        w = 52
        print("=" * w)
        print("PHASE 9A — FYP POPULATION REPORT")
        print("=" * w)
        print(f"Restaurants processed:     {self.restaurants_processed}")
        print(f"Restaurants skipped:       {self.restaurants_skipped}")
        print(f"Dishes updated:            {self.dishes_updated}")
        print(f"Posts created:             {self.posts_created}")
        print(f"Stories created:           {self.stories_created}")
        print(f"Reviews created:           {self.reviews_created}")
        print(f"Likes created:             {self.likes_created}")
        print(f"Comments created:          {self.comments_created}")
        print(f"Saved posts created:       {self.saves_created}")
        print(f"Missing restaurant images: {self.missing_restaurant_images}")
        print(f"Missing dish images:       {self.missing_dish_images}")
        print(f"Total execution time:      {self.execution_seconds:.1f}s")
        print("=" * w)


@dataclass
class PopulationReport:
    restaurants_total: int = 0
    restaurants_approved: int = 0
    restaurants_with_image: int = 0
    restaurants_missing_image: int = 0
    restaurants_missing_tags: int = 0
    dishes_total: int = 0
    dishes_with_image: int = 0
    dishes_missing_image: int = 0
    dishes_with_nutrition: int = 0
    dishes_missing_nutrition: int = 0
    dishes_missing_allergens: int = 0
    dishes_missing_cuisine: int = 0
    posts_total: int = 0
    restaurant_posts: int = 0
    blogs_total: int = 0
    reels_total: int = 0
    stories_total: int = 0
    users_total: int = 0
    friendships_total: int = 0
    groups_total: int = 0
    reviews_total: int = 0
    likes_total: int = 0
    comments_total: int = 0
    saves_total: int = 0
    placeholder_restaurants: int = 0
    placeholder_dishes: int = 0
    duplicate_external_codes: int = 0
    quality_score: float = 0.0
    notes: list[str] = field(default_factory=list)

    def print_report(self) -> None:
        w = 64
        print("=" * w)
        print("PHASE 9A — DATABASE QUALITY REPORT")
        print("=" * w)
        print(f"Restaurants:              {self.restaurants_total} ({self.restaurants_approved} approved)")
        print(f"  With cover/logo image:  {self.restaurants_with_image}")
        print(f"  Missing image:          {self.restaurants_missing_image}")
        print(f"  Missing cuisine tags:   {self.restaurants_missing_tags}")
        print(f"Dishes:                   {self.dishes_total}")
        print(f"  With image:             {self.dishes_with_image}")
        print(f"  Missing image:          {self.dishes_missing_image}")
        print(f"  With nutrition:         {self.dishes_with_nutrition}")
        print(f"  Missing nutrition:      {self.dishes_missing_nutrition}")
        print(f"  Missing allergens:      {self.dishes_missing_allergens}")
        print(f"  Missing cuisine:        {self.dishes_missing_cuisine}")
        print(f"Posts (total):            {self.posts_total}")
        print(f"  Restaurant posts:       {self.restaurant_posts}")
        print(f"Stories:                  {self.stories_total}")
        print(f"Reviews:                  {self.reviews_total}")
        print(f"Likes:                    {self.likes_total}")
        print(f"Comments:                 {self.comments_total}")
        print(f"Saved posts:              {self.saves_total}")
        print(f"Quality score:            {self.quality_score:.1f}/100")
        if self.notes:
            print("Notes:")
            for note in self.notes:
                print(f"  • {note}")
        print("=" * w)


def count_missing_images(db: Session) -> tuple[int, int]:
    restaurants_total = int(db.query(func.count(Restaurant.id)).scalar() or 0)
    restaurants_with_image = int(
        db.query(func.count(Restaurant.id))
        .filter(Restaurant.image.isnot(None), Restaurant.image != "")
        .scalar()
        or 0
    )
    dishes_total = int(db.query(func.count(Dish.id)).scalar() or 0)
    dishes_with_image = int(
        db.query(func.count(Dish.id)).filter(Dish.image.isnot(None), Dish.image != "").scalar() or 0
    )
    return restaurants_total - restaurants_with_image, dishes_total - dishes_with_image


def build_fyp_report(db: Session, **kwargs) -> FypRunReport:
    missing_r, missing_d = count_missing_images(db)
    return FypRunReport(
        missing_restaurant_images=missing_r,
        missing_dish_images=missing_d,
        **kwargs,
    )


def build_report(db: Session) -> PopulationReport:
    report = PopulationReport()

    report.restaurants_total = int(db.query(func.count(Restaurant.id)).scalar() or 0)
    report.restaurants_approved = int(
        db.query(func.count(Restaurant.id)).filter(Restaurant.approval_status == APPROVED).scalar() or 0
    )
    report.restaurants_with_image = int(
        db.query(func.count(Restaurant.id))
        .filter(Restaurant.image.isnot(None), Restaurant.image != "")
        .scalar()
        or 0
    )
    report.restaurants_missing_image = report.restaurants_total - report.restaurants_with_image
    report.restaurants_missing_tags = sum(
        1
        for (tags,) in db.query(Restaurant.tags).filter(Restaurant.approval_status == APPROVED).all()
        if not tags or (isinstance(tags, list) and len(tags) == 0)
    )

    report.dishes_total = int(db.query(func.count(Dish.id)).scalar() or 0)
    report.dishes_with_image = int(
        db.query(func.count(Dish.id)).filter(Dish.image.isnot(None), Dish.image != "").scalar() or 0
    )
    report.dishes_missing_image = report.dishes_total - report.dishes_with_image
    report.dishes_with_nutrition = int(
        db.query(func.count(Dish.id)).filter(Dish.calories.isnot(None)).scalar() or 0
    )
    report.dishes_missing_nutrition = report.dishes_total - report.dishes_with_nutrition
    report.dishes_missing_allergens = int(
        db.query(func.count(Dish.id)).filter(Dish.allergens.is_(None)).scalar() or 0
    )
    report.dishes_missing_cuisine = int(
        db.query(func.count(Dish.id))
        .filter(or_(Dish.cuisine.is_(None), Dish.cuisine == ""))
        .scalar()
        or 0
    )

    report.posts_total = int(db.query(func.count(Post.id)).scalar() or 0)
    report.restaurant_posts = int(
        db.query(func.count(Post.id)).filter(Post.post_type == "restaurant_post").scalar() or 0
    )
    report.reels_total = int(
        db.query(func.count(Post.id)).filter(Post.post_type == "chef_post").scalar() or 0
    )
    report.blogs_total = int(
        db.query(func.count(Post.id)).filter(Post.post_type == "recipe").scalar() or 0
    )
    report.stories_total = int(db.query(func.count(Story.id)).scalar() or 0)

    report.users_total = int(db.query(func.count(User.id)).scalar() or 0)
    report.friendships_total = int(db.query(func.count(Friendship.id)).scalar() or 0)
    report.groups_total = int(db.query(func.count(GroupSession.id)).scalar() or 0)
    report.reviews_total = int(db.query(func.count(Review.id)).scalar() or 0)
    report.likes_total = int(db.query(func.count(PostLike.id)).scalar() or 0)
    report.comments_total = int(db.query(func.count(PostComment.id)).scalar() or 0)
    report.saves_total = int(db.query(func.count(PostSave.id)).scalar() or 0)

    report.placeholder_restaurants = sum(
        1 for (name,) in db.query(Restaurant.name).all() if is_bad_restaurant_name(name)
    )
    report.placeholder_dishes = sum(
        1 for (name,) in db.query(Dish.name).all() if is_bad_dish_name(name)
    )

    codes = [
        c for (c,) in db.query(Restaurant.external_code).filter(Restaurant.external_code.isnot(None)).all() if c
    ]
    report.duplicate_external_codes = len(codes) - len({x.lower() for x in codes})

    scores: list[float] = []
    scores.append(min(20, 20 * report.restaurants_approved / 200))
    scores.append(min(25, 25 * report.dishes_total / 5000))
    img = (report.dishes_with_image / max(report.dishes_total, 1)) * 0.7 + (
        report.restaurants_with_image / max(report.restaurants_total, 1)
    ) * 0.3
    scores.append(15 * img)
    scores.append(10 * (report.dishes_with_nutrition / max(report.dishes_total, 1)))
    scores.append(10 * (1 - report.dishes_missing_allergens / max(report.dishes_total, 1)))
    social = min(1.0, report.restaurant_posts / max(report.restaurants_approved * 5, 1))
    scores.append(15 * social)
    scores.append(5 * min(1.0, report.reviews_total / 400))
    penalty = min(15, report.placeholder_restaurants * 2 + report.placeholder_dishes)
    report.quality_score = max(0.0, sum(scores) - penalty)

    if report.restaurants_missing_image:
        report.notes.append(f"{report.restaurants_missing_image} restaurants still need cover images.")
    if report.dishes_missing_nutrition:
        report.notes.append(f"{report.dishes_missing_nutrition} dishes missing nutrition.")

    return report
