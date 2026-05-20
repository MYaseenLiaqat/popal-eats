# Backend (FastAPI)

## Install

From the `backend` folder:

```powershell
python -m venv .venv
.\.venv\Scripts\activate
pip install fastapi uvicorn sqlalchemy psycopg2-binary python-dotenv pydantic
pip install -r requirements.txt
```

(`requirements.txt` matches that set so installs stay reproducible.)

## Configure

Put your Neon (or other Postgres) URL in `backend/.env`:

```env
DATABASE_URL=postgresql://user:pass@host/dbname?sslmode=require
```

`app/config.py` loads this file from the `backend` directory automatically.

## Run the API

Still inside `backend` with the venv activated:

```powershell
python -m uvicorn app.main:app --reload --host 127.0.0.1 --port 8000
```

Then open:

- http://127.0.0.1:8000 — root JSON
- http://127.0.0.1:8000/docs — Swagger UI

Importing `app.database` (e.g. when you add routes that use `get_db`) requires a valid `DATABASE_URL`. The root route in `main.py` does not touch the DB.
