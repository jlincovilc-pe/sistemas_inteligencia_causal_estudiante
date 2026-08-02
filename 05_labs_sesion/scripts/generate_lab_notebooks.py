#!/usr/bin/env python3
"""Generate student-facing lab.ipynb from each lab's lab_core + metadata.

Usage (from monorepo root or 05_labs_sesion)::

    python 05_labs_sesion/scripts/generate_lab_notebooks.py
"""

from __future__ import annotations

import json
import re
from pathlib import Path

LABS_ROOT = Path(__file__).resolve().parents[1]

# Session / monografía / value map (camino profesional)
META = {
    "L01_correlacion_causacion": {
        "session": "S1",
        "cap": "Cap. 1 Causalidad elemental",
        "value": "Deja de confundir correlación con “qué pasa si actuamos”.",
        "entrega": "—",
    },
    "L02_entorno_hf_git": {
        "session": "S2",
        "cap": "Cap. 2 Anatomía del sistema",
        "value": "El efecto no sirve si no se puede operar (entorno + monorepo).",
        "entrega": "Lab 0",
    },
    "L03_pch_clasificar": {
        "session": "S3",
        "cap": "Cap. 3 SCM y PCH",
        "value": "Clasifica preguntas: ver / hacer / imaginar.",
        "entrega": "—",
    },
    "L04_roles_eda_jobs": {
        "session": "S4",
        "cap": "Cap. 4 Ingeniería de datos",
        "value": "Roles T/Y/X = contrato del sistema.",
        "entrega": "A1 arranca",
    },
    "L05_pds_jobs": {
        "session": "S5",
        "cap": "Cap. 6 Regularización (+ Cap. 16 PDS ◇)",
        "value": "Controles en alta dimensión sin p-hacking ingenuo.",
        "entrega": "A1",
    },
    "L06_splits_jobs": {
        "session": "S6",
        "cap": "Cap. 7 Datos de entrenamiento",
        "value": "Splits y procedencia = auditabilidad.",
        "entrega": "A1 entrega",
    },
    "L07_backdoor_latente": {
        "session": "S7",
        "cap": "Cap. 8 Intervención y contrafactual",
        "value": "Cuándo no estimar (abstenerse).",
        "entrega": "—",
    },
    "L08_leakage_ihdp": {
        "session": "S8",
        "cap": "Cap. 9 Features sin fuga",
        "value": "Evita “efectos” inventados por leakage.",
        "entrega": "A2 arranca",
    },
    "L09_neyman_residuals": {
        "session": "S9",
        "cap": "Cap. 10 Ortogonalidad",
        "value": "Inferencia válida con ML flexible.",
        "entrega": "A2",
    },
    "L10_plr_minimo": {
        "session": "S10",
        "cap": "Cap. 11 DML",
        "value": "ATE accionable con IC.",
        "entrega": "A2",
    },
    "L11_qini_placebo": {
        "session": "S11",
        "cap": "Cap. 14 Validación",
        "value": "Confianza sin ground truth de negocio.",
        "entrega": "A2 entrega",
    },
    "L12_fastapi_stub": {
        "session": "S12",
        "cap": "Cap. 15 Despliegue servicio",
        "value": "El efecto se consulta por API.",
        "entrega": "B1",
    },
    "L13_t_learner_ihdp": {
        "session": "S13",
        "cap": "Cap. 12 Meta-learners",
        "value": "Heterogeneidad = targeting.",
        "entrega": "A3 arranca",
    },
    "L14_b1_humo": {
        "session": "S14",
        "cap": "Cap. 13 Bosques · Cap. 15 servicio",
        "value": "CATE + servicio vivo.",
        "entrega": "B1 entrega",
    },
    "L15_checklist_a1a3": {
        "session": "S15",
        "cap": "Repaso Caps. 1–15",
        "value": "Checklist de sistema causal.",
        "entrega": "A3 entrega",
    },
    "L17_model_card_esqueleto": {
        "session": "S17",
        "cap": "Cap. 19 Hub y model cards",
        "value": "Documentar supuestos = activo reutilizable.",
        "entrega": "B2",
    },
    "L18_gha_humo_b1": {
        "session": "S18",
        "cap": "Cap. 20 CI/CD",
        "value": "No se publica un efecto roto.",
        "entrega": "B2 entrega",
    },
    "L19_explicacion_causal": {
        "session": "S19",
        "cap": "Cap. 23 Explicación y equidad",
        "value": "Efecto ≠ importancia SHAP.",
        "entrega": "—",
    },
    "L20_shap_audit": {
        "session": "S20",
        "cap": "Cap. 24 Ética e interpretabilidad",
        "value": "Auditoría responsable del CATE.",
        "entrega": "—",
    },
    "L21_formalizar_decision": {
        "session": "S21",
        "cap": "Cap. 25 Decisiones estructurales",
        "value": "Formalizar la decisión de negocio.",
        "entrega": "A4",
    },
    "L22_policy_topk": {
        "session": "S22",
        "cap": "Cap. 21 Policy learning",
        "value": "Presupuesto → quién tratar.",
        "entrega": "A4 arranca",
    },
    "L23_uplift_gradio_stub": {
        "session": "S23",
        "cap": "Cap. 22 Uplift",
        "value": "Política en Space HF.",
        "entrega": "A4 + B3",
    },
    "L24_transportabilidad": {
        "session": "S24",
        "cap": "Cap. 26 Generalización",
        "value": "¿El efecto vale en mi mercado?",
        "entrega": "—",
    },
    "L25_ks_drift": {
        "session": "S25",
        "cap": "Cap. 30 Monitoreo",
        "value": "Detectar cuando el efecto deja de valer.",
        "entrega": "B4",
    },
    "L26_discovery_pc": {
        "session": "S26",
        "cap": "Cap. 29 Discovery",
        "value": "Estructura cuando el DAG no está dado.",
        "entrega": "B3 cierre",
    },
    "L27_reentrenar_alertar": {
        "session": "S27",
        "cap": "Cap. 31 Aprendizaje continuo",
        "value": "Reentrenar vs alertar.",
        "entrega": "B4",
    },
    "L28_comunicar_ate": {
        "session": "S28",
        "cap": "Cap. 32 Lado humano",
        "value": "Comunicar ATE a no técnicos.",
        "entrega": "B4 entrega",
    },
}


def _nb(cells: list) -> dict:
    return {
        "nbformat": 4,
        "nbformat_minor": 5,
        "metadata": {
            "kernelspec": {
                "display_name": "Python 3",
                "language": "python",
                "name": "python3",
            },
            "language_info": {"name": "python", "pygments_lexer": "ipython3"},
        },
        "cells": cells,
    }


def _md(text: str) -> dict:
    return {
        "cell_type": "markdown",
        "metadata": {},
        "source": text.splitlines(keepends=True),
    }


def _code(text: str) -> dict:
    return {
        "cell_type": "code",
        "metadata": {},
        "outputs": [],
        "execution_count": None,
        "source": text.splitlines(keepends=True),
    }


def build_notebook(lab_dir: Path, meta: dict) -> dict:
    name = lab_dir.name
    title = name.replace("_", " ")
    header = f"""# {name}

**Sesión:** {meta['session']} · **Lectura monografía:** {meta['cap']}  
**Entrega / hito:** {meta['entrega']}  
**Código de referencia:** `lab_core.py` · **Smoke:** `checks.py`

### Pregunta de valor (disrupción)

> {meta['value']}

### Aviso sobre los datos

Los escenarios del monorepo son **benchmarks documentados** (a menudo sintéticos con semántica de literatura).  
Ver `metadata.json` → `what_is_real` / `what_is_synthetic` cuando aplique. No uses `truth_*` fuera de evaluación.
"""
    setup = """from pathlib import Path
import sys

# Raíz monorepo: 05_labs_sesion/<lab>/ → parents[2]
REPO = Path("../..").resolve()
SERIE_A = REPO / "03_notebooks_caso_estudio"
LABS = REPO / "05_labs_sesion"
for p in (str(LABS), str(SERIE_A), str(Path(".").resolve())):
    if p not in sys.path:
        sys.path.insert(0, p)

from lab_core import run_lab  # referencia del curso
print("lab_core import OK")
"""
    run = """# Ejecuta la solución de referencia del lab (kernel-less).
# En versión "estudiante" se pediría completar celdas antes de llamar a run_lab.
out = run_lab()
out
"""
    checks = """# Smoke del lab (mismo contrato que pytest)
import checks as lab_checks
for name in dir(lab_checks):
    if name.startswith("test_"):
        getattr(lab_checks, name)()
        print(name, "PASS")
print("all checks OK")
"""
    closing = f"""## Checklist

- [ ] Leí {meta['cap']}
- [ ] Respondí mentalmente la pregunta de valor
- [ ] `run_lab()` y checks en verde
- [ ] Sé qué entrega alimenta: **{meta['entrega']}**

## Siguiente

Consulta el sílabo (`01_silabo/silabo.pdf`) y `PLAN_INTEGRACION_MONOGRAFIA.md`.
"""
    return _nb(
        [
            _md(header),
            _md("## 1. Setup"),
            _code(setup),
            _md("## 2. Ejecutar el lab (referencia)"),
            _code(run),
            _md("## 3. Smoke checks"),
            _code(checks),
            _md(closing),
        ]
    )


def main() -> int:
    n = 0
    for lab_dir in sorted(LABS_ROOT.glob("L*")):
        if not lab_dir.is_dir():
            continue
        if not (lab_dir / "lab_core.py").is_file():
            continue
        meta = META.get(
            lab_dir.name,
            {
                "session": "?",
                "cap": "ver sílabo",
                "value": "Ver PLAN_INTEGRACION_MONOGRAFIA.md",
                "entrega": "—",
            },
        )
        nb = build_notebook(lab_dir, meta)
        out = lab_dir / "lab.ipynb"
        out.write_text(json.dumps(nb, ensure_ascii=False, indent=1), encoding="utf-8")
        n += 1
        print("wrote", out.relative_to(LABS_ROOT))
    print(f"generated {n} notebooks")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
