"""L23 — Uplift curve + stub de decisión (puente A4 → B3)."""

from __future__ import annotations

import sys
from pathlib import Path

import numpy as np

_LABS = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(_LABS))
from lab_harness import REPO_ROOT, SERIE_A, ensure_serie_a

ensure_serie_a()

from lib.data_io import load_scenario
from lib.metrics import qini_auc, qini_curve
from lib.paths import SCENARIO_A3
from lib.policy_utils import load_policy


def _rel_to_repo(path: Path) -> str:
    try:
        return str(path.resolve().relative_to(REPO_ROOT.resolve()))
    except ValueError:
        return str(path)


def load_a4_policy():
    path = SERIE_A / "artifacts" / "A4" / "policy.joblib"
    if not path.is_file():
        # fallback B3 copy
        path = (
            REPO_ROOT
            / "04_notebooks_produccion_hf"
            / "B3_policy_space"
            / "artifacts"
            / "policy.joblib"
        )
    return load_policy(path), path


def run_lab() -> dict:
    policy, path = load_a4_policy()
    b = load_scenario(SCENARIO_A3)
    y_te, t_te, X_te = b.ytx("test")
    X = np.asarray(X_te, dtype=float)

    pred = policy.predict(X=X)
    scores = np.asarray(pred["uplift_score"], dtype=float).reshape(-1)
    decision = np.asarray(pred["decision"], dtype=int).reshape(-1)

    curve = qini_curve(y_te, t_te, scores)
    auc = float(qini_auc(curve))

    # Three smoke cases for B3 (zeros / ones / linspace)
    p = X.shape[1]
    cases = []
    for i, x in enumerate([np.zeros(p), np.ones(p), np.linspace(-1, 1, p)]):
        o = policy.predict(X=x.reshape(1, -1))
        cases.append(
            {
                "case": i,
                "decision": int(o["decision"][0]),
                "uplift_score": float(o["uplift_score"][0]),
            }
        )

    return {
        "policy_path": _rel_to_repo(path),
        "treat_rate_test": float(decision.mean()),
        "budget_fraction": float(policy.budget_fraction),
        "threshold": float(policy.threshold),
        "qini_auc": auc,
        "b3_smoke_cases": cases,
        "interface": "predict(X) -> {decision, uplift_score}",
        "feeds": "B3 Gradio Space",
        "disclaimer": (
            "Política docente sobre datos sintéticos IHDP-style; "
            "no es recomendación clínica."
        ),
    }


if __name__ == "__main__":
    import json

    print(json.dumps(run_lab(), indent=2, default=str))
