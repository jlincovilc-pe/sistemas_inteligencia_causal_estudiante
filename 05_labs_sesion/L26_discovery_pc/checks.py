from __future__ import annotations

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from lab_core import run_lab


def test_discovery_skeleton():
    out = run_lab()
    assert out["n_vars"] == 10
    assert out["n_skeleton_edges"] >= 1
    if "shd_undirected_vs_true" in out:
        assert out["shd_undirected_vs_true"] >= 0


if __name__ == "__main__":
    test_discovery_skeleton()
    print("L26 OK")
