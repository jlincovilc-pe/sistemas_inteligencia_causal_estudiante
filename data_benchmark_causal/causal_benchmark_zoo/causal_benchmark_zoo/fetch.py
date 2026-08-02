from __future__ import annotations

import argparse
import hashlib
import json
import subprocess
import sys
from pathlib import Path
from typing import Any

from .graph_metrics import evaluate_graph_json
from .registry import BENCHMARKS_ROOT, list_benchmarks, load_manifest
from .validation import validate_all_manifests


def _run_script(benchmark_id: str, script_name: str) -> int:
    script = BENCHMARKS_ROOT / benchmark_id / "scripts" / script_name
    if not script.exists():
        print(f"Missing script: {script}", file=sys.stderr)
        return 1
    return subprocess.call([sys.executable, str(script)], cwd=str(BENCHMARKS_ROOT / benchmark_id))


def _sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as f:
        for chunk in iter(lambda: f.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def _artifact_summary(benchmark_id: str, item: dict[str, Any] | None, section: str) -> dict[str, Any]:
    item = item or {}
    rel_path = item.get("path")
    full_path = BENCHMARKS_ROOT / benchmark_id / rel_path if rel_path else None
    exists = bool(full_path and full_path.exists())
    declared_sha256 = item.get("sha256")
    actual_sha256 = _sha256_file(full_path) if exists and full_path and full_path.is_file() else None
    return {
        "section": section,
        "path": rel_path,
        "status": item.get("status"),
        "exists": exists,
        "sha256": declared_sha256,
        "actual_sha256": actual_sha256,
        "hash_matches": (actual_sha256 == declared_sha256) if declared_sha256 and actual_sha256 else None,
        "url": item.get("url"),
        "description": item.get("description"),
    }


def inspect_benchmark(benchmark_id: str) -> dict[str, Any]:
    manifest = load_manifest(benchmark_id)
    manifest.pop("_manifest_path", None)
    artifacts: list[dict[str, Any]] = []
    for section in ["raw", "processed"]:
        for item in manifest.get("files", {}).get(section, []) or []:
            artifacts.append(_artifact_summary(benchmark_id, item, f"files.{section}"))
    artifacts.append(_artifact_summary(benchmark_id, manifest.get("graph"), "graph"))
    artifacts.append(_artifact_summary(benchmark_id, manifest.get("ground_truth"), "ground_truth"))

    available = [a for a in artifacts if a.get("status") == "available"]
    missing_available = [a for a in available if not a.get("exists")]
    hash_mismatches = [a for a in available if a.get("hash_matches") is False]

    return {
        "id": manifest.get("id"),
        "name": manifest.get("name"),
        "category": manifest.get("category"),
        "version": manifest.get("version"),
        "intended_tasks": manifest.get("intended_tasks", []),
        "source": manifest.get("source", {}),
        "license": manifest.get("license", {}),
        "schema": manifest.get("schema", {}),
        "ground_truth": manifest.get("ground_truth", {}),
        "graph": manifest.get("graph", {}),
        "artifacts": artifacts,
        "artifact_status_counts": {
            status: sum(1 for artifact in artifacts if artifact.get("status") == status)
            for status in ["available", "manual", "pending", "external", "not_applicable"]
        },
        "available_artifacts_missing": missing_available,
        "available_artifact_hash_mismatches": hash_mismatches,
        "limitations": manifest.get("limitations", []),
    }


def _inspect_cli(benchmark_id: str) -> int:
    try:
        payload = inspect_benchmark(benchmark_id)
    except FileNotFoundError as exc:
        print(f"Benchmark not found or manifest missing: {benchmark_id}: {exc}", file=sys.stderr)
        return 1
    print(json.dumps(payload, indent=2, sort_keys=True))
    return 0


def _evaluate_graph_cli(benchmark_id: str, predicted: str) -> int:
    manifest = load_manifest(benchmark_id)
    graph_path = (manifest.get("graph", {}) or {}).get("path")
    if not graph_path:
        print(f"Benchmark {benchmark_id} has no reference graph path", file=sys.stderr)
        return 1
    true_path = BENCHMARKS_ROOT / benchmark_id / graph_path
    if not true_path.exists():
        print(f"Reference graph does not exist: {true_path}", file=sys.stderr)
        return 1
    predicted_path = Path(predicted)
    if not predicted_path.is_absolute():
        predicted_path = Path.cwd() / predicted_path
    if not predicted_path.exists():
        print(f"Predicted graph does not exist: {predicted_path}", file=sys.stderr)
        return 1
    metrics = evaluate_graph_json(true_path, predicted_path)
    print(json.dumps(metrics.to_dict(), indent=2))
    return 0


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(prog="causal-benchmark-zoo")
    sub = parser.add_subparsers(dest="command", required=True)
    sub.add_parser("list")
    sub.add_parser("validate-all")
    fetch_p = sub.add_parser("fetch")
    fetch_p.add_argument("benchmark_id")
    proc_p = sub.add_parser("process")
    proc_p.add_argument("benchmark_id")
    inspect_p = sub.add_parser("inspect")
    inspect_p.add_argument("benchmark_id")
    info_p = sub.add_parser("info")
    info_p.add_argument("benchmark_id")
    eval_p = sub.add_parser("evaluate-graph")
    eval_p.add_argument("benchmark_id")
    eval_p.add_argument("--predicted", required=True, help="Path to predicted graph JSON")
    args = parser.parse_args(argv)

    if args.command == "list":
        print(json.dumps(list_benchmarks(), indent=2))
        return 0
    if args.command == "validate-all":
        validated = validate_all_manifests()
        print(json.dumps({"validated": validated}, indent=2))
        return 0
    if args.command == "fetch":
        return _run_script(args.benchmark_id, "download.py")
    if args.command == "process":
        return _run_script(args.benchmark_id, "process.py")
    if args.command in {"inspect", "info"}:
        return _inspect_cli(args.benchmark_id)
    if args.command == "evaluate-graph":
        return _evaluate_graph_cli(args.benchmark_id, args.predicted)
    return 1


if __name__ == "__main__":
    raise SystemExit(main())
