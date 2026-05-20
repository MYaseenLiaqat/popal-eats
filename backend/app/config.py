import os
from pathlib import Path

from dotenv import load_dotenv

# Load backend/.env regardless of current working directory
_backend_dir = Path(__file__).resolve().parent.parent
# Prefer values from backend/.env over inherited shell/system env (avoids stale DATABASE_URL)
load_dotenv(_backend_dir / ".env", override=True)

DATABASE_URL = os.getenv("DATABASE_URL")
