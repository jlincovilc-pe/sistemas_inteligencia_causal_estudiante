from __future__ import annotations

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from lab_core import run_lab, score_pager


def test_one_pager():
    out = run_lab()
    assert out["score"]["complete"] is True
    assert "sintético" in out["pager"]["who_it_applies_to"].lower() or "synthetic" in out["pager"]["who_it_applies_to"].lower() or "scenario" in out["pager"]["who_it_applies_to"].lower()
    assert score_pager({"headline": "x"})["complete"] is False


if __name__ == "__main__":
    test_one_pager()
    print("L28 OK")
