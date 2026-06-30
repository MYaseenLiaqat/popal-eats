# Phase 16.6 — Manual QA Setup (Final)

**Status:** All sessions running — begin manual testing now.

---

## Running sessions

| Service | URL / device | API base |
|---------|--------------|----------|
| **Backend** | http://127.0.0.1:8000 | — |
| **Swagger** | http://127.0.0.1:8000/docs | — |
| **Chrome** | http://localhost:8080 | `http://127.0.0.1:8000` |
| **Android** | Redmi Note 9S (`f731c5e1`) | `http://192.168.100.171:8000` |

**Do not press `q` in Flutter terminals.**

---

## Credentials (all roles)

| Role | Email | Password |
|------|-------|----------|
| Customer | `demo.host@example.com` | `Demo1234!` |
| Customer (friend) | `demo.friend@example.com` | `Demo1234!` |
| Restaurant | `demo.owner@example.com` | `Demo1234!` |
| Admin | `demo.admin@example.com` or `admin@popaleats.com` | `Demo1234!` / `YourPassword123` |
| Home Chef | Register via Sign Up | — |

---

## Role test matrix

### Customer

| # | Feature | Navigation | Expected API | Expected UI | Failure signs |
|---|---------|------------|--------------|-------------|---------------|
| 1 | Login | Login screen | `POST /login` 200 | Main shell tabs | Connection error, 401 |
| 2 | Google Sign-In | Login → Google button | `POST /auth/google` 200 | Logged in | Button missing (web), popup blocked |
| 3 | Onboarding | Auto after login | `GET /preferences/onboarding/status` | Cuisine/allergy wizard | Stuck spinner |
| 4 | Home feed | Tab Home | `GET /feed/home`, `GET /stories` | Posts, stories, reels entry | Empty + no retry |
| 5 | Order / browse | Tab Order | `GET /restaurants` | Restaurant cards | Blank list |
| 6 | Restaurant detail | Tap restaurant | `GET /restaurants/{id}`, dishes | Menu, hero, cart bar | Overflow, missing images |
| 7 | Dish detail | Tap dish | `GET /dishes/{id}` | Nutrition, reviews, Add to cart | Crash |
| 8 | Recommendations | Order / Profile | `GET /recommendations/v2` | AI list + explanations | Timeout >30s, empty |
| 9 | Cart / checkout | Cart → Checkout | `GET /cart`, `POST /checkout` | Summary, place order | 400 validation |
| 10 | Delivery | Tab Delivery | `GET /orders` | Map fallback, timeline | Rider buttons active (bug) |
| 11 | Community | Tab Community | `GET /friends`, groups | Friends, groups list | 500 error |
| 12 | Group recs | Group → Recommendations | `GET /groups/{id}/recommendations` | Vote + rec cards | Empty group |
| 13 | Stories / Reels | Home | `GET /stories`, reels | Full-screen media | Broken images |
| 14 | Profile / logout | Tab Profile | `GET /me` | Settings, sign out | Token not cleared |

### Restaurant owner

| # | Feature | Navigation | Expected API | Expected UI |
|---|---------|------------|--------------|-------------|
| 1 | Login | `demo.owner@example.com` | `POST /login` | Restaurant shell |
| 2 | Dashboard | Default | `GET /restaurants/{id}/dashboard` | Stats grid |
| 3 | Orders | Orders tab | `GET /restaurants/{id}/orders` | Status updates |
| 4 | Dishes CRUD | Dishes | `POST/PUT /dishes` | Form + image upload |
| 5 | Content | Content tab | `POST .../posts` | Post in home feed |
| 6 | Analytics | Profile | `GET .../analytics` | Charts/metrics |
| 7 | Image upload | Profile | `POST /restaurants/{id}/image` | Cover/logo stored |

### Home Chef

| # | Feature | Navigation | Expected API | Expected UI |
|---|---------|------------|--------------|-------------|
| 1 | Register | Sign Up → Home Chef | `POST /register` | Pending approval |
| 2 | License upload | After register | `POST /home-chef/me/profile/license` | File URL in profile |
| 3 | Dashboard | After approval | `GET /home-chef/dashboard` | Kitchen metrics |
| 4 | Orders / recipes | Shell tabs | `/home-chef/orders`, dishes | Same as restaurant |

### Admin

| # | Feature | Navigation | Expected API | Expected UI |
|---|---------|------------|--------------|-------------|
| 1 | Login | Admin credentials | `POST /login` | Admin dashboard |
| 2 | Approvals | Approvals section | `PUT /admin/.../approve` | Pending list clears |
| 3 | Stats | Dashboard | Admin metrics | Stat cards load |

---

## Google Sign-In verification

| Platform | Button visible? | Config status | Manual test |
|----------|-----------------|---------------|-------------|
| **Android** | Yes (if Firebase configured) | `google-services.json` + embedded `firebase_options` | Tap Google → account picker → `POST /auth/google` |
| **Web (Chrome)** | **No** unless `FIREBASE_*` dart-defines set | `GOOGLE_WEB_CLIENT_ID` alone is insufficient for web Firebase init | Add to run command: `FIREBASE_API_KEY`, `FIREBASE_APP_ID`, `FIREBASE_PROJECT_ID`, `FIREBASE_MESSAGING_SENDER_ID` |

**Backend:** `GOOGLE_CLIENT_ID` set in `.env` — required for token verification.

**New Google users:** Backend creates user on first `POST /auth/google`; returns JWT pair.

**Session restore:** App reload → `GET /me` with stored token.

---

## Google Maps — usage map

| Screen / feature | Uses Google Maps? | Notes |
|------------------|-------------------|-------|
| **Delivery tracking** | **YES** — `DeliveryMap` widget | Only real `GoogleMap` in app |
| Customer address selection | **NO** | Text fields in checkout |
| Restaurant registration | **NO** | Text address only |
| Home Chef registration | **NO** | Kitchen address text field |
| Restaurant details | **NO** | Static images only |
| Location onboarding | **NO** | `geolocator` permission only |
| Group member locations | **NO** | Coordinate labels, no map widget |

**Keys required:**

| Platform | Key | Where |
|----------|-----|-------|
| Android | Maps SDK for Android | `android/local.properties` → `GOOGLE_MAPS_API_KEY` |
| Web | Maps JavaScript API | `--dart-define=GOOGLE_MAPS_WEB_API_KEY=...` |

**Current Chrome session:** Maps fallback UI (no web key passed).  
**Android:** Live map only if `GOOGLE_MAPS_API_KEY` is in `local.properties`.

---

## Infrastructure status

| Check | Result |
|-------|--------|
| `/health` | 200 `{"status":"ok","version":"3.0.0"}` |
| Swagger `/docs` | 200 |
| Supabase PostgreSQL | Connected (pooler URL) |
| Alembic | `023_cart_and_orders (head)` |
| Android device | Redmi Note 9S connected via Flutter |
| ADB in PATH | Not in PATH (Flutter detects device OK) |

---

## Ready for manual testing: **YES** (with notes)

**Layout fix applied:** `registration_image_picker.dart` — press **`R`** (hot restart) in both Flutter terminals to pick up the signup upload button fix.

**Known runtime notes:**
- Chrome may log render errors on Sign Up until hot restart
- Google Sign-In button hidden on web until `FIREBASE_*` dart-defines are added
- Maps show fallback UI without API keys

See also: [`MANUAL_TESTING_GUIDE.md`](MANUAL_TESTING_GUIDE.md)
