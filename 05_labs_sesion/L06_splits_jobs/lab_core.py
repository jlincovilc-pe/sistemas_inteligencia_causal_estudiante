"""L06 — Splits oficiales y diseño de muestreo (cierra A1)."""

from __future__ import annotations

import json
import sys
from pathlib import Path
from typing import Dict

_LABS = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(_LABS))
from lab_harness import ensure_serie_a

ensure_serie_a()

from lib.data_io import load_scenario
from lib.paths import SCENARIO_A1, scenario_dir


def split_sizes() -> Dict[str, int]:
    b = load_scenario(SCENARIO_A1)
    return {
        "train": len(b.train),
        "validation": len(b.validation),
        "test": len(b.test),
        "total": len(b.train) + len(b.validation) + len(b.test),
    }


def load_splits_json() -> dict:
    p = scenario_dir(SCENARIO_A1) / "splits.json"
    if not p.is_file():
        return {}
    return json.loads(p.read_text(encoding="utf-8"))


def no_row_id_overlap() -> bool:
    b = load_scenario(SCENARIO_A1)
    if "row_id" not in b.train.columns:
        return True
    a, v, t = set(b.train.row_id), set(b.validation.row_id), set(b.test.row_id)
    return a.isdisjoint(v) and a.isdisjoint(t) and v.isdisjoint(t)


def run_lab() -> dict:
    sizes = split_sizes()
    bundle = load_scenario(SCENARIO_A1)
    meta = dict(bundle.meta or {})
    sid = meta.get("scenario_id") or meta.get("name") or bundle.scenario_id or SCENARIO_A1
    return {
        "sizes": sizes,
        "official_total": 1722,
        "matches_official": sizes["total"] == 1722,
        "no_overlap": no_row_id_overlap(),
        "scenario_id": sid,
        "splits_json_keys": list(load_splits_json().keys()),
        "design_note": (
            "Usar splits oficiales del monorepo; no re-particionar al azar "
            "para entregas A1 (reproducibilidad y autograder)."
        ),
    }


if __name__ == "__main__":
    print(json.dumps(run_lab(), indent=2, default=str))
