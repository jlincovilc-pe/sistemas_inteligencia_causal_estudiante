"""Smoke checks L13."""

from __future__ import annotations

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from lab_core import run_lab


def test_t_learner_ihdp():
    out = run_lab()
    assert out["n_train"] == 448
    assert out["n_test"] == 150
    assert out["n_features"] == 25
    # CATE mean near ATE ~4
    assert 1.0 < out["mean_tau_hat"] < 10.0
    # PEHE ceiling (scorecard ~3.9)
    assert out["pehe_test"] < 10.0
    assert abs(out["placebo_ate"]) < 2.0
    assert out["method_selected"] == "t_learner"


if __name__ == "__main__":
    test_t_learner_ihdp()
    print("L13 OK")
