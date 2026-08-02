# Scorecard: datasets/synthetic/inference/ihdp_medium

Task type: `inference_effect_estimation`

## Baselines

### inference_naive_test_difference

```json
{
  "ate_estimate": 7.458652594268941,
  "absolute_error": 3.5207565362766626,
  "bias": 3.5207565362766626,
  "relative_error": 0.8940704590541446
}
```

### inference_ols_adjusted

```json
{
  "ate_estimate": 3.5840673008600503,
  "absolute_error": 0.3538287571322276,
  "bias": -0.3538287571322276,
  "relative_error": 0.08985223376175804
}
```

### inference_ipw_clipped_0.02_0.98

```json
{
  "ate_estimate": 5.0887926344666745,
  "absolute_error": 1.1508965764743966,
  "bias": 1.1508965764743966,
  "relative_error": 0.2922617965343598
}
```

### propensity_test_summary

```json
{
  "min": 0.1271646245070258,
  "median": 0.37208623171995914,
  "max": 0.6705326804818393
}
```

### inference_t_learner_random_forest

```json
{
  "ate_estimate": 3.7566938042817766,
  "absolute_error": 0.18120225371050136,
  "bias": -0.18120225371050136,
  "relative_error": 0.046014991518817966,
  "pehe": 3.403012167425046,
  "mae_tau": 2.672088806469468
}
```

