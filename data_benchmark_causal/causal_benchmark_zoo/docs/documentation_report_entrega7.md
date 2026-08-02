# Entrega 7 documentation report

Ruta A focused on making the repository usable and auditable without adding new data.

## Added or consolidated

- `README.md`
- `DATASETS.md`
- `LIMITATIONS.md`
- `CONTRIBUTING.md`
- `docs/quickstart.md`
- `docs/adding_a_dataset.md`
- `docs/dowhy_econml_integration.md`
- `docs/ground_truth_taxonomy.md`
- `tests/test_documentation_files.py`

## Current usable workflow

```bash
python -m pytest tests/
python -m causal_benchmark_zoo.fetch validate-all
python -m causal_benchmark_zoo.fetch list
python -m causal_benchmark_zoo.fetch evaluate-graph bnlearn_asia --predicted benchmarks/bnlearn_asia/graphs/graph.json
```

## Active data

Only bnlearn Asia and Alarm graph artifacts are active. No new datasets were downloaded or fabricated in this stage.
