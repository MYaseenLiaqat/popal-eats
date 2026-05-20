"""
Popal Eats API entry point.

On startup: create SQLAlchemy tables in PostgreSQL if they do not exist yet.
"""

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.database import Base, engine
from app.models import User  # noqa: F401 — register User model with Base.metadata
from app.routes.auth import router as auth_router

app = FastAPI(
    title="Popal Eats API",
    version="1.0.0",
    description="Food delivery API with JWT authentication",
)

# Auto-create tables (users, etc.) — fine for development; use Alembic migrations in production
Base.metadata.create_all(bind=engine)

# CORS: allows Flutter/web frontends to call this API from another origin
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=False,  # must be False when allow_origins is "*"
    allow_methods=["*"],
    allow_headers=["*"],
)

# Auth: POST /register, POST /login
app.include_router(auth_router)


@app.get("/")
def home():
    return {"message": "Popal Eats Backend Running"}
