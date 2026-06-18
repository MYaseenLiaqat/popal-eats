"""Soft ranking adjustments for extreme menu prices (PKR)."""

from __future__ import annotations

from decimal import Decimal


def apply_price_outlier_penalty(score: float, price: Decimal | float | None) -> float:
    """
    Down-rank luxury/outlier items without removing them from results.

    Thresholds align with typical Foodpanda Lahore PKR ranges.
    """
    if price is None:
        return score
    amount = float(price)
    if amount >= 15_000:
        return round(score * 0.55, 2)
    if amount >= 8_000:
        return round(score * 0.75, 2)
    if amount >= 5_000:
        return round(score * 0.88, 2)
    return score
