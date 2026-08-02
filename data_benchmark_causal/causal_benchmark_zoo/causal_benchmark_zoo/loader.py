from __future__ import annotations

from pathlib import Path

import pandas as pd

from .registry import BENCHMARKS_ROOT, load_manifest
from .types import CausalBenchmark, GroundTruth
from .graph_io import load_graph_json


class BenchmarkDataNotFound(FileNotFoundError):
    """Raised when a benchmark is registered but processed artifacts are absent."""


def _first_existing_processed_file(benchmark_id: str, manifest: dict) -> Path | None:
    for item in manifest.get("files", {}).get("processed", []) or []:
        if not isinstance(item, dict):
            continue
        rel = item.get("path")
        if not rel:
            continue
        path = BENCHMARKS_ROOT / benchmark_id / rel
        if path.exists():
            return path
    return None


def _load_table(path: Path) -> pd.DataFrame:
    if path.suffix == ".parquet":
        return pd.read_parquet(path)
    if path.suffix == ".csv":
        return pd.read_csv(path)
    raise ValueError(f"Unsupported processed table format: {path}")


def load_benchmark(benchmark_id: str) -> CausalBenchmark:
    manifest = load_manifest(benchmark_id)
    schema = manifest.get("schema", {}) or {}
    gt_info = manifest.get("ground_truth", {}) or {}

    data_path = _first_existing_processed_file(benchmark_id, manifest)
    data = _load_table(data_path) if data_path else None

    graph = None
    graph_path = (manifest.get("graph", {}) or {}).get("path")
    if graph_path:
        full_graph_path = BENCHMARKS_ROOT / benchmark_id / graph_path
        if full_graph_path.exists() and full_graph_path.suffix == ".json":
            graph = load_graph_json(full_graph_path)

    if data is None and graph is None:
        raise BenchmarkDataNotFound(
            f"{benchmark_id} has no processed data or graph yet. Run: "
            f"causal-benchmark-zoo fetch {benchmark_id} && "
            f"causal-benchmark-zoo process {benchmark_id}"
        )

    return CausalBenchmark(
        id=manifest["id"],
        name=manifest["name"],
        category=manifest["category"],
        data=data,
        graph=graph,
        treatment=schema.get("treatment"),
        outcome=schema.get("outcome"),
        covariates=schema.get("covariates", []) or [],
        effect_modifiers=schema.get("effect_modifiers", []) or [],
        ground_truth=GroundTruth(kind=gt_info.get("type", "none"), metadata=gt_info),
        manifest=manifest,
    )
