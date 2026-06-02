# Recommendation Engine V1 — Operational Audit

**Date:** 2026-06-01  
**Scope:** Explain real scores returned by `GET /recommendations`, using live PostgreSQL sample data and `recommendation_service.py` logic.  
**Constraint:** Read-only analysis; no code changes.

---

## Executive summary

On the current development database, **every recommendation returned `recommendation_score: 10.0`** with explanation **"Fits your budget."** No dish scored above 10.

| Component | Max | Typical value in sample | Contributing? |
|-----------|-----|-------------------------|---------------|
| Cuisine | 40 | 0 | **No** |
| Nutrition | 25 | 0 | **No** |
| Budget | 20 | **10** (half credit) | **Partial only** |
| Restaurant rating | 15 | 0 | **No** |
| **Total** | 100 | **10** | |

Root causes are **data mismatch** (preferences vs menu text/macros), **zero restaurant ratings** on parent restaurants, and a **budget partial-credit rule** that awards 10 points when price is under `budget_max` but **below** `budget_min`.

---

## 1. Actual score calculation (formula)

For each eligible dish, V1 computes:

```
recommendation_score = cuisine_pts + nutrition_pts + budget_pts + rating_pts
```

Rounded to **one decimal** (`round(..., 1)` in `_score_dish`).

### 1.1 Cuisine (max 40)

```text
IF favorite_cuisines is empty → 0
ELSE IF any cuisine tag is a substring of text_blob → 40
ELSE → 0
```

**text_blob** = lowercase concatenation of:

- `dish.name`
- `dish.description`
- `category.name`
- `restaurant.name`
- `restaurant.description`

### 1.2 Nutrition (max 25)

```text
IF nutrition_goal is null → 0
ELSE evaluate goal-specific rules on dish.protein, dish.carbs, dish.calories
```

For `high_protein` / `muscle_gain` / `high-protein`:

| Condition | Points |
|-----------|--------|
| `protein >= 20` | 25 |
| `protein >= 12` | 15 (60% of 25) |
| Otherwise | 0 |

**Note:** `protein = 0` or `NULL` does not qualify.

### 1.3 Budget (max 20)

```text
IF budget_min AND budget_max both null → 0
min_ok = (budget_min is null) OR (price >= budget_min)
max_ok = (budget_max is null) OR (price <= budget_max)

IF min_ok AND max_ok → 20 (full)
ELIF price <= budget_max * 1.1 → 10 (half)   # does NOT require min_ok
ELSE → 0
```

### 1.4 Restaurant rating (max 15)

```text
rating_pts = (clamp(average_rating, 0, 5) / 5) * 15
```

Uses **`restaurants.average_rating`** (denormalized), not live review joins.

### 1.5 Eligibility filter

Only dishes where:

- `dishes.is_available = true`
- `restaurants.is_open = true`

---

## 2. Live sample data (database inspection)

### 2.1 User preferences (user_id = 2)

| Field | Value |
|-------|--------|
| `favorite_cuisines` | `["pakistani"]` |
| `dietary_preference` | `halal` *(stored, not used in V1 scoring)* |
| `nutrition_goal` | `high_protein` |
| `budget_min` | `500.00` |
| `budget_max` | `2000.00` |

### 2.2 Eligible dishes in pool (3 total)

| dish_id | dish_name | category | restaurant | price | calories | protein | restaurant `average_rating` | `total_reviews` |
|---------|-----------|----------|------------|-------|----------|---------|----------------------------|-----------------|
| 2 | string | Pizza | pizza | 1.00 | 0 | 0.00 | **0.0** | 0 |
| 3 | Test Dish | Cat-69113a | Rest-71a2de | 9.99 | NULL | NULL | **0.0** | 1 |
| 4 | Test Dish | Cat-3634f3 | Rest-52f520 | 9.99 | NULL | NULL | **0.0** | 1 |

### 2.3 Categories in database

`Pizza`, `string`, `Cat-69113a`, `Cat-3634f3`, `DevCat-a581` — **none contain `pakistani`**.

### 2.4 Restaurants with high rating but no dishes in pool

| restaurant_id | name | average_rating | In recommendation pool? |
|---------------|------|----------------|-------------------------|
| 1 | string | **5.0** | **No** — no available dishes linked / not in filtered set |

The three scored dishes all sit under restaurants with **`average_rating = 0.0`**, so the rating component cannot contribute.

---

## 3. Per-recommendation score breakdown

All three returned items tie at **10.0**; sort order is stable but arbitrary among equals.

---

### Recommendation A — dish_id **2**

**Response fields (typical):**

```json
{
  "dish_id": 2,
  "dish_name": "string",
  "restaurant_name": "pizza",
  "price": "1.00",
  "calories": 0,
  "recommendation_score": 10.0,
  "explanation": "Fits your budget."
}
```

#### Score calculation

| Component | Calculation | Points |
|-----------|-------------|--------|
| Cuisine | text_blob = `"string string pizza pizza string"`. Is `"pakistani"` a substring? **No** | **0** |
| Nutrition | Goal `high_protein`. `protein = 0.00` → not ≥ 20 or ≥ 12 | **0** |
| Budget | `price = 1.00`, `budget_min = 500`, `budget_max = 2000` | |
| | `min_ok`: 1.00 ≥ 500 → **False** | |
| | `max_ok`: 1.00 ≤ 2000 → **True** | |
| | Full budget (both ok): **False** | |
| | Partial: 1.00 ≤ 2000 × 1.1 → **True** → 20 × 0.5 | **10** |
| Rating | `(0.0 / 5) × 15` | **0** |
| **Total** | 0 + 0 + 10 + 0 | **10.0** |

#### Why total is only 10

Only the **half budget branch** fired. Price is far **below** `budget_min` (500), but the partial rule only checks the **upper** bound, so the dish still receives 10 budget points.

#### Why cuisine does not contribute

User wants **`pakistani`**. Searchable text is Swagger placeholder values (`string`, `pizza`, `Pizza`) — **no lexical overlap**.

#### Why nutrition does not contribute

`high_protein` requires **`protein ≥ 20g`** (or ≥ 12g partial). Dish has **`protein = 0.00`** (and `calories = 0`), so rules fail.

#### Why restaurant rating does not contribute

Parent restaurant **`pizza`** has `average_rating = 0.0` → rating_pts = **0**.

#### Explanation vs score

`budget_ok = True` because partial budget returns `(10, True)`, so the API says **"Fits your budget."** even though price **does not** meet the stated minimum (500).

---

### Recommendation B — dish_id **3**

**Response fields (typical):**

```json
{
  "dish_id": 3,
  "dish_name": "Test Dish",
  "restaurant_name": "Rest-71a2de",
  "price": "9.99",
  "calories": null,
  "recommendation_score": 10.0,
  "explanation": "Fits your budget."
}
```

#### Score calculation

| Component | Calculation | Points |
|-----------|-------------|--------|
| Cuisine | text_blob = `"test dish cat-69113a rest-71a2de"`. **`pakistani`** present? **No** | **0** |
| Nutrition | `protein` / `carbs` / `calories` all **NULL** → cannot satisfy `high_protein` | **0** |
| Budget | 9.99 < 500 → `min_ok` **False**; 9.99 ≤ 2000 → partial branch | **10** |
| Rating | Restaurant rating **0.0** | **0** |
| **Total** | | **10.0** |

Same structural reasons as dish 2 for cuisine, nutrition, and rating. Budget partial again dominates.

**Data note:** `total_reviews = 1` but `average_rating = 0.0` — aggregation may not have run after review, or review pipeline did not update the denormalized field. Either way, V1 reads **0.0**.

---

### Recommendation C — dish_id **4**

**Response fields (typical):**

```json
{
  "dish_id": 4,
  "dish_name": "Test Dish",
  "restaurant_name": "Rest-52f520",
  "price": "9.99",
  "calories": null,
  "recommendation_score": 10.0,
  "explanation": "Fits your budget."
}
```

#### Score calculation

| Component | Points | Reason |
|-----------|--------|--------|
| Cuisine | 0 | blob `"test dish cat-3634f3 rest-52f520"` — no `pakistani` |
| Nutrition | 0 | NULL macros, `high_protein` |
| Budget | 10 | Same partial rule as dish 3 |
| Rating | 0 | `average_rating = 0.0` |
| **Total** | **10.0** | |

---

## 4. Cross-cutting answers

### 4.1 Why is the score only 10?

Because **only one scoring branch awards points** in this dataset:

- **10 points** = 50% budget credit (`SCORE_BUDGET * 0.5`)
- All other components are **0** for every eligible dish

There is no dish with:

- `pakistani` in metadata text (+40)
- `protein ≥ 12` (+15–25)
- price between 500 and 2000 (+20 full budget)
- `average_rating > 0` on the parent restaurant (+1–15)

So the **ceiling for the current pool is 10.0**.

### 4.2 Why cuisine matching is not contributing

| Factor | Detail |
|--------|--------|
| User input | `favorite_cuisines: ["pakistani"]` |
| Matching method | Substring search in dish/category/restaurant **names and descriptions** |
| Actual menu text | Placeholder names: `string`, `Test Dish`, `Pizza`, `pizza`, `Cat-*`, `Rest-*` |
| Result | **Zero substring hits** → 0 / 40 points for all dishes |

**There is no `cuisine` column** on restaurants or dishes; category names do not encode cuisine (e.g. `Pizza` ≠ `pakistani`).

### 4.3 Why nutrition matching is not contributing

| Factor | Detail |
|--------|--------|
| User goal | `high_protein` (valid alias in engine) |
| Required data | `dish.protein` ≥ 20 (full) or ≥ 12 (partial) |
| Actual dishes | `NULL` or `0.00` protein; calories often `NULL` or `0` |
| `dietary_preference` | `halal` is **not referenced** in V1 scorer |
| Result | **0 / 25** for all dishes |

Swagger/API tests often create dishes **without macro fields**, which makes nutrition goals impossible to satisfy.

### 4.4 Why restaurant rating is not contributing

| Factor | Detail |
|--------|--------|
| Formula | `(average_rating / 5) × 15` |
| Parent restaurants of pool dishes | All **`average_rating = 0.0`** |
| High-rated restaurant in DB | `id=1`, rating **5.0**, but **not** parent of any dish in the eligible pool |
| Reviews exist | Some restaurants show `total_reviews = 1` with rating still **0.0** — denormalized field out of sync |
| Result | **0 / 15** for all returned recommendations |

Explanation threshold for “highly rated restaurant” is `rating_pts >= 9` (60% of 15); with 0.0 rating, that text never appears.

---

## 5. Model vs data alignment matrix

| Model field | Used in V1? | Sample data quality | Impact on score |
|-------------|-------------|---------------------|-----------------|
| `user_preferences.favorite_cuisines` | Yes | `pakistani` | No menu text match |
| `user_preferences.nutrition_goal` | Yes | `high_protein` | No protein on dishes |
| `user_preferences.budget_min/max` | Yes | 500–2000 | Prices 1–10 → partial credit only |
| `user_preferences.dietary_preference` | **No** | `halal` | Ignored by engine |
| `dishes.protein/carbs/calories` | Yes | Mostly null/0 | Nutrition blocked |
| `categories.name` | Yes (cuisine text) | Pizza, Cat-* | No cuisine tags |
| `restaurants.average_rating` | Yes | 0.0 on parents | Rating blocked |
| `restaurants.description` | Yes (cuisine text) | Empty or `string` | No signal |

---

## 6. What scores would look like if data aligned

**Hypothetical dish** for user 2:

- Name: `"Pakistani Chicken Karahi"`
- Category: `"Pakistani"`
- Restaurant: `"Lahore Kitchen"`, `average_rating = 4.0`
- Price: `850`, protein: `28`, calories: `600`

| Component | Points |
|-----------|--------|
| Cuisine (`pakistani` in blob) | 40 |
| Nutrition (`high_protein`, protein 28) | 25 |
| Budget (850 in [500, 2000]) | 20 |
| Rating (4/5 × 15) | 12 |
| **Total** | **97.0** |

This illustrates that the engine can score highly **when metadata and preferences align**; the current **10.0** results are a **data + partial-budget artifact**, not a cap in the formula.

---

## 7. Explanation text audit

| Observation | Detail |
|-------------|--------|
| Shown text | `"Fits your budget."` |
| Trigger | `budget_matched=True` from partial 10-point branch |
| Misleading aspect | Price **below** `budget_min` still sets `budget_ok=True` |
| Missing phrases | No cuisine / nutrition / “highly rated” — flags were false |
| Fallback unused | `"Popular dish based on restaurant rating..."` only when **all** flags false; partial budget prevents fallback |

---

## 8. Recommendations for operators (no code changes)

1. **Set preferences that match catalog text** — e.g. `"pizza"` if testing with Pizza category, or tag restaurants/dishes with cuisine words in name/description.
2. **Enter macros** on dishes when using `high_protein` / `low_carb` / `weight_loss`.
3. **Set realistic `budget_min`** (or leave null) — current 500 minimum with $1–$10 test dishes triggers misleading half budget scores.
4. **Ensure `refresh_restaurant_rating`** runs after reviews so `average_rating` reflects stars.
5. **Link highly rated restaurants to dishes** in the pool so rating points can appear.
6. Treat **`dietary_preference`** as informational only until a future engine version uses it.

---

## 9. Reference implementation map

| Item | Location |
|------|----------|
| Scoring logic | `backend/app/services/recommendation_service.py` |
| Endpoint | `GET /recommendations` → `backend/app/routes/recommendations.py` |
| Preferences source | `user_preferences` table / `get_or_create_preferences()` |
| Product doc | `docs/recommendation_engine_v1.md` |
| Pre-V1 gap analysis | `docs/recommendation_audit.md` |

---

## 10. Conclusion

**Recommendation Engine V1 is functioning as coded:** it loads preferences, scores eligible dishes, and returns the top 10. The **10.0** score observed in production-like sample data is explained by:

1. **Budget partial credit (10 pts)** on under-min prices due to the `price <= budget_max * 1.1` branch.
2. **Cuisine (0)** — `pakistani` absent from all searchable dish/restaurant/category strings.
3. **Nutrition (0)** — `high_protein` requires protein data missing on all dishes.
4. **Rating (0)** — parent `average_rating` is 0.0 for every dish in the pool; the one 5-star restaurant has no dishes in the filtered set.

Improving scores requires **better-aligned sample/production data**, not a change to the endpoint contract described in V1 docs.

---

*End of audit.*
