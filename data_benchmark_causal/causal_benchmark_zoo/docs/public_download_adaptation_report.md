# Public download adaptation report

The repository was adapted so the default strategy no longer requires physical files from the user.

## Automated public downloads now active

- `bnlearn_asia`: public bnlearn BIF URL, graph artifacts already processed.
- `bnlearn_alarm`: public bnlearn BIF URL, graph artifacts already processed.
- `lalonde_nsw`: public NBER/Dehejia-Wahba URLs, tabular data processed, expert DAG created, reference estimate computed.

## Remaining manual source

- `csuite_lingauss`: the public GitHub Releases URL returned HTTP 403 in this platform, so it remains manual. No mirror or substitute file was used.

## Lalonde processed result

- rows: 445
- columns: 10
- treated: 185
- controls: 260
- ATE estimate, 1978 earnings difference: 1794.34
- standard error: 671.00
- 95% CI: [474.01, 3114.67]
- Welch t-test p-value: 0.007893

This is an experimental reference estimate with sampling uncertainty, not an exact mathematical constant.
