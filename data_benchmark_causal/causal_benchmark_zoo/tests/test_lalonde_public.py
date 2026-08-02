import math
from pathlib import Path

import pandas as pd
import yaml

from causal_benchmark_zoo import load_benchmark
from causal_benchmark_zoo.registry import BENCHMARKS_ROOT, load_manifest


def test_lalonde_processed_files_and_columns():
    root = BENCHMARKS_ROOT / "lalonde_nsw"
    parquet = root / "processed" / "lalonde_nsw.parquet"
    csv = root / "processed" / "lalonde_nsw.csv"
    assert parquet.exists()
    assert csv.exists()
    df = pd.read_parquet(parquet)
    assert df.shape == (445, 10)
    assert list(df.columns) == ["treat", "age", "educ", "black", "hispan", "married", "nodegree", "re74", "re75", "re78"]
    assert sorted(df["treat"].unique().tolist()) == [0, 1]
    assert int((df["treat"] == 1).sum()) == 185
    assert int((df["treat"] == 0).sum()) == 260


def test_lalonde_ground_truth_reference_estimate():
    path = BENCHMARKS_ROOT / "lalonde_nsw" / "ground_truth" / "ate_reference.yaml"
    with path.open("r", encoding="utf-8") as f:
        gt = yaml.safe_load(f)
    assert gt["type"] == "experimental_reference_estimate"
    assert gt["status"] == "available"
    assert gt["n_treated"] == 185
    assert gt["n_control"] == 260
    assert math.isclose(gt["value"], 1794.342404270271, rel_tol=0, abs_tol=1e-9)
    assert math.isclose(gt["standard_error"], 670.9965463815241, rel_tol=0, abs_tol=1e-9)
    assert len(gt["confidence_interval_95"]) == 2
    assert gt["confidence_interval_95"][0] < gt["value"] < gt["confidence_interval_95"][1]


def test_lalonde_loader_returns_data_graph_and_metadata():
    bench = load_benchmark("lalonde_nsw")
    assert bench.data is not None
    assert bench.data.shape == (445, 10)
    assert bench.graph is not None
    assert bench.treatment == "treat"
    assert bench.outcome == "re78"
    assert bench.ground_truth.kind == "experimental_reference_estimate"


def test_lalonde_manifest_available_statuses():
    manifest = load_manifest("lalonde_nsw")
    assert all(item["status"] == "available" for item in manifest["files"]["raw"])
    assert all(item["status"] == "available" for item in manifest["files"]["processed"])
    assert manifest["graph"]["status"] == "available"
    assert manifest["ground_truth"]["status"] == "available"
