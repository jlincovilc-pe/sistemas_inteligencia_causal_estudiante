# Entrega 6 graph metrics

This stage adds graph evaluation utilities for causal discovery benchmarks.

## Metrics

- `true_positives`: directed edges present in both reference and predicted graph.
- `false_positives`: directed edges present only in predicted graph.
- `false_negatives`: directed edges present only in reference graph.
- `precision`: TP / (TP + FP), or null when no predicted edges exist.
- `recall`: TP / (TP + FN), or null when no reference edges exist.
- `f1`: harmonic mean of precision and recall, or null when undefined.
- `structural_hamming_distance`: DAG-style edit distance; one reversed edge counts as one operation.
- `reversed_edges`: number of true edges found in the opposite direction in the predicted graph.
- `node_jaccard`: Jaccard similarity between reference and predicted node sets.

## CLI

```bash
python -m causal_benchmark_zoo.fetch evaluate-graph bnlearn_asia   --predicted benchmarks/bnlearn_asia/graphs/graph.json
```

Self-comparison of a reference graph should return precision = 1, recall = 1, F1 = 1, and SHD = 0.

## Scope

These metrics evaluate graph recovery only. They do not evaluate ATE/CATE and should not be interpreted as treatment-effect validation.
