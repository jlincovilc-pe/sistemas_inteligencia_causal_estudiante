# IA Causal en Producción — Monorepo del curso

Curso ECO-490 / ECON-540 (2026): causalidad estructural + estimación con ML + ingeniería de sistemas en Hugging Face.  
**16 semanas · 32 sesiones · 50% teoría / 50% producción.**

> **Uso local.** Este monorepo vive **solo en tu máquina**. No hay remoto GitHub configurado, ni CI en la nube, ni publicación automática.  
> La Serie B *enseña* conceptos de HF (API, model card, Space, monitor); el push a Hub es **opcional y manual** del estudiante en su propia cuenta.

## Fuente de verdad

| Documento | Rol |
|---|---|
| [`PLAN_CURSO_COMPLETO.md`](./PLAN_CURSO_COMPLETO.md) | Práctica: sesiones, labs, A/B, datos, DoD de código |
| [`PLAN_INTEGRACION_MONOGRAFIA.md`](./PLAN_INTEGRACION_MONOGRAFIA.md) | Integración libro ↔ monorepo (profesionales, HF, efecto causal) |
| [`CHRONOGRAMA_SEMANAL.md`](./CHRONOGRAMA_SEMANAL.md) | Semana a semana: material del profesor y del estudiante |
| [`docs/NOTA_INSTRUCTORS.md`](./docs/NOTA_INSTRUCTORS.md) | Camino ★ vs electivos ◇ |
| [`02_monografia/`](./02_monografia/) | Monografía Typst 32 caps. + PDF |

**Posicionamiento:** curso para **profesionales** — estudios de caso, puesta en producción (HF opcional), utilidad de **estimar efectos** frente a solo predecir.

Si hay conflicto de **código/entregas**, manda el plan de práctica. Si hay conflicto de **numeración de capítulos del PDF**, manda el plan de integración + monografía.

---

## Mapa del repositorio

| Carpeta | Contenido |
|---|---|
| [`01_silabo/`](./01_silabo/) | Sílabo Typst + PDF (§12 cronograma) |
| [`02_monografia/`](./02_monografia/) | Monografía 32 caps. + PDF compilado |
| [`03_notebooks_caso_estudio/`](./03_notebooks_caso_estudio/) | Serie A (A1–A4) + `lib/` + autograders + tests |
| [`04_notebooks_produccion_hf/`](./04_notebooks_produccion_hf/) | Serie B (B1–B4): API, card/CI plantilla, Space, monitor |
| [`05_labs_sesion/`](./05_labs_sesion/) | 27 labs L01–L28 (sin L16) |
| [`06_proyecto_final/`](./06_proyecto_final/) | Guía + rúbrica + checklist humo |
| [`data_benchmark_causal/`](./data_benchmark_causal/) | Datasets del curso (Jobs, IHDP, sintéticos, …) |
| [`scripts/audit_repo.sh`](./scripts/audit_repo.sh) | Auditoría local de práctica |

---

## Modelo pedagógico

```text
Sesión 90 min  →  capítulo monografía + lab corto L##  (formativo)
Bloque 2–3 sem →  entrega A# o B#                     (sumativa)
Semanas 15–16  →  proyecto final (HF opcional)        (40%)
```

**~27 labs** + **8 entregas (4A+4B)** + **proyecto**. No hay 32 notebooks de entrega.

### Serie A

| ID | Dataset | Sesiones |
|---|---|---|
| A1 | `real/jobs` | S4–S6 |
| A2 | `synthetic/inference/ihdp_medium` | S8–S11 → artefacto B1 |
| A3 | `real/ihdp` | S13–S15 |
| A4 | `real/ihdp` | S22–S23 → artefacto B3 |

### Serie B (todo ejecutable en local)

| ID | Insumo | Qué se practica |
|---|---|---|
| B1 | A2 joblib | FastAPI + Docker (local) |
| B2 | B1 | Model card + plantilla CI (sin Actions en la nube) |
| B3 | A4 policy | Gradio Space (local; push HF opcional) |
| B4 | drift sim. | Dashboard de monitoreo (local) |

### Entorno (local)

```bash
# Serie A
cd 03_notebooks_caso_estudio
python3 -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt
pytest tests/ -q

# B1
cd ../04_notebooks_produccion_hf/B1_fastapi_dml
python3 -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt
pytest tests/ -q && python ../autograder/grade_b1.py
```

Los `.venv` **no** se versionan; se recrean con los `requirements.txt` / `environment.yml`.

---

## Auditoría local

```bash
bash scripts/audit_repo.sh
```

Compileall · pytest A · pytest labs · pytest B1 · grade A1–A4 · grade B1–B4 · sync de artefactos.

Plantilla educativa de CI (no activa):  
`04_notebooks_produccion_hf/B2_hub_cicd/templates/b1_smoke.yml`

---

## Git (solo local)

```bash
# Ya inicializado en esta carpeta, sin remoto.
git status
# No hacer: git remote add …  /  git push
```

---

## Licencia y citación

Código de benchmarks: MIT (ver `data_benchmark_causal/`).  
Citar fuentes originales de escenarios (Sachs, Hill, LaLonde, etc.) según `CITATION.cff`.
