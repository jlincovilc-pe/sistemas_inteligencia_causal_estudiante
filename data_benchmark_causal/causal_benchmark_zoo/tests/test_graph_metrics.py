import json
import subprocess

import networkx as nx

from causal_benchmark_zoo.graph_metrics import evaluate_graph, evaluate_graph_json, structural_hamming_distance
from causal_benchmark_zoo.registry import BENCHMARKS_ROOT


def test_evaluate_graph_perfect_match():
    g = nx.DiGraph([("a", "b"), ("b", "c")])
    metrics = evaluate_graph(g, g).to_dict()
    assert metrics["precision"] == 1.0
    assert metrics["recall"] == 1.0
    assert metrics["f1"] == 1.0
    assert metrics["structural_hamming_distance"] == 0
    assert metrics["true_positives"] == 2


def test_evaluate_graph_with_extra_and_missing_edges():
    true = nx.DiGraph([("a", "b"), ("b", "c")])
    pred = nx.DiGraph([("a", "b"), ("a", "c")])
    metrics = evaluate_graph(true, pred).to_dict()
    assert metrics["true_positives"] == 1
    assert metrics["false_positives"] == 1
    assert metrics["false_negatives"] == 1
    assert metrics["precision"] == 0.5
    assert metrics["recall"] == 0.5
    assert metrics["f1"] == 0.5
    assert metrics["structural_hamming_distance"] == 2


def test_reversal_counts_as_one_shd_operation():
    true = nx.DiGraph([("a", "b")])
    pred = nx.DiGraph([("b", "a")])
    shd, reversals = structural_hamming_distance(true, pred)
    assert shd == 1
    assert reversals == 1


def test_evaluate_processed_bnlearn_self_comparison_is_perfect():
    for benchmark_id, expected_edges in [("bnlearn_asia", 8), ("bnlearn_alarm", 46)]:
        graph_path = BENCHMARKS_ROOT / benchmark_id / "graphs" / "graph.json"
        metrics = evaluate_graph_json(graph_path, graph_path).to_dict()
        assert metrics["true_edges"] == expected_edges
        assert metrics["predicted_edges"] == expected_edges
        assert metrics["precision"] == 1.0
        assert metrics["recall"] == 1.0
        assert metrics["f1"] == 1.0
        assert metrics["structural_hamming_distance"] == 0


def test_cli_evaluate_graph_self_comparison():
    repo = BENCHMARKS_ROOT.parents[0]
    predicted = BENCHMARKS_ROOT / "bnlearn_asia" / "graphs" / "graph.json"
    result = subprocess.run(
        ["python", "-m", "causal_benchmark_zoo.fetch", "evaluate-graph", "bnlearn_asia", "--predicted", str(predicted)],
        cwd=repo,
        text=True,
        capture_output=True,
    )
    assert result.returncode == 0, result.stderr
    payload = json.loads(result.stdout)
    assert payload["precision"] == 1.0
    assert payload["recall"] == 1.0
    assert payload["structural_hamming_distance"] == 0
