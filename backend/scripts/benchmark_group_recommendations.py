#!/usr/bin/env python
"""Benchmark cold group recommendation generation time."""

from __future__ import annotations

import json
import sys
import time
import urllib.error
import urllib.request
import uuid

BASE = "http://127.0.0.1:8000"
PASSWORD = "Demo1234!"


def req(method, path, token=None, body=None, timeout=180):
    url = f"{BASE}{path}"
    data = json.dumps(body).encode() if body else None
    headers = {"Content-Type": "application/json"}
    if token:
        headers["Authorization"] = f"Bearer {token}"
    request = urllib.request.Request(url, data=data, headers=headers, method=method)
    t0 = time.perf_counter()
    with urllib.request.urlopen(request, timeout=timeout) as resp:
        raw = resp.read().decode()
        ms = (time.perf_counter() - t0) * 1000
        return json.loads(raw) if raw else {}, ms


def register(label: str) -> tuple[str, int]:
    email = f"bench_{label}_{uuid.uuid4().hex[:8]}@example.com"
    username = f"bench{label}{uuid.uuid4().hex[:6]}"
    req(
        "POST",
        "/register",
        body={
            "full_name": f"Bench {label}",
            "email": email,
            "username": username,
            "password": PASSWORD,
        },
    )
    data, _ = req("POST", "/login", body={"email": email, "password": PASSWORD})
    me, _ = req("GET", "/me", token=data["access_token"])
    return data["access_token"], me["id"]


def main():
    host_token, host_id = register("host")
    friend_token, friend_id = register("friend")

    fr, _ = req(
        "POST",
        "/friends/request",
        token=host_token,
        body={"receiver_id": friend_id},
    )
    req("POST", f"/friends/request/{fr['id']}/accept", token=friend_token)

    session, _ = req(
        "POST",
        "/groups",
        token=host_token,
        body={"name": "Bench Group"},
    )
    sid = session["id"]

    inv, _ = req(
        "POST",
        f"/groups/{sid}/invite",
        token=host_token,
        body={"receiver_id": friend_id},
    )
    req("POST", f"/groups/invitations/{inv['id']}/accept", token=friend_token)

    req(
        "POST",
        f"/groups/{sid}/location",
        token=host_token,
        body={"latitude": 31.4824, "longitude": 74.3237},
    )
    req(
        "POST",
        f"/groups/{sid}/location",
        token=friend_token,
        body={"latitude": 31.4850, "longitude": 74.3250},
    )

    recs, cold_ms = req("GET", f"/groups/{sid}/recommendations", token=host_token)
    _, warm_ms = req("GET", f"/groups/{sid}/recommendations", token=host_token)

    items = recs.get("recommendations") or recs.get("items") or []
    print(f"Cold group recommendations: {cold_ms:.0f}ms ({len(items)} items)")
    print(f"Warm group recommendations: {warm_ms:.0f}ms")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except urllib.error.HTTPError as e:
        print(f"HTTP {e.code}: {e.read().decode()}", file=sys.stderr)
        raise SystemExit(1)
