from __future__ import annotations

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from lab_core import run_lab


def test_perm_importance():
    out = run_lab()
    assert len(out["top5_associative"]) == 5
    assert out["n"] >= 100
    assert "asociativa" in out["warning"].lower() or "asociativ" in out["warning"].lower()


if __name__ == "__main__":
    test_perm_importance()
    print("L20 OK")
