# Scorecard: datasets/real/jobs

Task type: `inference_effect_estimation`

## Baselines

### inference_naive_test_difference

```json
{
  "ate_estimate": 1610.1863370731726,
  "absolute_error": 27.94452319024299,
  "bias": 27.94452319024299,
  "relative_error": 0.017661347933705038
}
```

### inference_ols_adjusted

```json
{
  "ate_estimate": 1596.0422143776746,
  "absolute_error": 13.800400494744963,
  "bias": 13.800400494744963,
  "relative_error": 0.008722055234324668
}
```

### inference_ipw_clipped_0.02_0.98

```json
{
  "ate_estimate": 1689.6210983483327,
  "absolute_error": 107.37928446540309,
  "bias": 107.37928446540309,
  "relative_error": 0.0678652804667619
}
```

### propensity_test_summary

```json
{
  "min": 0.10280398606370628,
  "median": 0.24737403469638014,
  "max": 0.5306781438897429
}
```

### inference_t_learner_random_forest

```json
{
  "ate_estimate": 1470.6706188006644,
  "absolute_error": 111.57119508226515,
  "bias": -111.57119508226515,
  "relative_error": 0.07051462937163935,
  "pehe": 1759.439813880105,
  "mae_tau": 1371.7359053848322
}
```

