# Foodpanda Menu Endpoint Discovery Report

Generated from `restaurants.xlsx` (first row).

## Test vendor

| Field | Value |
|-------|-------|
| vendor_id | `98218` |
| vendor_code | `szwr` |
| vendor_name | Sweet Creme - Garden East |
| url_key | `sweet-creme-garden-east` |
| restaurant Referer | `https://www.foodpanda.pk/restaurant/szwr/sweet-creme-garden-east` |

**Candidates probed:** 31
**Raw responses:** `raw\menu_discovery/`

## Summary

| Category | Count |
|----------|------:|
| HTTP 200 | 9 |
| Menu-like JSON | 3 |
| JSON (non-menu) | 4 |
| HTML | 6 |
| Errors (non-200 / failed) | 18 |

## Discovered menu API (use for Phase 2 `menu_scraper.py`)

**Endpoint:**

`GET https://pk.fd-api.com/api/v5/vendors/{vendor_code}`

**Required query parameters:**

- `latitude`, `longitude`
- `language_id=1`
- `country=pk`
- `opening_type=delivery`
- `include=menus`

**Required headers (in addition to `BROWSER_HEADERS` / `x-disco-client-id: web`):**

- `perseus-client-id: web`
- `perseus-session-id: <session>` (any non-empty value worked in probe; browser sets real value)
- `Referer: https://www.foodpanda.pk/restaurant/{vendor_code}/{url_key}`

**Path identifier:** use `vendor_code` (e.g. `szwr`), not numeric `vendor_id`.

**Response shape:** `data.menus[].menu_categories[].products[]`

Verified probe results (menu-like JSON):

- **api v5 vendor + include=menus (Perseus) — restaurant MENU**
  - URL: `https://pk.fd-api.com/api/v5/vendors/szwr?latitude=24.8607&longitude=67.0011&language_id=1&country=pk&opening_type=delivery&include=menus`
  - Saved: `api_v5_vendors_szwr.json` (197894 bytes)

- **api v5 vendor + include=menu,products (Perseus)**
  - URL: `https://pk.fd-api.com/api/v5/vendors/szwr?latitude=24.8607&longitude=67.0011&language_id=1&country=pk&opening_type=delivery&include=menu%2Cproducts`
  - Saved: `api_v5_vendors_szwr_3.json` (197894 bytes)

- **api v5 vendor id + include=menus (Perseus)**
  - URL: `https://pk.fd-api.com/api/v5/vendors/98218?latitude=24.8607&longitude=67.0011&language_id=1&country=pk&opening_type=delivery&include=menus`
  - Saved: `api_v5_vendors_98218.json` (197842 bytes)

## HTTP 200 responses

| Status | Class | Menu-like | Length | Description | URL |
|--------|-------|-----------|--------|-------------|-----|
| 200 | menu_json | True | 197894 | api v5 vendor + include=menus (Perseus) — restaurant MENU | `https://pk.fd-api.com/api/v5/vendors/szwr?latitude=24.8607&longitude=67.0011&language_i...` |
| 200 | json | False | 12166 | api v5 vendor detail (Perseus), menus=null without include | `https://pk.fd-api.com/api/v5/vendors/szwr?latitude=24.8607&longitude=67.0011&language_i...` |
| 200 | menu_json | True | 197894 | api v5 vendor + include=menu,products (Perseus) | `https://pk.fd-api.com/api/v5/vendors/szwr?latitude=24.8607&longitude=67.0011&language_i...` |
| 200 | menu_json | True | 197842 | api v5 vendor id + include=menus (Perseus) | `https://pk.fd-api.com/api/v5/vendors/98218?latitude=24.8607&longitude=67.0011&language_...` |
| 200 | json | False | 3559 | pandora vendor by code | `https://pk.fd-api.com/vendors-gateway/api/v1/pandora/vendors/szwr?latitude=24.8607&long...` |
| 200 | json | False | 751178 | pandora vendors list filtered by vendor_id | `https://pk.fd-api.com/vendors-gateway/api/v1/pandora/vendors?latitude=24.8607&longitude...` |
| 200 | json | False | 751213 | pandora vendors list filtered by code | `https://pk.fd-api.com/vendors-gateway/api/v1/pandora/vendors?latitude=24.8607&longitude...` |
| 200 | html | False | 599492 | foodpanda.pk restaurant HTML page | `https://www.foodpanda.pk/restaurant/szwr/sweet-creme-garden-east` |
| 200 | html | False | 599492 | foodpanda.pk (no www) restaurant page | `https://foodpanda.pk/restaurant/szwr/sweet-creme-garden-east` |

## Menu-like JSON (HTTP 200)

| Status | Class | Menu-like | Length | Description | URL |
|--------|-------|-----------|--------|-------------|-----|
| 200 | menu_json | True | 197894 | api v5 vendor + include=menus (Perseus) — restaurant MENU | `https://pk.fd-api.com/api/v5/vendors/szwr?latitude=24.8607&longitude=67.0011&language_i...` |
| 200 | menu_json | True | 197894 | api v5 vendor + include=menu,products (Perseus) | `https://pk.fd-api.com/api/v5/vendors/szwr?latitude=24.8607&longitude=67.0011&language_i...` |
| 200 | menu_json | True | 197842 | api v5 vendor id + include=menus (Perseus) | `https://pk.fd-api.com/api/v5/vendors/98218?latitude=24.8607&longitude=67.0011&language_...` |

## JSON without menu markers (HTTP 200)

| Status | Class | Menu-like | Length | Description | URL |
|--------|-------|-----------|--------|-------------|-----|
| 200 | json | False | 12166 | api v5 vendor detail (Perseus), menus=null without include | `https://pk.fd-api.com/api/v5/vendors/szwr?latitude=24.8607&longitude=67.0011&language_i...` |
| 200 | json | False | 3559 | pandora vendor by code | `https://pk.fd-api.com/vendors-gateway/api/v1/pandora/vendors/szwr?latitude=24.8607&long...` |
| 200 | json | False | 751178 | pandora vendors list filtered by vendor_id | `https://pk.fd-api.com/vendors-gateway/api/v1/pandora/vendors?latitude=24.8607&longitude...` |
| 200 | json | False | 751213 | pandora vendors list filtered by code | `https://pk.fd-api.com/vendors-gateway/api/v1/pandora/vendors?latitude=24.8607&longitude...` |

## HTML responses

| Status | Class | Menu-like | Length | Description | URL |
|--------|-------|-----------|--------|-------------|-----|
| 404 | html | False | 53 | pandora vendor code + /menu | `https://pk.fd-api.com/vendors-gateway/api/v1/pandora/vendors/szwr/menu?latitude=24.8607...` |
| 404 | html | False | 53 | pandora vendor id + /menu | `https://pk.fd-api.com/vendors-gateway/api/v1/pandora/vendors/98218/menu?latitude=24.860...` |
| 404 | html | False | 53 | vendors-gateway v1 code menu | `https://pk.fd-api.com/vendors-gateway/api/v1/vendors/szwr/menu?latitude=24.8607&longitu...` |
| 404 | html | False | 53 | vendors-gateway v1 id menu | `https://pk.fd-api.com/vendors-gateway/api/v1/vendors/98218/menu?latitude=24.8607&longit...` |
| 200 | html | False | 599492 | foodpanda.pk restaurant HTML page | `https://www.foodpanda.pk/restaurant/szwr/sweet-creme-garden-east` |
| 200 | html | False | 599492 | foodpanda.pk (no www) restaurant page | `https://foodpanda.pk/restaurant/szwr/sweet-creme-garden-east` |

## Errors and non-200

| Status | Class | Menu-like | Length | Description | URL |
|--------|-------|-----------|--------|-------------|-----|
| 400 | error | False | 83 | pandora vendor by numeric id | `https://pk.fd-api.com/vendors-gateway/api/v1/pandora/vendors/98218?latitude=24.8607&lon...` |
| 404 | error | False | 264 | menu-gateway code menu | `https://pk.fd-api.com/menu-gateway/api/v1/vendors/szwr/menu?latitude=24.8607&longitude=...` |
| 404 | error | False | 265 | menu-gateway id menu | `https://pk.fd-api.com/menu-gateway/api/v1/vendors/98218/menu?latitude=24.8607&longitude...` |
| 404 | error | False | 272 | menu-gateway pandora code menu | `https://pk.fd-api.com/menu-gateway/api/v1/pandora/vendors/szwr/menu?latitude=24.8607&lo...` |
| 404 | error | False | 273 | menu-gateway pandora id menu | `https://pk.fd-api.com/menu-gateway/api/v1/pandora/vendors/98218/menu?latitude=24.8607&l...` |
| 404 | error | False | 271 | product-gateway code products | `https://pk.fd-api.com/product-gateway/api/v1/vendors/szwr/products?latitude=24.8607&lon...` |
| 404 | error | False | 272 | product-gateway id products | `https://pk.fd-api.com/product-gateway/api/v1/vendors/98218/products?latitude=24.8607&lo...` |
| 404 | error | False | 279 | product-gateway pandora products | `https://pk.fd-api.com/product-gateway/api/v1/pandora/vendors/szwr/products?latitude=24....` |
| 404 | error | False | 267 | catalog-gateway code menu | `https://pk.fd-api.com/catalog-gateway/api/v1/vendors/szwr/menu?latitude=24.8607&longitu...` |
| 404 | error | False | 268 | catalog-gateway id menu | `https://pk.fd-api.com/catalog-gateway/api/v1/vendors/98218/menu?latitude=24.8607&longit...` |
| 400 | error | False | 122 | api v5 include=menus WITHOUT Perseus | `https://pk.fd-api.com/api/v5/vendors/szwr?latitude=24.8607&longitude=67.0011&language_i...` |
| 400 | error | False | 122 | api v5 vendor by code, no Perseus | `https://pk.fd-api.com/api/v5/vendors/szwr?latitude=24.8607&longitude=67.0011&language_i...` |
| 400 | error | False | 122 | api v5 vendor by id, no Perseus | `https://pk.fd-api.com/api/v5/vendors/98218?latitude=24.8607&longitude=67.0011&language_...` |
| 400 | error | False | 122 | api v5 vendor by url_key, no Perseus | `https://pk.fd-api.com/api/v5/vendors/sweet-creme-garden-east?latitude=24.8607&longitude...` |
| 404 | error | False | 172 | api v5 restaurant by url_key | `https://pk.fd-api.com/api/v5/restaurants/sweet-creme-garden-east?latitude=24.8607&longi...` |
| 404 | error | False | 19 | api v5 /menu path (404) | `https://pk.fd-api.com/api/v5/vendors/szwr/menu?latitude=24.8607&longitude=67.0011&langu...` |
| 404 | error | False | 19 | api v5 id /menu path (404) | `https://pk.fd-api.com/api/v5/vendors/98218/menu?latitude=24.8607&longitude=67.0011&lang...` |
| 404 | error | False | 19 | api v5 /products path (404) | `https://pk.fd-api.com/api/v5/vendors/szwr/products?latitude=24.8607&longitude=67.0011&l...` |

## Per-request log

| # | Status | Content-Type | Length | Class | File |
|---|--------|--------------|--------|-------|------|
| 1 | 200 | application/json | 197894 | menu_json | `api_v5_vendors_szwr.json` |
| 2 | 200 | application/json | 12166 | json | `api_v5_vendors_szwr_2.json` |
| 3 | 200 | application/json | 197894 | menu_json | `api_v5_vendors_szwr_3.json` |
| 4 | 200 | application/json | 197842 | menu_json | `api_v5_vendors_98218.json` |
| 5 | 400 | application/json; charset=utf-8 | 83 | error | `vendors-gateway_api_v1_pandora_vendors_98218.json` |
| 6 | 200 | application/json; charset=utf-8 | 3559 | json | `vendors-gateway_api_v1_pandora_vendors_szwr.json` |
| 7 | 404 | text/html; charset=utf-8 | 53 | html | `vendors-gateway_api_v1_pandora_vendors_szwr_menu.html` |
| 8 | 404 | text/html; charset=utf-8 | 53 | html | `vendors-gateway_api_v1_pandora_vendors_98218_menu.html` |
| 9 | 404 | text/html; charset=utf-8 | 53 | html | `vendors-gateway_api_v1_vendors_szwr_menu.html` |
| 10 | 404 | text/html; charset=utf-8 | 53 | html | `vendors-gateway_api_v1_vendors_98218_menu.html` |
| 11 | 200 | application/json; charset=utf-8 | 751178 | json | `vendors-gateway_api_v1_pandora_vendors.json` |
| 12 | 200 | application/json; charset=utf-8 | 751213 | json | `vendors-gateway_api_v1_pandora_vendors_2.json` |
| 13 | 404 | application/json; charset=utf-8 | 264 | error | `menu-gateway_api_v1_vendors_szwr_menu.json` |
| 14 | 404 | application/json; charset=utf-8 | 265 | error | `menu-gateway_api_v1_vendors_98218_menu.json` |
| 15 | 404 | application/json; charset=utf-8 | 272 | error | `menu-gateway_api_v1_pandora_vendors_szwr_menu.json` |
| 16 | 404 | application/json; charset=utf-8 | 273 | error | `menu-gateway_api_v1_pandora_vendors_98218_menu.json` |
| 17 | 404 | application/json; charset=utf-8 | 271 | error | `product-gateway_api_v1_vendors_szwr_products.json` |
| 18 | 404 | application/json; charset=utf-8 | 272 | error | `product-gateway_api_v1_vendors_98218_products.json` |
| 19 | 404 | application/json; charset=utf-8 | 279 | error | `product-gateway_api_v1_pandora_vendors_szwr_products.json` |
| 20 | 404 | application/json; charset=utf-8 | 267 | error | `catalog-gateway_api_v1_vendors_szwr_menu.json` |
| 21 | 404 | application/json; charset=utf-8 | 268 | error | `catalog-gateway_api_v1_vendors_98218_menu.json` |
| 22 | 400 | application/json | 122 | error | `api_v5_vendors_szwr_4.json` |
| 23 | 400 | application/json | 122 | error | `api_v5_vendors_szwr_5.json` |
| 24 | 400 | application/json | 122 | error | `api_v5_vendors_98218_2.json` |
| 25 | 400 | application/json | 122 | error | `api_v5_vendors_sweet-creme-garden-east.json` |
| 26 | 404 | application/json; charset=utf-8 | 172 | error | `api_v5_restaurants_sweet-creme-garden-east.json` |
| 27 | 404 | text/plain; charset=utf-8 | 19 | error | `api_v5_vendors_szwr_menu.txt` |
| 28 | 404 | text/plain; charset=utf-8 | 19 | error | `api_v5_vendors_98218_menu.txt` |
| 29 | 404 | text/plain; charset=utf-8 | 19 | error | `api_v5_vendors_szwr_products.txt` |
| 30 | 200 | text/html | 599492 | html | `www_restaurant_page.html` |
| 31 | 200 | text/html | 599492 | html | `www_restaurant_page_alt.html` |
