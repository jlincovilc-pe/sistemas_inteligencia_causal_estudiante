# Scorecard: datasets/synthetic/inference/lalonde_medium

Task type: `inference_effect_estimation`

## Baselines

### inference_naive_test_difference

```json
{
  "ate_estimate": 846.4586832276009,
  "absolute_error": 745.3721246166542,
  "bias": -745.3721246166542,
  "relative_error": 0.46824833452374137
}
```

### inference_ols_adjusted

```json
{
  "ate_estimate": 1413.3474764718746,
  "absolute_error": 178.48333137238046,
  "bias": -178.48333137238046,
  "relative_error": 0.11212456153810242
}
```

### inference_ipw_clipped_0.02_0.98

```json
{
  "ate_estimate": 724.9279608962134,
  "absolute_error": 866.9028469480417,
  "bias": -866.9028469480417,
  "relative_error": 0.5445948417860119
}
```

### propensity_test_summary

```json
{
  "min": 0.11343575937270653,
  "median": 0.254067927250927,
  "max": 0.49268072161675397
}
```

### inference_t_learner_random_forest

```json
{
  "ate_estimate": 1346.032126920971,
  "absolute_error": 245.7986809232841,
  "bias": -245.7986809232841,
  "relative_error": 0.154412566782872,
  "pehe": 1556.4458202778549,
  "mae_tau": 1246.0491083145287
}
```

