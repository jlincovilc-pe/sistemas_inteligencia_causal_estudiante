"""Smoke checks L15."""

from __future__ import annotations

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from lab_core import run_lab


def test_integration_checklist():
    out = run_lab()
    assert out["n_ok"] == out["n_items"]
    assert out["all_green"] is True
    assert out["a2_meta"]["ok"] is True
    assert out["a3_scores"]["ok"] is True
    assert len(out["common_bugs"]) >= 4


if __name__ == "__main__":
    test_integration_checklist()
    print("L15 OK")
