# Recommendation Engine V1

Rule-based personalized dish rankings using the authenticated user’s **User Preferences** profile and live menu data.

## Endpoint

| Method | Path | Auth |
|--------|------|------|
| `GET` | `/recommendations` | JWT Bearer (required) |

**Swagger:** Open `/docs` → tag **recommendations** → authorize with login token → **GET /recommendations**.

## Prerequisites

1. User registered and logged in (`POST /login`).
2. Preferences set (recommended): `PUT /users/preferences`
3. Dishes and restaurants in the database (`is_available=true`, `is_open=true`).

## Scoring model (max 100 points)

| Component | Max points | Rule |
|-----------|------------|------|
| **Cuisine match** | 40 | Any `favorite_cuisines` tag appears in dish name, description, category name, restaurant name, or restaurant description (case-insensitive). |
| **Nutrition match** | 25 | Dish macros vs `nutrition_goal` (see table below). |
| **Budget match** | 20 | `price` within `budget_min` and `budget_max` (either bound optional). Partial credit if slightly above max (≤110%). |
| **Restaurant rating** | 15 | `(average_rating / 5) × 15` |

Results are sorted by **total score** descending; **top 10** dishes returned.

### Nutrition goals

| `nutrition_goal` values (examples) | Match criteria |
|-----------------------------------|----------------|
| `muscle_gain`, `high_protein`, `high-protein` | `protein ≥ 20g` (full); `≥ 12g` (partial) |
| `low_carb`, `low-carb`, `keto` | `carbs ≤ 25g` (full); `≤ 40g` (partial) |
| `weight_loss`, `weight-loss` | `calories ≤ 450` (full); `≤ 600` (partial) |
| `balanced`, `maintain` | `calories` between 300–750 (full); macros present (partial) |

If nutrition data is missing on a dish, that component scores **0** for strict goals.

## Response shape

```json
{
  "items": [
    {
      "dish_id": 3,
      "dish_name": "Chicken Tikka Bowl",
      "restaurant_name": "Lahore Spice House",
      "price": "850.00",
      "calories": 520,
      "recommendation_score": 72.5,
      "explanation": "Matches your cuisine preferences and high-protein goal."
    }
  ],
  "count": 1
}
```

### Fields

| Field | Description |
|-------|-------------|
| `dish_id` | Dish ID |
| `dish_name` | Menu item name |
| `restaurant_name` | Parent restaurant |
| `price` | Current list price |
| `calories` | Per serving (nullable) |
| `recommendation_score` | Sum of weighted components (0–100) |
| `explanation` | Short human-readable reason |

## Example flow

### 1. Login

```bash
curl -s -X POST "http://127.0.0.1:8000/login" \
  -H "Content-Type: application/json" \
  -d '{"email":"customer@example.com","password":"YourPassword123"}'
```

### 2. Set preferences

```bash
curl -s -X PUT "http://127.0.0.1:8000/users/preferences" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "favorite_cuisines": ["pakistani", "bbq"],
    "nutrition_goal": "high_protein",
    "budget_min": 400,
    "budget_max": 1500
  }'
```

### 3. Get recommendations

```bash
curl -s "http://127.0.0.1:8000/recommendations" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

## PowerShell

```powershell
$base = "http://127.0.0.1:8000"
$login = Invoke-RestMethod -Method Post -Uri "$base/login" -ContentType "application/json" `
  -Body '{"email":"customer@example.com","password":"YourPassword123"}'
$h = @{ Authorization = "Bearer $($login.access_token)" }

Invoke-RestMethod -Uri "$base/recommendations" -Headers $h | ConvertTo-Json -Depth 5
```

## Implementation

| Layer | Path |
|-------|------|
| Service | `backend/app/services/recommendation_service.py` |
| Schemas | `backend/app/schemas/recommendation.py` |
| Routes | `backend/app/routes/recommendations.py` |

Preferences are loaded via `user_preference_service.get_or_create_preferences`.

## Limitations (V1)

- **Content-based rules only** — no collaborative filtering or ML embeddings.
- **Cuisine** inferred from text fields (no dedicated `cuisine` column on restaurants).
- **No dish-level reviews** — restaurant `average_rating` only.
- **No dietary_preference** scoring yet (field stored but not used in V1 weights).
- Empty preferences → recommendations driven mainly by **restaurant rating** and availability.

## Related docs

- [User preferences API](./user_preferences.md)
- [Recommendation audit (pre-V1)](./recommendation_audit.md)

---

*Engine version: V1 — weighted rule-based scorer.*
