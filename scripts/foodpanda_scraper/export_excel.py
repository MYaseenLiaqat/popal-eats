"""
Reusable Excel export utilities for Foodpanda scraper outputs.
"""

from __future__ import annotations

import logging
from pathlib import Path

import pandas as pd

logger = logging.getLogger(__name__)


def ensure_parent_dir(path: Path) -> None:
    """Create parent directory for a file path if it does not exist."""
    path.parent.mkdir(parents=True, exist_ok=True)


def save_dataframe_excel(
    df: pd.DataFrame,
    path: Path,
    *,
    sheet_name: str = "Sheet1",
    index: bool = False,
) -> Path:
    """
    Export a DataFrame to an Excel file using openpyxl.

    Args:
        df: Data to export.
        path: Destination .xlsx path.
        sheet_name: Worksheet name.
        index: Whether to write row indices.

    Returns:
        Resolved output path.

    Raises:
        ValueError: If DataFrame is empty.
    """
    if df.empty:
        raise ValueError(f"Cannot export empty DataFrame to {path}")

    ensure_parent_dir(path)
    resolved = path.resolve()

    with pd.ExcelWriter(resolved, engine="openpyxl") as writer:
        df.to_excel(writer, sheet_name=sheet_name, index=index)

    logger.info("Saved Excel (%d rows) -> %s", len(df), resolved)
    return resolved


def load_dataframe_excel(path: Path, *, sheet_name: str | int = 0) -> pd.DataFrame:
    """Load an Excel file into a DataFrame."""
    if not path.exists():
        raise FileNotFoundError(f"Excel file not found: {path}")
    return pd.read_excel(path, sheet_name=sheet_name, engine="openpyxl")
