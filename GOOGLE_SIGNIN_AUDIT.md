# Google Sign-In Audit

**Date:** 2026-06-05  
**Firebase project:** `popal-eats-16b36`  
**Android package:** `com.example.popal_eats`

---

## Root cause — why the Google button was hidden

The login screen shows the Google button only when:

```
auth.googleSignInAvailable
  → GoogleAuthService.isConfigured
  → DefaultFirebaseOptions.isConfigured
```

**Before fix:** `isConfigured` required compile-time dart-defines (`FIREBASE_API_KEY`, `FIREBASE_APP_ID`, `FIREBASE_PROJECT_ID`). Running without `--dart-define=...` made `isConfigured == false`, so the login screen showed the configuration warning instead of the button.

**After fix:** Android uses embedded values from `google-services.json` when dart-defines are absent. `isConfigured` is `true` on Android without extra flags.

---

## PASS / FAIL summary

| Area | Status | Notes |
|------|--------|-------|
| Android Firebase setup | **PASS** | `google-services.json` present; Gradle plugin added |
| Flutter Firebase setup | **PASS** (Android) / **FAIL** (Web) | Android auto-configured; Web still needs dart-defines |
| Backend Google auth setup | **CONDITIONAL** | Code ready; requires `GOOGLE_CLIENT_ID` in `.env` |
| Missing Firebase values | See below | |
| Android Google login should work | **LIKELY YES** | After rebuild; SHA-1 may still be required |
| Web Google login should work | **NO** (without dart-defines) | Web Firebase app not configured in repo |

---

## 1. google-services.json detection

| Check | Status |
|-------|--------|
| File at `frontend/android/app/google-services.json` | **PASS** |
| `package_name` matches `applicationId` (`com.example.popal_eats`) | **PASS** |
| `project_id` | `popal-eats-16b36` |
| `mobilesdk_app_id` | `1:427158581376:android:e08914afc33ff7e26f7665` |

---

## 2. Android Gradle setup

| File | Change | Status |
|------|--------|--------|
| `settings.gradle.kts` | `com.google.gms.google-services` plugin 4.4.2 | **ADDED** |
| `app/build.gradle.kts` | Apply `com.google.gms.google-services` | **ADDED** |
| `build.gradle.kts` (root) | No change needed | **PASS** |

---

## 3. Flutter packages

| Package | pubspec.yaml | Status |
|---------|--------------|--------|
| `firebase_core` | `^3.8.1` | **PASS** |
| `firebase_auth` | `^5.3.4` | **PASS** |
| `google_sign_in` | `^6.2.2` | **PASS** |

---

## 4. Firebase initialization (`main.dart`)

| Check | Status |
|-------|--------|
| `WidgetsFlutterBinding.ensureInitialized()` | **PASS** |
| `GoogleAuthService.instance.ensureInitialized()` when configured | **PASS** |
| Uses `DefaultFirebaseOptions.currentPlatform` | **PASS** |

---

## 5. `google_auth_service.dart`

| Check | Status |
|-------|--------|
| `isConfigured` gate | **PASS** |
| `Firebase.initializeApp` | **PASS** |
| `serverClientId` on Android (for ID token) | **FIXED** |
| Web `clientId` | **PASS** (needs dart-defines on web) |

**Web client ID (OAuth type 3):**  
`427158581376-o1jd1m4bem383gkoj7ji22sdnta6o98t.apps.googleusercontent.com`

---

## 6. Backend `google_auth_service.py`

| Check | Status |
|-------|--------|
| Verifies token via Google `tokeninfo` | **PASS** |
| Checks `aud` against `settings.google_client_id` | **PASS** |
| Creates/links user by `google_id` / email | **PASS** |
| Returns 503 if `GOOGLE_CLIENT_ID` empty | **PASS** |

**Action required:** Set in `backend/.env`:

```
GOOGLE_CLIENT_ID=427158581376-o1jd1m4bem383gkoj7ji22sdnta6o98t.apps.googleusercontent.com
```

(Value documented in `.env.example`.)

---

## 7. Backend `auth.py`

| Check | Status |
|-------|--------|
| `POST /auth/google` accepts `id_token` | **PASS** |
| Issues JWT via `_issue_tokens` | **PASS** |

---

## 8. Missing / optional Firebase values

| Value | Android | Web |
|-------|---------|-----|
| `FIREBASE_API_KEY` | Embedded from JSON | **Required** dart-define |
| `FIREBASE_APP_ID` | Embedded from JSON | **Required** dart-define |
| `FIREBASE_PROJECT_ID` | Embedded from JSON | **Required** dart-define |
| `GOOGLE_WEB_CLIENT_ID` | Embedded default | **Required** dart-define |
| `FIREBASE_AUTH_DOMAIN` | Auto-derived | Optional |
| `FIREBASE_STORAGE_BUCKET` | Embedded from JSON | Optional |
| Android OAuth client (type 1) in JSON | **Not present** | N/A |
| `GOOGLE_CLIENT_ID` in backend `.env` | N/A | **Required** for API |

### google-services.json note

The file only lists **client_type 3** (Web client). There is no **client_type 1** (Android OAuth) entry. Google Sign-In on Android often still works via `google-services` + `serverClientId`, but if sign-in fails at runtime:

1. Add your debug/release **SHA-1** in Firebase Console → Project settings → Android app.
2. Re-download `google-services.json` (should then include an Android OAuth client).

---

## 9. Should Google login work?

### Android

**Expected: YES** after:

1. Rebuild app (`flutter run` on device/emulator).
2. Set `GOOGLE_CLIENT_ID` in backend `.env` and restart API.
3. Enable **Google** provider in Firebase Authentication console.

**Remaining runtime risks:** missing SHA-1 fingerprint, Google provider disabled in Firebase.

### Web

**Expected: NO** without dart-defines — no web Firebase app config is checked in. Run with:

```bash
flutter run -d chrome \
  --dart-define=FIREBASE_API_KEY=... \
  --dart-define=FIREBASE_APP_ID=... \
  --dart-define=FIREBASE_PROJECT_ID=popal-eats-16b36 \
  --dart-define=GOOGLE_WEB_CLIENT_ID=427158581376-o1jd1m4bem383gkoj7ji22sdnta6o98t.apps.googleusercontent.com
```

(Register a Web app in Firebase Console to obtain web `appId` and `apiKey`.)

---

## Files modified

- `frontend/android/settings.gradle.kts` — Google Services plugin
- `frontend/android/app/build.gradle.kts` — apply plugin
- `frontend/lib/firebase_options.dart` — embedded Android config + `isConfigured` fix
- `frontend/lib/services/google_auth_service.dart` — `serverClientId` on Android
- `backend/.env.example` — documented `GOOGLE_CLIENT_ID`

## Files verified (no change)

- `frontend/pubspec.yaml`
- `frontend/lib/main.dart`
- `frontend/lib/screens/login_screen.dart`
- `backend/app/services/google_auth_service.py`
- `backend/app/routes/auth.py`
