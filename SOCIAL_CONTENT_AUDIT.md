# Social Content — Validation Audit

**Date:** 2026-06-19  
**Type:** Audit only — no code changes  
**Method:** Code inspection + live API/DB checks via `backend/scripts/audit_social_content.py`

---

## Executive summary

| Area | Status | Notes |
|------|--------|-------|
| Posts (CRUD + interactions) | **PASS** | Backend complete; Flutter feed-only view |
| Stories | **PASS** | Create, view, 24h expiration filter |
| Home feed | **PASS** with caveats | API ordering correct; UI interleaves rec cards |
| Discover / Reels | **PASS** | API-backed; placeholder fallback works |
| Restaurant announcements | **PASS** | Global visibility in home feed |
| Database | **PASS** | FKs + CASCADE verified |
| Performance | **WARN** | Home feed ~5.4s on seeded data |

**Overall: PASS** when backend includes social content routes (migration 016 applied, server restarted).

---

## 1. Posts

| Check | Result | Evidence |
|-------|--------|----------|
| Create post | **PASS** | `POST /posts` → 201; Flutter `CreatePostScreen` + `CreateRecipeScreen` |
| View post | **PARTIAL** | `GET /posts/{id}` works; **no dedicated Post detail screen** in Flutter — cards only |
| Like post | **PASS** | `POST/DELETE /posts/{id}/like`; `liked_by_me` + `like_count` update; UI toggles optimistically |
| Save post | **PASS** | `POST/DELETE /posts/{id}/save`; `saved_by_me` + `save_count` update; **no Saved collection UI** |
| Comment post | **PASS** | `POST /posts/{id}/comments`; bottom sheet lists/adds comments |

### Live API (port 8001, demo.host@example.com)

| Operation | Latency |
|-----------|--------:|
| Create post | ~1.5s |
| View post | ~0.8s |
| Like / Save | ~0.9s each |
| Add comment | ~1.3s |

### Bugs / gaps

| ID | Severity | Issue | Suggested fix |
|----|----------|-------|---------------|
| P1 | Low | Comment count on feed card not refreshed after adding comment in sheet | Callback to increment `commentCount` on parent `Post` |
| P2 | Low | No post detail screen; recipe steps/ingredients not expandable in feed | Optional `PostDetailScreen` for recipes |
| P3 | Info | `GET /posts/{id}` has **no feed visibility gate** — any user with ID can read any post | Add same friend/restaurant filter as home feed if privacy required |
| P4 | Info | Posts created without image upload have empty `images[]` | Expected; demo should upload image or use seeder |

---

## 2. Stories

| Check | Result | Evidence |
|-------|--------|----------|
| Create story | **PASS** | `POST /stories` multipart → `uploads/stories/`; Flutter `showCreateStorySheet` + file picker |
| View story | **PASS** | `StoryViewerScreen` tap-to-advance; `POST /stories/{id}/view` marks viewed |
| Story expiration | **PASS** | `STORY_TTL_HOURS = 24`; `list_active_stories` filters `expires_at > now()` |

### DB state (sample)

| Metric | Value |
|--------|------:|
| Total stories | 4 |
| Active (unexpired) | 4 |
| Expired | 0 |

### Notes

- Seeded stories use **Foodpanda CDN URLs** (full `https://` paths) — render correctly via `resolveMediaUrl`.
- Expired stories are **hidden, not deleted** — no cleanup cron (acceptable for demo).
- Story rings show **friend + self** only (`Friendship` graph).

| ID | Severity | Issue | Suggested fix |
|----|----------|-------|---------------|
| S1 | Info | No scheduled purge of expired `stories` rows | Optional cron or TTL job post-demo |

---

## 3. Feed

| Check | Result | Evidence |
|-------|--------|----------|
| Home feed API ordering | **PASS** | `list_home_feed` → `ORDER BY created_at DESC` (verified on 14 items) |
| Friend posts visible | **PASS** | Filter: `author_id IN (friends ∪ self)` |
| Restaurant posts visible | **PASS** | All users see `restaurant_post` from **approved** restaurants |
| Recipe posts visible | **PASS** | Included in home feed for friends/self |
| UI merge ordering | **PARTIAL** | `_buildMergedFeed()` pattern: **1 social post → 2 rec/group cards → repeat** — not strict global chronology |

### Feed visibility rules (`content_service.py`)

```
visible = (author is friend or self) OR (post is restaurant_post from approved restaurant)
```

### Frontend load

- Fetches `/feed/home?limit=15` + recommendations in parallel.
- **No pagination / infinite scroll** for social posts (page 1 only).

| ID | Severity | Issue | Suggested fix |
|----|----------|-------|---------------|
| F1 | Low | UI interleaving breaks pure chronological feed | Document for demo; or merge by `created_at` if strict order needed |
| F2 | Low | Single page (15 posts max) | Add pull-to-refresh only today |

---

## 4. Discover

| Check | Result | Evidence |
|-------|--------|----------|
| Reels loading | **PASS** | `GET /discover/reels` → 6 items (~483ms) |
| Empty state | **PASS** | `ReelsScreen` shows "No reels yet" when list empty |
| Placeholder fallback | **PASS** | `ReelsService` falls back to `placeholderReels` on API error or empty response |

### Content types in Discover

| Type | In Discover API | In Home Feed |
|------|-----------------|--------------|
| `recipe` | Yes | Yes (friends/self) |
| `chef_post` | Yes | Yes — **no Flutter create UI** |
| `restaurant_post` | Yes (approved only) | Yes (global) |
| `food_post` | **No** (by design) | Yes |

### Reels UI limitations (not bugs)

- Video playback: preview image + play button → SnackBar "future update"
- Side actions (save/share/recipe): placeholder SnackBars in `reel_card.dart`

| ID | Severity | Issue | Suggested fix |
|----|----------|-------|---------------|
| D1 | Info | `chef_post` creatable via API only | Add create screen or skip in demo |
| D2 | Info | Reel interactions are placeholders | Use Home feed like/save for demo |

---

## 5. Restaurant announcements

| Check | Result | Evidence |
|-------|--------|----------|
| Creation | **PASS** | `RestaurantPostScreen` + owner RBAC; subtypes: promotion, new_dish, announcement |
| Visibility | **PASS** | Appear in **all users'** home feeds when restaurant `approval_status=approved` |
| Feed rendering | **PASS** | `SocialPostCard` shows restaurant name as author; subtype label; 3 seeded announcements |

### Validation rules

- Owner or admin only.
- Restaurant must be **approved** before posting.
- Pending restaurants cannot publish announcements.

---

## 6. Database

### Counts (live DB)

| Table / type | Count |
|--------------|------:|
| `posts` total | 14 |
| `food_post` | 8 |
| `recipe` | 3 |
| `restaurant_post` | 3 |
| `stories` (active) | 4 |
| `post_likes` | (per interactions) |
| `post_comments` | ≥1 |
| `post_saves` | (per interactions) |

### Foreign keys (migration 016)

| Table | FK | ON DELETE |
|-------|-----|-----------|
| `posts.author_id` | → `users.id` | **CASCADE** |
| `posts.restaurant_id` | → `restaurants.id` | SET NULL |
| `posts.dish_id` | → `dishes.id` | SET NULL |
| `stories.user_id` | → `users.id` | **CASCADE** |
| `post_likes` | → `posts`, `users` | **CASCADE** |
| `post_comments` | → `posts`, `users` | **CASCADE** |
| `post_saves` | → `posts`, `users` | **CASCADE** |
| `story_views` | → `stories`, `users` | **CASCADE** |

**Verified:** 12 FK rows in `information_schema`; `post_likes` delete rule = CASCADE.

### Cascade behavior

- Delete user → posts, stories, likes, comments, saves cascade.
- Delete post → likes, comments, saves cascade.
- Delete restaurant/dish → post FK nulled, post remains.

| ID | Severity | Issue | Suggested fix |
|----|----------|-------|---------------|
| DB1 | Info | Denormalized `like_count` / `comment_count` / `save_count` could drift if rows edited manually | Acceptable; counts updated in service layer |

---

## 7. Performance

Measured on port **8001** with 14 feed items (demo seed):

| Endpoint | Latency | Assessment |
|----------|--------:|------------|
| `GET /feed/home?limit=50` | **~5.4s** | **Slow** — N+1 queries per post for `liked_by_me` / `saved_by_me` |
| `GET /stories` | ~1.2s | Acceptable |
| `GET /discover/reels` | ~0.5s | Good |
| `POST /posts` | ~1.5s | Acceptable |

**Root cause (code):** `_serialize_post()` runs 2 extra queries per post (`PostLike`, `PostSave`).

| ID | Severity | Issue | Suggested fix |
|----|----------|-------|---------------|
| PERF1 | **Medium** | Home feed 5+ seconds with ~15 posts | Batch-load likes/saves for viewer in one query |
| PERF2 | Low | Home also loads recommendations + groups sequentially | Already parallelized; rec API dominates on cold start |

---

## 8. Operational / demo risks

| Risk | Impact | Mitigation |
|------|--------|------------|
| **Backend not restarted** after social content deploy | All content APIs return **404** on old process (confirmed on :8000) | Restart uvicorn; verify `GET /feed/home` ≠ 404 |
| Empty feed | No seed data | Run `python scripts/seed_demo_content.py` |
| Demo login fails | Used `@popaleats.test` emails | Use `demo.host@example.com` / `Demo1234!` |
| Slow home load | Examiner sees spinner | Pre-warm feed before demo; explain first load |
| Reels video tap | SnackBar "future update" | Show reels as **image previews**; don't tap play |
| No saved posts screen | Save appears to do nothing visible | Demo like + comment instead |
| Chef posts | No create UI | Demo recipe + restaurant posts |

---

## 9. Pass/Fail matrix

| # | Area | Check | Result |
|---|------|-------|--------|
| 1 | Posts | Create | **PASS** |
| 2 | Posts | View (API) | **PASS** |
| 3 | Posts | View (Flutter detail) | **PARTIAL** |
| 4 | Posts | Like | **PASS** |
| 5 | Posts | Save | **PASS** |
| 6 | Posts | Comment | **PASS** |
| 7 | Stories | Create | **PASS** |
| 8 | Stories | View | **PASS** |
| 9 | Stories | Expiration | **PASS** |
| 10 | Feed | API ordering | **PASS** |
| 11 | Feed | Friend posts | **PASS** |
| 12 | Feed | Restaurant posts | **PASS** |
| 13 | Feed | Recipe posts | **PASS** |
| 14 | Feed | UI merge order | **PARTIAL** |
| 15 | Discover | Reels load | **PASS** |
| 16 | Discover | Empty state | **PASS** |
| 17 | Discover | Placeholder fallback | **PASS** |
| 18 | Restaurant | Announcement create | **PASS** |
| 19 | Restaurant | Global visibility | **PASS** |
| 20 | Restaurant | Feed rendering | **PASS** |
| 21 | Database | Counts + FKs | **PASS** |
| 22 | Database | CASCADE | **PASS** |
| 23 | Performance | Feed < 2s | **FAIL** (~5.4s) |

**Score: 20 PASS · 2 PARTIAL · 1 FAIL** (performance threshold)

---

## 10. Re-run validation

```bash
cd backend
python scripts/seed_demo_content.py
python scripts/audit_social_content.py http://127.0.0.1:8000
```

Expect **20/20** API checks when backend is current. Performance measured separately.

---

*Supersedes the pre-implementation audit in this file (Phase 1, pre-coding). Implementation status: complete.*
