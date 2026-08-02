"""L28 — Comunicar un ATE a audiencia no técnica (1 página estructurada)."""

from __future__ import annotations

import json
import sys
from pathlib import Path

_LABS = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(_LABS))
from lab_harness import SERIE_A


TEMPLATE_SECTIONS = [
    "headline",
    "what_we_estimated",
    "number",
    "uncertainty",
    "assumptions_plain",
    "who_it_applies_to",
    "what_it_is_not",
    "next_step",
]


def load_a2_ate() -> dict:
    p = SERIE_A / "artifacts" / "A2" / "training_meta.json"
    if not p.is_file():
        return {"ate": 3.53, "ci_low": 2.89, "ci_high": 4.17, "scenario_id": "demo"}
    m = json.loads(p.read_text(encoding="utf-8"))
    return {
        "ate": m.get("ate_point_estimate"),
        "ci_low": m.get("ci_low"),
        "ci_high": m.get("ci_high"),
        "scenario_id": m.get("scenario_id"),
        "se": m.get("se"),
    }


def build_one_pager(stats: dict) -> dict:
    ate = stats["ate"]
    lo, hi = stats.get("ci_low"), stats.get("ci_high")
    return {
        "headline": "Efecto medio estimado del programa (ATE)",
        "what_we_estimated": (
            "Comparamos el resultado medio si tratáramos a todos vs a ninguno, "
            "ajustando por características observables, en un ejercicio docente."
        ),
        "number": f"El efecto medio estimado es aproximadamente {ate:.2f} unidades del outcome.",
        "uncertainty": (
            f"Un intervalo de confianza del 95% va de {lo:.2f} a {hi:.2f}."
            if lo is not None and hi is not None
            else "La incertidumbre no está reportada."
        ),
        "assumptions_plain": (
            "Esto vale si no quedan confusores importantes sin medir, si hay solapamiento "
            "entre tratados y controles, y si no hay interferencia entre personas."
        ),
        "who_it_applies_to": (
            f"Población del escenario {stats.get('scenario_id')} (datos sintéticos de entrenamiento)."
        ),
        "what_it_is_not": (
            "No es una predicción individual, no es un resultado clínico real, "
            "y no autoriza desplegar el programa sin validación externa."
        ),
        "next_step": (
            "Revisar la model card (B2), el monitoreo de drift (B4) y si el efecto "
            "transporta a la población objetivo (L24)."
        ),
    }


def score_pager(pager: dict) -> dict:
    missing = [k for k in TEMPLATE_SECTIONS if not str(pager.get(k, "")).strip()]
    return {
        "complete": len(missing) == 0,
        "missing": missing,
        "n_sections": len(TEMPLATE_SECTIONS),
    }


def run_lab() -> dict:
    stats = load_a2_ate()
    pager = build_one_pager(stats)
    sc = score_pager(pager)
    return {
        "stats": stats,
        "pager": pager,
        "score": sc,
        "session": "S28",
        "feeds": "B4 entrega / comunicación responsable",
    }


if __name__ == "__main__":
    print(json.dumps(run_lab(), indent=2, ensure_ascii=False))
