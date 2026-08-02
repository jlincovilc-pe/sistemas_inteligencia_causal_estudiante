#!/usr/bin/env python3
"""Export A2 DML artifacts for Serie B (B1) without a Jupyter kernel.

Writes under ``artifacts/A2/``::

    dml_estimator.joblib
    feature_list.json
    training_meta.json

Usage (from package root or monorepo root)::

    python scripts/export_a2_artifacts.py
    python scripts/export_a2_artifacts.py --backend sklearn --out-dir artifacts/A2
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

from lib.dml_utils import export_a2_artifacts, load_dml_artifact  # noqa: E402
from lib.paths import RANDOM_STATE, SCENARIO_A2, artifacts_dir  # noqa: E402


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="Export A2 DML artifacts for B1")
    parser.add_argument(
        "--scenario",
        default=SCENARIO_A2,
        help="Scenario key under datasets/ (default: synthetic/inference/ihdp_medium)",
    )
    parser.add_argument(
        "--out-dir",
        type=Path,
        default=None,
        help="Output directory (default: artifacts/A2)",
    )
    parser.add_argument(
        "--backend",
        default="auto",
        choices=("auto", "sklearn", "econml", "doubleml"),
        help="PLR backend (auto degrades to sklearn if econml missing)",
    )
    parser.add_argument("--n-folds", type=int, default=5)
    parser.add_argument("--seed", type=int, default=RANDOM_STATE)
    parser.add_argument(
        "--model-y",
        default="lasso",
        help="Nuisance model_y kind (official course: lasso)",
    )
    parser.add_argument(
        "--model-t",
        default="lasso",
        help="Nuisance model_t kind (official course: lasso)",
    )
    args = parser.parse_args(argv)

    out = args.out_dir or artifacts_dir("A2")
    info = export_a2_artifacts(
        scenario=args.scenario,
        out_dir=out,
        n_folds=args.n_folds,
        random_state=args.seed,
        backend=args.backend,
        model_y_kind=args.model_y,
        model_t_kind=args.model_t,
    )

    est = load_dml_artifact(info["joblib"])
    ate = float(est.const_marginal_ate())
    print("A2 artifacts written:")
    for key in ("joblib", "feature_list", "training_meta"):
        print(f"  {key}: {info[key]}")
    print(f"  method: {info['result'].get('method')}")
    print(f"  ATE   : {ate:.6f}")
    print(f"  CI    : [{info['result'].get('ci_low')}, {info['result'].get('ci_high')}]")
    print(json.dumps(info["result"], indent=2, default=str))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
