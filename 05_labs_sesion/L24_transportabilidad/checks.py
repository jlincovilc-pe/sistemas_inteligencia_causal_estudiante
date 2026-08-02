from __future__ import annotations

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from lab_core import run_lab


def test_transport_lab():
    out = run_lab()
    assert out["n_checklist"] >= 6
    assert out["toy"]["difference"] > 0.3
    assert out["all_risks_score"]["transport_cautious"] is True


if __name__ == "__main__":
    test_transport_lab()
    print("L24 OK")
