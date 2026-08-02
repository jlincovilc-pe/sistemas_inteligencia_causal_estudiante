"""L24 — Checklist de transportabilidad entre dominios."""

from __future__ import annotations

from typing import Dict, List


CHECKLIST: List[Dict] = [
    {
        "id": "t1",
        "item": "¿La población objetivo difiere en la distribución de X?",
        "risk_if_yes": "Shift de covariables; reponderar o reestimar",
    },
    {
        "id": "t2",
        "item": "¿Hay confusores en el origen no medidos en el destino?",
        "risk_if_yes": "Identificación puede fallar en el nuevo dominio",
    },
    {
        "id": "t3",
        "item": "¿El soporte de X en destino está cubierto por el origen (overlap)?",
        "risk_if_yes": "Extrapolación; abstenerse o recortar",
    },
    {
        "id": "t4",
        "item": "¿El mecanismo Y|T,X se asume estable (transportabilidad de la respuesta)?",
        "risk_if_yes": "Si no, el ATE no transporta sin ajuste de selección/mecanismo",
    },
    {
        "id": "t5",
        "item": "¿La definición de tratamiento y outcome es la misma?",
        "risk_if_yes": "Incomparabilidad de estimandos",
    },
    {
        "id": "t6",
        "item": "¿Se documentaron límites de validez externa en la model card?",
        "risk_if_yes": "Riesgo de uso indebido del artefacto (B2/B4)",
    },
]


def score_transport(answers: Dict[str, bool]) -> dict:
    """answers: id -> True if risk factor present."""
    risks = [c["id"] for c in CHECKLIST if answers.get(c["id"]) is True]
    return {
        "n_risks": len(risks),
        "risk_ids": risks,
        "transport_cautious": len(risks) >= 2,
    }


def toy_two_populations() -> dict:
    """Synthetic illustration: mean shift in X breaks naive ATE equality claim."""
    import numpy as np

    rng = np.random.default_rng(42)
    # Source: X~N(0,1), Dest: X~N(2,1); effect depends on X
    xs = rng.normal(0, 1, 1000)
    xd = rng.normal(2, 1, 1000)
    # tau(x) = 1 + 0.5*x
    ate_s = float(np.mean(1 + 0.5 * xs))
    ate_d = float(np.mean(1 + 0.5 * xd))
    return {
        "ate_source": ate_s,
        "ate_dest": ate_d,
        "difference": abs(ate_s - ate_d),
        "lesson": "Si τ depende de X y P(X) cambia, el ATE cambia aunque el mecanismo τ(x) sea el mismo",
    }


def run_lab() -> dict:
    # worst-case: all risks flagged
    sc = score_transport({c["id"]: True for c in CHECKLIST})
    toy = toy_two_populations()
    return {
        "n_checklist": len(CHECKLIST),
        "checklist": CHECKLIST,
        "all_risks_score": sc,
        "toy": toy,
        "session": "S24",
    }


if __name__ == "__main__":
    import json

    print(json.dumps(run_lab(), indent=2, ensure_ascii=False))
