"""Smoke checks L23."""

from __future__ import annotations

import math
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from lab_core import run_lab


def test_uplift_and_b3_smoke():
    out = run_lab()
    assert abs(out["budget_fraction"] - 0.2) < 1e-6
    assert abs(out["treat_rate_test"] - 0.2) <= 0.02
    assert math.isfinite(out["qini_auc"])
    assert len(out["b3_smoke_cases"]) == 3
    for c in out["b3_smoke_cases"]:
        assert c["decision"] in (0, 1)
        assert math.isfinite(c["uplift_score"])
    assert "decision" in out["interface"]


if __name__ == "__main__":
    test_uplift_and_b3_smoke()
    print("L23 OK")
