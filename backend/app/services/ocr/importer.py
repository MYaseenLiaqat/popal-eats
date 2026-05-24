"""Import normalized OCR dishes into PostgreSQL with validation."""

import logging
from decimal import Decimal

from sqlalchemy.orm import Session

from app.models.category import Category
from app.models.dish import Dish

logger = logging.getLogger(__name__)


def _resolve_category_id(db: Session, hint: str | None, default_id: int | None) -> int | None:
    if not hint:
        return default_id
    cat = db.query(Category).filter(Category.name.ilike(hint)).first()
    if cat:
        return cat.id
    # Title-case hint as category name match
    cat = db.query(Category).filter(Category.name.ilike(hint.capitalize())).first()
    return cat.id if cat else default_id


def import_dishes(
    db: Session,
    *,
    restaurant_id: int,
    items: list[dict],
    default_category_id: int | None = None,
    skip_duplicates: bool = True,
) -> dict:
    """
    Insert dishes from OCR items. Returns import summary.
    """
    created = 0
    skipped = 0
    errors: list[str] = []

    existing_names = {
        d.name.lower()
        for d in db.query(Dish).filter(Dish.restaurant_id == restaurant_id).all()
    }

    for item in items:
        name = item.get("name", "").strip()
        if not name:
            skipped += 1
            continue

        if skip_duplicates and name.lower() in existing_names:
            skipped += 1
            logger.debug("Skipping existing dish: %s", name)
            continue

        try:
            price = Decimal(str(item["price"]))
        except Exception:
            errors.append(f"Invalid price for {name}")
            skipped += 1
            continue

        category_id = _resolve_category_id(
            db, item.get("category_hint"), default_category_id
        )
        if category_id is None:
            errors.append(f"No category for {name} (hint={item.get('category_hint')})")
            skipped += 1
            continue

        dish = Dish(
            restaurant_id=restaurant_id,
            category_id=category_id,
            name=name,
            description=item.get("description"),
            price=price,
            is_available=True,
        )
        db.add(dish)
        existing_names.add(name.lower())
        created += 1

    db.flush()
    logger.info(
        "Menu import restaurant=%s created=%s skipped=%s errors=%s",
        restaurant_id,
        created,
        skipped,
        len(errors),
    )
    return {"created": created, "skipped": skipped, "errors": errors}
