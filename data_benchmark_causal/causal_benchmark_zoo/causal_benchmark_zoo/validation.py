from __future__ import annotations

import json
from pathlib import Path
from typing import Any

import jsonschema

from .registry import BENCHMARKS_ROOT, PACKAGE_ROOT, load_manifest, registry_ids

SCHEMAS_ROOT = PACKAGE_ROOT / "schemas"
VALID_ARTIFACT_STATUSES = {"pending", "available", "manual", "external", "not_applicable"}
VALID_GROUND_TRUTH_TYPES = {"ate", "cate", "graph", "sem", "experimental_reference_estimate", "none"}
ATE_TASKS = {"ate_estimation", "cate_estimation"}


def _load_json(path: Path) -> dict[str, Any]:
    with path.open("r", encoding="utf-8") as f:
        return json.load(f)


def _artifact_path(benchmark_id: str, rel_path: str | None) -> Path | None:
    if not rel_path:
        return None
    return BENCHMARKS_ROOT / benchmark_id / rel_path


def _validate_artifact_item(benchmark_id: str, section: str, item: dict[str, Any]) -> None:
    status = item.get("status")
    if status not in VALID_ARTIFACT_STATUSES:
        raise ValueError(f"{benchmark_id}: files.{section} has invalid status {status!r}")
    path = item.get("path")
    if status == "available":
        full = _artifact_path(benchmark_id, path)
        if full is None or not full.exists():
            raise FileNotFoundError(f"{benchmark_id}: files.{section} marks {path!r} as available but file is missing")
        if item.get("sha256") is None:
            raise ValueError(f"{benchmark_id}: available artifact {path!r} must declare sha256")
    if status in {"pending", "manual"} and item.get("sha256") is not None:
        raise ValueError(f"{benchmark_id}: {path!r} has status {status!r} but already declares sha256")


def validate_manifest(benchmark_id: str) -> None:
    schema = _load_json(SCHEMAS_ROOT / "manifest.schema.json")
    manifest = load_manifest(benchmark_id).copy()
    manifest.pop("_manifest_path", None)
    jsonschema.validate(instance=manifest, schema=schema)

    if manifest.get("id") != benchmark_id:
        raise ValueError(f"Registry id {benchmark_id!r} does not match manifest id {manifest.get('id')!r}")

    for section in ["raw", "processed"]:
        for item in manifest.get("files", {}).get(section, []) or []:
            _validate_artifact_item(benchmark_id, section, item)

    graph = manifest.get("graph", {}) or {}
    graph_status = graph.get("status")
    if graph_status not in VALID_ARTIFACT_STATUSES:
        raise ValueError(f"{benchmark_id}: invalid graph.status {graph_status!r}")
    if graph.get("available") is False and graph.get("path") is not None:
        raise ValueError(f"{benchmark_id}: graph.path should be null when graph.available is false")
    if graph_status == "available":
        full = _artifact_path(benchmark_id, graph.get("path"))
        if full is None or not full.exists():
            raise FileNotFoundError(f"{benchmark_id}: graph is marked available but file is missing")
    if graph_status == "not_applicable" and graph.get("available") is True:
        raise ValueError(f"{benchmark_id}: graph.available cannot be true when graph.status is not_applicable")

    gt = manifest.get("ground_truth", {}) or {}
    gt_type = gt.get("type")
    gt_status = gt.get("status")
    if gt_type not in VALID_GROUND_TRUTH_TYPES:
        raise ValueError(f"{benchmark_id}: invalid ground_truth.type {gt_type!r}")
    if gt_status not in VALID_ARTIFACT_STATUSES:
        raise ValueError(f"{benchmark_id}: invalid ground_truth.status {gt_status!r}")
    if gt_type == "none" and gt_status != "not_applicable":
        raise ValueError(f"{benchmark_id}: ground_truth.status should be not_applicable when type is none")
    if gt_status == "available":
        full = _artifact_path(benchmark_id, gt.get("path"))
        if full is None or not full.exists():
            raise FileNotFoundError(f"{benchmark_id}: ground truth is marked available but file is missing")

    tasks = set(manifest.get("intended_tasks", []))
    schema_block = manifest.get("schema", {}) or {}
    if tasks & ATE_TASKS:
        # CSuite may define treatment/outcome after archive inspection, but real tabular benchmarks should declare them now.
        if manifest.get("category") == "real_experimental_reference":
            if not schema_block.get("treatment") or not schema_block.get("outcome"):
                raise ValueError(f"{benchmark_id}: real ATE benchmark must declare treatment and outcome")
    if gt_type == "graph" and tasks & ATE_TASKS:
        raise ValueError(f"{benchmark_id}: graph-only ground truth cannot advertise ATE/CATE tasks")


def validate_all_manifests() -> list[str]:
    validated: list[str] = []
    for benchmark_id in registry_ids():
        validate_manifest(benchmark_id)
        validated.append(benchmark_id)
    return validated
