# Scorecard: datasets/synthetic/inference/ihdp_small

Task type: `inference_effect_estimation`

## Baselines

### inference_naive_test_difference

```json
{
  "ate_estimate": 9.747578086971906,
  "absolute_error": 5.6348995969827165,
  "bias": 5.6348995969827165,
  "relative_error": 1.3701288857611449
}
```

### inference_ols_adjusted

```json
{
  "ate_estimate": 3.8131903992737843,
  "absolute_error": 0.29948809071540516,
  "bias": -0.29948809071540516,
  "relative_error": 0.07282069129507675
}
```

### inference_ipw_clipped_0.02_0.98

```json
{
  "ate_estimate": 8.03359726528196,
  "absolute_error": 3.9209187752927708,
  "bias": 3.9209187752927708,
  "relative_error": 0.9533735216202318
}
```

### propensity_test_summary

```json
{
  "min": 0.11075422222890685,
  "median": 0.3627262992695768,
  "max": 0.7408351480151595
}
```

### inference_t_learner_random_forest

```json
{
  "ate_estimate": 4.680220527152038,
  "absolute_error": 0.5675420371628483,
  "bias": 0.5675420371628483,
  "relative_error": 0.13799815340399735,
  "pehe": 3.7348560516446683,
  "mae_tau": 3.0873302747215807
}
```

