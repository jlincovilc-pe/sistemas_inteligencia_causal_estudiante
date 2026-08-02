"""Smoke checks L12."""

from __future__ import annotations

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from lab_core import run_lab, stub_predict, zero_features


def test_stub_matches_a2():
    out = run_lab()
    assert out["matches_meta_ate"] is True
    p = out["predict"]
    assert 3.0 < p["ate"] < 4.5
    assert p["n"] == 1
    # second call
    p2 = stub_predict(zero_features())
    assert abs(p2["effect"] - p["ate"]) < 1e-9


if __name__ == "__main__":
    test_stub_matches_a2()
    print("L12 OK")
