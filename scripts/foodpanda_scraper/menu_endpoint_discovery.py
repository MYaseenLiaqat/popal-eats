"""
Foodpanda menu endpoint discovery — Phase 2 diagnostic.

Reads restaurants.xlsx, probes candidate menu API URLs for the first vendor,
saves raw responses under raw/menu_discovery/, and writes menu_discovery_report.md.

Does NOT scrape or parse menus.
"""

from __future__ import annotations

import json
import logging
import re
import time
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any
from urllib.parse import urlencode, urlparse

import pandas as pd
import requests

from config import (
    BROWSER_HEADERS,
    DEFAULT_LATITUDE,
    DEFAULT_LONGITUDE,
    LOG_LEVEL,
    MENU_API_V5_BASE,
    OUTPUT_DIR,
    PERSEUS_HEADERS,
    RAW_DIR,
    REQUEST_TIMEOUT_SECONDS,
    RESTAURANTS_EXCEL,
    SITE_ORIGIN,
)

logger = logging.getLogger(__name__)

MENU_DISCOVERY_DIR: Path = RAW_DIR / "menu_discovery"
REPORT_PATH: Path = Path(__file__).resolve().parent / "menu_discovery_report.md"
REQUEST_DELAY_SECONDS: float = 0.35

# JSON keys that suggest a menu/catalog payload (not exhaustive)
MENU_JSON_MARKERS: tuple[str, ...] = (
    "menu",
    "menus",
    "products",
    "product",
    "categories",
    "menu_categories",
    "menu_category",
    "toppings",
    "variations",
    "menu_items",
    "items",
)


@dataclass
class VendorRow:
    vendor_id: str
    vendor_code: str
    vendor_name: str
    url_key: str


@dataclass
class Candidate:
    slug: str
    url: str
    description: str
    referer: str | None = None
    extra_headers: dict[str, str] = field(default_factory=dict)


@dataclass
class ProbeResult:
    candidate: Candidate
    status_code: int | None
    content_type: str
    response_length: int
    saved_path: Path
    classification: str
    menu_like: bool
    error: str | None = None
    preview: str = ""


def setup_logging(level: str | None = None) -> None:
    logging.basicConfig(
        level=getattr(logging, (level or LOG_LEVEL).upper(), logging.INFO),
        format="%(asctime)s | %(levelname)s | %(name)s | %(message)s",
        datefmt="%Y-%m-%d %H:%M:%S",
    )


def load_first_vendor(excel_path: Path) -> VendorRow:
    if not excel_path.is_file():
        raise FileNotFoundError(
            f"Missing {excel_path}. Run vendor_scraper.py first."
        )
    df = pd.read_excel(excel_path)
    required = {"vendor_id", "vendor_code", "vendor_name", "url_key"}
    missing = required - set(df.columns)
    if missing:
        raise ValueError(f"restaurants.xlsx missing columns: {sorted(missing)}")
    row = df.iloc[0]
    return VendorRow(
        vendor_id=str(row["vendor_id"]).strip(),
        vendor_code=str(row["vendor_code"]).strip(),
        vendor_name=str(row["vendor_name"]).strip(),
        url_key=str(row["url_key"]).strip(),
    )


def _base_query() -> dict[str, Any]:
    return {
        "latitude": DEFAULT_LATITUDE,
        "longitude": DEFAULT_LONGITUDE,
        "language_id": 1,
        "country": "pk",
    }


def _menu_query() -> dict[str, Any]:
    q = _base_query()
    q.update(
        {
            "configuration": "Variant1",
            "dynamic_pricing": 0,
            "customer_type": "regular",
            "include": "menus",
        }
    )
    return q


def _v5_menu_query() -> dict[str, Any]:
    """Query string for restaurant menu on api/v5 (verified Pakistan web app)."""
    return {
        **_base_query(),
        "opening_type": "delivery",
        "include": "menus",
    }


def _qs(params: dict[str, Any]) -> str:
    return urlencode(params, doseq=True)


def restaurant_referer(vendor: VendorRow) -> str:
    return f"{SITE_ORIGIN}/restaurant/{vendor.vendor_code}/{vendor.url_key}"


def build_menu_candidates(vendor: VendorRow) -> list[Candidate]:
    """
    Generate probe URLs from vendor_id, vendor_code, and url_key.

    Patterns follow pk.fd-api.com gateway layout (vendors/menu/product/catalog, api/v5)
    and foodpanda.pk restaurant pages (HTML baseline).
    """
    vid = vendor.vendor_id
    code = vendor.vendor_code
    key = vendor.url_key
    ref = restaurant_referer(vendor)
    bq = _qs(_base_query())
    mq = _qs(_menu_query())
    host = "https://pk.fd-api.com"

    def api(
        url: str,
        desc: str,
        *,
        referer: str | None = ref,
        extra_headers: dict[str, str] | None = None,
    ) -> Candidate:
        return Candidate(
            slug=_slug_from_url(url),
            url=url,
            description=desc,
            referer=referer,
            extra_headers=extra_headers or {},
        )

    v5q = _qs(_v5_menu_query())
    v5_base = _qs({**_base_query(), "opening_type": "delivery"})

    candidates: list[Candidate] = [
        # --- api/v5 (restaurant menu — verified) ---
        api(
            f"{MENU_API_V5_BASE}/vendors/{code}?{v5q}",
            "api v5 vendor + include=menus (Perseus) — restaurant MENU",
            extra_headers=PERSEUS_HEADERS,
        ),
        api(
            f"{MENU_API_V5_BASE}/vendors/{code}?{v5_base}",
            "api v5 vendor detail (Perseus), menus=null without include",
            extra_headers=PERSEUS_HEADERS,
        ),
        api(
            f"{MENU_API_V5_BASE}/vendors/{code}?{_qs({**_v5_menu_query(), 'include': 'menu,products'})}",
            "api v5 vendor + include=menu,products (Perseus)",
            extra_headers=PERSEUS_HEADERS,
        ),
        api(
            f"{MENU_API_V5_BASE}/vendors/{vid}?{v5q}",
            "api v5 vendor id + include=menus (Perseus)",
            extra_headers=PERSEUS_HEADERS,
        ),
        # --- vendors-gateway (same family as listing) ---
        api(f"{host}/vendors-gateway/api/v1/pandora/vendors/{vid}?{bq}", "pandora vendor by numeric id"),
        api(f"{host}/vendors-gateway/api/v1/pandora/vendors/{code}?{bq}", "pandora vendor by code"),
        api(
            f"{host}/vendors-gateway/api/v1/pandora/vendors/{code}/menu?{mq}",
            "pandora vendor code + /menu",
        ),
        api(
            f"{host}/vendors-gateway/api/v1/pandora/vendors/{vid}/menu?{mq}",
            "pandora vendor id + /menu",
        ),
        api(
            f"{host}/vendors-gateway/api/v1/vendors/{code}/menu?{mq}",
            "vendors-gateway v1 code menu",
        ),
        api(
            f"{host}/vendors-gateway/api/v1/vendors/{vid}/menu?{mq}",
            "vendors-gateway v1 id menu",
        ),
        api(
            f"{host}/vendors-gateway/api/v1/pandora/vendors?{_qs({**_base_query(), 'vendor_id': vid})}",
            "pandora vendors list filtered by vendor_id",
        ),
        api(
            f"{host}/vendors-gateway/api/v1/pandora/vendors?{_qs({**_base_query(), 'code': code})}",
            "pandora vendors list filtered by code",
        ),
        # --- menu-gateway ---
        api(f"{host}/menu-gateway/api/v1/vendors/{code}/menu?{mq}", "menu-gateway code menu"),
        api(f"{host}/menu-gateway/api/v1/vendors/{vid}/menu?{mq}", "menu-gateway id menu"),
        api(
            f"{host}/menu-gateway/api/v1/pandora/vendors/{code}/menu?{mq}",
            "menu-gateway pandora code menu",
        ),
        api(
            f"{host}/menu-gateway/api/v1/pandora/vendors/{vid}/menu?{mq}",
            "menu-gateway pandora id menu",
        ),
        # --- product-gateway ---
        api(
            f"{host}/product-gateway/api/v1/vendors/{code}/products?{mq}",
            "product-gateway code products",
        ),
        api(
            f"{host}/product-gateway/api/v1/vendors/{vid}/products?{mq}",
            "product-gateway id products",
        ),
        api(
            f"{host}/product-gateway/api/v1/pandora/vendors/{code}/products?{mq}",
            "product-gateway pandora products",
        ),
        # --- catalog-gateway ---
        api(
            f"{host}/catalog-gateway/api/v1/vendors/{code}/menu?{mq}",
            "catalog-gateway code menu",
        ),
        api(
            f"{host}/catalog-gateway/api/v1/vendors/{vid}/menu?{mq}",
            "catalog-gateway id menu",
        ),
        # --- api/v5 without Perseus (expect 400) ---
        api(f"{host}/api/v5/vendors/{code}?{v5q}", "api v5 include=menus WITHOUT Perseus"),
        api(f"{host}/api/v5/vendors/{code}?{bq}", "api v5 vendor by code, no Perseus"),
        api(f"{host}/api/v5/vendors/{vid}?{bq}", "api v5 vendor by id, no Perseus"),
        api(f"{host}/api/v5/vendors/{key}?{bq}", "api v5 vendor by url_key, no Perseus"),
        api(f"{host}/api/v5/restaurants/{key}?{bq}", "api v5 restaurant by url_key"),
        api(f"{host}/api/v5/vendors/{code}/menu?{mq}", "api v5 /menu path (404)"),
        api(f"{host}/api/v5/vendors/{vid}/menu?{mq}", "api v5 id /menu path (404)"),
        api(
            f"{host}/api/v5/vendors/{code}/products?{mq}",
            "api v5 /products path (404)",
        ),
        # --- www (HTML restaurant page — not API) ---
        Candidate(
            slug="www_restaurant_page",
            url=f"{SITE_ORIGIN}/restaurant/{code}/{key}",
            description="foodpanda.pk restaurant HTML page",
            referer=ref,
        ),
        Candidate(
            slug="www_restaurant_page_alt",
            url=f"https://foodpanda.pk/restaurant/{code}/{key}",
            description="foodpanda.pk (no www) restaurant page",
            referer=ref,
        ),
    ]
    return candidates


def _slug_from_url(url: str) -> str:
    path = urlparse(url).path.strip("/").replace("/", "_") or "root"
    path = re.sub(r"[^\w\-]+", "_", path)[:80]
    return path


def _unique_slug(base: str, used: set[str]) -> str:
    slug = base
    n = 2
    while slug in used:
        slug = f"{base}_{n}"
        n += 1
    used.add(slug)
    return slug


def _headers_for(candidate: Candidate) -> dict[str, str]:
    headers = dict(BROWSER_HEADERS)
    if candidate.referer:
        headers["Referer"] = candidate.referer
    headers.update(candidate.extra_headers)
    return headers


def _walk_json_keys(obj: Any, found: set[str], depth: int = 0) -> None:
    if depth > 8:
        return
    if isinstance(obj, dict):
        for k, v in obj.items():
            if isinstance(k, str) and k.lower() in MENU_JSON_MARKERS:
                found.add(k.lower())
            _walk_json_keys(v, found, depth + 1)
    elif isinstance(obj, list) and obj:
        _walk_json_keys(obj[0], found, depth + 1)


def classify_body(
    status_code: int | None,
    content_type: str,
    body: bytes,
) -> tuple[str, bool, str]:
    """Return (classification, menu_like, preview)."""
    text = body.decode("utf-8", errors="replace")
    preview = text[:500]
    ct = (content_type or "").lower()

    if status_code is None:
        return "error", False, preview

    if "text/html" in ct or text.lstrip().startswith("<!DOCTYPE") or text.lstrip().startswith("<html"):
        return "html", False, preview

    if status_code != 200:
        return "error", False, preview

    if "json" not in ct and not text.lstrip().startswith(("{", "[")):
        return "other", False, preview

    try:
        parsed = json.loads(text)
    except json.JSONDecodeError:
        return "other", False, preview

    if _has_restaurant_menu(parsed):
        return "menu_json", True, preview

    markers: set[str] = set()
    _walk_json_keys(parsed, markers)
    if markers and _has_product_shapes(parsed):
        return "menu_json", True, preview

    return "json", False, preview


def _has_restaurant_menu(parsed: Any) -> bool:
    """True when payload has data.menus[].menu_categories[].products (api/v5 shape)."""
    if not isinstance(parsed, dict):
        return False
    data = parsed.get("data")
    if not isinstance(data, dict):
        return False
    menus = data.get("menus")
    if not isinstance(menus, list) or not menus:
        return False
    for menu in menus:
        if not isinstance(menu, dict):
            continue
        categories = menu.get("menu_categories")
        if not isinstance(categories, list):
            continue
        for category in categories:
            if not isinstance(category, dict):
                continue
            products = category.get("products")
            if isinstance(products, list) and products:
                return True
    return False


def _count_menu_products(parsed: Any) -> int:
    if not isinstance(parsed, dict):
        return 0
    data = parsed.get("data")
    if not isinstance(data, dict):
        return 0
    total = 0
    menus = data.get("menus")
    if not isinstance(menus, list):
        return 0
    for menu in menus:
        if not isinstance(menu, dict):
            continue
        for category in menu.get("menu_categories") or []:
            if isinstance(category, dict):
                total += len(category.get("products") or [])
    return total


def _has_product_shapes(obj: Any, depth: int = 0) -> bool:
    if depth > 6:
        return False
    if isinstance(obj, dict):
        keys = {str(k).lower() for k in obj}
        if ("name" in keys or "title" in keys) and (
            "price" in keys or "product_price" in keys or "unit_price" in keys
        ):
            return True
        return any(_has_product_shapes(v, depth + 1) for v in obj.values())
    if isinstance(obj, list):
        return any(_has_product_shapes(item, depth + 1) for item in obj[:5])
    return False


def probe_candidate(
    candidate: Candidate,
    save_dir: Path,
    slug: str,
) -> ProbeResult:
    headers = _headers_for(candidate)
    logger.info("GET %s", candidate.url)
    logger.info("  Referer: %s", headers.get("Referer", ""))
    if candidate.extra_headers:
        logger.info("  Extra headers: %s", json.dumps(candidate.extra_headers))

    status_code: int | None = None
    content_type = ""
    body = b""
    error: str | None = None

    try:
        resp = requests.get(
            candidate.url,
            headers=headers,
            timeout=REQUEST_TIMEOUT_SECONDS,
        )
        status_code = resp.status_code
        content_type = resp.headers.get("Content-Type", "")
        body = resp.content
        logger.info(
            "  status=%s content-type=%s length=%s",
            status_code,
            content_type,
            len(body),
        )
    except requests.RequestException as exc:
        error = str(exc)
        logger.warning("  request failed: %s", exc)

    ext = ".json" if "json" in content_type.lower() else ".txt"
    if "html" in content_type.lower():
        ext = ".html"
    save_path = save_dir / f"{slug}{ext}"
    save_path.write_bytes(body)

    meta_path = save_dir / f"{slug}_meta.json"
    classification, menu_like, preview = classify_body(status_code, content_type, body)
    product_count = 0
    if menu_like and body:
        try:
            product_count = _count_menu_products(json.loads(body))
        except json.JSONDecodeError:
            pass
    meta = {
        "url": candidate.url,
        "description": candidate.description,
        "status_code": status_code,
        "content_type": content_type,
        "response_length": len(body),
        "classification": classification,
        "menu_like": menu_like,
        "menu_product_count": product_count,
        "error": error,
        "saved_body": save_path.name,
    }
    meta_path.write_text(json.dumps(meta, indent=2), encoding="utf-8")

    return ProbeResult(
        candidate=candidate,
        status_code=status_code,
        content_type=content_type,
        response_length=len(body),
        saved_path=save_path,
        classification=classification,
        menu_like=menu_like,
        error=error,
        preview=preview,
    )


def write_report(vendor: VendorRow, results: list[ProbeResult], report_path: Path) -> None:
    ok_200 = [r for r in results if r.status_code == 200]
    menu_json = [r for r in results if r.classification == "menu_json"]
    plain_json = [r for r in results if r.classification == "json"]
    html = [r for r in results if r.classification == "html"]
    errors = [r for r in results if r.classification == "error" or r.error]

    lines: list[str] = [
        "# Foodpanda Menu Endpoint Discovery Report",
        "",
        f"Generated from `{RESTAURANTS_EXCEL}` (first row).",
        "",
        "## Test vendor",
        "",
        f"| Field | Value |",
        f"|-------|-------|",
        f"| vendor_id | `{vendor.vendor_id}` |",
        f"| vendor_code | `{vendor.vendor_code}` |",
        f"| vendor_name | {vendor.vendor_name} |",
        f"| url_key | `{vendor.url_key}` |",
        f"| restaurant Referer | `{restaurant_referer(vendor)}` |",
        "",
        f"**Candidates probed:** {len(results)}",
        f"**Raw responses:** `{MENU_DISCOVERY_DIR.relative_to(Path(__file__).resolve().parent)}/`",
        "",
        "## Summary",
        "",
        f"| Category | Count |",
        f"|----------|------:|",
        f"| HTTP 200 | {len(ok_200)} |",
        f"| Menu-like JSON | {len(menu_json)} |",
        f"| JSON (non-menu) | {len(plain_json)} |",
        f"| HTML | {len(html)} |",
        f"| Errors (non-200 / failed) | {len(errors)} |",
        "",
    ]

    lines.extend(
        [
            "## Discovered menu API (use for Phase 2 `menu_scraper.py`)",
            "",
            "**Endpoint:**",
            "",
            f"`GET {MENU_API_V5_BASE}/vendors/{{vendor_code}}`",
            "",
            "**Required query parameters:**",
            "",
            "- `latitude`, `longitude`",
            "- `language_id=1`",
            "- `country=pk`",
            "- `opening_type=delivery`",
            "- `include=menus`",
            "",
            "**Required headers (in addition to `BROWSER_HEADERS` / `x-disco-client-id: web`):**",
            "",
            "- `perseus-client-id: web`",
            "- `perseus-session-id: <session>` (any non-empty value worked in probe; browser sets real value)",
            "- `Referer: https://www.foodpanda.pk/restaurant/{vendor_code}/{url_key}`",
            "",
            "**Path identifier:** use `vendor_code` (e.g. `szwr`), not numeric `vendor_id`.",
            "",
            "**Response shape:** `data.menus[].menu_categories[].products[]`",
            "",
        ]
    )

    if menu_json:
        lines.extend(
            [
                "Verified probe results (menu-like JSON):",
                "",
            ]
        )
        for r in menu_json:
            lines.append(f"- **{r.candidate.description}**")
            lines.append(f"  - URL: `{r.candidate.url}`")
            lines.append(f"  - Saved: `{r.saved_path.name}` ({r.response_length} bytes)")
            lines.append("")
    else:
        lines.append("_No candidate returned menu-like JSON in this run._")
        lines.append("")

    def section(title: str, items: list[ProbeResult]) -> None:
        lines.append(f"## {title}")
        lines.append("")
        if not items:
            lines.append("_None._")
            lines.append("")
            return
        lines.append("| Status | Class | Menu-like | Length | Description | URL |")
        lines.append("|--------|-------|-----------|--------|-------------|-----|")
        for r in items:
            status = r.status_code if r.status_code is not None else "—"
            url = r.candidate.url
            if len(url) > 90:
                url = url[:87] + "..."
            lines.append(
                f"| {status} | {r.classification} | {r.menu_like} | "
                f"{r.response_length} | {r.candidate.description} | `{url}` |"
            )
        lines.append("")

    section("HTTP 200 responses", ok_200)
    section("Menu-like JSON (HTTP 200)", menu_json)
    section("JSON without menu markers (HTTP 200)", plain_json)
    section("HTML responses", html)
    section("Errors and non-200", errors)

    lines.extend(
        [
            "## Per-request log",
            "",
            "| # | Status | Content-Type | Length | Class | File |",
            "|---|--------|--------------|--------|-------|------|",
        ]
    )
    for i, r in enumerate(results, 1):
        ct = (r.content_type or "—")[:40]
        lines.append(
            f"| {i} | {r.status_code} | {ct} | {r.response_length} | "
            f"{r.classification} | `{r.saved_path.name}` |"
        )
    lines.append("")

    report_path.write_text("\n".join(lines), encoding="utf-8")
    logger.info("Wrote report -> %s", report_path)


def print_vendor(vendor: VendorRow) -> None:
    print("First vendor from restaurants.xlsx:")
    print(f"  vendor_id   = {vendor.vendor_id}")
    print(f"  vendor_code = {vendor.vendor_code}")
    print(f"  vendor_name = {vendor.vendor_name}")
    print(f"  url_key     = {vendor.url_key}")


def main() -> int:
    setup_logging()
    excel_path = OUTPUT_DIR / RESTAURANTS_EXCEL
    vendor = load_first_vendor(excel_path)
    print_vendor(vendor)

    candidates = build_menu_candidates(vendor)
    print(f"\nProbing {len(candidates)} candidate endpoint(s)...\n")

    MENU_DISCOVERY_DIR.mkdir(parents=True, exist_ok=True)
    used_slugs: set[str] = set()
    results: list[ProbeResult] = []

    for cand in candidates:
        slug = _unique_slug(cand.slug, used_slugs)
        result = probe_candidate(cand, MENU_DISCOVERY_DIR, slug)
        results.append(result)
        time.sleep(REQUEST_DELAY_SECONDS)

    write_report(vendor, results, REPORT_PATH)
    print(f"\nReport: {REPORT_PATH}")
    print(f"Raw:    {MENU_DISCOVERY_DIR}")
    menu_hits = [r for r in results if r.menu_like and r.status_code == 200]
    if menu_hits:
        print(f"\nMenu-like JSON: {len(menu_hits)} hit(s)")
        for r in menu_hits:
            print(f"  - {r.candidate.url}")
    else:
        print("\nNo menu-like JSON found; see report for HTTP 200 JSON candidates.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
