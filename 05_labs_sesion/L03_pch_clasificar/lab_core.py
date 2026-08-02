"""L03 — Clasificar preguntas en la Jerarquía Causal de Pearl (PCH)."""

from __future__ import annotations

from typing import Dict, List, Tuple

# level: 1 association, 2 intervention, 3 counterfactual
QUESTIONS: List[Dict] = [
    {
        "id": "q1",
        "text": "¿Cuál es la correlación entre educación e ingresos?",
        "level": 1,
        "label": "asociación",
    },
    {
        "id": "q2",
        "text": "Si obligamos a todos a completar un año más de educación, ¿cuánto suben los ingresos medios?",
        "level": 2,
        "label": "intervención",
    },
    {
        "id": "q3",
        "text": "¿Habría sobrevivido este paciente si no le hubiéramos dado el fármaco?",
        "level": 3,
        "label": "contrafactual",
    },
    {
        "id": "q4",
        "text": "¿Qué variables predicen mejor el default crediticio?",
        "level": 1,
        "label": "asociación",
    },
    {
        "id": "q5",
        "text": "¿Cuál es el ATE de un programa de empleo sobre re78?",
        "level": 2,
        "label": "intervención",
    },
    {
        "id": "q6",
        "text": "Dado que la unidad fue tratada y Y=y, ¿qué valor habría tomado Y sin tratamiento?",
        "level": 3,
        "label": "contrafactual",
    },
    {
        "id": "q7",
        "text": "E[Y | T=1, X=x]",
        "level": 1,
        "label": "asociación",
    },
    {
        "id": "q8",
        "text": "E[Y | do(T=1), X=x]",
        "level": 2,
        "label": "intervención",
    },
    {
        "id": "q9",
        "text": "Y_x(u) vs Y_{x'}(u) para la misma unidad u",
        "level": 3,
        "label": "contrafactual",
    },
    {
        "id": "q10",
        "text": "¿El modelo de churn tiene buen AUC?",
        "level": 1,
        "label": "asociación",
    },
]


def classify(answers: Dict[str, int]) -> Tuple[int, int, List[str]]:
    """Score student answers {qid: level}."""
    correct = 0
    wrong = []
    for q in QUESTIONS:
        a = answers.get(q["id"])
        if a == q["level"]:
            correct += 1
        else:
            wrong.append(q["id"])
    return correct, len(QUESTIONS), wrong


def reference_answers() -> Dict[str, int]:
    return {q["id"]: q["level"] for q in QUESTIONS}


def run_lab() -> dict:
    ans = reference_answers()
    correct, total, wrong = classify(ans)
    counts = {1: 0, 2: 0, 3: 0}
    for q in QUESTIONS:
        counts[q["level"]] += 1
    return {
        "n_questions": total,
        "reference_score": correct,
        "perfect_reference": correct == total and not wrong,
        "counts_by_level": counts,
        "session": "S3",
        "feeds": "A1 (formular pregunta causal antes de estimar)",
    }


if __name__ == "__main__":
    import json

    print(json.dumps(run_lab(), indent=2))
