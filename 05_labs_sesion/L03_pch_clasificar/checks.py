from __future__ import annotations

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from lab_core import QUESTIONS, classify, reference_answers, run_lab


def test_pch_bank():
    assert len(QUESTIONS) == 10
    out = run_lab()
    assert out["perfect_reference"] is True
    assert out["counts_by_level"][1] >= 3
    assert out["counts_by_level"][2] >= 2
    assert out["counts_by_level"][3] >= 2
    # intentional mistake
    bad = reference_answers()
    bad["q1"] = 3
    c, t, w = classify(bad)
    assert c == t - 1
    assert "q1" in w


if __name__ == "__main__":
    test_pch_bank()
    print("L03 OK")
