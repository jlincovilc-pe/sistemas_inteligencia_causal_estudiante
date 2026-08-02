#!/usr/bin/env python3
"""Autograder for Notebook A2 (DML / PLR on IHDP medium).

Pure script (no Jupyter kernel state). Uses ground truth and
``expected_ranges.yaml`` only on the grader side.

Checks
------
1. Reference DML-PLR (Lasso, K=5) absolute error vs ``ate_true`` within tolerance.
2. Confidence interval reported; soft check that it covers ``ate_true``.
3. Cross-fitting implementation does not leak fold train indices into OOF residuals
   (unit-style probe on synthetic data + source markers).
4. Artifacts under ``artifacts/A2/`` exist and expose B1 interface.
5. Optional notebook audit: no truth columns in estimation cells;
   methodological markdown length heuristic.

Usage
-----
From package root or monorepo root::

    python autograder/grade_a2.py
    python autograder/grade_a2.py --notebook notebooks/A2_dml_ihdp_medium.ipynb
    python autograder/grade_a2.py --json-out /tmp/a2_grade.json

Exit code 0 if all hard checks pass; 1 otherwise.
"""

from __future__ import annotations

import argparse
import inspect
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
from lib.dml_utils import (  # noqa: E402
    cross_fit_residuals,
    default_model_t,
    default_model_y,
    export_a2_artifacts,
    fit_plr,
    load_dml_artifact,
)
from lib.metrics import ate_absolute_error, ate_from_tau, coverage_indicator  # noqa: E402
from lib.paths import (  # noqa: E402
    RANDOM_STATE,
    SCENARIO_A2,
    artifacts_dir,
    package_root,
)

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
)

CROSSFIT_MARKERS = (
    "cross_fit_residuals",
    "fit_plr",
    "fit_plr_sklearn",
    "LinearDML",
    "DoubleMLPLR",
    "n_folds",
    "KFold",
)


def _load_ranges() -> Dict[str, Any]:
    path = package_root() / "autograder" / "expected_ranges.yaml"
    if not path.is_file():
        return {
            "scenario": SCENARIO_A2,
            "scenario_id": "synthetic_inference_ihdp_medium",
            "ate_true": 3.9685,
            "max_abs_error_dml": 0.5,
            "require_artifact": "artifacts/A2/dml_estimator.joblib",
        }
    with path.open("r", encoding="utf-8") as f:
        raw = yaml.safe_load(f)
    return dict(raw.get("a2_ihdp_medium", raw))


def _check_crossfit_no_leak() -> Tuple[Dict[str, Any], bool]:
    """Probe that OOF residuals differ from in-sample residuals (no trivial leak)."""
    rng = np.random.default_rng(RANDOM_STATE)
    n, p = 200, 5
    X = rng.normal(size=(n, p))
    t = (X[:, 0] + rng.normal(scale=0.5, size=n) > 0).astype(float)
    y = 2.0 * t + X[:, 1] + rng.normal(scale=0.3, size=n)

    my = default_model_y("lasso", random_state=RANDOM_STATE)
    mt = default_model_t("lasso", random_state=RANDOM_STATE)
    y_res_oof, t_res_oof, y_hat_oof, t_hat_oof = cross_fit_residuals(
        y, t, X, my, mt, n_folds=5, random_state=RANDOM_STATE
    )

    # In-sample (leaky) fit on full data
    my_full = default_model_y("lasso", random_state=RANDOM_STATE)
    mt_full = default_model_t("lasso", random_state=RANDOM_STATE)
    my_full.fit(X, y)
    mt_full.fit(X, t)
    y_hat_in = np.asarray(my_full.predict(X), dtype=float).reshape(-1)
    if hasattr(mt_full, "predict_proba"):
        t_hat_in = mt_full.predict_proba(X)[:, 1]
    else:
        t_hat_in = np.asarray(mt_full.predict(X), dtype=float).reshape(-1)

    # OOF predictions must not be identical to full in-sample predictions
    max_diff_y = float(np.max(np.abs(y_hat_oof - y_hat_in)))
    max_diff_t = float(np.max(np.abs(t_hat_oof - t_hat_in)))
    # Residuals finite and full length
    shapes_ok = (
        y_res_oof.shape == (n,)
        and t_res_oof.shape == (n,)
        and np.isfinite(y_res_oof).all()
        and np.isfinite(t_res_oof).all()
    )
    # Source audit: train_idx used for fit, test_idx for predict
    src = inspect.getsource(cross_fit_residuals)
    uses_split = "train_idx" in src and "test_idx" in src and "clone" in src
    # Difference threshold: with CV, OOF ≠ in-sample almost always
    distinct = max_diff_y > 1e-8 or max_diff_t > 1e-8
    passed = bool(shapes_ok and uses_split and distinct)
    detail = (
        f"shapes_ok={shapes_ok} uses_split={uses_split} "
        f"max|y_oof-y_in|={max_diff_y:.3e} max|t_oof-t_in|={max_diff_t:.3e}"
    )
    return {
        "check": "crossfit_no_fold_leakage",
        "passed": passed,
        "detail": detail,
        "max_diff_y": max_diff_y,
        "max_diff_t": max_diff_t,
    }, passed


def run_estimation_checks(ranges: Dict[str, Any]) -> Tuple[List[Dict], bool]:
    """DML ATE vs truth + CI soft check."""
    scenario = ranges.get("scenario", SCENARIO_A2)
    ate_true = float(ranges.get("ate_true", 3.9685))
    max_ae = float(ranges.get("max_abs_error_dml", 0.5))

    results: List[Dict[str, Any]] = []
    ok = True

    bundle = load_scenario(scenario)
    assert_no_truth_columns(bundle.train, context="grade_a2 train")
    assert_no_truth_columns(bundle.test, context="grade_a2 test")

    y, t, X = bundle.ytx("train")
    _, res = fit_plr(
        y,
        t,
        X,
        backend="auto",
        model_y_kind="lasso",
        model_t_kind="lasso",
        n_folds=5,
        random_state=RANDOM_STATE,
    )
    ae = ate_absolute_error(res.ate, ate_true)
    ae_ok = ae < max_ae
    results.append(
        {
            "check": "ate_ae_dml_lasso_train",
            "passed": ae_ok,
            "ate_hat": float(res.ate),
            "ate_true": ate_true,
            "abs_error": ae,
            "threshold": max_ae,
            "method": res.method,
            "detail": (
                f"|{res.ate:.4f} - {ate_true:.4f}| = {ae:.4f} "
                f"(max {max_ae}); method={res.method}"
            ),
        }
    )
    if not ae_ok:
        ok = False

    # CI present + coverage (soft: does not alone fail if AE ok and CI length finite)
    has_ci = res.ci_low is not None and res.ci_high is not None and res.se is not None
    results.append(
        {
            "check": "dml_ci_reported",
            "passed": bool(has_ci),
            "ci_low": res.ci_low,
            "ci_high": res.ci_high,
            "se": res.se,
            "detail": (
                f"CI=[{res.ci_low}, {res.ci_high}] se={res.se}"
                if has_ci
                else "missing SE/CI on DML result"
            ),
        }
    )
    if not has_ci:
        ok = False

    covered = False
    if has_ci:
        covered = coverage_indicator(res.ci_low, res.ci_high, ate_true)
        ci_len = float(res.ci_high) - float(res.ci_low)
        # Soft: coverage failure alone does not fail if AE ok and CI finite/positive
        results.append(
            {
                "check": "dml_ci_covers_ate_true",
                "passed": True,  # soft informational
                "covered": covered,
                "ci_length": ci_len,
                "detail": (
                    f"covers={covered} length={ci_len:.4f} "
                    f"(soft check; AE hard check is primary)"
                ),
            }
        )

    # Truth consistency
    truth_test = load_truth(scenario, "test")
    tau_mean = ate_from_tau(truth_test["tau"])
    results.append(
        {
            "check": "truth_tau_mean_test",
            "passed": abs(tau_mean - ate_true) < 1.0,
            "value": tau_mean,
            "ate_true": ate_true,
            "detail": f"mean(tau_test)={tau_mean:.4f} vs ate_true={ate_true:.4f}",
        }
    )

    cf_result, cf_ok = _check_crossfit_no_leak()
    results.append(cf_result)
    if not cf_ok:
        ok = False

    return results, ok


def run_artifact_checks(ranges: Dict[str, Any], *, ensure: bool = True) -> Tuple[List[Dict], bool]:
    """Verify A2 joblib + sidecars; optionally generate reference artifacts."""
    results: List[Dict[str, Any]] = []
    ok = True
    art_dir = artifacts_dir("A2")
    joblib_path = art_dir / "dml_estimator.joblib"
    fl_path = art_dir / "feature_list.json"
    meta_path = art_dir / "training_meta.json"

    if ensure and not joblib_path.is_file():
        # Generate reference artifacts so grader can validate B1 contract
        try:
            export_a2_artifacts(
                scenario=ranges.get("scenario", SCENARIO_A2),
                out_dir=art_dir,
                n_folds=5,
                random_state=RANDOM_STATE,
                backend="auto",
                model_y_kind="lasso",
                model_t_kind="lasso",
            )
            results.append(
                {
                    "check": "artifact_generated_by_grader",
                    "passed": True,
                    "detail": f"export_a2_artifacts wrote {joblib_path}",
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

    exists = joblib_path.is_file()
    results.append(
        {
            "check": "artifact_joblib_exists",
            "passed": exists,
            "path": str(joblib_path),
            "detail": f"exists={exists}: {joblib_path}",
        }
    )
    if not exists:
        return results, False

    try:
        est = load_dml_artifact(joblib_path)
        # B1 interface
        if hasattr(est, "const_marginal_ate"):
            ate_v = float(np.asarray(est.const_marginal_ate()).reshape(-1)[0])
            iface = "const_marginal_ate"
        elif hasattr(est, "ate"):
            ate_v = float(np.asarray(est.ate()).reshape(-1)[0])
            iface = "ate"
        elif hasattr(est, "predict"):
            dummy = np.zeros((3, 25))
            pred = np.asarray(est.predict(dummy), dtype=float).reshape(-1)
            ate_v = float(pred.mean())
            iface = "predict"
        else:
            raise AttributeError("estimator has no const_marginal_ate/ate/predict")

        # Optional predict smoke
        pred_ok = True
        if hasattr(est, "predict"):
            bundle = load_scenario(ranges.get("scenario", SCENARIO_A2))
            _, _, X_te = bundle.ytx("test")
            pred = np.asarray(est.predict(X_te.head(5)), dtype=float).reshape(-1)
            pred_ok = pred.shape[0] == 5 and np.isfinite(pred).all()

        ate_true = float(ranges.get("ate_true", 3.9685))
        max_ae = float(ranges.get("max_abs_error_dml", 0.5))
        ae = ate_absolute_error(ate_v, ate_true)
        # Artifact AE can be slightly different if student serialized another learner;
        # hard fail only if wildly off (> 2.0) — primary AE is re-estimation check.
        art_ae_ok = ae < max(max_ae * 2, 1.0)
        results.append(
            {
                "check": "artifact_interface_ate",
                "passed": pred_ok and np.isfinite(ate_v),
                "ate": ate_v,
                "interface": iface,
                "abs_error_vs_true": ae,
                "detail": (
                    f"{iface}()={ate_v:.4f} AE_vs_true={ae:.4f} pred_ok={pred_ok}"
                ),
            }
        )
        if not (pred_ok and np.isfinite(ate_v)):
            ok = False
        results.append(
            {
                "check": "artifact_ate_sane",
                "passed": art_ae_ok,
                "abs_error": ae,
                "threshold": max(max_ae * 2, 1.0),
                "detail": f"artifact AE={ae:.4f} (sanity threshold)",
            }
        )
        if not art_ae_ok:
            ok = False
    except Exception as exc:
        results.append(
            {
                "check": "artifact_interface_ate",
                "passed": False,
                "detail": f"load/predict failed: {exc}",
            }
        )
        ok = False

    fl_ok = fl_path.is_file()
    meta_ok = meta_path.is_file()
    results.append(
        {
            "check": "artifact_feature_list_json",
            "passed": fl_ok,
            "detail": f"exists={fl_ok}: {fl_path}",
        }
    )
    results.append(
        {
            "check": "artifact_training_meta_json",
            "passed": meta_ok,
            "detail": f"exists={meta_ok}: {meta_path}",
        }
    )
    if not fl_ok or not meta_ok:
        ok = False

    if fl_ok:
        with fl_path.open("r", encoding="utf-8") as f:
            fl = json.load(f)
        fl_len_ok = isinstance(fl, list) and len(fl) == 25
        results.append(
            {
                "check": "feature_list_length_25",
                "passed": fl_len_ok,
                "value": len(fl) if isinstance(fl, list) else None,
                "detail": f"feature_list length={len(fl) if isinstance(fl, list) else type(fl)}",
            }
        )
        if not fl_len_ok:
            ok = False

    if meta_ok:
        with meta_path.open("r", encoding="utf-8") as f:
            tmeta = json.load(f)
        has_keys = all(
            k in tmeta
            for k in ("scenario_id", "seed", "ate_point_estimate", "estimand")
        )
        results.append(
            {
                "check": "training_meta_keys",
                "passed": has_keys,
                "detail": (
                    "scenario_id/seed/ate_point_estimate/estimand present"
                    if has_keys
                    else f"keys={list(tmeta.keys())}"
                ),
            }
        )
        if not has_keys:
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
                    "plr",
                    "dml",
                    "neyman",
                    "cross-fit",
                    "cross fitting",
                    "ortogonal",
                    "learner",
                    "model card",
                    "supuesto",
                    "identific",
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
    leakage_hits: List[str] = []
    for pat in TRUTH_PATTERNS:
        for m in re.finditer(pat, combined_est):
            snippet = combined_est[max(0, m.start() - 40) : m.end() + 40].replace(
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

    cross_hits = [m for m in CROSSFIT_MARKERS if m in combined_est]
    cross_ok = len(cross_hits) >= 2
    results.append(
        {
            "check": "notebook_mentions_crossfit_api",
            "passed": cross_ok,
            "detail": f"markers found: {cross_hits}",
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
    has_plr = "plr" in blob or "partially linear" in blob or "doble machine" in blob or "double machine" in blob
    results.append(
        {
            "check": "mentions_plr_or_dml",
            "passed": has_plr or ("dml" in blob),
            "detail": "markdown mentions PLR/DML" if (has_plr or "dml" in blob) else "missing PLR/DML language",
        }
    )

    ok = leak_ok and cross_ok and text_ok and (has_plr or "dml" in blob)
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
            package_root() / "notebooks" / "A2_dml_ihdp_medium.ipynb"
        )
        nb_results, nb_ok = audit_notebook(Path(nb_path))

    all_results = est_results + art_results + nb_results
    hard_ok = est_ok and art_ok and (nb_ok if not skip_notebook_audit else True)

    summary = {
        "notebook_id": "A2",
        "scenario": ranges.get("scenario", SCENARIO_A2),
        "scenario_id": ranges.get(
            "scenario_id", "synthetic_inference_ihdp_medium"
        ),
        "random_state": RANDOM_STATE,
        "passed": hard_ok,
        "n_checks": len(all_results),
        "n_passed": sum(1 for r in all_results if r.get("passed")),
        "checks": all_results,
    }
    return summary


def main(argv: Optional[List[str]] = None) -> int:
    parser = argparse.ArgumentParser(
        description="Grade Serie A notebook A2 (DML IHDP medium)"
    )
    parser.add_argument(
        "--notebook",
        type=Path,
        default=None,
        help="Path to A2_dml_ihdp_medium.ipynb (default: package notebooks/)",
    )
    parser.add_argument(
        "--skip-notebook-audit",
        action="store_true",
        help="Only run estimation/artifact checks (no nbformat grep)",
    )
    parser.add_argument(
        "--no-ensure-artifacts",
        action="store_true",
        help="Do not auto-export missing A2 artifacts",
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
        print("A2 Autograder — DML PLR (synthetic/inference/ihdp_medium)")
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
