"""Home chef owner dashboard tests."""

from __future__ import annotations

import uuid

from app.core.account_status import ACTIVE
from app.models.home_chef_profile import HomeChefProfile
from app.models.restaurant import Restaurant
from app.models.user import User


def _register_home_chef(client):
    from tests.conftest import unique_email, unique_username

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
            "chef_display_name": "Chef Test Kitchen",
            "cuisine_specialty": "Baking",
            "kitchen_address": "2 Kitchen Lane",
        },
    }
    r = client.post("/register", json=payload)
    assert r.status_code == 201, r.text
    return payload, r.json()


def _register_customer(client):
    from tests.conftest import unique_email, unique_username

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


def _approve_home_chef(client, db, user_id: int):
    from app.core.security import hash_password
    from tests.conftest import unique_email

    email = unique_email("admin")
    admin = User(
        full_name="Admin User",
        first_name="Admin",
        last_name="User",
        email=email,
        password_hash=hash_password("AdminPass1!"),
        role="admin",
        account_status=ACTIVE,
        username=f"admin{uuid.uuid4().hex[:6]}",
    )
    db.add(admin)
    db.commit()
    login = client.post("/login", json={"email": email, "password": "AdminPass1!"})
    token = login.json()["access_token"]
    approve = client.post(
        f"/admin/business-accounts/{user_id}/approve",
        headers={"Authorization": f"Bearer {token}"},
    )
    assert approve.status_code == 200


def _login(client, email: str, password: str) -> str:
    r = client.post("/login", json={"email": email, "password": password})
    assert r.status_code == 200, r.text
    return r.json()["access_token"]


def test_active_home_chef_can_load_dashboard(client, db):
    payload, body = _register_home_chef(client)
    _approve_home_chef(client, db, body["id"])
    token = _login(client, payload["email"], payload["password"])

    me = client.get("/home-chef/me", headers={"Authorization": f"Bearer {token}"})
    assert me.status_code == 200
    assert me.json()["kitchen_restaurant_id"] is not None

    dash = client.get("/home-chef/dashboard", headers={"Authorization": f"Bearer {token}"})
    assert dash.status_code == 200
    data = dash.json()
    assert "orders_today" in data
    assert "kitchen_restaurant_id" in data
    assert "story_views" in data

    profile = db.query(HomeChefProfile).filter(HomeChefProfile.user_id == body["id"]).first()
    kitchen = db.query(Restaurant).filter(Restaurant.id == profile.kitchen_restaurant_id).first()
    assert kitchen.source == "home_chef"


def test_customer_cannot_access_home_chef_dashboard(client, db):
    payload, body = _register_home_chef(client)
    _approve_home_chef(client, db, body["id"])
    _, customer_body = _register_customer(client)
    cust_token = _login(client, customer_body["email"], "SecurePass1!")

    dash = client.get("/home-chef/dashboard", headers={"Authorization": f"Bearer {cust_token}"})
    assert dash.status_code == 403


def test_pending_home_chef_cannot_access_dashboard(client, db):
    payload, body = _register_home_chef(client)
    token = _login(client, payload["email"], payload["password"])

    dash = client.get("/home-chef/dashboard", headers={"Authorization": f"Bearer {token}"})
    assert dash.status_code == 403


def test_home_chef_can_list_orders(client, db):
    payload, body = _register_home_chef(client)
    _approve_home_chef(client, db, body["id"])
    token = _login(client, payload["email"], payload["password"])

    orders = client.get("/home-chef/orders", headers={"Authorization": f"Bearer {token}"})
    assert orders.status_code == 200
    assert isinstance(orders.json(), list)
