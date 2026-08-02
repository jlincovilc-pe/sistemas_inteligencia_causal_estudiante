import csv
import json

import networkx as nx
import yaml

from causal_benchmark_zoo import load_benchmark
from causal_benchmark_zoo.registry import BENCHMARKS_ROOT, load_manifest


EXPECTED = {
    "bnlearn_asia": {"nodes": 8, "edges": 8},
    "bnlearn_alarm": {"nodes": 37, "edges": 46},
}


def _graph_payload(benchmark_id):
    path = BENCHMARKS_ROOT / benchmark_id / "graphs" / "graph.json"
    with path.open("r", encoding="utf-8") as f:
        return json.load(f)


def test_processed_graph_files_exist_and_match_expected_counts():
    for benchmark_id, expected in EXPECTED.items():
        root = BENCHMARKS_ROOT / benchmark_id
        assert (root / "graphs" / "graph.json").exists()
        assert (root / "graphs" / "graph.dot").exists()
        assert (root / "graphs" / "adjacency.csv").exists()
        assert (root / "ground_truth" / "graph_reference.yaml").exists()
        payload = _graph_payload(benchmark_id)
        assert len(payload["nodes"]) == expected["nodes"]
        assert len(payload["edges"]) == expected["edges"]
        assert payload["metadata"]["node_count"] == expected["nodes"]
        assert payload["metadata"]["edge_count"] == expected["edges"]


def test_processed_graphs_are_directed_acyclic_graphs():
    for benchmark_id in EXPECTED:
        payload = _graph_payload(benchmark_id)
        graph = nx.DiGraph()
        graph.add_nodes_from([node["id"] for node in payload["nodes"]])
        graph.add_edges_from([tuple(edge) for edge in payload["edges"]])
        assert nx.is_directed_acyclic_graph(graph)


def test_adjacency_dimensions_match_node_count():
    for benchmark_id, expected in EXPECTED.items():
        path = BENCHMARKS_ROOT / benchmark_id / "graphs" / "adjacency.csv"
        with path.open("r", encoding="utf-8") as f:
            rows = list(csv.reader(f))
        assert len(rows) == expected["nodes"] + 1
        assert len(rows[0]) == expected["nodes"] + 1
        assert all(len(row) == expected["nodes"] + 1 for row in rows)


def test_ground_truth_yaml_matches_graph_metadata():
    for benchmark_id, expected in EXPECTED.items():
        path = BENCHMARKS_ROOT / benchmark_id / "ground_truth" / "graph_reference.yaml"
        with path.open("r", encoding="utf-8") as f:
            gt = yaml.safe_load(f)
        assert gt["type"] == "graph"
        assert gt["status"] == "available"
        assert gt["node_count"] == expected["nodes"]
        assert gt["edge_count"] == expected["edges"]


def test_load_benchmark_loads_processed_graphs():
    for benchmark_id, expected in EXPECTED.items():
        bench = load_benchmark(benchmark_id)
        assert bench.data is None
        assert bench.graph is not None
        assert bench.graph.number_of_nodes() == expected["nodes"]
        assert bench.graph.number_of_edges() == expected["edges"]
        assert bench.ground_truth.kind == "graph"


def test_manifests_mark_processed_graphs_available():
    for benchmark_id in EXPECTED:
        manifest = load_manifest(benchmark_id)
        assert manifest["graph"]["status"] == "available"
        assert manifest["graph"]["path"] == "graphs/graph.json"
        assert manifest["ground_truth"]["status"] == "available"
        assert manifest["ground_truth"]["path"] == "ground_truth/graph_reference.yaml"
