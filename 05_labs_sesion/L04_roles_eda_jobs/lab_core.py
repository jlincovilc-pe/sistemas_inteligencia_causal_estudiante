"""L04 — Roles T/Y/X y EDA causal en Jobs (alimenta A1)."""

from __future__ import annotations

import sys
from pathlib import Path
from typing import Dict, List, Tuple

import pandas as pd

_LABS = Path(__file__).resolve().parents[1]
if str(_LABS) not in sys.path:
    sys.path.insert(0, str(_LABS))

from lab_harness import ensure_serie_a  # noqa: E402

ensure_serie_a()

from lib.data_io import load_scenario  # noqa: E402
from lib.identification import balance_table  # noqa: E402
from lib.paths import SCENARIO_A1  # noqa: E402

SCENARIO = SCENARIO_A1  # real/jobs
TREATMENT = "treatment"
OUTCOME = "re78"
COVARIATES = [
    "age",
    "educ",
    "black",
    "hispan",
    "married",
    "nodegree",
    "re74",
    "re75",
]


def load_jobs_train() -> Tuple[pd.DataFrame, str, str, List[str]]:
    bundle = load_scenario(SCENARIO)
    return bundle.train, TREATMENT, OUTCOME, list(COVARIATES)


def role_table(columns: List[str], t: str, y: str, x: List[str]) -> pd.DataFrame:
    """Assign each column a role: treatment / outcome / covariate / other."""
    roles = []
    for c in columns:
        if c == t:
            role = "treatment"
        elif c == y:
            role = "outcome"
        elif c in x:
            role = "covariate"
        elif c in ("row_id",):
            role = "id"
        else:
            role = "other"
        roles.append({"column": c, "role": role})
    return pd.DataFrame(roles)


def treatment_rate(df: pd.DataFrame, t: str) -> float:
    return float(df[t].mean())


def mean_outcome_by_treatment(df: pd.DataFrame, t: str, y: str) -> Dict[str, float]:
    g = df.groupby(t)[y].mean()
    return {str(k): float(v) for k, v in g.items()}


def covariate_balance(df: pd.DataFrame, t: str, x: List[str]) -> pd.DataFrame:
    T = df[t].to_numpy()
    X = df[x]
    return balance_table(X, T, covariates=x)


def run_lab() -> dict:
    df, t, y, x = load_jobs_train()
    roles = role_table(list(df.columns), t, y, x)
    bal = covariate_balance(df, t, x)
    return {
        "n": len(df),
        "n_covariates": len(x),
        "treatment_rate": treatment_rate(df, t),
        "mean_y_by_t": mean_outcome_by_treatment(df, t, y),
        "n_roles": len(roles),
        "n_covariate_roles": int((roles["role"] == "covariate").sum()),
        "balance_rows": len(bal),
        "scenario": SCENARIO,
    }


if __name__ == "__main__":
    import json

    print(json.dumps(run_lab(), indent=2, default=str))
