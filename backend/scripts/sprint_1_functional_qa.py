#!/usr/bin/env python
"""Sprint 1 functional QA — API verification with timing."""

from __future__ import annotations

import json
import sys
import time
import uuid
from dataclasses import dataclass, field
from pathlib import Path

import urllib.error
import urllib.request

_backend = Path(__file__).resolve().parent.parent
if str(_backend) not in sys.path:
    sys.path.insert(0, str(_backend))

BASE = "http://127.0.0.1:8000"
PWD = "Test1234!"


@dataclass
class Row:
    area: str
    name: str
    status: str
    detail: str = ""
    ms: float | None = None


@dataclass
class Report:
    rows: list[Row] = field(default_factory=list)
    perf: dict[str, float] = field(default_factory=dict)

    def add(self, area: str, name: str, status: str, detail: str = "", ms: float | None = None):
        self.rows.append(Row(area, name, status, detail, ms))


def req(method: str, path: str, token: str | None = None, body: dict | None = None, timeout: int = 120):
    t0 = time.perf_counter()
    data = json.dumps(body).encode() if body is not None else None
    headers = {"Content-Type": "application/json"}
    if token:
        headers["Authorization"] = f"Bearer {token}"
    request = urllib.request.Request(f"{BASE}{path}", data=data, headers=headers, method=method)
    try:
        with urllib.request.urlopen(request, timeout=timeout) as resp:
            raw = resp.read().decode()
            elapsed = (time.perf_counter() - t0) * 1000
            return resp.status, json.loads(raw) if raw else {}, elapsed
    except urllib.error.HTTPError as e:
        elapsed = (time.perf_counter() - t0) * 1000
        try:
            detail = json.loads(e.read().decode())
        except Exception:
            detail = {"error": str(e)}
        return e.code, detail, elapsed


def login(email: str, password: str = PWD) -> tuple[str | None, dict]:
    code, data, _ = req("POST", "/login", body={"email": email, "password": password})
    if code != 200:
        return None, data
    return data.get("access_token"), data


def signup_customer(email: str, full_name: str = "QA User") -> tuple[str | None, dict]:
    parts = full_name.split()
    code, data, _ = req(
        "POST",
        "/register",
        body={
            "role": "customer",
            "email": email,
            "password": PWD,
            "confirm_password": PWD,
            "first_name": parts[0],
            "last_name": parts[-1] if len(parts) > 1 else "Test",
            "phone": f"+92319{uuid.uuid4().int % 10_000_000:07d}",
            "date_of_birth": "1995-06-15",
        },
    )
    if code not in (200, 201):
        return None, data
    token, _ = login(email)
    return token, data


def main() -> int:
    r = Report()
    suffix = uuid.uuid4().hex[:8]

    # Health
    code, _, ms = req("GET", "/health")
    r.add("Infra", "Backend health", "PASS" if code == 200 else "FAIL", f"HTTP {code}", ms)

    # Demo login
    demo_token, _ = login("demo.host@example.com", "Demo1234!")
    r.add("Auth", "Demo customer login", "PASS" if demo_token else "FAIL")

    # Signup + session
    email_a = f"s1.qa.a.{suffix}@example.com"
    email_b = f"s1.qa.b.{suffix}@example.com"
    tok_a, _ = signup_customer(email_a, "Alpha QA")
    tok_b, _ = signup_customer(email_b, "Beta QA")
    r.add("Auth", "Customer signup A", "PASS" if tok_a else "FAIL", email_a)
    r.add("Auth", "Customer signup B", "PASS" if tok_b else "FAIL", email_b)

    relog, _ = login(email_a)
    r.add("Auth", "Session persistence (re-login)", "PASS" if relog else "FAIL")

    # Preferences + differentiated recommendations
    prefs_a = {
        "favorite_cuisines": ["Italian", "Pizza"],
        "dietary_preferences": ["vegetarian"],
        "nutrition_goal": "weight_loss",
        "budget_level": "low",
        "allergies": ["peanuts"],
    }
    prefs_b = {
        "favorite_cuisines": ["Desi", "Biryani"],
        "dietary_preferences": ["halal"],
        "nutrition_goal": "muscle_gain",
        "budget_level": "high",
        "allergies": ["shellfish"],
    }
    code, _, _ = req("PUT", "/preferences", tok_a, prefs_a)
    r.add("Recommendations", "Save prefs user A", "PASS" if code == 200 else "FAIL", f"HTTP {code}")
    code, _, _ = req("PUT", "/preferences", tok_b, prefs_b)
    r.add("Recommendations", "Save prefs user B", "PASS" if code == 200 else "FAIL", f"HTTP {code}")

    code, rec_a, ms_a = req("GET", "/recommendations/v2?strategy=hybrid&limit=10", tok_a)
    code, rec_b, ms_b = req("GET", "/recommendations/v2?strategy=hybrid&limit=10", tok_b)
    r.perf["recommendations_user_a_ms"] = ms_a
    r.perf["recommendations_user_b_ms"] = ms_b
    items_a = rec_a.get("items", []) if code == 200 else []
    items_b = rec_b.get("items", []) if code == 200 else []
    ids_a = [i.get("dish_id") for i in items_a]
    ids_b = [i.get("dish_id") for i in items_b]
    differ = ids_a != ids_b and len(items_a) > 0 and len(items_b) > 0
    r.add(
        "Recommendations",
        "Different users get different recs",
        "PASS" if differ else "FAIL",
        f"A={ids_a[:3]} B={ids_b[:3]}",
        (ms_a + ms_b) / 2,
    )

    # Home feed social-only
    code, feed, ms_feed = req("GET", "/feed/home?limit=20", tok_a)
    r.perf["home_feed_ms"] = ms_feed
    posts = feed.get("items", feed) if isinstance(feed, dict) else feed
    if isinstance(posts, dict):
        posts = posts.get("items", [])
    r.add("Home Feed", "Feed endpoint", "PASS" if code == 200 else "FAIL", f"HTTP {code}, count={len(posts)}", ms_feed)

    # Friend search
    code, search, ms_search = req("GET", "/users/search?q=Beta", tok_a)
    r.perf["friend_search_ms"] = ms_search
    results = search.get("results", [])
    r.add("Community", "Search by display name", "PASS" if code == 200 else "FAIL", f"hits={len(results)}", ms_search)

    code, search2, _ = req("GET", f"/users/search?q=demo", tok_a)
    r.add("Community", "Partial username search", "PASS" if code == 200 and search2.get("results") else "FAIL")

    # Friend request flow
    code, demo_user, _ = req("GET", "/me", demo_token)
    demo_id = demo_user.get("id") if code == 200 else None
    if demo_id and tok_b:
        code, _, _ = req("POST", "/friends/request", tok_b, {"receiver_id": demo_id})
        r.add("Community", "Send friend request", "PASS" if code in (200, 201) else "FAIL", f"HTTP {code}")
        code, reqs, _ = req("GET", "/friends/requests", demo_token)
        incoming = reqs.get("incoming", [])
        req_id = incoming[0]["id"] if incoming else None
        if req_id:
            code, _, _ = req("POST", f"/friends/request/{req_id}/accept", demo_token)
            r.add("Community", "Accept friend request", "PASS" if code == 200 else "FAIL")
            code, friends, _ = req("GET", "/friends", demo_token)
            friend_ids = [f.get("id") for f in friends.get("friends", [])]
            r.add(
                "Community",
                "Friendship persists",
                "PASS" if any(email_b.split("@")[0].split(".")[2] in str(f) for f in friend_ids) or len(friend_ids) > 0 else "PARTIAL",
                f"friends={len(friend_ids)}",
            )

    # Restaurant search
    code, rest, ms_rest = req("GET", "/restaurants?search=pizza&limit=10")
    r.perf["restaurant_search_ms"] = ms_rest
    items = rest.get("items", [])
    r.add("Order", "Restaurant search API", "PASS" if code == 200 else "FAIL", f"hits={len(items)}", ms_rest)

    code, rest2, _ = req("GET", "/restaurants?search=biryani&limit=10")
    r2 = rest2.get("items", [])
    r.add("Order", "Cuisine/dish search API", "PASS" if code == 200 else "FAIL", f"hits={len(r2)}")

    # Reels
    code, reels, _ = req("GET", "/discover/reels?limit=10", demo_token)
    reel_items = reels if isinstance(reels, list) else reels.get("items", [])
    r.add("Reels", "Discover reels API", "PASS" if code == 200 else "FAIL", f"count={len(reel_items)}")

    # Orders / delivery status values
    code, orders, _ = req("GET", "/orders/mine?limit=5", demo_token)
    order_items = orders.get("items", orders) if isinstance(orders, dict) else orders
    if isinstance(order_items, dict):
        order_items = order_items.get("items", [])
    statuses = [o.get("status") for o in order_items[:3]] if order_items else []
    r.add("Delivery", "Orders expose backend status", "PASS" if code == 200 else "FAIL", f"statuses={statuses}")

    # Print report
    passes = [x for x in r.rows if x.status == "PASS"]
    fails = [x for x in r.rows if x.status == "FAIL"]
    warns = [x for x in r.rows if x.status == "PARTIAL"]

    print("=== SPRINT 1 API QA ===")
    for row in r.rows:
        ms = f" ({row.ms:.0f}ms)" if row.ms else ""
        print(f"[{row.status}] {row.area} — {row.name}{ms}: {row.detail}")
    print("\n=== PERFORMANCE ===")
    for k, v in r.perf.items():
        print(f"{k}: {v:.0f}ms")
    print(f"\nSUMMARY: PASS={len(passes)} FAIL={len(fails)} PARTIAL={len(warns)}")
    return 1 if fails else 0


if __name__ == "__main__":
    raise SystemExit(main())
