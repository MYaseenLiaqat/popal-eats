# Phase 13A — Application Setup & Manual QA Preparation

**Date:** 2026-06-28

---

## 1. Backend status — **RUNNING**

| Check | Result |
|-------|--------|
| Server | Listening on `http://0.0.0.0:8000` (PID 6064) |
| Health | `GET /health` → `{"status":"ok","version":"3.0.0"}` |
| Swagger | `GET /docs` → 200 |
| OpenAPI | `GET /openapi.json` → 200 |
| Python venv | Present; `pydantic_settings` imports OK |
| `.env` | Present with `DATABASE_URL`, `SECRET_KEY`, `GOOGLE_CLIENT_ID` |

### Backend blocker (migrations)

`alembic current` fails with:

```
Neon PostgreSQL: Your project has exceeded the data transfer quota.
```

The API is running against an existing connection pool, but **new migration runs may fail** until the Neon plan/quota is resolved or `DATABASE_URL` points to another database.

---

## 2. Web status — **RUNNING**

| Check | Result |
|-------|--------|
| `flutter build web` | **PASS** |
| `flutter run -d chrome --web-port=8082` | **PASS** — debug service connected |
| Port 8080 | Already in use (previous session) |
| Google Maps (web) | **Disabled** — `GOOGLE_MAPS_WEB_API_KEY` not provided (fallback UI active) |
| Google Sign-In (web) | **Hidden** — requires Firebase `FIREBASE_*` dart-defines on web |

---

## 3. Android status — **FAIL (build)**

| Check | Result |
|-------|--------|
| Device detected | **Redmi Note 9S** (`f731c5e1`) |
| `flutter run -d f731c5e1` | **FAIL** — Gradle `assembleDebug` |

**Error:** `:file_picker` compiled against `android-34`; `:flutter_plugin_android_lifecycle` requires `compileSdk 36`.

**Workaround to try:** ensure plugin `compileSdk` override applies, or upgrade `file_picker` further / clean rebuild:

```powershell
cd frontend
flutter clean
flutter pub get
flutter run -d f731c5e1 --dart-define=API_BASE_URL=http://192.168.100.171:8000
```

Use your PC's LAN IP (detected: `192.168.100.171`) — not `127.0.0.1` on a physical phone.

---

## 4. Compilation status — **PASS (Dart)**

| Command | Result |
|---------|--------|
| `flutter pub get` | **PASS** (after fixing `pubspec.yaml` merge conflict) |
| `flutter analyze` | **0 errors**, 1 warning (`unused_import` in `home_chef_shell.dart`), 100 info lints |
| `flutter test` | **18/18 passed** |
| `flutter build web` | **PASS** |

### Startup issue fixed

**`frontend/pubspec.yaml` had unresolved git merge conflict markers** (`<<<<<<<`, `=======`, `>>>>>>>`), which broke all Flutter CLI commands. Resolved to keep:

- `file_picker: ^9.2.1`
- `video_player: ^2.9.2`
- `google_maps_flutter: ^2.12.1`

---

## 5. Startup issues fixed

1. **`pubspec.yaml` merge conflict** — blocked `flutter pub get`, `analyze`, `run`, `build`.

---

## 6. Commands — Backend

```powershell
cd c:\Users\user\OneDrive\Desktop\popaleats\popal-eats\backend
.\venv\Scripts\uvicorn.exe app.main:app --host 0.0.0.0 --port 8000
```

Verify: http://127.0.0.1:8000/health and http://127.0.0.1:8000/docs

---

## 7. Commands — Flutter Web

**Basic (no Maps):**

```powershell
cd c:\Users\user\OneDrive\Desktop\popaleats\popal-eats\frontend
flutter run -d chrome --web-port=8082 --dart-define=API_BASE_URL=http://127.0.0.1:8000
```

**With Google Maps (delivery map on web):**

```powershell
flutter run -d chrome --web-port=8082 `
  --dart-define=API_BASE_URL=http://127.0.0.1:8000 `
  --dart-define=GOOGLE_MAPS_WEB_API_KEY=YOUR_MAPS_JS_API_KEY
```

**With Google Sign-In on web (optional):**

```powershell
flutter run -d chrome --web-port=8082 `
  --dart-define=API_BASE_URL=http://127.0.0.1:8000 `
  --dart-define=FIREBASE_API_KEY=... `
  --dart-define=FIREBASE_APP_ID=... `
  --dart-define=FIREBASE_PROJECT_ID=popal-eats-16b36 `
  --dart-define=GOOGLE_WEB_CLIENT_ID=427158581376-o1jd1m4bem383gkoj7ji22sdnta6o98t.apps.googleusercontent.com
```

---

## 8. Commands — Flutter Mobile

**Emulator:**

```powershell
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000
```

**Physical device (same Wi‑Fi as PC):**

```powershell
flutter run -d f731c5e1 --dart-define=API_BASE_URL=http://192.168.100.171:8000
```

Backend must be started with `--host 0.0.0.0`.

Android Google Sign-In uses embedded `google-services.json` (no dart-defines required on Android).

---

## 9. Test account credentials

Seeded by `backend/scripts/seed_demo_content.py` (password for all: **`Demo1234!`**)

| Role | Email | Password | Notes |
|------|-------|----------|-------|
| Customer | `demo.host@example.com` | `Demo1234!` | Primary demo customer |
| Customer | `demo.friend@example.com` | `Demo1234!` | Friend of demo host |
| Restaurant owner | `demo.owner@example.com` | `Demo1234!` | Owner dashboard |
| Admin | `demo.admin@example.com` | `Demo1234!` | Admin dashboard |

**Home Chef:** No pre-seeded account. Create via **Sign up → Home Chef** role, or register via API with `role: home_chef`. Admin must **approve** the business before full chef features unlock.

**Re-seed demo content:**

```powershell
cd backend
.\venv\Scripts\python.exe scripts\seed_demo_content.py
```

**Create extra admin:**

```powershell
.\venv\Scripts\python.exe scripts\seed_admin.py admin@test.com YourPassword
```

---

## 10. Manual testing checklist

Use **PASS / PARTIAL / FAIL** as you test. Expected behaviour → what to verify → bug indicators.

---

### 1. Customer

#### Signup
- **Expected:** Multi-step signup; customer completes account + optional onboarding.
- **Verify:** New user can register; lands on privacy/location/onboarding gates.
- **Bug:** Validation errors not shown; 409 username conflict with no message; stuck on spinner.

#### Login
- **Expected:** Email/password login with `demo.host@example.com` / `Demo1234!`.
- **Verify:** Reaches main shell after consent + onboarding.
- **Bug:** Raw API error text; infinite loading; 401 with valid credentials.

#### Onboarding
- **Expected:** Cuisine, allergies, budget chips; skippable or completable.
- **Verify:** Preferences saved; Discover reflects choices later.
- **Bug:** Save fails silently; repeats every login.

#### Home feed
- **Expected:** Posts from API; pull-to-refresh.
- **Verify:** Cards show image, caption, like/comment/save actions.
- **Bug:** Empty forever; placeholder only; crash on scroll.

#### Stories
- **Expected:** Story rings on home; tap opens viewer.
- **Verify:** Images load; advance between stories.
- **Bug:** No stories; viewer blank; expired stories shown as active.

#### Reels
- **Expected:** Vertical reels from `/discover/reels` or placeholders.
- **Verify:** Swipe between reels; recipe sheet opens on Recipe action.
- **Bug:** Only placeholders when API has content; sheet empty.

#### Order / Restaurant / Dish
- **Expected:** Browse restaurant → dish detail → add to cart.
- **Verify:** Images, price, nutrition, reviews on detail screens.
- **Bug:** Missing images; cart add fails; wrong restaurant dishes.

#### Cart / Checkout / Delivery
- **Expected:** Cart persists; checkout creates order; delivery screen shows map or fallback.
- **Verify:** Order appears in Orders; delivery map or fallback message on web without Maps key.
- **Bug:** Checkout 400; map blank without explaining missing API key.

#### Community (Friends / Groups / Invitations / Voting / Consensus)
- **Expected:** Friends list; create/join group; invite; vote; view decision.
- **Verify:** `demo.host` and `demo.friend` are friends if seeded.
- **Bug:** Group recommendations timeout; vote not counted; decision screen empty.

#### Profile / Logout
- **Expected:** Profile shows user info; nutrition preferences; logout returns to login.
- **Verify:** Nutrition goal saves; logout clears session.
- **Bug:** Stale user data; logout still authenticated.

#### Google Sign-In visibility
- **Web:** Button hidden without Firebase dart-defines (shows config hint).
- **Android:** Button should appear with embedded Firebase config.
- **Bug:** Button missing on Android; sign-in loop after Google account picker.

---

### 2. Restaurant (Owner)

Login as `demo.owner@example.com` / `Demo1234!`

#### Dashboard
- **Expected:** Metrics, restaurant selector, quick actions.
- **Verify:** Dashboard loads for owned restaurant.
- **Bug:** No restaurants; 403; blank metrics.

#### Orders
- **Expected:** Incoming orders list for restaurant.
- **Verify:** Status filters; order detail opens.
- **Bug:** Empty when orders exist in DB.

#### Menu CRUD
- **Expected:** List dishes with thumbnails; add/edit/delete.
- **Verify:** Changes persist after refresh.
- **Bug:** Image upload fails; delete doesn't remove dish.

#### Content creation
- **Expected:** Restaurant post (promotion/announcement) with image.
- **Verify:** Post appears in feed/reels if applicable.
- **Bug:** Submit fails; image not attached.

#### Stories / Reels
- **Expected:** Owner can contribute content visible in discover.
- **Verify:** Seeded restaurant posts appear in reels when images present.
- **Bug:** Posts without thumbnails excluded from reels.

#### Analytics
- **Expected:** Restaurant analytics screen loads.
- **Verify:** Charts/stats or empty state with message.
- **Bug:** Crash; wrong restaurant data.

#### Profile / Logout
- **Expected:** Owner profile; sign out.
- **Verify:** Returns to login; cannot access owner routes when logged out.
- **Bug:** Owner shell shown for customer account.

---

### 3. Home Chef

**No seeded account** — sign up as Home Chef first, then admin approval.

#### Login / Dashboard
- **Expected:** Home Chef shell: Dashboard, Orders, Recipes, Content, Analytics, Profile.
- **Verify:** Kitchen restaurant linked after approval.
- **Bug:** Stuck on loading; approval pending screen blocks all tabs.

#### Recipes / Orders / Content / Stories / Analytics / Profile
- **Expected:** Same patterns as owner but chef-branded kitchen.
- **Verify:** Recipe posts in reels; dish management via kitchen restaurant.
- **Bug:** 403 before approval; wrong tab routing.

#### Logout
- **Expected:** Clean logout to login screen.
- **Bug:** Remains in chef shell.

---

### 4. Admin

Login as `demo.admin@example.com` / `Demo1234!`

#### Dashboard
- **Expected:** Analytics overview, pending counts.
- **Verify:** `/admin/analytics/overview` data reflected in UI.
- **Bug:** 403 for non-admin; empty dashboard.

#### Business approvals
- **Expected:** Pending restaurants and home chefs; approve/reject/suspend/reactivate.
- **Verify:** Approve changes status; rejected shows reason.
- **Bug:** Action succeeds but list not refreshed; wrong account type shown.

---

## 11. Environment reference

| Variable | Location | Purpose |
|----------|----------|---------|
| `DATABASE_URL` | `backend/.env` | PostgreSQL (Neon) |
| `SECRET_KEY` | `backend/.env` | JWT signing |
| `GOOGLE_CLIENT_ID` | `backend/.env` | Google token verification |
| `API_BASE_URL` | Flutter `--dart-define` | Backend URL (default `http://127.0.0.1:8000`) |
| `GOOGLE_MAPS_WEB_API_KEY` | Flutter `--dart-define` | Maps on web only |
| `FIREBASE_*` | Flutter `--dart-define` | Firebase on web |
| `google-services.json` | `frontend/android/app/` | Firebase Android |

---

## 12. Known limitations before new development

1. Neon DB **data transfer quota** may block migrations and cold DB connections.
2. Android **Gradle compileSdk** mismatch blocks mobile debug build until resolved.
3. Google Maps on web requires **`GOOGLE_MAPS_WEB_API_KEY`** dart-define.
4. Google Sign-In on web requires **Firebase dart-defines**.
5. Port **8080** may be occupied by a previous Flutter web session.

---

*Functional testing not performed by agent — use checklist above for manual QA.*
