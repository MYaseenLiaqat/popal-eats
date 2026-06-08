# Run Popal Eats locally (Windows)

Run **one command per line**. Do not paste multiple commands on the same line.

## Terminal 1 — Backend

```powershell
cd C:\Users\user\OneDrive\Desktop\popaleats\popal-eats
.\scripts\start_backend.ps1
```

Or manually:

```powershell
cd backend
.\venv\Scripts\activate
python -m uvicorn app.main:app --reload --host 127.0.0.1 --port 8000
```

## Terminal 2 — Frontend (Chrome)

From **project root**:

```powershell
cd C:\Users\user\OneDrive\Desktop\popaleats\popal-eats
.\scripts\flutter_pub_get.ps1
.\scripts\run_web.ps1
```

From **frontend/** folder:

```powershell
cd C:\Users\user\OneDrive\Desktop\popaleats\popal-eats\frontend
.\pub_get.ps1
.\run_web.ps1
```

## If `flutter` is not recognized

Use project scripts (always work):

```powershell
.\scripts\flutter.ps1 --version
.\scripts\flutter_pub_get.ps1
.\scripts\run_web.ps1
```

After **Developer: Reload Window**, new terminals auto-load Flutter via `PowerShell (Popal Eats)` profile.

## Common mistakes

| Wrong | Right |
|-------|-------|
| `flutter pub get` (no PATH) | `.\scripts\flutter_pub_get.ps1` |
| `.\scripts\flutter.ps1 run -d chrome` from project root | `.\scripts\run_web.ps1` from root, or `.\run_web.ps1` from frontend |
| `.\scripts\run_web.ps1` from **frontend/** folder | `.\run_web.ps1` from frontend, or `cd ..` then `.\scripts\run_web.ps1` |
| `.\venv\Scripts\activatepip install ...` | Two lines: `activate` then `pip install ...` |
