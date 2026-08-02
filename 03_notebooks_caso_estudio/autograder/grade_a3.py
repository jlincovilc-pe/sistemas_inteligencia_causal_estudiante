#!/usr/bin/env python3
"""Autograder for Notebook A3 (CATE meta-learners on real/ihdp).

Pure script (no Jupyter kernel state). Uses ground truth and
``expected_ranges.yaml`` only on the grader side.

Checks
------
1. Placebo: |ATE after permuted treatment| below threshold.
2. PEHE of T-learner on test within scorecard-order ceiling.
3. Artifacts under ``artifacts/A3/`` (scores CSV + optional plots).
4. Optional notebook audit: no truth columns in estimation cells;
   meta-learner / Qini / placebo markers; methodological markdown.

Usage
-----
From package root or monorepo root::

    python autograder/grade_a3.py
    python autograder/grade_a3.py --notebook notebooks/A3_cate_meta_learners_ihdp.ipynb
    python autograder/grade_a3.py --json-out /tmp/a3_grade.json

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

from lib.cate_utils import (  # noqa: E402
    DEFAULT_METHOD_SELECTED,
    export_a3_artifacts,
    fit_t_learner,
    placebo_permute_treatment,
)
from lib.data_io import assert_no_truth_columns, load_scenario, load_truth  # noqa: E402
from lib.metrics import pehe  # noqa: E402
from lib.paths import (  # noqa: E402
    RANDOM_STATE,
    SCENARIO_A3,
    artifacts_dir,
    package_root,
)

# Ground-truth leakage (not estimated CATE locals named tau_hat / tau).
# Bare ``tau`` as a local for τ̂ is common; flag truth column access instead.
TRUTH_PATTERNS = (
    r"\by0\b",
    r"\by1\b",
    r"load_truth\s*\(",
    r"truth_train",
    r"truth_test",
    r"truth_validation",
    r"truth\.csv",
    r"\btau_true\b",
    r"\btrue_tau\b",
    r"""\[['\"]tau['\"]\]""",
    r"""\.get\(\s*['\"]tau['\"]""",
    r"""columns\s*==\s*['\"]tau['\"]""",
)
# Only final marked evaluation section headers (not the transparency policy table).
EVAL_SECTION_MARKERS = (
    "## 9. EVALUACIÓN CON GROUND TRUTH",
    "## 9. EVALUACION CON GROUND TRUTH",
    "SECCIÓN DE EVALUACIÓN — NO FORMA PARTE",
    "SECCION DE EVALUACION — NO FORMA PARTE",
    "=== EVALUACIÓN CON TRUTH (marcada)",
    "=== EVALUACION CON TRUTH (marcada)",
    "⚠️ **SECCIÓN DE EVALUACIÓN",
    "⚠️ **SECCION DE EVALUACION",
)

CATE_MARKERS = (
    "fit_s_learner",
    "fit_t_learner",
    "fit_x_learner",
    "fit_r_learner",
    "fit_meta_learners",
    "fit_causal_forest",
    "s_learner",
    "t_learner",
    "x_learner",
    "r_learner",
    "placebo",
    "qini",
)


def _load_ranges() -> Dict[str, Any]:
    path = package_root() / "autograder" / "expected_ranges.yaml"
    if not path.is_file():
        return {
            "scenario": SCENARIO_A3,
            "scenario_id": "real_ihdp",
            "ate_true": 3.9185,
            "max_pehe_t_learner": 8.0,
            "max_abs_ate_placebo": 0.5,
        }
    with path.open("r", encoding="utf-8") as f:
        raw = yaml.safe_load(f)
    return dict(raw.get("a3_ihdp", raw))


def run_estimation_checks(ranges: Dict[str, Any]) -> Tuple[List[Dict], bool]:
    """Placebo + PEHE T-learner (truth only here)."""
    scenario = ranges.get("scenario", SCENARIO_A3)
    max_pehe = float(ranges.get("max_pehe_t_learner", 8.0))
    max_placebo = float(ranges.get("max_abs_ate_placebo", 0.5))

    results: List[Dict[str, Any]] = []
    ok = True

    bundle = load_scenario(scenario)
    assert_no_truth_columns(bundle.train, context="grade_a3 train")
    assert_no_truth_columns(bundle.test, context="grade_a3 test")

    y, t, X = bundle.ytx("train")
    y_te, _, X_te = bundle.ytx("test")

    # Placebo on train
    placebo = placebo_permute_treatment(
        y, t, X, learner="t", n_perm=1, random_state=RANDOM_STATE
    )
    ate_p = float(placebo["ate_placebo"])
    placebo_ok = abs(ate_p) < max_placebo
    results.append(
        {
            "check": "placebo_ate_near_zero",
            "passed": placebo_ok,
            "ate_placebo": ate_p,
            "mean_abs_tau": float(placebo["mean_abs_tau"]),
            "threshold": max_placebo,
            "detail": (
                f"|ATE_placebo|={abs(ate_p):.4f} (max {max_placebo}); "
                f"mean|tau|={placebo['mean_abs_tau']:.4f}"
            ),
        }
    )
    if not placebo_ok:
        ok = False

    # PEHE T-learner on test (reference re-fit)
    t_model = fit_t_learner(y, t, X, random_state=RANDOM_STATE)
    tau_hat = t_model.predict(X_te)
    truth_test = load_truth(scenario, "test")
    if "tau" not in truth_test.columns:
        results.append(
            {
                "check": "pehe_t_learner_test",
                "passed": False,
                "detail": "truth_test missing tau column",
            }
        )
        return results, False

    pehe_val = pehe(tau_hat, truth_test["tau"].to_numpy())
    pehe_ok = pehe_val < max_pehe
    results.append(
        {
            "check": "pehe_t_learner_test",
            "passed": pehe_ok,
            "pehe": pehe_val,
            "threshold": max_pehe,
            "mean_tau_hat": float(np.mean(tau_hat)),
            "detail": (
                f"PEHE_T={pehe_val:.4f} (max {max_pehe}); "
                f"scorecard order ~3.9; mean_tau_hat={float(np.mean(tau_hat)):.4f}"
            ),
        }
    )
    if not pehe_ok:
        ok = False

    # Sanity: both treatment arms in train
    rate = float(np.mean(np.asarray(t, dtype=float)))
    rate_ok = 0.05 < rate < 0.95
    results.append(
        {
            "check": "treatment_rate_train",
            "passed": rate_ok,
            "value": rate,
            "detail": f"treatment rate train={rate:.3f}",
        }
    )
    if not rate_ok:
        ok = False

    # finite predictions
    finite_ok = bool(np.isfinite(tau_hat).all())
    results.append(
        {
            "check": "t_learner_predictions_finite",
            "passed": finite_ok,
            "detail": f"finite={finite_ok} n_test={len(tau_hat)}",
        }
    )
    if not finite_ok:
        ok = False

    return results, ok


def run_artifact_checks(
    ranges: Dict[str, Any], *, ensure: bool = True
) -> Tuple[List[Dict], bool]:
    """Verify A3 scores CSV (+ plots); optionally generate reference artifacts."""
    results: List[Dict[str, Any]] = []
    ok = True
    art_dir = artifacts_dir("A3")
    scores_path = art_dir / "cate_scores_test.csv"
    qini_path = art_dir / "qini_plot.png"
    cate_path = art_dir / "cate_comparison.png"

    if ensure and not scores_path.is_file():
        try:
            export_a3_artifacts(
                scenario=ranges.get("scenario", SCENARIO_A3),
                out_dir=art_dir,
                method_selected=DEFAULT_METHOD_SELECTED,
                random_state=RANDOM_STATE,
                save_plots=True,
            )
            results.append(
                {
                    "check": "artifact_generated_by_grader",
                    "passed": True,
                    "detail": f"export_a3_artifacts wrote {scores_path}",
                }
            )
        except Exception as exc:  # pragma: no cover
            results.append(
                {
                    "check": "artifact_generated_by_grader",
                    "passed": False,
                    "detail": f"export failed: {exc}",
                }
            )
            return results, False

    exists = scores_path.is_file()
    results.append(
        {
            "check": "artifact_cate_scores_exists",
            "passed": exists,
            "path": str(scores_path),
            "detail": f"exists={exists}: {scores_path}",
        }
    )
    if not exists:
        return results, False

    try:
        import pandas as pd

        df = pd.read_csv(scores_path)
        has_row = "row_id" in df.columns
        tau_cols = [c for c in df.columns if str(c).startswith("tau_hat_")]
        has_method = "method_selected" in df.columns
        n_ok = len(df) >= 50  # test split ~150
        multi = len(tau_cols) >= 4  # S/T/X/R at least
        finite = True
        for c in tau_cols:
            finite = finite and bool(np.isfinite(df[c].to_numpy(dtype=float)).all())

        structure_ok = has_row and has_method and multi and n_ok and finite
        results.append(
            {
                "check": "artifact_cate_scores_structure",
                "passed": structure_ok,
                "n_rows": len(df),
                "tau_columns": tau_cols,
                "detail": (
                    f"row_id={has_row} method_selected={has_method} "
                    f"n_tau_cols={len(tau_cols)} n_rows={len(df)} finite={finite}"
                ),
            }
        )
        if not structure_ok:
            ok = False

        if has_method and multi:
            method = str(df["method_selected"].iloc[0])
            col = f"tau_hat_{method}"
            if col not in df.columns:
                # allow fuzzy: method may be causal_forest_fallback...
                matches = [c for c in tau_cols if method in c or c.endswith(method)]
                col_ok = len(matches) > 0
            else:
                col_ok = True
            results.append(
                {
                    "check": "artifact_method_selected_column",
                    "passed": col_ok,
                    "method_selected": method,
                    "detail": f"method_selected={method!r} has matching tau column",
                }
            )
            if not col_ok:
                ok = False
    except Exception as exc:
        results.append(
            {
                "check": "artifact_cate_scores_structure",
                "passed": False,
                "detail": f"read/parse failed: {exc}",
            }
        )
        ok = False

    # Plots: soft if missing when ensure generated them, hard if scores exist
    # but plots are recommended; require both for full pass when ensure=True
    for label, path in (
        ("qini_plot", qini_path),
        ("cate_comparison", cate_path),
    ):
        p_ok = path.is_file() and path.stat().st_size > 100
        results.append(
            {
                "check": f"artifact_{label}_exists",
                "passed": p_ok,
                "path": str(path),
                "detail": f"exists={path.is_file()} size={path.stat().st_size if path.is_file() else 0}",
            }
        )
        if not p_ok:
            ok = False

    return results, ok


def _cell_source(cell: dict) -> str:
    src = cell.get("source", "")
    if isinstance(src, list):
        return "".join(src)
    return str(src)


def audit_notebook(nb_path: Path) -> Tuple[List[Dict], bool]:
    """Static checks on the student notebook."""
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

    in_eval = False
    est_code: List[str] = []
    all_md: List[str] = []
    method_md: List[str] = []

    for cell in cells:
        text = _cell_source(cell)
        ctype = cell.get("cell_type")
        if ctype == "markdown":
            all_md.append(text)
            upper = text.upper()
            if any(m.upper() in upper for m in EVAL_SECTION_MARKERS):
                in_eval = True
            low = text.lower()
            if any(
                k in low
                for k in (
                    "meta-learner",
                    "metalearner",
                    "cate",
                    "qini",
                    "placebo",
                    "heterogen",
                    "s-learner",
                    "t-learner",
                    "x-learner",
                    "r-learner",
                    "bosque causal",
                    "causal forest",
                    "pehe",
                    "uplift",
                )
            ):
                method_md.append(text)
        elif ctype == "code":
            if in_eval:
                continue
            if re.search(r"load_truth\s*\(", text) and not in_eval:
                in_eval = True
                continue
            est_code.append(text)

    combined_est = "\n".join(est_code)
    # Allow tau_hat_ as predicted CATE column names (not ground-truth tau)
    # Strip those before truth-pattern scan for \btau\b
    scrubbed = re.sub(r"tau_hat_\w+", "CATE_SCORE", combined_est)
    scrubbed = re.sub(r"\btau_hat\b", "CATE_SCORE", scrubbed)

    leakage_hits: List[str] = []
    for pat in TRUTH_PATTERNS:
        for m in re.finditer(pat, scrubbed):
            snippet = scrubbed[max(0, m.start() - 40) : m.end() + 40].replace(
                "\n", " "
            )
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

    cate_hits = [m for m in CATE_MARKERS if m in combined_est]
    # Need S/T/X/R coverage + validation tools
    has_meta = sum(
        1
        for m in (
            "fit_s_learner",
            "fit_t_learner",
            "fit_x_learner",
            "fit_r_learner",
            "fit_meta_learners",
        )
        if m in combined_est
    ) >= 1 or (
        "s_learner" in combined_est
        and "t_learner" in combined_est
        and "x_learner" in combined_est
    )
    has_qini = "qini" in combined_est.lower()
    has_placebo = "placebo" in combined_est.lower()
    api_ok = has_meta and has_qini and has_placebo
    results.append(
        {
            "check": "notebook_mentions_cate_api",
            "passed": api_ok,
            "detail": (
                f"meta={has_meta} qini={has_qini} placebo={has_placebo}; "
                f"markers={cate_hits[:12]}"
            ),
        }
    )

    method_chars = sum(len(t) for t in method_md)
    min_chars = 350
    text_ok = method_chars >= min_chars
    results.append(
        {
            "check": "methodological_markdown_length",
            "passed": text_ok,
            "value": method_chars,
            "threshold": min_chars,
            "detail": f"method-related markdown chars={method_chars} (min {min_chars})",
        }
    )

    blob = "\n".join(all_md).lower()
    has_transparency = (
        "transparencia" in blob
        or "what_is_synthetic" in blob
        or "sintético" in blob
        or "synthetic" in blob
        or "ground truth" in blob
    )
    results.append(
        {
            "check": "transparency_block_present",
            "passed": has_transparency,
            "detail": (
                "transparency language found"
                if has_transparency
                else "missing transparency / synthetic-data notice"
            ),
        }
    )

    ok = leak_ok and api_ok and text_ok and has_transparency
    return results, ok


def grade(
    notebook: Optional[Path] = None,
    skip_notebook_audit: bool = False,
    ensure_artifacts: bool = True,
) -> Dict[str, Any]:
    ranges = _load_ranges()
    est_results, est_ok = run_estimation_checks(ranges)
    art_results, art_ok = run_artifact_checks(ranges, ensure=ensure_artifacts)

    nb_results: List[Dict] = []
    nb_ok = True
    if not skip_notebook_audit:
        nb_path = notebook or (
            package_root() / "notebooks" / "A3_cate_meta_learners_ihdp.ipynb"
        )
        nb_results, nb_ok = audit_notebook(Path(nb_path))

    all_results = est_results + art_results + nb_results
    hard_ok = est_ok and art_ok and (nb_ok if not skip_notebook_audit else True)

    summary = {
        "notebook_id": "A3",
        "scenario": ranges.get("scenario", SCENARIO_A3),
        "scenario_id": ranges.get("scenario_id", "real_ihdp"),
        "random_state": RANDOM_STATE,
        "passed": hard_ok,
        "n_checks": len(all_results),
        "n_passed": sum(1 for r in all_results if r.get("passed")),
        "checks": all_results,
    }
    return summary


def main(argv: Optional[List[str]] = None) -> int:
    parser = argparse.ArgumentParser(
        description="Grade Serie A notebook A3 (CATE meta-learners IHDP)"
    )
    parser.add_argument(
        "--notebook",
        type=Path,
        default=None,
        help="Path to A3_cate_meta_learners_ihdp.ipynb (default: package notebooks/)",
    )
    parser.add_argument(
        "--skip-notebook-audit",
        action="store_true",
        help="Only run estimation/artifact checks (no nbformat grep)",
    )
    parser.add_argument(
        "--no-ensure-artifacts",
        action="store_true",
        help="Do not auto-export missing A3 artifacts",
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
        ensure_artifacts=not args.no_ensure_artifacts,
    )

    if args.json_out:
        args.json_out.parent.mkdir(parents=True, exist_ok=True)
        with args.json_out.open("w", encoding="utf-8") as f:
            json.dump(report, f, indent=2)

    if not args.quiet:
        print("=" * 60)
        print("A3 Autograder — CATE meta-learners (real/ihdp)")
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
