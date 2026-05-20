"""
Application settings loaded from backend/.env.

Uses python-dotenv so secrets stay out of source code.
"""

import os
from pathlib import Path

from dotenv import load_dotenv

# Always load backend/.env (works even if you start uvicorn from another folder)
_backend_dir = Path(__file__).resolve().parent.parent
load_dotenv(_backend_dir / ".env", override=True)

# --- Database ---
DATABASE_URL = os.getenv("DATABASE_URL")

# --- JWT (JSON Web Token) ---
# SECRET_KEY signs tokens; never commit a real production key to git.
SECRET_KEY = os.getenv("SECRET_KEY")
# Algorithm used to sign JWTs (HS256 is standard for symmetric keys)
ALGORITHM = os.getenv("ALGORITHM", "HS256")
# How long a login token stays valid (minutes)
ACCESS_TOKEN_EXPIRE_MINUTES = int(os.getenv("ACCESS_TOKEN_EXPIRE_MINUTES", "30"))
