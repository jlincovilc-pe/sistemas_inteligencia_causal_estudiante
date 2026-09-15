# Serie A — Notebooks de caso de estudio

Material de **diseño e implementación** de los cuatro notebooks de caso de estudio del curso *IA Causal en Producción*.

**Base dir (esta carpeta):** `03_notebooks_caso_estudio/`  
**Datos (obligatorio, monorepo):** `../data_benchmark_causal/causal_benchmark_synthetic/datasets/`  
Sin internet ni datasets externos en el flujo del estudiante.

## Documentos

| Documento | Contenido |
|---|---|
| [`../PLAN_CURSO_COMPLETO.md`](../PLAN_CURSO_COMPLETO.md) | Plan de práctica del monorepo (sesiones, A/B, labs) |

## Datasets (decisión del plan)

Todos los notebooks usan escenarios de:

`../data_benchmark_causal/causal_benchmark_synthetic/datasets/`

| Notebook | Escenario | `scenario_id` |
|---|---|---|
| A1 | `real/jobs` | `real_jobs` |
| A2 | `synthetic/inference/ihdp_medium` | `synthetic_inference_ihdp_medium` |
| A3 | `real/ihdp` | `real_ihdp` |
| A4 | `real/ihdp` (continúa A3) | `real_ihdp` |

**Contrato de capas**

| Capa | Archivos | Quién |
|---|---|---|
| Observables | `observed_*.csv` | Estudiante (siempre) |
| Ground truth | `truth_*.csv` (`y0`, `y1`, `tau`) | Autograder / celdas finales marcadas |
| Identificación / meta | `identification.json`, `metadata.json`, `scorecard.json` | Lectura guiada |

`RANDOM_STATE = 42` en código del curso (salvo seeds del generador en `metadata.json`).

## Estructura

```text
03_notebooks_caso_estudio/
├── README.md
├── requirements.txt
├── environment.yml
├── lib/                          # helpers importables (sin estado de kernel)
│   ├── paths.py                  # DATA_ROOT, RANDOM_STATE, scenario_dir
│   ├── data_io.py                # load_scenario / load_observed / load_truth
│   ├── metrics.py                # ATE error, PEHE, Qini, uplift
│   ├── identification.py         # A1: propensity, OLS, PDS
│   ├── dml_utils.py              # A2: PLR + export joblib → B1
│   ├── cate_utils.py             # A3: meta-learners, placebo
│   ├── policy_utils.py           # A4: policy + export joblib → B3
│   └── plotting.py
├── notebooks/
│   ├── A1_identificacion_jobs.ipynb
│   ├── A2_dml_ihdp_medium.ipynb
│   ├── A3_cate_meta_learners_ihdp.ipynb
│   └── A4_policy_uplift_ihdp.ipynb
├── artifacts/
│   ├── A2/   # dml_estimator.joblib, feature_list.json, training_meta.json  → B1
│   ├── A3/   # cate_scores_test.csv, plots
│   └── A4/   # policy.joblib, policy_card.md, equity_table.csv, …          → B3
├── autograder/
│   ├── expected_ranges.yaml
│   ├── grade_a1.py … grade_a4.py   # CLI: python autograder/grade_aN.py --help
├── rubrics/
├── scripts/                      # export_a2/a3/a4_artifacts.py (kernel-less)
└── tests/
    ├── test_data_io.py
    ├── test_metrics.py
    └── test_smoke_notebooks.py   # imports, nb parse, critical paths, artifacts
```

## Entorno

```bash
cd 03_notebooks_caso_estudio
python -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt
```

Datos solo monorepo (sin descargas)::

`../data_benchmark_causal/causal_benchmark_synthetic/datasets/`

Helpers::

```python
from lib.data_io import load_scenario, load_observed, load_truth
from lib.paths import RANDOM_STATE, DATA_ROOT
```

`load_truth` es **solo evaluación** (autograder / celdas finales marcadas). No usarlo en celdas de estimación del estudiante.

## Cómo ejecutar tests (kernel-less / offline)

Desde esta carpeta (recomendado)::

```bash
cd 03_notebooks_caso_estudio
source .venv/bin/activate   # si aplica
pytest tests/ -q
```

Desde la raíz del monorepo::

```bash
pytest 03_notebooks_caso_estudio/tests/ -q
```

### Qué cubre cada suite

| Archivo | Rol |
|---|---|
| `tests/test_data_io.py` | Loaders `real/jobs`, `synthetic/inference/ihdp_medium`, `real/ihdp`; shapes/columnas; `load_truth` separado |
| `tests/test_metrics.py` | ATE error, PEHE, uplift con arrays sintéticos fijos |
| `tests/test_smoke_notebooks.py` | Import de `lib.*`; parse JSON de notebooks; paths críticos A1–A4; artefactos A2/A4; CLI `--help` de graders |

**Smoke mode (por defecto):** no ejecuta los notebooks con un kernel persistente ni `nbconvert` completo (A2/A3 pueden ser lentos y dependen de opcionales como EconML). Sí verifica:

- importabilidad de módulos,
- presencia y estructura de notebooks,
- caminos de estimación en Python puro sobre datasets locales,
- artefactos serializados para Serie B.

**Modo pesado (opcional):**

```bash
SERIE_A_NBCONVERT=1 pytest tests/test_smoke_notebooks.py -q -k nbconvert
```

### Autograders (CLI, sin kernel)

```bash
python autograder/grade_a1.py --help
python autograder/grade_a1.py --skip-notebook-audit
python autograder/grade_a2.py --skip-notebook-audit
python autograder/grade_a3.py --skip-notebook-audit
python autograder/grade_a4.py --skip-notebook-audit
```

Tolerancias: [`autograder/expected_ranges.yaml`](./autograder/expected_ranges.yaml).

### Export de artefactos (sin notebook)

```bash
python scripts/export_a2_artifacts.py
python scripts/export_a3_artifacts.py
python scripts/export_a4_artifacts.py
```

## Mapeo a Serie B (artefactos)

```text
A2  artifacts/A2/dml_estimator.joblib
    artifacts/A2/feature_list.json
    artifacts/A2/training_meta.json
        └──► B1  (FastAPI / Docker: cargar estimador, exponer ATE / predict)

A3  artifacts/A3/cate_scores_test.csv  ──► A4 (scores CATE)

A4  artifacts/A4/policy.joblib
    artifacts/A4/policy_card.md
    artifacts/A4/equity_table.csv
    artifacts/A4/uplift_curve.png
        └──► B3  (Space Gradio: policy.predict(X) -> {decision, uplift_score})
```

Contratos de interfaz (resumen):

| Artefacto | Interfaz mínima |
|---|---|
| A2 `dml_estimator.joblib` | `const_marginal_ate()` / `ate()` y opcionalmente `predict(X)` |
| A4 `policy.joblib` | `predict(X=…, scores=…) -> {"decision", "uplift_score"}` |

Los JSON de meta usan **rutas relativas al monorepo** (no paths absolutos de máquina).

## Estado

- [x] Infra `lib/` + requirements
- [x] Notebooks A1–A4
- [x] Autograders, rúbricas, `expected_ranges.yaml`
- [x] Artefactos A2 → B1 y A4 → B3
- [x] Tests + graders A1–A4

## Cómo se conecta con el resto del repo

- **Plan del curso:** [`../PLAN_CURSO_COMPLETO.md`](../PLAN_CURSO_COMPLETO.md)
- Sílabo: `../01_silabo/`
- Monografía: `../02_monografia/`
- Serie B: `../04_notebooks_produccion_hf/`
- Labs: `../05_labs_sesion/`
- Datos: `../data_benchmark_causal/`
