from causal_benchmark_zoo import list_benchmarks


def test_ground_truth_types_are_expected():
    allowed = {"ate", "cate", "graph", "sem", "experimental_reference_estimate", "none"}
    for row in list_benchmarks():
        assert row["ground_truth_type"] in allowed
