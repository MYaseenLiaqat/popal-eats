"""
Popal Eats API entry point.

On startup: try to create all SQLAlchemy tables (does not block if DB is offline).
"""

import logging
from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.database import Base, engine
from app.models import (  # noqa: F401 — register all tables
    Cart,
    CartItem,
    Category,
    Dish,
    Order,
    OrderItem,
    Restaurant,
    User,
)
from app.routes.auth import router as auth_router
from app.routes.cart import router as cart_router
from app.routes.category import router as category_router
from app.routes.dish import router as dish_router
from app.routes.order import checkout_router, restaurant_orders_router, router as order_router
from app.routes.restaurant import router as restaurant_router

logger = logging.getLogger(__name__)


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Create tables (users, menus, carts, orders) if database is reachable."""
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
    description="Food delivery API: auth, restaurants, cart, checkout, orders",
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth_router)
app.include_router(category_router)
app.include_router(restaurant_router)
app.include_router(dish_router)
app.include_router(cart_router)
app.include_router(checkout_router)
app.include_router(order_router)
app.include_router(restaurant_orders_router)


@app.get("/")
def home():
    return {"message": "Popal Eats Backend Running"}
