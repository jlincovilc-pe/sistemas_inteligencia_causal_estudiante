# Entrega 5 processing report

This stage processed the raw bnlearn BIF files downloaded in Entrega 4 into graph artifacts.

## Results

| Benchmark | Nodes | Directed edges | Graph JSON | DOT | Adjacency CSV | Ground truth YAML |
|---|---:|---:|---|---|---|---|
| bnlearn_asia | 8 | 8 | `graphs/graph.json` | `graphs/graph.dot` | `graphs/adjacency.csv` | `ground_truth/graph_reference.yaml` |
| bnlearn_alarm | 37 | 46 | `graphs/graph.json` | `graphs/graph.dot` | `graphs/adjacency.csv` | `ground_truth/graph_reference.yaml` |

## Integrity notes

- Input files were the original `.bif.gz` files downloaded from the bnlearn Bayesian Network Repository in Entrega 4.
- No graph edges or nodes were invented. Nodes were parsed from `variable` declarations and directed edges from parent sets in `probability(child | parents)` blocks.
- These are graph-only benchmarks. No Average Treatment Effect (ATE) or Conditional Average Treatment Effect (CATE) is implied.
