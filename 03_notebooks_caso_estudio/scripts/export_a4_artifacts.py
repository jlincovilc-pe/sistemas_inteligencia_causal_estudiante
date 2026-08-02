#!/usr/bin/env python3
"""Export A4 policy artifacts for Serie B (B3) without a Jupyter kernel.

Writes under ``artifacts/A4/``::

    policy.joblib
    policy_card.md
    uplift_curve.png
    equity_table.csv

Reuses ``artifacts/A3/cate_scores_test.csv`` when present.

Usage (from package root or monorepo root)::

    python scripts/export_a4_artifacts.py
    python scripts/export_a4_artifacts.py --budget 0.20 --out-dir artifacts/A4
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

from lib.paths import RANDOM_STATE, SCENARIO_A4, artifacts_dir  # noqa: E402
from lib.policy_utils import export_a4_artifacts, load_policy  # noqa: E402


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(
        description="Export A4 policy / uplift artifacts for B3"
    )
    parser.add_argument(
        "--scenario",
        default=SCENARIO_A4,
        help="Scenario key under datasets/ (default: real/ihdp)",
    )
    parser.add_argument(
        "--out-dir",
        type=Path,
        default=None,
        help="Output directory (default: artifacts/A4)",
    )
    parser.add_argument(
        "--budget",
        type=float,
        default=0.20,
        help="Budget fraction B (default 0.20)",
    )
    parser.add_argument(
        "--method",
        default="t_learner",
        help="method_selected from A3 scores (default: t_learner)",
    )
    parser.add_argument(
        "--a3-scores",
        type=Path,
        default=None,
        help="Path to cate_scores_test.csv (default: artifacts/A3/...)",
    )
    parser.add_argument("--seed", type=int, default=RANDOM_STATE)
    parser.add_argument(
        "--no-plot",
        action="store_true",
        help="Skip uplift_curve.png",
    )
    args = parser.parse_args(argv)

    out = args.out_dir or artifacts_dir("A4")
    info = export_a4_artifacts(
        scenario=args.scenario,
        out_dir=out,
        budget_fraction=args.budget,
        method_selected=args.method,
        a3_scores_path=args.a3_scores,
        random_state=args.seed,
        save_plot=not args.no_plot,
    )

    print("A4 artifacts written:")
    for key in (
        "policy_path",
        "policy_card_path",
        "uplift_curve_path",
        "equity_table_path",
    ):
        print(f"  {key}: {info.get(key)}")
    print(f"  method_selected : {info.get('method_selected')}")
    print(f"  budget_fraction : {info.get('budget_fraction')}")
    print(f"  threshold       : {info.get('threshold')}")
    print(f"  treat_rate_test : {info.get('treat_rate_test')}")
    print(f"  qini_auc_test   : {info.get('qini_auc_test')}")
    print(f"  a3_scores_used  : {info.get('a3_scores_used')}")
    if info.get("plot_error"):
        print(f"  plot_error      : {info['plot_error']}")

    # Smoke: policy.predict on 3 rows (path may be monorepo-relative in meta)
    from lib.data_io import load_scenario
    from lib.paths import resolve_repo_path

    policy_fs = resolve_repo_path(info["policy_path"])
    pol = load_policy(policy_fs)
    bundle = load_scenario(args.scenario)
    _, _, X_te = bundle.ytx("test")
    smoke = pol.predict(X=X_te.iloc[:3])
    print(
        "  smoke predict  :",
        {
            "decision": smoke["decision"].tolist(),
            "uplift_score": [float(x) for x in smoke["uplift_score"]],
        },
    )
    print(
        json.dumps(
            {k: info[k] for k in info if k != "comparison_ipw"},
            indent=2,
            default=str,
        )
    )
    return 0



if __name__ == "__main__":
    raise SystemExit(main())
