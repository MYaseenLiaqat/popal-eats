#!/usr/bin/env python
"""Remove demo / QA test users and their data from the database.

Keeps restaurant + dish catalog (Foodpanda import). Reassigns any restaurants
owned by deleted users to the admin account before removal.

Usage (from backend/):
  python scripts/cleanup_demo_users.py --dry-run
  python scripts/cleanup_demo_users.py --confirm
"""

from __future__ import annotations

import argparse
import sys
from pathlib import Path

_backend = Path(__file__).resolve().parent.parent
if str(_backend) not in sys.path:
    sys.path.insert(0, str(_backend))

from sqlalchemy import delete, or_

from app.database import SessionLocal
from app.models.home_chef_profile import HomeChefProfile
from app.models.menu_upload import MenuUpload
from app.models.order import Order
from app.models.order_item import OrderItem
from app.models.restaurant import Restaurant
from app.models.user import User

# Emails we never delete automatically.
KEEP_EMAILS = {
    "admin@popaleats.com",
}

# Delete users whose email ends with any of these domains.
DELETE_EMAIL_SUFFIXES = (
    "@example.com",
    "@fyp.community",
    "@test.com",
)


def _should_delete(user: User) -> bool:
    email = (user.email or "").lower().strip()
    if not email or email in KEEP_EMAILS:
        return False
    return any(email.endswith(suffix) for suffix in DELETE_EMAIL_SUFFIXES)


def main() -> int:
    parser = argparse.ArgumentParser(description="Remove demo/QA users from the database")
    parser.add_argument("--dry-run", action="store_true", help="Show what would be deleted")
    parser.add_argument("--confirm", action="store_true", help="Actually delete users")
    args = parser.parse_args()

    if not args.dry_run and not args.confirm:
        print("Pass --dry-run to preview or --confirm to delete.")
        return 1

    db = SessionLocal()
    try:
        admin = db.query(User).filter(User.email == "admin@popaleats.com").first()
        if admin is None:
            print("ERROR: admin@popaleats.com not found — aborting.")
            return 1

        users = db.query(User).all()
        to_delete = [u for u in users if _should_delete(u)]
        keep = [u for u in users if u not in to_delete]

        print(f"Total users:     {len(users)}")
        print(f"Will delete:     {len(to_delete)}")
        print(f"Will keep:       {len(keep)}")
        print()
        print("Keeping:")
        for u in keep:
            print(f"  - {u.email} ({u.role})")
        print()
        print("Deleting:")
        for u in to_delete:
            print(f"  - {u.email} ({u.role})")

        owned = (
            db.query(Restaurant)
            .filter(Restaurant.owner_id.in_([u.id for u in to_delete]))
            .count()
        )
        print(f"\nRestaurants to reassign to admin: {owned}")

        if args.dry_run:
            print("\n[DRY RUN] No changes made.")
            return 0

        if not to_delete:
            print("\nNothing to delete.")
            return 0

        delete_ids = [u.id for u in to_delete]

        # ORM delete nullifies orders without cascade — remove dependents first.
        order_ids = [
            row[0]
            for row in db.query(Order.id).filter(Order.user_id.in_(delete_ids)).all()
        ]
        if order_ids:
            db.query(OrderItem).filter(OrderItem.order_id.in_(order_ids)).delete(
                synchronize_session=False
            )
            db.query(Order).filter(Order.id.in_(order_ids)).delete(synchronize_session=False)

        db.query(MenuUpload).filter(MenuUpload.uploaded_by.in_(delete_ids)).delete(
            synchronize_session=False
        )
        db.query(HomeChefProfile).filter(HomeChefProfile.user_id.in_(delete_ids)).delete(
            synchronize_session=False
        )

        qa_restaurants = (
            db.query(Restaurant).filter(Restaurant.owner_id.in_(delete_ids)).all()
        )
        reassigned = 0
        removed_restaurants = 0
        for restaurant in qa_restaurants:
            if restaurant.source == "foodpanda" and restaurant.external_code:
                restaurant.owner_id = admin.id
                reassigned += 1
            else:
                db.delete(restaurant)
                removed_restaurants += 1
        print(f"Reassigned Foodpanda restaurants: {reassigned}")
        print(f"Removed QA/test restaurants: {removed_restaurants}")

        db.flush()
        db.execute(delete(User).where(User.id.in_(delete_ids)))
        db.commit()
        print(f"\nDeleted {len(to_delete)} user(s). Restaurants catalog kept.")
        return 0
    except Exception as exc:
        db.rollback()
        print(f"ERROR: {exc}")
        return 1
    finally:
        db.close()


if __name__ == "__main__":
    raise SystemExit(main())
