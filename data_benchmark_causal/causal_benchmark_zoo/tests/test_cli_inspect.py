import json
import subprocess
import sys

from causal_benchmark_zoo.registry import BENCHMARKS_ROOT


def _run_inspect(benchmark_id: str, command: str = "inspect"):
    repo = BENCHMARKS_ROOT.parents[0]
    result = subprocess.run(
        [sys.executable, "-m", "causal_benchmark_zoo.fetch", command, benchmark_id],
        cwd=repo,
        text=True,
        capture_output=True,
    )
    assert result.returncode == 0, result.stderr
    return json.loads(result.stdout)


def test_inspect_lalonde_reports_ate_reference_and_artifacts():
    payload = _run_inspect("lalonde_nsw")
    assert payload["id"] == "lalonde_nsw"
    assert payload["category"] == "real_experimental_reference"
    assert payload["schema"]["treatment"] == "treat"
    assert payload["schema"]["outcome"] == "re78"
    assert payload["ground_truth"]["type"] == "experimental_reference_estimate"
    assert "ate_estimation" in payload["intended_tasks"]
    assert payload["artifact_status_counts"]["available"] >= 6
    assert payload["available_artifacts_missing"] == []
    assert payload["available_artifact_hash_mismatches"] == []


def test_inspect_bnlearn_reports_graph_reference():
    payload = _run_inspect("bnlearn_asia")
    assert payload["id"] == "bnlearn_asia"
    assert payload["category"] == "synthetic_bayesian_network"
    assert payload["ground_truth"]["type"] == "graph"
    assert payload["graph"]["status"] == "available"
    assert payload["graph"]["path"] == "graphs/graph.json"
    assert payload["available_artifacts_missing"] == []
    assert payload["available_artifact_hash_mismatches"] == []


def test_inspect_csuite_reports_manual_pending_without_bundled_data():
    payload = _run_inspect("csuite_lingauss")
    assert payload["id"] == "csuite_lingauss"
    assert payload["category"] == "synthetic_sem"
    assert payload["ground_truth"]["type"] == "sem"
    assert payload["ground_truth"]["status"] == "pending"
    assert payload["graph"]["status"] == "pending"
    assert payload["artifact_status_counts"]["manual"] == 1
    assert payload["artifact_status_counts"]["pending"] >= 3
    raw = [a for a in payload["artifacts"] if a["section"] == "files.raw"][0]
    assert raw["path"] == "raw/csuite_lingauss.zip"
    assert raw["status"] == "manual"
    assert raw["exists"] is False


def test_info_alias_matches_inspect_core_fields():
    inspect_payload = _run_inspect("bnlearn_alarm", "inspect")
    info_payload = _run_inspect("bnlearn_alarm", "info")
    for key in ["id", "category", "ground_truth", "schema", "artifact_status_counts"]:
        assert info_payload[key] == inspect_payload[key]
