"""
Popal Eats API — production entry point.

Schema: Alembic migrations only.
Workers: rq worker popal_eats (see README).
"""

import logging
from contextlib import asynccontextmanager

from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from slowapi import Limiter, _rate_limit_exceeded_handler
from slowapi.errors import RateLimitExceeded
from slowapi.middleware import SlowAPIMiddleware
from slowapi.util import get_remote_address

from app.config import get_settings
from app.core.exceptions import register_exception_handlers
from app.core.logging_config import setup_logging
from app.core.middleware import RequestLoggingMiddleware
from app.database import check_database_ready, engine
from app.routes.admin import router as admin_router
from app.routes.auth import router as auth_router
from app.routes.cart import router as cart_router
from app.routes.category import router as category_router
from app.routes.dish import router as dish_router
from app.routes.menu import router as menu_router
from app.routes.order import checkout_router, restaurant_orders_router, router as order_router
from app.routes.friends import router as friends_router
from app.routes.groups import router as groups_router
from app.routes.preferences import router as preferences_router
from app.routes.restaurant import router as restaurant_router
from app.routes.review import router as review_router
from app.routes.content import router as content_router
from app.routes.stories import router as stories_router
from app.routes.recommendations_v2 import router as recommendations_v2_router

settings = get_settings()
setup_logging(settings.log_level)
logger = logging.getLogger(__name__)

limiter = Limiter(key_func=get_remote_address, default_limits=[settings.rate_limit_default])


@asynccontextmanager
async def lifespan(app: FastAPI):
    dialect = engine.dialect.name
    driver = engine.dialect.driver

    logger.info("Starting Popal Eats API v3.0.0 (debug=%s)", settings.debug)
    logger.info("CORS origins: %s", settings.cors_origins_list)
    logger.info("Review processing: inline=%s redis=%s", settings.process_reviews_inline, settings.redis_url)
    logger.info("OCR engine: %s", settings.ocr_engine)

    if not settings.secret_key:
        logger.error("SECRET_KEY missing — auth will fail.")

    try:
        tables = check_database_ready()
        logger.info("PostgreSQL connected (%s/%s). Tables: %s", dialect, driver, ", ".join(tables))
        logger.info("App startup completed.")
    except Exception as exc:
        logger.error("Database not ready: %s — run: alembic upgrade head", exc, exc_info=True)

    yield


def create_app() -> FastAPI:
    application = FastAPI(
        title="Popal Eats API",
        version="3.0.0",
        description=(
            "Food delivery API — AI reviews, OCR menu import, admin, JWT+refresh, "
            "cart & orders, recommendations V2 (Phase 0)"
        ),
        lifespan=lifespan,
        debug=settings.debug,
    )

    application.state.limiter = limiter
    application.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)
    register_exception_handlers(application)

    application.add_middleware(SlowAPIMiddleware)
    application.add_middleware(RequestLoggingMiddleware)
    application.add_middleware(
        CORSMiddleware,
        allow_origins=settings.cors_origins_list,
        # Flutter web dev server uses random localhost ports (e.g. :56565).
        allow_origin_regex=r"http://(localhost|127\.0\.0\.1)(:\d+)?",
        allow_credentials=True,
        allow_methods=["GET", "POST", "PUT", "DELETE", "PATCH", "OPTIONS"],
        allow_headers=["Authorization", "Content-Type"],
    )

    application.include_router(auth_router)
    application.include_router(category_router)
    application.include_router(restaurant_router)
    application.include_router(dish_router)
    application.include_router(review_router)
    application.include_router(recommendations_v2_router)
    application.include_router(content_router)
    application.include_router(stories_router)
    application.include_router(preferences_router)
    application.include_router(friends_router)
    application.include_router(groups_router)
    application.include_router(menu_router)
    application.include_router(admin_router)
    application.include_router(cart_router)
    application.include_router(checkout_router)
    application.include_router(order_router)
    application.include_router(restaurant_orders_router)

    uploads_path = settings.upload_path
    uploads_path.mkdir(parents=True, exist_ok=True)
    application.mount("/uploads", StaticFiles(directory=str(uploads_path)), name="uploads")

    @application.get("/health")
    @limiter.limit(settings.rate_limit_default)
    def health(request: Request):
        return {"status": "ok", "version": "3.0.0"}

    @application.get("/")
    @limiter.limit(settings.rate_limit_default)
    def home(request: Request):
        return {
            "message": "Popal Eats Backend Running",
            "docs": "/docs",
            "version": "3.0.0",
        }

    return application


app = create_app()
