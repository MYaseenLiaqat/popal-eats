# Popal Eats Flutter Client

Connects to the FastAPI backend at `http://127.0.0.1:8000` by default.

## Setup

```powershell
cd frontend
flutter pub get
```

## Run

Start the backend first, then:

```powershell
flutter run
```

### Android emulator

Use a custom API host:

```powershell
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000
```

## API layer

| File                                   | Purpose                           |
| -------------------------------------- | --------------------------------- |
| `lib/services/api_client.dart`         | Central HTTP client + JWT storage |
| `lib/services/auth_service.dart`       | `/register`, `/login`, `/me`      |
| `lib/services/category_service.dart`   | Categories                        |
| `lib/services/restaurant_service.dart` | Restaurants                       |
| `lib/services/dish_service.dart`       | Dishes                            |
| `lib/services/review_service.dart`     | Reviews                           |

Token is stored in `shared_preferences` and attached as `Authorization: Bearer`.
