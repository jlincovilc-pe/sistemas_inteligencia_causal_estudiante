# Dataset catalog

This repository now supports public automated download for three benchmark entries and has one remaining manual entry.

## Current status

| Benchmark | Category | Raw data | Processed data | Processed graph | Ground truth | Supported task now |
|---|---|---:|---:|---:|---|---|
| `bnlearn_asia` | `synthetic_bayesian_network` | yes | no | yes | `graph` | causal discovery graph evaluation |
| `bnlearn_alarm` | `synthetic_bayesian_network` | yes | no | yes | `graph` | causal discovery graph evaluation |
| `lalonde_nsw` | `real_experimental_reference` | yes | yes | expert DAG | `experimental_reference_estimate` | ATE reference / tabular loading |
| `csuite_lingauss` | `synthetic_sem` | manual | no | no | `sem` pending/manual | pending source ZIP |

## `bnlearn_asia`

Public source: https://www.bnlearn.com/bnrepository/asia/asia.bif.gz

Reference graph size: 8 nodes, 8 directed edges.

## `bnlearn_alarm`

Public source: https://www.bnlearn.com/bnrepository/alarm/alarm.bif.gz

Reference graph size: 37 nodes, 46 directed edges.

## `lalonde_nsw`

Public source page: https://users.nber.org/~rdehejia/nswdata.html

Downloaded files:

- `raw/nswre74_treated.txt`: 185 treated observations with RE74
- `raw/nswre74_control.txt`: 260 control observations with RE74

Processed files:

- `processed/lalonde_nsw.parquet`
- `processed/lalonde_nsw.csv`
- `graphs/expert_dag.json`
- `graphs/expert_dag.dot`
- `ground_truth/ate_reference.yaml`

Processed table shape: 445 rows x 10 columns.

Columns:

```text
treat, age, educ, black, hispan, married, nodegree, re74, re75, re78
```

Experimental reference estimate from the randomized NSW sample:

- ATE difference in 1978 earnings: 1,794.34
- standard error: 671.00
- 95% CI: [474.01, 3,114.67]
- n treated: 185
- n control: 260

This is an experimental estimate with sampling uncertainty, not an exact mathematical constant.

## `csuite_lingauss`

Source declared in manifest:

- https://github.com/microsoft/csuite/releases/download/v0.1/csuite_lingauss.zip

Current status:

- public URL declared;
- platform request returned HTTP 403;
- no ZIP is bundled;
- no substituted mirror is used.
