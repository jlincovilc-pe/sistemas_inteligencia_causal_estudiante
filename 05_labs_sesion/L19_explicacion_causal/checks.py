from __future__ import annotations

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from lab_core import CASES, run_lab, score_answers


def test_causal_vs_assoc():
    out = run_lab()
    assert out["n_cases"] == 5
    assert out["reference_perfect"] is True
    bad = score_answers({c["id"]: "asociativa" for c in CASES})
    assert bad["correct"] < bad["total"]


if __name__ == "__main__":
    test_causal_vs_assoc()
    print("L19 OK")
