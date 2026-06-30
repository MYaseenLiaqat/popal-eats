"""Phase 12E role permission enforcement tests."""

from __future__ import annotations

import uuid

from app.core.account_status import ACTIVE
from app.core.security import hash_password
from app.models.user import User
from tests.conftest import unique_email, unique_username


def _register_customer(client):
    payload = {
        "role": "customer",
        "first_name": "Cust",
        "last_name": "User",
        "username": unique_username("cust"),
        "email": unique_email("cust"),
        "phone": f"+92302{uuid.uuid4().int % 10_000_000:07d}",
        "date_of_birth": "2000-01-01",
        "password": "SecurePass1!",
        "confirm_password": "SecurePass1!",
    }
    r = client.post("/register", json=payload)
    assert r.status_code == 201, r.text
    return payload, r.json()


def _register_restaurant(client):
    payload = {
        "role": "restaurant",
        "first_name": "Rest",
        "last_name": "Owner",
        "username": unique_username("rest"),
        "email": unique_email("rest"),
        "phone": f"+92300{uuid.uuid4().int % 10_000_000:07d}",
        "date_of_birth": "1990-01-01",
        "password": "SecurePass1!",
        "confirm_password": "SecurePass1!",
        "restaurant_profile": {
            "restaurant_name": "Test Bistro",
            "restaurant_address": "1 Test Road",
            "cuisine_type": "Italian",
        },
    }
    r = client.post("/register", json=payload)
    assert r.status_code == 201, r.text
    return payload, r.json()


def _register_home_chef(client):
    payload = {
        "role": "home_chef",
        "first_name": "Chef",
        "last_name": "Test",
        "username": unique_username("chef"),
        "email": unique_email("chef"),
        "phone": f"+92301{uuid.uuid4().int % 10_000_000:07d}",
        "date_of_birth": "1992-05-10",
        "password": "SecurePass1!",
        "confirm_password": "SecurePass1!",
        "home_chef_profile": {
            "chef_display_name": "Chef Test",
            "cuisine_specialty": "Baking",
            "kitchen_address": "2 Kitchen Lane",
        },
    }
    r = client.post("/register", json=payload)
    assert r.status_code == 201, r.text
    return payload, r.json()


def _create_admin(client, db):
    email = unique_email("admin")
    user = User(
        full_name="Admin User",
        first_name="Admin",
        last_name="User",
        email=email,
        password_hash=hash_password("AdminPass1!"),
        role="admin",
        account_status=ACTIVE,
        username=f"admin{uuid.uuid4().hex[:6]}",
    )
    db.add(user)
    db.commit()
    login = client.post("/login", json={"email": email, "password": "AdminPass1!"})
    return login.json()["access_token"]


def _login(client, email: str, password: str) -> str:
    r = client.post("/login", json={"email": email, "password": password})
    assert r.status_code == 200, r.text
    return r.json()["access_token"]


def test_customer_can_create_story(client):
    payload, _ = _register_customer(client)
    token = _login(client, payload["email"], payload["password"])
    r = client.post(
        "/stories",
        headers={"Authorization": f"Bearer {token}"},
        files={"file": ("story.jpg", b"fake", "image/jpeg")},
    )
    assert r.status_code == 201, r.text


def test_customer_cannot_create_chef_post(client):
    payload, _ = _register_customer(client)
    token = _login(client, payload["email"], payload["password"])
    r = client.post(
        "/posts",
        headers={"Authorization": f"Bearer {token}"},
        json={"post_type": "chef_post", "caption": "not allowed"},
    )
    assert r.status_code == 403


def test_customer_can_create_food_post(client):
    payload, _ = _register_customer(client)
    token = _login(client, payload["email"], payload["password"])
    r = client.post(
        "/posts",
        headers={"Authorization": f"Bearer {token}"},
        json={"post_type": "food_post", "caption": "community lunch"},
    )
    assert r.status_code == 201


def test_restaurant_cannot_checkout(client):
    payload, _ = _register_restaurant(client)
    token = _login(client, payload["email"], payload["password"])
    r = client.post("/checkout", headers={"Authorization": f"Bearer {token}"}, json={
        "delivery_address": "123 Test St",
    })
    assert r.status_code == 403


def test_admin_cannot_checkout(client, db):
    token = _create_admin(client, db)
    r = client.post("/checkout", headers={"Authorization": f"Bearer {token}"}, json={
        "delivery_address": "123 Test St",
    })
    assert r.status_code == 403


def test_home_chef_cannot_access_restaurant_mine(client, db):
    payload, body = _register_home_chef(client)
    admin_token = _create_admin(client, db)
    client.post(
        f"/admin/business-accounts/{body['id']}/approve",
        headers={"Authorization": f"Bearer {admin_token}"},
    )
    token = _login(client, payload["email"], payload["password"])
    r = client.get("/restaurants/mine", headers={"Authorization": f"Bearer {token}"})
    assert r.status_code == 403


def test_restaurant_cannot_access_home_chef_dashboard(client, db):
    payload, body = _register_restaurant(client)
    admin_token = _create_admin(client, db)
    client.post(
        f"/admin/business-accounts/{body['id']}/approve",
        headers={"Authorization": f"Bearer {admin_token}"},
    )
    token = _login(client, payload["email"], payload["password"])
    r = client.get("/home-chef/dashboard", headers={"Authorization": f"Bearer {token}"})
    assert r.status_code == 403


def test_restaurant_cannot_create_group(client, db):
    payload, body = _register_restaurant(client)
    admin_token = _create_admin(client, db)
    client.post(
        f"/admin/business-accounts/{body['id']}/approve",
        headers={"Authorization": f"Bearer {admin_token}"},
    )
    token = _login(client, payload["email"], payload["password"])
    r = client.post(
        "/groups",
        headers={"Authorization": f"Bearer {token}"},
        json={"name": "Blocked Group"},
    )
    assert r.status_code == 403
