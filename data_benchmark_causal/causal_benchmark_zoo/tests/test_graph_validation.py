import networkx as nx
import pytest

from causal_benchmark_zoo.graph_io import assert_dag


def test_assert_dag_accepts_acyclic_graph():
    g = nx.DiGraph([("a", "b"), ("b", "c")])
    assert_dag(g)


def test_assert_dag_rejects_cycle():
    g = nx.DiGraph([("a", "b"), ("b", "a")])
    with pytest.raises(ValueError, match="not a directed acyclic graph"):
        assert_dag(g)
