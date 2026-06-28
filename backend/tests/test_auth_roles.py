"""Authentication and registration tests."""

from __future__ import annotations

import uuid
from datetime import date, timedelta

import pytest
from jose import jwt

from app.config import ALGORITHM, SECRET_KEY
from app.core.roles import CUSTOMER, HOME_CHEF, RESTAURANT, normalize_role
from app.core.security import create_access_token, decode_access_token
from app.models.home_chef_profile import HomeChefProfile
from app.models.restaurant import Restaurant
from app.models.user import User
from app.utils.password import validate_password
from app.utils.username import validate_username


def _register_payload(**overrides):
    from tests.conftest import unique_email, unique_username

    base = {
        "role": "customer",
        "first_name": "Test",
        "last_name": "User",
        "username": unique_username(),
        "email": unique_email(),
        "phone": f"+92300{uuid.uuid4().int % 10_000_000:07d}",
        "date_of_birth": "2000-06-15",
        "password": "SecurePass1!",
        "confirm_password": "SecurePass1!",
    }
    base.update(overrides)
    return base


def test_customer_registration_and_login(client, db):
    payload = _register_payload()
    r = client.post("/register", json=payload)
    assert r.status_code == 201, r.text
    body = r.json()
    assert body["role"] == CUSTOMER
    assert body["account_status"] == "active"

    login = client.post("/login", json={"email": payload["email"], "password": payload["password"]})
    assert login.status_code == 200
    token_body = login.json()
    assert token_body["role"] == CUSTOMER
    assert token_body["account_status"] == "active"
    assert "access_token" in token_body

    claims = decode_access_token(token_body["access_token"])
    assert claims["uid"] == body["id"]
    assert normalize_role(claims["role"]) == CUSTOMER
    assert "iat" in claims


def test_restaurant_registration_pending(client, db):
    payload = _register_payload(
        role="restaurant",
        restaurant_profile={
            "restaurant_name": "Spice Hub",
            "restaurant_address": "123 Mall Road, Lahore",
            "cuisine_type": "Pakistani",
        },
    )
    r = client.post("/register", json=payload)
    assert r.status_code == 201, r.text
    body = r.json()
    assert body["role"] == RESTAURANT
    assert body["account_status"] == "pending"

    user = db.query(User).filter(User.email == payload["email"]).first()
    restaurant = db.query(Restaurant).filter(Restaurant.owner_id == user.id).first()
    assert restaurant is not None
    assert restaurant.approval_status == "pending"

    login = client.post("/login", json={"email": payload["email"], "password": payload["password"]})
    assert login.status_code == 200
    assert login.json()["account_status"] == "pending"


def test_home_chef_registration_pending(client, db):
    payload = _register_payload(
        role="home_chef",
        home_chef_profile={
            "chef_display_name": "Chef Sana",
            "cuisine_specialty": "Desserts",
            "kitchen_address": "45 Garden Town, Lahore",
        },
    )
    r = client.post("/register", json=payload)
    assert r.status_code == 201, r.text
    body = r.json()
    assert body["role"] == HOME_CHEF
    assert body["account_status"] == "pending"

    profile = db.query(HomeChefProfile).filter(HomeChefProfile.user_id == body["id"]).first()
    assert profile is not None
    assert profile.display_name == "Chef Sana"


def test_username_uniqueness(client):
    payload = _register_payload()
    assert client.post("/register", json=payload).status_code == 201
    payload["email"] = f"other_{uuid.uuid4().hex[:6]}@example.com"
    r = client.post("/register", json=payload)
    assert r.status_code == 400
    assert "Username" in r.json()["error"]


def test_email_uniqueness_case_insensitive(client):
    payload = _register_payload(email="Mixed@Example.com")
    assert client.post("/register", json=payload).status_code == 201
    payload["username"] = f"u{uuid.uuid4().hex[:6]}"
    payload["email"] = "mixed@example.com"
    r = client.post("/register", json=payload)
    assert r.status_code == 400


def test_password_validation_rules():
    with pytest.raises(ValueError):
        validate_password("short1!")
    with pytest.raises(ValueError):
        validate_password("alllowercase1!")
    with pytest.raises(ValueError):
        validate_password("ALLUPPERCASE1!")
    assert validate_password("ValidPass1!") == "ValidPass1!"


def test_username_reserved_and_format():
    with pytest.raises(ValueError):
        validate_username("admin")
    assert validate_username("food.lover_1") == "food.lover_1"


def test_age_validation_rejects_under_13(client):
    young = (date.today() - timedelta(days=365 * 10)).isoformat()
    payload = _register_payload(date_of_birth=young)
    r = client.post("/register", json=payload)
    assert r.status_code == 422


def test_phone_duplicate_rejected(client):
    phone = f"+92333{uuid.uuid4().int % 10_000_000:07d}"
    payload = _register_payload(phone=phone)
    assert client.post("/register", json=payload).status_code == 201
    payload["username"] = f"p{uuid.uuid4().hex[:6]}"
    payload["email"] = f"p{uuid.uuid4().hex[:6]}@example.com"
    r = client.post("/register", json=payload)
    assert r.status_code == 400
    assert "Phone" in r.json()["error"]


def test_register_does_not_require_full_name(client):
    """Modern signup sends first_name/last_name only — full_name is derived server-side."""
    payload = _register_payload()
    assert "full_name" not in payload
    r = client.post("/register", json=payload)
    assert r.status_code == 201, r.text
    body = r.json()
    assert body["full_name"] == "Test User"
    assert body["first_name"] == "Test"
    assert body["last_name"] == "User"


def test_legacy_register_backward_compatible(client):
    from tests.conftest import unique_email, unique_username

    r = client.post(
        "/register",
        json={
            "full_name": "Legacy User",
            "username": unique_username("legacy"),
            "email": unique_email("legacy"),
            "password": "LegacyPass1!",
        },
    )
    assert r.status_code == 201, r.text
    assert r.json()["role"] == CUSTOMER


def test_jwt_contains_role_and_uid():
    token = create_access_token("user@example.com", RESTAURANT, user_id=42)
    payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
    assert payload["sub"] == "user@example.com"
    assert payload["role"] == RESTAURANT
    assert payload["uid"] == 42
