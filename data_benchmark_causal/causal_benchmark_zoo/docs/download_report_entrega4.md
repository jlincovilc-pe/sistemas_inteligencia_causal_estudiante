# Entrega 4 download report

This stage implemented and executed raw-data download scripts where automated access was possible.

## Results

| Benchmark | Raw artifact | Status | Bytes | SHA256 |
|---|---|---:|---:|---|
| bnlearn_asia | raw/asia.bif.gz | available | 310 | 7d5e7b8549834824c1b05f367eb7860fa3fca3adaf3649f0c7be6035af197197 |
| bnlearn_alarm | raw/alarm.bif.gz | available | 1832 | f5860caa7137b5817e0c4f169cce0f1451ce6c246b96f5ce4fb4a8167993be29 |
| csuite_lingauss | raw/csuite_lingauss.zip | manual | not downloaded | not available |
| lalonde_nsw | raw/README_manual_download.txt | manual | 425 | not applicable |

## Notes

- bnlearn Asia and Alarm were downloaded from the bnlearn Bayesian Network Repository and their SHA256 hashes were written into their manifests.
- CSuite automated download from the GitHub release URL failed in this platform with HTTP 403 / `integration_not_connected`; the manifest was changed to `manual` and the download script now writes manual placement instructions when this occurs.
- Lalonde remains manual/on-demand because redistribution rights and endpoint behavior must be verified before bundling original data.
- No synthetic, substitute, or fabricated data were created.
