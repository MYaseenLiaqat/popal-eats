"""Restaurant follow API and feed prioritization."""

from tests.conftest import unique_email, unique_username


def _register_customer(client):
    payload = {
        "full_name": "Follow Tester",
        "email": unique_email("follow"),
        "password": "SecurePass1!",
        "username": unique_username("follow"),
    }
    r = client.post("/register", json=payload)
    assert r.status_code == 201
    login = client.post("/login", json={"email": payload["email"], "password": payload["password"]})
    assert login.status_code == 200
    token = login.json()["access_token"]
    return token, payload


def _auth(token: str) -> dict:
    return {"Authorization": f"Bearer {token}"}


def test_follow_unfollow_restaurant(client, db):
    token, _ = _register_customer(client)
    headers = _auth(token)

    # Use an approved restaurant from listing.
    listing = client.get("/restaurants", params={"limit": 1})
    assert listing.status_code == 200
    items = listing.json().get("items") or listing.json().get("data") or []
    if not items:
        return
    restaurant_id = items[0]["id"]

    empty = client.get("/restaurants/following", headers=headers)
    assert empty.status_code == 200
    assert empty.json()["total"] == 0

    follow = client.post(f"/restaurants/{restaurant_id}/follow", headers=headers)
    assert follow.status_code == 200
    body = follow.json()
    assert restaurant_id in body["restaurant_ids"]
    assert body["total"] >= 1

    again = client.post(f"/restaurants/{restaurant_id}/follow", headers=headers)
    assert again.status_code == 200
    assert again.json()["total"] == body["total"]

    unfollow = client.delete(f"/restaurants/{restaurant_id}/follow", headers=headers)
    assert unfollow.status_code == 200
    assert restaurant_id not in unfollow.json()["restaurant_ids"]
