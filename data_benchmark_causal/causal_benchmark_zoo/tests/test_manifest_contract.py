from pathlib import Path

from causal_benchmark_zoo.registry import BENCHMARKS_ROOT, load_manifest, registry_ids


def test_artifact_status_fields_present():
    for benchmark_id in registry_ids():
        manifest = load_manifest(benchmark_id)
        for section in ["raw", "processed"]:
            for item in manifest["files"][section]:
                assert {"path", "status", "description"}.issubset(item)
        assert "status" in manifest["graph"]
        assert "status" in manifest["ground_truth"]


def test_pending_artifacts_are_not_required_to_exist_yet():
    for benchmark_id in registry_ids():
        manifest = load_manifest(benchmark_id)
        for section in ["raw", "processed"]:
            for item in manifest["files"][section]:
                if item["status"] == "pending":
                    assert not (BENCHMARKS_ROOT / benchmark_id / item["path"]).exists()


def test_lalonde_has_explicit_treatment_outcome():
    manifest = load_manifest("lalonde_nsw")
    assert manifest["schema"]["treatment"] == "treat"
    assert manifest["schema"]["outcome"] == "re78"
    assert manifest["ground_truth"]["type"] == "experimental_reference_estimate"
