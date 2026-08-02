"""L19 — Explicación causal vs asociativa (casos)."""

from __future__ import annotations

from typing import Dict, List

CASES: List[Dict] = [
    {
        "id": "c1",
        "claim": "El modelo SHAP dice que 'edad' es la feature más importante para predecir Y",
        "kind": "asociativa",
        "why": "Importancia predictiva ≠ efecto causal de intervenir en edad",
    },
    {
        "id": "c2",
        "claim": "El ATE de DML estima E[Y|do(T=1)] - E[Y|do(T=0)] bajo supuestos declarados",
        "kind": "causal",
        "why": "Estimando intervencional con identificación explícita",
    },
    {
        "id": "c3",
        "claim": "Las unidades con alto risk score deberían recibir el tratamiento",
        "kind": "asociativa",
        "why": "Riesgo predictivo no es uplift causal (ver policy/CATE)",
    },
    {
        "id": "c4",
        "claim": "La política top-k usa τ̂(x) para maximizar bienestar bajo presupuesto",
        "kind": "causal",
        "why": "Ranking por efecto heterogéneo estimado (A4)",
    },
    {
        "id": "c5",
        "claim": "Correlación educación-ingresos justifica subvencionar educación",
        "kind": "asociativa",
        "why": "Sin identificación, correlación no autoriza intervención",
    },
]


def score_answers(answers: Dict[str, str]) -> dict:
    correct = 0
    wrong = []
    for c in CASES:
        a = (answers.get(c["id"]) or "").lower().strip()
        if a.startswith(c["kind"][:4]):  # causal / asoc
            correct += 1
        else:
            wrong.append(c["id"])
    return {"correct": correct, "total": len(CASES), "wrong": wrong}


def run_lab() -> dict:
    ref = {c["id"]: c["kind"] for c in CASES}
    sc = score_answers(ref)
    return {
        "n_cases": len(CASES),
        "reference_perfect": sc["correct"] == sc["total"],
        "cases": CASES,
        "session": "S19",
    }


if __name__ == "__main__":
    import json

    print(json.dumps(run_lab(), indent=2, ensure_ascii=False))
