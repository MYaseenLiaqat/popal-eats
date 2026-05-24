"""
ETL normalization for OCR menu text.

- Clean noise
- Parse dish names + prices
- Infer categories
- Filter invalid rows
- Detect duplicates
"""

import logging
import re
from decimal import Decimal, InvalidOperation

logger = logging.getLogger(__name__)

_PRICE_TRAIL = re.compile(
    r"(.+?)\s+[\$£€]?\s*(\d{1,4}(?:[.,]\d{1,2})?)\s*$"
)
_NOISE = re.compile(r"[^\w\s\.\$€£\-\'&]", re.UNICODE)

_CATEGORY_KEYWORDS = {
    "drink": ["drink", "cola", "juice", "water", "soda", "tea", "coffee"],
    "main": ["biryani", "karahi", "pulao", "burger", "pizza", "curry", "rice"],
    "bread": ["naan", "roti", "bread"],
    "dessert": ["dessert", "sweet", "ice cream", "cake"],
}


def clean_line(line: str) -> str:
    line = line.strip()
    line = _NOISE.sub(" ", line)
    return re.sub(r"\s+", " ", line).strip()


def normalize_price(raw: str) -> Decimal | None:
    try:
        cleaned = raw.replace(",", ".")
        value = Decimal(cleaned)
        if value <= 0 or value > 9999:
            return None
        return value.quantize(Decimal("0.01"))
    except (InvalidOperation, ValueError):
        return None


def infer_category(name: str) -> str | None:
    lower = name.lower()
    for cat, keywords in _CATEGORY_KEYWORDS.items():
        if any(k in lower for k in keywords):
            return cat
    return None


def parse_menu_lines(raw_text: str) -> list[dict]:
    """Parse OCR text into structured dish candidates."""
    items: list[dict] = []
    seen_names: set[str] = set()

    for raw_line in raw_text.splitlines():
        line = clean_line(raw_line)
        if len(line) < 3:
            continue

        match = _PRICE_TRAIL.match(line)
        if not match:
            continue

        name, price_raw = match.group(1).strip(), match.group(2)
        price = normalize_price(price_raw)
        if not name or price is None:
            continue

        key = name.lower()
        if key in seen_names:
            logger.debug("Duplicate dish skipped: %s", name)
            continue
        seen_names.add(key)

        items.append(
            {
                "name": name[:200],
                "price": str(price),
                "description": None,
                "category_hint": infer_category(name),
                "source_line": raw_line,
            }
        )

    logger.info("Parsed %d menu items from OCR text", len(items))
    return items


def filter_valid_items(items: list[dict]) -> list[dict]:
    return [i for i in items if i.get("name") and i.get("price")]
