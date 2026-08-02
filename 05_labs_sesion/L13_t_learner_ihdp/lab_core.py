"""L13 — Solo T-learner en real/ihdp (arranca A3)."""

from __future__ import annotations

import sys
from pathlib import Path

import numpy as np

_LABS = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(_LABS))
from lab_harness import ensure_serie_a

ensure_serie_a()

from lib.cate_utils import fit_t_learner, placebo_permute_treatment
from lib.data_io import load_scenario, load_truth
from lib.metrics import pehe
from lib.paths import RANDOM_STATE, SCENARIO_A3


def run_lab() -> dict:
    b = load_scenario(SCENARIO_A3)
    y_tr, t_tr, X_tr = b.ytx("train")
    y_te, t_te, X_te = b.ytx("test")

    model = fit_t_learner(y_tr, t_tr, X_tr, random_state=RANDOM_STATE)
    tau_hat = np.asarray(model.predict(X_te), dtype=float).reshape(-1)

    # Optional PEHE with truth (lab final cell / teaching only)
    truth = load_truth(SCENARIO_A3, "test")
    tau_true = truth["tau"].to_numpy(dtype=float)
    pehe_val = float(pehe(tau_hat, tau_true))

    placebo = placebo_permute_treatment(
        y_tr, t_tr, X_tr, learner="t", random_state=RANDOM_STATE + 7
    )

    return {
        "scenario": SCENARIO_A3,
        "n_train": int(len(y_tr)),
        "n_test": int(len(y_te)),
        "n_features": int(X_tr.shape[1]),
        "mean_tau_hat": float(np.mean(tau_hat)),
        "std_tau_hat": float(np.std(tau_hat)),
        "pehe_test": pehe_val,
        "placebo_ate": float(placebo["ate_placebo"]),
        "method_selected": "t_learner",
        "feeds": "A3 (meta-learners + scores for A4)",
    }


if __name__ == "__main__":
    import json

    print(json.dumps(run_lab(), indent=2))
