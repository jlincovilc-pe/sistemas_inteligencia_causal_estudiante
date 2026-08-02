# Scorecard: datasets/synthetic/inference/lalonde_small

Task type: `inference_effect_estimation`

## Baselines

### inference_naive_test_difference

```json
{
  "ate_estimate": -363.93557758836687,
  "absolute_error": 1972.8510564417004,
  "bias": -1972.8510564417004,
  "relative_error": 1.2261993139923932
}
```

### inference_ols_adjusted

```json
{
  "ate_estimate": 1183.5086153232894,
  "absolute_error": 425.4068635300441,
  "bias": -425.4068635300441,
  "relative_error": 0.2644059735401574
}
```

### inference_ipw_clipped_0.02_0.98

```json
{
  "ate_estimate": 529.9166347846004,
  "absolute_error": 1078.998844068733,
  "bias": -1078.998844068733,
  "relative_error": 0.6706373692406331
}
```

### propensity_test_summary

```json
{
  "min": 0.13022247969490838,
  "median": 0.2632125482668014,
  "max": 0.44159546796792126
}
```

### inference_t_learner_random_forest

```json
{
  "ate_estimate": 847.2903840243158,
  "absolute_error": 761.6250948290177,
  "bias": -761.6250948290177,
  "relative_error": 0.4733779398852103,
  "pehe": 2197.385413543741,
  "mae_tau": 1743.7021933229553
}
```

