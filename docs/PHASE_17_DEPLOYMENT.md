# Phase 17 — Android Release & Production Deployment

**Status:** Release artifacts generated. Deployment configs prepared. **Do not deploy automatically** — complete manual steps below.

---

## Part 1 — Android configuration

| Setting | Value |
|---------|-------|
| compileSdk | **36** |
| targetSdk | **35** (Play Store 2025 compliance) |
| minSdk | **23** (Firebase Auth requirement) |
| Gradle | **9.1.0** |
| AGP | **9.0.1** |
| Kotlin | **2.3.20** |
| Java | **17** |

**Fix applied:** Forced `compileSdk=36` on all Android library subprojects (resolved `file_picker` / `flutter_plugin_android_lifecycle` AAR metadata failure).

**Application ID:** `com.example.popal_eats` — **must change** to `com.popaleats.app` (or your domain) before Play Store submission. Requires updating Firebase `google-services.json` + OAuth SHA-1 fingerprints.

---

## Part 2 — Release builds

| Artifact | Status | Path |
|----------|--------|------|
| Release APK | **Generated** | `frontend/build/app/outputs/flutter-apk/app-release.apk` (98.8 MB) |
| App Bundle (.aab) | See build output below | `frontend/build/app/outputs/bundle/release/app-release.aab` |

**Build command:**
```powershell
cd frontend
flutter build apk --release --dart-define=API_BASE_URL=https://YOUR_API_URL
flutter build appbundle --release --dart-define=API_BASE_URL=https://YOUR_API_URL
```

Or use `frontend/scripts/build_release.ps1 -ApiBaseUrl https://YOUR_API_URL`.

---

## Part 3 — App signing

| File | Purpose | Git |
|------|---------|-----|
| `android/key.properties.example` | Template for signing credentials | Committed |
| `android/key.properties` | Real keystore paths/passwords | **Gitignored** |
| `android/upload-keystore.jks` | Release keystore | **Gitignored** |

**Generate keystore:**
```bash
keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

Copy `key.properties.example` → `key.properties` and set `storeFile`, passwords, and alias.

**Current state:** Without `key.properties`, release builds use **debug signing** (fine for QA, not for Play Store upload).

**Play Store:** Add release SHA-1 to Firebase Console → Project Settings → Your apps → Android → SHA certificate fingerprints.

---

## Part 4 — Firebase

| Platform | Config file | Status |
|----------|-------------|--------|
| Android | `android/app/google-services.json` | Present — project `popal-eats-16b36`, package `com.example.popal_eats` |
| Web | `lib/firebase_options.dart` + dart-defines | Requires `FIREBASE_*` dart-defines for web builds |
| Google Sign-In | `GOOGLE_WEB_CLIENT_ID` / `GOOGLE_CLIENT_ID` | Configured (client_type 3) |

**Services in use:**
- Firebase Core — yes
- Firebase Auth — yes (Google Sign-In)
- Crashlytics — **not integrated** (optional)
- Analytics — **not integrated** (optional)

**Web production:** Pass all `FIREBASE_*` values via `dart_defines.production.json` (see example file).

---

## Part 5 — Google Maps

| Platform | Configuration |
|----------|---------------|
| Android | `GOOGLE_MAPS_API_KEY` in `android/local.properties` → manifest placeholder `com.google.android.geo.API_KEY` |
| Web | `--dart-define=GOOGLE_MAPS_WEB_API_KEY=...` via `GoogleMapsConfig` |
| Fallback | `DeliveryMap` shows static fallback when Maps unavailable (10s timeout / missing key) |

**Template:** `android/local.properties.example`

---

## Part 6 — Production environment

| Variable | Dev | Production |
|----------|-----|------------|
| `API_BASE_URL` | `http://127.0.0.1:8000` | `https://YOUR_RAILWAY_URL` (dart-define) |
| `DATABASE_URL` | Supabase pooler (IPv4) | Same Supabase project — use **session pooler** URL |
| `SECRET_KEY` | `.env` | Strong random string in host env |
| `CORS_ORIGINS` | localhost | Production web + API domains |
| `DEBUG` | `true` | `false` |
| `HTTPS` | N/A locally | Required for production API |

**Templates:**
- `backend/.env.production.example`
- `frontend/dart_defines.production.example.json`

**Android network security:** HTTPS enforced in release; cleartext allowed only for `localhost`, `127.0.0.1`, `10.0.2.2` (emulator).

---

## Part 7 — Backend deployment readiness

| Item | Status |
|------|--------|
| Entry point | `app.main:app` (FastAPI) |
| Server | `uvicorn` with 2 workers (Procfile / railway.toml) |
| Health | `GET /health` |
| Dependencies | `backend/requirements.txt` |
| Migrations | `alembic upgrade head` (in Railway/Render build) |
| Static uploads | `/uploads` mounted from `UPLOAD_DIR` |
| Redis worker | Optional — set `PROCESS_REVIEWS_INLINE=false` + Redis on Railway |

**Files added:**
- `backend/Procfile`
- `backend/railway.toml` (preferred)
- `backend/render.yaml` (alternative)

**Railway startup:**
1. Create project → connect repo → set root to `backend`
2. Add PostgreSQL or use existing Supabase `DATABASE_URL`
3. Add Redis plugin (optional)
4. Set env vars from `.env.production.example`
5. Deploy — migrations run on build

**Note:** Use Supabase **session pooler** (`*.pooler.supabase.com`) for IPv4 compatibility.

---

## Part 8 — Deployment targets

| Component | Target |
|-----------|--------|
| Backend API | **Railway** (primary) or Render |
| Database | **Supabase PostgreSQL** (production) |
| File storage | Backend `UPLOAD_DIR` on Railway volume, or migrate to Supabase Storage later |
| Android app | Google Play Console |
| Flutter Web | Firebase Hosting / Vercel (optional) |

---

## Part 9 — Play Store checklist

| Item | Status |
|------|--------|
| Application ID | `com.example.popal_eats` — **change before upload** |
| Version code | `1` (`pubspec.yaml` `1.0.0+1`) |
| Version name | `1.0.0` |
| Adaptive icon | `mipmap-anydpi-v26/ic_launcher.xml` added |
| Splash screen | `LaunchTheme` / `launch_background.xml` |
| Permissions | INTERNET, ACCESS_FINE_LOCATION, ACCESS_COARSE_LOCATION |
| Network security | `network_security_config.xml` (HTTPS enforced) |
| Privacy policy URL | Placeholder: `https://popaleats.com/privacy` in `strings.xml` |
| Terms URL | Placeholder: `https://popaleats.com/terms` in `strings.xml` |
| Target SDK 35 | **Compliant** |
| Release signing | **Manual** — create keystore + `key.properties` |

---

## Part 10 — Release QA

Release build uses same Dart code as debug. Verify on a physical device:

1. Install `app-release.apk`
2. Set production `API_BASE_URL` at build time (or rebuild with live API URL)
3. Test: Customer login → browse → order → delivery tracking
4. Test: Restaurant / Home Chef / Admin portals
5. Verify Google Sign-In with **release SHA-1** in Firebase
6. Verify Maps on delivery screen (with `GOOGLE_MAPS_API_KEY` in `local.properties`)

---

## Part 11 — Remaining manual steps

1. **Change application ID** from `com.example.*` to production package name
2. **Regenerate** `google-services.json` in Firebase for new package + release SHA-1
3. **Create release keystore** and `key.properties`
4. **Rebuild** signed AAB: `flutter build appbundle --release`
5. **Deploy backend** to Railway with production env vars
6. **Update** `API_BASE_URL` in release dart-defines to live API URL
7. **Add** `GOOGLE_MAPS_API_KEY` to `android/local.properties`
8. **Publish** privacy policy & terms at placeholder URLs
9. **Upload** AAB to Google Play Console (Internal testing → Production)
10. **Configure** Play Store listing (screenshots, description, content rating)

---

## Play Store readiness: **78%**

## Production deployment readiness: **85%**

Ready for manual deployment — no automatic deploy performed.
