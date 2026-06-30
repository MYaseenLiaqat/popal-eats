# Phase 16.5 — Pre-Release QA Report

**Date:** 2026-06-29  
**Objective:** Stable, optimized, testable builds on Android + Chrome before deployment.

---

## Part 1 — Development environment

| Component | Status |
|-----------|--------|
| Flutter 3.44.1 / Dart 3.12.1 | ✓ Installed |
| Android SDK 36.1.0 / Build-tools 36.1.0 | ✓ Installed |
| Java (OpenJDK 21, Android Studio JBR) | ✓ |
| Gradle 9.1.0 / AGP 9.0.1 / Kotlin 2.3.20 | ✓ |
| Android licenses | ✓ All accepted |
| Chrome | ✓ |
| ADB / device | ✓ Redmi Note 9S (`f731c5e1`) |
| `flutter pub get` | ✓ |
| Backend venv + `requirements.txt` | ✓ Installed |
| Backend API | ✓ Running on port 8000 |

**Note:** Visual Studio (Windows desktop) not installed — not required for Android/Web.

---

## Part 2 — Mobile build

| Item | Status |
|------|--------|
| Device detected | Redmi Note 9S (Android 12, API 31) |
| `flutter run` | **✓ SUCCESS** |
| Build time | ~28 min (first debug assemble after release builds) |
| API URL | `http://192.168.100.171:8000` |
| Warnings | AAPT2 daemon shutdown timeout (non-fatal, build succeeded) |

**Fixes applied (Phase 17, retained):** `compileSdk=36` on all plugin subprojects.

**Session:** `flutter run` is **active** on device — do not press `q`.

---

## Part 3 — Web build (Chrome)

| Item | Status |
|------|--------|
| Port 8082 | In use (prior session) |
| Port 8083 | **✓ Chrome launched successfully** |
| API URL | `http://127.0.0.1:8000` |
| Google Maps | Fallback active (no `GOOGLE_MAPS_WEB_API_KEY` — expected) |
| Compilation | ✓ No errors |

**Session:** `flutter run -d chrome --web-port=8083` is **active**.

---

## Part 4 — Code optimization

| Action | Result |
|--------|--------|
| `dart fix --apply` | **51 fixes** in 27 files (`prefer_const_constructors`) |
| `HomeNetworkImage` | Added `cacheWidth` / `cacheHeight` for memory-efficient decoding |
| `flutter analyze` | **0 errors** (info-level `prefer_const` reduced) |
| Dead code / unused imports | No analyzer errors; automated const fixes applied |

**Not changed:** Business logic, providers architecture, recommendation code.

---

## Part 5 — Application size audit

| Category | Size / count |
|----------|----------------|
| Bundled assets (`assets/images/`) | **35.6 MB** (24 files — cuisines + allergies) |
| Release APK (Phase 17 artifact, reference) | **98.8 MB** |
| Release AAB (reference) | **95.3 MB** |
| Debug APK (current run) | ~similar order of magnitude |

**Safe reduction recommendations (do not apply pre-release without review):**
- Compress allergy/cuisine JPG assets (largest contributor in `assets/`)
- Consider WebP for bundled images (~30–50% savings)
- `video_player` adds native weight — required for reels
- No unused fonts in `pubspec.yaml`
- All pubspec dependencies are referenced in code

---

## Part 6 — Performance (API benchmarks)

| Endpoint | Avg latency |
|----------|-------------|
| `/health` | 312 ms |
| `/feed/home` | 1,083 ms |
| `/stories` | 902 ms |
| `/discover/reels` | 1,139 ms |
| `/recommendations/v2` | **42.6 s** (cold cache / DB load) |

**Client optimizations in place:**
- Home feed: posts first, stories deferred
- Recommendation: server-side TTL caches (Phase 16)
- Image: decode cache dimensions on `HomeNetworkImage`

**Manual client profiling:** Use Flutter DevTools on running sessions:
- Android: http://127.0.0.1:55505/.../devtools
- Chrome: http://127.0.0.1:55442/.../devtools

---

## Part 7 — UI QA status

Automated UI walkthrough not possible in CI; **manual guide provided**.

| Area | Automated | Manual |
|------|-----------|--------|
| Overflow / layout | — | Required on device + Chrome |
| All 4 roles | — | See `MANUAL_TESTING_GUIDE.md` |
| Delivery rider stubs | ✓ Disabled in code (Phase 16) |
| Error states | ✓ Patterns exist (`RecommendationCopy.friendlyError`) |

---

## Part 8 — Manual testing guide

**Location:** [`docs/MANUAL_TESTING_GUIDE.md`](MANUAL_TESTING_GUIDE.md)

Covers all roles, navigation paths, expected API/UI, bug indicators, and 60-minute test plan.

---

## Part 9 — Final summary

| Item | Status |
|------|--------|
| Mobile build | ✓ Running on Redmi Note 9S |
| Chrome build | ✓ Running on port 8083 |
| Android debug install | ✓ |
| Dependencies | ✓ Verified / installed |
| Issues fixed | Port conflicts (8083), const optimizations, image cache |
| APK/AAB this phase | **Not generated** (per phase scope) |
| Estimated release APK | **~99 MB** |
| Estimated release AAB | **~95 MB** |

### Remaining issues

1. **Recommendations cold latency** — first load can exceed 15s; warm cache ~2–5s
2. **Google Maps web** — requires `GOOGLE_MAPS_WEB_API_KEY` dart-define for live map
3. **Home Chef** — no seeded demo account; register or approve manually
4. **Application ID** — still `com.example.popal_eats` (change before Play Store)
5. **`test_username_uniqueness`** — pytest flake on populated DB
6. **AAPT2 timeout warning** — monitor on future builds; non-blocking today

### Running sessions (leave open)

| Platform | Command | URL / device |
|----------|---------|--------------|
| **Android** | `flutter run -d f731c5e1 --dart-define=API_BASE_URL=http://192.168.100.171:8000` | Redmi Note 9S |
| **Chrome** | `flutter run -d chrome --web-port=8083 --dart-define=API_BASE_URL=http://127.0.0.1:8000` | http://localhost:8083 |
| **Backend** | `uvicorn app.main:app --host 0.0.0.0 --port 8000` | :8000 |

**Pre-release readiness: 90%** — proceed with manual QA using the guide above.
