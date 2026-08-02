# Scorecard: datasets/synthetic/timeseries/10_vars_3_lags

Task type: `time_series_link_recovery`

## Baselines

### timeseries_empty_links

```json
{
  "true_links": 156,
  "estimated_links": 0,
  "precision": 0.0,
  "recall": 0.0,
  "f1": 0.0
}
```

### timeseries_lagged_corr_threshold_0.20

```json
{
  "true_links": 156,
  "estimated_links": 242,
  "precision": 0.5454545454545454,
  "recall": 0.8461538461538461,
  "f1": 0.6633165829145727
}
```

