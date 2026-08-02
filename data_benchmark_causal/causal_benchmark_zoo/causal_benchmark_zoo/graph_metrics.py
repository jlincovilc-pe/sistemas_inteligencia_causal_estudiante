from __future__ import annotations

from dataclasses import asdict, dataclass
from pathlib import Path

import networkx as nx

from .graph_io import load_graph_json


@dataclass(frozen=True)
class GraphMetrics:
    true_nodes: int
    predicted_nodes: int
    shared_nodes: int
    true_edges: int
    predicted_edges: int
    true_positives: int
    false_positives: int
    false_negatives: int
    precision: float | None
    recall: float | None
    f1: float | None
    structural_hamming_distance: int
    reversed_edges: int
    node_jaccard: float | None

    def to_dict(self) -> dict:
        return asdict(self)


def _edge_set(graph: nx.DiGraph) -> set[tuple[str, str]]:
    return {(str(u), str(v)) for u, v in graph.edges()}


def _node_set(graph: nx.DiGraph) -> set[str]:
    return {str(n) for n in graph.nodes()}


def structural_hamming_distance(true_graph: nx.DiGraph, predicted_graph: nx.DiGraph) -> tuple[int, int]:
    """Compute DAG-style SHD with one reversal counted as one operation."""
    true_edges = set(_edge_set(true_graph))
    pred_edges = set(_edge_set(predicted_graph))

    reversals = 0
    for edge in list(true_edges):
        rev = (edge[1], edge[0])
        if rev in pred_edges:
            reversals += 1
            true_edges.remove(edge)
            pred_edges.remove(rev)

    shd = reversals + len(true_edges - pred_edges) + len(pred_edges - true_edges)
    return shd, reversals


def evaluate_graph(true_graph: nx.DiGraph, predicted_graph: nx.DiGraph) -> GraphMetrics:
    true_nodes = _node_set(true_graph)
    pred_nodes = _node_set(predicted_graph)
    shared_nodes = true_nodes & pred_nodes
    node_union = true_nodes | pred_nodes

    true_edges = _edge_set(true_graph)
    pred_edges = _edge_set(predicted_graph)

    tp = len(true_edges & pred_edges)
    fp = len(pred_edges - true_edges)
    fn = len(true_edges - pred_edges)

    precision = tp / (tp + fp) if (tp + fp) else None
    recall = tp / (tp + fn) if (tp + fn) else None
    f1 = (2 * precision * recall / (precision + recall)) if precision is not None and recall is not None and (precision + recall) else None
    shd, reversals = structural_hamming_distance(true_graph, predicted_graph)
    node_jaccard = len(shared_nodes) / len(node_union) if node_union else None

    return GraphMetrics(
        true_nodes=len(true_nodes),
        predicted_nodes=len(pred_nodes),
        shared_nodes=len(shared_nodes),
        true_edges=len(true_edges),
        predicted_edges=len(pred_edges),
        true_positives=tp,
        false_positives=fp,
        false_negatives=fn,
        precision=precision,
        recall=recall,
        f1=f1,
        structural_hamming_distance=shd,
        reversed_edges=reversals,
        node_jaccard=node_jaccard,
    )


def evaluate_graph_json(true_graph_path: str | Path, predicted_graph_path: str | Path) -> GraphMetrics:
    true_graph = load_graph_json(true_graph_path)
    predicted_graph = load_graph_json(predicted_graph_path)
    return evaluate_graph(true_graph, predicted_graph)
