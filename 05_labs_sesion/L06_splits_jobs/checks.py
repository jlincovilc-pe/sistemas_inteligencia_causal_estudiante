"""Smoke checks L06."""

from __future__ import annotations

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from lab_core import no_row_id_overlap, run_lab, split_sizes


def test_official_splits():
    s = split_sizes()
    assert s["train"] == 1033
    assert s["validation"] == 344
    assert s["test"] == 345
    assert s["total"] == 1722
    assert no_row_id_overlap()
    out = run_lab()
    assert out["matches_official"] is True
    assert out["no_overlap"] is True


if __name__ == "__main__":
    test_official_splits()
    print("L06 OK")
