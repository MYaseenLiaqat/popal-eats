"""Restaurant owner dashboard access and metrics tests."""

from __future__ import annotations

import uuid

from app.core.account_status import ACTIVE
from app.models.restaurant import Restaurant
from app.models.user import User


def _register_restaurant(client):
    from tests.conftest import unique_email, unique_username

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
            "restaurant_name": "Dash Bistro",
            "restaurant_address": "1 Test Road",
            "cuisine_type": "Italian",
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


def _approve_restaurant(client, db, user_id: int):
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
    db.refresh(admin)
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


def test_active_restaurant_can_load_dashboard(client, db):
    payload, body = _register_restaurant(client)
    _approve_restaurant(client, db, body["id"])
    token = _login(client, payload["email"], payload["password"])

    restaurant = db.query(Restaurant).filter(Restaurant.owner_id == body["id"]).first()
    assert restaurant is not None

    dash = client.get(
        f"/restaurants/{restaurant.id}/dashboard",
        headers={"Authorization": f"Bearer {token}"},
    )
    assert dash.status_code == 200
    data = dash.json()
    assert data["restaurant_id"] == restaurant.id
    assert "orders_today" in data
    assert "revenue_today" in data
    assert "recent_reviews" in data


def test_customer_cannot_access_restaurant_dashboard(client, db):
    payload, body = _register_restaurant(client)
    _approve_restaurant(client, db, body["id"])
    _, customer_body = _register_customer(client)
    cust_token = _login(client, customer_body["email"], "SecurePass1!")

    restaurant = db.query(Restaurant).filter(Restaurant.owner_id == body["id"]).first()
    dash = client.get(
        f"/restaurants/{restaurant.id}/dashboard",
        headers={"Authorization": f"Bearer {cust_token}"},
    )
    assert dash.status_code == 403


def test_pending_restaurant_cannot_access_dashboard(client, db):
    payload, body = _register_restaurant(client)
    token = _login(client, payload["email"], payload["password"])
    restaurant = db.query(Restaurant).filter(Restaurant.owner_id == body["id"]).first()

    dash = client.get(
        f"/restaurants/{restaurant.id}/dashboard",
        headers={"Authorization": f"Bearer {token}"},
    )
    assert dash.status_code == 403


def test_restaurant_owner_can_list_orders(client, db):
    payload, body = _register_restaurant(client)
    _approve_restaurant(client, db, body["id"])
    token = _login(client, payload["email"], payload["password"])
    restaurant = db.query(Restaurant).filter(Restaurant.owner_id == body["id"]).first()

    orders = client.get(
        f"/restaurants/{restaurant.id}/orders",
        headers={"Authorization": f"Bearer {token}"},
    )
    assert orders.status_code == 200
    assert isinstance(orders.json(), list)
