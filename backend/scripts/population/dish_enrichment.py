"""Derive nutrition, allergens, cuisine, and descriptions for dishes."""

from __future__ import annotations

import random
import re
from dataclasses import dataclass

from sqlalchemy import func, or_
from sqlalchemy.orm import Session

from app.models.dish import Dish
from app.models.restaurant import Restaurant

from .placeholders import is_bad_text
from .progress import log_progress

_NUTRITION_CAP = 300
_BATCH = 50

_NUTRITION_HINTS: list[tuple[re.Pattern[str], dict[str, float | int]]] = [
    (re.compile(r"biryani|pulao", re.I), {"calories": 520, "protein": 22, "carbs": 68, "fats": 16}),
    (re.compile(r"burger|zinger", re.I), {"calories": 580, "protein": 28, "carbs": 45, "fats": 32}),
    (re.compile(r"pizza", re.I), {"calories": 640, "protein": 26, "carbs": 72, "fats": 28}),
    (re.compile(r"karahi|curry|handi", re.I), {"calories": 480, "protein": 30, "carbs": 18, "fats": 34}),
    (re.compile(r"roll|wrap|shawarma", re.I), {"calories": 420, "protein": 20, "carbs": 38, "fats": 20}),
    (re.compile(r"salad", re.I), {"calories": 180, "protein": 8, "carbs": 14, "fats": 10}),
    (re.compile(r"fries", re.I), {"calories": 360, "protein": 4, "carbs": 42, "fats": 18}),
    (re.compile(r"shake|milkshake|lassi", re.I), {"calories": 280, "protein": 6, "carbs": 44, "fats": 8}),
    (re.compile(r"bbq|tikka|seekh", re.I), {"calories": 390, "protein": 34, "carbs": 8, "fats": 24}),
    (re.compile(r"naan|roti|paratha", re.I), {"calories": 260, "protein": 7, "carbs": 42, "fats": 7}),
]

_ALLERGEN_KEYWORDS: list[tuple[re.Pattern[str], str]] = [
    (re.compile(r"nut|almond|cashew|pistachio|walnut", re.I), "nuts"),
    (re.compile(r"milk|cheese|cream|butter|dairy|paneer", re.I), "dairy"),
    (re.compile(r"egg|omelette|mayo", re.I), "eggs"),
    (re.compile(r"gluten|wheat|bread|naan|roti|burger bun", re.I), "gluten"),
    (re.compile(r"soy|soya", re.I), "soy"),
    (re.compile(r"shellfish|prawn|shrimp", re.I), "shellfish"),
    (re.compile(r"fish", re.I), "fish"),
]


@dataclass
class DishEnrichmentStats:
    dishes_updated: int = 0
    nutrition_filled: int = 0
    allergens_filled: int = 0
    cuisine_filled: int = 0
    descriptions_filled: int = 0
    images_linked: int = 0


def _infer_nutrition(name: str, description: str | None) -> dict[str, float | int]:
    blob = f"{name} {description or ''}"
    for pattern, values in _NUTRITION_HINTS:
        if pattern.search(blob):
            return values
    return {
        "calories": random.randint(280, 520),
        "protein": random.randint(12, 28),
        "carbs": random.randint(20, 55),
        "fats": random.randint(10, 28),
    }


def _infer_allergens(name: str, description: str | None) -> list[str]:
    blob = f"{name} {description or ''}"
    found: list[str] = []
    for pattern, label in _ALLERGEN_KEYWORDS:
        if pattern.search(blob) and label not in found:
            found.append(label)
    return found


def _load_restaurant_maps(db: Session) -> tuple[dict[int, list], dict[int, str]]:
    tags = {r.id: (r.tags or []) for r in db.query(Restaurant.id, Restaurant.tags).all()}
    names = {r.id: r.name for r in db.query(Restaurant.id, Restaurant.name).all()}
    return tags, names


def _fill_nutrition_batch(
    db: Session,
    stats: DishEnrichmentStats,
    *,
    budget: int,
) -> int:
    remaining = budget
    last_id = 0
    processed = 0

    while remaining > 0:
        batch = (
            db.query(Dish)
            .filter(
                Dish.id > last_id,
                or_(Dish.calories.is_(None), Dish.allergens.is_(None)),
            )
            .order_by(Dish.id)
            .limit(min(_BATCH, remaining))
            .all()
        )
        if not batch:
            break

        for dish in batch:
            changed = False
            if dish.calories is None:
                n = _infer_nutrition(dish.name, dish.description)
                dish.calories = int(n["calories"])
                dish.protein = n["protein"]
                dish.carbs = n["carbs"]
                dish.fats = n["fats"]
                dish.fiber = round(random.uniform(2, 8), 1)
                dish.sugar = round(random.uniform(2, 14), 1)
                dish.sodium = random.randint(180, 680)
                stats.nutrition_filled += 1
                changed = True
            if dish.allergens is None:
                dish.allergens = _infer_allergens(dish.name, dish.description)
                stats.allergens_filled += 1
                changed = True
            if changed:
                stats.dishes_updated += 1
            last_id = dish.id
            processed += 1
            remaining -= 1

        db.commit()
        log_progress("Dish nutrition", processed, budget)

    return remaining


def _fill_metadata_batch(
    db: Session,
    stats: DishEnrichmentStats,
    restaurant_tags: dict[int, list],
    restaurant_names: dict[int, str],
) -> None:
    total = int(
        db.query(func.count(Dish.id))
        .filter(
            or_(
                Dish.cuisine.is_(None),
                Dish.cuisine == "",
                Dish.image.is_(None),
                Dish.image == "",
                Dish.description.is_(None),
                Dish.description == "",
            )
        )
        .scalar()
        or 0
    )
    last_id = 0
    processed = 0

    while True:
        batch = (
            db.query(Dish)
            .filter(
                Dish.id > last_id,
                or_(
                    Dish.cuisine.is_(None),
                    Dish.cuisine == "",
                    Dish.image.is_(None),
                    Dish.image == "",
                    Dish.description.is_(None),
                    Dish.description == "",
                ),
            )
            .order_by(Dish.id)
            .limit(_BATCH)
            .all()
        )
        if not batch:
            break

        fallback_images: dict[int, str | None] = {}
        for rid in {d.restaurant_id for d in batch}:
            fallback_images[rid] = (
                db.query(Dish.image)
                .filter(Dish.restaurant_id == rid, Dish.image.isnot(None), Dish.image != "")
                .limit(1)
                .scalar()
            )

        for dish in batch:
            changed = False

            if not dish.cuisine:
                tags = restaurant_tags.get(dish.restaurant_id) or []
                if tags:
                    dish.cuisine = str(tags[0])[:100]
                    stats.cuisine_filled += 1
                    changed = True

            if not dish.description or is_bad_text(dish.description):
                rname = restaurant_names.get(dish.restaurant_id, "our kitchen")
                dish.description = (
                    f"Fresh {dish.name} prepared to order at {rname}. "
                    f"A customer favourite in Lahore."
                )[:500]
                stats.descriptions_filled += 1
                changed = True

            if not dish.image or not str(dish.image).strip():
                fb = fallback_images.get(dish.restaurant_id)
                if fb:
                    dish.image = fb
                    stats.images_linked += 1
                    changed = True

            if not dish.tags:
                tags_out: list[str] = []
                if dish.cuisine:
                    tags_out.append(str(dish.cuisine).lower())
                for t in (restaurant_tags.get(dish.restaurant_id) or [])[:2]:
                    tags_out.append(str(t).lower())
                if tags_out:
                    dish.tags = list(dict.fromkeys(tags_out))[:6]
                    changed = True

            if changed:
                stats.dishes_updated += 1

            last_id = dish.id
            processed += 1

        db.commit()
        log_progress("Dish metadata", processed, total)


def enrich_dishes(db: Session, *, seed: int = 42) -> DishEnrichmentStats:
    random.seed(seed)
    stats = DishEnrichmentStats()
    restaurant_tags, restaurant_names = _load_restaurant_maps(db)

    _fill_nutrition_batch(db, stats, budget=_NUTRITION_CAP)
    _fill_metadata_batch(db, stats, restaurant_tags, restaurant_names)

    return stats


enrich_dish_nutrition = enrich_dishes
