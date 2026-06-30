# Popal Eats — Manual Testing Guide

Use this guide while **Android** (Redmi Note 9S) and **Chrome** (http://localhost:8083) are running.

**Backend:** `http://127.0.0.1:8000` (Chrome) · `http://192.168.100.171:8000` (Android on same Wi‑Fi)

---

## Prerequisites

| Check | Command / URL |
|-------|----------------|
| API health | `GET /health` → `200` |
| Android API | Device must reach `192.168.100.171:8000` |
| Chrome API | `http://127.0.0.1:8000` |
| Google Maps (web) | Optional: `--dart-define=GOOGLE_MAPS_WEB_API_KEY=...` |
| Google Sign-In | Requires Firebase + release/debug SHA-1 |

---

## Demo credentials

| Role | Email | Password | Notes |
|------|-------|----------|-------|
| **Customer** | `demo.host@example.com` | `Demo1234!` | Onboarding may be complete |
| **Customer (friend)** | `demo.friend@example.com` | `Demo1234!` | For friends/groups tests |
| **Restaurant owner** | `demo.owner@example.com` | `Demo1234!` | Has demo restaurant + dishes |
| **Admin (seed)** | `demo.admin@example.com` | `Demo1234!` | Platform admin |
| **Admin (primary)** | `admin@popaleats.com` | `YourPassword123` | If `seed_admin.py` was run |
| **Home Chef** | *(register new)* | — | No seeded home chef; use Sign Up → Home Chef |

---

## 1. Customer workflow

### 1.1 Login
- **Path:** Launch app → Login screen
- **Action:** Email `demo.host@example.com`, password `Demo1234!`
- **API:** `POST /login` → `200`, `access_token` in response
- **UI:** Main shell with bottom tabs (Home, Order, Delivery, Community, Profile)
- **Bug indicators:** "Could not connect", infinite spinner, 401 on `/me`

### 1.2 Privacy & location gates (first launch)
- **Path:** After login if fresh install
- **UI:** Privacy consent → Location permission onboarding
- **Verify:** Tapping "Agree & Continue" reaches main app

### 1.3 Preference onboarding (if incomplete)
- **Path:** Auto-shown when `GET /preferences/onboarding/status` → incomplete
- **API:** `GET/PUT /preferences/*`
- **UI:** Cuisine, allergies, budget, nutrition steps
- **Verify:** Completing reaches MainShell

### 1.4 Home feed (social)
- **Path:** Tab **Home**
- **API:** `GET /feed/home?limit=20`, then `GET /stories` (background)
- **UI:** Stories row, reels entry, post cards with images
- **Verify:** Pull-to-refresh, like/save/comment, tap restaurant/dish links
- **Bug indicators:** Empty feed with no retry, broken images, overflow on small screen

### 1.5 Order / Discover restaurants
- **Path:** Tab **Order**
- **API:** `GET /restaurants`, `GET /dishes`
- **UI:** Restaurant list, search, cuisine filters, hero images
- **Verify:** Tap restaurant → detail with menu sections, AI badges

### 1.6 Restaurant detail & dish
- **Path:** Order → select restaurant → tap dish
- **API:** `GET /restaurants/{id}`, `GET /dishes?restaurant_id=`
- **UI:** Hero image, dish cards, allergens, nutrition, reviews, sticky Add to Cart
- **Verify:** Add to cart updates cart badge

### 1.7 Recommendations
- **Path:** Order tab → Recommendations / AI picks, or Profile → Recommendations
- **API:** `GET /recommendations/v2?limit=10` (may take 5–20s first load)
- **UI:** Ranked dishes with explanations, score breakdown
- **Bug indicators:** Timeout without friendly message, empty list without copy

### 1.8 Cart & checkout
- **Path:** Cart icon → Cart → Checkout
- **API:** `GET /cart`, `POST /checkout`
- **UI:** Items, address preview, coupon field, order summary
- **Verify:** Place order → success screen

### 1.9 Delivery tracking
- **Path:** Tab **Delivery**
- **API:** `GET /orders`
- **UI:** Active order map (fallback if no Maps key), timeline, restaurant-managed delivery copy
- **Verify:** Call/Chat Rider **disabled**; Need Help shows restaurant contact; Report Issue opens order detail

### 1.10 Community
- **Path:** Tab **Community**
- **UI:** Friends, groups, invitations
- **API:** `GET /friends`, `GET /groups`

### 1.11 Groups & group recommendations
- **Path:** Community → Groups → Create / open session
- **API:** `POST /groups`, `GET /groups/{id}/recommendations`
- **UI:** Vote widgets, location sharing, group rec cards
- **Verify:** Recommendations load for group context

### 1.12 Stories & reels
- **Path:** Home → story bubble / reels entry
- **API:** `GET /stories`, `GET /discover/reels`
- **UI:** Full-screen story viewer, reels vertical scroll

### 1.13 Profile & preferences
- **Path:** Tab **Profile**
- **API:** `GET /me`, `GET /preferences`
- **UI:** Edit nutrition, budget, logout
- **Verify:** Logout returns to login screen

---

## 2. Restaurant owner workflow

### 2.1 Login
- **Credentials:** `demo.owner@example.com` / `Demo1234!`
- **API:** `POST /login` → role `restaurant_owner` or `restaurant`
- **UI:** Restaurant shell (dashboard, orders, dishes, content, profile)

### 2.2 Dashboard
- **Path:** Default landing
- **API:** `GET /restaurants/{id}/dashboard`
- **UI:** Stats grid, revenue/orders metrics
- **Bug indicators:** 403 if account pending approval

### 2.3 Orders
- **Path:** Orders tab
- **API:** `GET /restaurants/{id}/orders`
- **UI:** Status filters, update order status
- **Verify:** Status change reflects on customer delivery tab

### 2.4 Dish management
- **Path:** Dishes → Add/Edit
- **API:** `POST/PUT /dishes`, `POST /dishes/{id}/image`
- **UI:** Form validation, image upload
- **Verify:** New dish appears on customer menu

### 2.5 Content (posts)
- **Path:** Content tab → Create post
- **API:** `POST /restaurants/{id}/posts`
- **UI:** Caption, image, appears in home feed

### 2.6 Analytics
- **Path:** Profile → Analytics
- **API:** `GET /restaurants/{id}/analytics`

### 2.7 Image uploads
- **Path:** Restaurant profile / registration
- **API:** `POST /restaurants/{id}/image`
- **Verify:** Logo/cover stored under `/uploads/restaurants/`

---

## 3. Home Chef workflow

### 3.1 Register (no seed account)
- **Path:** Login → Sign Up → Home Chef
- **API:** `POST /register`, then `POST /home-chef/me/profile/image`, `POST /home-chef/me/profile/license`
- **UI:** Profile image + food license file picker
- **Verify:** Pending approval screen after login if admin approval required

### 3.2 After approval
- **Path:** Home Chef shell
- **API:** `GET /home-chef/dashboard`, `GET /home-chef/orders`
- **UI:** Kitchen dashboard, recipes (dishes), orders, content
- **Mirror:** Same flows as restaurant owner via kitchen restaurant ID

---

## 4. Admin workflow

### 4.1 Login
- **Credentials:** `admin@popaleats.com` / `YourPassword123` **or** `demo.admin@example.com` / `Demo1234!`
- **UI:** Admin dashboard with gradient header, stat grid

### 4.2 Dashboard
- **API:** `GET /admin/dashboard` (or aggregated admin routes)
- **UI:** User/restaurant counts, quick actions

### 4.3 Business approvals
- **Path:** Approvals → Restaurants / Home chefs
- **API:** `PUT /admin/restaurants/{id}/approve`, reject flows
- **Verify:** Approved account can access owner/chef shell

### 4.4 Restaurant approvals
- **Path:** Restaurant approval queue
- **Verify:** Pending restaurants from signup appear

---

## 5. Cross-platform checks

| Area | Android | Chrome |
|------|---------|--------|
| Login / logout | ✓ test | ✓ test |
| Dark theme | ✓ | ✓ |
| Keyboard overlap (forms) | ✓ signup, checkout | ✓ |
| Image loading | Network images | CORS via API host |
| Google Maps delivery | Native key in `local.properties` | Fallback map without web key |
| File upload | Profile, license, dish images | file_picker web |
| Pull-to-refresh | Home, Delivery | Home, Delivery |
| Back navigation | System back | Browser back |

---

## 6. API error scenarios (manual)

| Scenario | How to test | Expected UI |
|----------|-------------|-------------|
| No internet | Airplane mode | Friendly error + Retry |
| API timeout | Slow recommendations | Loading skeleton, then error/retry |
| Empty recommendations | New user no prefs | Empty state message |
| Expired JWT | Wait 30+ min or clear token | Redirect to login |
| 403 pending approval | Login as pending business | Business status screen |

---

## 7. Suggested verification order (60 min)

1. Customer login → home feed → order food → checkout (15 min)
2. Delivery tab → order history (5 min)
3. Recommendations + group session (10 min)
4. Restaurant owner login → orders + dish edit (10 min)
5. Admin login → approvals glance (5 min)
6. Repeat critical paths on second platform (15 min)

---

## 8. Bug report template

```
Platform: Android / Chrome
Screen:
Role:
Steps:
Expected API:
Actual API (status code):
Expected UI:
Actual UI:
Screenshot:
```
