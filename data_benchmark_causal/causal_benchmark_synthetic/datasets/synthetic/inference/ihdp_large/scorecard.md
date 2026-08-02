# Scorecard: datasets/synthetic/inference/ihdp_large

Task type: `inference_effect_estimation`

## Baselines

### inference_naive_test_difference

```json
{
  "ate_estimate": 8.634160392329335,
  "absolute_error": 4.706138431521411,
  "bias": 4.706138431521411,
  "relative_error": 1.1980937170100348
}
```

### inference_ols_adjusted

```json
{
  "ate_estimate": 4.023498590041434,
  "absolute_error": 0.0954766292335103,
  "bias": 0.0954766292335103,
  "relative_error": 0.02430654160952615
}
```

### inference_ipw_clipped_0.02_0.98

```json
{
  "ate_estimate": 6.05635225865878,
  "absolute_error": 2.128330297850856,
  "bias": 2.128330297850856,
  "relative_error": 0.5418325862447817
}
```

### propensity_test_summary

```json
{
  "min": 0.11177041667112464,
  "median": 0.38643856985142205,
  "max": 0.7451152450181577
}
```

### inference_t_learner_random_forest

```json
{
  "ate_estimate": 4.036982206983033,
  "absolute_error": 0.10896024617510847,
  "bias": 0.10896024617510847,
  "relative_error": 0.027739215122080756,
  "pehe": 3.584254480294571,
  "mae_tau": 2.8540986372590424
}
```

