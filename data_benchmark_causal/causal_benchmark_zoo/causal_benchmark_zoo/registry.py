from __future__ import annotations

from pathlib import Path
from typing import Any

import yaml

PACKAGE_ROOT = Path(__file__).resolve().parents[1]
BENCHMARKS_ROOT = PACKAGE_ROOT / "benchmarks"
REGISTRY_PATH = BENCHMARKS_ROOT / "registry.yaml"


class BenchmarkNotFound(KeyError):
    """Raised when a benchmark id is absent from the registry."""


def _read_yaml(path: Path) -> dict[str, Any]:
    with path.open("r", encoding="utf-8") as f:
        data = yaml.safe_load(f)
    return data or {}


def registry_ids() -> list[str]:
    registry = _read_yaml(REGISTRY_PATH)
    return [item["id"] for item in registry.get("benchmarks", [])]


def load_manifest(benchmark_id: str) -> dict[str, Any]:
    if benchmark_id not in registry_ids():
        raise BenchmarkNotFound(f"Unknown benchmark id: {benchmark_id}")
    manifest_path = BENCHMARKS_ROOT / benchmark_id / "manifest.yaml"
    if not manifest_path.exists():
        raise FileNotFoundError(f"Missing manifest: {manifest_path}")
    manifest = _read_yaml(manifest_path)
    manifest["_manifest_path"] = str(manifest_path)
    return manifest


def _file_exists_relative(benchmark_id: str, rel_path: str | None) -> bool:
    if not rel_path:
        return False
    return (BENCHMARKS_ROOT / benchmark_id / rel_path).exists()


def list_benchmarks() -> list[dict[str, Any]]:
    rows: list[dict[str, Any]] = []
    for benchmark_id in registry_ids():
        manifest = load_manifest(benchmark_id)
        processed = manifest.get("files", {}).get("processed", []) or []
        has_data = any(_file_exists_relative(benchmark_id, item.get("path")) for item in processed if isinstance(item, dict))
        graph_info = manifest.get("graph", {}) or {}
        has_graph = _file_exists_relative(benchmark_id, graph_info.get("path"))
        rows.append({
            "id": manifest.get("id", benchmark_id),
            "name": manifest.get("name"),
            "category": manifest.get("category"),
            "has_data": has_data,
            "has_graph": has_graph,
            "ground_truth_type": (manifest.get("ground_truth", {}) or {}).get("type"),
            "intended_tasks": manifest.get("intended_tasks", []),
        })
    return rows
