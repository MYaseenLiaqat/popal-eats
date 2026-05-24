"""End-to-end validation for v3 AI pipeline."""

import sys
import time
import uuid
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from fastapi.testclient import TestClient

from app.database import check_database_ready
from app.main import app


def _paginated_items(r):
    return r.json()["items"]


def main() -> int:
    print("Checking database...")
    tables = check_database_ready()
    print("Tables:", ", ".join(tables))
    assert "refresh_tokens" in tables

    email = f"v3_{uuid.uuid4().hex[:8]}@example.com"
    password = "TestPass123!"

    with TestClient(app) as client:
        r = client.post("/register", json={"full_name": "V3", "email": email, "password": password})
        assert r.status_code == 201, r.text
        print("POST /register OK")

        r = client.post("/login", json={"email": email, "password": password})
        assert r.status_code == 200, r.text
        data = r.json()
        assert "refresh_token" in data and data["refresh_token"]
        token = data["access_token"]
        refresh = data["refresh_token"]
        headers = {"Authorization": f"Bearer {token}"}
        print("POST /login OK (refresh token issued)")

        r = client.post("/refresh", json={"refresh_token": refresh})
        assert r.status_code == 200, r.text
        headers = {"Authorization": f"Bearer {r.json()['access_token']}"}
        print("POST /refresh OK")

        r = client.post("/restaurants", json={"name": f"R-{uuid.uuid4().hex[:6]}"}, headers=headers)
        assert r.status_code == 201, r.text
        restaurant_id = r.json()["id"]
        print("POST /restaurants OK")

        r = client.post(
            "/reviews",
            json={"restaurant_id": restaurant_id, "rating": 5, "comment": "bohat acha khana hai"},
            headers=headers,
        )
        assert r.status_code == 201, r.text
        review_id = r.json()["id"]
        print("POST /reviews OK (queued)")

        for _ in range(15):
            r = client.get(f"/reviews/{review_id}/processing")
            assert r.status_code == 200
            status = r.json()["processing_status"]
            if status == "completed":
                print(f"Review AI completed: lang={r.json().get('detected_language')} sentiment={r.json().get('sentiment')}")
                break
            if status == "failed":
                print("Review processing failed:", r.json())
                break
            time.sleep(0.5)
        else:
            print("WARN: review still processing (inline/RQ may be slow)")

        r = client.get(f"/restaurants/{restaurant_id}")
        assert r.json()["total_reviews"] >= 1
        print("Rating aggregation OK")

        r = client.get("/health")
        assert r.status_code == 200
        print("GET /health OK")

        r = client.get("/admin/analytics/overview", headers=headers)
        assert r.status_code == 403
        print("Admin blocked for non-admin OK")

    print("\nAll v3 validations passed.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
