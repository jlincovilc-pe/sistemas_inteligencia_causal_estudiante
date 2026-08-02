#!/usr/bin/env python3
"""Export A3 CATE artifacts for A4 (and Serie B handoff) without a Jupyter kernel.

Writes under ``artifacts/A3/``::

    cate_scores_test.csv
    qini_plot.png
    cate_comparison.png

Usage (from package root or monorepo root)::

    python scripts/export_a3_artifacts.py
    python scripts/export_a3_artifacts.py --method t_learner --out-dir artifacts/A3
"""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

_THIS = Path(__file__).resolve()
_PKG = _THIS.parent.parent
if str(_PKG) not in sys.path:
    sys.path.insert(0, str(_PKG))

from lib.cate_utils import DEFAULT_METHOD_SELECTED, export_a3_artifacts  # noqa: E402
from lib.paths import RANDOM_STATE, SCENARIO_A3, artifacts_dir  # noqa: E402


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(
        description="Export A3 CATE scores and plots for A4"
    )
    parser.add_argument(
        "--scenario",
        default=SCENARIO_A3,
        help="Scenario key under datasets/ (default: real/ihdp)",
    )
    parser.add_argument(
        "--out-dir",
        type=Path,
        default=None,
        help="Output directory (default: artifacts/A3)",
    )
    parser.add_argument(
        "--method",
        default=DEFAULT_METHOD_SELECTED,
        help="method_selected column value for A4 (default: t_learner)",
    )
    parser.add_argument("--seed", type=int, default=RANDOM_STATE)
    parser.add_argument(
        "--n-estimators-cf",
        type=int,
        default=100,
        help="Trees for causal forest / RF fallback (smoke-friendly default 100)",
    )
    parser.add_argument(
        "--no-plots",
        action="store_true",
        help="Skip PNG figures",
    )
    args = parser.parse_args(argv)

    out = args.out_dir or artifacts_dir("A3")
    info = export_a3_artifacts(
        scenario=args.scenario,
        out_dir=out,
        method_selected=args.method,
        random_state=args.seed,
        n_estimators_cf=args.n_estimators_cf,
        save_plots=not args.no_plots,
    )

    print("A3 artifacts written:")
    for key in ("scores_path", "qini_path", "cate_comparison_path"):
        print(f"  {key}: {info.get(key)}")
    print(f"  method_selected : {info.get('method_selected')}")
    print(f"  models          : {info.get('model_names')}")
    print(f"  mean_tau_test   : {info.get('mean_tau_test')}")
    print(f"  qini_auc_val    : {info.get('qini_auc_val')}")
    print(f"  placebo_ate     : {info.get('placebo_ate')}")
    print(f"  cf_backend      : {info.get('cf_backend')}")
    if info.get("plot_error"):
        print(f"  plot_error      : {info['plot_error']}")
    # compact JSON for CI logs
    serializable = {
        k: v
        for k, v in info.items()
        if k not in ("mean_tau_test",)
    }
    serializable["mean_tau_test"] = info.get("mean_tau_test")
    print(json.dumps(serializable, indent=2, default=str))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
