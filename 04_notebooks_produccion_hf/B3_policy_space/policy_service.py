"""Kernel-less policy API for tests/autograder (no Gradio required)."""

from __future__ import annotations

import os
import sys
from pathlib import Path
from typing import Any, Dict, List, Mapping, Optional, Sequence, Union

import numpy as np

B3_ROOT = Path(__file__).resolve().parent
REPO = B3_ROOT.parents[1]
SERIE_A = REPO / "03_notebooks_caso_estudio"
if str(SERIE_A) not in sys.path:
    sys.path.insert(0, str(SERIE_A))

ARTIFACTS = Path(os.environ.get("B3_ARTIFACTS_DIR", B3_ROOT / "artifacts"))


def load_policy(path: Optional[Path] = None):
    from lib.policy_utils import load_policy as _load

    p = Path(path) if path is not None else ARTIFACTS / "policy.joblib"
    return _load(p)


def predict_rows(
    policy,
    rows: Union[Mapping[str, float], Sequence[Mapping[str, float]], np.ndarray],
) -> Dict[str, Any]:
    names = list(policy.feature_names or [])
    if isinstance(rows, np.ndarray):
        X = np.asarray(rows, dtype=float)
        if X.ndim == 1:
            X = X.reshape(1, -1)
    elif isinstance(rows, Mapping):
        X = np.asarray([[float(rows[n]) for n in names]], dtype=float)
    else:
        X = np.asarray([[float(r[n]) for n in names] for r in rows], dtype=float)
    out = policy.predict(X=X)
    return {
        "decision": np.asarray(out["decision"], dtype=int).reshape(-1),
        "uplift_score": np.asarray(out["uplift_score"], dtype=float).reshape(-1),
        "threshold": float(policy.threshold),
        "budget_fraction": float(policy.budget_fraction),
    }


def smoke_three_cases(policy) -> List[Dict[str, Any]]:
    """Three fixed cases for humo (zeros, ones, mixed)."""
    names = list(policy.feature_names or [])
    p = len(names)
    cases = [
        np.zeros(p),
        np.ones(p),
        np.linspace(-1.0, 1.0, p),
    ]
    results = []
    for i, x in enumerate(cases):
        out = predict_rows(policy, x.reshape(1, -1))
        results.append(
            {
                "case": i,
                "decision": int(out["decision"][0]),
                "uplift_score": float(out["uplift_score"][0]),
            }
        )
    return results
