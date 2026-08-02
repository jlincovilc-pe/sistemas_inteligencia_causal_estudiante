"""L21 — Formalizar una decisión estructural (prep A4)."""

from __future__ import annotations

import json
from dataclasses import asdict, dataclass
from typing import Any, Dict, List


@dataclass
class DecisionProblem:
    """Plantilla de decisión del curso (no es un estimador)."""

    units: str
    action: str
    outcome: str
    information_set: List[str]
    constraint: str
    loss_or_welfare: str
    estimand_link: str
    population: str

    def validate(self) -> List[str]:
        errs = []
        for field in (
            "units",
            "action",
            "outcome",
            "constraint",
            "loss_or_welfare",
            "estimand_link",
            "population",
        ):
            if not str(getattr(self, field)).strip():
                errs.append(f"empty:{field}")
        if not self.information_set:
            errs.append("empty:information_set")
        if "CATE" not in self.estimand_link and "tau" not in self.estimand_link.lower():
            # soft warning stored as note, not hard error
            pass
        return errs


def reference_ihdp_decision() -> DecisionProblem:
    """Decisión de referencia alineada a A4 (targeting bajo presupuesto)."""
    return DecisionProblem(
        units="individuos del escenario real/ihdp (unidades del SEM docente)",
        action="tratar (T=1) vs no tratar (T=0) con un programa de intervención",
        outcome="outcome (score de desarrollo / cognitivo en el benchmark)",
        information_set=[
            "bw",
            "b.head",
            "preterm",
            "momage",
            "sex",
            "… (25 covariables pre-tratamiento del escenario)",
        ],
        constraint="presupuesto: tratar a lo sumo B=20% de la población (capacidad)",
        loss_or_welfare=(
            "maximizar bienestar incremental ≈ E[π(X)·τ(X)] "
            "(welfare miópico bajo ITE; en A4 se usa ranking por CATE)"
        ),
        estimand_link="CATE τ(x)=E[Y(1)-Y(0)|X=x] estimado en A3 (t_learner por defecto)",
        population="split test oficial del escenario (n=150) para evaluación de política",
    )


def run_lab() -> dict:
    d = reference_ihdp_decision()
    errs = d.validate()
    return {
        "decision": asdict(d),
        "valid": len(errs) == 0,
        "errors": errs,
        "feeds": "A4 policy learning — la formalización debe preceder al umbral λ",
        "session": "S21",
    }


if __name__ == "__main__":
    print(json.dumps(run_lab(), indent=2, ensure_ascii=False))
