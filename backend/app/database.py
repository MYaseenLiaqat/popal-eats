from collections.abc import Generator

from sqlalchemy import create_engine, text
from sqlalchemy.engine import Engine
from sqlalchemy.orm import DeclarativeBase, Session, sessionmaker

from app.config import DATABASE_URL

if not DATABASE_URL:
    raise ValueError(
        "DATABASE_URL is not set. Add it to backend/.env (see README) and restart."
    )

if not DATABASE_URL.startswith("postgresql+psycopg2://"):
    raise ValueError(
        "DATABASE_URL must use the PostgreSQL psycopg2 driver "
        "(postgresql+psycopg2://...). Check backend/.env."
    )

engine: Engine = create_engine(
    DATABASE_URL,
    pool_pre_ping=True,
    pool_recycle=300,
    pool_size=2,
    max_overflow=2,
    connect_args={"sslmode": "require"} if "sslmode=require" in DATABASE_URL else {},
)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)


class Base(DeclarativeBase):
    pass


def verify_postgresql_connection() -> None:
    """Raise if the engine cannot connect to PostgreSQL."""
    with engine.connect() as conn:
        conn.execute(text("SELECT 1"))


def check_database_ready() -> list[str]:
    """
    Verify connectivity and that expected tables exist (Alembic-managed).

    Does NOT call create_all — schema changes use migrations only.
    """
    from app.models import (  # noqa: F401
        Category,
        Dish,
        MenuUpload,
        RecommendationEvent,
        RefreshToken,
        Restaurant,
        Review,
        User,
    )

    verify_postgresql_connection()
    with engine.connect() as conn:
        rows = conn.execute(
            text(
                "SELECT table_name FROM information_schema.tables "
                "WHERE table_schema = 'public' AND table_type = 'BASE TABLE'"
            )
        ).fetchall()
    existing = {r[0] for r in rows}
    expected = set(Base.metadata.tables.keys())
    missing = expected - existing
    if missing:
        raise RuntimeError(
            f"Missing tables: {', '.join(sorted(missing))}. "
            "Run: alembic upgrade head"
        )
    return sorted(existing & expected)


def get_db() -> Generator[Session, None, None]:
    db = SessionLocal()
    try:
        yield db
    except Exception:
        db.rollback()
        raise
    finally:
        db.close()
