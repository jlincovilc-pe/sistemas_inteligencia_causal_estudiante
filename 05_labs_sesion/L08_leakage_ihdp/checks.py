"""Smoke checks L08."""

from __future__ import annotations

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from lab_core import detect_leaks, run_lab


def test_leakage_detected():
    out = run_lab()
    assert out["leakage_inflates_r2"] is True
    assert set(out["planted_leaks"]).issubset(set(out["detected_leaks"]))
    assert len(detect_leaks(out["detected_leaks"])) >= 3


if __name__ == "__main__":
    test_leakage_detected()
    print("L08 OK")
