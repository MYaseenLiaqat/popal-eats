"""
Popal Eats API entry point.

On startup: try to create SQLAlchemy tables in PostgreSQL (does not block if DB is offline).
"""

import logging
from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.database import Base, engine
from app.models import Category, Dish, Restaurant, User  # noqa: F401 — register all tables
from app.routes.auth import router as auth_router
from app.routes.category import router as category_router
from app.routes.dish import router as dish_router
from app.routes.restaurant import router as restaurant_router

logger = logging.getLogger(__name__)


@asynccontextmanager
async def lifespan(app: FastAPI):
    """
    Run once when the server starts.
    Creates tables (users, categories, restaurants, dishes) if DB is reachable.
    """
    try:
        Base.metadata.create_all(bind=engine)
        logger.info("Database connected — tables ready.")
    except Exception as exc:
        logger.warning(
            "Database not reachable at startup: %s. "
            "Check internet, DATABASE_URL in backend/.env, and Neon dashboard. "
            "Server will run, but DB routes may fail until connected.",
            exc,
        )
    yield


app = FastAPI(
    title="Popal Eats API",
    version="1.0.0",
    description="Food delivery API with JWT authentication, restaurants, and menus",
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Auth
app.include_router(auth_router)
# Menu & restaurants
app.include_router(category_router)
app.include_router(restaurant_router)
app.include_router(dish_router)


@app.get("/")
def home():
    return {"message": "Popal Eats Backend Running"}
