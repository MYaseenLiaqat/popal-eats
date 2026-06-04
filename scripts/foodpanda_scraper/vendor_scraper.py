"""
Foodpanda vendor (restaurant) scraper — Phase 1.

Fetches vendors from the Pandora API, saves raw JSON, and exports restaurants.xlsx.
"""

from __future__ import annotations

import json
import logging
import sys
from pathlib import Path
from typing import Any

import pandas as pd
import requests

from config import (
    BROWSER_HEADERS,
    BROWSER_REFERENCE_FILE,
    DEFAULT_LATITUDE,
    DEFAULT_LONGITUDE,
    ERROR_RESPONSE_FILE,
    LEGACY_PYTHON_HEADERS,
    LOG_LEVEL,
    OUTPUT_DIR,
    RAW_DIR,
    REQUEST_COMPARISON_FILE,
    REQUEST_TIMEOUT_SECONDS,
    RESTAURANTS_EXCEL,
    SITE_ORIGIN,
    SITE_REFERER,
    VENDORS_API_URL,
    VENDORS_RAW_JSON,
    build_vendor_query_params,
)
from export_excel import save_dataframe_excel

logger = logging.getLogger(__name__)

# Columns for restaurants.xlsx (filled when data is available)
VENDOR_COLUMNS: list[str] = [
    "vendor_id",
    "vendor_code",
    "vendor_name",
    "url_key",
    "rating",
    "review_count",
    "minimum_order_amount",
    "delivery_fee",
    "delivery_time",
    "cuisines",
    "address",
    "city",
    "latitude",
    "longitude",
    "is_open",
]


def setup_logging(level: str | None = None) -> None:
    """Configure root logging for CLI runs."""
    logging.basicConfig(
        level=getattr(logging, (level or LOG_LEVEL).upper(), logging.INFO),
        format="%(asctime)s | %(levelname)s | %(name)s | %(message)s",
        datefmt="%Y-%m-%d %H:%M:%S",
    )


def ensure_directories() -> None:
    """Create raw/ and output/ if missing."""
    RAW_DIR.mkdir(parents=True, exist_ok=True)
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    logger.debug("Ensured directories: %s, %s", RAW_DIR, OUTPUT_DIR)


def _legacy_minimal_params(lat: float, lon: float) -> dict[str, Any]:
    """Old Python scraper params (caused HTTP 403)."""
    return {"latitude": lat, "longitude": lon}


def log_request_debug(
    *,
    url: str,
    params: dict[str, Any],
    headers: dict[str, str],
    response: requests.Response | None = None,
) -> None:
    """DEBUG: full URL, params, headers, status, body preview."""
    prepared = requests.Request("GET", url, params=params, headers=headers).prepare()
    logger.debug("=== HTTP REQUEST DEBUG ===")
    logger.debug("Full URL: %s", prepared.url)
    logger.debug("Query parameters: %s", json.dumps(params, ensure_ascii=False, sort_keys=True))
    logger.debug("Headers: %s", json.dumps(headers, ensure_ascii=False, indent=2, sort_keys=True))
    if response is not None:
        logger.debug("Response status: %s", response.status_code)
        preview = (response.text or "")[:500]
        logger.debug("Response body (first 500 chars): %s", preview)


def save_error_response(response: requests.Response) -> Path:
    """Persist non-200 response body to raw/error_response.txt."""
    ensure_directories()
    target = RAW_DIR / ERROR_RESPONSE_FILE
    lines = [
        f"status_code: {response.status_code}",
        f"url: {response.url}",
        "",
        response.text or "",
    ]
    target.write_text("\n".join(lines), encoding="utf-8")
    logger.error("Saved error response -> %s", target)
    return target


def write_request_comparison_report(
    *,
    lat: float,
    lon: float,
    browser_params: dict[str, Any],
    browser_headers: dict[str, str],
    legacy_params: dict[str, Any],
    legacy_headers: dict[str, str],
) -> Path:
    """
    Document differences between failing minimal Python request and browser request.
    """
    ensure_directories()
    target = RAW_DIR / REQUEST_COMPARISON_FILE

    browser_url = requests.Request(
        "GET", VENDORS_API_URL, params=browser_params, headers=browser_headers
    ).prepare().url
    legacy_url = requests.Request(
        "GET", VENDORS_API_URL, params=legacy_params, headers=legacy_headers
    ).prepare().url

    missing_headers = sorted(set(browser_headers) - set(legacy_headers))
    extra_headers = sorted(set(legacy_headers) - set(browser_headers))
    missing_params = sorted(set(browser_params) - set(legacy_params))
    extra_params = sorted(set(legacy_params) - set(browser_params))

    lines = [
        "Foodpanda Vendor API — Request Comparison Report",
        "=" * 60,
        "",
        "ENDPOINT (both):",
        f"  {VENDORS_API_URL}",
        "",
        "BROWSER / WORKING REQUEST (foodpanda.pk DevTools + probe 200 OK):",
        f"  URL: {browser_url}",
        "  Required header: x-disco-client-id: web",
        f"  Origin: {SITE_ORIGIN}",
        f"  Referer: {SITE_REFERER}",
        "",
        "LEGACY PYTHON REQUEST (403 Invalid or null Client Id):",
        f"  URL: {legacy_url}",
        "",
        "MISSING HEADERS in legacy (must add):",
        *[f"  - {h}: {browser_headers[h]!r}" for h in missing_headers],
        "",
        "MISSING QUERY PARAMETERS in legacy (must add):",
        *[f"  - {k}: {browser_params[k]!r}" for k in missing_params],
        "",
        "ROOT CAUSE:",
        "  1. Missing x-disco-client-id: web (API returns 403 without it)",
        "  2. Missing Pandora listing query params (country, vertical, language_id, ...)",
        "  3. Missing Origin/Referer from https://www.foodpanda.pk",
        "",
        "REQUIRED FIXES (applied in config.py + vendor_scraper.py):",
        "  - Use BROWSER_HEADERS including x-disco-client-id",
        "  - Use build_vendor_query_params() for full query string",
        "  - Set Origin + Referer to foodpanda.pk",
    ]
    target.write_text("\n".join(lines), encoding="utf-8")
    logger.info("Wrote request comparison -> %s", target)
    return target


def save_browser_request_reference(
    params: dict[str, Any],
    headers: dict[str, str],
) -> Path:
    """Save canonical working request template for reproducibility."""
    ensure_directories()
    target = RAW_DIR / BROWSER_REFERENCE_FILE
    payload = {
        "method": "GET",
        "url": VENDORS_API_URL,
        "query_parameters": params,
        "headers": headers,
        "verified_status": 200,
        "note": "Captured via probe against pk.fd-api.com; matches foodpanda.pk web listing API.",
    }
    with target.open("w", encoding="utf-8") as fh:
        json.dump(payload, fh, ensure_ascii=False, indent=2)
    return target


def _first(*values: Any) -> Any:
    """Return the first non-None value."""
    for value in values:
        if value is not None:
            return value
    return None


def _as_list_join(value: Any, sep: str = ", ") -> str | None:
    """Normalize cuisines/tags to a comma-separated string."""
    if value is None:
        return None
    if isinstance(value, str):
        return value
    if isinstance(value, list):
        parts: list[str] = []
        for item in value:
            if isinstance(item, dict):
                parts.append(
                    str(
                        _first(
                            item.get("name"),
                            item.get("title"),
                            item.get("locale"),
                        )
                        or item
                    )
                )
            else:
                parts.append(str(item))
        return sep.join(parts) if parts else None
    return str(value)


def fetch_vendors(
    latitude: float | None = None,
    longitude: float | None = None,
    *,
    extra_params: dict[str, Any] | None = None,
) -> dict[str, Any]:
    """
    Request vendors from the Foodpanda Pandora API (browser-mimic).

    Args:
        latitude: Search latitude (defaults to config).
        longitude: Search longitude (defaults to config).
        extra_params: Additional query parameters for the API.

    Returns:
        Parsed JSON response as a dict.

    Raises:
        requests.RequestException: On network/HTTP failures.
        ValueError: On empty or non-JSON responses.
    """
    lat = latitude if latitude is not None else DEFAULT_LATITUDE
    lon = longitude if longitude is not None else DEFAULT_LONGITUDE

    params = build_vendor_query_params(lat, lon)
    if extra_params:
        params.update(extra_params)

    headers = dict(BROWSER_HEADERS)

    write_request_comparison_report(
        lat=lat,
        lon=lon,
        browser_params=params,
        browser_headers=headers,
        legacy_params=_legacy_minimal_params(lat, lon),
        legacy_headers=LEGACY_PYTHON_HEADERS,
    )
    save_browser_request_reference(params, headers)

    logger.info("Fetching vendors lat=%s lon=%s url=%s", lat, lon, VENDORS_API_URL)

    response = requests.get(
        VENDORS_API_URL,
        params=params,
        headers=headers,
        timeout=REQUEST_TIMEOUT_SECONDS,
    )

    log_request_debug(url=VENDORS_API_URL, params=params, headers=headers, response=response)

    if response.status_code != 200:
        save_error_response(response)
        response.raise_for_status()

    if not response.text or not response.text.strip():
        save_error_response(response)
        raise ValueError("Vendors API returned an empty response body")

    try:
        payload: dict[str, Any] = response.json()
    except json.JSONDecodeError as exc:
        save_error_response(response)
        raise ValueError(f"Vendors API returned invalid JSON: {exc}") from exc

    if not payload:
        raise ValueError("Vendors API returned empty JSON object")

    logger.info(
        "Fetched vendors response (%d bytes, status=%s)",
        len(response.content),
        response.status_code,
    )
    return payload


def _extract_vendor_list(payload: dict[str, Any]) -> list[dict[str, Any]]:
    """
    Extract vendor list from varying API response shapes.

    Common shapes:
      - {"data": {"data": [...]}}
      - {"data": [...]}
      - {"items": [...]}
    """
    data = payload.get("data", payload)

    if isinstance(data, dict):
        for key in ("data", "items", "vendors", "restaurants"):
            inner = data.get(key)
            if isinstance(inner, list):
                return [v for v in inner if isinstance(v, dict)]
        # Single vendor wrapped in data
        if data.get("id") or data.get("vendor_id") or data.get("code"):
            return [data]

    if isinstance(data, list):
        return [v for v in data if isinstance(v, dict)]

    if isinstance(payload.get("items"), list):
        return [v for v in payload["items"] if isinstance(v, dict)]

    return []


def _parse_vendor_row(vendor: dict[str, Any]) -> dict[str, Any]:
    """Map one vendor object to a flat row for Excel export."""
    address = vendor.get("address") or vendor.get("address_line") or {}
    if isinstance(address, dict):
        address_text = _first(
            address.get("address_line_1"),
            address.get("formatted_address"),
            address.get("street"),
        )
        city = _first(address.get("city"), vendor.get("city"))
        lat = _first(address.get("latitude"), vendor.get("latitude"))
        lon = _first(address.get("longitude"), vendor.get("longitude"))
    else:
        address_text = str(address) if address else None
        city = vendor.get("city")
        lat = vendor.get("latitude")
        lon = vendor.get("longitude")

    delivery = vendor.get("delivery") or vendor.get("delivery_fee") or {}
    if isinstance(delivery, dict):
        delivery_fee = _first(
            delivery.get("fee"),
            delivery.get("delivery_fee"),
            delivery.get("amount"),
        )
        delivery_time = _first(
            delivery.get("time"),
            delivery.get("delivery_time"),
            delivery.get("duration"),
        )
        minimum_order = _first(
            delivery.get("minimum_order_amount"),
            delivery.get("minimum_order_value"),
        )
    else:
        delivery_fee = delivery
        delivery_time = vendor.get("delivery_time")
        minimum_order = vendor.get("minimum_order_amount")

    rating_block = vendor.get("rating") or {}
    if isinstance(rating_block, dict):
        rating = _first(rating_block.get("value"), rating_block.get("average"))
        review_count = _first(
            rating_block.get("count"),
            rating_block.get("review_count"),
            vendor.get("review_count"),
        )
    else:
        rating = rating_block or vendor.get("average_rating")
        review_count = vendor.get("review_count")

    cuisines = _as_list_join(
        _first(
            vendor.get("cuisines"),
            vendor.get("cuisine_types"),
            vendor.get("tags"),
            vendor.get("characteristics"),
        )
    )

    is_open = _first(
        vendor.get("is_open"),
        vendor.get("open"),
        vendor.get("is_active"),
    )
    if isinstance(is_open, bool):
        is_open_val: bool | None = is_open
    else:
        status = str(vendor.get("status", "")).lower()
        is_open_val = status in {"open", "active", "online"} if status else None

    return {
        "vendor_id": _first(vendor.get("id"), vendor.get("vendor_id")),
        "vendor_code": _first(vendor.get("code"), vendor.get("vendor_code")),
        "vendor_name": _first(
            vendor.get("name"),
            vendor.get("vendor_name"),
            vendor.get("title"),
        ),
        "url_key": _first(vendor.get("url_key"), vendor.get("slug"), vendor.get("key")),
        "rating": rating,
        "review_count": review_count,
        "minimum_order_amount": minimum_order,
        "delivery_fee": delivery_fee,
        "delivery_time": delivery_time,
        "cuisines": cuisines,
        "address": address_text,
        "city": city,
        "latitude": lat,
        "longitude": lon,
        "is_open": is_open_val,
    }


def parse_vendors(payload: dict[str, Any]) -> pd.DataFrame:
    """
    Parse raw vendors JSON into a normalized DataFrame.

    Args:
        payload: Raw API JSON.

    Returns:
        DataFrame with VENDOR_COLUMNS (may be empty if no vendors found).
    """
    vendors = _extract_vendor_list(payload)
    logger.info("Parsing %d vendor record(s) from payload", len(vendors))

    if not vendors:
        logger.warning("No vendor records found in API response")
        return pd.DataFrame(columns=VENDOR_COLUMNS)

    rows = [_parse_vendor_row(v) for v in vendors]
    df = pd.DataFrame(rows)

    for col in VENDOR_COLUMNS:
        if col not in df.columns:
            df[col] = None

    df = df[VENDOR_COLUMNS]
    logger.info("Parsed %d vendor row(s)", len(df))
    return df


def save_json(payload: dict[str, Any], path: Path | None = None) -> Path:
    """
    Save raw API JSON to raw/vendors.json.

    Args:
        payload: API response dict.
        path: Optional override path.

    Returns:
        Path to written file.
    """
    ensure_directories()
    target = (path or RAW_DIR / VENDORS_RAW_JSON).resolve()
    target.parent.mkdir(parents=True, exist_ok=True)

    with target.open("w", encoding="utf-8") as fh:
        json.dump(payload, fh, ensure_ascii=False, indent=2)

    logger.info("Saved raw JSON -> %s", target)
    return target


def save_excel(df: pd.DataFrame, path: Path | None = None) -> Path | None:
    """
    Save vendor DataFrame to output/restaurants.xlsx.

    Returns:
        Output path, or None if DataFrame is empty.
    """
    ensure_directories()
    target = path or OUTPUT_DIR / RESTAURANTS_EXCEL

    if df.empty:
        logger.warning("Skipping Excel export — no vendor rows to write")
        return None

    return save_dataframe_excel(df, target, sheet_name="restaurants")


def run(
    latitude: float | None = None,
    longitude: float | None = None,
) -> tuple[dict[str, Any], pd.DataFrame]:
    """
    Full Phase 1 pipeline: fetch -> save JSON -> parse -> save Excel.

    Returns:
        Tuple of (raw_payload, vendors_dataframe).
    """
    ensure_directories()
    payload = fetch_vendors(latitude=latitude, longitude=longitude)
    save_json(payload)
    df = parse_vendors(payload)
    save_excel(df)
    return payload, df


def main() -> int:
    """CLI entry point."""
    setup_logging()
    try:
        _, df = run()
        print(f"Done. Vendors parsed: {len(df)}")
        print(f"Raw JSON: {RAW_DIR / VENDORS_RAW_JSON}")
        if not df.empty:
            print(f"Excel:    {OUTPUT_DIR / RESTAURANTS_EXCEL}")
        return 0
    except requests.RequestException as exc:
        logger.error("HTTP request failed: %s", exc)
        return 1
    except ValueError as exc:
        logger.error("Invalid API response: %s", exc)
        return 1
    except Exception as exc:
        logger.exception("Vendor scraper failed: %s", exc)
        return 1


if __name__ == "__main__":
    sys.exit(main())
