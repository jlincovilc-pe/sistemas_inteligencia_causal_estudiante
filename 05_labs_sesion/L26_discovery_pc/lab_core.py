"""L26 — Descubrimiento estructural ligero (correlación + umbral) en red pequeña.

Nota: PC/NOTEARS completos son opcionales (causal-learn). Aquí recuperamos un
esqueleto por umbral de correlación parcial simple como lab de 45 min.
"""

from __future__ import annotations

import sys
from pathlib import Path

import numpy as np
import pandas as pd

_LABS = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(_LABS))
from lab_harness import ensure_serie_a

ensure_serie_a()

from lib.data_io import load_scenario
from lib.paths import scenario_dir


def correlation_skeleton(X: np.ndarray, thr: float = 0.15) -> np.ndarray:
    """Undirected edges where |corr| > thr (zero diagonal)."""
    C = np.corrcoef(X, rowvar=False)
    np.fill_diagonal(C, 0.0)
    return (np.abs(C) > thr).astype(int)


def load_true_adj_if_any(scenario: str):
    p = scenario_dir(scenario) / "graph_adjmatrix.csv"
    if not p.is_file():
        return None
    df = pd.read_csv(p, index_col=0)
    return df.to_numpy(dtype=float)


def shd_undirected(a: np.ndarray, b: np.ndarray) -> int:
    """Hamming on undirected skeletons."""
    au = np.maximum(a, a.T)
    bu = np.maximum(b, b.T)
    np.fill_diagonal(au, 0)
    np.fill_diagonal(bu, 0)
    return int(np.sum(np.abs(au - bu)) // 2)


def run_lab() -> dict:
    scenario = "synthetic/linear_gaussian/10_vars_10_edges"
    b = load_scenario(scenario)
    X = b.train.drop(columns=[c for c in b.train.columns if c == "row_id"], errors="ignore")
    X = X.select_dtypes(include=[np.number]).to_numpy(dtype=float)
    skel = correlation_skeleton(X, thr=0.12)
    n_edges = int(skel.sum() // 2)
    true = load_true_adj_if_any(scenario)
    out = {
        "scenario": scenario,
        "n_vars": int(X.shape[1]),
        "n_skeleton_edges": n_edges,
        "session": "S26",
        "note": "Esqueleto por correlación — no es PC/NOTEARS; para SOTA usar causal-learn.",
    }
    if true is not None:
        # binarize true
        t = (np.abs(true) > 0).astype(int)
        out["shd_undirected_vs_true"] = shd_undirected(skel, t)
        out["true_edges"] = int(t.sum() // 2) if t.shape[0] == t.shape[1] else int(t.sum())
    return out


if __name__ == "__main__":
    import json

    print(json.dumps(run_lab(), indent=2))
