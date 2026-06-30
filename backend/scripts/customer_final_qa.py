#!/usr/bin/env python
"""Final customer QA — API verification after backend restart."""

from __future__ import annotations

import json
import sys
import urllib.error
import urllib.request

BASE = "http://127.0.0.1:8000"
LOGIN = ("demo.host@example.com", "Demo1234!")


def req(method: str, path: str, token: str | None = None, body: dict | None = None):
    data = json.dumps(body).encode() if body else None
    headers = {"Content-Type": "application/json"}
    if token:
        headers["Authorization"] = f"Bearer {token}"
    request = urllib.request.Request(f"{BASE}{path}", data=data, headers=headers, method=method)
    with urllib.request.urlopen(request, timeout=20) as resp:
        raw = resp.read().decode()
        return resp.status, json.loads(raw) if raw else {}


def main() -> int:
    failures: list[str] = []
    try:
        code, data = req("POST", "/login", body={"email": LOGIN[0], "password": LOGIN[1]})
    except Exception as exc:
        print(f"FAIL login: {exc}")
        return 1
    if code != 200:
        print(f"FAIL login status {code}")
        return 1
    token = data["access_token"]
    print("OK login")

    for q in ("demo", "yas", "lia", "restaurant"):
        code, res = req("GET", f"/users/search?q={q}", token=token)
        n = len(res.get("results", []))
        ok = code == 200 and n > 0
        print(f"{'OK' if ok else 'FAIL'} search {q!r}: {n} results")
        if not ok:
            failures.append(f"search:{q}")

    code, res = req("GET", "/users/suggestions?limit=5", token=token)
    n = len(res.get("results", []))
    ok = code == 200 and n > 0
    print(f"{'OK' if ok else 'FAIL'} suggestions: {n}")
    if not ok:
        failures.append("suggestions")

    code, res = req("GET", "/feed/home?limit=10", token=token)
    posts = res.get("posts", [])
    types = {p.get("post_type") for p in posts}
    bad = types & {"restaurant_post"}
    ok = code == 200 and not bad
    print(f"{'OK' if ok else 'FAIL'} home feed: {len(posts)} posts types={types}")
    if not ok:
        failures.append("home_feed")

    code, res = req("GET", "/recommendations/v2", token=token)
    n = len(res.get("recommendations", res if isinstance(res, list) else []))
    if isinstance(res, dict) and "recommendations" in res:
        n = len(res["recommendations"])
    elif isinstance(res, list):
        n = len(res)
    print(f"{'OK' if code == 200 else 'FAIL'} recommendations: status={code}")

    if failures:
        print("FAILED:", ", ".join(failures))
        return 1
    print("ALL API CHECKS PASSED")
    return 0


if __name__ == "__main__":
    sys.exit(main())
