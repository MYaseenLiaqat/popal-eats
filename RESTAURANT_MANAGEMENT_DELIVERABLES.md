# Restaurant Management Platform — Deliverables

Implementation complete for Phases 1–7. Migration `015_restaurant_management` applied.

---

## Phase 1 — Audit

See [`RESTAURANT_MANAGEMENT_AUDIT.md`](RESTAURANT_MANAGEMENT_AUDIT.md) for the pre-implementation audit (already / partial / missing).

---

## 1. Files created

### Backend
| File | Purpose |
|------|---------|
| `backend/alembic/versions/015_restaurant_management.py` | DB migration: approval workflow + dish nutrition/allergens |
| `backend/app/core/restaurant_constants.py` | `pending`/`approved`/`rejected`, allergen tags, user-allergy mapping |
| `backend/app/services/restaurant_dashboard_service.py` | Dashboard metrics aggregation |
| `backend/app/routes/admin/restaurants.py` | Admin restaurant list + approval |

### Frontend
| File | Purpose |
|------|---------|
| `frontend/lib/models/restaurant_dashboard.dart` | Dashboard API model |
| `frontend/lib/utils/dish_allergens.dart` | Allergen labels + validation |
| `frontend/lib/utils/app_roles.dart` | Role helpers (`restaurant_owner`, `admin`) |
| `frontend/lib/services/restaurant_owner_service.dart` | Owner CRUD, dashboard, image upload |
| `frontend/lib/screens/restaurant_dashboard_screen.dart` | Owner dashboard UI |
| `frontend/lib/screens/owner_dishes_screen.dart` | Dish list for owners |
| `frontend/lib/screens/owner_dish_form_screen.dart` | Create/edit dish with nutrition + allergens |
| `frontend/lib/screens/restaurant_register_screen.dart` | Register restaurant (starts as pending) |
| `frontend/lib/screens/admin_restaurant_approvals_screen.dart` | Admin approve/reject UI |

---

## 2. Files modified

### Backend
| File | Change |
|------|--------|
| `backend/app/models/restaurant.py` | `approval_status`, `rejection_reason` |
| `backend/app/models/dish.py` | `cuisine`, fiber/sugar/sodium, `ingredients`, `allergens`, `images` |
| `backend/app/schemas/restaurant.py` | Approval fields, dashboard + approval update schemas |
| `backend/app/schemas/dish.py` | Full nutrition, ingredients, allergens validation |
| `backend/app/routes/restaurant.py` | Approval on create, public filter, `/mine`, `/dashboard` |
| `backend/app/routes/dish.py` | Approved-restaurant gate, owner bypass, `POST /{id}/image` |
| `backend/app/routes/admin/__init__.py` | Mount restaurants admin router |
| `backend/app/core/dependencies.py` | `get_optional_current_user` for public + owner override |
| `backend/app/main.py` | Static mount `/uploads` for dish images |
| `backend/app/services/foodpanda_import_service.py` | Imported restaurants default `approved` |
| `backend/app/services/recommendation/v2_candidates.py` | Only approved restaurants in candidate pool |
| `backend/app/services/group_recommendation/filters.py` | Structured `dish.allergens` before text heuristics |

### Frontend
| File | Change |
|------|--------|
| `frontend/lib/models/dish.dart` | Extended fields + `toWriteJson()` |
| `frontend/lib/models/restaurant.dart` | `approvalStatus`, `rejectionReason` |
| `frontend/lib/services/admin_service.dart` | Restaurant approval APIs |
| `frontend/lib/services/api_client.dart` | `patch()` helper |
| `frontend/lib/screens/profile_screen.dart` | Business + Admin nav sections |
| `frontend/lib/screens/admin_dashboard_screen.dart` | Pending approvals banner |
| `frontend/pubspec.yaml` | `file_picker` for dish image upload |

---

## 3. Database changes (migration 015)

**`restaurants`**
- `approval_status` VARCHAR(20) NOT NULL, default `approved` (existing rows stay visible)
- `rejection_reason` TEXT nullable
- Index `ix_restaurants_approval_status`

**`dishes`**
- `cuisine` VARCHAR(100)
- `fiber`, `sugar`, `sodium` NUMERIC(8,2)
- `ingredients` JSON (list of strings)
- `allergens` JSON (list of tags: peanut, dairy, gluten, soy, egg, shellfish, tree_nut)
- `images` JSON (additional image URLs; primary remains `image_url`)

Run: `cd backend && alembic upgrade head`

---

## 4. APIs added / extended

| Method | Path | Description |
|--------|------|-------------|
| GET | `/restaurants/mine` | Owner's restaurants (any approval status) |
| GET | `/restaurants/{id}/dashboard` | Metrics: dishes, rating, reviews, orders, popular dishes |
| PATCH | `/admin/restaurants/{id}/approval` | Admin approve/reject with optional reason |
| GET | `/admin/restaurants` | List restaurants (filter by status) |
| GET | `/admin/restaurants/pending/count` | Pending count for admin banner |
| POST | `/dishes/{id}/image` | Multipart dish image upload → `/uploads/dishes/...` |

**Behavior changes (existing routes)**
- `POST /restaurants` — owners create as `pending`; admin creates as `approved`; auto-promotes customer → `restaurant_owner`
- `GET /restaurants`, `GET /restaurants/{id}` — public sees `approved` only; owner/admin see own pending
- `GET /dishes`, `GET /dishes/{id}` — same approval gate; owner bypass for own restaurant dishes
- Foodpanda import unchanged; imported restaurants set `approval_status=approved`

---

## 5. Flutter screens added

| Screen | Entry |
|--------|-------|
| `RestaurantRegisterScreen` | Profile → Register Restaurant |
| `RestaurantDashboardScreen` | Profile → Restaurant Dashboard |
| `OwnerDishesScreen` | Dashboard → Manage Dishes |
| `OwnerDishFormScreen` | Create / Edit dish |
| `AdminRestaurantApprovalsScreen` | Profile → Restaurant Approvals (admin) |

---

## 6. Navigation changes

**Profile tab** (role-based, no change to Home/Discover/Community tabs):

- **Business** (role `restaurant_owner` or `admin`):
  - Restaurant Dashboard → pick restaurant → stats + manage dishes
  - Register Restaurant (if no restaurant yet)
- **Admin** (role `admin`):
  - Admin Dashboard (existing analytics)
  - Restaurant Approvals (new)

Consumer user flows (home feed, recommendations, cart, groups) unchanged.

---

## 7. Recommendation integration points

| Location | Integration |
|----------|-------------|
| `backend/app/services/recommendation/v2_candidates.py` | `load_eligible_dishes()` and `is_eligible_dish()` require `restaurant.approval_status == approved` |
| `backend/app/services/group_recommendation/filters.py` | `_dish_allergen_tags()` checks structured JSON allergens; maps user allergies via `USER_ALLERGY_TO_DISH_TAG`; falls back to legacy text heuristics when tags absent |
| `backend/app/routes/dish.py` | Public dish list excludes dishes from non-approved restaurants |

**Verified:** Pending restaurants' dishes do not appear in recommendation candidates. Foodpanda-imported dishes (approved) continue to appear. Flutter tests: 18/18 pass.

---

## 8. Remaining work

| Item | Priority | Notes |
|------|----------|-------|
| Menu upload UI | Low | `menu_upload_screen.dart` still placeholder; backend `POST /menu/upload` works via `MenuService` |
| Restaurant logo upload | Low | URL field only; dish image upload implemented |
| Per-restaurant categories | Low | Categories remain global shared list |
| Personal reco allergy filter | Medium | Group reco uses structured allergens; personal V2 may still rely on preference heuristics for dishes without tags |
| Image URL base on mobile | Medium | Uploaded paths are `/uploads/...`; ensure `ApiClient.baseUrl` prefixes in dish display |
| E2E owner flow script | Low | Manual demo: register restaurant → admin approve → add dish → verify in recommendations |
| Restart backend after deploy | Required | Load new routes + static files mount |

---

## Demo flow (evaluators)

1. Sign up / log in as customer → Profile → **Register Restaurant** (status: Pending).
2. Log in as admin → Profile → **Restaurant Approvals** → Approve.
3. Owner → **Restaurant Dashboard** → **Manage Dishes** → create dish with nutrition + allergen tags + image.
4. Consumer → Discover / recommendations → new dish appears after approval.
5. Group with peanut allergy → dish tagged `peanut` excluded from group recommendations.

Foodpanda import path unchanged; owner-created and imported dishes coexist in the same tables.
