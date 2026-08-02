"""Smoke checks L09."""

from __future__ import annotations

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from lab_core import run_lab


def test_residuals_partialling():
    out = run_lab()
    assert abs(out["mean_y_res"]) < 0.5
    assert abs(out["mean_t_res"]) < 0.05
    # ATE on IHDP medium scale
    assert 2.0 < out["ate_partialling"] < 6.0


if __name__ == "__main__":
    test_residuals_partialling()
    print("L09 OK")
