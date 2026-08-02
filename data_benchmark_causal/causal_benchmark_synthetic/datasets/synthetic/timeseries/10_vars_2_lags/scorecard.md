# Scorecard: datasets/synthetic/timeseries/10_vars_2_lags

Task type: `time_series_link_recovery`

## Baselines

### timeseries_empty_links

```json
{
  "true_links": 128,
  "estimated_links": 0,
  "precision": 0.0,
  "recall": 0.0,
  "f1": 0.0
}
```

### timeseries_lagged_corr_threshold_0.20

```json
{
  "true_links": 128,
  "estimated_links": 200,
  "precision": 0.64,
  "recall": 1.0,
  "f1": 0.7804878048780487
}
```

