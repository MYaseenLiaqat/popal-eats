# Backend deployment — Railway + Supabase

Host the FastAPI backend on the public internet so the Play Store app can call it.

**Recommended stack (already in repo):**

| Piece | Service | You already have |
|-------|---------|------------------|
| API | **Railway** | Deploy from GitHub |
| Database | **Supabase PostgreSQL** | Yes (pooler URL in `.env`) |
| Redis (optional) | Railway Redis or Upstash | For async review queue |

---

## Step 1 — Railway project

1. Go to [railway.app](https://railway.app) → New project → **Deploy from GitHub repo**
2. Select **`popal-eats`** repository
3. Set **Root directory** / service path to: **`backend`**
4. Railway reads `backend/railway.toml` automatically:
   - Build: `pip install -r requirements.txt && alembic upgrade head`
   - Start: `uvicorn app.main:app --host 0.0.0.0 --port $PORT --workers 2`
   - Health: `GET /health`

5. After deploy, copy the public URL, e.g. `https://popal-eats-production.up.railway.app`

Test: open `https://YOUR_URL/health` → should return JSON OK.

---

## Step 2 — Environment variables (Railway dashboard)

Set these in **Variables** for the backend service. Use your real values from `backend/.env` where noted.

| Variable | Value |
|----------|--------|
| `DATABASE_URL` | Supabase **session pooler** URL (`*.pooler.supabase.com:5432`) |
| `SECRET_KEY` | **New** long random string (32+ chars) — do not reuse dev key |
| `DEBUG` | `false` |
| `LOG_LEVEL` | `INFO` |
| `CORS_ORIGINS` | `https://popaleats.com` (add web admin URLs if any) |
| `GOOGLE_CLIENT_ID` | `427158581376-o1jd1m4bem383gkoj7ji22sdnta6o98t.apps.googleusercontent.com` |
| `PROCESS_REVIEWS_INLINE` | `true` (simplest — no Redis) **or** `false` + Redis |
| `OCR_ENGINE` | `tesseract` |
| `UPLOAD_DIR` | `/app/uploads` |
| `MAX_UPLOAD_MB` | `10` |

**Optional (if using Redis worker):**

| Variable | Value |
|----------|--------|
| `REDIS_URL` | From Railway Redis plugin |
| `PROCESS_REVIEWS_INLINE` | `false` |
| `RQ_QUEUE_NAME` | `popal_eats` |

Template: `backend/.env.production.example`

---

## Step 3 — Database migrations

Migrations run automatically on Railway build (`alembic upgrade head` in `railway.toml`).

Your Supabase DB already has data from local dev — migrations are idempotent. For a **clean production DB**, use a new Supabase project and run migrations there instead.

---

## Step 4 — File uploads (images, menus)

Railway ephemeral disk is cleared on redeploy. Options:

1. **MVP:** `UPLOAD_DIR=/app/uploads` + Railway **volume** mounted at `/app/uploads`
2. **Later:** Supabase Storage or S3

For demo/launch, a volume is enough.

---

## Step 5 — Point the Android app at production

After Railway URL is live:

```powershell
cd frontend
flutter build appbundle --release --dart-define=API_BASE_URL=https://YOUR_RAILWAY_URL
```

Use the **same URL** in `dart_defines.production.json` for future builds.

---

## Alternative: Render

If you prefer Render, use `backend/render.yaml` and the same env vars in the Render dashboard. Process is equivalent.

---

## Post-deploy verification

```bash
curl https://YOUR_RAILWAY_URL/health
curl https://YOUR_RAILWAY_URL/docs   # OpenAPI (disable in prod if desired)
```

From a phone with the release APK: login, browse restaurants, place test order.

---

## Security reminders

- Never commit `backend/.env` to GitHub
- Rotate `SECRET_KEY` for production (invalidates existing JWTs)
- Keep `DEBUG=false`
- Use HTTPS only (Railway provides TLS)
