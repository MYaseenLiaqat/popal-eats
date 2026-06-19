# Popal Eats — Demo Readiness Report

**Date:** 2026-06-19  
**Scope:** Data population, E2E verification, UX audit — no new features.

---

## Executive summary

| Area | Status |
|------|--------|
| Restaurant catalog | **PASS** — 8,434 dishes, 4,487 recommendation candidates |
| Group recommendations + voting | **PASS** — E2E verified (20 recs → agreed → ordered) |
| Social content (posts/stories/reels) | **PASS** — after backend restart + demo seed |
| Demo accounts | **PASS** — stable `@example.com` accounts seeded |
| Geographic keyword audit | **WARN** — address text lacks neighborhood names; 805 manifest vendors not yet imported |
| Google Sign-In | **WARN** — requires Firebase dart-defines; email auth is demo-safe |
| Video reels playback | **N/A** — static preview only |

**Overall demo readiness: PASS** with pre-demo checklist below.

---

## Phase 1 — Restaurant coverage

See [`backend/RESTAURANT_COVERAGE_REPORT.md`](backend/RESTAURANT_COVERAGE_REPORT.md).

| Check | Result |
|-------|--------|
| Lahore Foodpanda restaurants | 100 |
| Total dishes | 8,434 |
| Recommendation candidates | 4,487 |
| Lake City / Gulberg / Wapda / Valencia (address match) | 0 (expected — addresses omit area names) |
| Manifest vs imported | 905 discovered, 100 imported |

**Actions taken:**
- Added discovery anchors for Gulberg, Lake City, Wapda Town, Valencia (next discovery run).
- Enhanced audit script with Valencia + candidate pool count.

**Recommended before FYP (optional, long-running):**
```bash
cd backend
python scripts/foodpanda_discover_lahore.py   # refresh manifest with new anchors
python scripts/foodpanda_import_lahore.py --limit 150
```

---

## Phase 2 — Demo content seeder

**Script:** `backend/scripts/seed_demo_content.py`

```bash
cd backend
python scripts/seed_demo_content.py          # idempotent
python scripts/seed_demo_content.py --reset-posts   # fresh posts/stories
```

### Demo accounts (password: `Demo1234!`)

| Role | Email |
|------|-------|
| Host (presenter) | `demo.host@example.com` |
| Friend (second device) | `demo.friend@example.com` |
| Restaurant owner | `demo.owner@example.com` |
| Admin | `demo.admin@example.com` |

**Seeded content:** 5 food posts, 3 recipes, 4 stories, 3 restaurant announcements, host↔friend friendship.

---

## Phase 3 — E2E verification

| Script | Result |
|--------|--------|
| `scripts/e2e_social_workflow.py` | **PASS** — friends, group, location, 20 recs, voting, ordered |
| `scripts/e2e_demo_verification.py` | **PASS** — 14/14 checks (on backend with social content routes) |

Run before demo:
```bash
cd backend
# Restart backend first (see checklist)
python scripts/seed_demo_content.py
python scripts/e2e_demo_verification.py http://127.0.0.1:8000
python scripts/e2e_social_workflow.py
```

### Flow status

| Flow | Status | Notes |
|------|--------|-------|
| Signup | **PASS** | Requires `username` field |
| Login | **PASS** | Use `@example.com` emails only |
| Google Sign-In | **WARN** | Needs Firebase config |
| Preferences onboarding | **PASS** | |
| Personal recommendations | **PASS** | 10+ items |
| Friend request | **PASS** | |
| Story / Post / Feed | **PASS** | Login as `demo.host@example.com` |
| Group invite + location | **PASS** | |
| Group recommendations | **PASS** | 20 dishes |
| Voting + consensus | **PASS** | |
| Restaurant registration | **PASS** | Starts as `pending` |
| Admin approval | **PASS** | `demo.admin@example.com` |
| Dish creation + promotion | **PASS** | Owner dashboard |

---

## Phase 4 — UX audit (fixes applied)

| Issue | Severity | Fix |
|-------|----------|-----|
| Demo emails `@popaleats.test` rejected by login API | **High** | Seeder uses `@example.com`; migrates by username |
| E2E register missing `username` | **High** | Updated `e2e_social_workflow.py` + `e2e_demo_verification.py` |
| Community activity empty state misleading | **Low** | Points users to Home feed |
| Content APIs 404 on stale backend | **High** | **Restart backend** after social content deploy |
| Reels side actions show "coming soon" | **Low** | Documented; use Home like/save for demo |
| Health dashboard / calorie chart | **Low** | Mock data — skip in demo |
| Menu upload OCR screen | **Low** | Placeholder — skip in demo |
| Food post restaurant/dish tagging uses IDs | **Low** | Works for demo; search picker is future work |

No broken navigation or blocking empty states on core paths after seed + restart.

---

## Phase 5 — Recommended demo sequence (12 min)

### Pre-demo (5 min, off-screen)

1. `cd backend && alembic upgrade head`
2. **Restart backend:** `uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload`
3. `python scripts/seed_demo_content.py`
4. Flutter: `flutter run --dart-define=API_BASE_URL=http://<LAN_IP>:8000`
5. Device B: same API URL, login `demo.friend@example.com` / `Demo1234!`

### Live demo

| Step | Screen | Account |
|------|--------|---------|
| 1 | Login | `demo.host@example.com` |
| 2 | **Home** — stories, food posts, rec cards | Host |
| 3 | **Discover** — For You + Watch reels | Host |
| 4 | **Community** — friends list | Host |
| 5 | Create group → invite Demo Friend | Host |
| 6 | Accept invite | Friend |
| 7 | Share location (both) | Both |
| 8 | Group recommendations → vote Love/Like | Both |
| 9 | View decision → Mark ordered | Host |
| 10 | **Profile → Restaurant Dashboard** (optional) | `demo.owner@example.com` |
| 11 | **Admin → Restaurant Approvals** (optional) | `demo.admin@example.com` |

Full script: [`DEMO_FLOW.md`](DEMO_FLOW.md)

---

## Known limitations

| Limitation | Impact | Workaround |
|------------|--------|------------|
| Only 11% of discovered vendors imported | Some areas underrepresented in UI | Import batch before demo; explain manifest pipeline |
| Address lacks neighborhood names | Coverage report shows 0 by area | Show dish count + group recs near Lahore centroid |
| Google Sign-In | May fail without Firebase | Use email demo accounts |
| Reels video playback | Preview images only | Say "video streaming is future work" |
| Token auto-refresh | Long sessions may expire | Re-login if 401 |
| Backend must be restarted | Social routes 404 on old process | Restart before demo |
| `demo.host@popaleats.test` | Invalid for API login | Use `@example.com` accounts only |

---

## Risks

| Risk | Likelihood | Mitigation |
|------|------------|------------|
| Backend not restarted | Medium | Run `e2e_demo_verification.py` — fails fast on 404 |
| Empty home feed | Low | Run `seed_demo_content.py` |
| Group recs empty | Low | Ensure Lahore location shared; catalog has 4k+ candidates |
| Emulator location off | Medium | Set GPS to Lahore (31.4824, 74.3237) |
| Examiner asks about Lake City | Medium | Explain Foodpanda import + discovery anchors; show import pipeline |

---

## Files created / modified (this phase)

**Created:**
- `backend/scripts/seed_demo_content.py`
- `backend/scripts/e2e_demo_verification.py`
- `backend/RESTAURANT_COVERAGE_REPORT.md`
- `DEMO_READINESS_REPORT.md`

**Modified:**
- `backend/scripts/audit_restaurant_coverage.py` — Valencia, candidate count
- `backend/scripts/e2e_social_workflow.py` — username on register
- `backend/app/services/foodpanda_bulk/discovery.py` — 4 new anchors
- `frontend/lib/screens/community_screen.dart` — activity empty state copy

---

## Quick verification checklist

- [ ] Backend restarted on port 8000
- [ ] `python scripts/seed_demo_content.py` exit 0
- [ ] `python scripts/e2e_demo_verification.py` → 14/14 pass
- [ ] Flutter points to correct `API_BASE_URL`
- [ ] Login `demo.host@example.com` / `Demo1234!`
- [ ] Home feed shows posts + stories
- [ ] Second device logged in as `demo.friend@example.com`
