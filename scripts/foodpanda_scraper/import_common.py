"""
Shared utilities for Foodpanda → Popal Eats PostgreSQL import (Phase 3).
"""

from __future__ import annotations

import ast
import logging
import os
import re
import sys
from dataclasses import dataclass, field
from decimal import Decimal, InvalidOperation
from pathlib import Path

from dotenv import load_dotenv
from sqlalchemy import func
from sqlalchemy.orm import Session

# Project roots
SCRAPER_DIR = Path(__file__).resolve().parent
PROJECT_ROOT = SCRAPER_DIR.parents[1]
BACKEND_DIR = PROJECT_ROOT / "backend"
OUTPUT_DIR = SCRAPER_DIR / "output"
REPORT_PATH = SCRAPER_DIR / "import_report.md"
RESTAURANTS_EXCEL = OUTPUT_DIR / "restaurants.xlsx"
DISHES_EXCEL = OUTPUT_DIR / "dishes.xlsx"
IMPORT_MAP_JSON = OUTPUT_DIR / "restaurant_vendor_map.json"

BATCH_SIZE = int(os.getenv("FOODPANDA_IMPORT_BATCH_SIZE", "100"))
VENDOR_CODE_PREFIX = "Foodpanda vendor_code:"

logger = logging.getLogger(__name__)


def setup_backend_path() -> None:
    """Allow `from app.*` imports using backend package."""
    backend_str = str(BACKEND_DIR)
    if backend_str not in sys.path:
        sys.path.insert(0, backend_str)


def load_backend_env() -> None:
    env_path = BACKEND_DIR / ".env"
    if not env_path.is_file():
        raise FileNotFoundError(f"Missing backend/.env at {env_path}")
    load_dotenv(env_path, override=True)


def get_session() -> Session:
    setup_backend_path()
    load_backend_env()
    from app.database import SessionLocal

    return SessionLocal()


@dataclass
class ImportStats:
    inserted: int = 0
    skipped: int = 0
    errors: list[str] = field(default_factory=list)

    def add_error(self, message: str) -> None:
        self.errors.append(message)
        logger.error(message)


def setup_logging(verbose: bool = False) -> None:
    level = logging.DEBUG if verbose else logging.INFO
    logging.basicConfig(
        level=level,
        format="%(asctime)s | %(levelname)s | %(message)s",
        datefmt="%Y-%m-%d %H:%M:%S",
    )


def normalize_name(value: str | None) -> str:
    if not value:
        return ""
    return re.sub(r"\s+", " ", str(value).strip()).lower()


def parse_city(value: object) -> str | None:
    if value is None or (isinstance(value, float) and str(value) == "nan"):
        return None
    text = str(value).strip()
    if not text or text.lower() == "nan":
        return None
    if text.startswith("{") and "name" in text:
        try:
            parsed = ast.literal_eval(text)
            if isinstance(parsed, dict) and parsed.get("name"):
                return str(parsed["name"])[:100]
        except (SyntaxError, ValueError):
            pass
    return text[:100]


def build_restaurant_description(
    *,
    vendor_code: str,
    vendor_id: str,
    cuisines: str | None = None,
    url_key: str | None = None,
) -> str:
    lines = [
        "Imported from Foodpanda.",
        f"{VENDOR_CODE_PREFIX} {vendor_code}",
        f"Foodpanda vendor_id: {vendor_id}",
    ]
    if url_key:
        lines.append(f"Foodpanda url_key: {url_key}")
    if cuisines and str(cuisines).strip() and str(cuisines).lower() != "nan":
        lines.append(f"Cuisines: {cuisines}")
    return "\n".join(lines)


def extract_vendor_code(description: str | None) -> str | None:
    if not description:
        return None
    for line in description.splitlines():
        line = line.strip()
        if line.startswith(VENDOR_CODE_PREFIX):
            return line[len(VENDOR_CODE_PREFIX) :].strip()
    return None


def resolve_import_owner_id(session: Session, *, dry_run: bool) -> int:
    from app.core.roles import ADMIN, RESTAURANT_OWNER
    from app.models.user import User

    owner_id_raw = os.getenv("FOODPANDA_IMPORT_OWNER_ID")
    if owner_id_raw:
        owner_id = int(owner_id_raw)
        user = session.get(User, owner_id)
        if not user and not dry_run:
            raise ValueError(f"FOODPANDA_IMPORT_OWNER_ID={owner_id} not found in users table")
        return owner_id

    owner_email = os.getenv("FOODPANDA_IMPORT_OWNER_EMAIL", "").strip().lower()
    if owner_email:
        user = session.query(User).filter(func.lower(User.email) == owner_email).first()
        if user:
            return user.id
        if not dry_run:
            raise ValueError(f"FOODPANDA_IMPORT_OWNER_EMAIL={owner_email} not found")

    for role in (RESTAURANT_OWNER, ADMIN):
        user = session.query(User).filter(User.role == role).order_by(User.id).first()
        if user:
            logger.info("Using owner user id=%s role=%s email=%s", user.id, user.role, user.email)
            return user.id

    raise ValueError(
        "No import owner found. Set FOODPANDA_IMPORT_OWNER_ID or FOODPANDA_IMPORT_OWNER_EMAIL "
        "in backend/.env, or create a restaurant_owner/admin user."
    )


def load_existing_restaurant_indexes(session: Session) -> tuple[dict[str, int], dict[str, int]]:
    """
    Build lookup maps: normalized name -> id, vendor_code -> id.
    """
    from app.models.restaurant import Restaurant

    by_name: dict[str, int] = {}
    by_vendor_code: dict[str, int] = {}

    for restaurant in session.query(Restaurant).all():
        by_name[normalize_name(restaurant.name)] = restaurant.id
        code = extract_vendor_code(restaurant.description)
        if code:
            by_vendor_code[code.lower()] = restaurant.id

    return by_name, by_vendor_code


def find_existing_restaurant_id(
    by_name: dict[str, int],
    by_vendor_code: dict[str, int],
    *,
    vendor_code: str,
    vendor_name: str,
) -> int | None:
    code_key = vendor_code.strip().lower()
    if code_key and code_key in by_vendor_code:
        return by_vendor_code[code_key]

    name_key = normalize_name(vendor_name)
    if name_key and name_key in by_name:
        return by_name[name_key]

    return None


def parse_decimal(value: object) -> Decimal | None:
    if value is None:
        return None
    if isinstance(value, float) and str(value) == "nan":
        return None
    text = str(value).strip()
    if not text or text.lower() == "nan":
        return None
    try:
        return Decimal(text).quantize(Decimal("0.01"))
    except (InvalidOperation, ValueError):
        return None


def dish_price(discounted: object, regular: object) -> Decimal | None:
    """Use discounted price when present, else list price."""
    return parse_decimal(discounted) or parse_decimal(regular)


def get_or_create_category(
    session: Session,
    category_name: str,
    *,
    dry_run: bool,
    cache: dict[str, int],
    stats: ImportStats,
) -> int | None:
    from app.models.category import Category

    name = str(category_name or "").strip()[:120]
    if not name:
        name = "Uncategorized"

    cache_key = normalize_name(name)
    if cache_key in cache:
        return cache[cache_key]

    existing = (
        session.query(Category)
        .filter(func.lower(Category.name) == cache_key)
        .first()
    )
    if existing:
        cache[cache_key] = existing.id
        return existing.id

    if dry_run:
        cache[cache_key] = -1
        return -1

    category = Category(name=name, description="Imported from Foodpanda menus")
    session.add(category)
    session.flush()
    cache[cache_key] = category.id
    logger.debug("Created category id=%s name=%s", category.id, name)
    return category.id


def load_vendor_restaurant_map(session: Session) -> dict[str, int]:
    """vendor_code -> restaurant_id from DB descriptions and names."""
    by_name, by_vendor_code = load_existing_restaurant_indexes(session)
    return dict(by_vendor_code)


def append_report(section_title: str, lines: list[str]) -> None:
    """Append a section to import_report.md (create or extend)."""
    header = f"## {section_title}\n\n"
    body = "\n".join(lines) + "\n\n"
    if REPORT_PATH.exists():
        existing = REPORT_PATH.read_text(encoding="utf-8")
        if section_title in existing:
            # Replace section between this header and next ##
            pattern = rf"## {re.escape(section_title)}\n\n.*?(?=\n## |\Z)"
            existing = re.sub(pattern, header + body, existing, count=1, flags=re.DOTALL)
            REPORT_PATH.write_text(existing, encoding="utf-8")
            return
        content = existing.rstrip() + "\n\n" + header + body
    else:
        content = "# Foodpanda PostgreSQL Import Report\n\n" + header + body
    REPORT_PATH.write_text(content, encoding="utf-8")
    logger.info("Updated report -> %s", REPORT_PATH)


def write_report_header() -> None:
    if not REPORT_PATH.exists():
        REPORT_PATH.write_text(
            "# Foodpanda PostgreSQL Import Report\n\n",
            encoding="utf-8",
        )
