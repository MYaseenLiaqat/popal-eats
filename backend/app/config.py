"""
Centralized configuration with validation (loaded from backend/.env).
"""

import os
from functools import lru_cache
from pathlib import Path

from dotenv import load_dotenv
from pydantic import Field, field_validator
from pydantic_settings import BaseSettings, SettingsConfigDict

_backend_dir = Path(__file__).resolve().parent.parent
load_dotenv(_backend_dir / ".env", override=True)


def normalize_database_url(url: str | None) -> str | None:
    if not url:
        return None
    stripped = url.strip()
    lower = stripped.lower()
    if lower.startswith("mysql") or "pymysql" in lower:
        raise ValueError("DATABASE_URL must use PostgreSQL.")
    if lower.startswith("postgres://"):
        return "postgresql+psycopg2://" + stripped[11:]
    if lower.startswith("postgresql://"):
        return "postgresql+psycopg2://" + stripped[13:]
    if lower.startswith("postgresql+psycopg2://"):
        return stripped
    raise ValueError(f"Unsupported DATABASE_URL scheme: {stripped.split(':', 1)[0]}")


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=str(_backend_dir / ".env"),
        env_file_encoding="utf-8",
        extra="ignore",
    )

    database_url: str = Field(..., alias="DATABASE_URL")
    secret_key: str = Field(..., alias="SECRET_KEY")
    algorithm: str = Field("HS256", alias="ALGORITHM")
    access_token_expire_minutes: int = Field(30, alias="ACCESS_TOKEN_EXPIRE_MINUTES")
    refresh_token_expire_days: int = Field(7, alias="REFRESH_TOKEN_EXPIRE_DAYS")

    debug: bool = Field(False, alias="DEBUG")
    log_level: str = Field("INFO", alias="LOG_LEVEL")
    cors_origins: str = Field(
        "http://localhost:3000,http://127.0.0.1:8000",
        alias="CORS_ORIGINS",
    )
    rate_limit_default: str = Field("200/minute", alias="RATE_LIMIT_DEFAULT")

    redis_url: str = Field("redis://127.0.0.1:6379/0", alias="REDIS_URL")
    rq_queue_name: str = Field("popal_eats", alias="RQ_QUEUE_NAME")
    process_reviews_inline: bool = Field(False, alias="PROCESS_REVIEWS_INLINE")

    upload_dir: str = Field(str(_backend_dir / "uploads"), alias="UPLOAD_DIR")
    max_upload_mb: int = Field(10, alias="MAX_UPLOAD_MB")
    ocr_engine: str = Field("tesseract", alias="OCR_ENGINE")  # tesseract | easyocr | mock

    default_translation_target: str = Field("en", alias="DEFAULT_TRANSLATION_TARGET")
    sentiment_model_name: str = Field(
        "nlptown/bert-base-multilingual-uncased-sentiment",
        alias="SENTIMENT_MODEL_NAME",
    )
    enable_hf_sentiment: bool = Field(False, alias="ENABLE_HF_SENTIMENT")
    enable_marian_translation: bool = Field(False, alias="ENABLE_MARIAN_TRANSLATION")

    # Foodpanda (Pakistan) external API — used by app.integrations.foodpanda
    foodpanda_vendors_api_url: str = Field(
        "https://pk.fd-api.com/vendors-gateway/api/v1/pandora/vendors",
        alias="FOODPANDA_VENDORS_API_URL",
    )
    foodpanda_menu_api_base: str = Field(
        "https://pk.fd-api.com/api/v5",
        alias="FOODPANDA_MENU_API_BASE",
    )
    foodpanda_site_origin: str = Field(
        "https://www.foodpanda.pk",
        alias="FOODPANDA_SITE_ORIGIN",
    )
    foodpanda_default_latitude: float = Field(24.8607, alias="FOODPANDA_LATITUDE")
    foodpanda_default_longitude: float = Field(67.0011, alias="FOODPANDA_LONGITUDE")
    foodpanda_country: str = Field("pk", alias="FOODPANDA_COUNTRY")
    foodpanda_language_id: int = Field(1, alias="FOODPANDA_LANGUAGE_ID")
    foodpanda_configuration: str = Field("Variant1", alias="FOODPANDA_CONFIGURATION")
    foodpanda_request_timeout_seconds: int = Field(30, alias="FOODPANDA_REQUEST_TIMEOUT")
    foodpanda_disco_client_id: str = Field("web", alias="FOODPANDA_DISCO_CLIENT_ID")
    foodpanda_perseus_client_id: str = Field("web", alias="FOODPANDA_PERSEUS_CLIENT_ID")
    foodpanda_perseus_session_id: str = Field("", alias="FOODPANDA_PERSEUS_SESSION_ID")
    foodpanda_user_agent: str = Field(
        (
            "Mozilla/5.0 (Windows NT 10.0; Win64; x64) "
            "AppleWebKit/537.36 (KHTML, like Gecko) "
            "Chrome/131.0.0.0 Safari/537.36"
        ),
        alias="FOODPANDA_USER_AGENT",
    )
    foodpanda_accept_language: str = Field("en-PK,en;q=0.9", alias="FOODPANDA_ACCEPT_LANGUAGE")

    @field_validator("database_url", mode="before")
    @classmethod
    def validate_db_url(cls, v: str) -> str:
        normalized = normalize_database_url(v)
        if not normalized:
            raise ValueError("DATABASE_URL is required")
        return normalized

    @field_validator("secret_key", mode="before")
    @classmethod
    def validate_secret(cls, v: str | None) -> str:
        key = v or os.getenv("JWT_SECRET_KEY")
        if not key:
            raise ValueError("SECRET_KEY is required in backend/.env")
        return key

    @property
    def cors_origins_list(self) -> list[str]:
        if self.cors_origins.strip() == "*":
            return ["*"]
        return [o.strip() for o in self.cors_origins.split(",") if o.strip()]

    @property
    def upload_path(self) -> Path:
        return Path(self.upload_dir)


@lru_cache
def get_settings() -> Settings:
    return Settings()


# Module-level aliases (backward compatible)
_settings = get_settings()
DATABASE_URL = _settings.database_url
SECRET_KEY = _settings.secret_key
ALGORITHM = _settings.algorithm
ACCESS_TOKEN_EXPIRE_MINUTES = _settings.access_token_expire_minutes
REFRESH_TOKEN_EXPIRE_DAYS = _settings.refresh_token_expire_days
DEBUG = _settings.debug
LOG_LEVEL = _settings.log_level
CORS_ORIGINS = _settings.cors_origins_list
RATE_LIMIT_DEFAULT = _settings.rate_limit_default
REDIS_URL = _settings.redis_url
RQ_QUEUE_NAME = _settings.rq_queue_name
PROCESS_REVIEWS_INLINE = _settings.process_reviews_inline
UPLOAD_DIR = _settings.upload_path
MAX_UPLOAD_MB = _settings.max_upload_mb
OCR_ENGINE = _settings.ocr_engine
