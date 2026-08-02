# causal-benchmark-zoo

[![License: MIT](../LICENSE)](../LICENSE)

Python package for loading, validating, and evaluating causal inference benchmarks. Part of the [Causal Benchmark Ecosystem](../README.md).

## Current benchmarks

| Benchmark | Nodes | Edges | Task | Ground truth | Status |
|---|---:|---:|---|---|---|
| `bnlearn_asia` | 8 | 8 | causal discovery | `graph` | Available |
| `bnlearn_alarm` | 37 | 46 | causal discovery | `graph` | Available |
| `lalonde_nsw` | — | — | ATE reference / tabular loading | `experimental_reference_estimate` | Available |

## Pending / manual

| Benchmark | Reason |
|---|---|
| `csuite_lingauss` | GitHub release download returned HTTP 403; ZIP must be provided manually or via authorized access. |

## Installation

```bash
pip install .

# Optional adapters
pip install .[dowhy]
pip install .[econml]
pip install .[dev]
```

Requires Python 3.10+.

## Quickstart

```bash
python -m pytest tests/
python -m causal_benchmark_zoo.fetch validate-all
python -m causal_benchmark_zoo.fetch list
python -m causal_benchmark_zoo.fetch inspect bnlearn_asia
```

Evaluate a predicted graph:

```bash
python -m causal_benchmark_zoo.fetch evaluate-graph bnlearn_asia \
  --predicted benchmarks/bnlearn_asia/graphs/graph.json
```

Run example:

```bash
python examples/evaluate_graph_bnlearn.py
```

## Python API

```python
from causal_benchmark_zoo import list_benchmarks, load_benchmark, evaluate_graph

bench = load_benchmark("lalonde_nsw")
metrics = evaluate_graph(bench.graph, predicted_graph)
```

Optional adapters:

```python
from causal_benchmark_zoo.adapters.dowhy import to_dowhy_model
from causal_benchmark_zoo.adapters.econml import to_econml_arrays
```

## Data integrity

- No fabricated data.
- Raw files are preserved under `raw/`.
- Processed graph artifacts are derived from raw BIF files.
- Manual sources remain manual until access/licensing is resolved.
- Graph benchmarks are not ATE/CATE benchmarks.

## Documentation

| File | Description |
|---|---|
| [`DATASETS.md`](./DATASETS.md) | Dataset catalog and status |
| [`LIMITATIONS.md`](./LIMITATIONS.md) | Methodological and access limitations |
| [`CONTRIBUTING.md`](./CONTRIBUTING.md) | Rules for adding benchmarks |
| [`docs/quickstart.md`](./docs/quickstart.md) | Basic usage |
| [`docs/adding_a_dataset.md`](./docs/adding_a_dataset.md) | Dataset integration workflow |
| [`docs/dowhy_econml_integration.md`](./docs/dowhy_econml_integration.md) | DoWhy / EconML integration |
| [`docs/ground_truth_taxonomy.md`](./docs/ground_truth_taxonomy.md) | Ground-truth types |
| [`docs/graph_metrics_entrega6.md`](./docs/graph_metrics_entrega6.md) | Graph metric definitions |
| [`audit_outputs/`](./audit_outputs/) | Reference readiness reports (stage 7) |

## License

MIT — see [`LICENSE`](./LICENSE). Benchmark data may be subject to upstream source terms (bnlearn, NBER/Dehejia-Wahba).
