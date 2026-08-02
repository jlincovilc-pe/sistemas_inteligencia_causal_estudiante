"""L01 — Correlación ≠ causación (3 casos + Simpson)."""

from __future__ import annotations

from typing import Dict, List

import numpy as np
import pandas as pd


def case_ice_cream_crime(n: int = 500, seed: int = 42) -> Dict:
    """Confusor común: temperatura → helados y crimen (simulado)."""
    rng = np.random.default_rng(seed)
    temp = rng.normal(25, 5, n)
    ice = 2.0 * temp + rng.normal(0, 3, n)
    crime = 1.5 * temp + rng.normal(0, 3, n)
    corr = float(np.corrcoef(ice, crime)[0, 1])
    # residualize on temp
    ice_r = ice - np.polyval(np.polyfit(temp, ice, 1), temp)
    crime_r = crime - np.polyval(np.polyfit(temp, crime, 1), temp)
    corr_adj = float(np.corrcoef(ice_r, crime_r)[0, 1])
    return {
        "name": "ice_cream_crime",
        "corr_raw": corr,
        "corr_after_temp": corr_adj,
        "lesson": "Confusor (temperatura) induce correlación espuria",
    }


def case_simpson_admission(seed: int = 42) -> Dict:
    """Paradoja de Simpson: agregación invierte la asociación.

    Dentro de cada departamento F tiene mayor tasa de admisión que M,
    pero en el agregado M tiene mayor tasa (más mujeres en el depto difícil).
    """
    # Dept A (fácil): 90 hombres, 10 mujeres
    #   M: 72/90=0.80, F: 9/10=0.90
    # Dept B (difícil): 10 hombres, 90 mujeres
    #   M: 2/10=0.20, F: 27/90=0.30
    # Overall M: 74/100=0.74, F: 36/100=0.36
    rows = []
    for _ in range(72):
        rows.append({"dept": "A", "gender": "M", "admit": 1})
    for _ in range(18):
        rows.append({"dept": "A", "gender": "M", "admit": 0})
    for _ in range(9):
        rows.append({"dept": "A", "gender": "F", "admit": 1})
    for _ in range(1):
        rows.append({"dept": "A", "gender": "F", "admit": 0})
    for _ in range(2):
        rows.append({"dept": "B", "gender": "M", "admit": 1})
    for _ in range(8):
        rows.append({"dept": "B", "gender": "M", "admit": 0})
    for _ in range(27):
        rows.append({"dept": "B", "gender": "F", "admit": 1})
    for _ in range(63):
        rows.append({"dept": "B", "gender": "F", "admit": 0})
    data = pd.DataFrame(rows)
    overall = data.groupby("gender")["admit"].mean().to_dict()
    by_dept = data.groupby(["dept", "gender"])["admit"].mean().unstack()
    f_better_each = all(
        by_dept.loc[d, "F"] >= by_dept.loc[d, "M"] - 1e-9 for d in by_dept.index
    )
    overall_m_higher = overall["M"] > overall["F"]
    return {
        "name": "simpson_admission",
        "rate_M": float(overall["M"]),
        "rate_F": float(overall["F"]),
        "overall_M_higher": overall_m_higher,
        "F_ge_M_within_dept": f_better_each,
        "lesson": "Agregar sin estratificar invierte la asociación (Simpson)",
    }


def case_predict_vs_intervene() -> Dict:
    """Pregunta predictiva vs intervencional."""
    return {
        "name": "predict_vs_do",
        "predictive": "¿Cuál es E[Y | T=1, X]?",
        "interventional": "¿Cuál es E[Y | do(T=1), X]?",
        "same_only_if": "ignorabilidad / experimento / ajuste válido",
        "lesson": "Predecir ≠ intervenir; do-calculus formaliza la diferencia",
    }


def run_lab() -> dict:
    c1 = case_ice_cream_crime()
    c2 = case_simpson_admission()
    c3 = case_predict_vs_intervene()
    return {
        "cases": [c1, c2, c3],
        "n_cases": 3,
        "spurious_corr_large": abs(c1["corr_raw"]) > 0.5,
        "simpson_present": c2["overall_M_higher"] and c2["F_ge_M_within_dept"],
        "session": "S1",
    }


if __name__ == "__main__":
    import json

    print(json.dumps(run_lab(), indent=2))
