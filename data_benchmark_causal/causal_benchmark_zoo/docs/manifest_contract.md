# Manifest contract

Each benchmark must declare metadata before any dataset is downloaded. The manifest is a contract: it records what artifacts are expected, which artifacts are already available, and what causal task the benchmark supports.

## Artifact status

Artifacts under `files.raw`, `files.processed`, `graph`, and `ground_truth` use a `status` field:

- `pending`: expected in a later fetch/process stage; path may not exist yet.
- `available`: file must exist locally and should include a SHA256 hash when applicable.
- `manual`: user must place the file manually because automated download or redistribution is uncertain.
- `external`: artifact is not stored locally and remains referenced by source metadata.
- `not_applicable`: artifact does not apply to this benchmark.

Validation enforces existence only for `available` artifacts. This lets the repository remain honest during early stages without fabricating data.

## Ground truth types

Allowed `ground_truth.type` values:

- `ate`: Average Treatment Effect is known or directly computable from interventional/potential-outcome files.
- `cate`: Conditional Average Treatment Effect is known or directly computable.
- `graph`: reference graph exists; no ATE is implied.
- `sem`: structural equation model is known.
- `experimental_reference_estimate`: estimate from randomized experimental data, with uncertainty when computable.
- `none`: no acceptable ground truth is available.

A benchmark with `ground_truth.type: graph` must not be treated as an ATE benchmark unless an intervention and outcome are explicitly defined elsewhere.
