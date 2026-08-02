"""Smoke checks L22."""

from __future__ import annotations

import math
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from lab_core import run_lab


def test_topk_policy():
    out = run_lab()
    assert out["treat_rate_ok"] is True
    assert abs(out["treat_rate"] - 0.20) <= 0.02
    assert out["beats_random"] is True
    assert out["n"] == 150
    assert math.isfinite(out["threshold"])


if __name__ == "__main__":
    test_topk_policy()
    print("L22 OK")
