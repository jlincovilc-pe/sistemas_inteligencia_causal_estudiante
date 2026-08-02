"""Smoke checks L05."""

from __future__ import annotations

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from lab_core import run_lab


def test_pds_near_lalonde_scale():
    out = run_lab()
    # Jobs synthetic ATE ~1600
    for key in ("ate_dim", "ate_ols", "ate_pds"):
        assert 500 < abs(out[key]) < 5000, (key, out[key])
    assert out["n"] == 1033
    assert out["n_features_expanded"] > out["n_features_raw"]
    # PDS should return a finite ATE
    assert out["ate_pds"] == out["ate_pds"]


if __name__ == "__main__":
    test_pds_near_lalonde_scale()
    print("L05 OK")
