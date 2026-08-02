from causal_benchmark_zoo import list_benchmarks
from causal_benchmark_zoo.registry import registry_ids


def test_registry_has_mvp_benchmarks():
    assert registry_ids() == [
        "csuite_lingauss",
        "bnlearn_asia",
        "bnlearn_alarm",
        "lalonde_nsw",
    ]


def test_list_benchmarks_shape_and_current_status():
    rows = list_benchmarks()
    assert len(rows) == 4
    assert {"id", "category", "has_data", "has_graph", "ground_truth_type"}.issubset(rows[0].keys())
    by_id = {row["id"]: row for row in rows}
    assert by_id["bnlearn_asia"]["has_graph"] is True
    assert by_id["bnlearn_alarm"]["has_graph"] is True
    assert by_id["lalonde_nsw"]["has_data"] is True
    assert by_id["lalonde_nsw"]["has_graph"] is True
    assert by_id["csuite_lingauss"]["has_data"] is False
