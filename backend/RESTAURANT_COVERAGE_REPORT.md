# Restaurant Coverage Report

Generated: 2026-06-19 · `python scripts/audit_restaurant_coverage.py`

## Summary

| Metric | Count |
|--------|------:|
| Total restaurants in DB | 161 |
| Foodpanda Lahore restaurants | 100 |
| Total dishes in DB | 8,434 |
| Recommendation candidates (eligible) | 4,487 |
| Vendors in local discovery manifest | 905 |
| Vendors imported vs discovered | **100 / 905 (11%)** |

## Target area coverage (address keyword match)

Foodpanda import addresses rarely include neighborhood names, so **address keyword counts under-report** geographic coverage. Use manifest anchor distribution as the discovery proxy.

| Area | DB (address match) | Manifest anchor vendors |
|------|-------------------:|------------------------:|
| Lake City | 0 | 0* |
| DHA | 0 | 100 (DHA Phase 5 anchor) |
| Johar Town | 0 | 75 |
| Gulberg | 0 | 0* |
| Wapda Town | 0 | 0* |
| Valencia | 0 | 0* |

\* *New gap-fill anchors added in code (Gulberg, Lake City, Wapda Town, Valencia) — re-run discovery to populate manifest.*

## Manifest anchor distribution (current cache)

| Anchor | Vendors |
|--------|--------:|
| primary (Lahore centroid) | 657 |
| DHA Phase 5 | 100 |
| Johar Town | 75 |
| Allama Iqbal Town | 73 |

## Gap analysis

1. **805 vendors** discovered but not imported — largest catalog gap.
2. **Area names absent from addresses** — keyword audit shows 0 for all neighborhoods; this is expected for Foodpanda data, not a total absence of nearby restaurants.
3. **Lake City / Gulberg / Wapda / Valencia** — not in current manifest; discovery anchors added for next `foodpanda_discover_lahore.py` run.

## Recommendation pool

- **4,487 eligible dishes** in V2 candidate pool (available + approved restaurant + non-placeholder).
- Group E2E verified: **20 recommendations** returned for Lahore centroid; voting → **agreed** → **ordered**.

## Recommended import commands

```bash
cd backend

# Re-discover with new anchors (optional, ~15 min, needs network)
python scripts/foodpanda_discover_lahore.py

# Import next batch (resume from checkpoint)
python scripts/foodpanda_import_lahore.py --limit 100

# Full remaining import (long-running)
python scripts/foodpanda_import_lahore.py
```

## City breakdown (DB)

| City | Count |
|------|------:|
| Lahore | 101 |
| Karachi | 48 |
| Test/legacy rows | 12 |
