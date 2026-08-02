"""L17 — Esqueleto de model card causal (prep B2)."""

from __future__ import annotations

import json
import re
import sys
from pathlib import Path

_LABS = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(_LABS))
from lab_harness import REPO_ROOT, SERIE_A


REQUIRED_SECTIONS = [
    "estimando",
    "supuesto",  # supuestos
    "poblaci",  # población
    "límite",  # límites / sintético
]


def load_reference_card() -> str:
    p = (
        REPO_ROOT
        / "04_notebooks_produccion_hf"
        / "B2_hub_cicd"
        / "model_card"
        / "MODEL_CARD.md"
    )
    if p.is_file():
        return p.read_text(encoding="utf-8")
    # fallback from A2 meta
    return "# Model card\n\nEstimando ATE\nSupuestos\nPoblación train\nLímites sintéticos\n"


def score_card(text: str) -> dict:
    low = text.lower()
    hits = {s: (s in low or s.replace("ó", "o") in low) for s in REQUIRED_SECTIONS}
    # accents variants
    if "limite" in low or "sintético" in low or "sintetico" in low:
        hits["límite"] = True
    if "poblacion" in low or "train" in low:
        hits["poblaci"] = True
    if "supuestos" in low or "ignorabilidad" in low or "sutva" in low:
        hits["supuesto"] = True
    return {
        "hits": hits,
        "n_hits": sum(1 for v in hits.values() if v),
        "n_required": len(REQUIRED_SECTIONS),
        "complete": all(hits.values()),
    }


def a2_numbers() -> dict:
    meta_p = SERIE_A / "artifacts" / "A2" / "training_meta.json"
    if not meta_p.is_file():
        return {}
    return json.loads(meta_p.read_text(encoding="utf-8"))


def run_lab() -> dict:
    card = load_reference_card()
    sc = score_card(card)
    meta = a2_numbers()
    return {
        "card_chars": len(card),
        "score": sc,
        "a2_ate": meta.get("ate_point_estimate"),
        "a2_scenario": meta.get("scenario_id"),
        "feeds": "B2 MODEL_CARD.md",
        "session": "S17",
    }


if __name__ == "__main__":
    print(json.dumps(run_lab(), indent=2, default=str))
