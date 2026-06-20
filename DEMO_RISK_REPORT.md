# Popal Eats — Demo Risk Report

**Date:** 2026-06-20

---

## Critical

| Risk | Severity | Impact | Workaround |
|------|----------|--------|------------|
| **Stale backend process** | Critical | Content/social routes return 404; feed empty; demo scripts fail | Stop process on `:8000`, restart: `cd backend && python -m uvicorn app.main:app --host 127.0.0.1 --port 8000` |
| **Missing `DATABASE_URL`** | Critical | API fails at startup | Copy `backend/.env.example` → `.env`, set PostgreSQL URL, run `alembic upgrade head` |
| **Migrations not applied** | Critical | 500 errors on social/restaurant tables | `cd backend && alembic upgrade head` |

---

## High

| Risk | Severity | Impact | Workaround |
|------|----------|--------|------------|
| **Cold group recommendations (~20 s)** | High | First group rec load feels frozen | Wait for spinner; second load uses snapshot (~1.6 s). Pre-open group rec screen before demo segment. |
| **Hybrid recommendations slow (~12–18 s)** | High | Home screen waits on rec API in parallel | Pull-to-refresh after feed appears; or demo feed/stories first before scrolling to rec cards |
| **Hybrid returns 0 items for users without preferences** | High | Empty personalized section | Use `demo.host@example.com` (seeded with onboarding) or complete onboarding before demo |
| **Firebase not configured (mobile)** | High | Google sign-in fails | Use email demo accounts (`demo.host@example.com` / `Demo1234!`) or pass `FIREBASE_*` dart-defines |

---

## Medium

| Risk | Severity | Impact | Workaround |
|------|----------|--------|------------|
| **Demo accounts use `@example.com`** | Medium | `@popaleats.test` emails fail login (422) | Use seeded accounts from `seed_demo_content.py` only |
| **Foodpanda import requires network** | Medium | Catalog expansion fails offline | Pre-run `python scripts/foodpanda_import_lahore.py --limit 150` before demo |
| **Uploads directory not writable** | Medium | Post/story image upload fails | Ensure `backend/uploads/` exists and is writable |
| **Remote PostgreSQL latency** | Medium | Feed/rec endpoints 1–2 s even after optimization | Expected on cloud DB; restart backend to pick up code fixes |

---

## Low

| Risk | Severity | Impact | Workaround |
|------|----------|--------|------------|
| **No post detail screen** | Low | Tapping post has limited navigation | Use comments sheet and feed cards only |
| **Comment count not live-updated on card** | Low | Count stale until refresh | Pull to refresh home feed |
| **Reels placeholder fallback** | Low | Offline reels show placeholders | Ensure backend running for `/discover/reels` |
| **Area keyword coverage gaps** | Low | Audit shows 0 restaurants for DHA/Gulberg keywords | Foodpanda vendors use free-text addresses; discovery by coordinates still works |

---

## Environment Checklist (Pre-Demo)

```bash
# 1. Backend
cd backend
alembic upgrade head
python scripts/seed_demo_content.py
python -m uvicorn app.main:app --host 127.0.0.1 --port 8000

# 2. Verify
python scripts/e2e_demo_verification.py   # expect 14/14 PASS
python scripts/audit_social_content.py      # expect 20/20 PASS

# 3. Flutter (point API to host machine IP if on device)
flutter run
```

---

## Demo Accounts

| Email | Password | Role |
|-------|----------|------|
| demo.host@example.com | Demo1234! | customer |
| demo.friend@example.com | Demo1234! | customer |
| demo.owner@example.com | Demo1234! | restaurant_owner |
| demo.admin@example.com | Demo1234! | admin |

---

## Stale Routes (None Known)

All social routes registered in `app/main.py`: `content_router`, `stories_router`, `recommendations_v2_router`. If any return 404, the running process predates the deploy — **restart required**, not a routing bug.
