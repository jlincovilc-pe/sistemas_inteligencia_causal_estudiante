from __future__ import annotations

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from lab_core import run_lab


def test_gha_workflow():
    out = run_lab()
    assert out["found"] is True
    assert out["validation"]["ok"] is True


if __name__ == "__main__":
    test_gha_workflow()
    print("L18 OK")
