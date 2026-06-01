# User Preferences API

Store per-user taste and budget settings for personalized recommendations (content-based filtering, nutrition rules, and future hybrid models).

## Overview

| Item | Value |
|------|--------|
| Table | `user_preferences` |
| Relationship | One-to-one with `users` (`user_id` unique) |
| Auth | JWT Bearer (same as `/me`, cart, reviews) |
| Tag (Swagger) | `user-preferences` |

## Database schema

| Column | Type | Notes |
|--------|------|--------|
| `id` | Integer PK | Auto |
| `user_id` | Integer FK → `users.id` | Unique, CASCADE delete |
| `favorite_cuisines` | JSON array | e.g. `["italian", "pakistani"]` |
| `dietary_preference` | String(64), nullable | e.g. `vegetarian`, `halal` |
| `nutrition_goal` | String(64), nullable | e.g. `low_carb`, `balanced` |
| `budget_min` | Numeric(10,2), nullable | Minimum spend per order |
| `budget_max` | Numeric(10,2), nullable | Maximum spend per order |
| `created_at` | Timestamptz | Set on create |
| `updated_at` | Timestamptz | Updated on each PUT |

## Migration

From the `backend` directory:

```powershell
cd backend
.\venv\Scripts\activate
alembic upgrade head
```

Revision: `004_user_preferences` (after `003_ai_pipeline`).

## Endpoints

### GET `/users/preferences`

Returns the authenticated user’s preferences. If no row exists yet, an empty profile is created automatically.

**Headers**

```
Authorization: Bearer <access_token>
```

**Response `200`**

```json
{
  "user_id": 1,
  "favorite_cuisines": [],
  "dietary_preference": null,
  "nutrition_goal": null,
  "budget_min": null,
  "budget_max": null,
  "created_at": "2026-05-22T12:00:00Z",
  "updated_at": "2026-05-22T12:00:00Z"
}
```

---

### PUT `/users/preferences`

Partial update: only include fields you want to change.

**Headers**

```
Authorization: Bearer <access_token>
Content-Type: application/json
```

**Request body (example — full update)**

```json
{
  "favorite_cuisines": ["pakistani", "italian", "bbq"],
  "dietary_preference": "halal",
  "nutrition_goal": "low_carb",
  "budget_min": 500.00,
  "budget_max": 2500.00
}
```

**Request body (example — cuisines only)**

```json
{
  "favorite_cuisines": ["chinese", "thai"]
}
```

**Response `200`** — same shape as GET.

**Response `400`** — validation error (e.g. `budget_max` &lt; `budget_min`)

```json
{
  "detail": "budget_max must be greater than or equal to budget_min"
}
```

**Response `401`** — missing or invalid JWT

---

## Swagger / OpenAPI

1. Start the API: `python -m uvicorn app.main:app --reload` (from `backend/`).
2. Open [http://127.0.0.1:8000/docs](http://127.0.0.1:8000/docs).
3. Use **POST /login** to obtain `access_token`.
4. Click **Authorize**, paste the token (no `Bearer` prefix needed in the UI).
5. Expand **user-preferences** → try **GET /users/preferences** and **PUT /users/preferences**.

## cURL examples

### 1. Login

```bash
curl -s -X POST "http://127.0.0.1:8000/login" \
  -H "Content-Type: application/json" \
  -d '{"email":"customer@example.com","password":"YourPassword123"}'
```

Copy `access_token` from the response.

### 2. Get preferences

```bash
curl -s "http://127.0.0.1:8000/users/preferences" \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"
```

### 3. Update preferences

```bash
curl -s -X PUT "http://127.0.0.1:8000/users/preferences" \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "favorite_cuisines": ["pakistani", "bbq"],
    "dietary_preference": "halal",
    "nutrition_goal": "balanced",
    "budget_min": 300,
    "budget_max": 2000
  }'
```

## PowerShell examples

```powershell
$base = "http://127.0.0.1:8000"

# Login
$login = Invoke-RestMethod -Method Post -Uri "$base/login" `
  -ContentType "application/json" `
  -Body '{"email":"customer@example.com","password":"YourPassword123"}'
$token = $login.access_token
$headers = @{ Authorization = "Bearer $token" }

# GET preferences
Invoke-RestMethod -Uri "$base/users/preferences" -Headers $headers

# PUT preferences
$body = @{
  favorite_cuisines = @("italian", "pakistani")
  dietary_preference = "vegetarian"
  nutrition_goal = "weight_loss"
  budget_min = 400
  budget_max = 1800
} | ConvertTo-Json

Invoke-RestMethod -Method Put -Uri "$base/users/preferences" `
  -Headers $headers -ContentType "application/json" -Body $body
```

## Implementation map

| Layer | Path |
|-------|------|
| Model | `backend/app/models/user_preference.py` |
| Schemas | `backend/app/schemas/user_preference.py` |
| Service | `backend/app/services/user_preference_service.py` |
| Routes | `backend/app/routes/user_preferences.py` |
| Migration | `backend/alembic/versions/004_user_preferences.py` |

## Field conventions

- **favorite_cuisines**: lowercased on save; use short tags (`italian`, not `Italian Food`).
- **dietary_preference**: free-form string (64 chars); align with app enums when you add a recommendation engine.
- **nutrition_goal**: free-form string (64 chars); pairs with dish `calories` / macros for rule-based suggestions.
- **budget_min / budget_max**: PKR or your app currency; compare against `Dish.price` and order totals in future recommendation logic.

## Related docs

- [Recommendation engine audit](./recommendation_audit.md) — data gaps this module addresses for content-based and hybrid approaches.
