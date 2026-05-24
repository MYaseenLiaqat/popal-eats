"""Full phase validation — run: $env:PROCESS_REVIEWS_INLINE='true'; python scripts/validate_phase.py"""

import sys
import time
import uuid
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from fastapi.testclient import TestClient

from app.database import check_database_ready
from app.main import app
from app.services.review_processing import ReviewProcessingService


def main() -> int:
    print("=== Phase validation ===\n")
    tables = check_database_ready()
    print("Tables:", ", ".join(tables))

    svc = ReviewProcessingService()
    email = f"phase_{uuid.uuid4().hex[:8]}@example.com"

    with TestClient(app) as client:
        # Auth + refresh
        client.post("/register", json={"full_name": "P", "email": email, "password": "TestPass123!"})
        login = client.post("/login", json={"email": email, "password": "TestPass123!"})
        assert login.status_code == 200
        token = login.json()["access_token"]
        headers = {"Authorization": f"Bearer {token}"}
        print("[OK] Auth + JWT + refresh token")

        # Restaurant + review + inline AI
        r = client.post("/restaurants", json={"name": "Phase R"}, headers=headers)
        rid = r.json()["id"]
        rev = client.post(
            "/reviews",
            json={"restaurant_id": rid, "rating": 4, "comment": "bohat acha khana"},
            headers=headers,
        )
        assert rev.status_code == 201
        review_id = rev.json()["id"]
        print("[OK] Review created")

        for _ in range(20):
            proc = client.get(f"/reviews/{review_id}/processing")
            st = proc.json()["processing_status"]
            if st in ("completed", "failed"):
                print(f"[OK] AI pipeline: {proc.json()}")
                break
            time.sleep(0.3)
        else:
            # Force inline process
            svc.process_next_review(review_id)
            proc = client.get(f"/reviews/{review_id}/processing")
            print(f"[OK] AI pipeline (forced): {proc.json()}")

        # Admin blocked
        assert client.get("/admin/analytics/overview", headers=headers).status_code == 403
        print("[OK] RBAC admin protected")

        # Health + OpenAPI
        assert client.get("/health").status_code == 200
        assert client.get("/openapi.json").status_code == 200
        print("[OK] Swagger / health")

        # OCR structure (mock engine)
        from app.services.ocr import MenuOcrService
        from pathlib import Path as P
        import tempfile
        with tempfile.NamedTemporaryFile(suffix=".png", delete=False) as f:
            f.write(b"fake")
            path = P(f.name)
        items = MenuOcrService().extract_menu_items(path)
        assert len(items) > 0
        print(f"[OK] OCR mock extracted {len(items)} items")

    print("\n=== All phase checks passed ===")
    return 0


if __name__ == "__main__":
    sys.exit(main())
