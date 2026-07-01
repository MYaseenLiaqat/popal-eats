# Production go-live — what to do now

Quick checklist for **Popal Eats** as of your current setup.

| Item | Status |
|------|--------|
| Backend API (Railway) | Live — `https://popal-eats-production.up.railway.app` |
| Database (Supabase) | Connected |
| Demo / QA users | Cleaned (13 real users remain) |
| Android AAB | Built — `frontend/build/app/outputs/bundle/release/app-release.aab` |
| Package name | `com.popaleats.app` |
| Privacy policy | https://sites.google.com/view/popal-eats/home |
| Admin web (Vercel) | **You need to deploy** (steps below) |

---

## 1. Send Play Store files to your firm

Send these **securely** (password manager for secrets):

| Send | Path / value |
|------|----------------|
| App bundle | `frontend\build\app\outputs\bundle\release\app-release.aab` |
| Keystore | `frontend\android\upload-keystore.jks` |
| Keystore passwords | From your `key.properties` |
| Package name | `com.popaleats.app` |
| Privacy policy URL | https://sites.google.com/view/popal-eats/home |

**Do not send:** `backend/.env`, database password, or `SECRET_KEY`.

More detail: [PLAY_STORE_HANDOFF.md](./PLAY_STORE_HANDOFF.md)

---

## 2. Deploy admin dashboard on the web (Vercel)

The admin UI is the same Flutter app — it shows the admin panel when you log in as `admin@popaleats.com`.

### Build (on your PC)

```powershell
cd C:\Users\user\OneDrive\Desktop\popaleats\popal-eats\frontend
.\scripts\deploy_admin_web.ps1 -CreateZip
```

### Upload on Vercel website (no CLI)

1. Sign in at [vercel.com](https://vercel.com)
2. Open **[vercel.com/drop](https://vercel.com/drop)**
3. Drag **`frontend\build\web`** (or **`build\popal-eats-admin-web.zip`**) onto the page
4. Project name: `popal-eats-admin` → **Deploy**
5. Copy the URL (e.g. `https://popal-eats-admin.vercel.app`)

Full steps: [ADMIN_WEB_VERCEL.md](./ADMIN_WEB_VERCEL.md)

### Allow admin site to call the API

1. Railway → your backend service → **Variables**
2. Set `CORS_ORIGINS` to your Vercel URL, e.g.:

   ```
   https://popal-eats-admin.vercel.app
   ```

   (Comma-separate if you add more origins later.)

3. Save — Railway will restart the service.

### Log in as admin

If you need to set or reset the admin password (from `backend/`):

```powershell
.\venv\Scripts\python.exe scripts\seed_admin.py admin@popaleats.com YourSecurePassword123
```

Open your Vercel URL → sign in with that email/password.

More detail: [ADMIN_WEB_VERCEL.md](./ADMIN_WEB_VERCEL.md)

---

## 3. Test on your phone (optional)

If install failed with `INSTALL_FAILED_USER_RESTRICTED` (Xiaomi / MIUI):

1. **Settings → Additional settings → Developer options**
2. Enable **Install via USB** (or **USB debugging (Security settings)**)
3. Reconnect USB and run:

```powershell
cd frontend
flutter install --release --dart-define=API_BASE_URL=https://popal-eats-production.up.railway.app
```

Or install the APK from `build\app\outputs\flutter-apk\app-release.apk` manually.

---

## 4. Rebuild Android after future changes

```powershell
cd frontend
.\scripts\prepare_play_store.ps1 -ApiBaseUrl "https://popal-eats-production.up.railway.app"
```

Send the new `app-release.aab` to your firm for each Play Store update.

---

## 5. Rebuild admin web after future changes

```powershell
cd frontend
.\scripts\deploy_admin_web.ps1 -CreateZip
```

Upload the new folder or zip at [vercel.com/drop](https://vercel.com/drop).

---

## Reference

| Doc | Purpose |
|-----|---------|
| [BACKEND_DEPLOY_RAILWAY.md](./BACKEND_DEPLOY_RAILWAY.md) | Railway + env vars |
| [ADMIN_WEB_VERCEL.md](./ADMIN_WEB_VERCEL.md) | Admin web deploy |
| [PLAY_STORE_HANDOFF.md](./PLAY_STORE_HANDOFF.md) | Play Console handoff |
