from __future__ import annotations

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from lab_core import run_lab


def test_ks_drift_alerts():
    out = run_lab()
    assert out["alerts_triggered"] is True
    assert out["max_ks_after_drift"] >= out["ks_threshold"]


if __name__ == "__main__":
    test_ks_drift_alerts()
    print("L25 OK")
