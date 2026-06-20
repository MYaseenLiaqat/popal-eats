#!/usr/bin/env python
"""Measure API response times for performance audit (read-only)."""

from __future__ import annotations

import json
import statistics
import sys
import time
import urllib.error
import urllib.request
from pathlib import Path

_backend = Path(__file__).resolve().parent.parent
if str(_backend) not in sys.path:
    sys.path.insert(0, str(_backend))

BASE = "http://127.0.0.1:8000"
DEMO_EMAIL = "demo.host@example.com"
DEMO_PASSWORD = "Demo1234!"
SAMPLES = 5


def req(method, path, token=None, body=None, timeout=180):
    url = f"{BASE}{path}"
    data = json.dumps(body).encode() if body else None
    headers = {"Content-Type": "application/json"}
    if token:
        headers["Authorization"] = f"Bearer {token}"
    request = urllib.request.Request(url, data=data, headers=headers, method=method)
    t0 = time.perf_counter()
    try:
        with urllib.request.urlopen(request, timeout=timeout) as resp:
            raw = resp.read().decode()
            ms = (time.perf_counter() - t0) * 1000
            return resp.status, json.loads(raw) if raw else {}, ms
    except urllib.error.HTTPError as e:
        ms = (time.perf_counter() - t0) * 1000
        try:
            detail = json.loads(e.read().decode())
        except Exception:
            detail = {"error": str(e)}
        return e.code, detail, ms


def login():
    code, data, _ = req("POST", "/login", body={"email": DEMO_EMAIL, "password": DEMO_PASSWORD})
    if code != 200:
        return None
    return data["access_token"]


def bench(name, fn, samples=SAMPLES):
    times = []
    last_status = None
    last_detail = None
    for _ in range(samples):
        status, detail, ms = fn()
        last_status, last_detail = status, detail
        if status < 400:
            times.append(ms)
        time.sleep(0.05)
    if not times:
        return {
            "endpoint": name,
            "status": last_status,
            "avg_ms": None,
            "min_ms": None,
            "max_ms": None,
            "samples": 0,
            "error": str(last_detail)[:200],
        }
    return {
        "endpoint": name,
        "status": last_status,
        "avg_ms": round(statistics.mean(times), 1),
        "min_ms": round(min(times), 1),
        "max_ms": round(max(times), 1),
        "samples": len(times),
    }


def main():
    print(f"Performance audit — {BASE} ({SAMPLES} samples each)\n")
    token = login()
    if not token:
        print("FAIL: cannot login demo.host — run seed_demo_content.py")
        return 1

    # Resolve group session for group recommendations
    code, sessions, _ = req("GET", "/groups", token=token)
    group_session_id = None
    if code == 200:
        if isinstance(sessions, dict):
            items = sessions.get("items") or sessions.get("sessions") or []
        elif isinstance(sessions, list):
            items = sessions
        else:
            items = []
        if items:
            group_session_id = items[0].get("id")

    # Resolve owner restaurant for dashboard
    code, me, _ = req("GET", "/me", token=token)
    owner_token = None
    owner_code, owner_data, _ = req(
        "POST",
        "/login",
        body={"email": "demo.owner@example.com", "password": DEMO_PASSWORD},
    )
    restaurant_id = None
    if owner_code == 200:
        owner_token = owner_data["access_token"]
        code, owned, _ = req("GET", "/restaurants/mine", token=owner_token)
        if code == 200 and isinstance(owned, list) and owned:
            restaurant_id = owned[0].get("id")

    endpoints = [
        ("GET /health", lambda: req("GET", "/health")),
        ("GET /feed/home", lambda: req("GET", "/feed/home?limit=20", token=token)),
        ("GET /stories", lambda: req("GET", "/stories", token=token)),
        ("GET /discover/reels", lambda: req("GET", "/discover/reels", token=token)),
        (
            "GET /recommendations/v2",
            lambda: req("GET", "/recommendations/v2?limit=10", token=token),
        ),
    ]
    if group_session_id:
        endpoints.append(
            (
                f"GET /groups/{group_session_id}/recommendations",
                lambda sid=group_session_id: req(
                    "GET",
                    f"/groups/{sid}/recommendations",
                    token=token,
                    timeout=180,
                ),
            )
        )
    if restaurant_id and owner_token:
        endpoints.append(
            (
                f"GET /restaurants/{restaurant_id}/dashboard",
                lambda rid=restaurant_id, ot=owner_token: req(
                    "GET", f"/restaurants/{rid}/dashboard", token=ot
                ),
            )
        )

    results = []
    for name, fn in endpoints:
        row = bench(name, fn)
        results.append(row)
        if row["avg_ms"] is not None:
            print(
                f"  {row['endpoint']}: avg {row['avg_ms']}ms "
                f"(min {row['min_ms']}, max {row['max_ms']})"
            )
        else:
            print(f"  {row['endpoint']}: ERROR {row.get('error', row['status'])}")

    out_path = _backend.parent / "PERFORMANCE_AUDIT.json"
    out_path.write_text(json.dumps(results, indent=2), encoding="utf-8")
    print(f"\nWrote {out_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
