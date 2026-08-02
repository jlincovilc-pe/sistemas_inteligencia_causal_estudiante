"""L22 — Política top-k B=20% sobre scores CATE (A3 → A4)."""

from __future__ import annotations

import sys
from pathlib import Path

import numpy as np
import pandas as pd

_LABS = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(_LABS))
from lab_harness import SERIE_A, ensure_serie_a

ensure_serie_a()

from lib.cate_utils import fit_t_learner
from lib.data_io import load_scenario, load_truth
from lib.paths import RANDOM_STATE, SCENARIO_A3
from lib.policy_utils import (
    make_threshold_policy,
    policy_value_from_tau,
    random_policy,
)


def load_scores() -> tuple[np.ndarray, np.ndarray, np.ndarray, list]:
    """Prefer A3 artifact; else recompute T-learner on train → score test."""
    scores_path = SERIE_A / "artifacts" / "A3" / "cate_scores_test.csv"
    b = load_scenario(SCENARIO_A3)
    y_te, t_te, X_te = b.ytx("test")
    names = list(X_te.columns)

    if scores_path.is_file():
        df = pd.read_csv(scores_path)
        # prefer method_selected column
        if "method_selected" in df.columns:
            method = str(df["method_selected"].iloc[0])
            col = f"tau_hat_{method}" if f"tau_hat_{method}" in df.columns else None
            if col is None:
                # try tau_hat_t_learner
                col = "tau_hat_t_learner" if "tau_hat_t_learner" in df.columns else None
            if col is None:
                tau_cols = [c for c in df.columns if c.startswith("tau_hat")]
                col = tau_cols[0]
        else:
            tau_cols = [c for c in df.columns if c.startswith("tau_hat")]
            col = tau_cols[0]
            method = col.replace("tau_hat_", "")
        scores = df[col].to_numpy(dtype=float)
        return scores, y_te.to_numpy(), t_te.to_numpy(), names

    y_tr, t_tr, X_tr = b.ytx("train")
    model = fit_t_learner(y_tr, t_tr, X_tr, random_state=RANDOM_STATE)
    scores = np.asarray(model.predict(X_te), dtype=float).reshape(-1)
    return scores, y_te.to_numpy(), t_te.to_numpy(), names


def run_lab() -> dict:
    scores, y_te, t_te, names = load_scores()
    B = 0.20
    policy = make_threshold_policy(
        scores,
        budget_fraction=B,
        mode="topk",
        method_name="t_learner",
        feature_names=names,
    )
    out = policy.predict(scores=scores)
    decision = out["decision"].astype(int)
    treat_rate = float(decision.mean())

    # Oracle welfare if truth available
    truth = load_truth(SCENARIO_A3, "test")
    tau = truth["tau"].to_numpy(dtype=float)
    val_pi = policy_value_from_tau(decision, tau)
    rng_dec = random_policy(len(scores), B, random_state=RANDOM_STATE)
    val_rand = policy_value_from_tau(rng_dec, tau)

    return {
        "budget_fraction": B,
        "threshold": float(policy.threshold),
        "treat_rate": treat_rate,
        "treat_rate_ok": abs(treat_rate - B) <= 0.02 + 1e-9,
        "welfare_pi": float(val_pi),
        "welfare_random": float(val_rand),
        "beats_random": val_pi >= val_rand - 1e-9,
        "n": int(len(scores)),
        "feeds": "A4 policy.joblib / B3",
    }


if __name__ == "__main__":
    import json

    print(json.dumps(run_lab(), indent=2))
