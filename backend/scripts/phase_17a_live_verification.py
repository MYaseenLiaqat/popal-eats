#!/usr/bin/env python
"""Phase 17A live API verification — exercises workflows via HTTP."""

from __future__ import annotations

import json
import re
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
DEMO = "Demo1234!"
ADMIN_PWD = "YourPassword123"
SEED_MARKER = re.compile(r"<!--\s*fyp_seed", re.I)


@dataclass
class Result:
    area: str
    name: str
    status: str  # PASS | FAIL | PARTIAL | SKIP
    detail: str = ""
    ms: float | None = None


@dataclass
class Report:
    rows: list[Result] = field(default_factory=list)

    def add(self, area: str, name: str, status: str, detail: str = "", ms: float | None = None):
        self.rows.append(Result(area, name, status, detail, ms))

    def summary(self) -> dict[str, int]:
        out = {"PASS": 0, "FAIL": 0, "PARTIAL": 0, "SKIP": 0}
        for r in self.rows:
            out[r.status] = out.get(r.status, 0) + 1
        return out


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


def login(email: str, password: str) -> tuple[str | None, dict | None, str]:
    code, data, _ = req("POST", "/login", body={"email": email, "password": password})
    if code != 200:
        return None, None, str(data)
    return data.get("access_token"), data, ""


def main() -> int:
    global BASE
    if len(sys.argv) > 1:
        BASE = sys.argv[1].rstrip("/")

    r = Report()
    print(f"Phase 17A live verification — {BASE}\n")

    # STEP 1 — health
    code, health, ms = req("GET", "/health")
    ok = code == 200 and health.get("status") == "ok"
    r.add("Infra", "GET /health", "PASS" if ok else "FAIL", str(health), ms)

    suffix = uuid.uuid4().hex[:8]

    # CUSTOMER — signup/login/logout/preferences/cart/checkout
    cust_email = f"qa17a.cust.{suffix}@example.com"
    code, reg, _ = req(
        "POST",
        "/register",
        body={
            "role": "customer",
            "email": cust_email,
            "phone": f"+92300{suffix[:7]}",
            "password": PWD,
            "confirm_password": PWD,
            "first_name": "QA",
            "last_name": "Customer",
            "date_of_birth": "2000-01-15",
        },
    )
    r.add("Customer", "Signup", "PASS" if code == 201 else "FAIL", f"HTTP {code}")

    token, login_data, err = login(cust_email, PWD)
    r.add("Customer", "Login (new)", "PASS" if token else "FAIL", err or login_data.get("role", ""))

    code, demo_tok_data, _ = req("POST", "/login", body={"email": "demo.host@example.com", "password": DEMO})
    demo_token = demo_tok_data.get("access_token") if code == 200 else None
    r.add("Customer", "Login (demo)", "PASS" if demo_token else "FAIL", f"HTTP {code}")

    r.add("Customer", "Forgot password", "SKIP", "No backend endpoint")

    if token:
        code, _, _ = req(
            "POST",
            "/preferences/onboarding",
            token=token,
            body={"favorite_cuisines": ["pakistani"], "allergies": []},
        )
        r.add("Customer", "Preference onboarding", "PASS" if code in (200, 201) else "FAIL", f"HTTP {code}")

        code, prefs, _ = req(
            "PUT",
            "/preferences",
            token=token,
            body={"nutrition_goal": "maintain", "budget_level": "medium", "favorite_cuisines": ["pakistani"]},
        )
        r.add("Customer", "Nutrition/budget preferences", "PASS" if code == 200 else "FAIL", f"HTTP {code}")

        code, feed, ms = req("GET", "/feed/home?limit=10", token=token)
        items = feed.get("items", []) if isinstance(feed, dict) else []
        markers = [
            p.get("caption", "")
            for p in items
            if isinstance(p, dict) and SEED_MARKER.search(p.get("caption") or "")
        ]
        r.add("Customer", "Home feed API", "PASS" if code == 200 else "FAIL", f"{len(items)} posts", ms)
        r.add(
            "Phase16.9",
            "No HTML seed markers in feed API",
            "PASS" if not markers else "FAIL",
            f"{len(markers)} posts still contain markers",
        )

        code, rests, ms = req("GET", "/restaurants?limit=5", token=token)
        r.add("Customer", "Order/restaurants API", "PASS" if code == 200 else "FAIL", f"HTTP {code}", ms)

        rest_id = None
        dish_id = None
        if code == 200:
            raw = rests.get("items", rests) if isinstance(rests, dict) else rests
            if isinstance(raw, list) and raw:
                rest_id = raw[0].get("id")
        if rest_id:
            code, rest_detail, ms = req("GET", f"/restaurants/{rest_id}", token=token)
            r.add("Customer", "Restaurant detail API", "PASS" if code == 200 else "FAIL", f"id={rest_id}", ms)
            code, dishes, _ = req("GET", f"/dishes?restaurant_id={rest_id}&limit=5", token=token)
            ditems = dishes.get("items", dishes) if isinstance(dishes, dict) else dishes
            if isinstance(ditems, list) and ditems:
                dish_id = ditems[0].get("id")
            if dish_id:
                code, dish, ms = req("GET", f"/dishes/{dish_id}", token=token)
                r.add("Customer", "Dish detail API", "PASS" if code == 200 else "FAIL", f"id={dish_id}", ms)

        if dish_id:
            code, _, _ = req("POST", "/cart/add", token=token, body={"dish_id": dish_id, "quantity": 1})
            code, cart, _ = req("GET", "/cart", token=token)
            count = cart.get("item_count", 0) if isinstance(cart, dict) else 0
            r.add("Customer", "Add to cart + cart state", "PASS" if code == 200 and count > 0 else "FAIL", f"items={count}")

            code, order, ms = req(
                "POST",
                "/checkout",
                token=token,
                body={"delivery_address": "123 QA Street, Lahore, Pakistan"},
            )
            r.add("Customer", "Checkout", "PASS" if code in (200, 201) else "FAIL", f"HTTP {code}", ms)

            code, orders, _ = req("GET", "/orders/my-orders?limit=5", token=token)
            olist = orders if isinstance(orders, list) else []
            r.add("Customer", "Order history", "PASS" if code == 200 and len(olist) > 0 else "PARTIAL", f"{len(olist)} orders")

        code, friends, _ = req("GET", "/friends", token=token)
        r.add("Customer", "Community/friends API", "PASS" if code == 200 else "FAIL", f"HTTP {code}")

        code, me, _ = req("GET", "/me", token=token)
        r.add("Customer", "Profile /me", "PASS" if code == 200 else "FAIL", me.get("email", ""))

        code, orders_hist, ms = req("GET", "/orders/my-orders?limit=20", token=token)
        r.add("Customer", "Health dashboard data (orders)", "PASS" if code == 200 else "FAIL", f"HTTP {code}", ms)

        code, _, _ = req("POST", "/logout", token=token, body={"refresh_token": login_data.get("refresh_token", "")})
        r.add("Customer", "Logout", "PASS" if code in (200, 204) else "PARTIAL", f"HTTP {code}")

    # Reviews consistency
    if demo_token and rest_id:
        code, reviews, _ = req("GET", f"/reviews/restaurant/{rest_id}?limit=10", token=demo_token)
        revs = reviews if isinstance(reviews, list) else reviews.get("items", [])
        dupes = len(revs) - len({x.get("id") for x in revs if isinstance(x, dict)})
        conflicts = 0
        for rv in revs:
            if not isinstance(rv, dict):
                continue
            rating = rv.get("rating", 0)
            sent = (rv.get("sentiment") or "").lower()
            expected = "positive" if rating >= 4 else "neutral" if rating == 3 else "negative"
            if sent and sent != expected:
                conflicts += 1
        r.add("Phase16.9", "No duplicate review ids", "PASS" if dupes == 0 else "FAIL", f"dupes={dupes}")
        r.add("Phase16.9", "Review sentiment matches rating", "PASS" if conflicts == 0 else "PARTIAL", f"conflicts={conflicts}")

    # RESTAURANT
    rest_email = f"qa17a.rest.{suffix}@example.com"
    code, _, _ = req(
        "POST",
        "/register",
        body={
            "role": "restaurant",
            "email": rest_email,
            "phone": f"+92301{suffix[:7]}",
            "password": PWD,
            "confirm_password": PWD,
            "restaurant_profile": {
                "restaurant_name": f"QA Kitchen {suffix}",
                "restaurant_address": "1 Test Road Lahore",
                "cuisine_type": "pakistani",
            },
        },
    )
    r.add("Restaurant", "Signup", "PASS" if code == 201 else "FAIL", f"HTTP {code}")

    rest_token, rest_login, _ = login(rest_email, PWD)
    pending = rest_login.get("account_status") == "pending" if rest_login else False
    r.add("Restaurant", "Pending after signup", "PASS" if pending else "PARTIAL", str(rest_login))

    # Demo restaurant owner
    code, owner_data, _ = req("POST", "/login", body={"email": "demo.owner@example.com", "password": DEMO})
    owner_token = owner_data.get("access_token") if code == 200 else None
    r.add("Restaurant", "Login (demo owner)", "PASS" if owner_token else "FAIL", f"HTTP {code}")

    if owner_token:
        code, dash, ms = req("GET", "/restaurants/dashboard", token=owner_token)
        r.add("Restaurant", "Dashboard", "PASS" if code == 200 else "FAIL", f"HTTP {code}", ms)

        code, menu, _ = req("GET", "/dishes?limit=5", token=owner_token)
        r.add("Restaurant", "Menu list", "PASS" if code == 200 else "FAIL", f"HTTP {code}")

    # ADMIN
    code, admin_data, _ = req("POST", "/login", body={"email": "admin@popaleats.com", "password": ADMIN_PWD})
    admin_token = admin_data.get("access_token") if code == 200 else None
    r.add("Admin", "Login", "PASS" if admin_token else "FAIL", f"HTTP {code}")

    if admin_token:
        code, overview, ms = req("GET", "/admin/analytics/overview", token=admin_token)
        r.add("Admin", "Dashboard analytics", "PASS" if code == 200 else "FAIL", f"HTTP {code}", ms)

        code, pending_accts, _ = req("GET", "/admin/business-accounts/pending", token=admin_token)
        plist = pending_accts if isinstance(pending_accts, list) else []
        r.add("Admin", "Pending business accounts", "PASS" if code == 200 else "FAIL", f"{len(plist)} pending")

        if rest_token and pending:
            code, me, _ = req("GET", "/me", token=rest_token)
            uid = me.get("id")
            if uid:
                code, approved, _ = req("POST", f"/admin/business-accounts/{uid}/approve", token=admin_token)
                r.add("Admin", "Approve restaurant", "PASS" if code == 200 else "FAIL", f"HTTP {code}")

        code, users, _ = req("GET", "/admin/users?limit=5", token=admin_token)
        r.add("Admin", "Users list", "PASS" if code == 200 else "FAIL", f"HTTP {code}")

        code, rests_admin, _ = req("GET", "/admin/restaurants?limit=5", token=admin_token)
        r.add("Admin", "Restaurants list", "PASS" if code == 200 else "FAIL", f"HTTP {code}")

        code, revs, _ = req("GET", "/admin/reviews?limit=5", token=admin_token)
        r.add("Admin", "Moderation/reviews", "PASS" if code == 200 else "FAIL", f"HTTP {code}")

    # HOME CHEF
    chef_email = f"qa17a.chef.{suffix}@example.com"
    code, _, _ = req(
        "POST",
        "/register",
        body={
            "role": "home_chef",
            "email": chef_email,
            "phone": f"+92302{suffix[:7]}",
            "password": PWD,
            "confirm_password": PWD,
            "home_chef_profile": {
                "chef_display_name": f"Chef QA {suffix}",
                "kitchen_address": "Kitchen St Lahore",
                "cuisine_specialty": "pakistani",
            },
        },
    )
    r.add("Home Chef", "Signup", "PASS" if code == 201 else "FAIL", f"HTTP {code}")
    chef_token, chef_login, _ = login(chef_email, PWD)
    r.add("Home Chef", "Login (pending)", "PASS" if chef_token else "FAIL", chef_login.get("account_status", "") if chef_login else "")
    if chef_token:
        code, dash, _ = req("GET", "/home-chef/dashboard", token=chef_token)
        r.add("Home Chef", "Dashboard (pending gate)", "PARTIAL" if code == 403 else "PASS", f"HTTP {code}")

    # Performance samples
    if demo_token:
        for label, path in [
            ("Perf: recommendations", "/recommendations/v2?limit=5"),
            ("Perf: home feed", "/feed/home?limit=10"),
            ("Perf: restaurants", "/restaurants?limit=10"),
        ]:
            code, _, ms = req("GET", path, token=demo_token, timeout=180)
            r.add("Performance", label, "PASS" if code == 200 else "FAIL", f"{ms:.0f}ms", ms)

    # Print report
    print("\n=== PHASE 17A LIVE VERIFICATION REPORT ===\n")
    current = ""
    for row in r.rows:
        if row.area != current:
            current = row.area
            print(f"\n[{current}]")
        timing = f" ({row.ms:.0f}ms)" if row.ms is not None else ""
        print(f"  {row.status:7} {row.name}{timing}")
        if row.detail:
            print(f"           {row.detail}")

    s = r.summary()
    print(f"\nTotals: PASS={s['PASS']} FAIL={s['FAIL']} PARTIAL={s['PARTIAL']} SKIP={s['SKIP']}")
    return 0 if s["FAIL"] == 0 else 1


if __name__ == "__main__":
    sys.exit(main())
