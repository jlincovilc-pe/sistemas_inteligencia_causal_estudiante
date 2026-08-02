# Quickstart

## 1. Validate the repository

```bash
python -m pytest tests/
python -m causal_benchmark_zoo.fetch validate-all
```

Expected current result:

```text
21 tests passed
```

## 2. List benchmarks

```bash
python -m causal_benchmark_zoo.fetch list
```

Current graph-ready benchmarks:

- `bnlearn_asia`
- `bnlearn_alarm`

## 3. Load a benchmark in Python

```python
from causal_benchmark_zoo import load_benchmark

bench = load_benchmark("bnlearn_asia")
print(bench.graph.number_of_nodes())  # 8
print(bench.graph.number_of_edges())  # 8
```

## 4. Evaluate a predicted graph

Self-comparison smoke test:

```bash
python -m causal_benchmark_zoo.fetch evaluate-graph bnlearn_asia   --predicted benchmarks/bnlearn_asia/graphs/graph.json
```

Expected metrics:

- precision = 1.0
- recall = 1.0
- F1 = 1.0
- Structural Hamming Distance = 0

## 5. Run the example

```bash
python examples/evaluate_graph_bnlearn.py
```

This evaluates Asia and Alarm against themselves as a pipeline smoke test.

## 6. Download and process Lalonde from public NBER URLs

```bash
python -m causal_benchmark_zoo.fetch fetch lalonde_nsw
python -m causal_benchmark_zoo.fetch process lalonde_nsw
```

Load in Python:

```python
from causal_benchmark_zoo import load_benchmark

bench = load_benchmark("lalonde_nsw")
print(bench.data.shape)  # (445, 10)
print(bench.treatment, bench.outcome)  # treat re78
```

The reference estimate is stored in:

```text
benchmarks/lalonde_nsw/ground_truth/ate_reference.yaml
```

