from __future__ import annotations

import json
from pathlib import Path

import networkx as nx


def load_graph_json(path: str | Path) -> nx.DiGraph:
    path = Path(path)
    with path.open("r", encoding="utf-8") as f:
        payload = json.load(f)
    graph = nx.DiGraph()
    for node in payload.get("nodes", []):
        if isinstance(node, dict):
            node_id = node.get("id")
            attrs = {k: v for k, v in node.items() if k != "id"}
            graph.add_node(node_id, **attrs)
        else:
            graph.add_node(node)
    for edge in payload.get("edges", []):
        if len(edge) >= 2:
            graph.add_edge(edge[0], edge[1])
    return graph


def assert_dag(graph: nx.DiGraph) -> None:
    if not nx.is_directed_acyclic_graph(graph):
        raise ValueError("Graph is not a directed acyclic graph")
