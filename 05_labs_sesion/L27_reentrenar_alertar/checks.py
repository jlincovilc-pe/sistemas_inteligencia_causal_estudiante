from __future__ import annotations

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from lab_core import run_lab


def test_retrain_policy():
    out = run_lab()
    assert out["expect_retrain"] is True
    assert out["expect_alert_on_spike"] is True
    assert out["sustained_drift"]["action"] == "RETRAIN"
    assert out["single_spike"]["action"] == "ALERT"


if __name__ == "__main__":
    test_retrain_policy()
    print("L27 OK")
