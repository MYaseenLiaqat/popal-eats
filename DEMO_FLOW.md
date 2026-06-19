# Popal Eats — FYP Demo Flow

Step-by-step presentation script for your Final Year Project demonstration. Estimated duration: **12–15 minutes** (adjust sections as needed).

---

## Before You Start (2 min setup, not shown live)

1. Start backend: `cd backend && uvicorn app.main:app --reload --host 0.0.0.0 --port 8000`
2. Seed demo content: `python scripts/seed_demo_content.py`
3. Verify: `python scripts/e2e_demo_verification.py` (expect 14/14 pass)
4. Confirm database has restaurants, dishes, and categories.
5. Prepare **two accounts** on separate devices/emulators:
   - **Demo Host** — `demo.host@example.com` / `Demo1234!`
   - **Demo Friend** — `demo.friend@example.com` / `Demo1234!`
   - Optional owner: `demo.owner@example.com` · admin: `demo.admin@example.com`
4. Run Flutter app with correct API URL:
   ```bash
   cd frontend
   flutter run --dart-define=API_BASE_URL=http://<YOUR_LAN_IP>:8000
   ```
5. Clear app data or use fresh accounts if you want a clean onboarding flow.

---

## Act 1 — Problem & Product Vision (1 min)

**Say:** “Popal Eats helps groups decide what to order together using personalized recommendations, location sharing, and consensus voting.”

**Show:** Login screen → briefly mention auth, preferences, social groups, and AI recommendations.

---

## Act 2 — Authentication & Onboarding (2 min)

1. **Login** as Demo Host (or register if showing full flow).
2. If onboarding appears:
   - Select **2–3 food interests** and **1 allergy**
   - Tap **Continue** (or **Skip** if short on time)
3. **Say:** “Preferences are stored on the backend and drive the recommendation engine.”

**Avoid:** Health dashboard and mock calorie charts unless asked — they are demo placeholders.

---

## Act 3 — Personal Recommendations (2 min)

1. Open **For You** tab (bottom nav).
2. **Say:** “The recommendation engine uses hybrid scoring — cuisine match, budget, nutrition, and popularity.”
3. Scroll through **For You**, **Trending**, and **Popular** sections.
4. Tap a dish → **Dish Detail** screen.
5. Optional: add to cart to show commerce path later.

**Key point:** Individual recommendations vs group recommendations are separate features.

---

## Act 4 — Social Layer: Friends (1.5 min)

1. Go to **Community** tab (or Profile → Friends).
2. **Search Users** → find Demo Friend → send friend request.
3. On **second device/account**: accept friend request.
4. **Say:** “Friend graph enables group invitations and shared sessions.”

---

## Act 5 — Group Session (2 min)

1. **Community → Groups → Create Group** (e.g. “Lunch Squad”).
2. Open group → **Invite Friends** → invite Demo Friend.
3. Second account: **Group Invitations → Accept**.
4. On group detail, show **members list** and session info.

**Say:** “Groups are time-bound sessions where members collaborate on a food decision.”

---

## Act 6 — Location Sharing (1.5 min)

1. On group detail, tap **Share my location** (both accounts if possible).
2. Show **member locations** updating in the group.
3. **Say:** “Group centroid feeds the recommendation engine for nearby restaurant picks.”

**Tip:** Use real device GPS or emulator location for best results.

---

## Act 7 — Group Recommendations (2 min)

1. Tap **View Recommendations** on group detail.
2. Show ranked dish cards with scores and reasons.
3. Point out **consensus banner** at top (status: pending initially).
4. Tap a card briefly to show dish detail link.

**Say:** “Recommendations are generated per session using member preferences and shared location — not modified by voting logic.”

---

## Act 8 — Voting & Consensus (3 min) ★ Core differentiator

1. On a recommendation card, vote **Like** → show snackbar and **live scores** updating.
2. Second account: vote **Love** on same or different dish.
3. Show banner change: **“Consensus is forming”** → eventually **“Group has agreed…”**
4. Tap **View decision** (banner or app bar icon).
5. On **Group Decision** screen, show:
   - Status chip
   - Agreed dish name, restaurant, price
   - Consensus score & final score
   - Vote breakdown (likes / loves / dislikes)
6. When status is **Agreed**, tap **Mark as Ordered** → confirm dialog.
7. Show status **Ordered** and banner **“Decision finalized”**.

**Say:** “Voting updates consensus scores in real time. When enough members agree, the group locks a decision and can mark it ordered.”

---

## Act 9 — Wrap-Up & Architecture (1 min)

**Say (bullet points):**

- **Frontend:** Flutter + Provider pattern, REST via `ApiClient`
- **Backend:** FastAPI, JWT auth, group sessions, voting service
- **Social APIs:** friends, groups, invitations, locations
- **Recommendation engine:** existing backend logic; UI consumes APIs only

**Optional quick show:**

- **Orders tab** — if you placed a cart order earlier
- **Profile → Nutrition/Budget** — backend-synced preferences
- **Admin dashboard** — if demo account has admin role

---

## Fallback Scenarios

| Issue | What to do |
|------|-----------|
| No group recommendations | Ensure both members shared location and completed onboarding |
| Voting buttons missing | Recommendations need persisted `recommendation_id` from backend snapshots — refresh recommendations |
| Consensus stays pending | Need more member votes; explain threshold to examiner |
| Backend unreachable | Show pre-recorded screenshots or switch to localhost emulator |
| Location denied | Explain permission requirement; use second emulator with location set |

---

## Sections to Skip or Label as “Future Work”

| Section | Why |
|--------|-----|
| Home → Chef of the Week | Mock data |
| Community Activity feed | Redirected | Activity lives on **Home** feed (posts/stories) |
| Profile calorie chart | Mock data |
| Health Dashboard | Mock data |
| Admin → Import Menu (OCR) | Placeholder screen |
| Leave group | API exists, UI not wired |

**Script line:** “These areas use placeholder content for UI polish; the social and group decision flows are fully integrated with the backend.”

---

## Suggested Demo Data

| Item | Suggestion |
|------|------------|
| Group name | “FYP Lunch Demo” |
| Members | 2 (presenter + friend account) |
| Votes | Host = Love, Friend = Like on same dish (fastest path to agreed) |
| Dish to highlight | Top-ranked group recommendation |

---

## Post-Demo Q&A Prep

**Likely questions:**

1. **How is consensus calculated?** — Backend combines vote types with member count; positive votes weighted; agreed when threshold met.
2. **What if members disagree?** — Status stays considering; highest final score leads until agreement threshold.
3. **Is recommendation logic changed by votes?** — Base score from engine; votes adjust consensus/final score only.
4. **Token refresh / logout?** — Access token stored locally; refresh endpoint exists but auto-refresh not implemented.
5. **Production readiness?** — See stabilization audit: token lifecycle, vote persistence on reload, mock section replacement.

---

## Time-Compressed Version (8 min)

1. Login + skip onboarding if already done (30s)
2. For You recommendations (1 min)
3. Create group + invite friend (1.5 min)
4. Share location both sides (1 min)
5. Group recommendations (1 min)
6. Vote + decision + mark ordered (3 min)
7. Architecture summary (1 min)
