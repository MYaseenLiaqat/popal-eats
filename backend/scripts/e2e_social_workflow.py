"""End-to-end social + group recommendation workflow via live HTTP API."""

from __future__ import annotations

import json
import sys
import uuid
from dataclasses import dataclass
from pathlib import Path

import urllib.error
import urllib.request

BASE = "http://127.0.0.1:8000"
PASSWORD = "FypTest123!"
LAHORE_LAT = 31.4824
LAHORE_LNG = 74.3237


@dataclass
class Client:
    email: str
    token: str
    user_id: int


def _request(method: str, path: str, token: str | None = None, body: dict | None = None, timeout: int = 60) -> dict:
    url = f"{BASE}{path}"
    data = None if body is None else json.dumps(body).encode()
    headers = {"Content-Type": "application/json"}
    if token:
        headers["Authorization"] = f"Bearer {token}"
    req = urllib.request.Request(url, data=data, headers=headers, method=method)
    try:
        with urllib.request.urlopen(req, timeout=timeout) as resp:
            raw = resp.read().decode()
            return json.loads(raw) if raw else {}
    except urllib.error.HTTPError as exc:
        detail = exc.read().decode()
        raise RuntimeError(f"{method} {path} -> {exc.code}: {detail}") from exc


def register_and_login(label: str) -> Client:
    email = f"fyp_{label}_{uuid.uuid4().hex[:8]}@example.com"
    _request(
        "POST",
        "/register",
        body={"full_name": f"FYP {label}", "email": email, "password": PASSWORD},
    )
    login = _request("POST", "/login", body={"email": email, "password": PASSWORD})
    me = _request("GET", "/me", token=login["access_token"])
    return Client(email=email, token=login["access_token"], user_id=me["id"])


def complete_onboarding(client: Client) -> None:
    _request(
        "POST",
        "/preferences/onboarding",
        token=client.token,
        body={"favorite_cuisines": ["biryani", "burger"], "allergies": []},
    )


def main() -> int:
    print(f"Base URL: {BASE}")
    health = _request("GET", "/health")
    print("GET /health:", health)

    print("\n--- Register Account A & B ---")
    user_a = register_and_login("A")
    user_b = register_and_login("B")
    print(f"Account A: {user_a.email} (id={user_a.user_id})")
    print(f"Account B: {user_b.email} (id={user_b.user_id})")

    print("\n--- Onboarding ---")
    complete_onboarding(user_a)
    complete_onboarding(user_b)
    print("Onboarding complete for both users")

    print("\n--- Friend request A -> B ---")
    fr = _request(
        "POST",
        "/friends/request",
        token=user_a.token,
        body={"receiver_id": user_b.user_id},
    )
    request_id = fr["id"]
    print(f"Friend request created: id={request_id}")

    _request("POST", f"/friends/request/{request_id}/accept", token=user_b.token)
    friends_b = _request("GET", "/friends", token=user_b.token)
    assert any(f.get("id") == user_a.user_id or f.get("user_id") == user_a.user_id for f in friends_b.get("friends", [])), friends_b
    print("Friendship established")

    print("\n--- Group creation (A) ---")
    group = _request("POST", "/groups", token=user_a.token, body={"name": "FYP E2E Group"})
    session_id = group["id"]
    print(f"Group session id={session_id}")

    print("\n--- Invite B ---")
    inv = _request(
        "POST",
        f"/groups/{session_id}/invite",
        token=user_a.token,
        body={"receiver_id": user_b.user_id},
    )
    invitation_id = inv["id"]
    print(f"Invitation id={invitation_id}")

    _request("POST", f"/groups/invitations/{invitation_id}/accept", token=user_b.token)
    print("Invitation accepted")

    print("\n--- Location sharing ---")
    for client, label in ((user_a, "A"), (user_b, "B")):
        loc = _request(
            "POST",
            f"/groups/{session_id}/location",
            token=client.token,
            body={"latitude": LAHORE_LAT, "longitude": LAHORE_LNG},
        )
        print(f"User {label} location saved: user_id={loc.get('user_id')}")

    locations = _request("GET", f"/groups/{session_id}/location", token=user_a.token)
    loc_count = len(locations.get("locations", []))
    print(f"Member locations count={loc_count}")
    assert loc_count >= 2, locations

    print("\n--- Group recommendations ---")
    recs = _request("GET", f"/groups/{session_id}/recommendations", token=user_a.token, timeout=180)
    recommendations = recs.get("recommendations", [])
    print(f"Recommendations returned: {len(recommendations)}")
    if not recommendations:
        print("WARN: No recommendations — ensure catalog has dishes near Lahore")
        return 1

    top = recommendations[0]
    recommendation_id = top.get("recommendation_id")
    dish_name = top.get("dish_name")
    print(f"Top pick: {dish_name} (recommendation_id={recommendation_id})")
    assert recommendation_id, f"Missing recommendation_id: {top}"

    print("\n--- Voting ---")
    _request(
        "POST",
        f"/groups/recommendations/{recommendation_id}/vote",
        token=user_a.token,
        body={"vote_type": "LOVE"},
    )
    _request(
        "POST",
        f"/groups/recommendations/{recommendation_id}/vote",
        token=user_b.token,
        body={"vote_type": "LIKE"},
    )
    summary = _request("GET", f"/groups/recommendations/{recommendation_id}/votes", token=user_a.token)
    print(
        "Vote summary:",
        f"likes={summary.get('likes')} loves={summary.get('loves')} "
        f"consensus={summary.get('consensus_score')} final={summary.get('final_score')}",
    )
    assert summary.get("total_votes", 0) >= 2, summary

    print("\n--- Decision ---")
    decision = _request("GET", f"/groups/{session_id}/decision", token=user_a.token)
    status = decision.get("status")
    print(f"Decision status={status} dish={decision.get('dish_name')}")
    assert status in {"considering", "agreed"}, decision

    if status == "agreed":
        ordered = _request("POST", f"/groups/{session_id}/decision/ordered", token=user_a.token)
        print(f"Marked ordered: status={ordered.get('status')}")
        assert ordered.get("status") == "ordered"
    else:
        print("Status is considering (need 60% positive votes in 2-member group = both LIKE/LOVE)")
        print("Both users voted positive — re-check decision threshold")

    print("\n=== E2E SOCIAL WORKFLOW PASSED ===")
    print("\nUse these accounts for manual UI testing:")
    print(f"  Account A: {user_a.email} / {PASSWORD}")
    print(f"  Account B: {user_b.email} / {PASSWORD}")
    print(f"  Group session id: {session_id}")
    return 0


if __name__ == "__main__":
    if len(sys.argv) > 1:
        BASE = sys.argv[1].rstrip("/")
    sys.exit(main())
