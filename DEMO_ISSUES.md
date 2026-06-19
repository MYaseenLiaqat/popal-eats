# Demo Issues & Workarounds

Last updated: demo hardening pass (post redesign Phases 1–5).

## Remaining known issues

| Issue | Severity | Notes |
|-------|----------|-------|
| Group recommendations API slow (~90–120s) | High | Large candidate pool + scoring. Client timeout is 3 minutes. |
| Reels are placeholder only | Medium | No video playback; static previews + snackbar on play. |
| Health dashboard uses sample data | Medium | Labeled “Preview” — not connected to real tracking. |
| Friend activity feed empty | Low | No social activity API yet; Community shows honest empty state. |
| Dish images missing for some items | Low | Depends on Foodpanda import; gradient placeholder shown. |
| Group distance uses manifest/fallback coords | Low | All vendors may share anchor coords; “Near your group” is approximate. |
| Admin tools on Home (admin role only) | Low | Dashboard + menu upload visible if logged in as admin. |
| Vote snapshot if users refresh at different times | Low | Rare in demo; use two browsers without mid-flow refresh. |
| Web signup rejects `.test` email TLD | Low | Use `@example.com` accounts only. |

## Workarounds

### Backend not reachable (mobile)
- Start API: `uvicorn app.main:app --host 0.0.0.0 --port 8000`
- Use LAN IP in `api_config.dart` for physical devices (e.g. `192.168.x.x:8000`).
- Web: `--dart-define=API_BASE_URL=http://127.0.0.1:8000`

### Group recommendations loading
- Open group → recommendations → **wait up to 2 minutes** without leaving the screen.
- Demo with a pre-warmed group (load once before audience arrives).

### Two-account social demo
- Account A: `demoA@example.com` / `FypTest123!`
- Account B: `demoB@example.com` / `FypTest123!`
- Use Chrome + Edge (or normal + incognito) so sessions stay separate.

### Lahore-only catalog
- Recommendations exclude Karachi-tagged restaurants.
- Foodpanda-sourced restaurants without city are treated as Lahore.

### Luxury prices in results
- Soft price penalty applied; very expensive items rank lower but may still appear.

## Demo-safe flows (recommended order)

1. Login → onboarding (new user) or skip (returning)
2. Home food feed → tap dish → add to cart → checkout
3. Discover → For You / Trending / Popular
4. Activity (heart) → accept friend request / search users
5. Community → open group → share location → group recommendations → vote
6. Group decision → agreed dish → order flow
7. Profile → Your Orders

## Features to avoid during presentation

- **Reels “Watch”** — shows “video coming soon” message
- **Health dashboard** — sample numbers only (ok if you say “preview”)
- **Admin menu OCR upload** — unless specifically demoing admin
- **Refreshing group recommendations mid-vote** on both clients simultaneously
- **Logout from Home** — removed; use Profile → Logout
- **Karachi restaurant names** — should not appear; if one does, note data import edge case

## Quick pre-demo checklist

- [ ] Backend running on `0.0.0.0:8000`
- [ ] Both demo accounts exist and are friends (or send request live)
- [ ] Active group session with both members
- [ ] Group recommendations pre-loaded once (optional)
- [ ] Cart empty or intentional demo order ready
