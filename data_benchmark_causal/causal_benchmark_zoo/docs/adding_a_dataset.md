# Adding a dataset

## Step 1: Create folders

```text
benchmarks/<benchmark_id>/
  manifest.yaml
  raw/
  processed/
  graphs/
  ground_truth/
  scripts/
    download.py
    process.py
```

## Step 2: Write `manifest.yaml`

The manifest must validate against `schemas/manifest.schema.json`. Start with artifact statuses as `pending`, `manual`, or `external`. Use `available` only after the file exists and has a SHA256 hash.

## Step 3: Write a downloader

The downloader must:

- download only from declared sources;
- save raw files under `raw/`;
- avoid modifying raw files;
- compute SHA256;
- update the manifest to `available` only after successful validation;
- write manual instructions if automated download is not permitted or fails.

## Step 4: Write a processor

The processor must:

- read only raw files or declared external sources;
- write outputs to `processed/`, `graphs/`, or `ground_truth/`;
- update the manifest after outputs are successfully created;
- add tests for expected shape/counts/schema.

## Step 5: Add tests

Minimum tests:

- manifest validates;
- loader behavior is clear;
- expected files exist when marked `available`;
- hashes match;
- graph is acyclic for DAG benchmarks;
- treatment/outcome columns exist for ATE/CATE benchmarks.
