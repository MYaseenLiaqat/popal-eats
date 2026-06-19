# Social Content Platform — Deliverables

Migration `016_social_content` applied. Flutter tests: **18/18 pass**.

---

## Phase 1 — Audit

See [`SOCIAL_CONTENT_AUDIT.md`](SOCIAL_CONTENT_AUDIT.md).

**Summary:** Home feed was recommendation/group-driven only. Stories and reels were UI placeholders with no backend. Dish image upload pattern existed and was reused.

---

## 1. Files created

### Backend
| File | Purpose |
|------|---------|
| `backend/alembic/versions/016_social_content.py` | Posts, stories, likes, comments, saves |
| `backend/app/core/content_constants.py` | Post types, subtypes, story TTL |
| `backend/app/models/post.py` | Unified Post ORM |
| `backend/app/models/story.py` | Story + StoryView |
| `backend/app/models/post_interaction.py` | PostLike, PostComment, PostSave |
| `backend/app/schemas/content.py` | Request/response schemas |
| `backend/app/services/content_service.py` | Post CRUD, home feed, discover reels |
| `backend/app/services/story_service.py` | Story create/list/view/expire |
| `backend/app/services/post_interaction_service.py` | Like, comment, save |
| `backend/app/routes/content.py` | Posts, feed, discover, interactions |
| `backend/app/routes/stories.py` | Story endpoints + image upload |

### Frontend
| File | Purpose |
|------|---------|
| `frontend/lib/models/post.dart` | Post + PostComment models |
| `frontend/lib/models/story.dart` | StoryItem + StoryGroup |
| `frontend/lib/utils/media_url.dart` | Resolve `/uploads/...` URLs |
| `frontend/lib/services/content_service.dart` | Content API client |
| `frontend/lib/widgets/feed/social_post_card.dart` | Home feed post card |
| `frontend/lib/widgets/feed/post_comments_sheet.dart` | Comments bottom sheet |
| `frontend/lib/screens/create_post_screen.dart` | Food post creation |
| `frontend/lib/screens/create_recipe_screen.dart` | Recipe post creation |
| `frontend/lib/screens/restaurant_post_screen.dart` | Owner promotions/announcements |
| `frontend/lib/screens/story_viewer_screen.dart` | View stories + create helper |

---

## 2. Files modified

### Backend
| File | Change |
|------|--------|
| `backend/app/models/user.py` | Post/story/interaction relationships |
| `backend/app/models/restaurant.py` | `posts` relationship |
| `backend/app/models/dish.py` | `posts` relationship |
| `backend/app/models/__init__.py` | Register new models |
| `backend/app/main.py` | Mount content + stories routers |

### Frontend
| File | Change |
|------|--------|
| `frontend/lib/screens/home_screen.dart` | Social posts, real stories, create menu, like/save/comment |
| `frontend/lib/widgets/feed/feed_stories_row.dart` | API-backed story groups |
| `frontend/lib/models/reel.dart` | `restaurant` kind + discover JSON |
| `frontend/lib/services/reels_service.dart` | Calls `GET /discover/reels`, placeholder fallback |
| `frontend/lib/widgets/reels/reel_card.dart` | Restaurant reel styling |
| `frontend/lib/screens/recommendations_screen.dart` | Updated reels copy |
| `frontend/lib/screens/restaurant_dashboard_screen.dart` | Restaurant post action |

---

## 3. Database changes (migration 016)

**`posts`** — unified content: `post_type` (food_post, recipe, chef_post, restaurant_post), caption, title, images (JSON), video_url, restaurant_id, dish_id, restaurant_content_subtype, recipe fields, engagement counts

**`stories`** — user_id, image_url, expires_at (24h)

**`story_views`** — unique (story_id, viewer_id)

**`post_likes`**, **`post_comments`**, **`post_saves`** — simple social interactions

Run: `cd backend && alembic upgrade head`

---

## 4. APIs added

| Method | Path | Description |
|--------|------|-------------|
| GET | `/feed/home` | Friends + self + restaurant posts |
| GET | `/discover/reels` | Recipe, chef, restaurant vertical content |
| POST | `/posts` | Create post (all types) |
| GET | `/posts/{id}` | Get post |
| PUT | `/posts/{id}` | Update own post |
| DELETE | `/posts/{id}` | Delete own post |
| POST | `/posts/{id}/image` | Upload post image |
| POST/DELETE | `/posts/{id}/like` | Like / unlike |
| POST/DELETE | `/posts/{id}/save` | Save / unsave |
| GET | `/posts/{id}/comments` | List comments |
| POST | `/posts/{id}/comments` | Add comment |
| GET | `/stories` | Active friend stories |
| POST | `/stories` | Create story (multipart image) |
| GET | `/stories/user/{id}` | User's active stories |
| POST | `/stories/{id}/view` | Mark viewed |

---

## 5. Flutter screens added

| Screen | Entry |
|--------|-------|
| `CreatePostScreen` | Home → Create → Food post |
| `CreateRecipeScreen` | Home → Create → Recipe |
| `StoryViewerScreen` | Home → Story ring tap |
| `RestaurantPostScreen` | Restaurant Dashboard → Post promotion |

---

## 6. Navigation changes

- **Home app bar (+):** Bottom sheet — Food post · Recipe · Story
- **Home stories row:** Real API stories; tap own ring to create/view; tap friend to view
- **Home feed:** Social posts interleaved with existing recommendation/group cards (unchanged rec logic)
- **Discover:** Reels card still opens `ReelsScreen`; now loads API content when available
- **Restaurant Dashboard:** "Post promotion or announcement" (approved restaurants only)

No changes to tab structure (Home · Discover · Community · Profile).

---

## 7. Remaining work

| Item | Priority | Notes |
|------|----------|-------|
| Chef post dedicated UI | Low | API supports `chef_post`; create via API or add screen |
| Video playback in reels | Low | `video_url` stored; player not implemented |
| Saved posts screen | Low | Save API works; no saved collection UI |
| Community activity feed | Medium | `CommunityScreen` placeholder not wired to `/feed/home` |
| Rich restaurant/dish tagging | Medium | Food posts use ID fields; search picker would improve UX |
| Push notifications for likes/comments | Low | Not in scope |
| Content moderation / reporting | Low | Admin tools not added |
| Seed demo content script | Low | Empty feed until users post |

---

## Demo flow

1. **Food post:** Home → + → Food post → image + caption → appears in feed
2. **Recipe:** Home → + → Recipe → title, ingredients, steps → appears in feed + Discover reels
3. **Story:** Home → Your story → pick image → visible 24h in stories row
4. **Restaurant post:** Owner → Dashboard → Post promotion → appears in all users' home feeds
5. **Discover:** Discover tab → Watch reels → vertical recipe/chef/restaurant content
6. **Interactions:** Like, comment, save on any post card in Home feed

Recommendation engine, groups, and voting are untouched.
