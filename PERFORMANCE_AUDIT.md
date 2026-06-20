# Popal Eats — Performance Audit

**Date:** 2026-06-20  
**Environment:** Local API `http://127.0.0.1:8000`, PostgreSQL (remote), 5 samples per endpoint  
**Catalog at audit time:** ~138 Foodpanda Lahore restaurants, ~10,147 dishes, ~6,200 recommendation candidates

---

## Executive Summary

| Area | Before | After | Target | Status |
|------|--------|-------|--------|--------|
| Home feed (`GET /feed/home`) | ~5,400 ms | **~1,423 ms avg** (min 1,172 ms) | < 1,500 ms | **PASS** |
| Stories (`GET /stories`) | ~2,100 ms (N+1) | **~1,382 ms avg** | < 2,000 ms | **PASS** |
| Reels (`GET /discover/reels`) | ~650 ms | **~581 ms avg** | < 1,000 ms | **PASS** |
| Personal recs (`GET /recommendations/v2`) | ~18,390 ms | **~12–18 s** (catalog grew) | < 5,000 ms | **FAIL** |
| Group recs (cold) | 60–120 s reported | **~19.9 s** | < 10 s | **PARTIAL** |
| Group recs (warm / snapshot) | N/A | **~1.6 s** | < 3 s | **PASS** |

Primary wins came from eliminating N+1 like/save/view queries on the feed and stories, removing duplicate full-catalog tag scans in group recommendations, and scoping order-count aggregations.

---

## Endpoint Details

### 1. Home Feed — `GET /feed/home?limit=20`

| Metric | Value |
|--------|-------|
| Avg response time | 1,423 ms |
| Min / Max | 1,172 / 1,659 ms |
| Query pattern (before) | ~1 feed query + **40 like/save queries** (2 × 20 posts) + count |
| Query pattern (after) | ~1 count + 1 feed + **2 batch interaction queries** |

**Bottleneck (before):** `_serialize_post()` issued one `PostLike` and one `PostSave` query per post (classic N+1).

**Fix applied:** `_viewer_interaction_ids()` batch-loads liked/saved post IDs in two queries; `func.count(Post.id)` replaces expensive ORM `query.count()`.

**Recommended follow-up:** Add composite indexes on `(user_id, post_id)` for `post_likes` and `post_saves` if latency remains high on remote DB.

---

### 2. Stories — `GET /stories`

| Metric | Value |
|--------|-------|
| Avg response time | 1,382 ms |
| Min / Max | 1,117 / 1,543 ms |

**Bottleneck (before):** `_serialize_story()` queried `StoryView` per story (N+1).

**Fix applied:** `_viewer_story_ids()` batch-loads viewed story IDs once per request.

---

### 3. Discover Reels — `GET /discover/reels`

| Metric | Value |
|--------|-------|
| Avg response time | 581 ms |
| Min / Max | 499 / 697 ms |

**Bottleneck:** Single joined query with limit; no N+1. Acceptable for demo.

**Recommended fix:** None required for demo; optional CDN caching for thumbnails.

---

### 4. Personal Recommendations — `GET /recommendations/v2?strategy=hybrid`

| Metric | Value |
|--------|-------|
| Avg response time | 12,460–17,966 ms (varies with catalog size) |
| Min / Max | 8,551 / 24,579 ms |

**Bottlenecks identified:**
1. `load_eligible_dishes()` loads **~6,000+** dish rows with restaurant/category joins on every request.
2. Hybrid strategy runs content scoring twice (pool of 100 + full pass).
3. `load_tag_maps(db)` previously re-scanned **all** restaurants and dishes (removed in content path).
4. Global `OrderItem` aggregation (scoped to candidates in content path now).

**Fixes applied:** `build_tag_maps_from_dishes()` from in-memory candidates; scoped order counts; `heapq.nlargest` for top-N.

**Remaining bottleneck:** Full candidate load + Python scoring over entire Lahore pool. Home screen waits on this endpoint in parallel with feed — dominates perceived load when recommendations are slow.

**Recommended follow-up (post-demo):** Candidate caching per market, materialized recommendation snapshots, or precomputed nightly rankings.

---

### 5. Group Recommendations — `GET /groups/{session_id}/recommendations`

| Metric | Cold | Warm (snapshot) |
|--------|------|-----------------|
| Response time | ~19,910 ms | ~1,568 ms |
| Items returned | 20 | 20 |

**Bottlenecks identified (before):**
1. `load_tag_maps(db)` — duplicate full-catalog scan (~8k+ rows) on top of candidate load.
2. Global order-count aggregation.
3. Full sort of all scored candidates before slicing top 20.

**Fixes applied:**
- `build_tag_maps_from_dishes(candidates)` — zero extra DB round-trip.
- `_load_order_counts(db, candidate_ids)` — scoped aggregation.
- `heapq.nlargest(TOP_N, …)` — O(n log 20) instead of full sort.

**Before/after:** Reported 60–120 s cold loads reduced to **~20 s** on expanded catalog. Warm loads use persisted snapshots (~1.6 s).

**Recommended follow-up:** Pre-warm snapshots when group session is created or when last member shares location.

---

### 6. Restaurant Dashboard — `GET /restaurants/{id}/dashboard`

| Metric | Notes |
|--------|-------|
| Not benchmarked in automated run | Requires `demo.owner@example.com` token |

**Code review:** Scoped queries per restaurant (orders, dishes, pending counts). No N+1 patterns found. Expected < 500 ms on warm DB.

---

## Query Count Summary (Home Feed, 20 posts)

| Phase | Queries |
|-------|---------|
| Before optimization | ~43+ |
| After optimization | ~5 |

---

## Measurement Script

Re-run anytime:

```bash
cd backend
python scripts/performance_audit.py
python scripts/benchmark_group_recommendations.py
```

Raw JSON: `PERFORMANCE_AUDIT.json`
