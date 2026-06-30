#!/usr/bin/env python
"""Verify Alembic migrations create every ORM table (read-only check).

Usage:
  cd backend && python scripts/verify_schema_tables.py
  cd backend && python scripts/verify_schema_tables.py --database   # also check live DB
"""

from __future__ import annotations

import argparse
import sys
from pathlib import Path

_BACKEND = Path(__file__).resolve().parent.parent
if str(_BACKEND) not in sys.path:
    sys.path.insert(0, str(_BACKEND))

from alembic.config import Config
from alembic.script import ScriptDirectory
from sqlalchemy import inspect

from app.database import Base, engine

# Register every ORM table on Base.metadata
from app.models import (  # noqa: F401
    Cart,
    CartItem,
    Category,
    Dish,
    FriendRequest,
    Friendship,
    GroupDecision,
    GroupInvitation,
    GroupMemberLocation,
    GroupRecommendation,
    GroupSession,
    GroupSessionMember,
    GroupVote,
    HomeChefProfile,
    MenuUpload,
    Order,
    OrderItem,
    Post,
    PostComment,
    PostLike,
    PostSave,
    RecommendationEvent,
    RefreshToken,
    Restaurant,
    Review,
    Story,
    StoryView,
    User,
    UserPreference,
)


def _migration_create_tables() -> set[str]:
    """Tables created by op.create_table across all revisions."""
    import re

    versions_dir = _BACKEND / "alembic" / "versions"
    created: set[str] = set()
    for path in versions_dir.glob("*.py"):
        text = path.read_text(encoding="utf-8")
        for match in re.finditer(r'op\.create_table\(\s*["\']([^"\']+)["\']', text):
            created.add(match.group(1))
    return created


def main() -> int:
    parser = argparse.ArgumentParser(description="Verify schema table coverage")
    parser.add_argument(
        "--database",
        action="store_true",
        help="Compare against live DATABASE_URL (requires connectivity)",
    )
    args = parser.parse_args()

    cfg = Config(str(_BACKEND / "alembic.ini"))
    script = ScriptDirectory.from_config(cfg)
    head = script.get_current_head()

    orm_tables = set(Base.metadata.tables.keys())
    migration_tables = _migration_create_tables()

    missing_from_migrations = sorted(orm_tables - migration_tables)
    extra_in_migrations = sorted(migration_tables - orm_tables - {"alembic_version"})

    print("=" * 60)
    print("SCHEMA TABLE VERIFICATION")
    print("=" * 60)
    print(f"Alembic head: {head}")
    print(f"ORM tables: {len(orm_tables)}")
    print(f"Tables created in migrations: {len(migration_tables)}")
    print()

    if missing_from_migrations:
        print("MISSING from migrations:")
        for name in missing_from_migrations:
            print(f"  - {name}")
    else:
        print("OK: Every ORM table has a create_table migration.")

    if extra_in_migrations:
        print("\nExtra migration-only tables (no ORM model):")
        for name in extra_in_migrations:
            print(f"  - {name}")

    print("\nAll application tables (alphabetical):")
    for name in sorted(orm_tables):
        print(f"  {name}")

    if args.database:
        print("\n--- Live database ---")
        try:
            insp = inspect(engine)
            db_tables = {t for t in insp.get_table_names() if t != "alembic_version"}
            missing_in_db = sorted(orm_tables - db_tables)
            extra_in_db = sorted(db_tables - orm_tables)
            if missing_in_db:
                print("Missing in database:")
                for name in missing_in_db:
                    print(f"  - {name}")
            else:
                print("OK: Database contains every ORM table.")
            if extra_in_db:
                print("Extra in database (no ORM model):")
                for name in extra_in_db:
                    print(f"  - {name}")
        except Exception as exc:
            print(f"Could not connect: {exc}")
            return 1

    return 1 if missing_from_migrations else 0


if __name__ == "__main__":
    raise SystemExit(main())
