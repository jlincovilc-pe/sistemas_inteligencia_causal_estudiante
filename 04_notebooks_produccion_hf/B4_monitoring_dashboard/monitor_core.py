"""Kernel-less monitoring metrics for B4 tests (no Streamlit)."""

from __future__ import annotations

import sys
from pathlib import Path
from typing import Dict, Tuple

import numpy as np
import pandas as pd
from scipy import stats

B4 = Path(__file__).resolve().parent
REPO = B4.parents[1]
SERIE_A = REPO / "03_notebooks_caso_estudio"
if str(SERIE_A) not in sys.path:
    sys.path.insert(0, str(SERIE_A))

from lib.data_io import load_scenario
from lib.paths import RANDOM_STATE


def baseline_matrices(scenario: str = "synthetic/inference/ihdp_medium"):
    bundle = load_scenario(scenario)
    _, t, X = bundle.ytx("train")
    return X.to_numpy(dtype=float), t.to_numpy(dtype=int), list(X.columns)


def ks_drift_report(
    X_base: np.ndarray,
    X_window: np.ndarray,
    feature_idx: Tuple[int, ...] = (0, 1, 2),
) -> Dict[str, float]:
    out = {}
    for j in feature_idx:
        out[f"ks_f{j}"] = float(stats.ks_2samp(X_base[:, j], X_window[:, j]).statistic)
    out["ks_max"] = float(max(out.values()))
    return out


def simulate_and_count_alerts(
    *,
    n_windows: int = 12,
    window_size: int = 200,
    drift_start: int = 6,
    drift_strength: float = 0.8,
    ks_threshold: float = 0.15,
    seed: int = RANDOM_STATE,
) -> Dict[str, float]:
    X, t, _ = baseline_matrices()
    rng = np.random.default_rng(seed)
    n = X.shape[0]
    alerts = 0
    max_ks_after = 0.0
    for w in range(n_windows):
        idx = rng.integers(0, n, size=window_size)
        Xw = X[idx].copy()
        if w >= drift_start:
            Xw[:, :3] += drift_strength * (w - drift_start + 1)
        base_idx = rng.integers(0, n, size=window_size)
        rep = ks_drift_report(X[base_idx], Xw)
        if rep["ks_max"] >= ks_threshold:
            alerts += 1
        if w >= drift_start:
            max_ks_after = max(max_ks_after, rep["ks_max"])
    return {
        "n_alerts": float(alerts),
        "max_ks_after_drift": max_ks_after,
        "ks_threshold": ks_threshold,
    }
