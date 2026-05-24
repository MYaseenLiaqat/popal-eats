# Backend (FastAPI v3)

## Install

```powershell
cd backend
.\venv\Scripts\activate
pip install -r requirements.txt
```

Optional OCR: `pip install pytesseract` (and install Tesseract binary) or `pip install easyocr`  
Optional NLP: `pip install transformers torch` + set `ENABLE_HF_SENTIMENT=true`

## Environment (`backend/.env`)

```env
DATABASE_URL=postgresql://...
SECRET_KEY=your-secret-key
CORS_ORIGINS=http://localhost:3000,http://127.0.0.1:8000
RATE_LIMIT_DEFAULT=200/minute
LOG_LEVEL=INFO
REDIS_URL=redis://127.0.0.1:6379/0
RQ_QUEUE_NAME=popal_eats
PROCESS_REVIEWS_INLINE=false
REFRESH_TOKEN_EXPIRE_DAYS=7
OCR_ENGINE=mock
```

Set `PROCESS_REVIEWS_INLINE=true` for dev without Redis.

## Migrations

```powershell
alembic upgrade head
# existing DB: python scripts/setup_db.py
```

## Workers (review AI pipeline)

Terminal 1 — API:

```powershell
python -m uvicorn app.main:app --reload --host 127.0.0.1 --port 8000
```

Terminal 2 — Redis + RQ worker:

```powershell
# Start Redis locally, then:
rq worker popal_eats --url redis://127.0.0.1:6379/0
```

## Admin

```powershell
python scripts/seed_admin.py admin@popaleats.com YourPassword123
```

## Validate

```powershell
$env:PYTHONPATH="."
$env:PROCESS_REVIEWS_INLINE="true"
python scripts/validate_api.py
```

## Architecture

| Layer | Path |
|-------|------|
| ReviewProcessingService | `app/services/review_processing/service.py` |
| Review queue | `app/services/review_processing/queue.py` |
| Worker `process_next_review` | `app/workers/tasks.py` |
| NLP / sentiment | `app/services/nlp/` |
| OCR ETL | `app/services/ocr/` |
| Admin APIs | `app/routes/admin/` |
| Refresh tokens | `POST /refresh`, table `refresh_tokens` |

## Validate phase

```powershell
$env:PYTHONPATH="."
$env:PROCESS_REVIEWS_INLINE="true"
python scripts/validate_phase.py
```

If you do not see **Authorize**, hard-refresh the docs page (`Ctrl+F5`) after restarting the server.

## Restaurants, categories & dishes

| Resource | Endpoints |
|----------|-----------|
| Categories | `POST/GET/PUT/DELETE /categories` |
| Restaurants | `POST/GET/PUT/DELETE /restaurants` |
| Dishes | `POST/GET/PUT/DELETE /dishes` |

**Ownership:** creating a restaurant sets you as `owner_id`. Only the owner can update/delete that restaurant and its dishes.

**Swagger flow:** Register → Login → Authorize → `POST /categories` → `POST /restaurants` → `POST /dishes` (use real `restaurant_id` and `category_id` from responses).

## Cart, checkout & orders

| Step | Endpoint |
|------|----------|
| Add to cart | `POST /cart/add` `{ "dish_id": 1, "quantity": 2 }` |
| View cart | `GET /cart` |
| Update qty | `PUT /cart/items/{id}` |
| Remove item | `DELETE /cart/items/{id}` |
| Clear cart | `DELETE /cart/clear` |
| Checkout | `POST /checkout` `{ "delivery_address": "..." }` |
| My orders | `GET /orders/my-orders` |
| Order detail | `GET /orders/{id}` |
| Update status | `PUT /orders/{id}/status` (restaurant owner) |
| Restaurant orders | `GET /restaurants/{id}/orders` (owner) |

**Rules:** All cart items must be from **one restaurant**. Checkout snapshots dish prices into `order_items`. Payment is **mock** (`paid` on checkout).

### Troubleshooting (terminal / Swagger)

| Log / response | Meaning | Fix |
|----------------|---------|-----|
| `(trapped) error reading bcrypt version` | Old passlib+bcrypt clash | Fixed: use `bcrypt==4.0.1` (already in requirements). Restart server. |
| `could not translate host name` (Neon) | No internet / DNS | Connect Wi‑Fi; run `python test_db.py` |
| `POST /dishes` **404** | Wrong `restaurant_id` or `category_id` | Use ids from **POST /categories** and **POST /restaurants** responses |
| `POST /cart/add` **404** | Dish deleted or wrong `dish_id` | **POST /dishes** again; copy new `id` from response |
| `POST /checkout` **400** empty cart | Nothing in cart | **POST /cart/add** succeeded first; **GET /cart** to verify |
| `PUT /cart/items/1` **404** | No cart line with that id | **GET /cart** → use `items[].id` (not `0`) |
| `DELETE /dishes/1` then add dish 1 | Dish gone | Create dish again — new id may differ |

**Do not** run `pip freeze > requirements.txt` in PowerShell (breaks the file on Windows). Use the committed `requirements.txt`.

`.env` must include `SECRET_KEY`, `ALGORITHM`, `ACCESS_TOKEN_EXPIRE_MINUTES`, and `DATABASE_URL`.

If password hashing fails on install, run: `pip install "bcrypt>=4.0.1,<5.0.0"` (passlib compatibility).

**Do not** run `pip freeze > requirements.txt` in PowerShell — it can save UTF-16 and break `pip install -r`. Use the committed `requirements.txt` instead.
