"""Shared path / import harness for session labs (kernel-less)."""

from __future__ import annotations

import sys
from pathlib import Path

LABS_ROOT = Path(__file__).resolve().parent
REPO_ROOT = LABS_ROOT.parent
SERIE_A = REPO_ROOT / "03_notebooks_caso_estudio"
SERIE_B = REPO_ROOT / "04_notebooks_produccion_hf"


def ensure_serie_a() -> Path:
    s = str(SERIE_A.resolve())
    if s not in sys.path:
        sys.path.insert(0, s)
    return SERIE_A


def ensure_b1() -> Path:
    b1 = SERIE_B / "B1_fastapi_dml"
    s = str(b1.resolve())
    if s not in sys.path:
        sys.path.insert(0, s)
    return b1


def ensure_serie_a_lib():
    ensure_serie_a()
    from lib.paths import RANDOM_STATE, DATA_ROOT, SCENARIO_A1, SCENARIO_A2

    return RANDOM_STATE, DATA_ROOT, SCENARIO_A1, SCENARIO_A2
