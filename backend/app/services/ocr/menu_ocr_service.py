"""
Menu OCR orchestration — extract → normalize → JSON → optional DB import.
"""

import json
import logging
from pathlib import Path

from sqlalchemy.orm import Session

from app.services.ocr.importer import import_dishes
from app.services.ocr.normalizer import filter_valid_items, parse_menu_lines
from app.services.ocr.text_extractor import extract_raw_text

logger = logging.getLogger(__name__)


class MenuOcrService:
    def extract_menu_items(self, image_path: Path) -> list[dict]:
        raw = extract_raw_text(image_path)
        items = parse_menu_lines(raw)
        return filter_valid_items(items)

    def to_json(self, items: list[dict], *, raw_text: str | None = None) -> str:
        payload = {
            "items": items,
            "item_count": len(items),
            "raw_text_preview": (raw_text or "")[:500] if raw_text else None,
        }
        return json.dumps(payload)

    def process_and_import(
        self,
        db: Session,
        image_path: Path,
        *,
        restaurant_id: int,
        default_category_id: int | None = None,
    ) -> dict:
        raw = extract_raw_text(image_path)
        items = filter_valid_items(parse_menu_lines(raw))
        summary = import_dishes(
            db,
            restaurant_id=restaurant_id,
            items=items,
            default_category_id=default_category_id,
        )
        return {
            "items": items,
            "extracted_json": self.to_json(items, raw_text=raw),
            "import": summary,
        }
