"""L20 — Auditoría simple de importancia (proxy SHAP-free con permutación).

Si shap no está instalado, usamos permutation importance de sklearn sobre
un regresor del outcome (asociativo) y contrastamos con mensaje causal.
"""

from __future__ import annotations

import sys
from pathlib import Path

import numpy as np

_LABS = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(_LABS))
from lab_harness import ensure_serie_a

ensure_serie_a()

from lib.data_io import load_scenario
from lib.paths import RANDOM_STATE, SCENARIO_A2
from sklearn.ensemble import RandomForestRegressor
from sklearn.inspection import permutation_importance


def run_lab() -> dict:
    b = load_scenario(SCENARIO_A2)
    y, t, X = b.ytx("train")
    # subsample
    n = min(800, len(y))
    y = np.asarray(y, dtype=float)[:n]
    X = np.asarray(X, dtype=float)[:n]
    names = list(b.train.columns)
    xnames = [c for c in names if c.startswith("x")][: X.shape[1]]

    model = RandomForestRegressor(
        n_estimators=50, max_depth=6, random_state=RANDOM_STATE, n_jobs=-1
    )
    model.fit(X, y)
    r = permutation_importance(
        model, X, y, n_repeats=3, random_state=RANDOM_STATE, n_jobs=-1
    )
    order = np.argsort(-r.importances_mean)
    top = [
        {"feature": xnames[i] if i < len(xnames) else f"x{i}", "importance": float(r.importances_mean[i])}
        for i in order[:5]
    ]
    return {
        "n": n,
        "top5_associative": top,
        "warning": (
            "Importancia de permutación / SHAP sobre E[Y|X] es **asociativa**. "
            "No interpreta el efecto de intervenir en X ni el ATE de T. "
            "Para efectos usar DML/CATE (A2/A3) con identificación."
        ),
        "session": "S20",
    }


if __name__ == "__main__":
    import json

    print(json.dumps(run_lab(), indent=2))
