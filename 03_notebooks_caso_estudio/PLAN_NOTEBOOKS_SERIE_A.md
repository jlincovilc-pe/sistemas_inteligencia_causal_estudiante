# Plan completo — Serie A: Notebooks de caso de estudio

**Curso:** IA Causal en Producción (ECO-490 / ECON-540)  
**Carpeta de entrega:** `03_notebooks_caso_estudio/`  
**Fuente de datos (obligatoria):** `data_benchmark_causal/causal_benchmark_synthetic/datasets/`  
**Documento base:** `propuesta_notebooks_caso_estudio.md`  
**Estado:** planificación lista para implementación (sin notebooks ejecutables aún)

---

## 1. Objetivo del plan

Construir los **cuatro notebooks de caso de estudio (Serie A)** del curso de forma que:

1. Cubran las técnicas de la propuesta pedagógica (identificación → DML → CATE → policy).
2. Usen **exclusivamente** escenarios del paquete `causal_benchmark_synthetic` (sin 401(k), Card, Criteo ni otras fuentes externas).
3. Respeten el **contrato de datos** del benchmark: observables vs. ground truth vs. metadatos de identificación.
4. Sean **evaluables** (rúbrica + autograder) y alimenten la Serie B donde corresponda (A2 → B1, A4 → B3).
5. Declaring honestamente la naturaleza **sintética** de los datos (principio de transparencia del monorepo).

---

## 2. Principios de diseño

### 2.1 Transparencia pedagógica

Todos los notebooks abren con un bloque fijo:

> Los datasets de `datasets/real/` y `datasets/synthetic/inference/` **no son datos clínicos ni administrativos reales**.  
> Lo auténtico de la literatura son **nombres de variables, diseño del estudio y órdenes de magnitud de referencia**.  
> Los valores numéricos se generan con SEM / fórmulas documentadas para que exista **ground truth** (`truth_*.csv`) usable en evaluación y en autograder.  
> En el flujo del estudiante se usa solo `observed_*.csv` salvo donde el notebook diga explícitamente “evaluación con truth”.

### 2.2 Separación de capas (contrato del benchmark)

| Capa | Archivos | Quién la ve |
|---|---|---|
| Observables | `observed_train.csv`, `observed_validation.csv`, `observed_test.csv` | Estudiante (siempre) |
| Ground truth | `truth_*.csv` (`y0`, `y1`, `tau`) | Autograder / celdas de verificación ocultas o al final |
| Identificación | `identification.json`, `metadata.json` | Lectura guiada; no copiar ciegamente |
| Baseline | `scorecard.json` | Comparar resultados del estudiante |

### 2.3 Reproducibilidad

- Semilla global fija: `RANDOM_STATE = 42` (salvo seeds del generador del dataset, que ya están en `metadata.json`).
- Splits **oficiales** del escenario (`splits.json`); no re-particionar salvo ejercicios de sensibilidad.
- Rutas relativas al repo vía un helper común (ver §4).

### 2.4 Qué cambia respecto a la propuesta original

| Notebook | Propuesta original | Adaptación a este monorepo |
|---|---|---|
| A1 | Lalonde / NSW real | `real/jobs` (LaLonde-style sintético, ATE ≈ 1600) |
| A2 | 401(k) o Card (alta dimensión externa) | `synthetic/inference/ihdp_medium` (25 covars, n=2000) |
| A3 | IHDP | `real/ihdp` (nombres de variables de Hill; truth completo) |
| A4 | Criteo / transferencias | Reutiliza CATE de A3 sobre `real/ihdp` (o `ihdp_medium` si se prefiere más n) |

Razón: no existen 401(k), Card ni Criteo en el catálogo. IHDP-style ofrece dimensionalidad suficiente para DML y CATE; Jobs/LaLonde ofrece narrativa clásica de evaluación de programas.

---

## 3. Selección de datasets

### 3.1 Matriz notebook ↔ dataset

| Notebook | Dataset primario | Ruta relativa desde repo root | Fallback / extensión | Sesiones |
|---|---|---|---|---|
| **A1** | Jobs (LaLonde-style) | `.../datasets/real/jobs/` | `synthetic/inference/lalonde_medium` (sensibilidad n) | S4–S6 |
| **A2** | IHDP medium (sintético) | `.../datasets/synthetic/inference/ihdp_medium/` | `ihdp_large` si se quiere más potencia estadística | S9–S11 |
| **A3** | IHDP real-folder | `.../datasets/real/ihdp/` | `ihdp_medium` si A2/A3 deben compartir n | S13–S14 |
| **A4** | Mismo que A3 | `.../datasets/real/ihdp/` | — | S22–S23 |

Prefijo de datasets (constante del repo):

```text
DATA_ROOT = ../../data_benchmark_causal/causal_benchmark_synthetic/datasets
```

(desde `03_notebooks_caso_estudio/notebooks/`)

### 3.2 Fichas técnicas de los escenarios elegidos

#### A1 — `real/jobs` (`scenario_id: real_jobs`)

| Campo | Valor |
|---|---|
| n total | 1 722 (train 1033 / val 344 / test 345) |
| Covariables | `age, educ, black, hispan, married, nodegree, re74, re75` |
| Tratamiento | `treatment` (binario; tasa ≈ 0.25 en train) |
| Outcome | `re78` (ingresos post) |
| ATE true (`metadata`) | ≈ **1600.26** |
| Truth | `y0, y1, tau` |
| Identificación | `identifiable_by_design_all_simulated_confounders_observed_assumption` |
| Adjustment set (metadata) | las 8 covariables pre-tratamiento |
| Scorecard (test) | naive AE ≈ 28; OLS AE ≈ 14; IPW AE ≈ 107 |

**Por qué A1:** narrativa de evaluación de programa laboral, pocas covariables (PDS/MCO legibles), overlap y confusión observables, ATE de orden de magnitud “LaLonde”.

#### A2 — `synthetic/inference/ihdp_medium` (`scenario_id: synthetic_inference_ihdp_medium`)

| Campo | Valor |
|---|---|
| n total | 2 000 (1200 / 400 / 400) |
| Covariables | `x0`…`x24` (25) |
| Tratamiento | `treatment` (tasa ≈ 0.38) |
| Outcome | `outcome` |
| ATE true | ≈ **3.97** |
| Truth | `y0, y1, tau` |

**Por qué A2:** 25 controles + n=2000 estabilizan DML, cross-fitting y comparación Lasso vs. boosting. Sustituye 401(k)/Card sin salir del monorepo.

#### A3 / A4 — `real/ihdp` (`scenario_id: real_ihdp`)

| Campo | Valor |
|---|---|
| n total | 747 (448 / 149 / 150) |
| Covariables | nombres estilo Hill: `bw, b.head, preterm, momage, cig, …` (25) |
| Tratamiento | `treatment` (tasa ≈ 0.43) |
| Outcome | `outcome` |
| ATE true | ≈ **3.92** |
| Truth | `y0, y1, tau` (heterogeneidad real en `tau`) |
| Scorecard | naive AE ≈ 8.0; OLS AE ≈ 0.86; IPW AE ≈ 0.30; T-learner PEHE ≈ 3.91 |

**Por qué A3:** CATE con nombres interpretables + PEHE posible en autograder.  
**Por qué A4:** política de targeting sobre el mismo CATE (artefacto serializable para B3).

### 3.3 Datasets deliberadamente **no** usados como primarios

| Escenario | Motivo |
|---|---|
| `twins*` | `non_estimable` / control negativo; solo como **ejercicio opcional de abstención** |
| `latent_confounder` | No identificable; opcional en A1 como contrajemplo |
| Redes `sachs/alarm/child/insurance` | Discovery, no Serie A de efectos |
| `timeseries/*` | Fuera del alcance de A1–A4 |

### 3.4 Extensiones opcionales (no bloquean la entrega)

| Opción | Dataset | Cuándo |
|---|---|---|
| A1-extra: no identificable | `synthetic/edge_cases/latent_confounder` | Tras entregar A1 base |
| A1-sensibilidad n | `lalonde_small` vs `lalonde_medium` | Homework avanzado |
| A2-potencia | `ihdp_large` (n=5000) | Si EconML es inestable en medium |
| A5 (futuro): discovery | `real/sachs` | Módulo 5 / S26, no Serie A actual |

---

## 4. Estructura de carpetas a construir

```text
03_notebooks_caso_estudio/
├── README.md                          # índice de la carpeta (este plan + uso)
├── propuesta_notebooks_caso_estudio.md
├── PLAN_NOTEBOOKS_SERIE_A.md          # ← este documento
├── requirements.txt                   # deps de la Serie A
├── environment.yml                    # opcional (conda)
├── lib/                               # código compartido (importable desde notebooks)
│   ├── __init__.py
│   ├── paths.py                       # resolución de DATA_ROOT
│   ├── data_io.py                     # load_scenario(), load_observed(), load_truth()
│   ├── metrics.py                     # ATE error, PEHE, Qini, coverage helpers
│   ├── identification.py              # DAG helpers, propensity, overlap plots
│   ├── dml_utils.py                   # wrappers PLR/IRM, Neyman residual checks
│   ├── cate_utils.py                  # S/T/X/R learners, placebo
│   ├── policy_utils.py                # threshold policy, welfare, uplift curves
│   └── plotting.py                    # estilo único de figuras del curso
├── notebooks/
│   ├── A1_identificacion_jobs.ipynb
│   ├── A2_dml_ihdp_medium.ipynb
│   ├── A3_cate_meta_learners_ihdp.ipynb
│   └── A4_policy_uplift_ihdp.ipynb
├── artifacts/                         # salidas serializadas (gitkeep; no truth)
│   ├── A2/
│   │   └── dml_estimator.joblib       # insumo B1
│   ├── A3/
│   │   └── cate_scores_test.csv
│   └── A4/
│       ├── policy.joblib              # insumo B3
│       └── policy_card.md
├── autograder/                        # scripts de evaluación (usan truth)
│   ├── grade_a1.py
│   ├── grade_a2.py
│   ├── grade_a3.py
│   ├── grade_a4.py
│   └── expected_ranges.yaml           # tolerancias por escenario
├── rubrics/
│   ├── rubrica_a1.md
│   ├── rubrica_a2.md
│   ├── rubrica_a3.md
│   └── rubrica_a4.md
└── tests/
    ├── test_data_io.py
    ├── test_metrics.py
    └── test_smoke_notebooks.py        # ejecuta celdas clave o scripts exportados
```

### 4.1 API mínima de `lib/data_io.py`

```python
def load_scenario(scenario: str) -> ScenarioBundle:
    """
    scenario examples:
      'real/jobs'
      'synthetic/inference/ihdp_medium'
      'real/ihdp'
    Returns:
      train, val, test (DataFrames observed)
      meta, identification, scorecard (dicts)
      paths (Path objects)
    """

def load_truth(scenario: str, split: str = 'test') -> pd.DataFrame:
    """Only for autograder / final evaluation cells."""
```

Convenciones de columnas normalizadas (el loader puede renombrar internamente solo en A2 si se desea unificar `outcome`/`re78` → `Y`, `treatment` → `T`).

| Escenario | Y | T | X |
|---|---|---|---|
| jobs / lalonde_* | `re78` | `treatment` | 8 covars |
| ihdp / ihdp_* | `outcome` | `treatment` | 25 covars |

---

## 5. Dependencias

### 5.1 `requirements.txt` (propuesta)

```text
numpy>=1.24
pandas>=2.0
scipy>=1.10
scikit-learn>=1.3
matplotlib>=3.7
seaborn>=0.13
statsmodels>=0.14
networkx>=3.0
joblib>=1.3
pyyaml>=6.0
econml>=0.15
doubleml>=0.7          # opcional; al menos uno de econml|doubleml
jupyter>=1.0
nbformat>=5.9
nbconvert>=7.0
pytest>=7.0
```

**No requerido en Serie A:** FastAPI, Docker, Gradio, huggingface_hub (Serie B).

### 5.2 Hardware / tiempo de ejecución objetivo

| Notebook | Runtime esperado (CPU laptop) | Límite aceptable |
|---|---|---|
| A1 | < 2 min | 5 min |
| A2 | 3–8 min (cross-fit + 2 learners) | 15 min |
| A3 | 5–12 min (5 estimadores CATE) | 20 min |
| A4 | < 3 min (reusa scores A3) | 8 min |

Si A3 supera el límite: usar `n_estimators` bajos, subsample train, o `ihdp_small` solo en smoke tests.

---

## 6. Plan por notebook

### 6.1 Notebook A1 — Identificación (`A1_identificacion_jobs.ipynb`)

| | |
|---|---|
| **Sesiones** | S4–S6 |
| **Dataset** | `real/jobs` |
| **Técnica** | Pregunta causal, estimando, DAG, overlap, MCO vs PDS |
| **Carga estudiante** | 3–4 h |
| **Alimenta** | — (base conceptual de todo el curso) |

#### Objetivos de aprendizaje

1. Distinguir pregunta predictiva vs. causal en un programa laboral.
2. Declarar estimando ATE y supuestos de identificación (ignorabilidad condicional + overlap + SUTVA).
3. Diagnosticar soporte común (propensity, histogramas por grupo).
4. Comparar: diferencia de medias, OLS ajustado, Post-Double-Selection (Lasso en y y en t).
5. Interpretar resultados **sin** mirar truth en el cuerpo principal.

#### Estructura de celdas (outline)

1. **Setup y transparencia de datos**  
   - Cargar `metadata.json`; imprimir `what_is_real` / `what_is_synthetic` / `ate_true` **no** se usa para “chequear” hasta la sección final opcional.
2. **EDA causal**  
   - Tabla descriptiva tratados vs controles; balance de covariables (SMD).
3. **Pregunta y estimando**  
   - Celda markdown con plantilla a rellenar:  
     - *Unidades, tratamiento, outcome, población, estimando (ATE)*  
     - *DAG supuesto* (diagrama Mermaid o `networkx` dibujado).
4. **Identificación**  
   - Leer `identification.json`; discutir si el adjustment set del archivo es defendible *en el mundo real* vs. *por diseño del SEM*.
5. **Overlap**  
   - Propensity score (logística), recorte 0.02–0.98, % descartado.
6. **Estimación ingenua y ajustada**  
   - Diff-in-means, OLS con 8 covars.
7. **Post-Double-Selection**  
   - Expandir features (polinomios/interacciones ligeras de `age, educ, re74, re75`) para que Lasso tenga algo que seleccionar.  
   - Reportar controles seleccionados + ATE PDS.
8. **Tabla comparativa**  
   - Estimadores vs. scorecard baselines (leer `scorecard.json` como “piso del curso”).
9. **Escritura (obligatoria)**  
   - ½ página: justificación de identificación + un riesgo de validez externa.
10. **(Oculta / final) Chequeo con truth**  
    - AE del ATE del estudiante en test; no sustituye la rúbrica escrita.

#### Entregables del estudiante

- Notebook completado (celdas de escritura no vacías).
- DAG + lista de supuestos.
- Tabla de estimadores.

#### Autograder A1 (`grade_a1.py`)

| Check | Criterio |
|---|---|
| Columnas | no usa `y0/y1/tau` en celdas de estimación |
| ATE OLS / PDS | \|ATE − 1600.26\| en test o full observed dentro de tolerancia generosa (p.ej. AE < 250) |
| Propensity | `0 < e(x) < 1` para ≥ 95% de unidades |
| Texto | celdas markdown de identificación no vacías (heurística de longitud) |

#### Rúbrica (peso sugerido 100)

| Criterio | Puntos |
|---|---|
| Formulación de pregunta + estimando | 20 |
| DAG y supuestos defendibles | 25 |
| Diagnósticos de balance/overlap | 20 |
| Implementación MCO + PDS correcta | 20 |
| Interpretación y límites | 15 |

---

### 6.2 Notebook A2 — Double Machine Learning (`A2_dml_ihdp_medium.ipynb`)

| | |
|---|---|
| **Sesiones** | S9–S11 |
| **Dataset** | `synthetic/inference/ihdp_medium` |
| **Técnica** | PLR y/o IRM, Neyman orthogonality, cross-fitting, sensibilidad de learners |
| **Carga** | 4–5 h |
| **Alimenta** | **B1** (`artifacts/A2/dml_estimator.joblib`) |

#### Objetivos de aprendizaje

1. Especificar PLR: \( Y = \theta T + g(X) + \varepsilon \), \( T = m(X) + \eta \).
2. Implementar *cross-fitting* (K=5) sin fuga entre folds.
3. Verificar residuales de Neyman (correlación residual ~0 con scores de nuisance).
4. Comparar Lasso vs. Gradient Boosting (o RF) en nuisances.
5. Reportar ATE ± IC y comparar con scorecard / ATE true (solo al final).

#### Estructura de celdas

1. Carga de `ihdp_medium`; definición de `Y, T, X`.
2. Baseline: OLS y IPW (repaso A1 a mayor dimensión).
3. **DML-PLR** con `econml.dml.LinearDML` (o `DoubleMLPLR`):
   - `model_y`, `model_t` = LassoCV.
   - `cv=5`, `random_state=42`.
4. Diagnóstico de ortogonalidad:
   - Residuales \(\tilde Y, \tilde T\); correlación y scatter.
5. Segunda especificación: `HistGradientBoosting` / `RandomForest` en nuisances.
6. (Opcional avanzado) IRM / `CausalForestDML` solo ATE agregado.
7. Tabla: learner × ATE × SE × AE vs `ate_true`.
8. **Serialización** del estimador final (el de menor AE o el pre-especificado “oficial del curso”: LinearDML + Lasso).
9. Nota de model card mínima (estimando, población, supuestos) → anticipa B2.

#### Artefacto para Serie B

```text
artifacts/A2/dml_estimator.joblib
artifacts/A2/feature_list.json
artifacts/A2/training_meta.json   # scenario_id, seed, ATE point estimate, IC
```

#### Autograder A2

| Check | Criterio |
|---|---|
| Cross-fitting | función de folds no reutiliza índices de train en residuales de test fold |
| ATE | AE vs `ate_true≈3.97` < 0.5 (ajustable; scorecard IPW en real/ihdp es ~0.3) |
| IC | contiene `ate_true` (cobertura del punto) **o** longitud de IC documentada si falla por azar |
| Artefacto | `dml_estimator.joblib` existe y `predict` / `const_marginal_ate` responde |

#### Rúbrica

| Criterio | Puntos |
|---|---|
| Especificación PLR correcta | 20 |
| Cross-fitting sin fuga | 25 |
| Diagnóstico Neyman | 15 |
| Sensibilidad de learners | 20 |
| Interpretación + serialización | 20 |

---

### 6.3 Notebook A3 — CATE: meta-learners y bosque causal (`A3_cate_meta_learners_ihdp.ipynb`)

| | |
|---|---|
| **Sesiones** | S13–S14 |
| **Dataset** | `real/ihdp` |
| **Técnica** | S/T/X/R-learner, GRF/CausalForest, Qini, placebo |
| **Carga** | 4–5 h |
| **Alimenta** | A4 (scores CATE); opcionalmente tabla PEHE |

#### Objetivos de aprendizaje

1. Estimar CATE con cuatro meta-learners sobre el mismo split.
2. Entrenar bosque causal honesto (EconML `CausalForestDML` o GRF si está disponible).
3. Validar **sin truth en el cuerpo principal**: curva Qini / uplift y prueba placebo.
4. (Sección final) PEHE y MAE(τ) con `truth_test.csv` para cerrar el ciclo pedagógico.
5. Discutir desbalance tratados/controles y cuándo preferir X-learner.

#### Estructura de celdas

1. Carga `real/ihdp`; EDA de `treatment` y `outcome`.
2. Helpers de meta-learners en `lib/cate_utils.py` (implementación didáctica con sklearn):
   - S-learner, T-learner, X-learner, R-learner (R puede ser simplificado).
3. `CausalForestDML` (EconML) como quinto estimador.
4. Histogramas / KDE de \(\hat\tau(x)\) para los 5 métodos.
5. **Validación offline sin truth:**
   - Curva Qini en validation/test (ranking por \(\hat\tau\)).
   - Placebo: permutar `treatment`, reestimar T-learner, \|ATE\| ≈ 0.
6. Tabla PEHE (con truth, celda marcada “solo evaluación”):
   - Comparar con `scorecard.json` → `inference_t_learner_random_forest.pehe`.
7. Discusión guiada: ¿qué learner eliges para A4 y por qué?

#### Artefactos

```text
artifacts/A3/cate_scores_test.csv     # row_id, tau_hat_<method>, method_selected
artifacts/A3/qini_plot.png
artifacts/A3/cate_comparison.png
```

#### Autograder A3

| Check | Criterio |
|---|---|
| Placebo | \|ATE_placebo\| < umbral (p.ej. 0.5 en escala IHDP) o p-value > 0.1 |
| PEHE T-learner | del orden del scorecard (no exigir superarlo; techo p.ej. PEHE < 8) |
| Cinco distribuciones | archivo de figura o columnas en csv presentes |
| No data leakage | truth no aparece en celdas de entrenamiento (grep de notebook) |

#### Rúbrica

| Criterio | Puntos |
|---|---|
| Meta-learners correctos | 30 |
| Bosque causal | 15 |
| Qini + placebo | 25 |
| PEHE / comparación | 15 |
| Discusión metodológica | 15 |

---

### 6.4 Notebook A4 — Policy learning y uplift (`A4_policy_uplift_ihdp.ipynb`)

| | |
|---|---|
| **Sesiones** | S22–S23 |
| **Dataset** | `real/ihdp` (+ artefactos A3) |
| **Técnica** | Regla de umbral bajo presupuesto, welfare, uplift, baselines, equidad |
| **Carga** | 4–5 h |
| **Alimenta** | **B3** (`artifacts/A4/policy.joblib`) |

#### Objetivos de aprendizaje

1. Convertir \(\hat\tau(x)\) en política \(\pi(x) \in \{0,1\}\) bajo presupuesto (tratar al top-k% o umbral).
2. Estimar *value* / welfare de la política (con truth en evaluación; sin truth usar IPW value estimator).
3. Comparar vs. baseline aleatorio y baseline “tratar a los de peor outcome predicho” (riesgo, no causal).
4. Auditar equidad simple (p.ej. tasa de tratamiento por `sex`, `b.marr`, o terciles de `bw`).
5. Serializar la política para un Space Gradio (B3).

#### Estructura de celdas

1. Cargar `cate_scores_test.csv` de A3 (o reestimar T-learner embebido si A3 no está).
2. Definir presupuesto \(B \in \{10\%, 20\%, 30\%\}\) de la población tratable.
3. Política óptima miópica: tratar si \(\hat\tau(x) > \lambda\) calibrado a B.
4. Curvas de uplift / Qini de la política.
5. Baselines: random, outcome-model-only.
6. Tabla welfare (con `tau` de truth solo en celda de evaluación).
7. Análisis de equidad: tablas de composición de tratados bajo \(\pi\).
8. Export: `policy.joblib` con interfaz `predict(X) -> {decision, uplift_score}`.
9. `policy_card.md`: población, presupuesto, supuestos, límites.

#### Artefactos

```text
artifacts/A4/policy.joblib
artifacts/A4/policy_card.md
artifacts/A4/uplift_curve.png
artifacts/A4/equity_table.csv
```

#### Autograder A4

| Check | Criterio |
|---|---|
| Presupuesto | fracción tratada ≈ B ± 2 pp |
| Welfare | value(π) ≥ value(random) − holgura |
| Artefacto | `policy.predict` sobre 3 filas dummy |
| Equidad | tabla generada (existencia), no un umbral moral automático |

#### Rúbrica

| Criterio | Puntos |
|---|---|
| De CATE a política bajo B | 25 |
| Uplift / Qini | 20 |
| Baselines | 20 |
| Equidad y límites | 20 |
| Serialización + policy card | 15 |

---

## 7. Flujo de datos entre notebooks y Serie B

```text
real/jobs ──────────────────────► A1 (identificación)
                                      │
synthetic/.../ihdp_medium ──────► A2 (DML) ──joblib──► B1 FastAPI/Docker
                                      │                      │
                                      │                      └► B2 HF Hub + CI
                                      │
real/ihdp ──────────────────────► A3 (CATE) ──scores──► A4 (policy) ──joblib──► B3 Space
                                      │                      │
                                      └──── PEHE/truth       └► equity notes
                                                             (B4 monitorea endpoint B1/B2)
```

---

## 8. Fases de implementación (para el equipo docente / desarrollo)

### Fase 0 — Infraestructura (0.5–1 día)

- [ ] Crear árbol de carpetas §4.
- [ ] Implementar `lib/paths.py` + `lib/data_io.py`.
- [ ] `requirements.txt` + smoke: cargar los 3 escenarios y shapes correctos.
- [ ] Tests `tests/test_data_io.py`.
- [ ] README de la carpeta con instrucciones de entorno.

### Fase 1 — Notebook A1 (1–1.5 días)

- [ ] Outline de celdas + markdown pedagógico en español.
- [ ] EDA, propensity, OLS, PDS en `lib/`.
- [ ] Notebook ejecutable end-to-end.
- [ ] `grade_a1.py` + `rubrics/rubrica_a1.md`.
- [ ] Revisión: no se filtra `truth` en secciones de estudiante.

### Fase 2 — Notebook A2 (1.5–2 días)

- [ ] Wrapper DML en `lib/dml_utils.py`.
- [ ] Dos learners + tabla + serialización.
- [ ] Autograder A2 + tolerancia en `expected_ranges.yaml`.
- [ ] Verificar que el joblib es cargable en un script mínimo estilo B1.

### Fase 3 — Notebook A3 (2 días)

- [ ] Meta-learners didácticos + CausalForest.
- [ ] Qini + placebo.
- [ ] Figuras comparativas.
- [ ] Autograder A3 (placebo + techo PEHE).

### Fase 4 — Notebook A4 (1–1.5 días)

- [ ] Policy utils + baselines + equity.
- [ ] Export policy + policy card.
- [ ] Autograder A4.
- [ ] Contrato de interfaz documentado para B3.

### Fase 5 — Integración y calidad (1 día)

- [ ] `tests/test_smoke_notebooks.py` o ejecución `nbconvert --execute` con timeout.
- [ ] Unificar estilo de plots y avisos de transparencia.
- [ ] Checklist de paths relativos desde `notebooks/`.
- [ ] Actualizar `propuesta_notebooks_caso_estudio.md` con la tabla de datasets **final** (este plan).
- [ ] (Opcional) CI GitHub Actions: pytest + grade scripts en dry-run.

**Esfuerzo total estimado:** 7–10 días-persona para una versión docente lista.

---

## 9. Contrato de evaluación (`expected_ranges.yaml` — borrador)

```yaml
# autograder/expected_ranges.yaml
a1_jobs:
  scenario: real/jobs
  ate_true: 1600.26
  max_abs_error_ols: 250.0
  max_abs_error_pds: 250.0
  min_propensity: 0.01
  max_propensity: 0.99

a2_ihdp_medium:
  scenario: synthetic/inference/ihdp_medium
  ate_true: 3.9685
  max_abs_error_dml: 0.5
  require_artifact: artifacts/A2/dml_estimator.joblib

a3_ihdp:
  scenario: real/ihdp
  ate_true: 3.9185
  max_pehe_t_learner: 8.0
  max_abs_ate_placebo: 0.5

a4_ihdp:
  scenario: real/ihdp
  budget_fraction: 0.20
  budget_tolerance: 0.02
  require_artifact: artifacts/A4/policy.joblib
  welfare_beats_random: true
```

Los umbrales se **calibran** ejecutando una solución de referencia (`notebooks/solutions/` opcional, no publicada a estudiantes) antes de abrir el curso.

---

## 10. Contenido pedagógico fijo (snippets a reutilizar)

### 10.1 Bloque de transparencia (todas las series A)

Insertar al inicio de cada notebook (markdown):

```markdown
## Aviso sobre los datos

Este notebook usa un escenario del **Causal Benchmark Ecosystem**.
Los archivos en `datasets/real/` son **sintéticos con semántica de la literatura**:
las estructuras de referencia y los ATEs de orden de magnitud son reales;
los valores numéricos se generan para permitir evaluación con ground truth.
Consulta `metadata.json` → campos `what_is_real` / `what_is_synthetic`.
```

### 10.2 Política de uso de `truth_*.csv`

| Sección del notebook | ¿Truth permitido? |
|---|---|
| EDA, identificación, entrenamiento | **No** |
| Diagnósticos de solapamiento, Qini, placebo | **No** |
| Celda “Evaluación con ground truth” (final) | **Sí**, claramente marcada |
| Autograder | **Sí** |

### 10.3 Lenguaje de identificación

Insistir en que `identification.json` del benchmark es una **anotación de diseño del SEM**, no una prueba empírica de ignorabilidad en el mundo real. El estudiante debe contrastar:

1. Identificación *por construcción del simulador*.
2. Identificación *que defendería en un paper con datos reales del mismo dominio*.

---

## 11. Mapeo a monografía y sílabo

| Notebook | Capítulos monografía | Módulo sílabo |
|---|---|---|
| A1 | Cap. 1, 4, 6 (+16 opcional) (causal elemental, datos, regularización/PDS) | Módulo 1 |
| A2 | Cap. 10–11 (Neyman, DML) | Módulo 2 |
| A3 | Cap. 12–13 (meta-learners, bosques) | Módulo 2 |
| A4 | Cap. 21–22 (policy, uplift) | Módulo 4 |

La evaluación offline sin truth (A3) enlaza con Cap. 14 (Validación).

---

## 12. Riesgos y mitigaciones

| Riesgo | Mitigación |
|---|---|
| Estudiantes confunden sintético con real | Bloque de transparencia + pregunta de reflexión obligatoria en A1 |
| EconML frágil / lento en Windows | Pin de versión; fallback sklearn-only en `lib/`; smoke en CI Linux |
| A3 con n=747 inestable | Reducir hiperparámetros; permitir `ihdp_medium` como alternativa documentada |
| Fuga de truth en notebooks entregados | Autograder con grep; rúbrica penaliza uso de `y0/y1/tau` fuera de sección final |
| Paths rotos al mover carpetas | Único `DATA_ROOT` en `lib/paths.py` basado en ubicación del archivo |
| A2 no “se siente” de alta dimensión | Expandir polinomios grado 2 de un subconjunto o usar las 25 covars + interacciones seleccionadas |
| Desalineación A3→A4 si reestiman distinto | Fijar `method_selected: t_learner` por defecto en el curso |

---

## 13. Criterios de “Definition of Done” de la Serie A

La Serie A se considera **lista para el curso** cuando:

1. Los cuatro notebooks ejecutan de punta a punta en un entorno limpio con `requirements.txt`.
2. `pytest tests/` pasa (I/O + métricas + smoke).
3. Los cuatro `grade_a*.py` pasan sobre la **solución de referencia**.
4. Existen artefactos A2 y A4 con interfaz documentada para B1 y B3.
5. Cada notebook declara dataset (`scenario_id`), seed y límites de validez.
6. Ningún notebook primario depende de descargas externas ni de datos fuera de `causal_benchmark_synthetic/datasets/`.

---

## 14. Orden de construcción recomendado (checklist operativa)

```text
[ ] 0.1  lib/paths.py + data_io.py
[ ] 0.2  requirements + env smoke
[ ] 1.1  A1 markdown skeleton
[ ] 1.2  A1 código + rúbrica + grader
[ ] 2.1  A2 DML + artifact joblib
[ ] 2.2  A2 grader + test load joblib
[ ] 3.1  A3 meta-learners + plots
[ ] 3.2  A3 placebo/Qini + grader
[ ] 4.1  A4 policy + equity + artifact
[ ] 4.2  A4 grader
[ ] 5.1  nbconvert smoke all
[ ] 5.2  actualizar propuesta_*.md con datasets finales
[ ] 5.3  handoff doc para Serie B (interfaces)
```

---

## 15. Tabla resumen final (fuente de verdad de esta carpeta)

| ID | Archivo notebook | Dataset (`scenario_id`) | Técnica | Truth en autograder | Artefacto salida | Sesiones |
|---|---|---|---|---|---|---|
| A1 | `notebooks/A1_identificacion_jobs.ipynb` | `real_jobs` | Identificación, overlap, OLS, PDS | ATE AE | justificación escrita | S4–S6 |
| A2 | `notebooks/A2_dml_ihdp_medium.ipynb` | `synthetic_inference_ihdp_medium` | DML PLR, Neyman, CF | ATE AE + IC | `dml_estimator.joblib` → B1 | S9–S11 |
| A3 | `notebooks/A3_cate_meta_learners_ihdp.ipynb` | `real_ihdp` | S/T/X/R + CF, Qini, placebo | PEHE, placebo | `cate_scores_test.csv` → A4 | S13–S14 |
| A4 | `notebooks/A4_policy_uplift_ihdp.ipynb` | `real_ihdp` | Policy, uplift, equity | welfare vs random | `policy.joblib` → B3 | S22–S23 |

---

## 16. Próximo paso inmediato

Cuando se apruebe este plan, la implementación debe empezar por **Fase 0 + A1** (desbloquea el lenguaje de datos del curso) y en paralelo pin de dependencias EconML para A2/A3.

No se deben crear notebooks vacíos masivos sin `lib/data_io.py`: el helper de carga es el cuello de botella compartido.

---

*Plan alineado con `propuesta_notebooks_caso_estudio.md`, el sílabo (`01_silabo/`), el esqueleto de monografía (`02_monografia_esqueleto/`) y el contrato `BENCHMARK_SCHEMA.md` del release sintético.*
