git commit -m "Implemented recommendation engine v1"# Recommendation Engine V1.1

Upgrade from V1 with transparent scoring, accurate budget messaging, tag-based cuisine fallback, and structured explanations.

## Changelog from V1

| Feature | V1 | V1.1 |
|---------|----|------|
| `score_breakdown` in response | No | Yes |
| Explanation format | Short prose | Point-level `"Label (+N)"` list |
| Budget below `budget_min` | Incorrect +10 partial credit | **0 points**, message "Below your budget range" |
| Cuisine sources | Text blob only | **Dish tags → restaurant tags → category → text** |
| `engine_version` in response | No | `"1.1"` |

## Endpoint

| Method | Path | Auth |
|--------|------|------|
| `GET` | `/recommendations` | JWT Bearer |

## Response shape

```json
{
  "items": [
    {
      "dish_id": 12,
      "dish_name": "Chicken Karahi",
      "restaurant_name": "Lahore Kitchen",
      "price": "850.00",
      "calories": 520,
      "recommendation_score": 97.0,
      "score_breakdown": {
        "cuisine_score": 40,
        "nutrition_score": 25,
        "budget_score": 20,
        "rating_score": 12,
        "total_score": 97
      },
      "explanation": "Matched Pakistani cuisine (+40), High Protein goal (+25), Within budget range (+20), Restaurant rating (+12)."
    }
  ],
  "count": 1,
  "engine_version": "1.1"
}
```

## Scoring (unchanged weights)

| Component | Max | Rules |
|-----------|-----|--------|
| Cuisine | 40 | See cuisine fallback chain below |
| Nutrition | 25 | Same goal rules as V1 |
| Budget | 20 | See budget states below |
| Rating | 15 | `(average_rating / 5) × 15` |

## Cuisine fallback chain (V1.1)

For each `favorite_cuisines` entry (lowercase), the engine checks in order:

1. **`dishes.tags`** (JSON array) — substring match on each tag
2. **`restaurants.tags`** (JSON array)
3. **`categories.name`** — category name contains cuisine or vice versa
4. **Text blob** — dish name, description, restaurant name, description, plus category name

First hit awards **40** points and uses that cuisine in the explanation.

### Tags schema (migration `005_tags`)

```sql
-- restaurants.tags, dishes.tags — JSON array, default []
["pakistani", "bbq", "halal"]
```

Set tags via SQL or future menu APIs; empty arrays are valid.

## Budget states (V1.1 fix)

| State | Condition | Points | Explanation text |
|-------|-----------|--------|------------------|
| **within** | `budget_min ≤ price ≤ budget_max` (bounds optional) | 20 | `Within budget range (+20)` |
| **below** | `price < budget_min` when min set | 0 | `Below your budget range` (no “fits budget”) |
| **slightly_above** | `price > budget_max` but `≤ budget_max × 1.1` | 10 | `Slightly above budget (+10)` |
| **above** | `price > budget_max × 1.1` | 0 | `Above your budget range` |
| **none** | No budget prefs | 0 | (no budget line) |

**V1 bug fixed:** prices under `budget_min` no longer receive partial credit for being under `budget_max`.

## Explanation format

Built only from **positive** score lines (`+N`), plus **non-scoring** budget warnings when applicable:

```
Matched Pakistani cuisine (+40), High Protein goal (+25), Within budget range (+20), Restaurant rating (+12).
```

Nutrition labels: `High Protein`, `Low Carb`, `Weight Loss`, `Balanced Nutrition`, or title-cased custom goals.

## Prerequisites

1. `alembic upgrade head` (includes `005_tags` for `dishes.tags` / `restaurants.tags`)
2. User preferences via `PUT /users/preferences`
3. Tag dishes/restaurants or use category names that reflect cuisines (e.g. category `"Pakistani"`)

## Example flow

### 1. Login

```bash
curl -s -X POST "http://127.0.0.1:8000/login" \
  -H "Content-Type: application/json" \
  -d '{"email":"you@example.com","password":"YourPassword123"}'
```

### 2. Preferences

```bash
curl -s -X PUT "http://127.0.0.1:8000/users/preferences" \
  -H "Authorization: Bearer TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "favorite_cuisines": ["pakistani"],
    "nutrition_goal": "high_protein",
    "budget_min": 500,
    "budget_max": 2000
  }'
```

### 3. Recommendations

```bash
curl -s "http://127.0.0.1:8000/recommendations" \
  -H "Authorization: Bearer TOKEN"
```

### 4. Tag a dish (SQL example)

```sql
UPDATE dishes SET tags = '["pakistani", "halal", "high-protein"]'::json WHERE id = 12;
UPDATE restaurants SET tags = '["pakistani", "bbq"]'::json WHERE id = 5;
```

## Swagger

`/docs` → **recommendations** → **GET /recommendations** — response schema includes `score_breakdown` and `engine_version`.

## Implementation map

| Layer | Path |
|-------|------|
| Service | `backend/app/services/recommendation_service.py` |
| Schemas | `backend/app/schemas/recommendation.py` |
| Routes | `backend/app/routes/recommendations.py` |
| Tags migration | `backend/alembic/versions/005_dish_restaurant_tags.py` |
| Models | `dishes.tags`, `restaurants.tags` |

## Related docs

- [V1 overview](./recommendation_engine_v1.md)
- [V1 operational audit](./recommendation_v1_audit.md)
- [User preferences](./user_preferences.md)

---

*Engine version: 1.1*
