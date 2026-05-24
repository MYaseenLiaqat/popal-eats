"""
Menu OCR ingestion: upload, import, process.

POST /menu/import — upload + OCR + validate + DB import in one flow.
"""

import json
import uuid
from pathlib import Path

from fastapi import APIRouter, Depends, File, HTTPException, Query, UploadFile, status
from sqlalchemy.orm import Session

from app.config import MAX_UPLOAD_MB, UPLOAD_DIR
from app.core.dependencies import get_current_user
from app.core.permissions import assert_restaurant_owner, get_restaurant_or_404
from app.database import get_db
from app.models.menu_upload import MenuUpload
from app.models.user import User
from app.schemas.menu import MenuExtractionPreview, MenuImportResponse, MenuUploadResponse
from app.services.ocr import MenuOcrService
from app.services.ocr.text_extractor import extract_raw_text

router = APIRouter(prefix="/menu", tags=["menu"])
_ocr = MenuOcrService()

ALLOWED_EXTENSIONS = {".jpg", ".jpeg", ".png", ".webp", ".pdf"}


async def _save_upload(restaurant_id: int, file: UploadFile, user_id: int, db: Session) -> MenuUpload:
    suffix = Path(file.filename or "").suffix.lower()
    if suffix not in ALLOWED_EXTENSIONS:
        raise HTTPException(
            status_code=400,
            detail=f"Allowed types: {', '.join(sorted(ALLOWED_EXTENSIONS))}",
        )

    content = await file.read()
    if len(content) > MAX_UPLOAD_MB * 1024 * 1024:
        raise HTTPException(status_code=400, detail=f"Max {MAX_UPLOAD_MB}MB")

    UPLOAD_DIR.mkdir(parents=True, exist_ok=True)
    dest = UPLOAD_DIR / f"{restaurant_id}_{uuid.uuid4().hex}{suffix}"
    dest.write_bytes(content)

    record = MenuUpload(
        restaurant_id=restaurant_id,
        uploaded_by=user_id,
        file_path=str(dest),
        original_filename=file.filename,
        status="pending",
    )
    db.add(record)
    db.commit()
    db.refresh(record)
    return record


@router.post("/upload", response_model=MenuUploadResponse, status_code=status.HTTP_201_CREATED)
async def upload_menu(
    restaurant_id: int,
    file: UploadFile = File(...),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    restaurant = get_restaurant_or_404(db, restaurant_id)
    assert_restaurant_owner(restaurant, current_user)
    return await _save_upload(restaurant_id, file, current_user.id, db)


@router.post("/import", response_model=MenuImportResponse, status_code=status.HTTP_201_CREATED)
async def import_menu(
    restaurant_id: int,
    file: UploadFile = File(...),
    default_category_id: int = Query(..., description="Category for imported dishes"),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """
    Full pipeline: upload → OCR → normalize → validate → import dishes.
    """
    restaurant = get_restaurant_or_404(db, restaurant_id)
    assert_restaurant_owner(restaurant, current_user)

    record = await _save_upload(restaurant_id, file, current_user.id, db)
    record.status = "processing"
    db.commit()

    try:
        result = _ocr.process_and_import(
            db,
            Path(record.file_path),
            restaurant_id=restaurant_id,
            default_category_id=default_category_id,
        )
        record.extracted_json = result["extracted_json"]
        record.status = "completed"
        db.commit()
        db.refresh(record)

        return MenuImportResponse(
            upload_id=record.id,
            status=record.status,
            items=result["items"],
            import_summary=result["import"],
            message="Menu imported successfully",
        )
    except Exception as exc:
        record.status = "failed"
        record.error_message = str(exc)[:2000]
        db.commit()
        raise HTTPException(status_code=500, detail=f"Menu import failed: {exc}") from exc


@router.post("/upload/{upload_id}/process", response_model=MenuExtractionPreview)
def process_menu_upload(
    upload_id: int,
    default_category_id: int | None = Query(None),
    import_to_db: bool = Query(False),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    record = db.query(MenuUpload).filter(MenuUpload.id == upload_id).first()
    if not record:
        raise HTTPException(status_code=404, detail="Upload not found")

    restaurant = get_restaurant_or_404(db, record.restaurant_id)
    assert_restaurant_owner(restaurant, current_user)

    path = Path(record.file_path)
    if import_to_db and default_category_id:
        result = _ocr.process_and_import(
            db,
            path,
            restaurant_id=record.restaurant_id,
            default_category_id=default_category_id,
        )
        items = result["items"]
        record.extracted_json = result["extracted_json"]
    else:
        raw = extract_raw_text(path)
        items = _ocr.extract_menu_items(path)
        record.extracted_json = _ocr.to_json(items, raw_text=raw)

    record.status = "completed"
    db.commit()

    return MenuExtractionPreview(
        upload_id=record.id,
        status=record.status,
        items=items,
    )


@router.get("/uploads", response_model=list[MenuUploadResponse])
def list_uploads(
    restaurant_id: int | None = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    query = db.query(MenuUpload)
    if restaurant_id:
        restaurant = get_restaurant_or_404(db, restaurant_id)
        assert_restaurant_owner(restaurant, current_user)
        query = query.filter(MenuUpload.restaurant_id == restaurant_id)
    return query.order_by(MenuUpload.created_at.desc()).limit(50).all()
