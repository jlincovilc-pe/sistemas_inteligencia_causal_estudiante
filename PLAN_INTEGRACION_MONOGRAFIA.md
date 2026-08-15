# Plan profesional de integración — Monografía × Monorepo

**Documento de integración** del curso *IA Causal en Producción* (ECO-490 / ECON-540, 2026).  
Complementa (no reemplaza) [`PLAN_CURSO_COMPLETO.md`](./PLAN_CURSO_COMPLETO.md). Cuando haya conflicto de **calendario o de práctica**, gana el plan de práctica; cuando haya conflicto de **numeración de capítulos del libro**, gana este documento + el PDF en `02_monografia/`.

**Uso semana a semana (profesor / estudiante):** [`CHRONOGRAMA_SEMANAL.md`](./CHRONOGRAMA_SEMANAL.md) y §12 de [`01_silabo/silabo.pdf`](./01_silabo/silabo.pdf).

| Campo | Valor |
|---|---|
| Fecha | 2026-08-02 |
| Audiencia objetivo | **Profesionales** (data/ML/product/analytics/risk/ops), no perfil de investigación básica |
| Norte del curso | **Casos de estudio** + **producción en Hugging Face** + **utilidad disruptiva del efecto causal** |
| Estado de partida | Monografía 32 caps. compilada · Serie A/B y 27 labs operativos · sílabo con refs. de caps. desactualizadas · contratos de datos idealizados en el libro vs CSV en el monorepo |

---

## 0. Tesis del producto formativo

### 0.1 Para quién es (y para quién no)

| Sí | No |
|---|---|
| Profesionales que ya usan ML/BI y deben **decidir o priorizar intervenciones** | Formación de econometristas teóricos |
| Equipos que llevan modelos a **servicios, Spaces, Hub, CI** | Solo paper methods o benchmarks SOTA |
| Quien necesita **comunicar efecto e incertidumbre** a negocio | Quién solo optimiza AUC/accuracy |

El profesional sale capaz de:

1. **Formular** una pregunta de efecto (no de predicción).  
2. **Estimar** ATE/CATE con stack moderno (DML, meta-learners) bajo supuestos explícitos.  
3. **Empaquetar** el estimador o la política en **HF** (API, model card, CI, Space, monitoreo).  
4. **Argumentar** por qué eso cambia la decisión de negocio (disrupción / utilidad).

### 0.2 Mensaje de disrupción (debe atravesar libro, labs y entregas)

Cada bloque del curso cierra con la misma pregunta de valor:

> *Si solo predijéramos el outcome, ¿a quién trataríamos? Si estimamos el **efecto**, ¿cambia el ranking, el presupuesto o el riesgo?*

| Nivel | Utilidad profesional | Ejemplo de disrupción |
|---|---|---|
| Asociación (ML clásico) | Score de riesgo / propensión | Tratar a los de “mayor riesgo” |
| Efecto medio (ATE) | ¿Vale la pena el programa en promedio? | Go / no-go de inversión |
| Efecto heterogéneo (CATE) | ¿A quién le mueve la aguja? | Targeting y fairness |
| Política bajo presupuesto | Asignación óptima de capacidad | Space + regla de decisión en HF |
| Monitoreo en producción | ¿Sigue siendo válido el efecto? | Alertas de drift de supuestos |

La monografía aporta el **porqué** y el **lenguaje de supuestos**. El monorepo aporta el **cómo se entrega en producción**.

### 0.3 Principios de integración (no negociables)

1. **Profesional primero:** menos teoremas sin decisión; más trade-offs, checklists y artefactos.  
2. **Un hilo de producto:** un sistema causal de ejemplo recorre A1→A2→B1→B2→A3→A4→B3→B4.  
3. **HF es el campus de producción:** Hub, Spaces, Actions, model cards — no demos sueltas.  
4. **Monorepo es la verdad del código:** CSV + `lib` + joblib; la monografía no inventa otro stack sin puente.  
5. **Tabla maestra única** sesión ↔ capítulo ↔ lab ↔ entrega (fuente de verdad de navegación).  
6. **Honestidad de datos:** benchmark sintético documentado; la disrupción se enseña con *decisiones*, no fingiendo datos clínicos reales.  
7. **Capítulos “científicos densos”** se marcan como *profundización opcional*, no como camino crítico del profesional.

---

## 1. Diagnóstico (por qué hace falta este plan)

| Dimensión | Hallazgo | Impacto en el profesional |
|---|---|---|
| Sílabo → caps. | Citas “Typst Cap. 2/3/4…” de la monografía **corta** | Abre el PDF en el cap. equivocado |
| Orden libro vs calendario | PDS en S5 (sílabo) vs Cap. 16 (libro) | Sensación de desorden |
| Contrato de datos | Libro: `CausalSchema` + Parquet; repo: CSV + `metadata.json` | Ejercicios del libro no corren tal cual |
| Labs | 27 labs en repo; monografía casi no los nombra | El libro no “empuja” a la práctica |
| Caps. 17–18, 27–28 | Panel/DML-IV, deep causal, matrix completion | Valiosos pero no son el núcleo pro/HF |
| Fuentes de verdad | PDF + plan práctica + esqueleto histórico | Confusión de qué mandar |

**Objetivo de integración:** que un profesional pueda, en cualquier sesión, saber en **un solo lugar**: qué leer (título del cap.), qué practicar (L##), qué entregar (A/B) y **qué decisión de negocio** se desbloquea.

---

## 2. Arquitectura de integración (capas)

```text
┌─────────────────────────────────────────────────────────────┐
│  POSICIONAMIENTO (este plan §0)                             │
│  Profesionales · efecto causal · disrupción · HF            │
└────────────────────────────┬────────────────────────────────┘
                             │
┌────────────────────────────▼────────────────────────────────┐
│  NAVEGACIÓN — Tabla maestra S ↔ Cap ↔ Lab ↔ A/B (§3)        │
│  PLAN_CURSO_COMPLETO + frontmatter monografía + sílabo      │
└────────────────────────────┬────────────────────────────────┘
                             │
        ┌────────────────────┼────────────────────┐
        ▼                    ▼                    ▼
┌───────────────┐  ┌──────────────────┐  ┌────────────────────┐
│ MONOGRAFÍA    │  │ PRÁCTICA         │  │ PRODUCCIÓN HF      │
│ 02_ PDF       │  │ Labs + Serie A   │  │ Serie B + proyecto │
│ porqué /      │  │ estimar en caso  │  │ servir · card ·    │
│ supuestos     │  │ realista monorepo│  │ CI · Space · drift │
└───────────────┘  └──────────────────┘  └────────────────────┘
                             │
┌────────────────────────────▼────────────────────────────────┐
│  CONTRATO TÉCNICO ÚNICO (§4) — monorepo como implementación │
│  de referencia; monografía alineada o con callout “en repo” │
└─────────────────────────────────────────────────────────────┘
```

---

## 3. Tabla maestra de navegación (S1–S32)

**Convención de lectura del libro:** siempre por **título / etiqueta `@cap-…`**, no por el número histórico del sílabo.  
**Camino crítico profesional (★):** obligatorio para la promesa del curso.  
**Profundización (◇):** lectura o lab ligero; no bloquea HF.

| Sesión | Tema (sílabo) | Cap. monografía (PDF) | Archivo `.typ` | Lab | Entrega | Valor de disrupción (1 línea) |
|---:|---|---|---|---|---|---|
| **S1** ★ | Causalidad elemental | **1** Causalidad elemental | `cap01_causalidad_elemental` | L01 | — | Deja de confundir correlación con “qué pasa si actuamos” |
| **S2** ★ | Sistema ML en producción | **2** Anatomía del sistema | `cap02_anatomia_sistema` | L02 | Lab 0 | El efecto no sirve si no se puede operar |
| **S3** ★ | SCM y PCH | **3** SCM y PCH | `cap03_scm_pch` | L03 | — | Clasifica preguntas: ver / hacer / imaginar |
| **S4** ★ | Ingeniería de datos causal | **4** Ingeniería de datos | `cap04_ingenieria_datos` | L04 | **A1 arranca** | Roles T/Y/X = contrato del sistema |
| **S5** ★ | Regularización y PDS | **6** (+ **16** PDS avanzado ◇) | `cap06_regularizacion_postseleccion` / `cap16_pds` | L05 | A1 | Controles en alta dimensión sin “p-hacking” ingenuo |
| **S6** ★ | Datos de entrenamiento | **7** Datos de entrenamiento | `cap07_datos_entrenamiento` | L06 | **A1 entrega** | Splits y procedencia = auditabilidad |
| **S7** ★ | do / contrafactuales | **8** Intervención y contrafactual | `cap08_intervencion_contrafactual` | L07 | — | Cuándo **no** estimar (abstenerse) |
| **S8** ★ | Features sin fuga | **9** Features sin fuga | `cap09_features_sin_fuga` | L08 | **A2 arranca** | Evita “efectos” inventados por leakage |
| **S9** ★ | Neyman / cross-fitting | **10** Ortogonalidad | `cap10_ortogonalidad_crossfitting` | L09 | A2 | Inferencia válida con ML flexible |
| **S10** ★ | DML PLR/IRM | **11** DML | `cap11_dml` | L10 | A2 | **ATE** accionable con IC |
| **S11** ★ | Eval offline | **14** Validación offline | `cap14_validacion` | L11 | **A2 entrega** | Confianza sin ground truth de negocio |
| **S12** ★ | Despliegue servicio | **15** Despliegue como servicio | `cap15_despliegue_servicio` | L12 | **B1** | El efecto se consulta por API |
| **S13** ★ | Meta-learners | **12** Meta-learners | `cap12_metalearners` | L13 | **A3 arranca** | Heterogeneidad = targeting |
| **S14** ★ | Bosques causales | **13** Árboles y bosques | `cap13_arboles_bosques` | L14 | **B1 entrega** | CATE robusto + servicio vivo |
| **S15** ★ | Integración | (repaso Caps. 1–15) | — | L15 | **A3 entrega** | Checklist de sistema causal |
| **S16** | Examen / checkpoint | — | — | — | Parcial | Síntesis, no nuevo método |
| **S17** ★ | HF Hub + model card | **19** Model cards y Hub | `cap19_hf_hub` | L17 | **B2** | Documentar supuestos = activo reutilizable |
| **S18** ★ | CI/CD | **20** CI/CD causal | `cap20_cicd` | L18 | **B2 entrega** | No se publica un efecto roto |
| **S19** ★ | Explicación y equidad | **23** Explicación y equidad | `cap23_explicacion_equidad` | L19 | — | Efecto ≠ importancia SHAP |
| **S20** ★ | Interpretabilidad / fairness | **24** Ética e interpretabilidad | `cap24_etica_interpretabilidad` | L20 | — | Auditoría responsable del CATE |
| **S21** ★ | Decisiones estructurales | **25** Decisiones bajo incertidumbre | `cap25_decisiones_estructurales` | L21 | — | Formalizar la decisión de negocio |
| **S22** ★ | Policy learning | **21** Policy learning | `cap21_policy_learning` | L22 | **A4 arranca** | Presupuesto → quién tratar |
| **S23** ★ | Uplift / targeting | **22** Uplift | `cap22_uplift_targeting` | L23 | **A4 + B3** | Política en **Space** HF |
| **S24** ★ | Transportabilidad | **26** Generalización | `cap26_generalizacion` | L24 | — | ¿El efecto vale en *mi* mercado? |
| **S25** ★ | Drift / monitoreo | **30** Monitoreo en producción | `cap30_monitoreo` | L25 | **B4** | Detectar cuando el efecto deja de valer |
| **S26** ★ | Discovery | **29** Descubrimiento de grafos | `cap29_descubrimiento_grafos` | L26 | B3 cierre | Estructura cuando el DAG no está dado |
| **S27** ★ | Continual / RL panorama | **31** Aprendizaje continuo (+ RL) | `cap31_aprendizaje_continuo` | L27 | B4 | Reentrenar vs alertar |
| **S28** ★ | Lado humano | **32** Lado humano | `cap32_lado_humano` | L28 | **B4 entrega** | Comunicar ATE a no técnicos |
| **S29–S32** ★ | Proyecto final | Ap. E + G/H + guía `06_` | — | P1–P4 | **40%** | Sistema causal en HF de punta a punta |

### 3.1 Capítulos de monografía **fuera del camino crítico** (profundización ◇)

| Cap. | Título | Uso recomendado para profesionales |
|---:|---|---|
| **5** | Predicción y causalidad (ML no es causal) | Lectura de refuerzo tras S1 (solapa con Cap. 1; priorizar Cap. 1 en vivo) |
| **16** | Post-Double-Selection (capítulo largo) | Ampliar S5 si el cohort es muy econométrico; si no, L05 + Cap. 6 bastan |
| **17** | Panel y DML-IV | Módulo electivo / oficina de proyectos sectoriales |
| **18** | Mapa de decisión metodológica | Guía de proyecto (elegir método); no sesión extra |
| **27** | Deep causal learning | Electivo avanzado (no bloquea HF) |
| **28** | SCM / matrix completion | Electivo (evaluación de programas con paneles) |

**Regla:** el profesional **aprueba el curso** sin dominar 17/27/28; los usa si su caso de negocio lo exige.

---

## 4. Contrato técnico único (cerrar el gap monografía ↔ código)

### 4.1 Decisión de producto

| Capa | Decisión |
|---|---|
| **Implementación de referencia** | Monorepo actual: `observed_*.csv`, `metadata.json`, `lib/*`, artefactos joblib, FastAPI/Gradio/Streamlit |
| **Monografía** | Describe el *diseño*; cuando el listado de código use `CausalSchema` / Parquet, se añade un **callout de implementación del curso** |

### 4.2 Callout estándar (insertar en monografía en caps. 4, 9, 15, 19, 20, 30)

> **Implementación en el monorepo del curso (2026).**  
> Los datos de práctica viven en `data_benchmark_causal/.../datasets/` como CSV + JSON (no Parquet obligatorio).  
> Los roles de variables se leen vía `lib.data_io.load_scenario` / `metadata.json` (equivalente operativo al `CausalSchema` del texto).  
> Serie A: `03_notebooks_caso_estudio/`. Serie B: `04_notebooks_produccion_hf/`. Labs: `05_labs_sesion/L##`.  
> Artefactos de producción: `artifacts/A2/dml_estimator.joblib` → B1/B2; `artifacts/A4/policy.joblib` → B3.

### 4.3 Opción de software (elegir una en ejecución del plan)

| Opción | Esfuerzo | Efecto |
|---|---|---|
| **A — Documental (recomendada v1)** | 1–2 días | Solo callouts + tabla maestra; cero reescritura de datos |
| **B — Puente ligero** | 3–5 días | Añadir `lib.schema.CausalSchema` que envuelve `load_scenario` y export opcional a Parquet |
| **C — Alineación total** | 2–3 semanas | Migrar datasets a Parquet + forzar schema en todos los notebooks | 

**Decisión de este plan:** **A + B ejecutados** (callouts monografía + `lib.schema.CausalSchema.from_scenario`). Opción C queda fuera de alcance salvo necesidad de producto.

### 4.4 Datasets canónicos del hilo profesional (sin cambio)

| Entrega | Dataset monorepo | Historia de negocio (framing pro) |
|---|---|---|
| A1 | `real/jobs` | ¿El programa de empleo sube ingresos? (go/no-go) |
| A2 / B1 / B2 | `ihdp_medium` | Efecto medio de una intervención con muchos controles |
| A3 / A4 / B3 | `real/ihdp` | ¿A quién priorizar bajo presupuesto 20%? |
| B4 | tráfico simulado sobre ihdp_medium | ¿El efecto sigue siendo creíble en “producción”? |

---

## 5. Integración por artefacto (qué tocar en cada carpeta)

### 5.1 Monografía (`02_monografia/monografia-ml-causal-typst/`)

| Acción | Prioridad | Descripción |
|---|---|---|
| Frontmatter “Mapa del curso profesional” | P0 | Nueva sección en `como_usar.typ` o `prefacio.typ`: audiencia, disrupción, tabla S↔Cap↔Lab↔A/B (resumida) |
| Callouts monorepo (§4.2) | P0 | Caps. 4, 9, 15, 19, 20, 30 |
| Pie de sesión | P1 | Al final de cada cap. con sesión: `Lab Lxx · Entrega Ay/Bz · Pregunta de valor` |
| Reencuadre Caps. 17, 27, 28 | P1 | Banner “Profundización profesional / electivo” |
| Cap. 5 vs Cap. 1 | P2 | Nota: Cap. 5 es refuerzo; sesión S1 prioriza Cap. 1 |
| Actualizar `PLAN_CONSTRUCCION.md` | P2 | Marcar compilación PDF hecha |
| Recompilar PDF | P0 | Tras cada oleada de edits Typst |

### 5.2 Sílabo (`01_silabo/silabo.typ`)

| Acción | Prioridad |
|---|---|
| Reemplazar “Typst Cap. N” por **título + número actual del PDF** (tabla §3) | P0 |
| Añadir columna o nota: Lab L## + entrega | P0 |
| Párrafo de posicionamiento: profesionales, HF, disrupción del efecto | P0 |
| Fuentes: monografía 32 caps. + monorepo paths | P1 |
| Compilar PDF del sílabo | P1 |

### 5.3 Plan de práctica (`PLAN_CURSO_COMPLETO.md`)

| Acción | Prioridad |
|---|---|
| Enlazar este plan de integración como “capa de libro” | P0 |
| Actualizar § monografía: 32 caps. (no 26) | P0 |
| Añadir columna “pregunta de valor / disrupción” a la tabla S1–S32 | P1 |

### 5.4 Labs (`05_labs_sesion/`)

| Acción | Prioridad |
|---|---|
| Cabecera unificada en cada `lab_core` / futuro `.ipynb`: Cap. monografía + pregunta de valor | P1 |
| Bloque final “Implicación de negocio (3 bullets)” en labs ★ del camino A/B | P1 |
| Generar `.ipynb` de estudiante (fase posterior) enlazando el cap. | P2 |

### 5.5 Serie A (`03_notebooks_caso_estudio/`)

| Acción | Prioridad |
|---|---|
| Portada de cada notebook: caps. monografía + sesión + **decisión de negocio** | P0 |
| Sección “Si solo predicéramos…” vs “Con el efecto…” (antes de resultados) | P0 |
| Mantener datasets monorepo (no close_college salvo electivo) | P0 |
| Opcional: `CausalSchema` puente (§4.3 B) | P2 |

### 5.6 Serie B (`04_notebooks_produccion_hf/`)

| Acción | Prioridad |
|---|---|
| B1–B4 README: enlace a caps. 15, 19–20, 30 + ap. G/H | P0 |
| Model card B2: plantilla alineada a Ap. G + números A2 | Ya casi; revisar wording “profesional / no clínico” | P1 |
| B3 Space: copy de UI orientado a decisor (no a paper) | P1 |
| B4: alertas como decisión ops (reentrenar / pausar política) | P1 |
| Checklist “publicado en HF” (manual) en B2/B3 | P1 |

### 5.7 Proyecto final (`06_proyecto_final/`)

| Acción | Prioridad |
|---|---|
| Rúbrica: peso a **decisión de negocio + HF humo** > novedad metodológica | P0 |
| Exigir sección “Disrupción: ranking predictivo vs causal” | P0 |
| Enlazar Ap. E/G/H de monografía | P1 |

### 5.8 Datos y zoo (`data_benchmark_causal/`)

| Acción | Prioridad |
|---|---|
| README corto “uso en el curso profesional” (Jobs/IHDP como *casos de decisión*) | P1 |
| No requiere cambio de esquema en v1 | — |

---

## 6. Hilo de producto único (storyline que unifica libro y repo)

Nombre de trabajo: **“Causal Decision System” (CDS)** — sistema de ejemplo del curso.

```text
Pregunta de negocio
    → A1  Identificación (Jobs)           [¿Es estimable?]
    → A2  ATE con DML (IHDP-medium)       [¿Cuánto mueve en promedio?]
    → B1  API FastAPI                     [¿Se puede consultar?]
    → B2  Hub + model card + CI           [¿Se puede confiar y versionar?]
    → A3  CATE                            [¿A quién le importa más?]
    → A4  Política bajo presupuesto       [¿A quién tratar con 20% capacidad?]
    → B3  Space Gradio                    [¿Un decisor no técnico puede usarlo?]
    → B4  Monitoreo                       [¿Sigue valiendo el efecto?]
    → P   Proyecto final en HF            [¿Tu caso de negocio en producción?]
```

La monografía **justifica** cada flecha; el monorepo **materializa** cada flecha.  
Ningún capítulo del camino crítico ★ termina solo en teoría sin apuntar a un artefacto A/B/L.

---

## 7. Enfoque de contenido: tono profesional en la monografía

Sin reescribir los 32 caps., aplicar en oleadas un **filtro de edición**:

| En cada cap. ★ | Añadir / enfatizar | Reducir / mover a notas |
|---|---|---|
| Apertura | Problema de decisión de negocio (1 párrafo) | Historia solo académica |
| Cierre | “Qué cambia en producción / HF” + lab/entrega | Solo ejercicios formales |
| Plantilla B | Trade-offs de costo (tiempo, riesgo, litigio, reputación) | Tutorial de una sola herramienta |
| Plantilla A | Supuestos en lenguaje de riesgo (“si falla X, la decisión se sesga así”) | Demostraciones largas (dejar en apéndice/nota) |

**Promesa de valor (elevator pitch del curso, reutilizar en sílabo + portada monografía + README):**

> *Deja de priorizar con scores predictivos que confunden correlación con impacto. Aprende a estimar efectos, a documentar supuestos y a poner políticas causales en producción en Hugging Face — con monitoreo de cuando dejan de ser válidas.*

---

## 8. Fases de ejecución (plan de trabajo)

### Fase I — Navegación y posicionamiento (3–5 días-persona) — **P0**

1. Publicar este plan y enlazarlo desde README + `PLAN_CURSO_COMPLETO`.  
2. Actualizar sílabo: columna fuente = Cap. **título + número actual**.  
3. Insertar en monografía frontmatter: audiencia profesional + tabla maestra resumida + pitch de disrupción.  
4. Callouts monorepo en caps. 4, 9, 15, 19, 20, 30.  
5. Recompilar monografía PDF + sílabo PDF.  
6. Portadas A1–A4 y README B1–B4 con mapa Cap/Lab y pregunta de valor.

**DoD Fase I:** un profesional puede ir de S10 a Cap. 11 + L10 + A2 + B1 sin contradicción de numeración.

### Fase II — Refuerzo de casos y HF (5–8 días) — **P1**

1. Bloques “Si solo predicéramos…” en A2, A3, A4.  
2. Copy B3 orientado a decisor; B4 a ops.  
3. Rúbrica de proyecto con sección disrupción predictivo vs causal.  
4. Banners “electivo” en caps. 17, 27, 28.  
5. Pies de sesión Lab/Entrega en todos los caps. ★.  
6. Recompilar PDF.

**DoD Fase II:** cada entrega A/B tiene un artefacto HF o de humo local y un párrafo de valor de negocio obligatorio.

### Fase III — Puente técnico opcional (3–5 días) — **P2**

1. Implementar `lib.schema.CausalSchema` (opción B §4.3).  
2. Migrar listados de monografía a “pseudocódigo = API del monorepo”.  
3. Notebooks `.ipynb` de labs con enlace al cap.  
4. CI ya existente: añadir job que falle si la tabla maestra y los paths A/B no existen (chequeo de integridad de integración).

**DoD Fase III:** un extracto de código del Cap. 15 corre contra B1 del monorepo con cambios mínimos.

### Fase IV — Operación del curso (continuo)

1. Guía del instructor: qué omitir en cohortes 100% pro (caps. ◇).  
2. Banco S16 alineado a camino ★ (no deep causal).  
3. Plantillas de comunicación (Cap. 32 / L28) en entregas B4 y proyecto.  
4. Casos de negocio adicionales (marketing, crédito, salud poblacional, políticas públicas) como *briefings* de 1 página, reutilizando los mismos estimadores.

---

## 9. Gobernanza de fuentes de verdad

Esta es la tabla **por pregunta** (qué documento responde cada duda operativa). Su contraparte **por documento** (qué archivo manda en general, para quien solo quiere un punto de entrada) vive en [`README.md` § Fuente de verdad](./README.md#fuente-de-verdad) — ambas deben mantenerse consistentes; no se duplica contenido, solo el ángulo de lectura.

| Pregunta | Documento que manda |
|---|---|
| ¿Qué se evalúa y cuándo se entrega? | `01_silabo` + `PLAN_CURSO_COMPLETO` |
| ¿Qué se lee del libro y con qué número de cap.? | **Este plan §3** + PDF `02_monografia` |
| ¿Qué código corre? | `03_`, `04_`, `05_`, `lib` |
| ¿Qué es electivo? | Este plan §3.1 |
| ¿Diseño histórico? | `02_monografia/HISTORICO.md` + `PLAN_CONSTRUCCION.md` en fuentes Typst |
| ¿Qué pasa semana a semana (profesor/estudiante)? | `CHRONOGRAMA_SEMANAL.md` |
| ¿Qué omitir en una cohorte 100% profesional? | `docs/NOTA_INSTRUCTORS.md` |

**Proceso:** todo cambio de orden de sesiones actualiza **sílabo + §3 de este plan + frontmatter monografía** en el mismo PR.

---

## 10. Métricas de éxito de la integración

| Métrica | Objetivo |
|---|---|
| Cero referencias “Typst Cap. N” incorrectas en sílabo | 100% |
| % de caps. ★ con pie Lab/Entrega/Valor | ≥ 95% |
| % de notebooks A/B con sección disrupción predictivo vs causal | 100% |
| Humo A+B+labs (`audit_repo.sh`) | Sigue en verde |
| Encuesta de cohort (fin de curso): “puedo llevar un efecto a HF” | ≥ 80% de acuerdo |
| Tiempo medio del profesional para localizar “qué hacer esta semana” | < 2 minutos (tabla maestra) |

---

## 11. Riesgos y mitigaciones

| Riesgo | Mitigación |
|---|---|
| Reescribir 32 caps. enteros | No: callouts + pies + banners electivos |
| Profesionales se pierden en Caps. 27–28 | Marcar electivo; sílabo no los programa como núcleo |
| Libro promete CausalSchema y el repo no lo tiene | Callout §4.2 + opción B de puente |
| Doble numeración confunde instructors | Una sola tabla maestra; deprecar esqueleto |
| Énfasis HF sin tokens en CI | Humo local obligatorio; push HF en rúbrica manual |
| “Disrupción” suena a marketing vacío | Exigir comparación **ranking predictivo vs política causal** con métrica (Qini / welfare) en A4 y proyecto |

---

## 12. Checklist operativa inmediata (sprint 1)

```text
[x] 1. Enlazar este plan desde README.md y PLAN_CURSO_COMPLETO.md
[x] 2. Reescribir sílabo (S1–S32): Caps. actuales del PDF + Lab + entrega + posicionamiento pro
[x] 2b. Compilar 01_silabo/silabo.pdf
[x] 3. Frontmatter monografía: audiencia pro + pitch disrupción + tabla resumida
[x] 4. Callouts monorepo en caps. 4, 9, 15, 19, 20, 30 (+ macro `#monorepo`)
[x] 7. typst compile monografía (311 pp.; recompilada 2026-08-02 tras Sprint 2 → 308 pp.)
[x] 5. Portadas A1–A4 y README B1–B4: Cap + Lab + pregunta de valor
[x] 6. Proyecto: rúbrica con sección "predictivo vs causal" (15 pts, irrenunciable)
[x] 8. bash scripts/audit_repo.sh — AUDIT PASS (A + labs + B + artefactos)
[x] 9. Nota histórica: `02_monografia/HISTORICO.md` (esqueleto antiguo no canónico)
[x] 10. Nota instructors: `docs/NOTA_INSTRUCTORS.md` (camino ★ vs electivos ◇)
[x] 11. Puente `lib.schema.CausalSchema` + tests
[x] 12. Notebooks de labs: `05_labs_sesion/L*/lab.ipynb` (27, generados)
```

### Sprint 2 — auditoría y cierre de brechas (2026-08-02)

Una auditoría independiente (evidencia contra código, no contra este checklist) encontró que el Sprint 1 estaba sustancialmente cumplido pero inflado en el detalle: un bug funcional real en `grade_a2` (DML sin SE/CI) y varios ítems del §5 marcados como P1 pendientes que el checklist arriba no reflejaba. Cerrado en esta sesión:

```text
[x] 13. Fix `dml_ci_reported`: econml PopulationSummaryResults usa stderr_mean/conf_int_mean, no stderr/conf_int (lib/dml_utils.py) — audit_repo.sh vuelve a AUDIT PASS
[x] 14. Bloque "Implicación de negocio" (3 bullets) en los 27 labs (generador + template_lab.ipynb)
[x] 15. `data_benchmark_causal/README.md`: sección "Uso en el curso profesional"
[x] 16. Recompilar PDF monografía (308 pp., reflejaba ~3h de ediciones no compiladas)
[x] 17. Unificar tablas de gobernanza (README.md ↔ este documento §9, referenciadas explícitamente)
[x] 18. Enlazar Ap. H (`apH_checklist_despliegue.typ`, sí existía pero sin inbound refs) en README B1/B3
[x] 19. Bloque "Decisión de negocio" explícito (frase "Si solo predijéramos… / Con el efecto…") en A1–A4
[x] 20. Model card B2: wording literal "profesional / no clínico" (antes parafraseado)
[x] 21. Copy de B3 Space reescrito para decisor no técnico: 25 covariables con etiqueta en español + explicación, salida en lenguaje de negocio (antes jerga tipo "ŝ(x) ≥ λ")
[x] 22. Numeración de apéndices: bug preexistente donde el índice general numeraba apéndices como capítulos secuenciales (33…40) mientras el encabezado visual usaba letras (A…H) y la palabra "Apéndice" nunca aparecía; fix en `template.typ` (`appendix-mode` resetea `counter(heading)` y usa numeración "A.1.1"; encabezado visual antepone la palabra "Apéndice"). De paso se descubrió y corrigió que la Bibliografía heredaba el estilo de apéndice (mostraba una letra fantasma, "Apéndice I", antes de "Bibliografía") — ahora usa el estilo frontmatter sin numerar.
```

---

## 13. Resumen ejecutivo

1. El monorepo y la monografía **ya comparten la visión** del curso; **no** comparten aún una navegación ni un contrato de datos idénticos.  
2. Este plan integra ambos alrededor de un **producto formativo para profesionales**: casos → efecto causal → **Hugging Face**.  
3. La disrupción se enseña como **cambio de decisión** (quién tratar / cuánto invertir / cuándo parar), no como paper.  
4. La ejecución es **incremental** (Fase I en días, no reescritura del libro).  
5. Tras Fase I, el curso se puede vender y dictar con un mensaje coherente; Fases II–III elevan pulido y fidelidad código–texto.

---

*Plan de integración monografía × monorepo — IA Causal en Producción · enfoque profesional · 2026.*
