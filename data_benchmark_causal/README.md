# Causal Benchmark Ecosystem

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](./LICENSE)
[![Python 3.10+](https://img.shields.io/badge/python-3.10+-blue.svg)](https://www.python.org/downloads/)

Repositorio monolítico para **evaluación reproducible** de algoritmos de descubrimiento causal e inferencia causal. Combina un framework Python de carga y métricas con una colección documentada de escenarios de benchmark.

| Componente | Descripción | Rol |
|---|---|---|
| [`causal_benchmark_zoo/`](./causal_benchmark_zoo/) | Paquete Python (`causal-benchmark-zoo`) | **Framework** — registro, carga, validación y métricas |
| [`causal_benchmark_synthetic/`](./causal_benchmark_synthetic/) | 43 escenarios con splits oficiales | **Datasets** — ground truth documentado y scorecards baseline |

> **Principio compartido:** ningún componente sustituye fuentes inaccesibles con datos no documentados. El origen de cada artefacto queda explícito en manifests o `metadata.json`.

---

## Tabla de contenidos

- [Inicio rápido](#inicio-rápido)
- [Inventario de datasets](#inventario-de-datasets)
- [Componentes](#componentes)
- [Relación entre componentes](#relación-entre-componentes)
- [Verificación de proveniencia](#verificación-de-proveniencia)
- [Limitaciones](#limitaciones)
- [Documentación adicional](#documentación-adicional)
- [Licencia y citación](#licencia-y-citación)

---

## Inicio rápido

### Requisitos

- Python 3.10+
- Dependencias base: `numpy`, `pandas`, `PyYAML`, `jsonschema`, `networkx`

### Clonar e instalar el framework

```bash
git clone https://github.com/OWNER/causal-benchmark-ecosystem.git
cd causal-benchmark-ecosystem/causal_benchmark_zoo
pip install .

# Adaptadores opcionales
pip install .[dowhy]    # integración DoWhy
pip install .[econml]   # integración EconML
pip install .[dev]      # pytest
```

### Listar y cargar benchmarks del zoo

```bash
python -m causal_benchmark_zoo.fetch list
python -m causal_benchmark_zoo.fetch validate-all
python -m causal_benchmark_zoo.fetch inspect bnlearn_asia
```

```python
from causal_benchmark_zoo import list_benchmarks, load_benchmark, evaluate_graph

bench = load_benchmark("bnlearn_asia")
metrics = evaluate_graph(bench.graph, predicted_graph)
```

### Usar los datasets sintéticos

```bash
cd ../causal_benchmark_synthetic

# Validar integridad del release
python scripts/00_validate_benchmark.py --root .

# Entradas de modelo: observed_train.csv, observed_validation.csv, observed_test.csv
# Evaluación: graph_*, truth_*, scorecard.json (según escenario)
```

Consulta [`causal_benchmark_synthetic/RELEASE_README.md`](./causal_benchmark_synthetic/RELEASE_README.md) para la guía de release v1.

---

## Inventario de datasets

**43 escenarios** en total (`release_index/dataset_index.csv`):

| Categoría | Cantidad | Tareas principales |
|---|---:|---|
| Basados en literatura (`datasets/real/`) | 7 | Descubrimiento e inferencia con referencias publicadas |
| Sintéticos controlados (`datasets/synthetic/`) | 36 | Lineal Gaussiano, no Gaussiano, no lineal, series temporales, inferencia, casos borde |

**Desglose sintético (36):**

| Subcategoría | Escenarios |
|---|---:|
| `linear_gaussian/` | 9 |
| `non_gaussian/` | 6 |
| `nonlinear/` | 6 |
| `timeseries/` | 5 |
| `inference/` | 7 |
| `edge_cases/` | 3 |

**Tipos de tarea registrados:**

| Tipo | Escenarios |
|---|---:|
| `structure_discovery` | 27 |
| `inference_effect_estimation` | 7 |
| `time_series_link_recovery` | 5 |
| `no_scored_target` | 4 |

---

## Componentes

### 1. `causal_benchmark_zoo` — Framework

**Ubicación:** [`causal_benchmark_zoo/`](./causal_benchmark_zoo/)

Paquete instalable que estandariza manifests YAML, carga de datos, validación JSON Schema, métricas de grafo (SHD, precision, recall, F1) y adaptadores para DoWhy y EconML.

```
causal_benchmark_zoo/
├── causal_benchmark_zoo/     # API pública, loader, registry, fetch CLI
├── benchmarks/             # bnlearn_asia, bnlearn_alarm, lalonde_nsw, csuite_lingauss
├── schemas/                # manifest, graph, ground_truth
├── examples/               # ejemplos de uso
├── tests/                  # pytest
├── docs/                   # guías técnicas y reportes de integración
└── audit_outputs/          # matrices de readiness de referencia (stage 7)
```

**Benchmarks registrados:**

| ID | Categoría | Ground truth | Estado |
|---|---|---|---|
| `bnlearn_asia` | Red Bayesiana | Grafo (8 nodos, 8 arcos) | Disponible |
| `bnlearn_alarm` | Red Bayesiana | Grafo (37 nodos, 46 arcos) | Disponible |
| `lalonde_nsw` | Referencia experimental | ATE experimental (1,794.34 ± 671) | Disponible |
| `csuite_lingauss` | SEM sintético | `sem` | Manual (HTTP 403 en descarga pública) |

Documentación detallada: [`causal_benchmark_zoo/README.md`](./causal_benchmark_zoo/README.md)

### 2. `causal_benchmark_synthetic` — Datasets

**Ubicación:** [`causal_benchmark_synthetic/`](./causal_benchmark_synthetic/)

Colección versionada con contrato de calidad (`BENCHMARK_SCHEMA.md`), índices maestros, scripts de validación/evaluación y scorecards baseline agregados.

```
causal_benchmark_synthetic/
├── datasets/
│   ├── real/               # 7 escenarios con referencias bibliográficas
│   └── synthetic/          # 36 escenarios controlados
├── scripts/                # 00_validate … 05_run_full_pipeline
├── release_index/          # dataset_index.csv, task_index.csv, known_issues.csv
├── results/
│   ├── scorecards/         # métricas baseline agregadas
│   └── validation/         # reportes de validación
└── docs/
    ├── DATASET_CATALOG.md
    └── METRICS_GUIDE.md
```

**Formato por escenario (mínimo):**

| Archivo | Uso |
|---|---|
| `observed_train.csv`, `observed_validation.csv`, `observed_test.csv` | Entrada del modelo |
| `metadata.json` | Proveniencia y roles de variables |
| `scm.json`, `interventions.json`, `identification.json` | Mecanismo generador e identificabilidad |
| `graph_adjmatrix.csv`, `graph_edges.csv` | Ground truth estructural (si aplica) |
| `scorecard.json` | Baselines de referencia |
| `splits.json` | Definición de particiones |

Documentación detallada: [`causal_benchmark_synthetic/README.md`](./causal_benchmark_synthetic/README.md)

---

## Relación entre componentes

```
causal_benchmark_zoo (framework)
│   Manifests YAML · loaders · métricas · CLI · adaptadores DoWhy/EconML
│
└── benchmarks/<id>/          ← formato estandarizado por manifest

causal_benchmark_synthetic (datasets)
│   43 escenarios · CSV/JSON · scorecards · release_index
│
└── datasets/<scenario>/      ← formato compatible a nivel tabular/grafos
```

- **Zoo** aporta infraestructura técnica para consumir benchmarks de forma uniforme.
- **Synthetic** aporta el contenido evaluable con splits, metadatos y baselines.
- Los formatos son **compatibles a nivel de archivos** (`metadata.json`, CSV observacionales, matrices de adyacencia). No existe aún un adaptador empaquetado que registre automáticamente los escenarios synthetic en el zoo; la integración puede implementarse siguiendo [`docs/adding_a_dataset.md`](./causal_benchmark_zoo/docs/adding_a_dataset.md).
- Los scripts en `causal_benchmark_synthetic/scripts/` funcionan de forma autónoma.

---

## Verificación de proveniencia

Referencias bibliográficas verificadas para escenarios basados en literatura:

| Escenario | Referencia | Verificación |
|---|---|---|
| **Sachs** | Sachs et al. (2005), *Science* | [DOI 10.1126/science.1109447](https://doi.org/10.1126/science.1109447) |
| **ALARM** | Beinlich et al. (1989) | bnlearn repository |
| **CHILD** | Spiegelhalter & Cowell (1992) | bnlearn repository |
| **Insurance** | Binder et al. (1997) | bnlearn repository |
| **IHDP** | Hill (2011), *JCGS* | [DOI 10.1198/jcgs.2010.08162](https://doi.org/10.1198/jcgs.2010.08162) |
| **Jobs** | LaLonde (1986), *AER* | NBER / Dehejia-Wahba |
| **Twins** | Almond et al. (2005), NBER WP 11796 | NBER |

**Transparencia de datos:** en `datasets/real/`, las **estructuras causales y ATEs de referencia** provienen de la literatura; los **valores numéricos observados** se generan mediante SEM documentado. Ver `what_is_real` / `what_is_synthetic` en cada `metadata.json`.

**Discrepancias documentadas:**

| Escenario | Nota |
|---|---|
| Sachs | README histórico cita 18 arcos; gold estándar bnlearn usa 17 |
| IHDP | Versión propia con covariables ~N(0,1), no el IHDP semisintético original |
| Twins | Marcado como control negativo no estimable (`ate_true: 0.0`) |

---

## Limitaciones

### Framework (`causal_benchmark_zoo`)

- `csuite_lingauss` permanece manual por restricciones de acceso HTTP 403.
- El ATE de LaLonde es una **estimación experimental** con incertidumbre muestral, no una constante exacta.
- Las métricas de grafo no implican validez de efectos de tratamiento.

### Datasets (`causal_benchmark_synthetic`)

- Escenarios **Twins** (real e inferencia) son controles negativos, no datos de entrenamiento ATE/CATE.
- Algunos `scm.json` son parciales (`parameters_available: false`).
- Inconsistencia menor de versiones de schema entre `metadata.json` (stage2) y `scm.json` (stage3).
- `data.csv` legacy puede contener columnas de truth; preferir siempre `observed_*.csv`.
- Scorecards usan algoritmos simples como piso cuantitativo, no referencias optimizadas.

Detalle ampliado:

- [`causal_benchmark_zoo/LIMITATIONS.md`](./causal_benchmark_zoo/LIMITATIONS.md)
- [`causal_benchmark_synthetic/BENCHMARK_SCHEMA.md`](./causal_benchmark_synthetic/BENCHMARK_SCHEMA.md)

---

## Documentación adicional (local)

| Documento | Contenido |
|---|---|
| [`causal_benchmark_zoo/DATASETS.md`](./causal_benchmark_zoo/DATASETS.md) | Catálogo y estado de benchmarks del zoo |
| [`causal_benchmark_synthetic/BENCHMARK_SCHEMA.md`](./causal_benchmark_synthetic/BENCHMARK_SCHEMA.md) | Contrato de calidad de escenarios |
| [`causal_benchmark_synthetic/docs/DATASET_CATALOG.md`](./causal_benchmark_synthetic/docs/DATASET_CATALOG.md) | Catálogo detallado por escenario |
| [`causal_benchmark_synthetic/docs/METRICS_GUIDE.md`](./causal_benchmark_synthetic/docs/METRICS_GUIDE.md) | Definición de métricas |

---

## Licencia y citación

### Licencia

- **Código del monorepo:** [MIT](./LICENSE)
- **`causal_benchmark_zoo`:** [MIT](./causal_benchmark_zoo/LICENSE); datos bnlearn sujetos a términos del repositorio bnlearn; LaLonde/NSW CC BY-NC (NBER/Dehejia-Wahba)
- **`causal_benchmark_synthetic`:** [MIT](./causal_benchmark_synthetic/LICENSE); escenarios basados en literatura sujetos a licencias de sus fuentes

### Citación

```bibtex
@software{causal_benchmark_ecosystem,
  title = {Causal Benchmark Ecosystem},
  author = {Santibanez Uribe, Segundo Alejandro},
  year = {2026},
  url = {https://github.com/OWNER/causal-benchmark-ecosystem}
}
```

También cite las referencias originales de los escenarios individuales (Sachs, ALARM, Hill, LaLonde, etc.) según [`CITATION.cff`](./CITATION.cff).

---

*Repositorio de benchmarks causales — descubrimiento estructural e inferencia con ground truth verificado y proveniencia documentada.*
