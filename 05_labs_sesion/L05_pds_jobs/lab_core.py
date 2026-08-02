"""L05 — Post-Double-Selection sobre Jobs (alimenta A1)."""

from __future__ import annotations

import sys
from pathlib import Path
from typing import List, Tuple

import numpy as np
from sklearn.preprocessing import PolynomialFeatures

_LABS = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(_LABS))
from lab_harness import ensure_serie_a

ensure_serie_a()

from lib.data_io import load_scenario
from lib.identification import diff_in_means, ols_ate, post_double_selection_ate
from lib.paths import RANDOM_STATE, SCENARIO_A1

COVARS = ["age", "educ", "black", "hispan", "married", "nodegree", "re74", "re75"]


def load_xy() -> Tuple[np.ndarray, np.ndarray, np.ndarray, List[str]]:
    bundle = load_scenario(SCENARIO_A1)
    y, t, X = bundle.ytx("train")
    return (
        np.asarray(y, dtype=float),
        np.asarray(t, dtype=float),
        np.asarray(X[COVARS], dtype=float),
        list(COVARS),
    )


def expand_features(X: np.ndarray) -> np.ndarray:
    poly = PolynomialFeatures(degree=2, include_bias=False)
    return poly.fit_transform(X)


def run_lab() -> dict:
    y, t, X, _ = load_xy()
    dim = diff_in_means(y, t)
    ols = ols_ate(y, t, X)
    Xp = expand_features(X)
    pds = post_double_selection_ate(y, t, Xp, random_state=RANDOM_STATE)
    return {
        "ate_dim": float(dim),
        "ate_ols": float(ols),
        "ate_pds": float(pds["ate"]),
        "n": int(y.size),
        "n_features_raw": int(X.shape[1]),
        "n_features_expanded": int(Xp.shape[1]),
        "n_selected": int(pds["n_selected"]),
        "selected": pds["selected"],
    }


if __name__ == "__main__":
    import json

    print(json.dumps(run_lab(), indent=2, default=str))
