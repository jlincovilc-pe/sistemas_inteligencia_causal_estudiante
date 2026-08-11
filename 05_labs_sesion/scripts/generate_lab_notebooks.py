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
        "business": [
            "Un ranking basado solo en correlación puede recomendar tratar a quien no lo necesita.",
            "Exigir la pregunta contrafactual (“¿qué pasaría sin actuar?”) es el filtro mínimo antes de aceptar cualquier insight de un dashboard predictivo.",
            "Esta distinción decide si un proyecto de datos cambia una decisión real o solo produce un score más.",
        ],
    },
    "L02_entorno_hf_git": {
        "session": "S2",
        "cap": "Cap. 2 Anatomía del sistema",
        "value": "El efecto no sirve si no se puede operar (entorno + monorepo).",
        "entrega": "Lab 0",
        "business": [
            "Un efecto que solo vive en un notebook local no se puede auditar ni entregar a producción.",
            "Versionar entorno y datos es lo que permite que otro equipo reproduzca la decisión, no solo el número.",
            "Sin este andamiaje, cualquier resultado causal queda como anécdota, no como activo reutilizable por la organización.",
        ],
    },
    "L03_pch_clasificar": {
        "session": "S3",
        "cap": "Cap. 3 SCM y PCH",
        "value": "Clasifica preguntas: ver / hacer / imaginar.",
        "entrega": "—",
        "business": [
            "Clasificar la pregunta (ver / hacer / imaginar) evita prometerle a negocio un contrafactual que los datos no pueden responder.",
            "Confundir “predecir” con “intervenir” desperdicia presupuesto en el nivel de análisis equivocado.",
            "Es el primer filtro de viabilidad antes de comprometer una fecha de entrega con el área de negocio.",
        ],
    },
    "L04_roles_eda_jobs": {
        "session": "S4",
        "cap": "Cap. 4 Ingeniería de datos",
        "value": "Roles T/Y/X = contrato del sistema.",
        "entrega": "A1 arranca",
        "business": [
            "Definir mal T/Y/X es la causa más común de un ATE que no significa lo que el equipo cree que significa.",
            "El contrato de roles es lo primero que revisa un auditor o regulador cuando cuestiona una decisión automatizada.",
            "Sin roles explícitos, dos analistas pueden estimar “el mismo” efecto y llegar a conclusiones opuestas.",
        ],
    },
    "L05_pds_jobs": {
        "session": "S5",
        "cap": "Cap. 6 Regularización (+ Cap. 16 PDS ◇)",
        "value": "Controles en alta dimensión sin p-hacking ingenuo.",
        "entrega": "A1",
        "business": [
            "Elegir controles a mano (o por p-value) puede inflar o borrar el efecto que negocio usará para decidir presupuesto.",
            "PDS documenta por qué se incluyó cada variable — evidencia necesaria si el resultado se cuestiona después.",
            "Evita el escenario más caro: publicar un ATE que colapsa al cambiar dos controles.",
        ],
    },
    "L06_splits_jobs": {
        "session": "S6",
        "cap": "Cap. 7 Datos de entrenamiento",
        "value": "Splits y procedencia = auditabilidad.",
        "entrega": "A1 entrega",
        "business": [
            "Splits mal hechos (fuga train/test) producen métricas que se ven bien en la demo y fallan en producción.",
            "La procedencia de los datos es lo primero que pide compliance antes de aprobar un modelo que afecta personas.",
            "Sin splits oficiales no hay forma de comparar honestamente dos candidatos a “el modelo que se despliega”.",
        ],
    },
    "L07_backdoor_latente": {
        "session": "S7",
        "cap": "Cap. 8 Intervención y contrafactual",
        "value": "Cuándo no estimar (abstenerse).",
        "entrega": "—",
        "business": [
            "Detectar un backdoor no observado es la razón profesional para decir “no se puede estimar esto todavía” en vez de forzar un número.",
            "Estimar bajo un confusor latente sin decirlo es el error que después se paga en una auditoría o un litigio.",
            "Abstenerse a tiempo cuesta menos que retractar una decisión de negocio tomada sobre un efecto sesgado.",
        ],
    },
    "L08_leakage_ihdp": {
        "session": "S8",
        "cap": "Cap. 9 Features sin fuga",
        "value": "Evita “efectos” inventados por leakage.",
        "entrega": "A2 arranca",
        "business": [
            "Un feature con fuga produce un “efecto” que en realidad es el resultado disfrazado — la decisión basada en él es circular.",
            "Leakage es la forma más común de que un piloto se vea excelente y falle en el primer mes de producción real.",
            "Revisar fuga de información es un checkpoint obligatorio antes de mostrarle el número al negocio.",
        ],
    },
    "L09_neyman_residuals": {
        "session": "S9",
        "cap": "Cap. 10 Ortogonalidad",
        "value": "Inferencia válida con ML flexible.",
        "entrega": "A2",
        "business": [
            "La ortogonalidad permite usar modelos de ML flexibles sin que su propio sesgo contamine el efecto estimado.",
            "Sin cross-fitting, el intervalo de confianza que le das a negocio puede ser más angosto de lo real — falsa seguridad.",
            "Esta técnica separa “estimar con ML moderno” de “hacer overfitting con nombre elegante”.",
        ],
    },
    "L10_plr_minimo": {
        "session": "S10",
        "cap": "Cap. 11 DML",
        "value": "ATE accionable con IC.",
        "entrega": "A2",
        "business": [
            "El ATE con intervalo de confianza es lo mínimo que negocio necesita para decidir go/no-go de una inversión.",
            "Sin IC, cualquier ATE es indistinguible de ruido — no hay forma de defenderlo frente a un CFO escéptico.",
            "Este número alimenta directamente la API de B1 y las decisiones que dependen de ella.",
        ],
    },
    "L11_qini_placebo": {
        "session": "S11",
        "cap": "Cap. 14 Validación",
        "value": "Confianza sin ground truth de negocio.",
        "entrega": "A2 entrega",
        "business": [
            "Validar sin ground truth es la situación real de casi cualquier decisión de negocio: no hay “respuesta correcta” contra la cual comparar.",
            "Un placebo test que falla es la señal más barata de que el modelo no debe salir a producción.",
            "Da la confianza mínima defendible para decir “este efecto no es un artefacto del pipeline”.",
        ],
    },
    "L12_fastapi_stub": {
        "session": "S12",
        "cap": "Cap. 15 Despliegue servicio",
        "value": "El efecto se consulta por API.",
        "entrega": "B1",
        "business": [
            "Un efecto que solo corre en un notebook no puede consultarse desde el sistema que realmente decide a quién tratar.",
            "Exponerlo como servicio permite que otros equipos (producto, riesgo) lo usen sin reimplementar el modelo.",
            "Es el primer paso para versionar y auditar el efecto como cualquier otro servicio de producción.",
        ],
    },
    "L13_t_learner_ihdp": {
        "session": "S13",
        "cap": "Cap. 12 Meta-learners",
        "value": "Heterogeneidad = targeting.",
        "entrega": "A3 arranca",
        "business": [
            "El CATE dice a quién le mueve más la aguja — sin él, el targeting trata a todos igual y desperdicia presupuesto.",
            "Es la base técnica de cualquier estrategia de priorización o segmentación defendible ante negocio.",
            "Ignorar heterogeneidad equivale a tratar como igual a un grupo que en realidad responde muy distinto.",
        ],
    },
    "L14_b1_humo": {
        "session": "S14",
        "cap": "Cap. 13 Bosques · Cap. 15 servicio",
        "value": "CATE + servicio vivo.",
        "entrega": "B1 entrega",
        "business": [
            "Un servicio con CATE + smoke test es la diferencia entre “funcionó en mi laptop” y “se puede confiar en producción”.",
            "El smoke test es la señal mínima que un equipo de plataforma exige antes de aprobar un despliegue.",
            "Convierte la entrega A2/A3 en un artefacto que otro equipo puede operar sin el autor original.",
        ],
    },
    "L15_checklist_a1a3": {
        "session": "S15",
        "cap": "Repaso Caps. 1–15",
        "value": "Checklist de sistema causal.",
        "entrega": "A3 entrega",
        "business": [
            "Un checklist de sistema causal evita repetir en producción los mismos errores de identificación del bloque anterior.",
            "Sirve como auditoría previa antes de comprometer el resultado frente a negocio o a un regulador.",
            "Convierte trabajo disperso en tres entregas en un criterio único de “listo para avanzar”.",
        ],
    },
    "L17_model_card_esqueleto": {
        "session": "S17",
        "cap": "Cap. 19 Hub y model cards",
        "value": "Documentar supuestos = activo reutilizable.",
        "entrega": "B2",
        "business": [
            "Una model card documenta los supuestos que, si fallan, invalidan la decisión — sin ella el riesgo queda invisible.",
            "Permite que otro equipo reutilice el modelo sin heredar ciegamente sus limitaciones.",
            "Es lo primero que pediría compliance o un cliente enterprise antes de aprobar el uso del modelo.",
        ],
    },
    "L18_gha_humo_b1": {
        "session": "S18",
        "cap": "Cap. 20 CI/CD",
        "value": "No se publica un efecto roto.",
        "entrega": "B2 entrega",
        "business": [
            "CI que corre el smoke test evita publicar (o dejar correr) un efecto roto sin que nadie lo note.",
            "Es la diferencia entre “confiamos porque funcionó una vez” y “confiamos porque se verifica en cada cambio”.",
            "Reduce el costo de un error: se detecta en el pipeline, no en la reunión donde negocio ya tomó la decisión.",
        ],
    },
    "L19_explicacion_causal": {
        "session": "S19",
        "cap": "Cap. 23 Explicación y equidad",
        "value": "Efecto ≠ importancia SHAP.",
        "entrega": "—",
        "business": [
            "Una importancia SHAP alta no implica que esa variable cause el resultado — confundirlas lleva a intervenir donde no sirve.",
            "Evita que negocio pida “actuar sobre la variable más importante” cuando esa variable no es intervenible.",
            "Explicar el efecto (no solo el score) es lo que hace defendible la recomendación frente a un comité.",
        ],
    },
    "L20_shap_audit": {
        "session": "S20",
        "cap": "Cap. 24 Ética e interpretabilidad",
        "value": "Auditoría responsable del CATE.",
        "entrega": "—",
        "business": [
            "Auditar el CATE con SHAP expone si el modelo está discriminando por un proxy de una variable protegida.",
            "Da evidencia concreta para justificar o corregir una política antes de que afecte a personas reales.",
            "Sin esta auditoría, un sesgo de targeting queda oculto hasta que se vuelve un problema reputacional o legal.",
        ],
    },
    "L21_formalizar_decision": {
        "session": "S21",
        "cap": "Cap. 25 Decisiones estructurales",
        "value": "Formalizar la decisión de negocio.",
        "entrega": "A4",
        "business": [
            "Formalizar la decisión (regla, umbral, presupuesto) convierte un estimador en una política ejecutable.",
            "Sin esta formalización, cada analista implementa “a quién tratar” distinto y los resultados no son comparables.",
            "Es el puente directo entre el número que produce el modelo y la acción que toma la organización.",
        ],
    },
    "L22_policy_topk": {
        "session": "S22",
        "cap": "Cap. 21 Policy learning",
        "value": "Presupuesto → quién tratar.",
        "entrega": "A4 arranca",
        "business": [
            "Bajo presupuesto fijo, la pregunta de negocio nunca es “a quién tratar” en abstracto sino “a quién tratar con el 20% que tenemos”.",
            "Una política top-k mal calibrada gasta capacidad en quien de todos modos hubiera mejorado sin la intervención.",
            "Convierte el CATE en asignación concreta de recursos, medible en presupuesto ahorrado o ganado.",
        ],
    },
    "L23_uplift_gradio_stub": {
        "session": "S23",
        "cap": "Cap. 22 Uplift",
        "value": "Política en Space HF.",
        "entrega": "A4 + B3",
        "business": [
            "Poner la política en un Space le da a un decisor no técnico la capacidad de probarla sin depender de un analista.",
            "Es el momento en que la organización deja de discutir el modelo en abstracto y empieza a decidir con él.",
            "Expone la política a revisión antes de comprometerla en un sistema productivo más rígido.",
        ],
    },
    "L24_transportabilidad": {
        "session": "S24",
        "cap": "Cap. 26 Generalización",
        "value": "¿El efecto vale en mi mercado?",
        "entrega": "—",
        "business": [
            "Un efecto medido en una población no necesariamente aplica a otra — asumir lo contrario es el error más caro al escalar un piloto.",
            "Decide si el mismo modelo sirve para expandirse a otro mercado o segmento sin recalibrar.",
            "Es el argumento técnico para pedir (o negar) presupuesto de validación antes de replicar la política en otro contexto.",
        ],
    },
    "L25_ks_drift": {
        "session": "S25",
        "cap": "Cap. 30 Monitoreo",
        "value": "Detectar cuando el efecto deja de valer.",
        "entrega": "B4",
        "business": [
            "Detectar drift a tiempo es la diferencia entre pausar una política a tiempo y seguir tratando gente con un efecto que ya no aplica.",
            "El monitoreo convierte “confiamos en el modelo” en una afirmación verificable, no en un acto de fe.",
            "Es la alerta que le da a operaciones una fecha concreta para decidir: reentrenar, pausar o escalar.",
        ],
    },
    "L26_discovery_pc": {
        "session": "S26",
        "cap": "Cap. 29 Discovery",
        "value": "Estructura cuando el DAG no está dado.",
        "entrega": "B3 cierre",
        "business": [
            "Sin un DAG dado por expertos, el discovery estructural es la forma honesta de proponer hipótesis causales, no certezas.",
            "Evita que el equipo asuma una estructura causal conveniente sin evidencia, un riesgo típico bajo presión de negocio.",
            "Sirve como punto de partida para una discusión informada con el dueño del proceso, no como respuesta final.",
        ],
    },
    "L27_reentrenar_alertar": {
        "session": "S27",
        "cap": "Cap. 31 Aprendizaje continuo",
        "value": "Reentrenar vs alertar.",
        "entrega": "B4",
        "business": [
            "Ante drift, reentrenar sin pensar puede ocultar un cambio estructural que merece revisión humana, no solo un nuevo fit.",
            "Reentrenar, alertar o pausar tienen costos distintos — la elección es una decisión de negocio, no solo técnica.",
            "Formalizar el criterio evita que la respuesta al drift dependa de quién esté de guardia esa semana.",
        ],
    },
    "L28_comunicar_ate": {
        "session": "S28",
        "cap": "Cap. 32 Lado humano",
        "value": "Comunicar ATE a no técnicos.",
        "entrega": "B4 entrega",
        "business": [
            "Un ATE con IC que nadie en el comité entiende no cambia ninguna decisión, sin importar cuán riguroso sea el método.",
            "Comunicar el efecto en términos de impacto, riesgo y costo de inacción es lo que realmente mueve presupuesto.",
            "Es la habilidad que separa a quien “sabe estimar” de quien “logra que la organización actúe” sobre el estimado.",
        ],
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
    business_bullets = "\n".join(f"- {b}" for b in meta.get("business", []))
    business = f"""## 4. Implicación de negocio

{business_bullets}
"""
    closing = f"""## Checklist

- [ ] Leí {meta['cap']}
- [ ] Respondí mentalmente la pregunta de valor
- [ ] `run_lab()` y checks en verde
- [ ] Repasé la implicación de negocio (§4)
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
            _md(business),
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
