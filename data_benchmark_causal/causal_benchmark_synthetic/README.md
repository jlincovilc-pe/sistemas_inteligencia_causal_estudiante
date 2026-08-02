# Causal Discovery Benchmark Datasets

[![License: MIT](./LICENSE)](./LICENSE)

Parte del [Causal Benchmark Ecosystem](../README.md). Release **v1** con **43 escenarios** documentados, splits oficiales y scorecards baseline.

| Recurso | Descripción |
|---|---|
| [`RELEASE_README.md`](./RELEASE_README.md) | Guía de uso del release v1 |
| [`BENCHMARK_SCHEMA.md`](./BENCHMARK_SCHEMA.md) | Contrato de calidad de escenarios |
| [`release_index/dataset_index.csv`](./release_index/dataset_index.csv) | Inventario maestro (43 escenarios) |
| [`docs/DATASET_CATALOG.md`](./docs/DATASET_CATALOG.md) | Catálogo detallado |
| [`docs/METRICS_GUIDE.md`](./docs/METRICS_GUIDE.md) | Guía de métricas |

## Descripcion

Este paquete contiene un conjunto completo de **datasets de benchmark** disenados para evaluar sistematicamente algoritmos de descubrimiento causal e inferencia.

> **⚠️ TRANSPARENCIA SOBRE EL ORIGEN DE LOS DATOS**
>
> Ninguno de los datasets en la carpeta `datasets/real/` contiene datos observacionales reales.
> **Todos son generados sinteticamente** mediante modelos de ecuaciones estructurales (SEM).
> Lo que es autentico de la literatura es:
> - **Las estructuras causales (grafos)** extraidas de papers revisados por pares (Sachs 2005, ALARM, CHILD, Insurance)
> - **Los valores de ATE de referencia** reportados en estudios originales (IHDP, LaLonde, Twins)
> - **Los nombres de variables y dominios de aplicacion**
>
> Los valores numericos en todos los casos son generados computacionalmente. Esto permite
> tener ground truth conocido (estructura causal exacta, ATE verdadero) para evaluacion,
> pero NO representa datos reales de pacientes, proteinas o asegurados.

Los benchmarks estan organizados en tres categorias:
- **Descubrimiento Causal Estructural**: Datasets con ground truth conocido (grafo real, datos sinteticos) para evaluar algoritmos PC, FCI, GES, FGES, NOTEARS, GOLEM, ICA-LiNGAM, DirectLiNGAM, PCMCI
- **Inferencia Causal (Efectos de Tratamiento)**: Datasets con contrafactuales observables generados sinteticamente para evaluar estimadores ATE/ATT/CATE
- **Sinteticos Controlados**: Datasets generados con estructuras causales conocidas para analisis sistematico (estos si son explicitamente sinteticos desde cero)

---

## Referencias Bibliograficas Principales

### Algoritmos de Descubrimiento Causal

2. **Spirtes et al. (2000)** - "Constructing Bayesian Network Models of Gene Expression Networks from Microarray Data". Proc. of the Atlantic Symposium on Computational Biology, Genome Information Systems & Technology. *(Algoritmo PC)*

3. **Spirtes et al. (2000)** - "Causation, Prediction, and Search", 2nd ed. MIT Press. *(Algoritmo FCI para variables latentes)*

4. **Chickering (2002)** - "Optimal Structure Identification with Greedy Search". Journal of Machine Learning Research, 3, 507-554. *(Algoritmo GES)*

5. **Ramsey et al. (2017)** - "A Million Variables and More: the Fast Greedy Equivalence Search Algorithm for Learning High-Dimensional Graphical Causal Models, with an Application to Functional Magnetic Resonance Images". International Journal of Data Science and Analytics. *(FGES)*

6. **Zheng et al. (2018)** - "DAGs with NO TEARS: Continuous Optimization for Structure Learning". NeurIPS 2018. *(NOTEARS)*

7. **Ng et al. (2020)** - "A Constrained Optimization Algorithm for Learning DAGs with GOLEM". NeurIPS 2020. *(GOLEM)*

8. **Shimizu et al. (2006)** - "A Linear Non-Gaussian Acyclic Model for Causal Discovery". Journal of Machine Learning Research, 7, 2003-2030. *(ICA-LiNGAM)*

9. **Shimizu (2011)** - "DirectLiNGAM: A Direct Method for Learning a Linear Non-Gaussian Structural Equation Model". Journal of Machine Learning Research, 12, 1225-1248. *(DirectLiNGAM)*

10. **Runge et al. (2019)** - "Detecting and Quantifying Causal Associations in Large Nonlinear Time Series Datasets". Science Advances, 5(11), eaau4996. *(PCMCI para series temporales)*

11. **Peters, Buhlmann & Meinshausen (2016)** - "Causal Inference by using Invariant Prediction: Identification and Confidence Intervals". Journal of the Royal Statistical Society: Series B, 78(5), 947-1012. *(ICP)*

### Algoritmos de Inferencia Causal

12. **Chernozhukov et al. (2018)** - "Double/Debiased Machine Learning for Treatment and Causal Parameters". The Econometrics Journal, 21(1), C1-C68. *(DML)*

13. **Athey & Imbens (2016)** - "Recursive Partitioning for Heterogeneous Causal Effects". PNAS, 113(27), 7353-7360. *(Causal Forest)*

14. **Robins et al. (2000)** - "Marginal Structural Models and Causal Inference in Epidemiology*. Epidemiology, 11(5), 550-560. *(IPTW/DR)*

15. **Stuart (2010)** - "Matching Methods for Causal Inference: A Review and a Look Forward". Statistical Science, 25(1), 1-21. *(PSM, CEM)*

16. **Imbens & Wooldridge (2009)** - "Recent Developments in the Econometrics of Program Evaluation". Journal of Economic Literature, 47(1), 5-86. *(Instrumental Variables, LATE)*

17. **Kunzel et al. (2019)** - "Metalearners for Estimating Heterogeneous Treatment Effects using Machine Learning*. PNAS, 116(10), 4156-4165. *(T-learner, S-learner, X-learner)*

18. **Pearl (2009)** - "Causality: Models, Reasoning, and Inference", 2nd ed. Cambridge University Press. *(Do-calculus, backdoor criterion)*

### Datasets de Benchmark - Descubrimiento Causal

> ⚠️ **Nota de transparencia**: Los datasets de Sachs, ALARM, CHILD e Insurance usan **grafos causales reales** extraidos de la literatura, pero los **datos numericos son generados sinteticamente** con SEM lineal Gaussiano. Vease `01_generate_literature_based_datasets.py` y `docs/DATASET_CATALOG.md` para detalles.

19. **Sachs et al. (2005)** - "Causal Protein-Signaling Networks Derived from Multiparameter Single-Cell Data". Science, 308(5721), 523-529. *(Sachs - Red de senalizacion proteica)*
   - **11 proteinas**, ~7,466 observaciones de citometria de flujo
   - **17 arcos causales validados experimentalmente**
   - Gold standard para evaluar descubrimiento causal

20. **Beinlich et al. (1989)** - "The ALARM Monitoring System: A Case Study with Two Probabilistic Inference Techniques for Belief Networks". Proc. of the 2nd European Conference on AI in Medicine. *(ALARM - Monitorizacion UCI)*
   - **37 variables**, 46 arcos en red bayesiana
   - Red medica clasica ampliamente usada

21. **Spiegelhalter et al. (1993)** - "BUGS: Bayesian Inference Using Gibbs Sampling". MRC Biostatistics Unit. *(CHILD - Diagnostico pediatrico)*
   - **20 variables**, 25 arcos
   - Red bayesiana para diagnostico de enfermedades pediatricas

22. **Binder et al. (1997)** - "A Simulator for Network Planning in the Mobile Internet". *(Insurance)*
   - **27 variables**, 52 arcos
   - Red de evaluacion de riesgos de seguros

### Datasets de Benchmark - Inferencia Causal (Tratamiento)

> ⚠️ **Nota de transparencia**: Los datasets de IHDP, Jobs/LaLonde y Twins son **completamente sinteticos**. Las covariables se generan con distribuciones de probabilidad (N(0,1), U(a,b)), los tratamientos con modelos logit, y los outcomes con formulas lineales que fuerzan ATEs similares a los reportados en la literatura. No contienen datos reales de pacientes.

23. **Hill (2011)** - "Bayesian Nonparametric Modeling for Causal Inference". Journal of Computational and Graphical Statistics, 20(1), 217-240. *(IHDP)*
   - **747 unidades** (ninos del Infant Health and Development Program)
   - **25 covariables** (medidas del nino y madre)
   - **Outcomes observados Y(0) y Y(1)**: permite calcular error ground truth
   - **ATE verdadero ≈ -4.0** (efecto negativo del tratamiento de bajo peso)
   - El benchmark mas utilizado en la literatura de inferencia causal

24. **LaLonde (1986)** - "Evaluating the Econometric Evaluations of Training Programs with Experimental Data". American Economic Review, 76(4), 604-620. *(LaLonde/Jobs)*
   - Datos experimentales del National Supported Work (NSW)
   - **Covariables demograficas + ingresos pre-tratamiento**
   - Permite comparar estimadores contra resultado experimental

25. **Smith & Todd (2005)** - "Does Matching Overcome LaLonde's Critique of Nonexperimental Estimators?". Journal of Econometrics, 125(1-2), 305-353. *(Jobs-Experimental vs Observacional)*
   - Extension del benchmark de LaLonde con multiples cohortes

26. **Almond et al. (2005)** - "Is Birth Weight a Determinant of Infant Health? Evidence from Twins". NBER Working Paper. *(Twins)*
   - **Datos de gemelos del U.S. National Center for Health Statistics (1989-1991)**
   - **40 covariables** relacionadas con mortalidad infantil
   - **Outcomes observados para ambos gemelos**: permite evaluar contrafactuales
   - ATE verdadero estimado por diferencias intra-gemelares

### Benchmarks Sinteticos y Frameworks

27. **Hernan et al. (2019)** - "A Second Chance to Get Causal Inference Right: A Classification of Data Science Tasks". CHANCE, 32(1), 42-49. *(Taxonomia de tareas causales)*

28. **Glynn & Kashin (2018)** - "Front-Door Versus Back-Door Adjustment with Unmeasured Confounding: Bias Formulas for Front-Door and Hybrid Adjustments with Application to a Job Training Program". Journal of Educational and Behavioral Statistics. *(Formulas de sesgo)*

29. **Dorie et al. (2019)** - "Automated versus Do-It-Yourself Methods for Causal Inference: Lessons Learned from Data Analysis Competitions*. Statistical Science, 34(1), 43-68. *(ACIC 2016/2018)*
   - Atlantic Causal Inference Conference benchmarks
   - **Miles de datasets sinteticos** con ATE conocido
   - Diferentes niveles de complejidad y confounding

30. **Shi et al. (2019)** - "Adapting Neural Networks for the Estimation of Treatment Effects**. NeurIPS 2019. *(CEVAE datasets)*
   - Datasets para evaluar modelos con variables latentes

### Librerias y Herramientas Relacionadas

31. **Zheng et al. (2024)** - "causal-learn: Causal Discovery in Python". Journal of Machine Learning Research, 25, 1-8.

32. **Sharma & Kiciman (2020)** - "DoWhy: An End-to-End Library for Causal Inference**. arXiv:2011.04216.

33. **Microsoft Research (2024)** - "EconML: A Python Package for ML-Based Heterogeneous Treatment Effects Estimation".

34. **Chen et al. (2020)** - "CausalML: Python Package for Causal Machine Learning". arXiv:2002.11631.

35. **Runge (2018)** - "tigramite: Causal Discovery in Python". 

36. **Singh et al. (2025)** - "Causal-Copilot: An Autonomous Causal Analysis Agent**. arXiv:2504.13263.

---

## Estructura del Paquete

```
causal_benchmark_synthetic/
├── README.md
├── RELEASE_README.md
├── BENCHMARK_SCHEMA.md
├── LICENSE
├── datasets/
│   ├── real/                          # 7 escenarios con referencias bibliograficas
│   │   ├── sachs/, alarm/, child/, insurance/
│   │   └── ihdp/, jobs/, twins/
│   └── synthetic/                     # 36 escenarios controlados
│       ├── linear_gaussian/           # 9
│       ├── non_gaussian/              # 6
│       ├── nonlinear/                 # 6
│       ├── timeseries/                # 5
│       ├── inference/                 # 7
│       └── edge_cases/                # 3
├── scripts/
│   ├── 00_validate_benchmark.py
│   ├── 01_generate_literature_based_datasets.py
│   ├── 02_generate_synthetic.py
│   ├── 03_run_discovery_benchmark.py
│   ├── 04_run_inference_benchmark.py
│   ├── 05_run_full_pipeline.py
│   └── utils.py
├── release_index/
│   ├── dataset_index.csv
│   ├── task_index.csv
│   └── known_issues.csv
├── results/
│   ├── scorecards/
│   └── validation/
└── docs/
    ├── DATASET_CATALOG.md
    └── METRICS_GUIDE.md
```

---

## Requisitos

```bash
pip install numpy pandas scipy scikit-learn matplotlib seaborn
pip install networkx joblib pyyaml requests

# Opcionales (para evaluacion con librerias especializadas)
pip install causal-learn lingam gcastle
pip install dowhy econml causalml
pip install tigramite
```

---

## Uso Rapido

### 1. Generar todos los datasets basados en literatura (estructura real, datos sinteticos)
```bash
python scripts/01_generate_literature_based_datasets.py --all --output datasets/real/
```

### 2. Ejecutar benchmark de descubrimiento causal
```bash
python scripts/03_run_discovery_benchmark.py \
    --datasets datasets/synthetic/linear_gaussian/ \
    --algorithms pc fci ges notears golem lingam \
    --output results/discovery/
```

### 3. Ejecutar benchmark de inferencia causal
```bash
python scripts/04_run_inference_benchmark.py \
    --datasets datasets/real/ihdp/ \
    --estimators linear_dml causal_forest psm \
    --output results/inference/
```

### 4. Pipeline completo de descubrimiento e inferencia
```bash
python scripts/05_run_full_pipeline.py \
    --dataset datasets/synthetic/linear_gaussian/20_vars_40_edges/ \
    --query "discover and estimate ATE" \
    --output results/full_pipeline/
```

---

## Datasets Incluidos

#### 1. Datasets basados en Literatura (datos sinteticos, estructura causal real)

> ⚠️ **Transparencia**: Aunque la carpeta se llama `datasets/real/`, esto se refiere a que las **estructuras causales** son reales (extraidas de papers). Todos los valores numericos son generados sinteticamente.

| Dataset | Variables | Instancias | Arcos | Tipo | Fuente del Grafo | Datos Numericos |
|---------|-----------|------------|-------|------|-----------------|-----------------|
| **Sachs** | 11 | 7,466 (gen) | 17-18 | Continuo (proteinas) | Science 2005 ✅ | SEM Lineal Gaussiano |
| **ALARM** | 37 | 20,000 (gen) | 46 | Mixto (medico) | Beinlich et al. 1989 ✅ | SEM Lineal Gaussiano |
| **CHILD** | 20 | 10,000 (gen) | 25 | Mixto (pediatrico) | Spiegelhalter 1993 ✅ | SEM Lineal Gaussiano |
| **Insurance** | 27 | 20,000 (gen) | 52 | Mixto (seguros) | Binder et al. 1997 ✅ | SEM Lineal Gaussiano |

#### 2. Datasets de Inferencia basados en Literatura (completamente sinteticos)

> ⚠️ **Transparencia**: Todos los valores numericos (covariables, tratamientos, outcomes) son generados sinteticamente. Solo los ATEs de referencia y los nombres de variables provienen de la literatura.

| Dataset | Unidades | Covariables | Outcome | Tratamiento | ATE Referencia | Datos |
|---------|----------|-------------|---------|-------------|----------------|-------|
| **IHDP** | 747 | 25 | Continuo | Binario | ~ -4.0 (Hill 2011) | 100% Sintetico |
| **Jobs** | 722 (exp) + 16,000 | 8 | Continuo | Binario | ~ 1,794 (LaLonde 1986) | 100% Sintetico |
| **Twins** | 11,400 pares | 40 | Binario | Binario | Control negativo (no estimable) | 100% Sintetico |

#### 3. Datasets Sinteticos Controlados (explicitamente sinteticos)

| Categoria | Generador | Variables | Instancias | Grafos |
|-----------|-----------|-----------|------------|--------|
| **Lineal Gaussiano** | SEM lineal | 10, 20, 50, 100 | 1,000-10,000 | Erdos-Renyi, Scale-Free |
| **No lineal** | MLP/GP | 10, 20, 50 | 1,000-5,000 | Mismo arriba + heterocedastico |
| **Mixto** | Mezcla | 20, 50 | 5,000 | Con confusores no observados |
| **Series Temporales** | VAR/NL-SEM | 5, 10 | 500-2,000 | Lagged causal structures |

---

## Metricas de Evaluacion

### Descubrimiento Causal
- **Structural Hamming Distance (SHD)**: Distancia entre grafo estimado y ground truth
- **Structural Intervention Distance (SID)**: Distancia en espacio de intervenciones
- **Precision/Recall de arcos**: TP/(TP+FP) y TP/(TP+FN)
- **F1-Score**: Media armonica de precision y recall
- **Orientacion correcta**: Proporcion de arcos con direccion correcta
- **CPDAG accuracy**: Comparacion en el espacio de equivalencia Markoviana

### Inferencia Causal
- **Error Absoluto Medio del ATE (ATE-MAE)**: |ATE_estimado - ATE_verdadero|
- **Error Cuadratico Medio (PEHE)**: Precision en Estimacion de Efectos Heterogeneos
- **Cobertura del Intervalo**: Proporcion de veces que el IC95% contiene el ATE verdadero
- **Longitud del Intervalo**: Precision estadistica (IC95% estrechos preferidos)
- **Sesgo**: Diferencia sistematica entre estimacion y verdadero

### Pipeline Completo
- **Tasa de abstencion correcta**: Cuando no hay set de ajuste valido
- **Tasa de refutacion superada**: Proporcion de tests de refutacion superados
- **E-value**: Resistencia a confusores no medidos
- **Tiempo de ejecucion**: Eficiencia computacional
- **Uso de memoria**: Consumo maximo de RAM

---

## Guia de Uso de los Datasets

Estos benchmarks estan disenados para probar:

### Capacidades de Descubrimiento
1. **Recuperacion de estructura**: Los datasets Sachs, ALARM, CHILD e Insurance tienen grafos causales conocidos (de la literatura) para comparar contra la salida de PC, FCI, GES, etc. Los datos numericos son SEM, pero la estructura de referencia es autentica.
2. **Robustez ante distribuciones no Gaussianas**: ICA-LiNGAM y DirectLiNGAM se evaluan con datos sinteticos super-Gaussianos y sub-Gaussianos
3. **Manejo de variables latentes**: FCI se evalua con datasets que incluyen confusores no observados
4. **Series temporales**: PCMCI se evalua con datos sinteticos VAR y no lineales con lag

### Capacidades de Inferencia
5. **Precision del ATE**: IHDP, Jobs y Twins permiten comparar las estimaciones de LinearDML, CausalForestDML, PSM, etc. contra ground truth sintetico conocido
6. **Efectos heterogeneos (CATE)**: Subgrupos en IHDP permiten evaluar CausalForestDML y T-learner
7. **Instrumentos y LATE**: Datasets sinteticos con variables instrumentales para DRIV

### Capacidades del Agente
8. **Seleccion automatica de algoritmo**: Los benchmarks con diferentes caracteristicas (lineal/no lineal, alta/baja dimensionalidad) prueban el selector basado en reglas YAML
9. **Refutacion**: Todos los datasets se pueden usar para probar los refuters (placebo, random common cause, subset)
10. **Abstencion**: Datasets no identificables prueban la capacidad de abstenerse
11. **Determinismo**: Semillas fijas permiten verificar reproducibilidad bit-a-bit

---

## Referencias de Implementacion

- **causal-learn**: https://github.com/py-why/causal-learn
- **DoWhy**: https://github.com/py-why/dowhy
- **EconML**: https://github.com/microsoft/EconML
- **CausalML**: https://github.com/uber/causalml
- **tigramite**: https://github.com/jakobrunge/tigramite
- **gCastle**: https://github.com/huawei-noah/trustworthyAI/tree/master/gcastle
- **LiNGAM**: https://github.com/cdt15/lingam
- **Causal-Copilot**: https://github.com/Lindsay-Lab/causal-copilot (alternativa LLM-based)

---

## Citacion

Si utilizas estos benchmarks en tu investigacion, por favor cita:

```bibtex
@software{causal_discovery_benchmarks,
  title = {Causal Discovery Benchmark Datasets},
  author = {Santibanez Uribe, Segundo Alejandro},
  year = {2026},
  url = {https://github.com/OWNER/causal-benchmark-ecosystem}
}
```

Y las referencias originales de los datasets individuales listadas arriba.

---

## Licencia

MIT — ver [`LICENSE`](./LICENSE).

Los escenarios basados en literatura mantienen las licencias de sus fuentes originales. Consulte `metadata.json` y [`../README.md`](../README.md) para detalles por dataset:

- Sachs, ALARM, CHILD, Insurance: grafos de referencia publicados; datos numericos generados por SEM
- IHDP, Jobs, Twins: escenarios sinteticos inspirados en Hill (2011), LaLonde (1986) y Almond et al. (2005)

---

*Repositorio de datasets de benchmark para descubrimiento causal e inferencia*
