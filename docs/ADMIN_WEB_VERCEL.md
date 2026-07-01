# Admin dashboard on the web (Vercel — upload from browser)

The **admin dashboard is not a separate app**. It is the same Flutter project (`frontend/`). When you log in as an **admin** user, the app shows `AdminShell` automatically.

---

## Architecture

| Piece | Where |
|-------|--------|
| Admin UI | Flutter **web** build (`frontend/build/web/`) |
| API | `https://popal-eats-production.up.railway.app` |
| Database | Supabase (already connected) |

---

## Step 1 — Build on your PC

```powershell
cd C:\Users\user\OneDrive\Desktop\popaleats\popal-eats\frontend
.\scripts\deploy_admin_web.ps1
```

Optional — create a zip for upload (easier on slow internet):

```powershell
.\scripts\deploy_admin_web.ps1 -CreateZip
```

That produces `frontend\build\web\` (folder) and optionally `frontend\build\popal-eats-admin-web.zip`.

Confirm `build\web` contains **`index.html`** and **`vercel.json`** at the top level.

---

## Step 2 — Upload on Vercel website (no CLI)

1. Create a free account at [vercel.com](https://vercel.com) if you don’t have one.
2. Open **[vercel.com/drop](https://vercel.com/drop)**.
3. Drag **`frontend\build\web`** onto the page  
   — or upload **`frontend\build\popal-eats-admin-web.zip`** if you used `-CreateZip`.
4. Choose your team (usually your personal account).
5. **Project name:** `popal-eats-admin` (or any name).
6. Click **Deploy** and wait until it finishes.
7. Copy your live URL, e.g. `https://popal-eats-admin.vercel.app`.

**Important:** Vercel Drop deploys **static files only** — you must build Flutter locally first (Step 1). Do not upload the whole `frontend` repo.

**Updates later:** Each new Drop creates a **new** project. To update the same URL without CLI, use the Vercel dashboard for that project → **Deployments** → redeploy, or connect GitHub later for auto-deploys.

---

## Step 3 — Allow Vercel in Railway CORS

1. Railway → your backend service → **Variables**
2. Edit `CORS_ORIGINS` to include your Vercel URL:

```
https://popal-eats-admin.vercel.app
```

(Use your actual URL from Step 2.)

3. Save — Railway restarts the service.

---

## Step 4 — Admin login

Use an **admin** account in the database (e.g. `admin@popaleats.com`).

If you need to set/reset the password (from `backend/`):

```powershell
.\venv\Scripts\python.exe scripts\seed_admin.py admin@popaleats.com YourSecurePassword123
```

Open your Vercel URL → log in with that email/password → you should land in the **admin dashboard**.

---

## When you change the app later

1. Rebuild:

```powershell
cd frontend
.\scripts\deploy_admin_web.ps1 -CreateZip
```

2. Go to [vercel.com/drop](https://vercel.com/drop) again with the new folder/zip, **or** use the Vercel dashboard for your existing project if you set up redeploy there.

---

## Optional — deploy with CLI

If you prefer the terminal later:

```powershell
npm install -g vercel
vercel login
cd frontend\build\web
vercel --prod
```

---

## Notes

- **Email/password login** works with only `API_BASE_URL` baked into the build.
- **Google Sign-In** on web needs extra Firebase dart-defines.
- The same web deploy works for customer/restaurant portals if those roles log in.
