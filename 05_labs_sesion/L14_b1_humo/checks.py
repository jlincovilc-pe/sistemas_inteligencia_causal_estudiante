"""Smoke checks L14."""

from __future__ import annotations

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from lab_core import run_lab


def test_b1_humo():
    out = run_lab()
    assert out["humo_ok"] is True
    assert 3.0 < float(out["ate"]) < 4.5


if __name__ == "__main__":
    test_b1_humo()
    print("L14 OK")
