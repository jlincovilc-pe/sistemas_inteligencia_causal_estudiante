"""L08 — Detectar fuga causal en un pipeline roto (alimenta A2)."""

from __future__ import annotations

import sys
from pathlib import Path
from typing import List, Tuple

import numpy as np
import pandas as pd

_LABS = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(_LABS))
from lab_harness import ensure_serie_a

ensure_serie_a()

from lib.data_io import load_scenario
from lib.paths import SCENARIO_A2


def build_leaky_and_clean_frames() -> Tuple[pd.DataFrame, pd.DataFrame, List[str], List[str]]:
    """Create a intentionally leaky feature set vs clean covariates."""
    b = load_scenario(SCENARIO_A2)
    train = b.train.copy()
    y = train["outcome"]
    t = train["treatment"]
    x_cols = [c for c in train.columns if c.startswith("x")]
    clean = train[x_cols].copy()

    leaky = clean.copy()
    # LEAK 1: post-treatment style — function of Y (never allowed as control)
    leaky["leak_outcome"] = y.to_numpy()
    # LEAK 2: almost-perfect propensity of treatment itself
    leaky["leak_treatment"] = t.to_numpy().astype(float)
    # LEAK 3: interaction Y*T
    leaky["leak_yt"] = y.to_numpy() * t.to_numpy()

    leak_names = ["leak_outcome", "leak_treatment", "leak_yt"]
    return clean, leaky, x_cols, leak_names


def detect_leaks(columns: List[str]) -> List[str]:
    """Rule-based detector for the planted leak column names."""
    banned_substrings = ("leak_", "outcome", "re78", "y0", "y1", "tau")
    # only flag columns that are clearly post-outcome / treatment copies for this lab
    found = []
    for c in columns:
        cl = c.lower()
        if cl.startswith("leak_"):
            found.append(c)
        elif cl in ("outcome", "re78", "treatment") and c not in (
            # treatment is the treatment variable, not a covariate — still not an X control
        ):
            pass
    return found


def naive_r2(y: np.ndarray, X: np.ndarray) -> float:
    from sklearn.linear_model import LinearRegression

    reg = LinearRegression().fit(X, y)
    return float(reg.score(X, y))


def run_lab() -> dict:
    clean, leaky, x_cols, leak_names = build_leaky_and_clean_frames()
    b = load_scenario(SCENARIO_A2)
    y = b.train["outcome"].to_numpy(dtype=float)
    r2_clean = naive_r2(y, clean.to_numpy(dtype=float))
    r2_leaky = naive_r2(y, leaky.to_numpy(dtype=float))
    detected = detect_leaks(list(leaky.columns))
    return {
        "n_clean_features": len(x_cols),
        "n_leaky_features": leaky.shape[1],
        "planted_leaks": leak_names,
        "detected_leaks": detected,
        "r2_clean": r2_clean,
        "r2_leaky": r2_leaky,
        "leakage_inflates_r2": r2_leaky > r2_clean + 0.05,
        "lesson": (
            "No usar Y, y0/y1/tau, ni funciones del outcome como 'features' de control; "
            "tampoco el propio T como covariable de ajuste en el sentido de X."
        ),
    }


if __name__ == "__main__":
    import json

    print(json.dumps(run_lab(), indent=2, default=str))
