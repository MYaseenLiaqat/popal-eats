# Demo Checklist

Mark each item **PASS** / **FAIL** during a dry run. Use two browsers for social flows.

**Accounts:** `demoA@example.com` / `demoB@example.com` — password `FypTest123!`

**Backend:** `cd backend` → `PYTHONPATH=. uvicorn app.main:app --host 0.0.0.0 --port 8000`

**Frontend (web):** `cd frontend` → `flutter run -d chrome --dart-define=API_BASE_URL=http://127.0.0.1:8000`

---

## Auth & onboarding

| # | Step | PASS | FAIL | Notes |
|---|------|------|------|-------|
| 1 | Login with demo account | ☐ | ☐ | |
| 2 | Signup (optional) with `@example.com` | ☐ | ☐ | Avoid `.test` domain |
| 3 | Preference onboarding completes | ☐ | ☐ | Cuisines, diet, allergies |
| 4 | Logout from Profile works | ☐ | ☐ | |

## Preferences

| # | Step | PASS | FAIL | Notes |
|---|------|------|------|-------|
| 5 | Nutrition preferences save | ☐ | ☐ | Profile → Nutrition |
| 6 | Budget preferences save | ☐ | ☐ | PKR fields, budget mode |
| 7 | Preferences summary on Profile | ☐ | ☐ | |

## Home & discover

| # | Step | PASS | FAIL | Notes |
|---|------|------|------|-------|
| 8 | Home feed loads (images + PKR) | ☐ | ☐ | Pull to refresh |
| 9 | Tap feed card → dish detail | ☐ | ☐ | |
| 10 | Discover tab: For You / Trending / Popular | ☐ | ☐ | No hybrid/AI jargon |
| 11 | Prices show as PKR | ☐ | ☐ | Cart, checkout, orders |
| 12 | Activity hub (heart) opens | ☐ | ☐ | |

## Friends & search

| # | Step | PASS | FAIL | Notes |
|---|------|------|------|-------|
| 13 | Search users (Activity → Search) | ☐ | ☐ | Min 2 characters |
| 14 | Send friend request (A → B) | ☐ | ☐ | |
| 15 | Accept request (B in Activity) | ☐ | ☐ | Badge clears |
| 16 | Friends list shows connection | ☐ | ☐ | Community / Profile |

## Groups

| # | Step | PASS | FAIL | Notes |
|---|------|------|------|-------|
| 17 | Create group session | ☐ | ☐ | |
| 18 | Invite friend to group | ☐ | ☐ | |
| 19 | Accept group invitation | ☐ | ☐ | |
| 20 | Community group card → group detail | ☐ | ☐ | |
| 21 | Share member location | ☐ | ☐ | |
| 22 | Group recommendations load | ☐ | ☐ | Allow ~2 min |
| 23 | Human-friendly group reasons | ☐ | ☐ | No “hybrid” text |

## Voting & consensus

| # | Step | PASS | FAIL | Notes |
|---|------|------|------|-------|
| 24 | Vote yes/maybe/no on dish | ☐ | ☐ | Both users |
| 25 | Vote summary updates | ☐ | ☐ | |
| 26 | Group decision screen | ☐ | ☐ | |
| 27 | Consensus / agreed status | ☐ | ☐ | 60% threshold |

## Ordering

| # | Step | PASS | FAIL | Notes |
|---|------|------|------|-------|
| 28 | Add dish to cart | ☐ | ☐ | |
| 29 | Checkout with address | ☐ | ☐ | |
| 30 | Order success screen | ☐ | ☐ | PKR total |
| 31 | Profile → Your Orders | ☐ | ☐ | |
| 32 | Order detail | ☐ | ☐ | |

## Navigation (4 tabs)

| # | Step | PASS | FAIL | Notes |
|---|------|------|------|-------|
| 33 | Home · Discover · Community · Profile | ☐ | ☐ | Orders under Profile |
| 34 | No accidental logout from Home | ☐ | ☐ | |

---

## Automated tests (dev)

```powershell
cd frontend
flutter test
```

Expected: all tests pass (including `reel_model_test.dart`).

Optional E2E (backend required):

```powershell
cd backend
$env:PYTHONPATH="."
python scripts/e2e_social_workflow.py
```

---

## Sign-off

| Role | Date | Result |
|------|------|--------|
| Dry run | | PASS / FAIL |
| Demo day | | PASS / FAIL |

**Blockers to fix before demo:** _(list any FAIL items)_
