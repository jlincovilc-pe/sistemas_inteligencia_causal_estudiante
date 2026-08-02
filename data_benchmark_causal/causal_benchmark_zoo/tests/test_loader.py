import pytest

from causal_benchmark_zoo import load_benchmark
from causal_benchmark_zoo.loader import BenchmarkDataNotFound


def test_load_benchmark_without_processed_artifacts_fails_clearly():
    with pytest.raises(BenchmarkDataNotFound, match="no processed data or graph"):
        load_benchmark("csuite_lingauss")
