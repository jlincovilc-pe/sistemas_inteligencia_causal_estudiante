"""Smoke checks L10."""

from __future__ import annotations

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from lab_core import run_lab


def test_plr_ate_reasonable():
    out = run_lab()
    assert 2.5 < out["ate"] < 5.5
    assert out["n"] == 1200
    if out["ci_low"] is not None and out["ci_high"] is not None:
        assert out["ci_low"] < out["ate"] < out["ci_high"]


if __name__ == "__main__":
    test_plr_ate_reasonable()
    print("L10 OK")
