from __future__ import annotations

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from lab_core import run_lab


def test_latent_vs_jobs():
    out = run_lab()
    assert out["contrast_ok"] is True
    assert out["latent"]["not_identifiable"] is True
    assert out["jobs"]["has_adjustment_set"] is True


if __name__ == "__main__":
    test_latent_vs_jobs()
    print("L07 OK")
