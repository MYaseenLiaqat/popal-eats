"""Stamp Alembic on existing DBs, then upgrade to head."""

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from sqlalchemy import inspect, text

from app.database import engine
from alembic import command
from alembic.config import Config


def main() -> None:
    cfg = Config(str(Path(__file__).resolve().parents[1] / "alembic.ini"))
    inspector = inspect(engine)
    existing = set(inspector.get_table_names())

    if existing & {"users", "restaurants", "categories"}:
        print("Existing tables detected — stamping 001_initial then upgrading...")
        command.stamp(cfg, "001_initial")
    command.upgrade(cfg, "head")
    print("Alembic upgrade head complete.")


if __name__ == "__main__":
    main()
