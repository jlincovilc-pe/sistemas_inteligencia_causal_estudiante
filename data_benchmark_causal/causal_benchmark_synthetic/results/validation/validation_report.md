# Validation report

Datasets checked: 43
Status counts: pass=33, warning=10, error=0

| dataset | status | errors | warnings | key issues |
|---|---:|---:|---:|---|
| `datasets/real/alarm` | pass | 0 | 0 |  |
| `datasets/real/child` | pass | 0 | 0 |  |
| `datasets/real/ihdp` | warning | 0 | 1 | warning:LEGACY_DATA_CONTAINS_TRUTH |
| `datasets/real/insurance` | pass | 0 | 0 |  |
| `datasets/real/jobs` | warning | 0 | 1 | warning:LEGACY_DATA_CONTAINS_TRUTH |
| `datasets/real/sachs` | pass | 0 | 0 |  |
| `datasets/real/twins` | warning | 0 | 3 | warning:CONSTANT_COLUMNS; warning:DEGENERATE_TREATMENT_NEGATIVE_CONTROL; warning:DEGENERATE_OUTCOME_NEGATIVE_CONTROL |
| `datasets/synthetic/edge_cases/high_collinearity` | pass | 0 | 0 |  |
| `datasets/synthetic/edge_cases/latent_confounder` | pass | 0 | 0 |  |
| `datasets/synthetic/edge_cases/m_graph` | pass | 0 | 0 |  |
| `datasets/synthetic/inference/ihdp_large` | warning | 0 | 1 | warning:LEGACY_DATA_CONTAINS_TRUTH |
| `datasets/synthetic/inference/ihdp_medium` | warning | 0 | 1 | warning:LEGACY_DATA_CONTAINS_TRUTH |
| `datasets/synthetic/inference/ihdp_small` | warning | 0 | 1 | warning:LEGACY_DATA_CONTAINS_TRUTH |
| `datasets/synthetic/inference/lalonde_medium` | warning | 0 | 1 | warning:LEGACY_DATA_CONTAINS_TRUTH |
| `datasets/synthetic/inference/lalonde_small` | warning | 0 | 1 | warning:LEGACY_DATA_CONTAINS_TRUTH |
| `datasets/synthetic/inference/twins_medium` | warning | 0 | 3 | warning:CONSTANT_COLUMNS; warning:DEGENERATE_TREATMENT_NEGATIVE_CONTROL; warning:DEGENERATE_OUTCOME_NEGATIVE_CONTROL |
| `datasets/synthetic/inference/twins_small` | warning | 0 | 3 | warning:CONSTANT_COLUMNS; warning:DEGENERATE_TREATMENT_NEGATIVE_CONTROL; warning:DEGENERATE_OUTCOME_NEGATIVE_CONTROL |
| `datasets/synthetic/linear_gaussian/100_vars_150_edges` | pass | 0 | 0 |  |
| `datasets/synthetic/linear_gaussian/10_vars_10_edges` | pass | 0 | 0 |  |
| `datasets/synthetic/linear_gaussian/10_vars_20_edges` | pass | 0 | 0 |  |
| `datasets/synthetic/linear_gaussian/20_vars_20_edges` | pass | 0 | 0 |  |
| `datasets/synthetic/linear_gaussian/20_vars_40_edges` | pass | 0 | 0 |  |
| `datasets/synthetic/linear_gaussian/20_vars_sf` | pass | 0 | 0 |  |
| `datasets/synthetic/linear_gaussian/50_vars_100_edges` | pass | 0 | 0 |  |
| `datasets/synthetic/linear_gaussian/50_vars_50_edges` | pass | 0 | 0 |  |
| `datasets/synthetic/linear_gaussian/50_vars_sf` | pass | 0 | 0 |  |
| `datasets/synthetic/non_gaussian/10_vars_gumbel` | pass | 0 | 0 |  |
| `datasets/synthetic/non_gaussian/10_vars_laplace` | pass | 0 | 0 |  |
| `datasets/synthetic/non_gaussian/10_vars_mixed_ng` | pass | 0 | 0 |  |
| `datasets/synthetic/non_gaussian/10_vars_uniform` | pass | 0 | 0 |  |
| `datasets/synthetic/non_gaussian/20_vars_exponential` | pass | 0 | 0 |  |
| `datasets/synthetic/non_gaussian/20_vars_laplace` | pass | 0 | 0 |  |
| `datasets/synthetic/nonlinear/10_vars_gp` | pass | 0 | 0 |  |
| `datasets/synthetic/nonlinear/10_vars_heteroscedastic` | pass | 0 | 0 |  |
| `datasets/synthetic/nonlinear/10_vars_mlp` | pass | 0 | 0 |  |
| `datasets/synthetic/nonlinear/10_vars_polynomial` | pass | 0 | 0 |  |
| `datasets/synthetic/nonlinear/20_vars_mlp` | pass | 0 | 0 |  |
| `datasets/synthetic/nonlinear/20_vars_polynomial` | pass | 0 | 0 |  |
| `datasets/synthetic/timeseries/10_vars_2_lags` | pass | 0 | 0 |  |
| `datasets/synthetic/timeseries/10_vars_3_lags` | pass | 0 | 0 |  |
| `datasets/synthetic/timeseries/5_vars_2_lags` | pass | 0 | 0 |  |
| `datasets/synthetic/timeseries/5_vars_3_lags` | pass | 0 | 0 |  |
| `datasets/synthetic/timeseries/5_vars_nonlinear_ts` | pass | 0 | 0 |  |
