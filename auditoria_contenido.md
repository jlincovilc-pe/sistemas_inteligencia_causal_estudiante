# Auditoría de contenido — Monografía *IA Causal en Producción*

**Objeto auditado:** `02_monografia/monografia_IA_Causal_en_Produccion.pdf` (32 capítulos, 9 partes, 8 apéndices, ~90 referencias)
**Marco de referencia:** `01_silabo/silabo.typ` (sílabo ECO-490/ECON-540, sesiones S1–S32, módulos 0–6)
**Fuentes externas de verificación:** OpenAlex (API `api.openalex.org`, verificación de 67 obras) y Tavily (búsqueda web, actualidad 2024–2026)
**Fecha de la auditoría:** 2026-08-10

---

## 1. Resumen ejecutivo

La monografía de 32 capítulos es, en conjunto, **sólida y por encima del estándar esperable** para un curso profesional de inferencia causal con despliegue: el núcleo teórico (ortogonalidad de Neyman, cross-fitting, DML, meta-learners, bosques causales, PDS) está formalizado con teoremas y garantías asintóticas correctos, y la cadena metodológica identificación → estimación → validación → servicio → monitoreo está completa y alineada con el sílabo y con la práctica industrial vigente (verificada en 2025 vía Tavily: talleres KDD de causal ML en producción, uso industrial de DML y uplift en Uber/DoorDash/BBVA).

Sin embargo, la auditoría detecta **tres familias de problemas** que conviene corregir antes de la edición definitiva:

1. **Brechas de fundamentación teórica** (Eje A): promesas formales incumplidas (el cálculo-*do* se anuncia en los Caps. 3 y 8 pero no se formaliza), referencias canónicas ausentes para teoremas clave (Robinson 1988, Kennedy 2020, Zhao & Yu 2006, Bareinboim et al. 2022 para el Teorema de la Jerarquía Causal), y atribuciones imprecisas (p. ej. garantía de *irrepresentabilidad* declarada sin demostrarla).
2. **Errores de citación verificables** (Eje B): `angrist1991` usado para el diseño IV de Card (debe ser `card1995`, que existe pero no se cita), `kuo2014causalml` con autoría/año incorrectos (la referencia real es Chen et al. 2020, arXiv:2002.11631), y `foster2023orthogonal` descrito con el contenido de `foster2019orthogonal`.
3. **Listados y decisiones no totalmente consistentes**: al menos tres ejemplos de código no ejecutables tal como se presentan (Cap. 17 API DoubleML, Cap. 22 columnas `uplift_*` inexistentes, Cap. 15 endpoint `/metadata` anunciado pero no implementado), y un "caso empírico" que en realidad simula los datos (Cap. 21).

**Calificación global:** Teoría **4.1/5** · Metodología **3.8/5** · Adecuación al sílabo **4.6/5**.

---

## 2. Alcance y método

| Fuente | Uso |
|---|---|
| `01_silabo/silabo.typ` | Marco de referencia: módulos 0–6, sesiones S1–S32, entregas A1–A4/B1–B4, bibliografía declarada del curso |
| `02_monografia/…/capitulos/*.typ` | Lectura completa de los 32 capítulos (7 010 líneas) con extracción de contenido teórico y metodológico |
| `02_monografia/…/bibliografia/refs.yml` | Contrastación de las ~90 entradas bibliográficas citadas |
| **OpenAlex** | Verificación de 67 obras: existencia, año, venue y citas. Criterio: una referencia es *canónica* si la obra está indexada con el título/autores correctos y tiene impacto alto |
| **Tavily** | Actualidad del estado del arte (2024–2026): causal ML en producción, DML, uplift, discovery, SCM, MLOps, Hugging Face |

**Criterios de evaluación por capítulo (escalas 1–5):**
- **Teoría (T):** formalización (definiciones, teoremas, supuestos, garantías), precisión de atribuciones, suficiencia del aparato bibliográfico teórico.
- **Metodología (M):** cobertura de métodos/algoritmos, ejecutabilidad de los listados, calidad de la validación empírica, adecuación al ciclo DMLS (datos → features → evaluación → despliegue → monitoreo).
- **Alineación al sílabo (A):** correspondencia sesión ↔ capítulo ↔ entrega según la tabla maestra de `PLAN_INTEGRACION_MONOGRAFIA.md`.

**Limitaciones:** OpenAlex subcuenta severamente algunas obras (p. ej. Athey & Wager 2021 = 3 citas en OpenAlex vs. ~500 en Google Scholar); las cifras se usan como señal de canonicidad relativa, no como conteo absoluto. El libro de Bareinboim (*Causal AI*, 2025) no está indexado en OpenAlex (verificado por web vía Tavily).

---

## 3. Eje A — Auditoría de Teoría

### 3.1 Mapa de cobertura teórica frente al sílabo

| Módulo (sílabo) | Sesiones | Capítulos | Contenido teórico esperado | Cobertura |
|---|---|:---:|---|:---:|
| M0 — Causalidad elemental | S1–S2 | 1–2 | Problema fundamental, PCH (adelanto), sistema causal vs. predictivo | Completa |
| M1 — Fundamentos y datos | S3–S8 | 3–9 | SCM, PCH formal, do(), puerta trasera, contrafactuales, PDS, no confusión, leakage | Completa con brechas formales (§3.3) |
| M2 — Estimación con ML | S9–S14 | 10–15 | Ortogonalidad de Neyman, cross-fitting, DML (PLR/IRM), meta-learners, bosques, validación | **Núcleo fuerte** |
| M3 — Hub y CI/CD | S17–S18 | 19–20 | Model cards causales, CI/CD con validez causal | Aceptable (delgada) |
| M4 — Decisión y policy | S19–S24 | 21–26 | Policy learning, uplift, decisiones estructurales, transportabilidad, explicación causal | Completa con matices |
| M5 — Monitoreo y frontera | S25–S28 | 29–32 | Discovery, monitoreo de supuestos, continual learning, RL causal, lado humano | Aceptable |
| Electivos ◇ | — | 5, 16, 17, 18, 27, 28 | Refuerzo/panel/deep/matrix completion | Presente y etiquetada |

### 3.2 Verificación de los fundamentos en OpenAlex

Las referencias teóricas centrales del curso citadas en el sílabo y la monografía **existen y son las canónicas**:

| Obra (clave en `refs.yml`) | Venue real | Citas OpenAlex | Veredicto |
|---|---|---|---|
| Chernozhukov et al. 2018 (DML) | Econometrics Journal | 2 646 | Canónica ✓ |
| Wager & Athey 2018 (bosques causales) | JASA | 2 862 | Canónica ✓ |
| Künzel et al. 2019 (metalearners) | PNAS | 1 030 | Canónica ✓ |
| Belloni, Chernozhukov, Hansen 2014 (PDS) | Rev. Econ. Studies | 1 524 | Canónica ✓ |
| Athey & Imbens 2016 (recursive partitioning) | PNAS | 1 568 | Canónica ✓ |
| Kitagawa & Tetenov 2018 (EWM) | Econometrica | 266 | Canónica ✓ |
| Robins, Rotnitzky, Zhao 1994 (doble robustez) | JASA | 2 775 | Canónica ✓ |
| Holland 1986 (problema fundamental) | JASA | 5 135 | Canónica ✓ |
| Pearl 2009 *Causality* (2.ª ed.) | Cambridge UP | ~6 300 (COCI) | Canónica ✓ |
| Bareinboim & Pearl 2013 (transportabilidad) | J. Causal Inference | 210 | Canónica ✓ |
| Kusner et al. 2017 (equidad contrafactual) | NeurIPS | 880 | Canónica ✓ |
| Lundberg & Lee 2017 (SHAP) | NeurIPS | 7 622 | Canónica ✓ |
| Mitchell et al. 2019 (model cards) | FAT* | 1 839 | Canónica ✓ |

### 3.3 Hallazgos teóricos

**Fortalezas:**

- El núcleo de la Parte II (Caps. 10–13) formaliza correctamente los tres pilares del curso: ortogonalidad de Neyman (score PLR con distinción explícita de la forma estructural `g0` vs. condicional `l0`, un error frecuente en implementaciones), cross-fitting con condición `√n·aₙ²→0`, y honestidad en árboles (partición `S_split ∪ S_est`). El Teorema central de DML se enuncia con su condición de tasas y la expansión de influence function.
- El Cap. 3 (SCM/PCH) da la definición formal de SCM `⟨U, V, F, P(u)⟩`, la equivalencia con resultados potenciales, y el Teorema de la Jerarquía Causal (informal pero bien orientado).
- El Cap. 8 formaliza el criterio de puerta trasera con prueba, clasifica controles (confusor vs. mediador/collider/instrumento/post-tratamiento) y desarrolla el cómputo contrafactual abducción-acción-predicción.
- El Cap. 16 (PDS) es de los más sólidos: teorema de BCH 2014 con varianza asintótica, condición RE, comparación PDS vs. DML y PDS-IV.
- La noción de *score ortogonal* se presenta con su definición formal (derivada de Gateaux), lo que permite a los caps. 11 y 12 construir sobre ella sin re-derivar.

**Brechas formales (prioridad de corrección):**

1. **Cálculo-*do* prometido, no formalizado.** El Cap. 3 anuncia la "formalización completa" del do-calculus en el Cap. 8, y el cuadro sinóptico del Cap. 8 lo reitera; pero el Cap. 8 solo formaliza el criterio de puerta trasera. Las tres reglas del cálculo-*do* (Pearl 2009) no se enuncian. → Decisión: o se añaden (con `dowhy` como automatización) o se reescribe la promesa como "criterio de puerta trasera y enfoque do-calculus (Pearl 2009)".
2. **Teorema de la Jerarquía Causal sin su referencia formal.** Se atribuye a `bareinboim2025causalai` sin citar la fuente canónica: Bareinboim, Correa, Ibeling & Icard (2022), *On Pearl's Hierarchy and the Foundations of Causal Inference* (ACM Books; 155 citas en OpenAlex). Al ser el resultado que sostiene la tesis del Cap. 1, merece cita explícita.
3. **Robinson (1988) ausente de la bibliografía.** El score de Robinson se usa en los Caps. 10 y 12 (R-learner) sin clave bibliográfica. Es la referencia canónica (2 513 citas) de la semiparametría que todo el curso usa.
4. **Cap. 6: garantía declarada ≠ garantía demostrada.** El cuadro sinóptico declara "consistencia de selección bajo irrepresentabilidad" pero el cuerpo solo desarrolla la *restricted eigenvalue condition* (Bickel–Ritov–Tsybakov). Falta Zhao & Yu (2006) (2 016 citas) o corregir el cuadro. Tampoco se cita la literatura de *selective inference* (Lee et al. 2016, 494 citas; Zhang & Zhang 2014, 1 045; van de Geer et al. 2014, 812) que formaliza el problema de inferencia post-selección que el capítulo describe informalmente.
5. **Cap. 12: DR-learner sin cita.** Se presenta el DR-learner sin su referencia canónica: Kennedy (2020; publicado EJS 2023, 152 citas). Es un método que los estudiantes usarán vía `econml`; la omisión es notable.
6. **Collider bias sin su referencia canónica.** El Cap. 8 (y el 5) tratan el sesgo por collider sin citar Elwert & Winship (2014) (1 231 citas), el tratamiento de referencia del tema.
7. **Atribución imprecisa en policy learning (Cap. 21).** La garantía de regret `O_p(n^{-1/2})` con clase de políticas de VC-finita se asocia en la literatura a Kitagawa & Tetenov (2018); el capítulo la atribuye a Athey & Wager (2021). Conviene precisar qué resultado es de quién.
8. **Cap. 24: definición no estándar.** *Equalized CATE* se presenta como definición de equidad estándar, pero las tres familias canónicas son demographic parity, equalized odds y calibration/predictive parity (Barocas–Hardt–Narayanan). Faltan Hardt et al. (2016, 1 927 citas) y Dwork et al. (2012, 3 423 citas).
9. **Cap. 23: literatura de equidad causal incompleta.** Faltan Kilbertus et al. (2017, *Avoiding Discrimination through Causal Reasoning*, 182 citas) y los trabajos de Nabi & Shpitser y Zhang & Bareinboim sobre descomposición de efectos en fairness.
10. **Cap. 26: la reponderación implementada corresponde al teorema de *generalización* (Pearl & Bareinboim 2011), no citado**; solo se cita Bareinboim & Pearl (2013). Falta también Correa & Bareinboim (2020) para el transporte de intervenciones suaves.
11. **Cap. 27: estado del arte deep causal incompleto.** No se citan las limitaciones de las representaciones balanceadas (Curth & van der Schaar 2021; *no* existe el título "On the limitations of balanced representations…", el trabajo real es *On inductive biases for HTE estimation*, NeurIPS 2021) ni la línea de redes con representers de Riesz para inferencia válida (Chernozhukov et al. 2021, *RieszNet and Forest-Riesz*; Farrell, Liang & Misra 2021, Econometrica, 319 citas), pese a que el propio capítulo declara la inferencia válida como problema abierto.
12. **Cap. 30: test de estabilidad del efecto ad-hoc.** La métrica `estabilidad_efecto` compara la media reciente contra el IC original sin propagar el error estándar reciente; no es un test formal. El umbral F>10 se usa sin citar Stock & Yogo (2005) (1 899 citas).
13. **Cap. 25: sin aparato de teoría de la decisión.** No se cita ningún texto de decisión bajo incertidumbre (Berger 1985; Parmigiani & Inoue 2009) ni la literatura de decisión con identificación parcial (Manski 2004, *Statistical Treatment Rules for Heterogeneous Populations*, Econometrica, 420 citas), que es el marco natural del capítulo.

---

## 4. Eje B — Auditoría de Metodología

### 4.1 Mapa de cobertura metodológica frente al sílabo

| Hito de producto (sílabo §11) | Capítulos | Métodos/artefactos | Estado |
|---|---|---|---|
| A1 — Identificación (Jobs) | 4, 7, 9 | `CausalSchema`, ficha de procedencia del tratamiento, `auditar_features`, chequeo de balance | Correcto; chequeo de balance rudimentario (§4.3.4) |
| A2 — DML (IHDP) | 10, 11, 16 | PLR/IRM/PLIV con DoubleML y econml, cross-fitting, `verify_no_leakage`, PDS | **Núcleo fuerte**; error de citación Card/Angrist (§4.3.1) |
| B1 — API + Docker | 15 | FastAPI + joblib, `/health` + `/predict` (+ `/metadata` anunciado, no implementado) | Correcto; inconsistencia §4.3.3 |
| A3 — CATE | 12, 13, 14 | Meta-learners S/T/X/R, bosques causales, Qini/placebos/transformed outcome | Fuerte; faltan Kennedy 2020 y VanderWeele & Ding 2017 |
| B2 — Hub/CI | 19, 20 | Model card causal, GitHub Actions con pruebas estadísticas | Novedoso y bien planteado; sin datasheets ni MLOps estándar |
| A4 — Policy B=20% | 21, 22 | Policy tree DR, uplift, Qini/AUUC, net score con presupuesto | Correcto con salvedades (§4.3.2) |
| B3 — Space | 22, 19 | Gradio/Space HF | Adecuado |
| B4 — Monitor | 30, 31 | KS por covariable, F de primera etapa, estabilidad del efecto, champion-challenger | Adecuado; test ad-hoc (§3.3.12) |
| Electivos | 17, 18, 27, 28, 29 | DML-panel, DML-IV, mapa de decisión, TARNet/CFRNet, SCM/matrix completion, PC/NOTEARS | Correctos; faltan referencias modernas (§3.3.10–11, §4.3.5) |

### 4.2 Actualidad metodológica verificada con Tavily (2024–2026)

- **DML como estándar establecido.** La literatura reciente (p. ej. Velez 2025, *On the Asymptotic Properties of Debiased ML with Growing Number of Cross-Fitting Folds*) extiende la teoría de cross-fitting; el curso cubre la versión canónica (Chernozhukov et al. 2018, AER 2018 "Double/Debiased/Neyman ML"). **No hay brecha de actualidad en el núcleo.**
- **Causal ML en producción es tendencia industrial consolidada**: 3.er workshop KDD *Causal Inference and ML in Practice* (2025) con casos de DoorDash (promociones), BBVA (tratamientos continuos), NTT DOCOMO (efectos múltiples); PyData London 2024 con uplift con `causalml`. La apuesta del curso por Hugging Face + FastAPI + model cards causales es coherente con esta tendencia, aunque el curso podría citar 1–2 de estos casos como referencia de industria.
- **Uplift**: Qini/AUUC siguen siendo las métricas estándar de industria (Uber causalml, DSAA 2019, KDD 2021 tutorial); el Cap. 22 está alineado. La referencia correcta del paquete es Chen et al. (2020), arXiv:2002.11631 — **no** "Kuo et al. (2014)" como figura en `refs.yml` (verificado en el repo oficial de Uber).
- **Causal discovery**: NOTEARS y PC siguen siendo el estándar de referencia; la frontera 2024–2025 añade DAGMA, DECI, métodos con LLMs y estudios de robustez a hiperparámetros (AISTATS 2024). El Cap. 29 es correcto en lo que cubre; podría mencionar la sensibilidad a hiperparámetros (documentada en Machlanski et al. 2024) como advertencia adicional.
- **SCM/DiD moderno**: la literatura de *staggered adoption* está dominada por Callaway–Sant'Anna, Sun–Abraham, de Chaisemartin–D'Haultfœuille (4 750 citas) y Goodman-Bacon (7 508), más Borusyak–Jaravel–Spiess (2024, 1 911). El Cap. 17 menciona Callaway–Sant'Anna y Sun–Abraham en su caja DiD; **de Chaisemartin & D'Haultfœuille y Goodman-Bacon no aparecen en ninguna parte** — es la brecha metodológica más notable en la literatura de paneles, relevante porque el Cap. 28 (matrix completion) es exactamente el área donde esos métodos compiten.
- **MLOps**: la documentación de modelos en 2025 sigue anclada en model cards (Mitchell et al. 2019) y datasheets (Gebru et al. 2021, ~3 500 citas GS). El Cap. 19 debería citar datasheets; el Cap. 20 podría mencionar herramientas estándar (MLflow, DVC, Evidently/Great Expectations) aunque su enfoque de "CI con pruebas estadísticas" es un aporte propio.

### 4.3 Hallazgos metodológicos

**Fortalezas:**

- La cadena completa del sílabo (§11) está implementada de punta a punta: de `CausalSchema` (Cap. 4) a `reporte_monitoreo` (Cap. 30), con artefactos joblib, autograders y checklists operativos. Ningún módulo termina en un notebook aislado.
- La validación offline (Cap. 14) es de lo mejor del libro: Qini acumulada con supuestos explícitos, transformed outcome, placebos (temporal/subgrupo/outcome), suite de refutación (placebo treatment, random common cause, subset validation), baselines obligatorios (efecto constante, aleatorio, riesgo) y versionado del proceso de evaluación.
- El Cap. 20 (CI/CD causal) es un aporte distintivo del curso: pruebas estadísticas (placebo + balance) que bloquean la publicación, separando el ciclo de software (segundos) del estadístico (minutos).
- Réplicas numéricas transparentes y honestas: el Cap. 11 declara explícitamente que su cifra de DML-PLIV es una réplica propia y no el valor del paper original; el Cap. 16 reporta sensibilidad a λ.

**Errores y debilidades (prioridad de corrección):**

1. **Error de citación empírica (Cap. 11).** Se cita `angrist1991` (Angrist & Krueger, *quarter of birth*, QJE 1991) como fuente del diseño IV con `nearc4` (proximidad a universidad), que es **Card (1995)**. La clave `card1995` existe en `refs.yml` pero no se usa. Mismo patrón en Caps. 3, 5, 8 y 26, donde Card se menciona en prosa sin `@card1995`.
2. **Casos empíricos simulados presentados como aplicados.** El Cap. 21 ("caso" con `gov_transfers`) en realidad **simula** tratamiento y outcome si "no están claros"; el Cap. 22 declara un caso de churn de telecomunicaciones cuyas columnas `uplift_sms`/`uplift_call` nunca se estiman (el código lanzaría `ValueError`); el Cap. 17 usa `time`, `unit_id` y `time_x_unit` como covariables proxy en el ejemplo sintético. El capítulo es honesto en los comentarios, pero la presentación mezcla "caso" con "simulación". **Sugerencia:** etiquetar explícitamente cada listado como *aplicado* vs. *sintético*.
3. **Inconsistencias código/declaración.** Cap. 9: la decisión de referencia admite features "desconocido" con advertencia, pero `incluir_en_X = (rol == "confusor") & (posterior == 0.0)` las excluye de facto. Cap. 15: el bloque `monorepo` anuncia `/metadata` que no existe en el `app.py` listado. Cap. 4: la decisión exige Parquet pero el callout del monorepo documenta CSV + `metadata.json` (el plan de integración ya contempla este gap vía `lib.schema.CausalSchema.from_scenario` — conviene cerrarlo).
4. **Chequeo de balance rudimentario (Cap. 7).** T-tests de Welch por covariable sin múltiples comparaciones; el estándar de la literatura de evaluación de programas usa diferencias estandarizadas (SMD) y el criterio de Rubin (ratio de varianzas). Tampoco se citan Lalonde (1986) ni Dehejia & Wahba (1999) — ambos nombrados en prosa sin clave — ni la literatura de missingness (Rubin 1976).
5. **Bibliografía sospechosa o a verificar:**
   - `kuo2014causalml` (Cap. 22): el paquete `causalml` es de Uber, abierto en 2019–2020; la cita canónica es Chen, Harinen, Lee, Yung & Zhao (2020), arXiv:2002.11631. **Corregir o eliminar.**
   - `foster2023orthogonal` (Cap. 12): en `refs.yml` figura como "Orthogonal Deep Learning to Recover the Blanchard-Qua Decomposition" (título visiblemente corrupto — "Blanchard-Quah"), pero el capítulo la describe con el contenido de `foster2019orthogonal` (Orthogonal Statistical Learning). **Revisar clave y título.**
   - `kitagawa2021equality` (Cap. 24): `refs.yml` la lista como Kitagawa & Wang, "Causal Estimation of Equality of Opportunity" (working paper), pero el contenido citado es el trade-off welfare vs. equidad de Kitagawa, Sakaguchi & Tetenov (2021), cuyo título real es *Constrained Classification and Policy Learning*. **Verificar y corregir.**
   - `spiegelhalter2017art` (Cap. 24): título correcto ("The Art of Statistics: Learning from Data"), fecha real 2019 (la clave dice 2017).
   - `chernozhukov2018applied`: título correcto ("Applied Causal Inference Inspired by Machine Learning", MIT WP 2018); verificar que las citas en texto no la confundan con el DML de Econometrics Journal.
6. **Numeración interna desactualizada.** Los comentarios de cabecera de `cap01` (Cap. 5), `cap02` (Cap. 6), `cap09` (17), `cap10` (18), `cap11` (21), `cap12` (22), `cap16` (24), `cap13` (27), `cap14` (28), `cap15` (29) conservan la numeración de la edición corta anterior; dentro del texto del Cap. 6 la caja de profundización dice "Capítulo 8" (antiguo) para PDS. El PDF numerado automáticamente está bien, pero los comentarios y referencias cruzadas textuales confunden.

---

## 5. Matriz capítulo a capítulo

Escalas 1–5. **T** = teoría, **M** = metodología, **A** = alineación con el sílabo. ◇ = electivo (fuera del camino crítico ★).

| Cap. | Título | T | M | A | Observación principal |
|:---:|---|---|:---:|:---:|:---:|---|
| 1 | Causalidad elemental | 3.5 | 2.0 | 5.0 | Arranque conceptual correcto; Yule (1903) sin clave; sin lab |
| 2 | Anatomía del sistema | 3.0 | 4.0 | 5.0 | Bien anclado en Huyen/Sculley/Breck; faltan Zinkevich 2017 y Paleyes et al. 2022 |
| 3 | SCM y PCH | 4.5 | 3.5 | 5.0 | SCM formal correcto; falta cita de Bareinboim et al. 2022 (PCH); do-calculus prometido |
| 4 | Ingeniería de datos | 3.0 | 4.0 | 5.0 | `CausalSchema` acertado; inconsistencia Parquet vs. CSV |
| 5 | Predicción vs. causalidad | 4.0 | 3.5 | 4.5 | Sólido; falta Kleinberg et al. 2015; numeración antigua en cabecera |
| 6 | Regularización y PDS | 4.5 | 4.0 | 5.0 | Teoría canónica; garantía "irrepresentabilidad" no demostrada; falta Zhao & Yu 2006 y selective inference |
| 7 | Datos de entrenamiento | 2.5 | 3.0 | 5.0 | Balance con t-tests rudimentario; faltan Lalonde/DW sin clave y Rubin 1976 |
| 8 | Intervención y contrafactual | 4.5 | 4.0 | 5.0 | Puerta trasera formal + 3 pasos contrafactual; no enuncian las 3 reglas del do-calculus; falta Elwert & Winship 2014 |
| 9 | Features sin fuga | 2.5 | 3.0 | 5.0 | Auditoría declarativa (timestamps + rol); inconsistencia "desconocido" en código |
| 10 | Ortogonalidad y cross-fitting | 5.0 | 4.5 | 5.0 | **Mejor capítulo teórico**; score ortogonal formal; prueba duplicada; falta Robinson 1988 en refs |
| 11 | DML | 4.5 | 4.5 | 5.0 | PLR/IRM/PLIV completos con librerías; **error `angrist1991`→Card** |
| 12 | Meta-learners | 4.5 | 4.0 | 5.0 | S/T/X/R + R-learner con teorema Nie–Wager; DR-learner sin Kennedy 2020; clave `foster2023` confusa |
| 13 | Bosques causales | 4.5 | 4.0 | 5.0 | Honestidad, GRF como pesos locales; policy trees sin cita Athey–Wager 2021 |
| 14 | Validación | 4.0 | 4.5 | 5.0 | Qini/TO/placebos completos; faltan Thornton 2008, VanderWeele & Ding 2017; AUUC no mencionada |
| 15 | Despliegue como servicio | 3.0 | 4.0 | 5.0 | FastAPI+Docker correcto, IC en la API; `/metadata` anunciado pero no implementado |
| 16 | PDS ◇ | 4.5 | 4.5 | 4.0 | Teorema BCH 2014 impecable; λ teórico vs. CV sin discutir; sin cross-fit PDS |
| 17 | Panel y DML-IV ◇ | 4.0 | 3.5 | 4.0 | FE + cluster cross-fitting correctos; caja DiD moderna; código dependiente de versión de DoubleML; falta Goodman-Bacon y de Chaisemartin |
| 18 | Mapa de decisión ◇ | 3.5 | 4.0 | 4.5 | Heurística `choose_method` útil; "Athey et al. 2021" sin clave (Arkhangelsky et al.) |
| 19 | Hub y model cards | 2.5 | 3.5 | 5.0 | Model card causal es aporte; muy breve; falta Gebru et al. 2021 (datasheets) |
| 20 | CI/CD causal | 2.5 | 3.5 | 5.0 | Pruebas estadísticas que bloquean publicación: distintivo; dependiente de infraestructura del curso; sin MLOps estándar |
| 21 | Policy learning | 4.0 | 3.5 | 5.0 | Teorema DR + presupuesto correctos; "caso" es DGP sintético; atribución regret imprecisa; EWM solo en refs |
| 22 | Uplift y targeting | 4.0 | 3.5 | 5.0 | Qini/AUUC/net score correctos; código con columnas inexistentes; cita `kuo2014causalml` errónea |
| 23 | Explicación y equidad | 3.5 | 3.0 | 5.0 | CDE/NIE y firma causal bien planteados; `dowhy` solo mencionado; falta Kilbertus et al. 2017 |
| 24 | Ética e interpretabilidad | 3.5 | 3.5 | 5.0 | SHAP aplicado al modelo de outcome, no al CATE (brecha central); *equalized CATE* no estándar; faltan Hardt 2016, Dwork 2012, calibration |
| 25 | Decisiones estructurales | 3.0 | 3.0 | 5.0 | Marco N2-PCH correcto; sin teoría de decisión (Berger, Manski) |
| 26 | Generalización ◇ | 3.5 | 3.0 | 4.0 | Reponderación = teorema de generalización; falta Pearl & Bareinboim 2011 y Correa & Bareinboim 2020 |
| 27 | Deep causal ◇ | 4.0 | 3.5 | 4.0 | TARNet/CFRNet/DeepIV bien; faltan Curth & van der Schaar 2021, RieszNet, Farrell et al. 2021 |
| 28 | SCM y matrix completion ◇ | 4.0 | 3.5 | 4.0 | SCM/MC canónicos; faltan Abadie et al. 2015, Doudchenko & Imbens 2016, Ben-Michael et al. 2021 |
| 29 | Discovery ◇ | 4.5 | 4.0 | 4.0 | PC/NOTEARS con CPDAG y validación SHD; faltan Kalisch & Bühlmann 2007, Chickering 2002 |
| 30 | Monitoreo | 3.0 | 3.5 | 5.0 | KS + F + estabilidad: bueno; test de estabilidad ad-hoc; F>10 sin Stock & Yogo; sin PSI/ASMD |
| 31 | Aprendizaje continuo | 3.0 | 3.5 | 5.0 | Champion-challenger integrado con CI causal; RL causal solo panorama (declarado) |
| 32 | Lado humano | 2.5 | 3.0 | 5.0 | Comunicación en 3 capas útil; bibliografía más delgada (sin risk communication ni Lipton 2018) |

**Promedios:** Teoría = **4.0** (4.1 ponderado por las entradas ★) · Metodología = **3.8** · Alineación = **4.6**.

---

## 6. Brechas frente al estado del arte (evidencia OpenAlex + Tavily)

Referencias **ausentes** de la monografía que el estado del arte considera canónicas para los temas cubiertos (citas OpenAlex):

| Tema donde aplica | Obra ausente | Citas OpenAlex | Impacto estimado |
|---|---|---|---|
| Paneles/DiD moderno (Caps. 17, 28) | Goodman-Bacon (2021), J. Econometrics | 7 508 | **Alto** |
| Paneles/DiD moderno (Caps. 17, 28) | de Chaisemartin & D'Haultfœuille (2020), AER | 4 750 | **Alto** |
| Paneles/DiD moderno (Cap. 17) | Borusyak, Jaravel & Spiess (2024), REStud | 1 911 | Medio |
| Sensibilidad a confusión (Cap. 14) | VanderWeele & Ding (2017), Ann. Int. Med. | 5 979 | **Alto** |
| Semiparametría (Caps. 10, 12) | Robinson (1988), Econometrica | 2 513 | **Alto** |
| Post-selección (Cap. 6) | Zhao & Yu (2006), JMLR | 2 016 | Medio |
| Equidad (Cap. 24) | Hardt et al. (2016), NeurIPS | 1 927 | **Alto** |
| Equidad (Cap. 24) | Dwork et al. (2012), ITCS | 3 423 | Medio |
| IV débil (Caps. 17, 30) | Stock & Yogo (2005) | 1 899 | Medio |
| Model cards (Cap. 19) | Gebru et al. (2021), CACM | ~3 500 (GS) | Medio |
| Discovery (Cap. 29) | Kalisch & Bühlmann (2007), JMLR | 621 | Medio |
| Discovery (Cap. 29) | Chickering (2002), JMLR | n/d (canónico) | Bajo |
| Collider (Caps. 5, 8) | Elwert & Winship (2014), Annu. Rev. Sociol. | 1 231 | Medio |
| CATE/DR-learner (Cap. 12) | Kennedy (2020), EJS 2023 | 152 | **Alto** |
| Deep causal (Cap. 27) | Farrell, Liang & Misra (2021), Econometrica | 319 | Medio |
| SCM (Cap. 28) | Ben-Michael, Feller & Rothstein (2021), JASA | 67 | Bajo |
| SCM (Cap. 28) | Doudchenko & Imbens (2016), NBER | 71 | Bajo |
| Uplift (Cap. 22) | Rzepakowski & Jaroszewicz (2012), KAIS | 184 | Bajo |
| Uplift (Cap. 22) | Chen et al. (2020), arXiv:2002.11631 (causalml) | n/d | **Alto** (cita errónea actual) |
| Uplift (Cap. 14) | Thornton (2008), AER | 522 | Bajo |
| Sistemas ML (Cap. 2) | Paleyes, Urma & Lawrence (2022), ACM Comput. Surv. | 586 | Medio |
| Decisiones (Cap. 25) | Manski (2004), Econometrica | 420 | Medio |
| Interpretabilidad (Cap. 32) | Lipton (2018), CACM | 457 | Bajo |
| Teoría de la PCH (Cap. 3) | Bareinboim, Correa, Ibeling & Icard (2022), ACM Books | 155 | **Alto** |
| RL causal (Cap. 31) | Zhang & Bareinboim (2019), NeurIPS | 24 | Bajo |

**Nota sobre la obra de Bareinboim (base teórica del curso).** *Causal Artificial Intelligence: A Roadmap for Building Causally Intelligent Systems* (causalai-book.net) es un borrador en evolución (v. Oct/2025, ~1 258 pp.), autoría de **Elias Bareinboim** (no "Bareinboim & Pearl"), gratuito y sin DOI/ISBN. Dos implicaciones: (i) citarla como "v0.27" (como hace el sílabo) es razonable pero conviene versionar la fecha de consulta; (ii) según una reseña pública (Hacker News), el libro **no cubre DML** — la monografía del curso cubre exactamente ese vacío (Caps. 10–11), lo que confirma su complementariedad, pero también significa que la "fuente principal de contenido teórico-causal" no puede sustituir a la bibliografía primaria (Pearl 2009; Chernozhukov et al. 2018; BCH 2014).

**Acierto de actualidad confirmado por Tavily:** la decisión del curso de combinar estimación causal con despliegue en Hugging Face (model cards causales, Spaces, CI con pruebas estadísticas) anticipa la dirección que la industria está tomando (workshops KDD 2025, tutoriales KDD 2021 EconML+CausalML, casos DoorDash/BBVA). No hay brecha de actualidad en el *posicionamiento*; sí en un puñado de referencias y en la ejecución de algunos listados.

---

## 7. Recomendaciones priorizadas

### P0 — Correcciones de contenido (antes de recompilar la edición definitiva)

1. **Corregir las citas erróneas verificadas:** (a) Cap. 11: `angrist1991` → `card1995` (existe en `refs.yml`); (b) Cap. 22: eliminar/reemplazar `kuo2014causalml` por Chen et al. (2020), arXiv:2002.11631; (c) Cap. 12: revisar `foster2023orthogonal` (título corrupto y contenido asignado a `foster2019`); (d) Cap. 24: verificar `kitagawa2021equality` (contenido citado = Kitagawa–Sakaguchi–Tetenov 2021, *Constrained Classification and Policy Learning*).
2. **Añadir las referencias canónicas ausentes del núcleo ★:** Robinson (1988) en Caps. 10/12; Kennedy (2020) en Cap. 12; Zhao & Yu (2006) en Cap. 6; Bareinboim et al. (2022) en Cap. 3; VanderWeele & Ding (2017) en Cap. 14; Hardt et al. (2016) y Dwork et al. (2012) en Cap. 24; Elwert & Winship (2014) en Caps. 5/8; Stock & Yogo (2005) en Caps. 17/30; Lalonde (1986) y Dehejia & Wahba (1999) en Cap. 7; Thornton (2008) en Cap. 14; Gebru et al. (2021) en Cap. 19; Kleinberg et al. (2015) en Cap. 5.
3. **Resolver las promesas formales:** formalizar las tres reglas del cálculo-*do* en el Cap. 8 (o reescribir la promesa de los Caps. 3/8); corregir la garantía del cuadro del Cap. 6 (irrepresentabilidad → restricted eigenvalue, o añadir Zhao & Yu); añadir cita al teorema de la PCH.

### P1 — Calidad de la evidencia empírica

4. **Etiquetar casos aplicados vs. simulados** (Caps. 17, 21, 22) y hacer ejecutables los listados que no lo son (Cap. 22: estimar `uplift_sms`/`uplift_call` o usar otro caso; Cap. 17: fijar versión de DoubleML o ajustar la API).
5. **Subir el nivel del chequeo de balance** (Cap. 7): SMD + criterio de Rubin + corrección por múltiples comparaciones, con cita (Imbens & Rubin 2015).
6. **Reparar inconsistencias código/declaración:** Cap. 9 (política "desconocido"), Cap. 15 (`/metadata`), Cap. 4 (Parquet vs. CSV, usando el puente `lib.schema.CausalSchema.from_scenario` ya previsto en `PLAN_INTEGRACION_MONOGRAFIA.md`).
7. **Duplicación de prueba en el Cap. 10:** la "prueba" del teorema central de DML repite la de ortogonalidad del score PLR; reemplazar por un sketch diferenciado.

### P2 — Ampliación selectiva (estado del arte)

8. **DiD moderno en Caps. 17/28:** añadir Goodman-Bacon (2021) y de Chaisemartin & D'Haultfœuille (2020) a la caja DiD; opcional Borusyak et al. (2024).
9. **Deep causal (Cap. 27):** añadir Curth & van der Schaar (2021, *inductive biases*) y la línea RieszNet/Farrell et al. (2021) para cerrar el problema de inferencia declarado.
10. **Discovery (Cap. 29):** añadir Kalisch & Bühlmann (2007), Chickering (2002) y una advertencia de sensibilidad a hiperparámetros (AISTATS 2024).
11. **SCM (Cap. 28):** añadir Abadie et al. (2015) (inferencia por placebos), Doudchenko & Imbens (2016) y Ben-Michael et al. (2021); discutir selección del rango `r`/`λ` en matrix completion.
12. **Monitoreo (Cap. 30):** formalizar el test de estabilidad del efecto (propagar SE) y añadir PSI o ASMD sobre la relación tratamiento-covariables.
13. **Cap. 19/20:** citar datasheets (Gebru et al. 2021) y nombrar 1–2 herramientas MLOps estándar (MLflow/DVC/Evidently) como referencia, manteniendo el aporte propio del CI estadístico.
14. **Caps. 25/32:** una referencia de teoría de la decisión (Manski 2004 o Parmigiani & Inoue 2009) y una de comunicación de riesgo (Galesic & Garcia-Retamero 2011 o Spiegelhalter 2019).

---

## 8. Limitaciones de esta auditoría

- Los conteos de citas de OpenAlex son orientativos: varias obras están subcontadas (Athey & Wager 2021, GRF 2019, Arkhangelsky 2021, Gebru 2021, RieszNet) y los libros (Pearl 2009, Imbens & Rubin 2015, Huyen 2022, Spiegelhalter 2019, Bareinboim 2025) no tienen conteo fiable vía API; se contrastaron con Crossref/COCI o verificación web.
- La revisión de los 32 capítulos se hizo sobre las fuentes Typst (`.typ`); la numeración citada corresponde al PDF 2026 (tabla maestra de `PLAN_INTEGRACION_MONOGRAFIA.md`).
- No se ejecutaron los listados de código (fuera de alcance); las observaciones de ejecutabilidad provienen de inspección estática del código publicado en los capítulos.
- Las búsquedas Tavily reflejan el estado del arte a agosto de 2026 (fecha del sistema); los talleres y publicaciones citados (KDD 2025, Velez 2025, arXiv 2024–2025) son las señales más recientes disponibles.

---

## Anexo — Acciones puntuales sobre `02_monografia/…/bibliografia/refs.yml`

| Clave | Acción |
|---|---|
| `kuo2014causalml` | Reemplazar por Chen, Harinen, Lee, Yung, Zhao (2020), arXiv:2002.11631 |
| `foster2023orthogonal` | Revisar título (posible corrupción "Blanchard-Qua" → "Blanchard-Quah") y su uso en Cap. 12 |
| `kitagawa2021equality` | Verificar autoría/título; el contenido citado corresponde a Kitagawa–Sakaguchi–Tetenov (2021) |
| `spiegelhalter2017art` | Renombrar clave a `spiegelhalter2019art` (fecha real 2019) |
| `angrist1991` (uso en Cap. 11) | Sustituir por `card1995` |
| — | Añadir: `robinson1988`, `kennedy2020`, `zhaoyu2006`, `vanderweeleding2017`, `hardt2016`, `dwork2012`, `elwertwinship2014`, `stockyogo2005`, `lalonde1986`, `dehejia1999` (si se cita formalmente), `thornton2008`, `gebrudatasheets2021`, `kleinberg2015`, `goodmanbacon2021`, `dechaisemartin2020`, `bchin2022` (Bareinboim et al., PCH), `pearlbareinboim2011`, `correabareinboim2020`, `curthvanderschaar2021`, `farrell2021`, `benmichael2021`, `doudchenkoimbens2016`, `kalischbuhlmann2007`, `chickering2002`, `manski2004`, `paleyes2022` |
