# Public download strategy

The repository no longer assumes that the user will provide physical data files for the default path. The default strategy is:

1. Prefer public, source-authoritative URLs declared in each manifest.
2. Download raw files into `benchmarks/<id>/raw/`.
3. Compute SHA256 and mark raw artifacts as `available` only after successful download.
4. Process raw files into `processed/`, `graphs/`, and `ground_truth/`.
5. Keep manual fallback only for sources that are blocked or require additional access.

## Current public-download status

| Benchmark | Public download status | Current state |
|---|---|---|
| `bnlearn_asia` | public bnlearn URL works | raw + graph available |
| `bnlearn_alarm` | public bnlearn URL works | raw + graph available |
| `lalonde_nsw` | public NBER URLs work | raw + processed table + expert DAG + reference estimate available |
| `csuite_lingauss` | GitHub Releases returned HTTP 403 in this platform | manual fallback |

## Lalonde public source

Source page:

- https://users.nber.org/~rdehejia/nswdata.html
- https://users.nber.org/~rdehejia/nswdata2.html

Downloaded files:

- https://www.nber.org/~rdehejia/data/nswre74_treated.txt
- https://www.nber.org/~rdehejia/data/nswre74_control.txt

The NBER/Dehejia-Wahba page states attributable non-commercial use (CC BY-NC) and asks users to cite Lalonde (1986), Dehejia and Wahba (1999), and Dehejia and Wahba (2002).

## CSuite public source issue

The declared public GitHub Releases URL for `csuite_lingauss` returned HTTP 403 with an `integration_not_connected` response in this platform. The repository keeps the manifest and fallback script, but does not include substituted files or mirrors.
