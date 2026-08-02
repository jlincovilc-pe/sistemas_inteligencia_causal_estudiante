# BENCHMARK_SCHEMA.md

Contrato mínimo para datasets de entrenamiento y evaluación causal.

## Principio central

Un escenario causal debe separar tres capas:

1. **Datos observables**: lo que recibe el algoritmo.
2. **Ground truth**: potenciales, efectos y grafo verdadero usados solo para evaluación.
3. **Mecanismo generador**: SCM completo para auditoría y regeneración.

## Estructura recomendada por escenario

```text
scenario_name/
├── observed_train.csv
├── observed_validation.csv
├── observed_test.csv
├── truth_train.csv
├── truth_validation.csv
├── truth_test.csv                  # o mantener oculto fuera del paquete público
├── graph.csv                       # nodos con mismos nombres que observed_*.csv
├── scm.json
├── interventions.json
├── identification.json
├── metadata.json
└── README.md
```

Durante la transición desde el formato actual, `data.csv`, `data_public.csv`, `graph_adjmatrix.csv` y `graph_edges.csv` siguen siendo aceptados, pero el validador los marca como formato legado.

## `metadata.json` mínimo

```json
{
  "schema_version": "1.0",
  "scenario_id": "ihdp_v2_medium_seed_001",
  "task_types": ["ate", "cate"],
  "data_generating_process": "synthetic_scm",
  "n_train": 2000,
  "n_validation": 1000,
  "n_test": 5000,
  "variables": [
    {"name": "x0", "role": "covariate", "observed": true, "type": "continuous"},
    {"name": "treatment", "role": "treatment", "observed": true, "type": "binary"},
    {"name": "outcome", "role": "outcome", "observed": true, "type": "continuous"}
  ],
  "treatments": ["treatment"],
  "outcomes": ["outcome"],
  "latent_variables": [],
  "known_adjustment_sets": [["x0", "x1"]],
  "identifiability": "identifiable_backdoor",
  "difficulty_tags": ["moderate_confounding", "heterogeneous_effect"],
  "ground_truth_available": ["ate", "att", "ite", "graph", "scm"]
}
```

## Reglas de validación

### Reglas bloqueantes (`error`)

- Dataset sin datos observables (`observed_*.csv`, `data_public.csv`, `data.csv` o equivalente documentado).
- Tratamiento binario con una sola clase en un dataset marcado como inferencia causal estimable.
- Outcome constante en un dataset de inferencia causal estimable.
- `outcome` inconsistente con `y0/y1/tau`: debe cumplirse `outcome = y1` si `treatment=1`, y `outcome = y0` si `treatment=0`.
- Grafo estático con ciclos si el escenario se declara DAG.

### Advertencias (`warning`)

- Columnas constantes no documentadas.
- Missing values no documentados como escenario de missingness.
- Duplicados exactos no documentados.
- `data.csv` contiene `y0`, `y1` o `tau`; debe separarse en `truth.csv`.
- `graph_adjmatrix.csv` usa nombres distintos a columnas observables y no existe `variable_mapping.csv`.
- Falta `scm.json`, `interventions.json`, `identification.json` o splits oficiales.
- Metadatos sin `schema_version` o sin `scenario_id`.

## Métricas mínimas por tarea

- Inferencia ATE/ATT: error absoluto, sesgo, intervalo de confianza y cobertura si hay replicaciones.
- CATE/ITE: PEHE y MAE de tau.
- Descubrimiento causal: SHD, precisión/recall/F1 skeleton, precisión/recall/F1 dirigido, orientación cuando sea identificable.
- Series temporales: precisión/recall por link `(source, target, lag)`.

## Versionado

Cualquier cambio que modifique datos, SCM, targets causales o splits debe cambiar `scenario_id` o incrementar `schema_version` si cambia el contrato.
