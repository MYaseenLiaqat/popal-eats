# Popal Eats — FYP Testing Checklist

Use this checklist before your FYP demonstration. Run the **backend** (`uvicorn` on port 8000) and **Flutter app** with API URL configured for your demo machine.

**Prerequisites**

- [ ] Backend running: `http://127.0.0.1:8000` (or set `--dart-define=API_BASE_URL=...`)
- [ ] Database seeded with restaurants, dishes, and categories
- [ ] At least **two test accounts** for social/group flows (User A and User B)
- [ ] Location permission enabled on device/emulator for group location sharing
- [ ] Flutter tests pass: `cd frontend && flutter test`

---

## 1. Authentication

| # | Test | Expected | Pass |
|---|------|----------|------|
| 1.1 | Open app while logged out | Login screen shown | ☐ |
| 1.2 | Register new account (valid email, password) | Account created; user lands in onboarding or main app | ☐ |
| 1.3 | Login with valid credentials | Main app loads after onboarding check | ☐ |
| 1.4 | Login with wrong password | Error message shown; stays on login | ☐ |
| 1.5 | Logout from Profile | Returns to login; session cleared | ☐ |
| 1.6 | Kill app and reopen while logged in | Session restored via stored token | ☐ |
| 1.7 | Backend offline at startup | Onboarding gate shows retry (not false onboarding) | ☐ |

---

## 2. Onboarding

| # | Test | Expected | Pass |
|---|------|----------|------|
| 2.1 | New user first login | Preference onboarding screen shown | ☐ |
| 2.2 | Load food interests & allergies options | Options load from API | ☐ |
| 2.3 | Complete onboarding with selections | User enters main app; not prompted again | ☐ |
| 2.4 | Skip onboarding | User enters main app; skip persisted | ☐ |
| 2.5 | Returning user | Onboarding skipped automatically | ☐ |
| 2.6 | API error loading options | Error state + Retry on onboarding screen | ☐ |

---

## 3. Preferences

| # | Test | Expected | Pass |
|---|------|----------|------|
| 3.1 | Profile → Nutrition Preferences | Current cuisines/diet load from backend | ☐ |
| 3.2 | Update diet type and save | Changes persist after refresh | ☐ |
| 3.3 | Profile → Budget Preferences | Budget level loads and saves | ☐ |
| 3.4 | Profile preferences summary | Reflects saved backend data | ☐ |
| 3.5 | Backend offline on preferences screen | Error + Retry shown | ☐ |

**Note:** Calorie goal and weekly/monthly budget on preference screens are display-only (not synced to API).

---

## 4. Friends

| # | Test | Expected | Pass |
|---|------|----------|------|
| 4.1 | Community → Search Users | Search returns users from backend | ☐ |
| 4.2 | Send friend request (User A → User B) | Request appears in User B incoming | ☐ |
| 4.3 | User B accepts request | Both users see each other in friends list | ☐ |
| 4.4 | User B rejects request | Request removed; no friendship created | ☐ |
| 4.5 | Remove friend | Friend removed from list | ☐ |
| 4.6 | Friend requests screen | Incoming/outgoing tabs load correctly | ☐ |
| 4.7 | Empty friends list | Empty state message shown | ☐ |

---

## 5. Groups

| # | Test | Expected | Pass |
|---|------|----------|------|
| 5.1 | Create group with name | Group appears in groups list | ☐ |
| 5.2 | Invite friend to group | Invitation sent; visible in outgoing | ☐ |
| 5.3 | Invitee accepts invitation | Joins group; detail screen opens | ☐ |
| 5.4 | Invitee rejects invitation | Invitation removed | ☐ |
| 5.5 | Group detail shows members & host | Member list matches backend | ☐ |
| 5.6 | Group invitations screen | Incoming/outgoing invitations load | ☐ |
| 5.7 | Empty groups list | Empty state shown | ☐ |

**Known gap:** Leave group API exists but no UI action yet.

---

## 6. Location Sharing

| # | Test | Expected | Pass |
|---|------|----------|------|
| 6.1 | Share my location on group detail | Location saved; appears in member list | ☐ |
| 6.2 | Second member shares location | Both locations visible | ☐ |
| 6.3 | Deny location permission | Clear error / permission dialog | ☐ |
| 6.4 | Refresh locations section | Pull/refresh reloads from API | ☐ |
| 6.5 | No locations shared yet | Empty state in locations section | ☐ |

---

## 7. Group Recommendations

| # | Test | Expected | Pass |
|---|------|----------|------|
| 7.1 | Open group recommendations (after locations shared) | Ranked dish list loads | ☐ |
| 7.2 | Recommendations show dish name, restaurant, price, score | Cards render with images when available | ☐ |
| 7.3 | Tap recommendation card | Dish detail opens | ☐ |
| 7.4 | Pull to refresh | Recommendations reload | ☐ |
| 7.5 | No recommendations (missing prefs/locations) | Empty state + refresh button | ☐ |
| 7.6 | Backend error | Error state + retry | ☐ |
| 7.7 | Consensus banner on recommendations screen | Shows pending/considering/agreed/ordered message | ☐ |

---

## 8. Voting

| # | Test | Expected | Pass |
|---|------|----------|------|
| 8.1 | Vote Like on a recommendation | Snackbar confirms vote; summary updates | ☐ |
| 8.2 | Change vote to Love | Selected state moves to Love button | ☐ |
| 8.3 | Vote Dislike | Dislike count increases in live scores | ☐ |
| 8.4 | Loading state while voting | Active button shows spinner | ☐ |
| 8.5 | Live scores section | Likes, loves, dislikes, consensus, final score shown | ☐ |
| 8.6 | Multiple members vote (User A + User B) | Totals reflect both votes | ☐ |

**Known gap:** Selected vote state is not restored after app refresh (no backend “my vote” field).

---

## 9. Consensus & Decision

| # | Test | Expected | Pass |
|---|------|----------|------|
| 9.1 | Open Group Decision from detail or recommendations | Decision screen loads | ☐ |
| 9.2 | Status = pending | Banner: “Waiting for members to vote” | ☐ |
| 9.3 | After some votes | Status may move to considering | ☐ |
| 9.4 | Enough positive votes | Status = agreed; agreed dish shown | ☐ |
| 9.5 | Mark as Ordered (when agreed) | Confirmation dialog → status = ordered | ☐ |
| 9.6 | Mark as Ordered before agreed | Button hidden; API would reject if forced | ☐ |
| 9.7 | Vote breakdown on decision screen | Aggregate likes/loves/dislikes shown | ☐ |
| 9.8 | Pull to refresh on decision screen | Decision and vote summary reload | ☐ |

---

## 10. Core App Flows (Demo Support)

| # | Test | Expected | Pass |
|---|------|----------|------|
| 10.1 | Home: browse restaurants/dishes | Data loads from API | ☐ |
| 10.2 | For You tab: personalized recommendations | Three sections load (For You, Trending, Popular) | ☐ |
| 10.3 | Add dish to cart → checkout → order success | Order placed; cart cleared | ☐ |
| 10.4 | Continue shopping after order | Returns to main app (not duplicate shell) | ☐ |
| 10.5 | Orders tab shows order history | Past orders listed | ☐ |
| 10.6 | Admin account: admin dashboard accessible | Analytics load (admin role only) | ☐ |

---

## 11. Mock / Placeholder Areas (Do Not Treat as Live Data)

These sections use **static demo content** — mention this during FYP if shown:

| Area | Location |
|------|----------|
| Chef of the Week / recipes | Home tab |
| Community Activity feed | Community tab |
| Weekly calorie chart | Profile tab |
| Health Dashboard | Profile → Health Dashboard |
| Menu OCR upload | Admin → Import Menu (placeholder screen) |

---

## Sign-off

| Role | Name | Date | Notes |
|------|------|------|-------|
| Developer | | | |
| Tester | | | |
| Demo lead | | | |
