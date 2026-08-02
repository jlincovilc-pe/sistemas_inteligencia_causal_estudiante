# Scorecard: datasets/synthetic/timeseries/5_vars_nonlinear_ts

Task type: `time_series_link_recovery`

## Baselines

### timeseries_empty_links

```json
{
  "true_links": 8,
  "estimated_links": 0,
  "precision": 0.0,
  "recall": 0.0,
  "f1": 0.0
}
```

### timeseries_lagged_corr_threshold_0.20

```json
{
  "true_links": 8,
  "estimated_links": 12,
  "precision": 0.5,
  "recall": 0.75,
  "f1": 0.6
}
```

