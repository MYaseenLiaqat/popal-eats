"""Audit restaurant catalog coverage by Lahore area keywords."""

from __future__ import annotations

import json
import sys
from collections import defaultdict
from pathlib import Path

_backend = Path(__file__).resolve().parent.parent
if str(_backend) not in sys.path:
    sys.path.insert(0, str(_backend))

from sqlalchemy import func, or_

from app.database import SessionLocal
from app.models.dish import Dish
from app.models.restaurant import Restaurant

AREA_KEYWORDS: dict[str, list[str]] = {
    "Valencia": ["valencia"],
    "Lake City": ["lake city", "lakecity"],
    "DHA": ["dha", "defence", "defense"],
    "Johar Town": ["johar"],
    "Gulberg": ["gulberg"],
    "Model Town": ["model town"],
    "Bahria Town": ["bahria"],
    "Allama Iqbal Town": ["iqbal town", "allama iqbal"],
    "Wapda Town": ["wapda"],
    "Cantt": ["cantt"],
}

LAHORE_TOTAL_QUERY = or_(
    Restaurant.city.ilike("%Lahore%"),
    Restaurant.city.is_(None),
    Restaurant.city == "",
)


def _manifest_stats() -> dict:
    manifest_path = _backend / "data" / "foodpanda" / "lahore" / "latest" / "manifest.json"
    if not manifest_path.is_file():
        return {"available": False, "path": str(manifest_path)}

    payload = json.loads(manifest_path.read_text(encoding="utf-8"))
    vendors = payload.get("vendors") or []
    by_anchor: dict[str, int] = defaultdict(int)
    for vendor in vendors:
        by_anchor[vendor.get("anchor") or "unknown"] += 1

    return {
        "available": True,
        "path": str(manifest_path),
        "vendor_count": len(vendors),
        "by_anchor": dict(sorted(by_anchor.items())),
    }


def main() -> int:
    db = SessionLocal()
    try:
        total = db.query(func.count(Restaurant.id)).scalar() or 0
        lahore_fp = (
            db.query(func.count(Restaurant.id))
            .filter(Restaurant.source == "foodpanda", LAHORE_TOTAL_QUERY)
            .scalar()
            or 0
        )
        dish_total = db.query(func.count(Dish.id)).scalar() or 0

        from app.services.recommendation.v2_candidates import load_eligible_dishes

        eligible_count = len(load_eligible_dishes(db))

        print("=" * 60)
        print("POPAL EATS — RESTAURANT COVERAGE AUDIT")
        print("=" * 60)
        print(f"Total restaurants in DB:     {total}")
        print(f"Foodpanda Lahore restaurants: {lahore_fp}")
        print(f"Total dishes in DB:          {dish_total}")
        print(f"Recommendation candidates:   {eligible_count}")
        print()

        print("--- Counts by area (address keyword match) ---")
        area_rows: list[tuple[str, int, list[str]]] = []
        for area, keywords in AREA_KEYWORDS.items():
            filters = [Restaurant.address.ilike(f"%{kw}%") for kw in keywords]
            count = (
                db.query(func.count(Restaurant.id))
                .filter(LAHORE_TOTAL_QUERY, or_(*filters))
                .scalar()
                or 0
            )
            samples = (
                db.query(Restaurant.name, Restaurant.address)
                .filter(LAHORE_TOTAL_QUERY, or_(*filters))
                .order_by(Restaurant.name)
                .limit(5)
                .all()
            )
            area_rows.append((area, count, [f"{n} — {a or '—'}" for n, a in samples]))
            print(f"  {area:22} {count:4} restaurants")

        print()
        print("--- Lake City Lahore sample ---")
        lake_count = next(row[1] for row in area_rows if row[0] == "Lake City")
        if lake_count == 0:
            print("  No restaurants matched 'Lake City' in address text.")
            print("  Tip: run discovery anchored at Lake City (~31.385, 74.455).")
        else:
            for line in next(row[2] for row in area_rows if row[0] == "Lake City"):
                print(f"  • {line}")

        print()
        print("--- Foodpanda manifest (local discovery cache) ---")
        manifest = _manifest_stats()
        if not manifest["available"]:
            print(f"  Manifest not found: {manifest['path']}")
        else:
            print(f"  Vendors in manifest: {manifest['vendor_count']}")
            for anchor, count in manifest.get("by_anchor", {}).items():
                print(f"    {anchor}: {count}")

        print()
        print("--- City breakdown (top 10) ---")
        city_counts = (
            db.query(Restaurant.city, func.count(Restaurant.id))
            .group_by(Restaurant.city)
            .order_by(func.count(Restaurant.id).desc())
            .limit(10)
            .all()
        )
        for city, count in city_counts:
            print(f"  {(city or '(null)'):20} {count}")

        print("=" * 60)
        return 0
    finally:
        db.close()


if __name__ == "__main__":
    sys.exit(main())
