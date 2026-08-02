# Limitations

## No fabricated data

This repository does not create synthetic replacements for missing datasets. If a source cannot be accessed, the benchmark remains manual or pending.

## Active benchmark scope

Currently active:

- graph benchmarks: `bnlearn_asia`, `bnlearn_alarm`;
- tabular experimental reference benchmark: `lalonde_nsw`.

## Lalonde reference estimate limitation

The Lalonde/NSW ATE is computed as a difference in observed 1978 earnings means between randomized treated and control groups in the public Dehejia-Wahba NSW sample. It is an experimental reference estimate with sampling uncertainty:

- ATE: 1,794.34
- SE: 671.00
- 95% CI: [474.01, 3,114.67]

Do not describe this as an exact mathematical ground truth.

## Expert DAG limitation

The Lalonde DAG is a maintained expert adjustment graph over documented pre-treatment covariates. It is not learned from the data and is not unique.

## CSuite access limitation

The GitHub release URL for `csuite_lingauss` returned HTTP 403 in this platform. The repository does not use unverified mirrors.

## Graph metric limitations

Graph metrics compare directed edge recovery. They do not establish treatment-effect validity. Structural Hamming Distance counts one reversed edge as one operation.
