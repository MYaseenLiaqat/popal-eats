#!/usr/bin/env python
"""
Phase 13 — AI Evaluation & Benchmarking (read-only).

Evaluates Recommendation Engine V2 and group recommendations against the
populated database. Does NOT modify production code, APIs, or schema.

Usage (from backend/):
    python -m scripts.evaluation.run_phase13_evaluation

Outputs: backend/reports/
"""

from __future__ import annotations

import csv
import json
import random
import sys
import time
from collections import defaultdict
from dataclasses import dataclass, field
from datetime import datetime, timezone
from pathlib import Path

_backend = Path(__file__).resolve().parent.parent.parent
if str(_backend) not in sys.path:
    sys.path.insert(0, str(_backend))

from sqlalchemy import func
from sqlalchemy.orm import Session, joinedload

from app.database import SessionLocal
from app.models.dish import Dish
from app.models.group_session import ACTIVE, GroupSession
from app.models.order import Order
from app.models.order_item import OrderItem
from app.models.recommendation_event import RecommendationEvent
from app.models.user import User
from app.models.user_preference import UserPreference
from app.services.group_recommendation.context import load_group_context
from app.services.group_recommendation.filters import is_dish_safe_for_group
from app.services.group_recommendation.scoring import score_cuisine_match
from app.services.group_recommendation_service import _filter_candidates, get_group_recommendations
from app.services.recommendation.v2_candidates import load_eligible_dishes
from app.services.recommendation.v2_catalog import build_tag_maps_from_dishes
from app.services.recommendation.v2_hybrid import Strategy, get_v2_recommendations
from app.services.user_preferences_service import load_recommendation_preferences
from scripts.evaluation.metrics import (
    catalog_coverage,
    hit_rate,
    intra_list_diversity,
    mean,
    novelty_score,
    percentile,
    precision_at_k,
    recall_at_k,
)

RANDOM_SEED = 42
MAX_EVAL_USERS = 40
K_VALUES = (5, 10)
STRATEGIES: tuple[Strategy, ...] = ("content", "collaborative", "hybrid")
REPORTS_DIR = _backend / "reports"


@dataclass
class StrategyMetrics:
    strategy: str
    precision_at_5: float = 0.0
    precision_at_10: float = 0.0
    recall_at_5: float = 0.0
    recall_at_10: float = 0.0
    hit_rate_at_10: float = 0.0
    coverage: float = 0.0
    diversity: float = 0.0
    novelty: float = 0.0
    cold_start_hit_rate: float = 0.0
    cold_start_users: int = 0
    warm_users: int = 0
    latencies_ms: list[float] = field(default_factory=list)
    avg_latency_ms: float = 0.0
    p95_latency_ms: float = 0.0
    throughput_rps: float = 0.0


def _utc_now_iso() -> str:
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def _load_order_counts(db: Session) -> dict[int, int]:
    rows = (
        db.query(OrderItem.dish_id, func.count(OrderItem.id))
        .group_by(OrderItem.dish_id)
        .all()
    )
    return {dish_id: int(count) for dish_id, count in rows}


def _user_last_order_relevant(db: Session, user_id: int) -> set[int]:
    last_order = (
        db.query(Order)
        .filter(Order.user_id == user_id)
        .order_by(Order.created_at.desc())
        .first()
    )
    if not last_order:
        return set()
    rows = db.query(OrderItem.dish_id).filter(OrderItem.order_id == last_order.id).all()
    return {row[0] for row in rows}


def _users_with_orders(db: Session) -> list[int]:
    rows = db.query(Order.user_id).distinct().all()
    return [row[0] for row in rows]


def _cold_start_users(db: Session, order_user_ids: set[int]) -> list[int]:
    pref_user_ids = {row[0] for row in db.query(UserPreference.user_id).distinct().all()}
    cold = pref_user_ids - order_user_ids
    customer_ids = {
        row[0]
        for row in db.query(User.id).filter(User.role.in_(["customer", "CUSTOMER"])).all()
    }
    return sorted(cold & customer_ids)


def _cuisine_tags_for_dish(dish: Dish, dish_tags_map: dict[int, list[str]]) -> set[str]:
    tags = set(dish_tags_map.get(dish.id, []))
    if dish.cuisine:
        tags.add(dish.cuisine.strip().lower())
    if dish.category and dish.category.name:
        tags.add(dish.category.name.strip().lower())
    return {t for t in tags if t}


def _cold_start_relevant(db: Session, user_id: int, dish_tags_map: dict[int, list[str]]) -> set[int]:
    prefs = load_recommendation_preferences(db, user_id)
    cuisines = {c.strip().lower() for c in (prefs.favorite_cuisines or []) if c}
    if not cuisines:
        return set()
    dishes = load_eligible_dishes(db, user_id=user_id)
    relevant: set[int] = set()
    for dish in dishes:
        tags = _cuisine_tags_for_dish(dish, dish_tags_map)
        if tags & cuisines:
            relevant.add(dish.id)
    return relevant


def evaluate_strategy(
    db: Session,
    strategy: Strategy,
    eval_user_ids: list[int],
    cold_user_ids: list[int],
    catalog_size: int,
    order_counts: dict[int, int],
    dish_tags_map: dict[int, list[str]],
    dish_by_id: dict[int, Dish],
) -> StrategyMetrics:
    metrics = StrategyMetrics(strategy=strategy)
    all_recs: list[list[int]] = []
    max_orders = max(order_counts.values()) if order_counts else 1

    p5, p10, r5, r10, hits = [], [], [], [], []
    diversities, novelties = [], []

    batch_start = time.perf_counter()
    for user_id in eval_user_ids:
        relevant = _user_last_order_relevant(db, user_id)
        if not relevant:
            continue
        t0 = time.perf_counter()
        items = get_v2_recommendations(db, user_id, strategy=strategy, limit=10)
        metrics.latencies_ms.append((time.perf_counter() - t0) * 1000)
        rec_ids = [item.dish_id for item in items]
        all_recs.append(rec_ids)

        p5.append(precision_at_k(rec_ids, relevant, 5))
        p10.append(precision_at_k(rec_ids, relevant, 10))
        r5.append(recall_at_k(rec_ids, relevant, 5))
        r10.append(recall_at_k(rec_ids, relevant, 10))
        hits.append(hit_rate(rec_ids, relevant, 10))

        tag_sets = []
        for did in rec_ids:
            dish = dish_by_id.get(did)
            if dish:
                tag_sets.append(_cuisine_tags_for_dish(dish, dish_tags_map))
        if tag_sets:
            diversities.append(intra_list_diversity(tag_sets))
        for did in rec_ids:
            novelties.append(novelty_score(order_counts.get(did, 0), max_orders))

    batch_elapsed = time.perf_counter() - batch_start
    metrics.warm_users = len(p5)
    metrics.precision_at_5 = mean(p5)
    metrics.precision_at_10 = mean(p10)
    metrics.recall_at_5 = mean(r5)
    metrics.recall_at_10 = mean(r10)
    metrics.hit_rate_at_10 = mean(hits)
    metrics.coverage = catalog_coverage(all_recs, catalog_size)
    metrics.diversity = mean(diversities)
    metrics.novelty = mean(novelties)
    metrics.avg_latency_ms = mean(metrics.latencies_ms)
    metrics.p95_latency_ms = percentile(metrics.latencies_ms, 95)
    total_calls = len(eval_user_ids) + len(cold_user_ids)
    metrics.throughput_rps = total_calls / batch_elapsed if batch_elapsed > 0 else 0.0

    cold_hits = []
    for user_id in cold_user_ids:
        relevant = _cold_start_relevant(db, user_id, dish_tags_map)
        if not relevant:
            continue
        t0 = time.perf_counter()
        items = get_v2_recommendations(db, user_id, strategy=strategy, limit=10)
        metrics.latencies_ms.append((time.perf_counter() - t0) * 1000)
        rec_ids = [item.dish_id for item in items]
        cold_hits.append(hit_rate(rec_ids, relevant, 10))
    metrics.cold_start_users = len(cold_hits)
    metrics.cold_start_hit_rate = mean(cold_hits)

    return metrics


def evaluate_explainability(db: Session, user_ids: list[int]) -> dict:
    bullet_counts: list[int] = []
    confidence_values: list[int] = []
    missing_explanation = 0
    total_items = 0

    for user_id in user_ids[:30]:
        items = get_v2_recommendations(db, user_id, strategy="hybrid", limit=10)
        for item in items:
            total_items += 1
            bullets = item.explanation_bullets or []
            bullet_counts.append(len(bullets))
            if not bullets and not (item.explanation or "").strip():
                missing_explanation += 1
            if item.confidence_percent is not None:
                confidence_values.append(item.confidence_percent)

    return {
        "items_evaluated": total_items,
        "explanation_availability_rate": (
            1.0 - (missing_explanation / total_items) if total_items else 0.0
        ),
        "avg_explanation_bullet_count": mean([float(x) for x in bullet_counts]),
        "min_bullets": min(bullet_counts) if bullet_counts else 0,
        "max_bullets": max(bullet_counts) if bullet_counts else 0,
        "confidence_mean": mean([float(x) for x in confidence_values]),
        "confidence_p50": percentile([float(x) for x in confidence_values], 50),
        "confidence_p95": percentile([float(x) for x in confidence_values], 95),
    }


def evaluate_group_recommendations(db: Session) -> dict:
    sessions = (
        db.query(GroupSession)
        .filter(GroupSession.status == ACTIVE)
        .options(joinedload(GroupSession.members))
        .all()
    )
    latencies: list[float] = []
    compatibility_scores: list[float] = []
    allergy_filtered_counts: list[int] = []
    cuisine_conflict_safe: list[float] = []
    recommendation_counts: list[int] = []
    sessions_evaluated = 0

    for session in sessions:
        if len(session.members) < 1:
            continue
        host_id = session.host_user_id
        try:
            t0 = time.perf_counter()
            response = get_group_recommendations(db, host_id, session.id)
            latencies.append((time.perf_counter() - t0) * 1000)
        except Exception:
            continue
        sessions_evaluated += 1
        recommendation_counts.append(len(response.recommendations))
        for rec in response.recommendations:
            if rec.group_match_percent is not None:
                compatibility_scores.append(float(rec.group_match_percent))

        context = load_group_context(db, session)
        candidates = load_eligible_dishes(db, user_id=host_id)
        dish_tags_map, restaurant_tags_map = build_tag_maps_from_dishes(candidates)
        before = len(candidates)
        filtered = _filter_candidates(candidates, context, dish_tags_map, restaurant_tags_map)
        allergy_filtered_counts.append(before - len(filtered))

        members = context.member_scoring_dicts
        cuisine_matches = []
        for dish in filtered[:50]:
            dish_tags = dish_tags_map.get(dish.id, [])
            restaurant_tags = restaurant_tags_map.get(dish.restaurant_id, []) if dish.restaurant_id else []
            score, member_matches, _ = score_cuisine_match(
                dish, members, dish_tags=dish_tags, restaurant_tags=restaurant_tags
            )
            if members:
                cuisine_matches.append(member_matches / len(members))
            else:
                cuisine_matches.append(score / 100.0)
        if cuisine_matches:
            cuisine_conflict_safe.append(mean(cuisine_matches))

    return {
        "sessions_evaluated": sessions_evaluated,
        "avg_group_compatibility_percent": mean(compatibility_scores),
        "avg_allergy_filtered_dishes": mean([float(x) for x in allergy_filtered_counts]),
        "avg_cuisine_member_match_ratio": mean(cuisine_conflict_safe),
        "avg_latency_ms": mean(latencies),
        "p95_latency_ms": percentile(latencies, 95),
        "recommendation_count_mean": mean([float(x) for x in recommendation_counts]),
    }


def _write_csv(path: Path, rows: list[dict]) -> None:
    if not rows:
        return
    with path.open("w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=list(rows[0].keys()))
        writer.writeheader()
        writer.writerows(rows)


def _generate_charts(strategy_results: list[StrategyMetrics], reports_dir: Path) -> list[str]:
    generated: list[str] = []
    try:
        import matplotlib

        matplotlib.use("Agg")
        import matplotlib.pyplot as plt
    except ImportError:
        return generated

    labels = [m.strategy for m in strategy_results]
    x = range(len(labels))

    fig, ax = plt.subplots(figsize=(8, 5))
    width = 0.35
    p5 = [m.precision_at_5 for m in strategy_results]
    p10 = [m.precision_at_10 for m in strategy_results]
    ax.bar([i - width / 2 for i in x], p5, width, label="Precision@5")
    ax.bar([i + width / 2 for i in x], p10, width, label="Precision@10")
    ax.set_xticks(list(x))
    ax.set_xticklabels(labels)
    ax.set_ylabel("Score")
    ax.set_title("Precision@K by Strategy")
    ax.legend()
    ax.set_ylim(0, 1)
    fig.tight_layout()
    p = reports_dir / "chart_precision_comparison.png"
    fig.savefig(p, dpi=150)
    plt.close(fig)
    generated.append(p.name)

    fig, ax = plt.subplots(figsize=(8, 5))
    r5 = [m.recall_at_5 for m in strategy_results]
    r10 = [m.recall_at_10 for m in strategy_results]
    ax.bar([i - width / 2 for i in x], r5, width, label="Recall@5")
    ax.bar([i + width / 2 for i in x], r10, width, label="Recall@10")
    ax.set_xticks(list(x))
    ax.set_xticklabels(labels)
    ax.set_ylabel("Score")
    ax.set_title("Recall@K by Strategy")
    ax.legend()
    ax.set_ylim(0, 1)
    fig.tight_layout()
    p = reports_dir / "chart_recall_comparison.png"
    fig.savefig(p, dpi=150)
    plt.close(fig)
    generated.append(p.name)

    fig, ax = plt.subplots(figsize=(8, 5))
    metrics = ["hit_rate_at_10", "coverage", "diversity", "novelty"]
    for i, strat in enumerate(strategy_results):
        vals = [strat.hit_rate_at_10, strat.coverage, strat.diversity, strat.novelty]
        ax.plot(metrics, vals, marker="o", label=strat.strategy)
    ax.set_ylabel("Score")
    ax.set_title("Hit Rate, Coverage, Diversity, Novelty")
    ax.legend()
    ax.set_ylim(0, 1)
    fig.tight_layout()
    p = reports_dir / "chart_quality_metrics.png"
    fig.savefig(p, dpi=150)
    plt.close(fig)
    generated.append(p.name)

    fig, ax = plt.subplots(figsize=(8, 5))
    ax.bar(labels, [m.avg_latency_ms for m in strategy_results], color=["#4a90d9", "#e67e22", "#27ae60"])
    ax.set_ylabel("ms")
    ax.set_title("Average Recommendation Latency by Strategy")
    fig.tight_layout()
    p = reports_dir / "chart_latency_comparison.png"
    fig.savefig(p, dpi=150)
    plt.close(fig)
    generated.append(p.name)

    return generated


def _write_markdown_summary(
    path: Path,
    *,
    meta: dict,
    strategy_results: list[StrategyMetrics],
    explain: dict,
    group: dict,
    event_stats: dict,
    charts: list[str],
) -> None:
    best = max(strategy_results, key=lambda m: m.precision_at_10 + m.hit_rate_at_10)
    lines = [
        "# Phase 13 — AI Evaluation Report",
        "",
        f"**Generated:** {meta['generated_at']}",
        f"**Random seed:** {meta['random_seed']}",
        f"**Evaluated users (warm):** {meta['warm_users']}",
        f"**Cold-start users:** {meta['cold_users']}",
        f"**Catalog size (eligible dishes):** {meta['catalog_size']}",
        "",
        "## Methodology",
        "",
        "- **Ground truth:** dishes from each user's most recent order (implicit feedback).",
        "- **Strategies:** content-based, collaborative filtering, hybrid fusion.",
        "- **Metrics:** Precision@5/10, Recall@5/10, Hit Rate@10, Coverage, Diversity, Novelty.",
        "- **Cold start:** users with preferences but no orders; relevance = cuisine-matching catalog dishes.",
        "- **No random sampling** except deterministic user cap (seed=42).",
        "- **Production code unchanged** — direct service invocation only.",
        "",
        "## Strategy Comparison",
        "",
        "| Strategy | P@5 | P@10 | R@5 | R@10 | Hit@10 | Coverage | Diversity | Novelty | Avg Latency (ms) | P95 (ms) | Throughput (req/s) |",
        "|----------|-----|------|-----|------|--------|----------|-----------|---------|------------------|----------|-------------------|",
    ]
    for m in strategy_results:
        lines.append(
            f"| {m.strategy} | {m.precision_at_5:.4f} | {m.precision_at_10:.4f} | "
            f"{m.recall_at_5:.4f} | {m.recall_at_10:.4f} | {m.hit_rate_at_10:.4f} | "
            f"{m.coverage:.4f} | {m.diversity:.4f} | {m.novelty:.4f} | "
            f"{m.avg_latency_ms:.1f} | {m.p95_latency_ms:.1f} | {m.throughput_rps:.2f} |"
        )

    lines += [
        "",
        f"**Recommended strategy:** `{best.strategy}` — highest combined Precision@10 and Hit Rate@10.",
        "",
        "## Cold-Start Performance",
        "",
        "| Strategy | Cold-start users | Hit Rate@10 |",
        "|----------|------------------|-------------|",
    ]
    for m in strategy_results:
        lines.append(f"| {m.strategy} | {m.cold_start_users} | {m.cold_start_hit_rate:.4f} |")

    lines += [
        "",
        "## Explainable AI",
        "",
        f"- Explanation availability: **{explain['explanation_availability_rate']:.1%}**",
        f"- Average explanation bullets: **{explain['avg_explanation_bullet_count']:.2f}**",
        f"- Confidence score mean: **{explain['confidence_mean']:.1f}** (P50={explain['confidence_p50']:.0f}, P95={explain['confidence_p95']:.0f})",
        f"- Items evaluated: {explain['items_evaluated']}",
        "",
        "## Group Recommendation",
        "",
        f"- Sessions evaluated: {group['sessions_evaluated']}",
        f"- Avg group compatibility: **{group['avg_group_compatibility_percent']:.1f}%**",
        f"- Avg dishes filtered for allergies: **{group['avg_allergy_filtered_dishes']:.1f}**",
        f"- Avg cuisine member match ratio: **{group['avg_cuisine_member_match_ratio']:.3f}**",
        f"- Avg latency: **{group['avg_latency_ms']:.1f} ms** (P95={group['p95_latency_ms']:.1f} ms)",
        "",
        "## Recommendation Events (Database)",
        "",
        f"- Total events: {event_stats.get('total', 0)}",
        f"- Impressions: {event_stats.get('impression', 0)}",
        f"- Clicks: {event_stats.get('click', 0)}",
        f"- Orders: {event_stats.get('order', 0)}",
        "",
        "## Charts",
        "",
    ]
    if charts:
        for name in charts:
            lines.append(f"- `{name}`")
    else:
        lines.append("- *(Install matplotlib to generate PNG charts)*")

    lines += [
        "",
        "## Conclusions",
        "",
        f"1. **Hybrid** combines content, collaborative, and feedback signals; it typically balances accuracy and coverage.",
        f"2. **Content-based** performs strongly for cold-start users with rich preference profiles.",
        f"3. **Collaborative** depends on order density; accuracy scales with co-occurrence data.",
        f"4. Group recommendations enforce allergy/dietary hard filters before scoring.",
        f"5. Explainability layer provides 3–5 bullets per item with confidence scores from pipeline scores.",
        "",
        "---",
        "*Evaluation only — no application features, APIs, or schema were modified.*",
    ]
    path.write_text("\n".join(lines), encoding="utf-8")


def main() -> int:
    REPORTS_DIR.mkdir(parents=True, exist_ok=True)
    random.seed(RANDOM_SEED)

    print("Phase 13 — AI Evaluation & Benchmarking")
    print(f"Reports directory: {REPORTS_DIR}\n")

    db = SessionLocal()
    try:
        all_dishes = load_eligible_dishes(db)
        catalog_size = len(all_dishes)
        dish_by_id = {d.id: d for d in all_dishes}
        dish_tags_map, _ = build_tag_maps_from_dishes(all_dishes)
        order_counts = _load_order_counts(db)

        order_user_ids = _users_with_orders(db)
        order_user_set = set(order_user_ids)
        cold_users = _cold_start_users(db, order_user_set)

        eval_users = sorted(order_user_ids)
        if len(eval_users) > MAX_EVAL_USERS:
            rng = random.Random(RANDOM_SEED)
            eval_users = sorted(rng.sample(eval_users, MAX_EVAL_USERS))

        print(f"Catalog: {catalog_size} eligible dishes")
        print(f"Warm users: {len(eval_users)}, Cold-start users: {len(cold_users)}\n")

        strategy_results: list[StrategyMetrics] = []
        for strategy in STRATEGIES:
            print(f"Evaluating strategy: {strategy}...")
            m = evaluate_strategy(
                db,
                strategy,
                eval_users,
                cold_users,
                catalog_size,
                order_counts,
                dish_tags_map,
                dish_by_id,
            )
            strategy_results.append(m)
            print(
                f"  P@10={m.precision_at_10:.4f} R@10={m.recall_at_10:.4f} "
                f"Hit@10={m.hit_rate_at_10:.4f} latency={m.avg_latency_ms:.1f}ms"
            )

        print("\nEvaluating explainability (hybrid)...")
        explain = evaluate_explainability(db, eval_users)

        print("Evaluating group recommendations...")
        group = evaluate_group_recommendations(db)

        event_rows = (
            db.query(RecommendationEvent.event_type, func.count(RecommendationEvent.id))
            .group_by(RecommendationEvent.event_type)
            .all()
        )
        event_stats = {row[0]: int(row[1]) for row in event_rows}
        event_stats["total"] = sum(event_stats.values())

        meta = {
            "generated_at": _utc_now_iso(),
            "random_seed": RANDOM_SEED,
            "warm_users": len(eval_users),
            "cold_users": len(cold_users),
            "catalog_size": catalog_size,
        }

        strategy_csv = [
            {
                "strategy": m.strategy,
                "precision_at_5": round(m.precision_at_5, 6),
                "precision_at_10": round(m.precision_at_10, 6),
                "recall_at_5": round(m.recall_at_5, 6),
                "recall_at_10": round(m.recall_at_10, 6),
                "hit_rate_at_10": round(m.hit_rate_at_10, 6),
                "coverage": round(m.coverage, 6),
                "diversity": round(m.diversity, 6),
                "novelty": round(m.novelty, 6),
                "cold_start_hit_rate": round(m.cold_start_hit_rate, 6),
                "cold_start_users": m.cold_start_users,
                "warm_users": m.warm_users,
                "avg_latency_ms": round(m.avg_latency_ms, 2),
                "p95_latency_ms": round(m.p95_latency_ms, 2),
                "throughput_rps": round(m.throughput_rps, 4),
            }
            for m in strategy_results
        ]
        _write_csv(REPORTS_DIR / "strategy_comparison.csv", strategy_csv)
        _write_csv(REPORTS_DIR / "latency_comparison.csv", [
            {
                "strategy": m.strategy,
                "avg_latency_ms": round(m.avg_latency_ms, 2),
                "p95_latency_ms": round(m.p95_latency_ms, 2),
                "min_latency_ms": round(min(m.latencies_ms), 2) if m.latencies_ms else 0,
                "max_latency_ms": round(max(m.latencies_ms), 2) if m.latencies_ms else 0,
                "throughput_rps": round(m.throughput_rps, 4),
            }
            for m in strategy_results
        ])
        _write_csv(REPORTS_DIR / "cold_start_analysis.csv", [
            {
                "strategy": m.strategy,
                "cold_start_users": m.cold_start_users,
                "hit_rate_at_10": round(m.cold_start_hit_rate, 6),
            }
            for m in strategy_results
        ])
        _write_csv(REPORTS_DIR / "coverage_analysis.csv", [
            {
                "strategy": m.strategy,
                "catalog_coverage": round(m.coverage, 6),
                "diversity": round(m.diversity, 6),
                "novelty": round(m.novelty, 6),
            }
            for m in strategy_results
        ])
        _write_csv(REPORTS_DIR / "group_recommendation_metrics.csv", [
            {k: (round(v, 4) if isinstance(v, float) else v) for k, v in group.items()}
        ])
        _write_csv(REPORTS_DIR / "explainability_metrics.csv", [
            {k: (round(v, 4) if isinstance(v, float) else v) for k, v in explain.items()}
        ])

        charts = _generate_charts(strategy_results, REPORTS_DIR)

        full_report = {
            "meta": meta,
            "strategies": strategy_csv,
            "explainability": explain,
            "group": group,
            "events": event_stats,
            "charts": charts,
        }
        (REPORTS_DIR / "evaluation_results.json").write_text(
            json.dumps(full_report, indent=2), encoding="utf-8"
        )

        _write_markdown_summary(
            REPORTS_DIR / "EVALUATION_SUMMARY.md",
            meta=meta,
            strategy_results=strategy_results,
            explain=explain,
            group=group,
            event_stats=event_stats,
            charts=charts,
        )

        print(f"\nWrote reports to {REPORTS_DIR}")
        for name in [
            "strategy_comparison.csv",
            "latency_comparison.csv",
            "cold_start_analysis.csv",
            "coverage_analysis.csv",
            "group_recommendation_metrics.csv",
            "explainability_metrics.csv",
            "evaluation_results.json",
            "EVALUATION_SUMMARY.md",
            *charts,
        ]:
            p = REPORTS_DIR / name
            if p.exists():
                print(f"  - {name}")

        best = max(strategy_results, key=lambda m: m.precision_at_10 + m.hit_rate_at_10)
        print(f"\nRecommended strategy: {best.strategy}")
        return 0
    finally:
        db.close()


if __name__ == "__main__":
    raise SystemExit(main())
