# Backend (FastAPI)

## Install

From the `backend` folder:

```powershell
python -m venv .venv
.\.venv\Scripts\activate
pip install fastapi uvicorn sqlalchemy psycopg2-binary python-dotenv pydantic
pip install -r requirements.txt
```

(`requirements.txt` matches that set so installs stay reproducible.)

## Configure

Put your Neon (or other Postgres) URL in `backend/.env`:

```env
DATABASE_URL=postgresql://user:pass@host/dbname?sslmode=require
```

`app/config.py` loads this file from the `backend` directory automatically.

## Run the API

Still inside `backend` with the venv activated:

```powershell
python -m uvicorn app.main:app --reload --host 127.0.0.1 --port 8000
```

Then open:

- http://127.0.0.1:8000 — root JSON
- http://127.0.0.1:8000/docs — Swagger UI

Importing `app.database` (e.g. when you add routes that use `get_db`) requires a valid `DATABASE_URL`. The root route in `main.py` does not touch the DB.

## Authentication (JWT)

Endpoints:

- `POST /register` — create account
- `POST /login` — returns `access_token` and `token_type: bearer`
- `GET /me` — current user (requires Bearer token)

Test in Swagger: http://127.0.0.1:8000/docs

### Protected route (`GET /me`)

1. Call `POST /login` and copy `access_token`
2. Click **Authorize** (green **Authorize** button, top right of http://127.0.0.1:8000/docs)
3. Paste the token in the **Value** field (Swagger adds `Bearer` for you)
4. Call `GET /me` — should return your user profile

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
