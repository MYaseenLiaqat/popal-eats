#!/usr/bin/env python
"""Full demo readiness verification via live HTTP API.

Checks user, social, group, restaurant, and content flows.
Usage: python scripts/e2e_demo_verification.py [BASE_URL]
"""

from __future__ import annotations

import json
import sys
import uuid
from dataclasses import dataclass, field
from pathlib import Path

import urllib.error
import urllib.request

_backend = Path(__file__).resolve().parent.parent
if str(_backend) not in sys.path:
    sys.path.insert(0, str(_backend))

BASE = "http://127.0.0.1:8000"
PASSWORD = "FypTest123!"
DEMO_PASSWORD = "Demo1234!"
LAHORE_LAT = 31.4824
LAHORE_LNG = 74.3237


@dataclass
class CheckResult:
    name: str
    passed: bool
    detail: str = ""


@dataclass
class Report:
    results: list[CheckResult] = field(default_factory=list)

    def add(self, name: str, passed: bool, detail: str = "") -> None:
        self.results.append(CheckResult(name, passed, detail))

    @property
    def all_passed(self) -> bool:
        return all(r.passed for r in self.results)


def _request(method: str, path: str, token: str | None = None, body: dict | None = None, timeout: int = 120) -> dict:
    url = f"{BASE}{path}"
    data = None if body is None else json.dumps(body).encode()
    headers = {"Content-Type": "application/json"}
    if token:
        headers["Authorization"] = f"Bearer {token}"
    req = urllib.request.Request(url, data=data, headers=headers, method=method)
    with urllib.request.urlopen(req, timeout=timeout) as resp:
        raw = resp.read().decode()
        return json.loads(raw) if raw else {}


def _login(email: str, password: str) -> tuple[str, int]:
    login = _request("POST", "/login", body={"email": email, "password": password})
    me = _request("GET", "/me", token=login["access_token"])
    return login["access_token"], me["id"]


def main() -> int:
    global BASE
    if len(sys.argv) > 1:
        BASE = sys.argv[1].rstrip("/")

    report = Report()
    print(f"Demo verification — {BASE}\n")

    try:
        health = _request("GET", "/health")
        report.add("Health check", health.get("status") == "ok", str(health))
    except Exception as exc:
        report.add("Health check", False, str(exc))
        _print_report(report)
        return 1

    # User flow
    email = f"verify_{uuid.uuid4().hex[:8]}@example.com"
    username = f"verify{uuid.uuid4().hex[:8]}"
    try:
        _request(
            "POST",
            "/register",
            body={
                "full_name": "Verify User",
                "username": username,
                "email": email,
                "password": PASSWORD,
            },
        )
        token, uid = _login(email, PASSWORD)
        report.add("Signup + login", True, f"user_id={uid}")
    except Exception as exc:
        report.add("Signup + login", False, str(exc))
        token, uid = None, None

    if token:
        try:
            _request("POST", "/preferences/onboarding", token=token, body={"favorite_cuisines": ["biryani"], "allergies": []})
            report.add("Preferences onboarding", True)
        except Exception as exc:
            report.add("Preferences onboarding", False, str(exc))

        try:
            recs = _request("GET", "/recommendations/v2", token=token, timeout=180)
            count = len(recs.get("recommendations", recs if isinstance(recs, list) else []))
            if isinstance(recs, dict) and "items" in recs:
                count = len(recs["items"])
            report.add("Personal recommendations", count > 0, f"{count} items")
        except Exception as exc:
            try:
                recs = _request("GET", "/recommendations", token=token, timeout=180)
                count = len(recs) if isinstance(recs, list) else len(recs.get("recommendations", []))
                report.add("Personal recommendations", count > 0, f"{count} items (legacy path)")
            except Exception as exc2:
                report.add("Personal recommendations", False, str(exc2))

    # Demo seeded content
    try:
        token, _ = _login("demo.host@example.com", DEMO_PASSWORD)
        feed = _request("GET", "/feed/home", token=token)
        posts = len(feed.get("items", []))
        report.add("Home feed (demo host)", posts > 0, f"{posts} posts")
    except urllib.error.HTTPError:
        report.add("Home feed (demo host)", False, "Run: python scripts/seed_demo_content.py")
    except Exception as exc:
        report.add("Home feed (demo host)", False, str(exc))

    try:
        token, _ = _login("demo.host@example.com", DEMO_PASSWORD)
        stories = _request("GET", "/stories", token=token)
        groups = len(stories.get("groups", []))
        report.add("Stories API", groups >= 0, f"{groups} story groups")
    except Exception as exc:
        report.add("Stories API", False, str(exc))

    try:
        reels = _request("GET", "/discover/reels")
        items = len(reels.get("items", []))
        report.add("Discover reels", items >= 0, f"{items} items")
    except Exception as exc:
        report.add("Discover reels", False, str(exc))

    # Social post create
    if token:
        try:
            post = _request(
                "POST",
                "/posts",
                token=token,
                body={"post_type": "food_post", "caption": "E2E verify post"},
            )
            pid = post.get("id")
            _request("POST", f"/posts/{pid}/like", token=token)
            _request("DELETE", f"/posts/{pid}/like", token=token)
            report.add("Post create + like", pid is not None, f"post_id={pid}")
        except Exception as exc:
            report.add("Post create + like", False, str(exc))

    # Group flow (abbreviated)
    try:
        user_a_email = f"grp_a_{uuid.uuid4().hex[:6]}@example.com"
        user_b_email = f"grp_b_{uuid.uuid4().hex[:6]}@example.com"
        for em in (user_a_email, user_b_email):
            _request(
                "POST",
                "/register",
                body={
                    "full_name": em,
                    "username": f"grp{uuid.uuid4().hex[:8]}",
                    "email": em,
                    "password": PASSWORD,
                },
            )
        tok_a, id_a = _login(user_a_email, PASSWORD)
        tok_b, id_b = _login(user_b_email, PASSWORD)
        for t in (tok_a, tok_b):
            _request("POST", "/preferences/onboarding", token=t, body={"favorite_cuisines": ["burger"], "allergies": []})

        fr = _request("POST", "/friends/request", token=tok_a, body={"receiver_id": id_b})
        _request("POST", f"/friends/request/{fr['id']}/accept", token=tok_b)

        grp = _request("POST", "/groups", token=tok_a, body={"name": "Verify Group"})
        sid = grp["id"]
        inv = _request("POST", f"/groups/{sid}/invite", token=tok_a, body={"receiver_id": id_b})
        _request("POST", f"/groups/invitations/{inv['id']}/accept", token=tok_b)

        for t in (tok_a, tok_b):
            _request("POST", f"/groups/{sid}/location", token=t, body={"latitude": LAHORE_LAT, "longitude": LAHORE_LNG})

        recs = _request("GET", f"/groups/{sid}/recommendations", token=tok_a, timeout=180)
        recommendations = recs.get("recommendations", [])
        report.add("Group recommendations", len(recommendations) > 0, f"{len(recommendations)} dishes")

        if recommendations:
            rid = recommendations[0]["recommendation_id"]
            _request("POST", f"/groups/recommendations/{rid}/vote", token=tok_a, body={"vote_type": "LOVE"})
            _request("POST", f"/groups/recommendations/{rid}/vote", token=tok_b, body={"vote_type": "LIKE"})
            decision = _request("GET", f"/groups/{sid}/decision", token=tok_a)
            report.add("Group voting + decision", decision.get("status") in {"considering", "agreed", "ordered"}, decision.get("status", ""))
        else:
            report.add("Group voting + decision", False, "no recommendations")
    except Exception as exc:
        report.add("Group flow", False, str(exc))

    # Restaurant flow
    try:
        owner_email = f"owner_{uuid.uuid4().hex[:6]}@example.com"
        _request(
            "POST",
            "/register",
            body={
                "full_name": "Verify Owner",
                "username": f"owner{uuid.uuid4().hex[:8]}",
                "email": owner_email,
                "password": PASSWORD,
            },
        )
        tok_o, _ = _login(owner_email, PASSWORD)
        rest = _request(
            "POST",
            "/restaurants",
            token=tok_o,
            body={"name": f"Verify Kitchen {uuid.uuid4().hex[:4]}", "city": "Lahore", "address": "Demo St"},
        )
        rid = rest.get("id")
        status = rest.get("approval_status", "pending")
        report.add("Restaurant registration", rid is not None, f"id={rid} status={status}")
    except Exception as exc:
        report.add("Restaurant registration", False, str(exc))

    # Catalog stats
    try:
        from app.database import SessionLocal
        from app.models.dish import Dish
        from app.models.restaurant import Restaurant
        from app.services.recommendation.v2_candidates import load_eligible_dishes

        db = SessionLocal()
        try:
            rest_count = db.query(Restaurant).filter(Restaurant.source == "foodpanda").count()
            dish_count = db.query(Dish).count()
            eligible = len(load_eligible_dishes(db))
            report.add("Catalog (foodpanda restaurants)", rest_count >= 100, f"{rest_count} restaurants")
            report.add("Catalog (dishes)", dish_count >= 1000, f"{dish_count} dishes")
            report.add("Recommendation candidates", eligible >= 100, f"{eligible} eligible")
        finally:
            db.close()
    except Exception as exc:
        report.add("Catalog stats", False, str(exc))

    _print_report(report)
    return 0 if report.all_passed else 1


def _print_report(report: Report) -> None:
    print()
    passed = sum(1 for r in report.results if r.passed)
    total = len(report.results)
    for r in report.results:
        mark = "PASS" if r.passed else "FAIL"
        line = f"  [{mark}] {r.name}"
        if r.detail:
            line += f" — {r.detail}"
        print(line)
    print(f"\nResult: {passed}/{total} passed")


if __name__ == "__main__":
    sys.exit(main())
