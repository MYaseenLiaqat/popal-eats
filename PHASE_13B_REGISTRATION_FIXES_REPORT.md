# Phase 13B — Registration Flow & Business Signup Fixes

## 1. Root cause of each issue

| Issue | Root cause |
|-------|------------|
| **Customer registration / full_name** | `UserRegister` required `first_name`, `last_name`, `username` for all roles. Business signups reused the customer wizard and always sent personal fields. `full_name` was never sent by the frontend (correct), but missing identity fields caused validation failures; error formatting sometimes surfaced as `full_name: Field required` when legacy paths or empty derived names were involved. |
| **Restaurant reused customer form** | `signup_screen.dart` used a universal step 1 (first/last name, username, DOB) for every role, then a role-specific step 2. |
| **Home chef reused customer form** | Same universal wizard as restaurant. |
| **Empty cuisine dropdowns** | Cuisine fields were free-text `TextField` controllers, not wired to `CuisineCatalog`. |
| **Image fields as URLs** | Logo/cover/profile were plain URL text inputs with no picker. |
| **Username validation broken** | Frontend reserved-name list was incomplete vs backend; submit allowed registration when `_usernameAvailable` was `null` (check failed); `checkUsernameAvailable` did not surface API error messages on network failures; users could proceed without a confirmed available username. |
| **Business account creation** | Backend already created User + Restaurant / HomeChefProfile + Kitchen, but required customer identity fields in the schema before business logic could run. |

## 2. Files modified

### Backend
- `backend/app/schemas/user.py` — optional identity fields for business roles; auto-derive names/username/DOB; `description` / `biography` on profiles; `resolved_full_name` from business names
- `backend/app/services/auth_registration_service.py` — unique username allocation; restaurant `description` and `phone_number`; chef `biography`
- `backend/tests/test_auth_roles.py` — tests for business signup without personal fields

### Frontend
- `frontend/lib/screens/signup_screen.dart` — role-specific registration forms (redesigned)
- `frontend/lib/services/auth_service.dart` — optional identity fields; never sends `full_name`; improved username check parsing
- `frontend/lib/providers/auth_provider.dart` — optional register params; post-signup image upload
- `frontend/lib/utils/auth_validation.dart` — aligned reserved usernames with backend
- `frontend/lib/data/cuisine_catalog.dart` — added BBQ, Beverages
- `frontend/lib/widgets/registration_image_picker.dart` — new reusable image picker with preview

## 3. Screens redesigned

- **`SignupScreen`** — Step 0: role selection. Step 1: dedicated form per role:
  - **Customer**: first/last name, username (live check), email, phone, DOB, password
  - **Restaurant**: restaurant name, email, business phone, address, cuisine dropdown, password; optional reg number, description, logo/cover pickers
  - **Home chef**: display name, email, phone, kitchen address, cuisine dropdown, password; optional biography, profile image, food license

## 4. Registration payloads

### Customer (frontend → `POST /register`)
```json
{
  "role": "customer",
  "first_name": "Jane",
  "last_name": "Doe",
  "username": "jane.doe",
  "email": "jane@example.com",
  "phone": "+923001234567",
  "date_of_birth": "2000-06-15",
  "password": "SecurePass1!",
  "confirm_password": "SecurePass1!"
}
```
**Never sends `full_name`.** Backend sets `full_name = "Jane Doe"`.

### Restaurant
```json
{
  "role": "restaurant",
  "email": "owner@spicehub.com",
  "phone": "+923001234568",
  "password": "SecurePass1!",
  "confirm_password": "SecurePass1!",
  "restaurant_profile": {
    "restaurant_name": "Spice Hub",
    "restaurant_address": "123 Mall Road, Lahore",
    "cuisine_type": "pakistani",
    "description": "Optional description",
    "business_registration_number": "REG-123"
  }
}
```
Backend auto-generates `first_name`, `last_name`, `username` (from email, uniquified), `date_of_birth` placeholder; `full_name = restaurant_name`.

### Home chef
```json
{
  "role": "home_chef",
  "email": "chef@example.com",
  "phone": "+923001234569",
  "password": "SecurePass1!",
  "confirm_password": "SecurePass1!",
  "home_chef_profile": {
    "chef_display_name": "Chef Sana",
    "cuisine_specialty": "desserts",
    "kitchen_address": "45 Garden Town",
    "biography": "Optional bio",
    "food_license": "LIC-456"
  }
}
```
Backend auto-generates identity fields; `full_name = chef_display_name`.

## 5. Validation fixes

- **Backend**: `first_name` / `last_name` / `username` / `phone` / `date_of_birth` optional at field level; required only for `customer` in `@model_validator(mode="after")`.
- **Backend**: `_allocate_unique_username()` suffixes collisions (`user_2`, etc.).
- **Frontend**: Reserved usernames synced with `backend/app/utils/username.py`.
- **Frontend**: Customer submit requires `_usernameAvailable == true` (not merely “not false”).
- **Frontend**: Clearer username helper text for taken / unavailable / invalid states.

## 6. Upload implementation

- New `RegistrationImagePicker` uses `FilePicker.platform.pickFiles(type: FileType.image, withData: true)`.
- Local preview via `Image.memory`.
- No URL fields on signup forms.
- After successful register + login, `AuthProvider._uploadRegistrationImages()`:
  - Restaurant: `POST /restaurants/{id}/image` (cover preferred, else logo)
  - Home chef: `POST /home-chef/me/profile/image`
- Upload failures are non-blocking; registration still succeeds.

## 7. Cuisine dropdown source

- `CuisineCatalog.cuisines` in `frontend/lib/data/cuisine_catalog.dart` (same catalog used by onboarding/recommendations).
- Dropdown sends cuisine **key** slug (e.g. `pakistani`, `turkish`, `bbq`).
- Added missing entries: **BBQ**, **Beverages**.

## 8. Verification status

| Check | Status |
|-------|--------|
| Pydantic schema validation (all 3 roles, no `full_name` in payload) | **PASS** (local Python validation) |
| `dart analyze` on changed files | **PASS** (1 deprecation info on dropdown `value`) |
| `pytest tests/test_auth_roles.py` | **BLOCKED** — Neon DB data transfer quota exceeded |
| Live `POST /register` + username check | **BLOCKED** — same DB quota (`HTTP 500` on username check) |
| Pending screens (`BusinessAccountStatusScreen`) | **Unchanged** — already wired in `main.dart` for `pending` / `rejected` / `suspended` |

**Manual QA** (once DB quota is restored): run through customer, restaurant, and home chef signup in the app; confirm customer → active shell, business → pending screen after login.

### Account status behavior (unchanged, confirmed in code)
- Customer → `account_status: active`
- Restaurant → User + Restaurant, `pending`
- Home chef → User + HomeChefProfile + Kitchen, `pending`
