from __future__ import annotations

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from lab_core import run_lab, score_card


def test_model_card_sections():
    out = run_lab()
    assert out["score"]["complete"] is True
    assert out["card_chars"] > 500
    # incomplete card fails
    bad = score_card("# hola accuracy only")
    assert bad["complete"] is False


if __name__ == "__main__":
    test_model_card_sections()
    print("L17 OK")
