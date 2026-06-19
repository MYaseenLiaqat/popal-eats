"""Foodpanda vendor discovery job — paginated search with manifest output."""

from __future__ import annotations

import time
import uuid
from dataclasses import dataclass, field
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

from app.integrations.foodpanda.foodpanda_client import FoodpandaAPIError, FoodpandaClient
from app.services.foodpanda_bulk.logging_utils import log_event, log_metrics
from app.services.foodpanda_bulk.manifest import DiscoveryManifest, ManifestVendor
from app.services.foodpanda_import_service import extract_vendor_list, parse_vendor

# Lahore gap-fill anchors from acquisition plan (first page only).
LAHORE_GAP_FILL_ANCHORS: list[tuple[str, float, float]] = [
    ("DHA Phase 5", 31.4697, 74.4066),
    ("Johar Town", 31.4692, 74.2724),
    ("Allama Iqbal Town", 31.5126, 74.2901),
    ("Gulberg", 31.5204, 74.3587),
    ("Lake City", 31.3850, 74.4550),
    ("Wapda Town", 31.4444, 74.2870),
    ("Valencia", 31.4120, 74.2280),
]


@dataclass
class DiscoveryResult:
    manifest: DiscoveryManifest
    manifest_json_path: Path
    manifest_jsonl_path: Path
    pages_fetched: int = 0
    errors: list[str] = field(default_factory=list)


def extract_available_count(payload: dict[str, Any]) -> int | None:
    data = payload.get("data")
    if isinstance(data, dict) and data.get("available_count") is not None:
        return int(data["available_count"])
    return None


class FoodpandaDiscoveryJob:
    """Paginate Foodpanda vendor search and write a deduplicated manifest."""

    def __init__(
        self,
        client: FoodpandaClient,
        *,
        page_limit: int = 100,
        search_delay_seconds: float = 0.3,
    ) -> None:
        self._client = client
        self._page_limit = page_limit
        self._search_delay = search_delay_seconds

    def discover_lahore(
        self,
        *,
        output_dir: Path,
        latitude: float,
        longitude: float,
        city: str = "Lahore",
        run_id: str | None = None,
        gap_fill: bool = True,
    ) -> DiscoveryResult:
        run = run_id or self._new_run_id(city)
        log_event(
            "DISCOVERY_START",
            run_id=run,
            city=city,
            latitude=latitude,
            longitude=longitude,
            page_limit=self._page_limit,
        )

        vendors_by_code: dict[str, ManifestVendor] = {}
        pages_fetched = 0
        errors: list[str] = []

        primary_pages, primary_errors = self._paginate_anchor(
            label="primary",
            latitude=latitude,
            longitude=longitude,
            vendors_by_code=vendors_by_code,
        )
        pages_fetched += primary_pages
        errors.extend(primary_errors)

        if gap_fill:
            for label, lat, lon in LAHORE_GAP_FILL_ANCHORS:
                _, gap_errors = self._paginate_anchor(
                    label=label,
                    latitude=lat,
                    longitude=lon,
                    vendors_by_code=vendors_by_code,
                    first_page_only=True,
                )
                pages_fetched += 1
                errors.extend(gap_errors)
                if self._search_delay > 0:
                    time.sleep(self._search_delay)

        manifest = DiscoveryManifest(
            run_id=run,
            city=city,
            anchor_latitude=latitude,
            anchor_longitude=longitude,
            discovered_at=datetime.now(timezone.utc).isoformat(),
            page_limit=self._page_limit,
            vendors_discovered=len(vendors_by_code),
            vendors=sorted(vendors_by_code.values(), key=lambda v: v.external_code),
        )

        json_path, jsonl_path = manifest.save(output_dir)
        log_metrics(
            run,
            {
                "vendors_discovered": manifest.vendors_discovered,
                "pages_fetched": pages_fetched,
                "manifest_json": str(json_path),
            },
        )
        log_event("DISCOVERY_COMPLETE", run_id=run, vendors_discovered=manifest.vendors_discovered)

        return DiscoveryResult(
            manifest=manifest,
            manifest_json_path=json_path,
            manifest_jsonl_path=jsonl_path,
            pages_fetched=pages_fetched,
            errors=errors,
        )

    def _paginate_anchor(
        self,
        *,
        label: str,
        latitude: float,
        longitude: float,
        vendors_by_code: dict[str, ManifestVendor],
        first_page_only: bool = False,
    ) -> tuple[int, list[str]]:
        errors: list[str] = []
        pages = 0
        offset = 0
        available_count: int | None = None

        while True:
            try:
                payload = self._client.search_restaurants(
                    latitude,
                    longitude,
                    limit=self._page_limit,
                    offset=offset,
                )
            except FoodpandaAPIError as exc:
                msg = f"Search failed anchor={label} offset={offset}: {exc}"
                errors.append(msg)
                log_event("DISCOVERY_PAGE_ERROR", anchor=label, offset=offset, error=str(exc))
                break

            pages += 1
            if available_count is None:
                available_count = extract_available_count(payload)

            raw_vendors = extract_vendor_list(payload)
            if not raw_vendors:
                log_event("DISCOVERY_PAGE_EMPTY", anchor=label, offset=offset)
                break

            before = len(vendors_by_code)
            for raw in raw_vendors:
                parsed = parse_vendor(raw)
                code = (parsed.get("vendor_code") or "").strip().lower()
                if not code:
                    continue
                if code in vendors_by_code:
                    continue
                vendors_by_code[code] = ManifestVendor(
                    external_code=code,
                    external_id=str(parsed.get("vendor_id") or ""),
                    vendor_name=str(parsed.get("vendor_name") or code),
                    city=self._normalize_city(parsed.get("city")) or "Lahore",
                    latitude=latitude,
                    longitude=longitude,
                    anchor=label,
                )

            added = len(vendors_by_code) - before
            log_event(
                "DISCOVERY_PAGE",
                anchor=label,
                offset=offset,
                returned=len(raw_vendors),
                new_vendors=added,
                total_unique=len(vendors_by_code),
                available_count=available_count,
            )

            if first_page_only:
                break
            if added == 0:
                log_event("DISCOVERY_STOP_NO_NEW", anchor=label, offset=offset)
                break
            if len(raw_vendors) < self._page_limit:
                break
            if available_count is not None and offset + self._page_limit >= available_count:
                break

            offset += self._page_limit
            if self._search_delay > 0:
                time.sleep(self._search_delay)

        return pages, errors

    @staticmethod
    def _normalize_city(value: object) -> str | None:
        if value is None:
            return None
        if isinstance(value, dict):
            name = value.get("name")
            return str(name)[:100] if name else None
        text = str(value).strip()
        return text[:100] if text else None

    @staticmethod
    def _new_run_id(city: str) -> str:
        stamp = datetime.now(timezone.utc).strftime("%Y%m%d-%H%M%S")
        slug = city.lower().replace(" ", "-")
        return f"{slug}-{stamp}-{uuid.uuid4().hex[:8]}"
