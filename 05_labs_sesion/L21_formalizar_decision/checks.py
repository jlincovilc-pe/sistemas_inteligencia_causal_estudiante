"""Smoke checks L21."""

from __future__ import annotations

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from lab_core import reference_ihdp_decision, run_lab


def test_decision_template():
    out = run_lab()
    assert out["valid"] is True
    d = out["decision"]
    assert "20%" in d["constraint"] or "0.2" in d["constraint"] or "B=" in d["constraint"]
    assert "CATE" in d["estimand_link"] or "tau" in d["estimand_link"]
    assert len(reference_ihdp_decision().information_set) >= 3


if __name__ == "__main__":
    test_decision_template()
    print("L21 OK")
