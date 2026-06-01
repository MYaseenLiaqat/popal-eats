# Popal Eats — Recommendation Engine Audit Report

**Date:** 2026-05-22  
**Scope:** Backend (`backend/app/`) — ORM models, services, routes, migrations  
**Purpose:** Assess readiness for personalized food recommendations (content-based, collaborative filtering, hybrid)  
**Constraint:** Read-only audit; no code changes were made.

---

## Executive Summary

The Popal Eats backend is a **production-oriented food-delivery API** with strong foundations for **reviews, ratings, nutrition metadata, and order history**, but it does **not implement a recommendation engine**. Project marketing (`README.md`) lists “AI food recommendations” and “group recommendations,” yet the codebase contains **zero** recommendation services, routes, scoring pipelines, or user-preference stores.

| Approach | Current support | Verdict |
|----------|-----------------|--------|
| **Content-based** | Partial raw features (dish nutrition, category, text descriptions, restaurant city/rating) | **Not implemented** — data exists; no similarity or profile matching |
| **Collaborative filtering** | Sparse explicit signals (1 review/user/restaurant); implicit signals possible via orders if tables exist | **Not implemented** — insufficient density and no user–item matrix layer |
| **Hybrid** | Review NLP (sentiment) + aggregates + orders (theoretical) | **Not implemented** — components are siloed |

**Overall maturity:** **Level 0 — Pre-recommendation** (catalog + filters + aggregate ratings only).

---

## Methodology

Inspected:

1. ORM models: `User`, `Restaurant`, `Dish`, `Review`, `Order` (+ `OrderItem`, `Cart`, `CartItem`, `Category`)
2. Alembic migrations (`001`–`003`)
3. Services under `app/services/` (rating, review AI, cart/checkout, OCR, NLP)
4. List/sort APIs on restaurants and dishes
5. Repository-wide search for: `recommend`, `similarity`, `collaborative`, `embedding`, `preference`, `personaliz`

---

## 1. User Model

**File:** `backend/app/models/user.py`  
**Table:** `users`

### Available fields

| Field | Type | Indexed | Notes |
|-------|------|---------|-------|
| `id` | Integer PK | Yes | User identifier for CF matrices |
| `full_name` | String | No | Display only; not used for ML |
| `email` | String(255) | Yes, unique | Identity; no preference linkage |
| `password_hash` | String | No | Auth only |
| `role` | String(32) | Yes | `admin`, `restaurant_owner`, `customer` (RBAC) |
| `profile_image` | String(500) | No | Optional avatar URL |
| `created_at` | DateTime(tz) | No | Tenure / cohort analysis possible |

### Relationships

| Relationship | Target | Cardinality | Relevance to recs |
|--------------|--------|-------------|-------------------|
| `restaurants` | `Restaurant` | 1:N (owner) | Owner context, not consumer taste |
| `reviews` | `Review` | 1:N | Explicit restaurant-level feedback |
| `cart` | `Cart` | 1:1 | Short-term intent signal |
| `orders` | `Order` | 1:N | Strong implicit purchase signal |

### Missing fields for personalized recommendations

| Missing field | Why it matters |
|---------------|----------------|
| `dietary_preferences` (JSON/array) | Vegetarian, halal, allergies — core for content-based filtering |
| `cuisine_preferences` | Taste profile bootstrap |
| `default_delivery_location` / `latitude`, `longitude` | Geo-personalization, “near you” |
| `budget_min`, `budget_max` | Price-aware ranking |
| `language` | UI + review language alignment |
| `last_active_at` | Recency weighting, session models |
| `onboarding_completed` | Cold-start handling |
| `favorite_restaurant_ids` / `favorite_dish_ids` | Explicit positive signals |
| `blocked_restaurant_ids` | Negative filtering |
| `nutrition_goals` (calories, macros targets) | Nutrition-based suggestions (claimed in README) |
| `embedding` / `taste_vector` | Precomputed profile for hybrid serving |

### Assessment

Users are **authentication and RBAC identities** with **no taste profile**. Personalization must be inferred entirely from `reviews`, `orders`, and `cart` — or remain cold-start.

---

## 2. Restaurant Model

**File:** `backend/app/models/restaurant.py`  
**Table:** `restaurants`

### Available fields

| Field | Type | Indexed | Notes |
|-------|------|---------|-------|
| `id` | Integer PK | Yes | Item ID in restaurant-level CF |
| `owner_id` | FK → `users.id` | Yes | Supply-side link |
| `name` | String(200) | Yes | Text feature for content-based |
| `description` | Text | No | Unstructured cuisine/style signal |
| `address` | String(300) | No | Weak geo proxy |
| `city` | String(100) | Yes | Regional filtering (`GET /restaurants?city=`) |
| `phone_number` | String(30) | No | — |
| `image` | String(500) | No | Visual features (not processed) |
| `opening_time`, `closing_time` | Time | No | Time-aware recs possible |
| `is_open` | Boolean | No | Filter in list API |
| `average_rating` | Float | No | **Denormalized** aggregate from reviews |
| `total_reviews` | Integer | No | Popularity / confidence signal |
| `created_at` | DateTime(tz) | No | New-restaurant boost possible |

### Relationships

| Relationship | Target | Notes |
|--------------|--------|-------|
| `owner` | `User` | — |
| `dishes` | `Dish` | Menu catalog |
| `reviews` | `Review` | Training labels for restaurant CF |
| `menu_uploads` | `MenuUpload` | OCR pipeline; not linked to rec engine |
| `orders` | `Order` | Popularity / conversion proxy |

### Missing fields

| Missing field | Why it matters |
|---------------|----------------|
| `cuisine_type` / `tags[]` | Primary content-based facets |
| `latitude`, `longitude` | Distance-based ranking |
| `price_tier` ($–$$$$) | Budget matching |
| `delivery_radius_km` | Feasibility filter |
| `popularity_score` / `order_count_30d` | Trending (beyond review count) |
| `embedding` | Semantic similarity between restaurants |
| `avg_prep_time` | UX ranking factor |

### Existing “soft recommendation” behavior

`GET /restaurants` supports `min_rating`, `city`, `is_open`, `search`, and `sort` by `average_rating`. This is **global catalog ranking**, not **user-specific** recommendation.

---

## 3. Dish Model

**File:** `backend/app/models/dish.py`  
**Table:** `dishes`

### Available fields

| Field | Type | Indexed | Notes |
|-------|------|---------|-------|
| `id` | Integer PK | Yes | Item ID for item-level CF |
| `restaurant_id` | FK | Yes | Single-restaurant cart constraint |
| `category_id` | FK | Yes | **Strong content facet** (Pizza, Burgers, …) |
| `name` | String(200) | Yes | Text similarity |
| `description` | Text | No | NLP feature source |
| `price` | Numeric(10,2) | No | Price filtering in list API |
| `calories` | Integer | No | Nutrition-based content filtering |
| `protein`, `carbs`, `fats` | Numeric | No | Macro-based suggestions |
| `image` | String(500) | No | — |
| `is_available` | Boolean | No | Availability filter |
| `created_at` | DateTime(tz) | No | — |

### Relationships

| Relationship | Target | Notes |
|--------------|--------|-------|
| `restaurant` | `Restaurant` | — |
| `category` | `Category` | Shared taxonomy across restaurants |
| `cart_items` | `CartItem` | Add-to-cart events |
| `order_items` | `OrderItem` | Purchase events (implicit feedback) |

### Missing fields

| Missing field | Why it matters |
|---------------|----------------|
| `tags` (spicy, vegan, gluten-free) | Fine-grained content filters |
| `cuisine` (override category) | Cross-restaurant taste mapping |
| `spice_level`, `allergens[]` | Safety + preference |
| `average_rating`, `order_count` | Item-level popularity (reviews are restaurant-only) |
| `embedding` | Dish–dish similarity |
| `dietary_flags` (boolean) | Fast rule-based filtering |

### Assessment for content-based recs

**Best current asset:** optional nutrition columns + `category_id` + text (`name`, `description`). A basic “dishes under 500 cal in category X under $15” query is **possible with SQL today**; no service exposes it as recommendations.

---

## 4. Review Model

**File:** `backend/app/models/review.py`  
**Table:** `reviews`

### Available fields

| Field | Type | Indexed | Notes |
|-------|------|---------|-------|
| `id` | Integer PK | Yes | — |
| `user_id` | FK | Yes | CF user dimension |
| `restaurant_id` | FK | Yes | CF item dimension (**restaurant**, not dish) |
| `rating` | Integer (1–5) | No | Explicit feedback |
| `comment` | Text | No | Raw text for NLP |
| `detected_language` | String(16) | Yes | AI pipeline output |
| `translated_text` | Text | No | Normalized text for NLP |
| `sentiment` | String(32) | Yes | e.g. positive/negative/neutral |
| `sentiment_score` | Float | No | Confidence/strength |
| `processing_status` | String(32) | Yes | `pending` / `processing` / `completed` / `failed` |
| `processing_error` | Text | No | — |
| `created_at` | DateTime(tz) | No | Temporal weighting |
| `processed_at` | DateTime(tz) | No | — |

### Constraints

- **`UniqueConstraint(user_id, restaurant_id)`** — at most **one review per user per restaurant**.
- No `dish_id` — cannot learn item-level taste from reviews alone.

### Relationships

- `user` ↔ `User.reviews`
- `restaurant` ↔ `Restaurant.reviews`

### Related code (not recommendations)

| Component | Role |
|-----------|------|
| `app/services/rating_service.py` | Recomputes `Restaurant.average_rating` and `total_reviews` |
| `app/services/review_processing/*` | Language detect → translate → sentiment |
| `app/routes/review.py` | CRUD + enqueue AI processing |
| `app/routes/admin/analytics.py` | Global sentiment breakdown (admin only) |

Sentiment is **stored per review** but **never consumed** by ranking or recommendation logic.

### Missing fields

| Missing field | Why it matters |
|---------------|----------------|
| `dish_id` (optional) | Item-level explicit ratings |
| `helpful_count` | Review quality weighting |
| `is_verified_purchase` | Trust signal (link to `orders`) |
| `aspect_ratings` (food, delivery, value) | Multi-facet models |
| `embedding` of comment | Semantic restaurant similarity |

---

## 5. Order Model

**File:** `backend/app/models/order.py`  
**Table:** `orders` (ORM present; **see schema gap below**)

### Available fields

| Field | Type | Indexed | Notes |
|-------|------|---------|-------|
| `id` | Integer PK | Yes | — |
| `user_id` | FK | Yes | CF user key |
| `restaurant_id` | FK | Yes | Implicit restaurant preference |
| `total_price` | Numeric(10,2) | No | Basket value / spend tier |
| `status` | String(30) | Yes | Fulfillment lifecycle |
| `payment_status` | String(30) | No | Mock `paid` on checkout |
| `delivery_address` | String(500) | No | Geo proxy (unparsed text) |
| `rider_name` | String(120) | No | — |
| `created_at` | DateTime(tz) | No | Recency for sequential models |

### Relationships

- `user`, `restaurant`
- `items` → `OrderItem` ( **`dish_id`, `quantity`, snapshot `price`** )

### OrderItem (interaction grain)

**File:** `backend/app/models/order_item.py`

| Field | Relevance |
|-------|-----------|
| `order_id`, `dish_id` | **Core implicit feedback** (purchase) |
| `quantity` | Strength of preference |
| `price` | Historical price at purchase |
| `created_at` | Time decay |

### Cart / CartItem (pre-purchase signals)

| Model | Signal type |
|-------|-------------|
| `Cart` | 1 per user; intent |
| `CartItem` | `dish_id` + `quantity`; abandonment analysis |

### Missing fields

| Missing field | Why it matters |
|---------------|----------------|
| `ordered_at` vs only `created_at` | Fine-grained time-of-day recs |
| `device_type`, `session_id` | Contextual bandits |
| `promo_code`, `discount` | Price sensitivity |
| `delivery_latitude/longitude` | Geo CF |
| `rating_after_delivery` | Post-order explicit signal |
| `repeat_order_flag` | Loyalty / re-order prediction |
| Materialized `user_dish_interaction` | Fast CF training exports |

### Schema / migration gap (critical)

Alembic revisions **`001`–`003` do not create `orders`, `order_items`, `carts`, or `cart_items`**. Models exist in code (merged from order feature branch) but:

- `app/database.py` → `check_database_ready()` imports only a **subset** of models (excludes cart/order).
- Fresh DBs running `alembic upgrade head` may **lack** order tables unless created elsewhere.

**Impact:** Collaborative filtering on purchase history is **blocked** on clean migrations until a `004_orders_and_carts` (or similar) revision exists.

---

## 6. Supporting Models (recommendation context)

### Category (`categories`)

- `name` (unique), `description`, `image`
- Links to many `Dish` — usable as **taxonomy feature** for content-based and demographic priors.

### MenuUpload (`menu_uploads`)

- OCR ingestion pipeline; `extracted_json` could seed dish attributes but is **not normalized into recommendation features**.

### RefreshToken

- Auth only; no recommendation relevance.

---

## 7. Existing Recommendation-Related Code

### Search results

No backend modules named or implementing:

- Recommendation endpoints (`/recommendations`, `/for-you`, etc.)
- Similarity engines (cosine, Jaccard, embeddings)
- Matrix factorization, k-NN, or ML model serving
- User taste profiles or feature stores

### Closest related functionality

| Location | Behavior | Rec classification |
|----------|----------|-------------------|
| `app/routes/restaurant.py` | Filter by `city`, `min_rating`; sort by `average_rating` | **Popularity / filter**, not personalized |
| `app/routes/dish.py` | Filter by `category_id`, price range; sort by `price` | **Catalog search**, not personalized |
| `app/services/rating_service.py` | Aggregate review stars → restaurant | **Feature engineering input**, not recs |
| `app/services/review_processing/*` | Sentiment on comments | **Potential hybrid feature**, unused |
| `app/services/nlp/sentiment_service.py` | HF optional sentiment | Same |
| `app/routes/admin/analytics.py` | Global counts + sentiment breakdown | **Ops analytics**, not user recs |
| `README.md` (root) | Claims AI recommendations | **Aspirational** — not in backend |

### Frontend note

`shared_preferences` in Flutter stores JWT only — **no local recommendation cache or preference store**.

---

## 8. Approach-by-Approach Analysis

### 8.1 Content-based recommendation

**Definition:** Recommend items similar to a user’s stated or inferred preferences, or to items the user liked, based on item attributes.

**What you have today**

| Feature source | Usable attributes |
|----------------|-------------------|
| Dish | `category_id`, `price`, `calories`, macros, `name`, `description`, `is_available` |
| Restaurant | `city`, `description`, `average_rating`, `is_open`, hours |
| Category | `name`, `description` |
| Review NLP | `sentiment`, `sentiment_score`, `translated_text` (restaurant-level) |

**What’s missing**

- User preference vector (diet, allergens, cuisines, budget)
- Structured tags / cuisine on restaurants and dishes
- Text embeddings or TF-IDF index for menu items
- Image features
- API endpoint that accepts user context and returns ranked dishes/restaurants

**Verdict:** **Theoretical foundation only (~25%)**. Raw attributes support **rule-based** suggestions (e.g. “low carb dishes in Lahore”), not a true content-based engine with similarity scoring.

---

### 8.2 Collaborative filtering

**Definition:** Recommend items liked by similar users (user-based) or items similar to those the user consumed (item-based).

**Explicit feedback matrix**

| Dimension | Coverage | Density issue |
|-----------|----------|---------------|
| Users | `users.id` | — |
| Items | `restaurants.id` only | Reviews **not** on dishes |
| Values | `Review.rating` 1–5 | **Max 1 rating per (user, restaurant)** |

**Implicit feedback matrix (stronger for dishes)**

| Event | Source | Field |
|-------|--------|-------|
| Purchase | `order_items` | `user_id` (via order), `dish_id`, `quantity` |
| Cart add | `cart_items` | Partial intent |
| Repeat orders | Derivable from `orders` | Needs SQL aggregation |

**Blockers**

1. **Sparse explicit data** — one review per restaurant caps user-based CF utility.
2. **No dish-level ratings** — item-based CF at dish grain relies on orders only.
3. **No similarity computation or model training pipeline**
4. **Order tables may be absent** on Alembic-only databases
5. **Small user base** (typical early-stage) → cold-start dominates

**Verdict:** **Not supported (~10%)**. Purchase history could power **implicit item-based CF** after schema fix and sufficient order volume; explicit restaurant CF is **too sparse** by design.

---

### 8.3 Hybrid recommendation

**Definition:** Combine content features (nutrition, category, tags) with collaborative signals (orders, reviews) and optionally NLP/semantic features.

**Composable pieces today**

```
┌─────────────────┐     ┌──────────────────┐     ┌─────────────────┐
│  Dish metadata  │     │  Orders/Cart     │     │ Review sentiment │
│  (content)      │     │  (implicit CF)   │     │  (NLP feature)   │
└────────┬────────┘     └────────┬─────────┘     └────────┬────────┘
         │                       │                          │
         └───────────────────────┼──────────────────────────┘
                                 ▼
                    ┌────────────────────────┐
                    │  NO FUSION LAYER       │
                    │  NO SCORING / RANKING  │
                    │  NO /recommend API     │
                    └────────────────────────┘
```

**Verdict:** **Not supported (0% implemented)**. Building blocks exist in **isolated pipelines**; nothing merges them into ranked recommendations per user.

---

## 9. Interaction Data Inventory

| Signal | Granularity | Storage | Used for recs? |
|--------|-------------|---------|----------------|
| Star rating | Restaurant | `reviews.rating` | No (only aggregate) |
| Review text | Restaurant | `reviews.comment` + AI fields | No |
| Purchase | Dish | `order_items` | No |
| Cart add | Dish | `cart_items` | No |
| Search/filter | — | Query params only | No (stateless) |
| View/click | — | **Not tracked** | — |
| Favorites | — | **Not stored** | — |

**Cold-start:** New users have no profile fields; new restaurants/dishes lack popularity counters beyond `average_rating` / `total_reviews` at restaurant level.

---

## 10. API & Infrastructure Gaps

| Gap | Priority |
|-----|----------|
| No `GET /users/me/preferences` or taste profile | High |
| No `GET /recommendations/dishes` or `/restaurants` | High |
| No event logging (`view`, `click`, `add_to_cart`) | High |
| Alembic missing `orders` / `carts` tables | **Critical** for purchase-based CF |
| `check_database_ready()` omits cart/order models | Medium — inconsistent startup checks |
| No feature store / batch export for ML | Medium |
| No vector DB or embedding table | Low (until semantic recs) |
| Redis used for RQ reviews only — not rec cache | Low |

---

## 11. Recommended Roadmap (informational)

Phases are ordered; this audit does not implement them.

### Phase A — Data foundation (prerequisite)

1. Alembic migration for `carts`, `cart_items`, `orders`, `order_items`.
2. Add `user_preferences` table or JSON column on `users`.
3. Add `cuisine_tags` on `restaurants`; `tags` + `dietary_flags` on `dishes`.
4. Optional: `user_events` (`view`, `cart_add`, `order`, `review`) for unified CF.

### Phase B — Baseline non-ML recommendations

1. **Popularity:** trending dishes by `order_items` count (30-day window).
2. **Content rules:** filter by user `nutrition_goals` + dish macros.
3. **Continue eating:** re-order from past `order_items`.
4. Endpoint: `GET /recommendations/home?user_id=…` (authenticated).

### Phase C — Collaborative filtering

1. Build sparse matrix: `user_id × dish_id` with weights (purchase=3, cart=1).
2. Item-based k-NN on co-purchase; fallback to popular in category for cold-start.
3. Restaurant-level CF from `reviews` for “similar restaurants.”

### Phase D — Hybrid + AI

1. Fuse content score + CF score + `sentiment_score` boost/penalty.
2. Optional: embed `Dish.description` + `Review.translated_text` for semantic similarity.
3. Group recommendations: requires `group_id`, shared cart, or household profile — **not in schema**.

---

## 12. Summary Tables

### Model readiness scorecard

| Model | Fields OK for recs | Relationships OK | Missing critical fields | Rec readiness |
|-------|-------------------|------------------|-------------------------|---------------|
| User | Low | Medium | Preferences, geo, taste vector | **Poor** |
| Restaurant | Medium | High | Cuisine, geo, popularity metrics | **Fair** |
| Dish | Medium–High | High | Tags, item rating, embedding | **Good (content)** |
| Review | Medium | High | Dish-level, verified purchase | **Fair (restaurant CF only)** |
| Order | High (implicit) | High | Geo, session, migration gap | **Good if tables exist** |

### System capability matrix

| Capability | Status |
|------------|--------|
| Personalized dish recommendations | ❌ |
| Personalized restaurant recommendations | ❌ |
| Similar dishes (content) | ❌ |
| Similar users (CF) | ❌ |
| Nutrition-based suggestions | ⚠️ Data only |
| Sentiment-aware ranking | ⚠️ Stored, unused |
| Trending / popular | ⚠️ Sort by `average_rating` only |
| Group recommendations | ❌ |
| Explainability (“because you ordered X”) | ❌ |

---

## 13. Conclusion

The Popal Eats backend provides **catalog management**, **denormalized restaurant ratings**, **rich dish nutrition metadata**, **restaurant-level reviews with NLP enrichment**, and **order/cart models suitable for implicit feedback** — but **no recommendation system** is wired up. The product README ahead of the implementation creates a **feature gap**.

**Content-based:** Feasible first step using `category_id`, price, macros, and city — requires user preference storage and ranking API.  
**Collaborative filtering:** Requires order history at scale, dish-level interaction matrix, and fixing migrations; restaurant reviews alone are too sparse.  
**Hybrid:** Natural end-state for this stack (orders + nutrition + sentiment) — **zero implementation today**.

---

## Appendix A — File references

| Asset | Path |
|-------|------|
| User model | `backend/app/models/user.py` |
| Restaurant model | `backend/app/models/restaurant.py` |
| Dish model | `backend/app/models/dish.py` |
| Review model | `backend/app/models/review.py` |
| Order model | `backend/app/models/order.py` |
| OrderItem model | `backend/app/models/order_item.py` |
| Rating aggregation | `backend/app/services/rating_service.py` |
| Review AI pipeline | `backend/app/services/review_processing/` |
| Restaurant list/filters | `backend/app/routes/restaurant.py` |
| Dish list/filters | `backend/app/routes/dish.py` |
| Migrations | `backend/alembic/versions/001_initial_schema.py` … `003_ai_pipeline_and_refresh_tokens.py` |

## Appendix B — Glossary

- **CF:** Collaborative filtering  
- **CB:** Content-based filtering  
- **Cold-start:** New user/item with insufficient interaction history  
- **Implicit feedback:** Behavior-derived signals (orders, views) vs explicit stars

---

*End of audit report.*
