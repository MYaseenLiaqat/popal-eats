"""
Configuration for Foodpanda (Pakistan) vendor/menu scrapers.

Verified against pk.fd-api.com (2026-06): requests without ``x-disco-client-id: web``
return HTTP 403 {"message":"Invalid or null Client Id"}.

Override coordinates via environment variables:
  FOODPANDA_LATITUDE
  FOODPANDA_LONGITUDE
"""

from __future__ import annotations

import os
from pathlib import Path
from typing import Any

# Project paths
BASE_DIR: Path = Path(__file__).resolve().parent
RAW_DIR: Path = BASE_DIR / "raw"
OUTPUT_DIR: Path = BASE_DIR / "output"

# API — Pakistan Pandora vendors gateway (same host as foodpanda.pk web app)
VENDORS_API_URL: str = (
    "https://pk.fd-api.com/vendors-gateway/api/v1/pandora/vendors"
)

# Browser context (foodpanda.pk)
SITE_ORIGIN: str = "https://www.foodpanda.pk"
SITE_REFERER: str = "https://www.foodpanda.pk/"

# Default location: Karachi
DEFAULT_LATITUDE: float = float(os.getenv("FOODPANDA_LATITUDE", "24.8607"))
DEFAULT_LONGITUDE: float = float(os.getenv("FOODPANDA_LONGITUDE", "67.0011"))

def build_vendor_query_params(
    latitude: float | None = None,
    longitude: float | None = None,
) -> dict[str, Any]:
    """
    Query string matching foodpanda.pk Network tab for pandora/vendors (Pakistan).

    Verified 2026-06: without these params + ``x-disco-client-id`` the API returns 403.
    """
    lat = latitude if latitude is not None else DEFAULT_LATITUDE
    lon = longitude if longitude is not None else DEFAULT_LONGITUDE
    return {
        "latitude": lat,
        "longitude": lon,
        "language_id": int(os.getenv("FOODPANDA_LANGUAGE_ID", "1")),
        "include": "characteristics",
        "dynamic_pricing": 0,
        "configuration": os.getenv("FOODPANDA_CONFIGURATION", "Variant1"),
        "country": "pk",
        "budgets": "",
        "cuisine": "",
        "sort": "",
        "food_characteristic": "",
        "use_free_delivery_label": "false",
        "vertical": "restaurants",
        "limit": int(os.getenv("FOODPANDA_LIMIT", "48")),
        "offset": 0,
        "customer_type": "regular",
    }

# Headers — browser DevTools / Delivery Hero Pandora listing API
BROWSER_HEADERS: dict[str, str] = {
    "Accept": "application/json, text/plain, */*",
    "Accept-Language": "en-PK,en;q=0.9",
    "Origin": SITE_ORIGIN,
    "Referer": SITE_REFERER,
    "User-Agent": (
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64) "
        "AppleWebKit/537.36 (KHTML, like Gecko) "
        "Chrome/131.0.0.0 Safari/537.36"
    ),
    "x-disco-client-id": "web",
    "Sec-Fetch-Dest": "empty",
    "Sec-Fetch-Mode": "cors",
    "Sec-Fetch-Site": "same-site",
}

# Legacy minimal headers (403 — documented for comparison only)
LEGACY_PYTHON_HEADERS: dict[str, str] = {
    "Accept": "application/json",
    "Accept-Language": "en-PK,en;q=0.9",
    "User-Agent": BROWSER_HEADERS["User-Agent"],
}

REQUEST_TIMEOUT_SECONDS: int = 30
ERROR_RESPONSE_FILE: str = "error_response.txt"

# Menu API (api/v5) — requires Perseus session headers (see menu_endpoint_discovery.py)
MENU_API_V5_BASE: str = "https://pk.fd-api.com/api/v5"
PERSEUS_HEADERS: dict[str, str] = {
    "perseus-client-id": "web",
    "perseus-session-id": os.getenv(
        "FOODPANDA_PERSEUS_SESSION_ID",
        "popal-eats-discovery-session",
    ),
}

# Output filenames
VENDORS_RAW_JSON: str = "vendors.json"
RESTAURANTS_EXCEL: str = "restaurants.xlsx"
MENU_RAW_JSON: str = "menu.json"
DISHES_EXCEL: str = "dishes.xlsx"
BROWSER_REFERENCE_FILE: str = "browser_request_reference.json"
REQUEST_COMPARISON_FILE: str = "request_comparison_report.txt"

# Logging
LOG_LEVEL: str = os.getenv("FOODPANDA_LOG_LEVEL", "INFO")
