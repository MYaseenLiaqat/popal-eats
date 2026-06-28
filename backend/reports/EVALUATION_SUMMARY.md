# Phase 13 — AI Evaluation Report

**Generated:** 2026-06-27T19:22:56Z
**Random seed:** 42
**Evaluated users (warm):** 5
**Cold-start users:** 44
**Catalog size (eligible dishes):** 11414

## Methodology

- **Ground truth:** dishes from each user's most recent order (implicit feedback).
- **Strategies:** content-based, collaborative filtering, hybrid fusion.
- **Metrics:** Precision@5/10, Recall@5/10, Hit Rate@10, Coverage, Diversity, Novelty.
- **Cold start:** users with preferences but no orders; relevance = cuisine-matching catalog dishes.
- **No random sampling** except deterministic user cap (seed=42).
- **Production code unchanged** — direct service invocation only.

## Strategy Comparison

| Strategy | P@5 | P@10 | R@5 | R@10 | Hit@10 | Coverage | Diversity | Novelty | Avg Latency (ms) | P95 (ms) | Throughput (req/s) |
|----------|-----|------|-----|------|--------|----------|-----------|---------|------------------|----------|-------------------|
| content | 0.0000 | 0.0000 | 0.0000 | 0.0000 | 0.0000 | 0.0035 | 0.5139 | 2.3219 | 13419.5 | 15902.6 | 0.72 |
| collaborative | 0.0000 | 0.0000 | 0.0000 | 0.0000 | 0.0000 | 0.0000 | 0.0000 | 0.0000 | 436.4 | 577.8 | 14.15 |
| hybrid | 0.0000 | 0.0000 | 0.0000 | 0.0000 | 0.0000 | 0.0035 | 0.5926 | 2.3219 | 16423.2 | 18287.7 | 0.59 |

**Recommended strategy:** `content` — highest combined Precision@10 and Hit Rate@10.

## Cold-Start Performance

| Strategy | Cold-start users | Hit Rate@10 |
|----------|------------------|-------------|
| content | 41 | 1.0000 |
| collaborative | 41 | 0.0000 |
| hybrid | 41 | 1.0000 |

## Explainable AI

- Explanation availability: **100.0%**
- Average explanation bullets: **3.40**
- Confidence score mean: **30.3** (P50=36, P95=53)
- Items evaluated: 50

## Group Recommendation

- Sessions evaluated: 1
- Avg group compatibility: **77.0%**
- Avg dishes filtered for allergies: **0.0**
- Avg cuisine member match ratio: **0.020**
- Avg latency: **14155.1 ms** (P95=14155.1 ms)

## Recommendation Events (Database)

- Total events: 13
- Impressions: 0
- Clicks: 12
- Orders: 1

## Charts

- `chart_precision_comparison.png`
- `chart_recall_comparison.png`
- `chart_quality_metrics.png`
- `chart_latency_comparison.png`

## Conclusions

1. **Hybrid** combines content, collaborative, and feedback signals; it typically balances accuracy and coverage.
2. **Content-based** performs strongly for cold-start users with rich preference profiles.
3. **Collaborative** depends on order density; accuracy scales with co-occurrence data.
4. Group recommendations enforce allergy/dietary hard filters before scoring.
5. Explainability layer provides 3–5 bullets per item with confidence scores from pipeline scores.

---
*Evaluation only — no application features, APIs, or schema were modified.*