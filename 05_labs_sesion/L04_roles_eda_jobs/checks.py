"""Smoke checks L04."""

from __future__ import annotations

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from lab_core import (  # noqa: E402
    COVARIATES,
    load_jobs_train,
    role_table,
    run_lab,
    treatment_rate,
)


def test_roles_and_eda():
    df, t, y, x = load_jobs_train()
    assert t == "treatment" and y == "re78"
    assert len(x) == 8
    roles = role_table(list(df.columns), t, y, x)
    assert set(roles.loc[roles["role"] == "covariate", "column"]) == set(COVARIATES)
    tr = treatment_rate(df, t)
    assert 0.05 < tr < 0.6
    out = run_lab()
    assert out["n"] == 1033  # official train
    assert out["n_covariate_roles"] == 8
    assert out["balance_rows"] == 8


if __name__ == "__main__":
    test_roles_and_eda()
    print("L04 OK")
