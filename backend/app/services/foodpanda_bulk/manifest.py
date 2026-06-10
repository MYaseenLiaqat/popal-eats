"""Discovery manifest and import checkpoint persistence."""

from __future__ import annotations

import json
from dataclasses import asdict, dataclass, field
from datetime import datetime, timezone
from pathlib import Path
from typing import Any


def _utc_now_iso() -> str:
    return datetime.now(timezone.utc).isoformat()


@dataclass
class ManifestVendor:
    external_code: str
    external_id: str
    vendor_name: str
    city: str | None = None
    latitude: float | None = None
    longitude: float | None = None
    anchor: str | None = None

    def to_dict(self) -> dict[str, Any]:
        return asdict(self)

    @classmethod
    def from_dict(cls, data: dict[str, Any]) -> ManifestVendor:
        return cls(
            external_code=str(data["external_code"]),
            external_id=str(data.get("external_id") or ""),
            vendor_name=str(data.get("vendor_name") or ""),
            city=data.get("city"),
            latitude=data.get("latitude"),
            longitude=data.get("longitude"),
            anchor=data.get("anchor"),
        )


@dataclass
class DiscoveryManifest:
    run_id: str
    city: str
    anchor_latitude: float
    anchor_longitude: float
    discovered_at: str
    page_limit: int
    vendors_discovered: int
    vendors: list[ManifestVendor] = field(default_factory=list)

    def to_dict(self) -> dict[str, Any]:
        return {
            "run_id": self.run_id,
            "city": self.city,
            "anchor_latitude": self.anchor_latitude,
            "anchor_longitude": self.anchor_longitude,
            "discovered_at": self.discovered_at,
            "page_limit": self.page_limit,
            "vendors_discovered": self.vendors_discovered,
            "vendors": [v.to_dict() for v in self.vendors],
        }

    @classmethod
    def from_dict(cls, data: dict[str, Any]) -> DiscoveryManifest:
        return cls(
            run_id=str(data["run_id"]),
            city=str(data.get("city") or "Lahore"),
            anchor_latitude=float(data["anchor_latitude"]),
            anchor_longitude=float(data["anchor_longitude"]),
            discovered_at=str(data.get("discovered_at") or _utc_now_iso()),
            page_limit=int(data.get("page_limit") or 100),
            vendors_discovered=int(data.get("vendors_discovered") or 0),
            vendors=[ManifestVendor.from_dict(v) for v in data.get("vendors", [])],
        )

    def save(self, directory: Path) -> tuple[Path, Path]:
        """Write manifest.json and manifest.jsonl to ``directory``."""
        directory.mkdir(parents=True, exist_ok=True)
        json_path = directory / "manifest.json"
        jsonl_path = directory / "manifest.jsonl"

        json_path.write_text(
            json.dumps(self.to_dict(), indent=2, ensure_ascii=False),
            encoding="utf-8",
        )
        with jsonl_path.open("w", encoding="utf-8") as fh:
            for vendor in self.vendors:
                fh.write(json.dumps(vendor.to_dict(), ensure_ascii=False) + "\n")

        return json_path, jsonl_path

    @classmethod
    def load(cls, path: Path) -> DiscoveryManifest:
        data = json.loads(path.read_text(encoding="utf-8"))
        return cls.from_dict(data)


@dataclass
class ImportCheckpoint:
    """Resumable state for chunked menu import."""

    run_id: str
    manifest_path: str
    status: str = "running"
    chunk_size: int = 50
    next_vendor_index: int = 0
    vendors_imported: int = 0
    vendors_failed: int = 0
    vendors_skipped: int = 0
    dishes_created: int = 0
    dishes_updated: int = 0
    categories_created: int = 0
    completed_codes: list[str] = field(default_factory=list)
    failed_vendors: dict[str, str] = field(default_factory=dict)
    last_checkpoint_at: str | None = None
    vendor_limit: int | None = None

    def to_dict(self) -> dict[str, Any]:
        return asdict(self)

    @classmethod
    def from_dict(cls, data: dict[str, Any]) -> ImportCheckpoint:
        vendor_limit_raw = data.get("vendor_limit")
        return cls(
            run_id=str(data["run_id"]),
            manifest_path=str(data["manifest_path"]),
            status=str(data.get("status") or "running"),
            chunk_size=int(data.get("chunk_size") or 50),
            next_vendor_index=int(data.get("next_vendor_index") or 0),
            vendors_imported=int(data.get("vendors_imported") or 0),
            vendors_failed=int(data.get("vendors_failed") or 0),
            vendors_skipped=int(data.get("vendors_skipped") or 0),
            dishes_created=int(data.get("dishes_created") or 0),
            dishes_updated=int(data.get("dishes_updated") or 0),
            categories_created=int(data.get("categories_created") or 0),
            completed_codes=list(data.get("completed_codes") or []),
            failed_vendors=dict(data.get("failed_vendors") or {}),
            last_checkpoint_at=data.get("last_checkpoint_at"),
            vendor_limit=int(vendor_limit_raw) if vendor_limit_raw is not None else None,
        )

    @classmethod
    def load(cls, path: Path) -> ImportCheckpoint:
        return cls.from_dict(json.loads(path.read_text(encoding="utf-8")))

    def save(self, path: Path) -> None:
        path.parent.mkdir(parents=True, exist_ok=True)
        self.last_checkpoint_at = _utc_now_iso()
        path.write_text(
            json.dumps(self.to_dict(), indent=2, ensure_ascii=False),
            encoding="utf-8",
        )

    @property
    def completed_code_set(self) -> set[str]:
        return {code.lower() for code in self.completed_codes}

    def metrics_dict(self) -> dict[str, int]:
        return {
            "vendors_imported": self.vendors_imported,
            "vendors_failed": self.vendors_failed,
            "vendors_skipped": self.vendors_skipped,
            "dishes_created": self.dishes_created,
            "dishes_updated": self.dishes_updated,
            "categories_created": self.categories_created,
        }
