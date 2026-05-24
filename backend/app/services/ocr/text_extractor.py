"""OCR text extraction — Tesseract, EasyOCR, or mock."""

import logging
from pathlib import Path

from app.config import get_settings

logger = logging.getLogger(__name__)


def extract_raw_text(image_path: Path) -> str:
    settings = get_settings()
    engine = settings.ocr_engine.lower()

    if engine == "easyocr":
        return _easyocr_extract(image_path)
    if engine == "tesseract":
        return _tesseract_extract(image_path)
    return _mock_extract(image_path)


def _tesseract_extract(image_path: Path) -> str:
    try:
        import pytesseract  # noqa: PLC0415
        from PIL import Image  # noqa: PLC0415

        img = Image.open(image_path)
        text = pytesseract.image_to_string(img)
        logger.info("Tesseract extracted %d chars from %s", len(text), image_path.name)
        return text
    except Exception as exc:
        logger.warning("Tesseract failed (%s), using mock", exc)
        return _mock_extract(image_path)


def _easyocr_extract(image_path: Path) -> str:
    try:
        import easyocr  # noqa: PLC0415

        reader = easyocr.Reader(["en", "ur"], gpu=False)
        lines = reader.readtext(str(image_path), detail=0)
        text = "\n".join(lines)
        logger.info("EasyOCR extracted %d chars", len(text))
        return text
    except Exception as exc:
        logger.warning("EasyOCR failed (%s), using mock", exc)
        return _mock_extract(image_path)


def _mock_extract(image_path: Path) -> str:
    """Deterministic sample for dev without OCR binaries."""
    logger.info("Mock OCR for %s", image_path)
    return (
        "Chicken Biryani 12.99\n"
        "Beef Karahi 15.50\n"
        "Mutton Pulao 18.00\n"
        "Soft Drink 2.50\n"
        "Garlic Naan 3.99\n"
    )
