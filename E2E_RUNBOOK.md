# Popal Eats — E2E Two-Account Runbook

**LAN IP:** `192.168.100.171`  
**Backend port:** `8000`  
**Phone + PC must be on the same Wi‑Fi.**

---

## Terminal 1 — Backend (keep open)

```powershell
cd c:\Users\user\OneDrive\Desktop\popaleats\popal-eats\backend
$env:PYTHONPATH="."
$env:PROCESS_REVIEWS_INLINE="true"
..\venv\Scripts\python.exe -m uvicorn app.main:app --host 0.0.0.0 --port 8000
```

Verify:

```powershell
Invoke-WebRequest -Uri "http://127.0.0.1:8000/health" -UseBasicParsing
Invoke-WebRequest -Uri "http://192.168.100.171:8000/health" -UseBasicParsing
```

Both should return `{"status":"ok","version":"3.0.0"}`.

> Use `--host 0.0.0.0` (not `127.0.0.1`) so your phone can reach the API.

---

## Terminal 2 — Flutter Web (Account B)

```powershell
cd c:\Users\user\OneDrive\Desktop\popaleats\popal-eats\frontend
flutter run -d chrome --dart-define=API_BASE_URL=http://127.0.0.1:8000
```

First web build may take 2–4 minutes.

---

## Terminal 3 — Flutter Mobile (Account A)

Connect phone via USB, enable USB debugging, then:

```powershell
cd c:\Users\user\OneDrive\Desktop\popaleats\popal-eats\frontend
flutter devices
flutter run --dart-define=API_BASE_URL=http://192.168.100.171:8000
```

**Android emulator** (no physical phone):

```powershell
flutter emulators
flutter emulators --launch <emulator_id>
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000
```

---

## Test Accounts

Register fresh accounts or use API-verified ones:

| Role | Suggested email | Password |
|------|-----------------|----------|
| **A (Mobile)** | `demoA@example.com` | `FypTest123!` |
| **B (Web)** | `demoB@example.com` | `FypTest123!` |

> Do **not** use `@fyp.test` — the backend rejects `.test` email domains.

---

## Step-by-Step Procedure

### Phase A — Setup (both accounts)

| Step | Account A (Mobile) | Account B (Web) |
|------|--------------------|-----------------|
| 1 | Open app → **Sign up** `demoA@example.com` | Open Chrome app → **Sign up** `demoB@example.com` |
| 2 | Complete **onboarding**: Biryani, Burger → Continue | Same onboarding choices |
| 3 | Land on **Home** tab | Land on **Home** tab |

### Phase B — Friends

| Step | Who | Action |
|------|-----|--------|
| 4 | **A** | Community tab → **Search Users** → search `demoB` → **Send friend request** |
| 5 | **B** | Community tab → **Friend Requests** → **Accept** A's request |
| 6 | Both | Confirm friends appear in **Friends List** |

### Phase C — Group session

| Step | Who | Action |
|------|-----|--------|
| 7 | **A** | Community → **Groups** → **Create Group** → name: `FYP Demo` |
| 8 | **A** | Group detail → **Invite Friends** → select **B** → Send |
| 9 | **B** | Groups → **Invitations** → **Accept** |
| 10 | Both | Open group detail → confirm **2 members** listed |

### Phase D — Location sharing

| Step | Who | Action |
|------|-----|--------|
| 11 | **A** | Group detail → **Share my location** → Allow GPS |
| 12 | **B** | Group detail → **Share my location** → Allow browser location |
| 13 | Both | Confirm both locations appear in **Locations** section |

### Phase E — Recommendations (wait ~2 minutes)

| Step | Who | Action |
|------|-----|--------|
| 14 | **A** | Group detail → **View Recommendations** |
| 15 | **B** | Same screen on web |
| 16 | Both | Wait for ranked dishes to load (**up to 2 min** — do not refresh early) |
| 17 | Both | Note consensus banner: **"Waiting for members to vote"** |

### Phase F — Voting & consensus

| Step | Who | Action |
|------|-----|--------|
| 18 | **A** | On top dish card → tap **Love** |
| 19 | **B** | On same dish → tap **Like** |
| 20 | Both | Confirm **Live scores** update (likes, loves, consensus %) |
| 21 | Both | Open **Group Decision** (banner link or app bar icon) |
| 22 | Both | Confirm status = **Agreed**, agreed dish shown |

> With 2 members, both must vote Like or Love to reach **Agreed** (60% threshold = 2/2).

### Phase G — Mark ordered

| Step | Who | Action |
|------|-----|--------|
| 23 | **A or B** | Group Decision → **Mark as Ordered** → Confirm |
| 24 | Both | Status = **Ordered**, banner: **"Decision finalized"** |

---

## Optional — Verify via API

```powershell
cd c:\Users\user\OneDrive\Desktop\popaleats\popal-eats\backend
$env:PYTHONPATH="."
..\venv\Scripts\python.exe scripts/e2e_social_workflow.py
```

Creates two test users and runs the full workflow automatically (~3 min).

---

## Troubleshooting

| Problem | Fix |
|---------|-----|
| Mobile can't reach API | Backend must use `--host 0.0.0.0`; phone on same Wi‑Fi; use `192.168.100.171` |
| Recommendations timeout | Normal first load ~112s; wait up to 2 min |
| No phone in `flutter devices` | Enable USB debugging; accept RSA prompt; install drivers |
| Web build slow | First compile 2–4 min; subsequent runs faster |
| Location denied | Grant permission in app/browser settings |
| IP changed | Run `ipconfig`, update mobile `API_BASE_URL` |

---

## Services NOT required

- Redis / RQ worker (set `PROCESS_REVIEWS_INLINE=true`)
- Docker
- Local PostgreSQL (uses Neon cloud from `backend/.env`)
