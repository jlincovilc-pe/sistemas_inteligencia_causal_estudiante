#!/usr/bin/env python3
"""Autograder for Notebook A4 (policy / uplift on real/ihdp).

Pure script (no Jupyter kernel state). Uses ground truth and
``expected_ranges.yaml`` only on the grader side.

Checks
------
1. Budget: treat fraction under policy ≈ B ± tolerance.
2. Welfare: oracle value(π) ≥ value(random) − slack (when configured).
3. Artifacts under ``artifacts/A4/`` (policy.joblib + card + plot + equity).
4. ``policy.predict`` smoke on a few test rows.
5. Optional notebook audit: no truth in estimation cells; policy / uplift markers.

Usage
-----
From package root or monorepo root::

    python autograder/grade_a4.py
    python autograder/grade_a4.py --notebook notebooks/A4_policy_uplift_ihdp.ipynb
    python autograder/grade_a4.py --json-out /tmp/a4_grade.json

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
from lib.paths import (  # noqa: E402
    RANDOM_STATE,
    SCENARIO_A4,
    artifacts_dir,
    package_root,
)
from lib.policy_utils import (  # noqa: E402
    export_a4_artifacts,
    load_or_compute_cate_scores,
    load_policy,
    make_threshold_policy,
    policy_value_from_tau,
    random_policy,
)

# Ground-truth leakage patterns (estimation cells).
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
    r"policy_value_from_tau",
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

POLICY_MARKERS = (
    "make_threshold_policy",
    "threshold_from_budget",
    "export_a4_artifacts",
    "random_policy",
    "outcome_only_policy",
    "equity_table",
    "qini_curve",
    "uplift_curve",
    "policy.joblib",
    "budget",
    "BUDGET",
)


def _load_ranges() -> Dict[str, Any]:
    path = package_root() / "autograder" / "expected_ranges.yaml"
    if not path.is_file():
        return {
            "scenario": SCENARIO_A4,
            "scenario_id": "real_ihdp",
            "budget_fraction": 0.20,
            "budget_tolerance": 0.02,
            "require_artifact": "artifacts/A4/policy.joblib",
            "welfare_beats_random": True,
            "welfare_slack": 0.0,
        }
    with path.open("r", encoding="utf-8") as f:
        raw = yaml.safe_load(f)
    cfg = dict(raw.get("a4_ihdp", raw))
    cfg.setdefault("budget_fraction", 0.20)
    cfg.setdefault("budget_tolerance", 0.02)
    cfg.setdefault("welfare_beats_random", True)
    cfg.setdefault("welfare_slack", 0.0)
    return cfg


def run_estimation_checks(ranges: Dict[str, Any]) -> Tuple[List[Dict], bool]:
    """Budget + welfare oracle (truth only here)."""
    scenario = ranges.get("scenario", SCENARIO_A4)
    B = float(ranges.get("budget_fraction", 0.20))
    tol = float(ranges.get("budget_tolerance", 0.02))
    slack = float(ranges.get("welfare_slack", 0.0))
    beats = bool(ranges.get("welfare_beats_random", True))

    results: List[Dict[str, Any]] = []
    ok = True

    bundle = load_scenario(scenario)
    assert_no_truth_columns(bundle.train, context="grade_a4 train")
    assert_no_truth_columns(bundle.test, context="grade_a4 test")

    scores_df, tau_hat, method, scorer = load_or_compute_cate_scores(
        scenario,
        method_selected="t_learner",
        random_state=RANDOM_STATE,
    )
    policy = make_threshold_policy(
        tau_hat,
        budget_fraction=B,
        mode="topk",
        method_name=method,
        feature_names=list(bundle.covariate_columns()),
        score_model=scorer,
    )
    decision = policy.predict(scores=tau_hat)["decision"]
    treat_rate = float(np.mean(decision))
    budget_ok = abs(treat_rate - B) <= tol + 1e-9
    results.append(
        {
            "check": "budget_treat_rate",
            "passed": budget_ok,
            "treat_rate": treat_rate,
            "budget_fraction": B,
            "tolerance": tol,
            "threshold": float(policy.threshold),
            "detail": (
                f"treat_rate={treat_rate:.4f} target={B:.2f}±{tol:.2f}; "
                f"λ={policy.threshold:.4f}; method={method}"
            ),
        }
    )
    if not budget_ok:
        ok = False

    # Oracle welfare vs random
    truth_test = load_truth(scenario, "test")
    if "tau" not in truth_test.columns:
        results.append(
            {
                "check": "welfare_beats_random",
                "passed": False,
                "detail": "truth_test missing tau column",
            }
        )
        return results, False

    tau_true = truth_test["tau"].to_numpy(dtype=float)
    if len(tau_true) != len(decision):
        results.append(
            {
                "check": "welfare_beats_random",
                "passed": False,
                "detail": (
                    f"tau length {len(tau_true)} != decision length {len(decision)}"
                ),
            }
        )
        return results, False

    v_pi = policy_value_from_tau(decision, tau_true)
    dec_rand = random_policy(len(decision), B, random_state=RANDOM_STATE)
    v_rand = policy_value_from_tau(dec_rand, tau_true)
    if beats:
        welfare_ok = v_pi >= (v_rand - slack)
    else:
        welfare_ok = True
    results.append(
        {
            "check": "welfare_beats_random",
            "passed": welfare_ok,
            "value_pi": v_pi,
            "value_random": v_rand,
            "slack": slack,
            "detail": (
                f"value_pi={v_pi:.4f} value_random={v_rand:.4f} "
                f"diff={v_pi - v_rand:.4f} slack={slack}"
            ),
        }
    )
    if not welfare_ok:
        ok = False

    # Finite scores
    finite_ok = bool(np.isfinite(tau_hat).all())
    results.append(
        {
            "check": "cate_scores_finite",
            "passed": finite_ok,
            "n": int(len(tau_hat)),
            "detail": f"finite={finite_ok} n={len(tau_hat)} mean={float(np.mean(tau_hat)):.4f}",
        }
    )
    if not finite_ok:
        ok = False

    _ = scores_df  # loaded for continuity with A3
    return results, ok


def run_artifact_checks(
    ranges: Dict[str, Any], *, ensure: bool = True
) -> Tuple[List[Dict], bool]:
    """Verify A4 policy artifacts; optionally generate reference artifacts."""
    results: List[Dict[str, Any]] = []
    ok = True
    art_dir = artifacts_dir("A4")
    policy_path = art_dir / "policy.joblib"
    card_path = art_dir / "policy_card.md"
    uplift_path = art_dir / "uplift_curve.png"
    equity_path = art_dir / "equity_table.csv"

    if ensure and not policy_path.is_file():
        try:
            export_a4_artifacts(
                scenario=ranges.get("scenario", SCENARIO_A4),
                out_dir=art_dir,
                budget_fraction=float(ranges.get("budget_fraction", 0.20)),
                random_state=RANDOM_STATE,
                save_plot=True,
            )
            results.append(
                {
                    "check": "artifact_generated_by_grader",
                    "passed": True,
                    "detail": f"export_a4_artifacts wrote {policy_path}",
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

    exists = policy_path.is_file()
    results.append(
        {
            "check": "artifact_policy_exists",
            "passed": exists,
            "path": str(policy_path),
            "detail": f"exists={exists}: {policy_path}",
        }
    )
    if not exists:
        return results, False

    # Load + predict smoke
    try:
        pol = load_policy(policy_path)
        bundle = load_scenario(ranges.get("scenario", SCENARIO_A4))
        _, _, X_te = bundle.ytx("test")
        smoke = pol.predict(X=X_te.iloc[:3])
        has_dec = "decision" in smoke and len(smoke["decision"]) == 3
        has_sc = "uplift_score" in smoke and len(smoke["uplift_score"]) == 3
        dec_bin = set(np.unique(smoke["decision"]).tolist()).issubset({0, 1})
        finite_sc = bool(np.isfinite(smoke["uplift_score"]).all())
        pred_ok = has_dec and has_sc and dec_bin and finite_sc
        results.append(
            {
                "check": "artifact_policy_predict_smoke",
                "passed": pred_ok,
                "decision": [int(x) for x in smoke["decision"]],
                "detail": (
                    f"keys={list(smoke.keys())} decision={smoke['decision'].tolist()} "
                    f"scores_finite={finite_sc}"
                ),
            }
        )
        if not pred_ok:
            ok = False

        # Budget of stored policy on full test via scores if available
        full = pol.predict(X=X_te)
        rate = float(np.mean(full["decision"]))
        B = float(ranges.get("budget_fraction", 0.20))
        tol = float(ranges.get("budget_tolerance", 0.02))
        # Allow a bit more slack for X-path vs score-path mismatch
        rate_ok = abs(rate - B) <= (tol + 0.05)
        results.append(
            {
                "check": "artifact_policy_treat_rate_x_path",
                "passed": rate_ok,
                "treat_rate": rate,
                "detail": (
                    f"treat_rate via predict(X)={rate:.4f} "
                    f"(B={B}; soft tol {tol}+0.05 for scorer mismatch)"
                ),
            }
        )
        if not rate_ok:
            ok = False
    except Exception as exc:
        results.append(
            {
                "check": "artifact_policy_predict_smoke",
                "passed": False,
                "detail": f"load/predict failed: {exc}",
            }
        )
        ok = False

    # Card
    card_ok = card_path.is_file() and card_path.stat().st_size > 200
    card_text = card_path.read_text(encoding="utf-8") if card_path.is_file() else ""
    has_scope = any(
        k in card_text.lower()
        for k in ("budget", "assumption", "limit", "non-claim", "non claim", "interface")
    )
    results.append(
        {
            "check": "artifact_policy_card",
            "passed": card_ok and has_scope,
            "path": str(card_path),
            "detail": (
                f"exists={card_path.is_file()} size="
                f"{card_path.stat().st_size if card_path.is_file() else 0} "
                f"auditable_keys={has_scope}"
            ),
        }
    )
    if not (card_ok and has_scope):
        ok = False

    # Equity + plot
    eq_ok = equity_path.is_file() and equity_path.stat().st_size > 20
    results.append(
        {
            "check": "artifact_equity_table",
            "passed": eq_ok,
            "path": str(equity_path),
            "detail": f"exists={equity_path.is_file()}",
        }
    )
    if not eq_ok:
        ok = False
    else:
        try:
            import pandas as pd

            eq = pd.read_csv(equity_path)
            cols_ok = len(eq) >= 1 and any(
                c in eq.columns for c in ("treat_rate", "n_treated")
            )
            results.append(
                {
                    "check": "artifact_equity_structure",
                    "passed": cols_ok,
                    "columns": list(eq.columns),
                    "n_rows": len(eq),
                    "detail": f"cols={list(eq.columns)} n={len(eq)}",
                }
            )
            if not cols_ok:
                ok = False
        except Exception as exc:
            results.append(
                {
                    "check": "artifact_equity_structure",
                    "passed": False,
                    "detail": f"read failed: {exc}",
                }
            )
            ok = False

    plot_ok = uplift_path.is_file() and uplift_path.stat().st_size > 100
    results.append(
        {
            "check": "artifact_uplift_curve",
            "passed": plot_ok,
            "path": str(uplift_path),
            "detail": (
                f"exists={uplift_path.is_file()} size="
                f"{uplift_path.stat().st_size if uplift_path.is_file() else 0}"
            ),
        }
    )
    if not plot_ok:
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
                    "policy",
                    "uplift",
                    "qini",
                    "presupuesto",
                    "budget",
                    "equidad",
                    "equity",
                    "baseline",
                    "welfare",
                    "política",
                    "politica",
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

    has_policy = any(
        m in combined_est
        for m in (
            "make_threshold_policy",
            "threshold_from_budget",
            "export_a4_artifacts",
            "Policy(",
        )
    )
    has_baseline = (
        "random_policy" in combined_est or "outcome_only_policy" in combined_est
    )
    has_qini = "qini" in combined_est.lower() or "uplift_curve" in combined_est
    has_equity = "equity" in combined_est.lower()
    api_ok = has_policy and has_baseline and has_qini and has_equity
    results.append(
        {
            "check": "notebook_mentions_policy_api",
            "passed": api_ok,
            "detail": (
                f"policy={has_policy} baseline={has_baseline} "
                f"qini/uplift={has_qini} equity={has_equity}"
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
            package_root() / "notebooks" / "A4_policy_uplift_ihdp.ipynb"
        )
        nb_results, nb_ok = audit_notebook(Path(nb_path))

    all_results = est_results + art_results + nb_results
    hard_ok = est_ok and art_ok and (nb_ok if not skip_notebook_audit else True)

    summary = {
        "notebook_id": "A4",
        "scenario": ranges.get("scenario", SCENARIO_A4),
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
        description="Grade Serie A notebook A4 (policy / uplift IHDP)"
    )
    parser.add_argument(
        "--notebook",
        type=Path,
        default=None,
        help="Path to A4_policy_uplift_ihdp.ipynb (default: package notebooks/)",
    )
    parser.add_argument(
        "--skip-notebook-audit",
        action="store_true",
        help="Only run estimation/artifact checks (no nbformat grep)",
    )
    parser.add_argument(
        "--no-ensure-artifacts",
        action="store_true",
        help="Do not auto-export missing A4 artifacts",
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
        print("A4 Autograder — policy / uplift (real/ihdp)")
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
