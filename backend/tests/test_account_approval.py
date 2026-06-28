"""Admin approval workflow tests."""

from __future__ import annotations

import uuid

from app.core.account_status import ACTIVE, PENDING, REJECTED, SUSPENDED
from app.core.roles import CUSTOMER, HOME_CHEF, RESTAURANT
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
            "restaurant_name": "Test Bistro",
            "restaurant_address": "1 Test Road",
            "cuisine_type": "Italian",
        },
    }
    r = client.post("/register", json=payload)
    assert r.status_code == 201, r.text
    return payload, r.json()


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
            "chef_display_name": "Chef Test",
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


def _create_admin(client, db):
    from app.core.security import hash_password
    from tests.conftest import unique_email

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
    db.refresh(user)
    login = client.post("/login", json={"email": email, "password": "AdminPass1!"})
    assert login.status_code == 200
    return login.json()["access_token"], user


def test_customer_registers_active(client):
    _, body = _register_customer(client)
    assert body["role"] == CUSTOMER
    assert body["account_status"] == ACTIVE


def test_restaurant_registers_pending(client):
    _, body = _register_restaurant(client)
    assert body["role"] == RESTAURANT
    assert body["account_status"] == PENDING


def test_home_chef_registers_pending(client):
    _, body = _register_home_chef(client)
    assert body["role"] == HOME_CHEF
    assert body["account_status"] == PENDING


def test_admin_approves_restaurant(client, db):
    payload, body = _register_restaurant(client)
    admin_token, _ = _create_admin(client, db)

    pending = client.get(
        "/admin/business-accounts/pending",
        headers={"Authorization": f"Bearer {admin_token}"},
    )
    assert pending.status_code == 200
    assert any(item["user_id"] == body["id"] for item in pending.json())

    approve = client.post(
        f"/admin/business-accounts/{body['id']}/approve",
        headers={"Authorization": f"Bearer {admin_token}"},
    )
    assert approve.status_code == 200
    assert approve.json()["account_status"] == ACTIVE

    login = client.post("/login", json={"email": payload["email"], "password": payload["password"]})
    assert login.json()["account_status"] == ACTIVE


def test_admin_approves_home_chef(client, db):
    _, body = _register_home_chef(client)
    admin_token, _ = _create_admin(client, db)

    approve = client.post(
        f"/admin/business-accounts/{body['id']}/approve",
        headers={"Authorization": f"Bearer {admin_token}"},
    )
    assert approve.status_code == 200
    assert approve.json()["account_status"] == ACTIVE


def test_rejected_account_can_login_but_not_access_dashboard(client, db):
    payload, body = _register_restaurant(client)
    admin_token, _ = _create_admin(client, db)

    reject = client.post(
        f"/admin/business-accounts/{body['id']}/reject",
        headers={"Authorization": f"Bearer {admin_token}"},
        json={"reason": "Incomplete documentation"},
    )
    assert reject.status_code == 200
    assert reject.json()["account_status"] == REJECTED

    login = client.post("/login", json={"email": payload["email"], "password": payload["password"]})
    assert login.status_code == 200
    token = login.json()["access_token"]

    restaurant = db.query(Restaurant).filter(Restaurant.owner_id == body["id"]).first()
    dash = client.get(
        f"/restaurants/{restaurant.id}/dashboard",
        headers={"Authorization": f"Bearer {token}"},
    )
    assert dash.status_code == 403


def test_pending_account_cannot_access_dashboard(client, db):
    payload, body = _register_restaurant(client)
    login = client.post("/login", json={"email": payload["email"], "password": payload["password"]})
    token = login.json()["access_token"]

    restaurant = db.query(Restaurant).filter(Restaurant.owner_id == body["id"]).first()
    dash = client.get(
        f"/restaurants/{restaurant.id}/dashboard",
        headers={"Authorization": f"Bearer {token}"},
    )
    assert dash.status_code == 403


def test_suspend_and_reactivate(client, db):
    payload, body = _register_restaurant(client)
    admin_token, _ = _create_admin(client, db)

    client.post(
        f"/admin/business-accounts/{body['id']}/approve",
        headers={"Authorization": f"Bearer {admin_token}"},
    )

    suspend = client.post(
        f"/admin/business-accounts/{body['id']}/suspend",
        headers={"Authorization": f"Bearer {admin_token}"},
        json={"reason": "Policy violation"},
    )
    assert suspend.status_code == 200
    assert suspend.json()["account_status"] == SUSPENDED

    login = client.post("/login", json={"email": payload["email"], "password": payload["password"]})
    assert login.status_code == 403

    reactivate = client.post(
        f"/admin/business-accounts/{body['id']}/reactivate",
        headers={"Authorization": f"Bearer {admin_token}"},
    )
    assert reactivate.status_code == 200
    assert reactivate.json()["account_status"] == ACTIVE

    login2 = client.post("/login", json={"email": payload["email"], "password": payload["password"]})
    assert login2.status_code == 200
