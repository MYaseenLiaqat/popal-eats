#!/usr/bin/env python
"""Phase 18 — Final E2E QA & release certification (HTTP + DB checks)."""

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
    part: str
    name: str
    status: str  # PASS | FAIL | PARTIAL | SKIP
    detail: str = ""
    ms: float | None = None
    severity: str = ""  # Critical | High | Medium | Low (for FAIL/PARTIAL)


@dataclass
class Report:
    rows: list[Result] = field(default_factory=list)
    bugs: list[dict] = field(default_factory=list)

    def add(
        self,
        part: str,
        name: str,
        status: str,
        detail: str = "",
        ms: float | None = None,
        severity: str = "",
    ):
        self.rows.append(Result(part, name, status, detail, ms, severity))
        if status in ("FAIL", "PARTIAL") and severity:
            self.bugs.append(
                {"part": part, "name": name, "status": status, "detail": detail, "severity": severity}
            )

    def counts(self) -> dict[str, int]:
        out = {"PASS": 0, "FAIL": 0, "PARTIAL": 0, "SKIP": 0}
        for r in self.rows:
            out[r.status] = out.get(r.status, 0) + 1
        return out


def req(method: str, path: str, token: str | None = None, body: dict | None = None, timeout: int = 180):
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


def login(email: str, password: str) -> tuple[str | None, dict | None]:
    code, data, _ = req("POST", "/login", body={"email": email, "password": password})
    if code != 200:
        return None, data
    return data.get("access_token"), data


def run_db_checks(r: Report) -> None:
    try:
        from sqlalchemy import func, text
        from app.database import SessionLocal
        from app.models.dish import Dish
        from app.models.order import Order
        from app.models.post import Post
        from app.models.restaurant import Restaurant
        from app.models.review import Review
        from app.models.story import Story
        from app.models.user import User
        from app.models.home_chef_profile import HomeChefProfile
    except Exception as exc:
        r.add("Database", "Import models", "FAIL", str(exc), severity="Critical")
        return

    db = SessionLocal()
    try:
        users = db.query(func.count(User.id)).scalar() or 0
        restaurants = db.query(func.count(Restaurant.id)).scalar() or 0
        chefs = db.query(func.count(HomeChefProfile.id)).scalar() or 0
        orders = db.query(func.count(Order.id)).scalar() or 0
        reviews = db.query(func.count(Review.id)).scalar() or 0
        posts = db.query(func.count(Post.id)).scalar() or 0
        stories = db.query(func.count(Story.id)).scalar() or 0
        dishes = db.query(func.count(Dish.id)).scalar() or 0

        r.add("Database", "Users count", "PASS", str(users))
        r.add("Database", "Restaurants count", "PASS", str(restaurants))
        r.add("Database", "Home chefs count", "PASS", str(chefs))
        r.add("Database", "Orders count", "PASS", str(orders))
        r.add("Database", "Reviews count", "PASS", str(reviews))
        r.add("Database", "Posts count", "PASS", str(posts))
        r.add("Database", "Stories count", "PASS", str(stories))
        r.add("Database", "Dishes count", "PASS", str(dishes))

        orphan_dishes = (
            db.query(func.count(Dish.id))
            .filter(~Dish.restaurant_id.in_(db.query(Restaurant.id)))
            .scalar()
            or 0
        )
        r.add(
            "Database",
            "Orphan dishes (no restaurant)",
            "PASS" if orphan_dishes == 0 else "FAIL",
            f"count={orphan_dishes}",
            severity="High" if orphan_dishes else "",
        )

        orphan_reviews = (
            db.query(func.count(Review.id))
            .filter(~Review.restaurant_id.in_(db.query(Restaurant.id)))
            .scalar()
            or 0
        )
        r.add(
            "Database",
            "Orphan reviews (no restaurant)",
            "PASS" if orphan_reviews == 0 else "FAIL",
            f"count={orphan_reviews}",
            severity="High" if orphan_reviews else "",
        )

        pending_users = (
            db.query(func.count(User.id)).filter(User.account_status == "pending").scalar() or 0
        )
        r.add("Database", "Pending business users", "PASS", f"{pending_users} pending")

        try:
            rec_events = db.execute(text("SELECT COUNT(*) FROM recommendation_events")).scalar()
            r.add("Database", "Recommendation events", "PASS", str(rec_events))
        except Exception as exc:
            r.add("Database", "Recommendation events", "PARTIAL", str(exc), severity="Low")
    finally:
        db.close()


def run_security_checks(r: Report, customer_token: str | None, admin_token: str | None) -> None:
    # No token
    code, data, _ = req("GET", "/admin/analytics/overview")
    r.add(
        "Security",
        "Admin route without JWT",
        "PASS" if code in (401, 403) else "FAIL",
        f"HTTP {code}",
        severity="Critical" if code == 200 else "",
    )

    # Customer cannot access admin
    if customer_token:
        code, _, _ = req("GET", "/admin/users?limit=1", token=customer_token)
        r.add(
            "Security",
            "Customer blocked from admin",
            "PASS" if code in (401, 403) else "FAIL",
            f"HTTP {code}",
            severity="Critical" if code == 200 else "",
        )

    # Invalid token
    code, _, _ = req("GET", "/me", token="invalid.jwt.token")
    r.add(
        "Security",
        "Invalid JWT rejected",
        "PASS" if code == 401 else "FAIL",
        f"HTTP {code}",
        severity="High" if code == 200 else "",
    )

    # Business approval without admin
    if customer_token:
        code, _, _ = req("POST", "/admin/business-accounts/1/approve", token=customer_token)
        r.add(
            "Security",
            "Approve endpoint RBAC",
            "PASS" if code in (401, 403, 404) else "FAIL",
            f"HTTP {code}",
            severity="Critical" if code == 200 else "",
        )

    # Input validation
    code, _, _ = req("POST", "/login", body={"email": "not-an-email", "password": "x"})
    r.add(
        "Security",
        "Login input validation",
        "PASS" if code in (400, 401, 422) else "FAIL",
        f"HTTP {code}",
        severity="Medium" if code == 200 else "",
    )

    if admin_token:
        r.add("Security", "Admin JWT valid", "PASS", "admin token issued")


def main() -> int:
    global BASE
    if len(sys.argv) > 1:
        BASE = sys.argv[1].rstrip("/")

    r = Report()
    suffix = uuid.uuid4().hex[:8]
    print(f"Phase 18 Release Certification — {BASE}\n")

    code, health, ms = req("GET", "/health")
    r.add("Infra", "GET /health", "PASS" if code == 200 else "FAIL", str(health), ms, severity="Critical" if code != 200 else "")

    # ── PART 1 Customer ─────────────────────────────────────────────────────
    cust_email = f"qa18.cust.{suffix}@example.com"
    code, _, ms = req(
        "POST",
        "/register",
        body={
            "role": "customer",
            "email": cust_email,
            "phone": f"+92310{suffix[:7]}",
            "password": PWD,
            "confirm_password": PWD,
            "first_name": "QA18",
            "last_name": "Customer",
            "date_of_birth": "2000-01-15",
        },
    )
    r.add("Customer", "Signup", "PASS" if code == 201 else "FAIL", f"HTTP {code}", ms, severity="Critical" if code != 201 else "")

    token, login_data = login(cust_email, PWD)
    r.add("Customer", "Login", "PASS" if token else "FAIL", login_data.get("role", "") if login_data else "", severity="Critical" if not token else "")

    demo_token, _ = login("demo.host@example.com", DEMO)
    r.add("Customer", "Login (demo)", "PASS" if demo_token else "FAIL", severity="High" if not demo_token else "")

    r.add("Customer", "Forgot password", "SKIP", "No backend endpoint")

    rest_id = dish_id = None
    if token:
        code, _, _ = req("POST", "/preferences/onboarding", token=token, body={"favorite_cuisines": ["pakistani"], "allergies": []})
        r.add("Customer", "Onboarding", "PASS" if code in (200, 201) else "FAIL", f"HTTP {code}")

        code, _, _ = req("PUT", "/preferences", token=token, body={"nutrition_goal": "maintain", "budget_level": "medium"})
        r.add("Customer", "Preference setup", "PASS" if code == 200 else "FAIL", f"HTTP {code}")

        code, feed, ms = req("GET", "/feed/home?limit=10", token=token)
        items = feed.get("items", []) if isinstance(feed, dict) else []
        r.add("Customer", "Browse Home (feed)", "PASS" if code == 200 else "FAIL", f"{len(items)} posts", ms)

        code, rests, ms = req("GET", "/restaurants?limit=10", token=token)
        r.add("Customer", "Browse Order (restaurants)", "PASS" if code == 200 else "FAIL", f"HTTP {code}", ms)
        raw = rests.get("items", rests) if isinstance(rests, dict) else rests
        if isinstance(raw, list) and raw:
            rest_id = raw[0].get("id")

        if rest_id:
            code, _, ms = req("GET", f"/restaurants/{rest_id}", token=token)
            r.add("Customer", "Restaurant details", "PASS" if code == 200 else "FAIL", f"id={rest_id}", ms)
            code, dishes, _ = req("GET", f"/dishes?restaurant_id={rest_id}&limit=5", token=token)
            ditems = dishes.get("items", dishes) if isinstance(dishes, dict) else dishes
            if isinstance(ditems, list) and ditems:
                dish_id = ditems[0].get("id")
            if dish_id:
                code, _, ms = req("GET", f"/dishes/{dish_id}", token=token)
                r.add("Customer", "Dish details", "PASS" if code == 200 else "FAIL", f"id={dish_id}", ms)

        if dish_id:
            code, _, _ = req("POST", "/cart/add", token=token, body={"dish_id": dish_id, "quantity": 2})
            code, cart, _ = req("GET", "/cart", token=token)
            items = cart.get("items", []) if isinstance(cart, dict) else []
            count = len(items) if isinstance(items, list) else cart.get("item_count", 0)
            r.add("Customer", "Add to cart + quantity", "PASS" if code == 200 and count > 0 else "FAIL", f"items={count}")

            code, order, ms = req("POST", "/checkout", token=token, body={"delivery_address": "QA18 Street Lahore"})
            r.add("Customer", "Checkout", "PASS" if code in (200, 201) else "FAIL", f"HTTP {code}", ms, severity="Critical" if code not in (200, 201) else "")

            code, orders, _ = req("GET", "/orders/my-orders?limit=5", token=token)
            olist = orders if isinstance(orders, list) else []
            r.add("Customer", "Order history", "PASS" if code == 200 and olist else "PARTIAL", f"{len(olist)} orders", severity="Medium" if not olist else "")

        code, _, _ = req("GET", "/orders/my-orders?limit=20", token=token)
        r.add("Customer", "Health dashboard (orders data)", "PASS" if code == 200 else "FAIL", f"HTTP {code}")

        code, _, _ = req("GET", "/friends", token=token)
        r.add("Customer", "Community (friends)", "PASS" if code == 200 else "FAIL", f"HTTP {code}")

        code, me, _ = req("GET", "/me", token=token)
        r.add("Customer", "Profile /me", "PASS" if code == 200 else "FAIL", me.get("email", ""))

        code, _, _ = req("POST", "/logout", token=token, body={"refresh_token": (login_data or {}).get("refresh_token", "")})
        r.add("Customer", "Logout", "PASS" if code in (200, 204) else "PARTIAL", f"HTTP {code}")

    r.add("Customer", "Order success screen (UI)", "SKIP", "API checkout verified; UI not automated")

    # ── PART 2 Restaurant ───────────────────────────────────────────────────
    rest_email = f"qa18.rest.{suffix}@example.com"
    code, _, _ = req(
        "POST",
        "/register",
        body={
            "role": "restaurant",
            "email": rest_email,
            "phone": f"+92311{suffix[:7]}",
            "password": PWD,
            "confirm_password": PWD,
            "restaurant_profile": {
                "restaurant_name": f"QA18 Kitchen {suffix}",
                "restaurant_address": "Test Rd Lahore",
                "cuisine_type": "pakistani",
            },
        },
    )
    r.add("Restaurant", "Register", "PASS" if code == 201 else "FAIL", f"HTTP {code}")

    rest_token, rest_login = login(rest_email, PWD)
    pending = (rest_login or {}).get("account_status") == "pending"
    r.add("Restaurant", "Pending status", "PASS" if pending else "PARTIAL", str((rest_login or {}).get("account_status")))

    owner_token, _ = login("demo.owner@example.com", DEMO)
    r.add("Restaurant", "Login (approved demo)", "PASS" if owner_token else "FAIL", severity="High" if not owner_token else "")

    owner_rest_id = None
    if owner_token:
        code, me, _ = req("GET", "/me", token=owner_token)
        uid = me.get("id")
        code, rests, _ = req("GET", "/restaurants?limit=50", token=owner_token)
        items = rests.get("items", rests) if isinstance(rests, dict) else rests
        if isinstance(items, list):
            for item in items:
                if item.get("owner_id") == uid:
                    owner_rest_id = item.get("id")
                    break
        dash_path = f"/restaurants/{owner_rest_id}/dashboard" if owner_rest_id else "/restaurants/dashboard"
        code, dash, ms = req("GET", dash_path, token=owner_token)
        r.add("Restaurant", "Dashboard", "PASS" if code == 200 else "FAIL", f"{dash_path} HTTP {code}", ms)

        code, menu, _ = req("GET", f"/dishes?restaurant_id={owner_rest_id}&limit=10" if owner_rest_id else "/dishes?limit=10", token=owner_token)
        r.add("Restaurant", "Menu management (list)", "PASS" if code == 200 else "FAIL", f"HTTP {code}")

        code, orders, _ = req("GET", f"/restaurants/{owner_rest_id}/orders?limit=5" if owner_rest_id else "/orders/my-orders", token=owner_token)
        r.add("Restaurant", "Order management", "PASS" if code == 200 else "PARTIAL", f"HTTP {code}", severity="Low" if code != 200 else "")

        code, _, _ = req("GET", "/me", token=owner_token)
        r.add("Restaurant", "Profile /me", "PASS" if code == 200 else "FAIL", f"HTTP {code}")

    # ── PART 3 Home Chef ────────────────────────────────────────────────────
    chef_email = f"qa18.chef.{suffix}@example.com"
    code, _, _ = req(
        "POST",
        "/register",
        body={
            "role": "home_chef",
            "email": chef_email,
            "phone": f"+92312{suffix[:7]}",
            "password": PWD,
            "confirm_password": PWD,
            "home_chef_profile": {
                "chef_display_name": f"Chef18 {suffix}",
                "kitchen_address": "Kitchen Lahore",
                "cuisine_specialty": "pakistani",
            },
        },
    )
    r.add("Home Chef", "Register", "PASS" if code == 201 else "FAIL", f"HTTP {code}")

    chef_token, chef_login = login(chef_email, PWD)
    r.add("Home Chef", "Pending status", "PASS" if (chef_login or {}).get("account_status") == "pending" else "PARTIAL", str((chef_login or {}).get("account_status")))

    if chef_token:
        code, _, _ = req("GET", "/home-chef/dashboard", token=chef_token)
        r.add("Home Chef", "Dashboard gate (pending)", "PASS" if code == 403 else "PARTIAL", f"HTTP {code} (403 expected)")

    # ── PART 4 Admin ──────────────────────────────────────────────────────
    admin_token, _ = login("admin@popaleats.com", ADMIN_PWD)
    r.add("Admin", "Login", "PASS" if admin_token else "FAIL", severity="Critical" if not admin_token else "")

    if admin_token:
        admin_pages = [
            ("Dashboard", "/admin/analytics/overview"),
            ("Business Approvals", "/admin/business-accounts/pending"),
            ("Restaurants", "/admin/restaurants?limit=5"),
            ("Customers", "/admin/users?role=customer&limit=5"),
            ("Reviews", "/admin/reviews?limit=5"),
        ]
        for name, path in admin_pages:
            code, data, ms = req("GET", path, token=admin_token)
            extra = ""
            if name == "Business Approvals" and isinstance(data, list):
                extra = f"{len(data)} pending"
            r.add("Admin", name, "PASS" if code == 200 else "FAIL", extra or f"HTTP {code}", ms)

        r.add("Admin", "Orders page data", "PARTIAL", "No /admin/orders API — UI shows review activity", severity="Low")
        r.add("Admin", "Analytics/Reports/Settings/Profile (UI)", "SKIP", "Sidebar pages use same APIs; manual UI walk recommended")

        if rest_token and pending:
            code, me, _ = req("GET", "/me", token=rest_token)
            uid = me.get("id")
            if uid:
                code, _, _ = req("POST", f"/admin/business-accounts/{uid}/approve", token=admin_token)
                r.add("Admin", "Approve restaurant", "PASS" if code == 200 else "FAIL", f"HTTP {code}")

        if chef_token:
            code, me, _ = req("GET", "/me", token=chef_token)
            uid = me.get("id")
            if uid:
                code, _, _ = req("POST", f"/admin/business-accounts/{uid}/approve", token=admin_token)
                r.add("Admin", "Approve home chef", "PASS" if code == 200 else "FAIL", f"HTTP {code}")

    # ── PART 5 Recommendations ──────────────────────────────────────────────
    rec_token = demo_token or token
    if rec_token:
        code, rec, ms_cold = req("GET", "/recommendations/v2?limit=10", token=rec_token)
        items = rec.get("items", rec) if isinstance(rec, dict) else rec
        n = len(items) if isinstance(items, list) else 0
        r.add("Recommendations", "V2 recommendations (cold)", "PASS" if code == 200 else "FAIL", f"{n} items", ms_cold)

        code, _, ms_warm = req("GET", "/recommendations/v2?limit=10", token=rec_token)
        r.add("Recommendations", "V2 recommendations (warm)", "PASS" if code == 200 else "FAIL", f"{ms_warm:.0f}ms", ms_warm)

        code, trend, _ = req("GET", "/recommendations/v2/trending?limit=10", token=rec_token)
        titems = trend if isinstance(trend, list) else trend.get("items", [])
        r.add("Recommendations", "Trending", "PASS" if code == 200 else "FAIL", f"{len(titems) if isinstance(titems, list) else 0} items")

        code, pop, _ = req("GET", "/recommendations/v2/popular?limit=10", token=rec_token)
        pitems = pop if isinstance(pop, list) else pop.get("items", [])
        r.add("Recommendations", "Popular", "PASS" if code == 200 else "FAIL", f"{len(pitems) if isinstance(pitems, list) else 0} items")

        code, _, _ = req("GET", "/recommendations/v2/profile", token=rec_token)
        r.add("Recommendations", "Health/feedback profile", "PASS" if code == 200 else "PARTIAL", f"HTTP {code}", severity="Low" if code != 200 else "")

    # Seed markers in API
    if demo_token:
        code, feed, _ = req("GET", "/feed/home?limit=20", token=demo_token)
        items = feed.get("items", []) if isinstance(feed, dict) else []
        markers = sum(1 for p in items if isinstance(p, dict) and SEED_MARKER.search(p.get("caption") or ""))
        r.add("UI/Data", "Seed markers in feed API", "PASS" if markers == 0 else "PARTIAL", f"{markers} posts", severity="Low" if markers else "")

    # ── PART 6 Database ─────────────────────────────────────────────────────
    run_db_checks(r)

    # ── PART 9 Security ─────────────────────────────────────────────────────
    run_security_checks(r, demo_token or token, admin_token)

    # ── PART 8 Performance ──────────────────────────────────────────────────
    if demo_token:
        perf_paths = [
            ("Login", "POST", "/login", {"email": "demo.host@example.com", "password": DEMO}),
            ("Signup", "POST", "/register", {
                "role": "customer", "email": f"perf.{suffix}@example.com",
                "phone": f"+92319{suffix[:7]}", "password": PWD, "confirm_password": PWD,
                "first_name": "P", "last_name": "F", "date_of_birth": "2000-01-01",
            }),
            ("Home feed", "GET", "/feed/home?limit=10", None),
            ("Restaurants", "GET", "/restaurants?limit=10", None),
            ("Recommendations", "GET", "/recommendations/v2?limit=10", None),
        ]
        for label, method, path, body in perf_paths:
            if method == "GET":
                code, _, ms = req(method, path, token=demo_token)
            else:
                code, _, ms = req(method, path, body=body)
            slow = ms > 15000
            r.add(
                "Performance",
                label,
                "PARTIAL" if slow else "PASS",
                f"{ms:.0f}ms HTTP {code}",
                ms,
                severity="Medium" if slow else "",
            )

        if admin_token:
            code, _, ms = req("GET", "/admin/analytics/overview", token=admin_token)
            r.add("Performance", "Admin dashboard", "PASS" if code == 200 else "FAIL", f"{ms:.0f}ms", ms)

    # ── Report ──────────────────────────────────────────────────────────────
    print("\n=== PHASE 18 RELEASE CERTIFICATION ===\n")
    current = ""
    for row in r.rows:
        if row.part != current:
            current = row.part
            print(f"\n[{current}]")
        timing = f" ({row.ms:.0f}ms)" if row.ms is not None else ""
        print(f"  {row.status:7} {row.name}{timing}")
        if row.detail:
            print(f"           {row.detail}")

    c = r.counts()
    print(f"\nTotals: PASS={c['PASS']} FAIL={c['FAIL']} PARTIAL={c['PARTIAL']} SKIP={c['SKIP']}")

    critical = [b for b in r.bugs if b["severity"] == "Critical"]
    high = [b for b in r.bugs if b["severity"] == "High"]

    print("\n=== REMAINING BUGS ===")
    if not r.bugs:
        print("  (none logged from automated run)")
    for sev in ("Critical", "High", "Medium", "Low"):
        items = [b for b in r.bugs if b["severity"] == sev]
        if items:
            print(f"\n{sev}:")
            for b in items:
                print(f"  - [{b['part']}] {b['name']}: {b['detail']}")

    if critical:
        print("\n*** RELEASE BLOCKED — Critical issues found ***")
        return 1

    if c["FAIL"] > 0:
        print("\n*** RELEASE CONDITIONAL — Failures present (no Critical) ***")
        return 1

    print("\n*** CERTIFIED: Ready for APK/AAB generation (automated gate) ***")
    print("Manual UI walk (Part 7) still recommended before store submission.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
