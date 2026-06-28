"""Progress logging for offline population scripts."""

from __future__ import annotations

import sys
from datetime import datetime


def log_step(step: str) -> None:
    ts = datetime.now().strftime("%H:%M:%S")
    print(f"\n[{ts}] === {step} ===", flush=True)


def log_progress(label: str, current: int, total: int, *, extra: str = "") -> None:
    pct = (100 * current / total) if total else 100
    suffix = f" | {extra}" if extra else ""
    print(f"  [{label}] {current}/{total} ({pct:.0f}%){suffix}", flush=True)


def log_done(label: str, **counts: int) -> None:
    parts = ", ".join(f"{k}={v}" for k, v in counts.items())
    print(f"  OK {label} complete{f': {parts}' if parts else ''}", flush=True)
