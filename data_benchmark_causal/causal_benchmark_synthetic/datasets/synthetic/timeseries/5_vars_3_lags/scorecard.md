# Scorecard: datasets/synthetic/timeseries/5_vars_3_lags

Task type: `time_series_link_recovery`

## Baselines

### timeseries_empty_links

```json
{
  "true_links": 41,
  "estimated_links": 0,
  "precision": 0.0,
  "recall": 0.0,
  "f1": 0.0
}
```

### timeseries_lagged_corr_threshold_0.20

```json
{
  "true_links": 41,
  "estimated_links": 25,
  "precision": 0.8,
  "recall": 0.4878048780487805,
  "f1": 0.6060606060606061
}
```

