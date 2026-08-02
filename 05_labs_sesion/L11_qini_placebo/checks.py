"""Smoke checks L11."""

from __future__ import annotations

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from lab_core import run_lab


def test_qini_and_placebo():
    out = run_lab()
    assert np_isfinite(out["qini_auc"])
    # Placebo ATE should be smaller in magnitude than typical CATE mean (~4)
    assert abs(out["placebo_ate"]) < 2.5
    assert out["n_val"] == 400


def np_isfinite(x):
    import math

    return math.isfinite(float(x))


if __name__ == "__main__":
    test_qini_and_placebo()
    print("L11 OK")
