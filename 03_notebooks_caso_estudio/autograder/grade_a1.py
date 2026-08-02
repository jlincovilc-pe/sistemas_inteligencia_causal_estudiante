#!/usr/bin/env python3
"""Autograder for Notebook A1 (Jobs / identificación).

Pure script (no Jupyter kernel state). Uses ground truth and
``expected_ranges.yaml`` only on the grader side.

Checks
------
1. Reference OLS / PDS ATE absolute error vs ``ate_true`` within tolerance.
2. Propensity scores strictly interior for ≥ 95% of train units.
3. Optional notebook audit: no truth columns in estimation cells;
   identification markdown not empty (length heuristic).

Usage
-----
From package root or monorepo root::

    python autograder/grade_a1.py
    python autograder/grade_a1.py --notebook notebooks/A1_identificacion_jobs.ipynb
    python autograder/grade_a1.py --json-out /tmp/a1_grade.json

Exit code 0 if all hard checks pass; 1 otherwise.
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path
from typing import Any, Dict, List, Optional, Tuple

import numpy as np
import yaml

# ---------------------------------------------------------------------------
# sys.path: allow running from monorepo root or 03_notebooks_caso_estudio/
# ---------------------------------------------------------------------------
_THIS = Path(__file__).resolve()
_PKG = _THIS.parent.parent
if str(_PKG) not in sys.path:
    sys.path.insert(0, str(_PKG))

from lib.data_io import assert_no_truth_columns, load_scenario, load_truth  # noqa: E402
from lib.identification import (  # noqa: E402
    fit_propensity,
    ols_ate,
    overlap_diagnostics,
    post_double_selection_ate,
)
from lib.metrics import ate_absolute_error, ate_from_tau  # noqa: E402
from lib.paths import RANDOM_STATE, SCENARIO_A1, package_root  # noqa: E402

try:
    from sklearn.preprocessing import PolynomialFeatures
except ImportError:  # pragma: no cover
    PolynomialFeatures = None  # type: ignore


TRUTH_PATTERNS = (
    r"\by0\b",
    r"\by1\b",
    r"\btau\b",
    r"load_truth\s*\(",
    r"truth_train",
    r"truth_test",
    r"truth_validation",
    r"truth\.csv",
)
EVAL_SECTION_MARKERS = (
    "EVALUACIÓN CON GROUND TRUTH",
    "EVALUACION CON GROUND TRUTH",
    "evaluación con ground truth",
    "evaluacion con ground truth",
    "SECCIÓN DE EVALUACIÓN",
    "SECCION DE EVALUACION",
    "load_truth",  # first load_truth cell starts eval region if marked above failed
)


def _load_ranges() -> Dict[str, Any]:
    path = package_root() / "autograder" / "expected_ranges.yaml"
    if not path.is_file():
        # Fallback defaults from plan
        return {
            "scenario": "real/jobs",
            "ate_true": 1600.26,
            "max_abs_error_ols": 250.0,
            "max_abs_error_pds": 250.0,
            "min_propensity": 0.01,
            "max_propensity": 0.99,
        }
    with path.open("r", encoding="utf-8") as f:
        raw = yaml.safe_load(f)
    return dict(raw.get("a1_jobs", raw))


def expand_jobs_features(X, continuous=None, degree: int = 2):
    """Mirror notebook expansion for PDS (polynomial on age/educ/re74/re75)."""
    import pandas as pd

    if PolynomialFeatures is None or not isinstance(X, pd.DataFrame):
        return X
    cont = continuous or [c for c in ("age", "educ", "re74", "re75") if c in X.columns]
    other = [c for c in X.columns if c not in cont]
    parts = []
    if cont:
        poly = PolynomialFeatures(degree=degree, include_bias=False)
        Xp = poly.fit_transform(X[cont].to_numpy(dtype=float))
        names = poly.get_feature_names_out(cont)
        parts.append(pd.DataFrame(Xp, columns=names, index=X.index))
    if other:
        parts.append(X[other].copy())
    if not parts:
        return X.copy()
    out = pd.concat(parts, axis=1)
    return out.loc[:, ~out.columns.duplicated()]


def run_estimation_checks(ranges: Dict[str, Any]) -> Tuple[List[Dict], bool]:
    """Run OLS/PDS/propensity against scenario data; return (results, ok)."""
    scenario = ranges.get("scenario", SCENARIO_A1)
    ate_true = float(ranges.get("ate_true", 1600.26))
    max_ae_ols = float(ranges.get("max_abs_error_ols", 250.0))
    max_ae_pds = float(ranges.get("max_abs_error_pds", 250.0))
    min_p = float(ranges.get("min_propensity", 0.01))
    max_p = float(ranges.get("max_propensity", 0.99))

    results: List[Dict[str, Any]] = []
    ok = True

    bundle = load_scenario(scenario)
    assert_no_truth_columns(bundle.train, context="grade_a1 train")
    assert_no_truth_columns(bundle.test, context="grade_a1 test")

    # Prefer train (matches scorecard OLS); also evaluate test
    for split in ("train", "test"):
        Y, T, X = bundle.ytx(split)
        dim = float(np.mean(Y[T == 1]) - np.mean(Y[T == 0]))
        ols = ols_ate(Y, T, X)
        X_exp = expand_jobs_features(X)
        pds = post_double_selection_ate(Y, T, X_exp, random_state=RANDOM_STATE)
        pds_ate = float(pds["ate"])

        for name, hat, thr in (
            (f"ols_{split}", ols, max_ae_ols),
            (f"pds_{split}", pds_ate, max_ae_pds),
        ):
            ae = ate_absolute_error(hat, ate_true)
            passed = ae < thr
            results.append(
                {
                    "check": f"ate_ae_{name}",
                    "passed": passed,
                    "ate_hat": hat,
                    "ate_true": ate_true,
                    "abs_error": ae,
                    "threshold": thr,
                    "detail": f"|{hat:.4f} - {ate_true:.4f}| = {ae:.4f} (max {thr})",
                }
            )
            # Hard fail only if *both* train and test fail for same estimator family
            # We mark individual results; aggregate below.
            if not passed and split == "train":
                # train is primary; soft-fail test alone
                ok = ok and passed if name.startswith("ols") or name.startswith("pds") else ok

        results.append(
            {
                "check": f"dim_{split}",
                "passed": True,  # informational
                "ate_hat": dim,
                "ate_true": ate_true,
                "abs_error": ate_absolute_error(dim, ate_true),
                "threshold": None,
                "detail": f"diff-in-means {split}={dim:.4f} (informational)",
            }
        )

    # Aggregate: pass if train OLS and train PDS within tolerance
    train_ols = next(r for r in results if r["check"] == "ate_ae_ols_train")
    train_pds = next(r for r in results if r["check"] == "ate_ae_pds_train")
    ok_est = bool(train_ols["passed"] and train_pds["passed"])
    if not ok_est:
        ok = False

    # Propensity on train
    Y, T, X = bundle.ytx("train")
    _, e = fit_propensity(X, T, random_state=RANDOM_STATE)
    ov = overlap_diagnostics(e, T, trim_low=min_p, trim_high=max_p)
    frac_int = float(ov["frac_strictly_interior"])
    prop_ok = frac_int >= 0.95
    results.append(
        {
            "check": "propensity_interior_ge_95pct",
            "passed": prop_ok,
            "value": frac_int,
            "threshold": 0.95,
            "detail": (
                f"frac 0<e<1 = {frac_int:.4f}; "
                f"min={ov['min']:.4f} max={ov['max']:.4f}"
            ),
        }
    )
    if not prop_ok:
        ok = False

    # Truth consistency (grader-only sanity)
    truth_test = load_truth(scenario, "test")
    tau_mean = ate_from_tau(truth_test["tau"])
    results.append(
        {
            "check": "truth_tau_mean_test",
            "passed": abs(tau_mean - ate_true) < 500.0,  # loose sanity
            "value": tau_mean,
            "ate_true": ate_true,
            "detail": f"mean(tau_test)={tau_mean:.4f} vs ate_true={ate_true:.4f}",
        }
    )

    results.append(
        {
            "check": "estimation_train_primary",
            "passed": ok_est,
            "detail": "train OLS and PDS absolute errors within YAML thresholds",
        }
    )
    return results, ok and ok_est and prop_ok


def _cell_source(cell: dict) -> str:
    src = cell.get("source", "")
    if isinstance(src, list):
        return "".join(src)
    return str(src)


def audit_notebook(nb_path: Path) -> Tuple[List[Dict], bool]:
    """Static checks on the student notebook (optional path)."""
    results: List[Dict[str, Any]] = []
    if not nb_path.is_file():
        results.append(
            {
                "check": "notebook_exists",
                "passed": False,
                "detail": f"Notebook not found: {nb_path}",
            }
        )
        return results, False

    with nb_path.open("r", encoding="utf-8") as f:
        nb = json.load(f)

    cells = nb.get("cells", [])
    results.append(
        {
            "check": "notebook_exists",
            "passed": True,
            "detail": f"{nb_path.name}: {len(cells)} cells",
        }
    )

    # Split cells into pre-eval vs eval using markdown markers
    in_eval = False
    est_code: List[str] = []
    eval_code: List[str] = []
    id_markdown: List[str] = []
    all_md = []

    for cell in cells:
        text = _cell_source(cell)
        ctype = cell.get("cell_type")
        if ctype == "markdown":
            all_md.append(text)
            upper = text.upper()
            if any(m.upper() in upper for m in EVAL_SECTION_MARKERS if m != "load_truth"):
                in_eval = True
            # Identification / justification heuristics
            low = text.lower()
            if any(
                k in low
                for k in (
                    "identific",
                    "estimando",
                    "supuesto",
                    "dag",
                    "justific",
                    "validez externa",
                    "ignorabilidad",
                    "overlap",
                    "pregunta causal",
                )
            ):
                id_markdown.append(text)
        elif ctype == "code":
            if in_eval:
                eval_code.append(text)
            else:
                # If cell itself only loads truth and is short, still mark
                if re.search(r"load_truth\s*\(", text) and not in_eval:
                    # Allow only if comment marks evaluation — still flag if y0 used with fit
                    in_eval = True
                    eval_code.append(text)
                else:
                    est_code.append(text)

    # Truth leakage in estimation region
    leakage_hits: List[str] = []
    combined_est = "\n".join(est_code)
    for pat in TRUTH_PATTERNS:
        for m in re.finditer(pat, combined_est):
            # allow string mentions in comments about "do not use truth"?
            # Still flag load_truth and column usage
            snippet = combined_est[max(0, m.start() - 40) : m.end() + 40].replace("\n", " ")
            leakage_hits.append(f"{pat}: ...{snippet}...")

    leak_ok = len(leakage_hits) == 0
    results.append(
        {
            "check": "no_truth_in_estimation_cells",
            "passed": leak_ok,
            "n_hits": len(leakage_hits),
            "detail": "OK" if leak_ok else "; ".join(leakage_hits[:5]),
        }
    )

    # Markdown length heuristic for identification writing
    id_chars = sum(len(t) for t in id_markdown)
    # Plan: non-empty identification cells; require substantive text
    min_chars = 400
    text_ok = id_chars >= min_chars
    results.append(
        {
            "check": "identification_markdown_length",
            "passed": text_ok,
            "value": id_chars,
            "threshold": min_chars,
            "detail": f"identification-related markdown chars={id_chars} (min {min_chars})",
        }
    )

    # Must mention ATE / estimando somewhere
    blob = "\n".join(all_md).lower()
    has_ate = "ate" in blob or "efecto medio" in blob or "estimando" in blob
    results.append(
        {
            "check": "mentions_estimand",
            "passed": has_ate,
            "detail": "markdown mentions ATE/estimando/efecto medio"
            if has_ate
            else "missing estimand language in markdown",
        }
    )

    ok = leak_ok and text_ok and has_ate
    return results, ok


def grade(
    notebook: Optional[Path] = None,
    skip_notebook_audit: bool = False,
) -> Dict[str, Any]:
    ranges = _load_ranges()
    est_results, est_ok = run_estimation_checks(ranges)

    nb_results: List[Dict] = []
    nb_ok = True
    if not skip_notebook_audit:
        nb_path = notebook or (package_root() / "notebooks" / "A1_identificacion_jobs.ipynb")
        nb_results, nb_ok = audit_notebook(Path(nb_path))

    all_results = est_results + nb_results
    hard_ok = est_ok and (nb_ok if not skip_notebook_audit else True)

    # Soft: test-set AE failures don't fail if train passed (already handled)
    summary = {
        "notebook_id": "A1",
        "scenario": ranges.get("scenario", SCENARIO_A1),
        "scenario_id": ranges.get("scenario_id", "real_jobs"),
        "random_state": RANDOM_STATE,
        "passed": hard_ok,
        "n_checks": len(all_results),
        "n_passed": sum(1 for r in all_results if r.get("passed")),
        "checks": all_results,
    }
    return summary


def main(argv: Optional[List[str]] = None) -> int:
    parser = argparse.ArgumentParser(description="Grade Serie A notebook A1 (Jobs)")
    parser.add_argument(
        "--notebook",
        type=Path,
        default=None,
        help="Path to A1_identificacion_jobs.ipynb (default: package notebooks/)",
    )
    parser.add_argument(
        "--skip-notebook-audit",
        action="store_true",
        help="Only run estimation/propensity checks (no nbformat grep)",
    )
    parser.add_argument(
        "--json-out",
        type=Path,
        default=None,
        help="Optional path to write full JSON report",
    )
    parser.add_argument(
        "-q",
        "--quiet",
        action="store_true",
        help="Only print pass/fail line",
    )
    args = parser.parse_args(argv)

    report = grade(
        notebook=args.notebook,
        skip_notebook_audit=args.skip_notebook_audit,
    )

    if args.json_out:
        args.json_out.parent.mkdir(parents=True, exist_ok=True)
        with args.json_out.open("w", encoding="utf-8") as f:
            json.dump(report, f, indent=2)

    if not args.quiet:
        print("=" * 60)
        print("A1 Autograder — Identificación Jobs (real/jobs)")
        print("=" * 60)
        for r in report["checks"]:
            status = "PASS" if r.get("passed") else "FAIL"
            print(f"  [{status}] {r['check']}: {r.get('detail', '')}")
        print("-" * 60)
        print(
            f"Result: {'PASS' if report['passed'] else 'FAIL'} "
            f"({report['n_passed']}/{report['n_checks']} checks)"
        )

    return 0 if report["passed"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
