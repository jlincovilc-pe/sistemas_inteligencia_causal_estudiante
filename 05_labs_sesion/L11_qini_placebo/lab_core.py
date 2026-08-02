"""L11 — Qini + placebo en miniatura."""

from __future__ import annotations

import sys
from pathlib import Path

import numpy as np

_LABS = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(_LABS))
from lab_harness import ensure_serie_a

ensure_serie_a()

from lib.cate_utils import fit_t_learner, placebo_permute_treatment
from lib.data_io import load_scenario
from lib.metrics import qini_auc, qini_curve
from lib.paths import RANDOM_STATE, SCENARIO_A2


def run_lab() -> dict:
    b = load_scenario(SCENARIO_A2)
    y_tr, t_tr, X_tr = b.ytx("train")
    y_va, t_va, X_va = b.ytx("validation")

    model = fit_t_learner(y_tr, t_tr, X_tr, random_state=RANDOM_STATE)
    scores = np.asarray(model.predict(X_va), dtype=float).reshape(-1)

    curve = qini_curve(y_va, t_va, scores)
    auc = qini_auc(curve)

    placebo = placebo_permute_treatment(
        y_tr, t_tr, X_tr, learner="t", random_state=RANDOM_STATE + 1
    )
    return {
        "qini_auc": float(auc),
        "placebo_ate": float(placebo["ate_placebo"]),
        "mean_score_val": float(np.mean(scores)),
        "n_train": int(len(y_tr)),
        "n_val": int(len(y_va)),
    }


if __name__ == "__main__":
    import json

    print(json.dumps(run_lab(), indent=2, default=str))
