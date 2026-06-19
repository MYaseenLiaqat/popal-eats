# Restaurant Management — Phase 1 Audit

Based on inspection of `backend/` and `frontend/` as of this implementation pass.

## 1. Already implemented

| Area | Evidence |
|------|----------|
| **Restaurant model** | `backend/app/models/restaurant.py` — owner_id, name, address, city, hours, rating, Foodpanda source fields |
| **Dish model** | `backend/app/models/dish.py` — restaurant/category FK, price, basic nutrition (calories, protein, carbs, fats), image URL, is_available |
| **Category model** | `backend/app/models/category.py` — global categories |
| **RESTAURANT_OWNER role** | `backend/app/core/roles.py` — `restaurant_owner`; auto-promote on first restaurant create |
| **Restaurant CRUD API** | `POST/GET/PUT/DELETE /restaurants` with owner RBAC |
| **Dish CRUD API** | `POST/GET/PUT/DELETE /dishes` with owner RBAC |
| **Menu OCR upload** | `POST /menu/upload`, `/menu/import`, `/menu/uploads` |
| **Admin analytics** | `GET /admin/analytics/overview` |
| **Admin users/reviews/menu** | `backend/app/routes/admin/*` |
| **Order listing for owners** | `GET /restaurants/{id}/orders` |
| **Recommendation candidates** | `load_eligible_dishes()` filters availability + open restaurant |
| **Group allergy filter** | Text/tag heuristics in `group_recommendation/filters.py` |
| **Flutter dish detail** | Consumer read-only dish view + cart |
| **Flutter admin dashboard** | Analytics overview (orphan screen) |
| **Flutter menu upload** | Stub screen; `MenuService` has multipart import |

## 2. Partially implemented

| Area | Gap |
|------|-----|
| **Restaurant owner UI** | Backend CRUD exists; no owner dashboard or dish management screens in Flutter |
| **Admin dashboard** | Analytics only; no restaurant approval, no links from app nav |
| **Menu upload UI** | Service ready; screen is placeholder text |
| **Dish nutrition** | calories/protein/carbs/fats only — no fiber, sugar, sodium, ingredients, allergens |
| **Dish images** | URL field only; no upload endpoint for dish photos |
| **Categories** | Global shared list; works but not per-restaurant |
| **Allergy filtering** | Heuristic name/tag search; no structured dish allergen tags |

## 3. Missing (before this pass)

| Area | Required for evaluators |
|------|-------------------------|
| **Approval workflow** | pending / approved / rejected before public visibility |
| **Owner dashboard** | dish count, ratings, reviews, popular dishes, orders |
| **Owner dish management UI** | create / edit / delete with full fields |
| **Structured allergens** | peanut, dairy, gluten, soy, egg, shellfish, tree nut |
| **Ingredients list** | per dish |
| **Dish image upload** | file upload, not URL-only |
| **Admin restaurant moderation** | approve/reject pending restaurants |
| **Navigation to owner/admin tools** | role-based entry from Profile |
| **Recommendation visibility gate** | owner dishes hidden until restaurant approved |

---

*Implementation in this pass addresses items listed under §3 Missing.*
