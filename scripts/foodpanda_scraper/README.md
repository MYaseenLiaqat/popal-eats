# Foodpanda Data Ingestion Pipeline

Scrape real restaurant (vendor) data from the Foodpanda Pakistan API for the **Popal Eats FYP recommendation system**, then load results into PostgreSQL instead of Swagger placeholder rows.

## Project purpose

| Phase | Script | Output |
|-------|--------|--------|
| **1** | `vendor_scraper.py` | `raw/vendors.json`, `output/restaurants.xlsx` |
| **2** | `menu_scraper.py` (TODO) | `raw/menu.json`, `output/dishes.xlsx` |

This pipeline is **standalone** from the FastAPI backend. After scraping, import Excel/JSON into your DB (manual step or future import script).

## Folder structure

```
scripts/foodpanda_scraper/
├── config.py           # API URL, lat/lon, paths, headers
├── vendor_scraper.py   # Phase 1 — restaurant vendors
├── menu_scraper.py     # Phase 2 — placeholder
├── export_excel.py     # Shared Excel helpers
├── requirements.txt
├── README.md
├── raw/                # Raw JSON API responses
└── output/             # Processed Excel files
```

## Setup

```powershell
cd scripts\foodpanda_scraper
python -m venv venv
.\venv\Scripts\activate
pip install -r requirements.txt
```

Optional — set search coordinates (default: Karachi):

```powershell
$env:FOODPANDA_LATITUDE = "24.8607"
$env:FOODPANDA_LONGITUDE = "67.0011"
$env:FOODPANDA_LOG_LEVEL = "DEBUG"
```

Edit `config.py` if you prefer fixed defaults in code.

## Running vendor scraper (Phase 1)

```powershell
cd scripts\foodpanda_scraper
.\venv\Scripts\activate
python vendor_scraper.py
```

### What it does

1. Calls `https://pk.fd-api.com/vendors-gateway/api/v1/pandora/vendors` with **browser-mimic** headers and query params (requires `x-disco-client-id: web`).
2. Saves the full response to **`raw/vendors.json`**.
3. On failure, writes **`raw/error_response.txt`** and **`raw/request_comparison_report.txt`**.
3. Parses vendors into a pandas DataFrame.
4. Writes **`output/restaurants.xlsx`** with columns:

   `vendor_id`, `vendor_code`, `vendor_name`, `url_key`, `rating`, `review_count`, `minimum_order_amount`, `delivery_fee`, `delivery_time`, `cuisines`, `address`, `city`, `latitude`, `longitude`, `is_open`

### Programmatic use

```python
from vendor_scraper import fetch_vendors, parse_vendors, save_json, save_excel, run

payload, df = run(latitude=24.86, longitude=67.00)
```

## Menu endpoint discovery (Phase 2a)

Probe candidate menu APIs for the first restaurant in `restaurants.xlsx`:

```powershell
cd scripts\foodpanda_scraper
$env:FOODPANDA_LOG_LEVEL = "DEBUG"
.\venv\Scripts\python.exe menu_endpoint_discovery.py
```

Outputs:

| Path | Description |
|------|-------------|
| `menu_discovery_report.md` | Summary: HTTP 200, menu JSON, HTML, errors |
| `raw/menu_discovery/` | Saved response body + `*_meta.json` per URL |

**Discovered menu API:** `GET https://pk.fd-api.com/api/v5/vendors/{vendor_code}?…&include=menus` with `perseus-client-id` / `perseus-session-id` headers (see report).

## PostgreSQL import (Phase 3)

Uses `backend/.env` (`DATABASE_URL`) and existing SQLAlchemy models. Run with **backend venv**:

```powershell
cd backend
.\venv\Scripts\pip.exe install openpyxl pandas -q
.\venv\Scripts\python.exe ..\scripts\foodpanda_scraper\import_restaurants.py --dry-run
.\venv\Scripts\python.exe ..\scripts\foodpanda_scraper\import_restaurants.py
.\venv\Scripts\python.exe ..\scripts\foodpanda_scraper\import_dishes.py --dry-run
.\venv\Scripts\python.exe ..\scripts\foodpanda_scraper\import_dishes.py
```

Optional in `backend/.env`: `FOODPANDA_IMPORT_OWNER_ID` or `FOODPANDA_IMPORT_OWNER_EMAIL` (defaults to first `restaurant_owner` or `admin`).

Outputs: `import_report.md`, `output/restaurant_vendor_map.json`.

## Running menu scraper (Phase 2b)

**Not implemented yet.** `menu_scraper.py` defines placeholders:

- `fetch_menu(vendor_id)` — TODO
- `parse_menu(payload)` — TODO
- `save_menu(payload, df)` — TODO

```powershell
python menu_scraper.py
```

Prints next-step instructions only.

## Output files

| File | Description |
|------|-------------|
| `raw/vendors.json` | Unmodified Pandora vendors API response |
| `raw/browser_request_reference.json` | Verified working request template |
| `raw/request_comparison_report.txt` | Legacy vs browser request diff |
| `raw/error_response.txt` | Last non-200 response body (if any) |
| `output/restaurants.xlsx` | Flattened restaurant/vendor table for import |
| `raw/menu.json` | (Future) Raw menu API response |
| `output/dishes.xlsx` | (Future) Menu items per vendor |

## Notes

- Respect Foodpanda terms of service and rate limits; use for academic/FYP purposes.
- API response shape may change; `parse_vendors()` handles several common nested layouts.
- If Excel is empty, check `raw/vendors.json` and logs — coordinates may need adjustment or the API may require extra query parameters.

## Next steps for FYP

1. Run `vendor_scraper.py` and verify `restaurants.xlsx`.
2. Implement Phase 2 menu scraping in `menu_scraper.py`.
3. Build a DB import script mapping Excel rows → `restaurants` and `dishes` tables.
4. Re-run Recommendation Engine V2 — placeholder filter will pass real names.
