"""Chunked Foodpanda menu import runner with checkpoint/resume support."""

from __future__ import annotations

import time
from dataclasses import dataclass, field
from pathlib import Path

from sqlalchemy.orm import Session

from app.integrations.foodpanda.foodpanda_client import FoodpandaClient
from app.services.foodpanda_bulk.logging_utils import log_event, log_metrics
from app.services.foodpanda_bulk.manifest import DiscoveryManifest, ImportCheckpoint, ManifestVendor
from app.services.foodpanda_import_service import FoodpandaImportService, ImportIndexes


@dataclass
class BulkImportResult:
    checkpoint: ImportCheckpoint
    checkpoint_path: Path
    errors: list[str] = field(default_factory=list)


class FoodpandaBulkImportRunner:
    """
    Import vendors from a discovery manifest in chunks.

    Indexes are rebuilt once per chunk (not per vendor) to avoid full-table scans
    on every menu import.
    """

    def __init__(
        self,
        db: Session,
        client: FoodpandaClient,
        *,
        chunk_size: int = 50,
        menu_delay_seconds: float = 0.5,
        skip_existing: bool = True,
    ) -> None:
        self._db = db
        self._client = client
        self._chunk_size = chunk_size
        self._menu_delay = menu_delay_seconds
        self._skip_existing = skip_existing
        self._service = FoodpandaImportService(db, client)

    def run(
        self,
        manifest_path: Path,
        *,
        checkpoint_path: Path | None = None,
        resume: bool = True,
        limit: int | None = None,
    ) -> BulkImportResult:
        manifest = DiscoveryManifest.load(manifest_path)
        cp_path = checkpoint_path or manifest_path.parent / "checkpoint.json"

        if resume and cp_path.exists():
            checkpoint = ImportCheckpoint.load(cp_path)
            if checkpoint.manifest_path != str(manifest_path):
                checkpoint.manifest_path = str(manifest_path)
            effective_limit = checkpoint.vendor_limit
            log_event(
                "IMPORT_RESUME",
                run_id=checkpoint.run_id,
                next_index=checkpoint.next_vendor_index,
                vendor_limit=effective_limit,
            )
        else:
            effective_limit = limit
            checkpoint = ImportCheckpoint(
                run_id=manifest.run_id,
                manifest_path=str(manifest_path),
                chunk_size=self._chunk_size,
                vendor_limit=effective_limit,
            )
            vendors_total = len(manifest.vendors)
            if effective_limit is not None:
                vendors_total = min(vendors_total, effective_limit)
            log_event(
                "IMPORT_START",
                run_id=checkpoint.run_id,
                vendors_total=vendors_total,
                vendor_limit=effective_limit,
            )

        errors: list[str] = []
        owner_id = self._service._resolve_import_owner_id()
        db_existing_codes: set[str] = set()

        vendors = manifest.vendors
        end_index = len(vendors)
        if effective_limit is not None:
            end_index = min(end_index, effective_limit)
        idx = checkpoint.next_vendor_index

        while idx < end_index:
            chunk = vendors[idx : min(idx + self._chunk_size, end_index)]
            chunk_num = (idx // self._chunk_size) + 1
            log_event(
                "IMPORT_CHUNK_START",
                run_id=checkpoint.run_id,
                chunk=chunk_num,
                chunk_size=len(chunk),
                start_index=idx,
            )

            indexes = self._service.build_import_indexes()
            if self._skip_existing:
                db_existing_codes = self._service.load_imported_external_codes()

            for vendor in chunk:
                code = vendor.external_code.lower()
                if code in checkpoint.completed_code_set:
                    checkpoint.vendors_skipped += 1
                    continue
                if self._skip_existing and code in db_existing_codes:
                    checkpoint.vendors_skipped += 1
                    checkpoint.completed_codes.append(code)
                    log_event(
                        "IMPORT_VENDOR_SKIPPED",
                        run_id=checkpoint.run_id,
                        external_code=code,
                        reason="already_in_db",
                    )
                    continue

                stats = self._import_one(vendor, owner_id=owner_id, indexes=indexes)
                if stats.errors:
                    checkpoint.vendors_failed += 1
                    error_msg = "; ".join(stats.errors)
                    checkpoint.failed_vendors[code] = error_msg
                    errors.append(f"{code}: {error_msg}")
                    log_event(
                        "IMPORT_VENDOR_FAIL",
                        run_id=checkpoint.run_id,
                        external_code=code,
                        error=error_msg,
                    )
                else:
                    checkpoint.vendors_imported += 1
                    checkpoint.completed_codes.append(code)
                    checkpoint.dishes_created += stats.dishes_created
                    checkpoint.dishes_updated += stats.dishes_updated
                    checkpoint.categories_created += stats.categories_created
                    log_event(
                        "IMPORT_VENDOR_SUCCESS",
                        run_id=checkpoint.run_id,
                        external_code=code,
                        dishes_created=stats.dishes_created,
                        dishes_updated=stats.dishes_updated,
                    )

                if self._menu_delay > 0:
                    time.sleep(self._menu_delay)

            idx += len(chunk)
            checkpoint.next_vendor_index = idx
            checkpoint.status = "running"
            checkpoint.save(cp_path)
            log_event(
                "CHECKPOINT_SAVED",
                run_id=checkpoint.run_id,
                chunk=chunk_num,
                next_vendor_index=idx,
                **checkpoint.metrics_dict(),
            )

        checkpoint.status = "completed"
        checkpoint.save(cp_path)
        log_metrics(checkpoint.run_id, checkpoint.metrics_dict())
        log_event("IMPORT_COMPLETE", run_id=checkpoint.run_id, status=checkpoint.status)

        return BulkImportResult(checkpoint=checkpoint, checkpoint_path=cp_path, errors=errors)

    def _import_one(
        self,
        vendor: ManifestVendor,
        *,
        owner_id: int,
        indexes: ImportIndexes,
    ):
        lat = vendor.latitude if vendor.latitude is not None else 31.5204
        lon = vendor.longitude if vendor.longitude is not None else 74.3587
        vendor_hint = {
            "vendor_id": vendor.external_id,
            "vendor_code": vendor.external_code,
            "vendor_name": vendor.vendor_name,
            "city": vendor.city,
        }
        return self._service.import_vendor(
            vendor.external_code,
            lat,
            lon,
            vendor_hint=vendor_hint,
            indexes=indexes,
            owner_id=owner_id,
        )
