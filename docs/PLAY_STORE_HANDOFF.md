# Play Store handoff — files for your firm

Use this when sending the Android app to whoever manages your **Google Play Console** account.

---

## What to send them

| # | File / item | Who creates it | Notes |
|---|-------------|----------------|-------|
| 1 | **`app-release.aab`** | You (build script below) | **Required** — only format accepted for new apps |
| 2 | **`upload-keystore.jks`** | You (`keytool`) | **Required** for first upload if not using Play App Signing enrollment flow they handle |
| 3 | **Keystore passwords** | You | Send **securely** (password manager / encrypted channel), not email |
| 4 | **Package name** | You | `com.popaleats.app` |
| 5 | **Version** | `pubspec.yaml` | `1.0.0+1` → name `1.0.0`, version code `1` |
| 6 | **Privacy policy URL** | You / firm | https://sites.google.com/view/popal-eats/home |
| 7 | **Terms URL** | You / firm | `https://popaleats.com/terms` |
| 8 | **Screenshots + icon** | You | Phone screenshots (min 2), feature graphic, 512×512 icon |
| 9 | **Content rating questionnaire** | Firm (Play Console) | IARC form in console |
| 10 | **Release SHA-1** | You | Add to Firebase after keystore is created (Google Sign-In) |

**Do not send:** `backend/.env`, database passwords, `SECRET_KEY`, or source code unless they need it for something else.

---

## Before building the AAB (blockers)

### 1. Change application ID (Play Store rejects `com.example.*`)

1. Pick final ID, e.g. **`com.popaleats.app`**
2. Firebase Console → Project **popal-eats-16b36** → Add Android app with that package name
3. Download new **`google-services.json`** → replace `frontend/android/app/google-services.json`
4. Update `frontend/android/app/build.gradle.kts`: `namespace` + `applicationId`
5. Move `MainActivity.kt` to matching package folder and update package line
6. Add **release SHA-1** fingerprint to Firebase (see below)

Until step 3 is done, keep `com.example.popal_eats` for local QA only.

### 2. Deploy backend first (app needs live API URL)

The release app is built with a fixed API URL. Deploy backend (see `BACKEND_DEPLOY_RAILWAY.md`), then use that HTTPS URL in the build.

Live API: `https://popal-eats-production.up.railway.app`

### 3. Create release keystore (one-time)

```powershell
cd frontend\android
keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

Copy `key.properties.example` → `key.properties`:

```properties
storePassword=YOUR_KEYSTORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=upload
storeFile=upload-keystore.jks
```

Get **SHA-1** for Firebase:

```powershell
keytool -list -v -keystore upload-keystore.jks -alias upload
```

Add that SHA-1 in Firebase → Project settings → Your Android app → SHA certificate fingerprints.

### 4. Production dart-defines

Copy `frontend/dart_defines.production.example.json` → `frontend/dart_defines.production.json` (gitignored) and set:

```json
{
  "API_BASE_URL": "https://YOUR_LIVE_API_URL",
  "GOOGLE_WEB_CLIENT_ID": "427158581376-o1jd1m4bem383gkoj7ji22sdnta6o98t.apps.googleusercontent.com"
}
```

(`GOOGLE_WEB_CLIENT_ID` must match backend `GOOGLE_CLIENT_ID`.)

---

## Build commands (Windows)

```powershell
cd frontend
flutter pub get
.\scripts\build_release.ps1 -ApiBaseUrl "https://YOUR_LIVE_API_URL"
```

Or with dart-defines file:

```powershell
flutter build appbundle --release --dart-define-from-file=dart_defines.production.json
```

**Output AAB:**

```
frontend\build\app\outputs\bundle\release\app-release.aab
```

Optional QA APK (same folder pattern):

```
frontend\build\app\outputs\flutter-apk\app-release.apk
```

---

## What your firm does in Play Console

1. Create app → **Production** or **Internal testing** track
2. **App integrity** → enable Play App Signing (recommended)
3. Upload **`app-release.aab`**
4. Store listing: name, short/full description, screenshots, category **Food & Drink**
5. **App content**: privacy policy URL, ads declaration, target audience
6. **Release** → review and roll out

---

## Checklist before upload

- [ ] Backend live at HTTPS URL
- [ ] AAB built with production `API_BASE_URL`
- [ ] Application ID is **not** `com.example.*`
- [ ] `google-services.json` matches package name
- [ ] Release keystore + `key.properties` used (not debug signing)
- [ ] Release SHA-1 in Firebase
- [ ] Google Sign-In tested on release APK
- [ ] Privacy policy & terms URLs live
- [ ] `targetSdk` 35 (already set)

---

## Support files in repo

| Path | Purpose |
|------|---------|
| `frontend/scripts/build_release.ps1` | Build APK + AAB |
| `frontend/android/key.properties.example` | Signing template |
| `frontend/dart_defines.production.example.json` | Production API / Firebase defines |
| `docs/BACKEND_DEPLOY_RAILWAY.md` | Host API on Railway + Supabase |
| `docs/PHASE_17_DEPLOYMENT.md` | Full technical deployment reference |
