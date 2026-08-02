"""L10 — PLR mínimo (K=3, un learner) sobre ihdp_medium."""

from __future__ import annotations

import sys
from pathlib import Path

import numpy as np

_LABS = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(_LABS))
from lab_harness import ensure_serie_a

ensure_serie_a()

from lib.data_io import load_scenario
from lib.dml_utils import fit_plr
from lib.paths import RANDOM_STATE, SCENARIO_A2


def run_lab() -> dict:
    b = load_scenario(SCENARIO_A2)
    y, t, X = b.ytx("train")
    _est, res = fit_plr(
        y,
        t,
        X,
        backend="sklearn",
        model_y_kind="lasso",
        model_t_kind="lasso",
        n_folds=3,
        random_state=RANDOM_STATE,
    )
    return {
        "ate": float(res.ate),
        "se": float(res.se) if res.se is not None else None,
        "ci_low": float(res.ci_low) if res.ci_low is not None else None,
        "ci_high": float(res.ci_high) if res.ci_high is not None else None,
        "method": str(res.method),
        "n": int(np.asarray(y).shape[0]),
        "n_folds": 3,
    }


if __name__ == "__main__":
    import json

    print(json.dumps(run_lab(), indent=2, default=str))
