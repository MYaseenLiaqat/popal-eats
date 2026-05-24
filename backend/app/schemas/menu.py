"""Schemas for menu upload / OCR pipeline."""

from datetime import datetime
from typing import Any

from pydantic import BaseModel, ConfigDict, Field


class MenuUploadResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    restaurant_id: int
    uploaded_by: int
    file_path: str
    original_filename: str | None
    status: str
    error_message: str | None = None
    created_at: datetime | None = None
    processed_at: datetime | None = None


class MenuExtractionPreview(BaseModel):
    upload_id: int
    status: str
    items: list[dict] = Field(default_factory=list)
    message: str = "OCR extraction complete"


class MenuImportResponse(BaseModel):
    upload_id: int
    status: str
    items: list[dict] = Field(default_factory=list)
    import_summary: dict[str, Any] = Field(default_factory=dict)
    message: str
