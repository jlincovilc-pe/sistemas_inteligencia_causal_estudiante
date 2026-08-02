from __future__ import annotations

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from lab_core import run_lab


def test_three_cases():
    out = run_lab()
    assert out["n_cases"] == 3
    assert out["spurious_corr_large"] is True
    assert out["simpson_present"] is True
    assert abs(out["cases"][0]["corr_after_temp"]) < abs(out["cases"][0]["corr_raw"])


if __name__ == "__main__":
    test_three_cases()
    print("L01 OK")
