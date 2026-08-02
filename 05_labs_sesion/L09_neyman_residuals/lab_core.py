"""L09 — Residuales de Neyman / cross-fitting (OOF)."""

from __future__ import annotations

import sys
from pathlib import Path

import numpy as np

_LABS = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(_LABS))
from lab_harness import ensure_serie_a

ensure_serie_a()

from lib.data_io import load_scenario
from lib.dml_utils import cross_fit_residuals, default_model_t, default_model_y, plr_from_residuals
from lib.paths import RANDOM_STATE, SCENARIO_A2


def run_lab() -> dict:
    b = load_scenario(SCENARIO_A2)
    y, t, X = b.ytx("train")
    n = min(600, len(y))
    y = np.asarray(y, dtype=float)[:n]
    t = np.asarray(t, dtype=float)[:n]
    X = np.asarray(X, dtype=float)[:n]

    my = default_model_y("lasso", random_state=RANDOM_STATE)
    mt = default_model_t("lasso", random_state=RANDOM_STATE)
    y_res, t_res, y_hat, t_hat = cross_fit_residuals(
        y, t, X, model_y=my, model_t=mt, n_folds=3, random_state=RANDOM_STATE
    )
    plr = plr_from_residuals(y_res, t_res)
    return {
        "n": n,
        "mean_y_res": float(np.mean(y_res)),
        "mean_t_res": float(np.mean(t_res)),
        "corr_yres_tres": float(np.corrcoef(y_res, t_res)[0, 1]),
        "ate_partialling": float(plr.ate),
        "n_folds": 3,
    }


if __name__ == "__main__":
    import json

    print(json.dumps(run_lab(), indent=2))
