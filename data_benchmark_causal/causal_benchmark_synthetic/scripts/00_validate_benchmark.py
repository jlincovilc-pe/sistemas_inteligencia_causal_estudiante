#!/usr/bin/env python3
"""Validate Causal Scout benchmark datasets.

This script is read-only with respect to datasets. It writes validation reports under results/validation.
"""
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path
from typing import Any

import numpy as np
import pandas as pd

try:
    import networkx as nx
except Exception:  # pragma: no cover
    nx = None

TRUTH_COLS = {"y0", "y1", "tau", "ite", "cate"}
TREATMENT_NAMES = ["treatment", "T", "trt", "treat", "A"]
OUTCOME_NAMES = ["outcome", "Y", "y", "re78", "mortality", "earnings"]


def load_json(path: Path) -> dict[str, Any]:
    if not path.exists():
        return {}
    try:
        return json.loads(path.read_text())
    except Exception as exc:
        return {"_json_error": str(exc)}


def dataset_dirs(root: Path) -> list[Path]:
    ds_root = root / "datasets"
    candidates = []
    for d in sorted(ds_root.rglob("*")):
        if not d.is_dir():
            continue
        names = {p.name for p in d.iterdir() if p.is_file()}
        if names & {"data.csv", "data_public.csv", "observed.csv", "observed_train.csv", "data_observed.csv"} or "metadata.json" in names or "graph_adjmatrix.csv" in names:
            candidates.append(d)
    return candidates


def first_existing(d: Path, names: list[str]) -> Path | None:
    for name in names:
        p = d / name
        if p.exists():
            return p
    return None


def infer_col(columns: list[str], names: list[str]) -> str | None:
    for name in names:
        if name in columns:
            return name
    return None


def add(issue_list: list[dict[str, str]], severity: str, code: str, message: str) -> None:
    issue_list.append({"severity": severity, "code": code, "message": message})


def validate_graph(d: Path, df: pd.DataFrame | None, issues: list[dict[str, str]]) -> dict[str, Any]:
    out: dict[str, Any] = {}
    adj_path = d / "graph_adjmatrix.csv"
    if not adj_path.exists():
        return out
    out["has_graph_adjmatrix"] = True
    try:
        adj = pd.read_csv(adj_path, index_col=0)
        vals = adj.apply(pd.to_numeric, errors="coerce").fillna(0).to_numpy()
        out["graph_nodes"] = int(vals.shape[0])
        out["graph_edges"] = int((vals != 0).sum())
        if nx is not None:
            G = nx.from_numpy_array((vals != 0).astype(int), create_using=nx.DiGraph)
            out["graph_is_dag"] = bool(nx.is_directed_acyclic_graph(G))
            if not out["graph_is_dag"]:
                add(issues, "error", "GRAPH_CYCLE", "graph_adjmatrix.csv is not acyclic")
        if df is not None:
            graph_names = set(map(str, adj.index))
            data_names = set(map(str, df.columns))
            out["graph_columns_match_data"] = bool(graph_names == data_names)
            if graph_names != data_names and not (d / "variable_mapping.csv").exists():
                add(issues, "warning", "GRAPH_COLUMN_MISMATCH", "Graph node names differ from data columns and variable_mapping.csv is absent")
    except Exception as exc:
        add(issues, "error", "GRAPH_READ_ERROR", f"Could not read graph_adjmatrix.csv: {exc}")
    return out


def validate_one(d: Path, root: Path) -> dict[str, Any]:
    rel = d.relative_to(root).as_posix()
    issues: list[dict[str, str]] = []
    meta = load_json(d / "metadata.json")
    rec: dict[str, Any] = {"dataset": rel, "metadata_keys": sorted(meta.keys())}

    if not (d / "metadata.json").exists():
        add(issues, "warning", "MISSING_METADATA", "metadata.json is absent")
    if meta.get("_json_error"):
        add(issues, "error", "METADATA_JSON_ERROR", meta["_json_error"])
    if "schema_version" not in meta:
        add(issues, "warning", "MISSING_SCHEMA_VERSION", "metadata.json lacks schema_version")
    if "scenario_id" not in meta:
        add(issues, "warning", "MISSING_SCENARIO_ID", "metadata.json lacks scenario_id")

    observable_path = first_existing(d, ["observed_train.csv", "observed.csv", "data_public.csv", "data.csv", "data_observed.csv"])
    full_data_path = first_existing(d, ["data.csv", "data_full.csv"])
    rec["observable_file"] = observable_path.name if observable_path else None
    rec["full_data_file"] = full_data_path.name if full_data_path else None

    df = None
    full_df = None
    if observable_path is None:
        add(issues, "error", "NO_OBSERVABLE_DATA", "No observable data file found")
    else:
        try:
            df = pd.read_csv(observable_path)
            rec["n_rows"] = int(df.shape[0])
            rec["n_cols"] = int(df.shape[1])
            rec["missing_cells"] = int(df.isna().sum().sum())
            rec["duplicate_rows"] = int(df.duplicated().sum())
            constants = [c for c in df.columns if df[c].nunique(dropna=False) <= 1]
            rec["constant_cols"] = constants
            if rec["missing_cells"] > 0:
                add(issues, "warning", "MISSING_VALUES", f"Observable data has {rec['missing_cells']} missing cells")
            if rec["duplicate_rows"] > 0:
                add(issues, "warning", "DUPLICATE_ROWS", f"Observable data has {rec['duplicate_rows']} exact duplicate rows")
            if constants:
                add(issues, "warning", "CONSTANT_COLUMNS", f"Constant columns: {constants}")
            leaked_truth = sorted(TRUTH_COLS & set(df.columns))
            rec["truth_cols_in_observable"] = leaked_truth
            if leaked_truth:
                add(issues, "warning", "TRUTH_IN_OBSERVABLE", f"Observable file contains ground-truth columns: {leaked_truth}")
        except Exception as exc:
            add(issues, "error", "DATA_READ_ERROR", f"Could not read {observable_path.name}: {exc}")

    if full_data_path is not None:
        try:
            full_df = pd.read_csv(full_data_path)
        except Exception:
            full_df = None

    check_df = full_df if full_df is not None else df
    if check_df is not None:
        cols = list(check_df.columns)
        meta_treatments = meta.get("treatments") or ([meta.get("treatment_var")] if meta.get("treatment_var") else [])
        meta_outcomes = meta.get("outcomes") or ([meta.get("outcome_var")] if meta.get("outcome_var") else [])
        tcol = infer_col(cols, list(meta_treatments) + TREATMENT_NAMES)
        ycol = infer_col(cols, list(meta_outcomes) + OUTCOME_NAMES)
        rec["treatment_col"] = tcol
        rec["outcome_col"] = ycol
        is_inference_like = tcol is not None or ycol is not None or bool({"ate_true", "att_true", "true_ate"} & set(meta.keys()))
        rec["is_inference_like"] = bool(is_inference_like)
        non_estimable_control = (meta.get("estimable_from_observed") is False) or ("negative_control" in meta.get("task_types", [])) or ("negative_control_non_estimable" in meta.get("task_types", []))
        rec["non_estimable_control"] = bool(non_estimable_control)
        if is_inference_like:
            if tcol is None:
                add(issues, "error", "NO_TREATMENT_COL", "Inference-like dataset lacks a recognized treatment column")
            else:
                nunique_t = int(check_df[tcol].nunique(dropna=False))
                rec["treatment_unique"] = nunique_t
                if pd.api.types.is_numeric_dtype(check_df[tcol]):
                    rec["treatment_mean"] = float(check_df[tcol].mean())
                if nunique_t <= 1:
                    if non_estimable_control:
                        add(issues, "warning", "DEGENERATE_TREATMENT_NEGATIVE_CONTROL", f"Treatment column {tcol} has one unique value; dataset marked non-estimable")
                    else:
                        add(issues, "error", "DEGENERATE_TREATMENT", f"Treatment column {tcol} has one unique value")
            if ycol is None:
                add(issues, "error", "NO_OUTCOME_COL", "Inference-like dataset lacks a recognized outcome column")
            else:
                nunique_y = int(check_df[ycol].nunique(dropna=False))
                rec["outcome_unique"] = nunique_y
                if nunique_y <= 1:
                    if non_estimable_control:
                        add(issues, "warning", "DEGENERATE_OUTCOME_NEGATIVE_CONTROL", f"Outcome column {ycol} has one unique value; dataset marked non-estimable")
                    else:
                        add(issues, "error", "DEGENERATE_OUTCOME", f"Outcome column {ycol} has one unique value")
            if tcol and ycol and {"y0", "y1"}.issubset(check_df.columns):
                obs = np.where(check_df[tcol].to_numpy() == 1, check_df["y1"].to_numpy(), check_df["y0"].to_numpy())
                err = np.nanmax(np.abs(check_df[ycol].to_numpy() - obs)) if len(check_df) else 0.0
                rec["potential_outcome_consistency_max_abs_error"] = float(err)
                if err > 1e-8:
                    add(issues, "error", "POTENTIAL_OUTCOME_INCONSISTENCY", f"Observed outcome inconsistent with y0/y1, max abs error={err}")
            if full_data_path is not None and full_df is not None and sorted(TRUTH_COLS & set(full_df.columns)) and full_data_path.name == "data.csv":
                add(issues, "warning", "LEGACY_DATA_CONTAINS_TRUTH", "data.csv contains ground truth; split observed/truth files are recommended")

    rec.update(validate_graph(d, df, issues))

    for fname in ["scm.json", "interventions.json", "identification.json"]:
        if not (d / fname).exists():
            add(issues, "warning", f"MISSING_{fname.upper().replace('.', '_')}", f"{fname} is absent")
    has_split = any((d / f"observed_{split}.csv").exists() for split in ["train", "validation", "test"])
    rec["has_official_observed_splits"] = bool(has_split)
    if not has_split:
        add(issues, "warning", "MISSING_OFFICIAL_SPLITS", "No observed_train/validation/test split files found")

    max_sev = max(({"error": 2, "warning": 1}.get(x["severity"], 0) for x in issues), default=0)
    rec["status"] = "error" if max_sev == 2 else ("warning" if max_sev == 1 else "pass")
    rec["issues"] = issues
    rec["n_errors"] = sum(1 for x in issues if x["severity"] == "error")
    rec["n_warnings"] = sum(1 for x in issues if x["severity"] == "warning")
    return rec



def validate_scorecard(d: Path, issues: list[dict[str, str]]) -> dict[str, Any]:
    out: dict[str, Any] = {}
    p = d / "scorecard.json"
    if not p.exists():
        add(issues, "warning", "MISSING_SCORECARD", "scorecard.json is absent")
        out["has_scorecard"] = False
        return out
    out["has_scorecard"] = True
    try:
        sc = json.loads(p.read_text())
    except Exception as exc:
        add(issues, "error", "SCORECARD_JSON_ERROR", f"Could not read scorecard.json: {exc}")
        return out
    out["scorecard_task_type"] = sc.get("task_type")
    br = sc.get("baseline_results")
    if br is None:
        add(issues, "error", "SCORECARD_MISSING_BASELINES", "scorecard.json lacks baseline_results")
    else:
        out["scorecard_n_baselines"] = len(br)
        if len(br) == 0 and sc.get("task_type") != "no_scored_target":
            add(issues, "warning", "SCORECARD_EMPTY_BASELINES", "No baselines for a scored target")
    return out


def write_markdown(records: list[dict[str, Any]], out_path: Path) -> None:
    total = len(records)
    errors = sum(1 for r in records if r["status"] == "error")
    warnings = sum(1 for r in records if r["status"] == "warning")
    passes = sum(1 for r in records if r["status"] == "pass")
    lines = [
        "# Validation report", "",
        f"Datasets checked: {total}",
        f"Status counts: pass={passes}, warning={warnings}, error={errors}", "",
        "| dataset | status | errors | warnings | key issues |",
        "|---|---:|---:|---:|---|",
    ]
    for r in records:
        key = "; ".join(f"{i['severity']}:{i['code']}" for i in r["issues"][:6])
        if len(r["issues"]) > 6:
            key += f"; ... +{len(r['issues'])-6} more"
        lines.append(f"| `{r['dataset']}` | {r['status']} | {r['n_errors']} | {r['n_warnings']} | {key} |")
    out_path.write_text("\n".join(lines) + "\n")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--root", default=".", help="Benchmark repository root")
    parser.add_argument("--output", default="results/validation", help="Output directory relative to root unless absolute")
    args = parser.parse_args()
    root = Path(args.root).resolve()
    outdir = Path(args.output)
    if not outdir.is_absolute():
        outdir = root / outdir
    outdir.mkdir(parents=True, exist_ok=True)
    records = [validate_one(d, root) for d in dataset_dirs(root)]
    records = sorted(records, key=lambda r: r["dataset"])
    summary = {
        "root": str(root),
        "n_datasets": len(records),
        "status_counts": {s: sum(1 for r in records if r["status"] == s) for s in ["pass", "warning", "error"]},
        "total_errors": sum(r["n_errors"] for r in records),
        "total_warnings": sum(r["n_warnings"] for r in records),
        "records": records,
    }
    (outdir / "validation_report.json").write_text(json.dumps(summary, indent=2, default=str))
    write_markdown(records, outdir / "validation_report.md")
    print(json.dumps({k: summary[k] for k in ["n_datasets", "status_counts", "total_errors", "total_warnings"]}, indent=2))
    if summary["total_errors"] > 0:
        sys.exit(1)


if __name__ == "__main__":
    main()
