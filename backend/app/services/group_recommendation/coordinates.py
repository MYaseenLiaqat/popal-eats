"""Restaurant coordinate lookup for group distance scoring."""

from __future__ import annotations

import json
import logging
from functools import lru_cache
from pathlib import Path

from app.config import get_settings
from app.models.restaurant import Restaurant
from app.services.recommendation.v2_catalog import FOODPANDA_SOURCE

logger = logging.getLogger(__name__)


@lru_cache(maxsize=1)
def _manifest_coordinate_index() -> dict[str, tuple[float, float]]:
    settings = get_settings()
    manifest_path = settings.foodpanda_bulk_data_path / "lahore" / "latest" / "manifest.json"
    if not manifest_path.is_file():
        logger.debug("Foodpanda manifest not found at %s — distance scoring uses fallback", manifest_path)
        return {}

    try:
        payload = json.loads(manifest_path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        logger.warning("Failed to load Foodpanda manifest for coordinates: %s", exc)
        return {}

    index: dict[str, tuple[float, float]] = {}
    for vendor in payload.get("vendors", []):
        code = vendor.get("external_code")
        lat = vendor.get("latitude")
        lng = vendor.get("longitude")
        if code and lat is not None and lng is not None:
            index[str(code)] = (float(lat), float(lng))
    return index


def build_restaurant_coordinate_map(
    restaurants: list[Restaurant],
) -> dict[int, tuple[float, float]]:
    """Map restaurant_id → (lat, lng) using Foodpanda manifest external_code."""
    manifest = _manifest_coordinate_index()
    fallback = default_city_centroid()

    coords: dict[int, tuple[float, float]] = {}
    for restaurant in restaurants:
        if restaurant.source != FOODPANDA_SOURCE or not restaurant.external_code:
            continue
        hit = manifest.get(restaurant.external_code) if manifest else None
        if hit:
            coords[restaurant.id] = hit
        else:
            coords[restaurant.id] = fallback
    return coords


def default_city_centroid() -> tuple[float, float]:
    settings = get_settings()
    return settings.foodpanda_lahore_latitude, settings.foodpanda_lahore_longitude
