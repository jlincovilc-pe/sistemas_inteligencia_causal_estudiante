# Plan único del curso — IA Causal en Producción

**Documento canónico de la práctica** del monorepo. Unifica sílabo (32 sesiones), labs, Serie A/B, datasets, evaluación y orden de construcción de código.

**Integración con la monografía (32 caps., enfoque profesional / HF / disrupción del efecto):** ver [`PLAN_INTEGRACION_MONOGRAFIA.md`](./PLAN_INTEGRACION_MONOGRAFIA.md).

| Campo | Valor |
|---|---|
| Curso | ECO-490 / ECON-540 — Edición 2026 |
| Duración | 16 semanas · **32 sesiones** × 1 h 30 |
| Balance | 50% teoría causal · 50% ingeniería de producción |
| Fuentes | Bareinboim · monografía Typst · DMLS (Chip Huyen) · HF Hub/Spaces |
| Datos de práctica | Solo `data_benchmark_causal/causal_benchmark_synthetic/datasets/` |
| Fecha del plan | 2026-08-02 |
| Estado Serie A | **Hecha** (`03_notebooks_caso_estudio/`) |
| Estado Serie B | **B1–B4 implementados** (humo local; push HF opcional) |
| Estado Labs / Proyecto | **27 labs smoke OK** + guías proyecto final |

### Documentos que este plan subsume (no los borra; los ordena)

| Carpeta / archivo | Rol residual |
|---|---|
| `01_silabo/silabo.typ` | Texto oficial del sílabo (evaluación, bibliografía) |
| `02_monografia/` | Monografía Typst **32 caps.** + PDF compilado |
| `02_monografia/HISTORICO.md` | Nota: esqueleto antiguo no es canónico |
| `03_notebooks_caso_estudio/` | Serie A implementada + plan A histórico |
| `04_notebooks_produccion_hf/propuesta_*.md` | Detalle B1–B4 (se implementa según §6) |
| `data_benchmark_causal/` | Ecosistema de benchmarks |

Si hay conflicto entre un doc antiguo y **este archivo**, gana **este archivo**.

---

## 1. Idea central (decisión de diseño)

### 1.1 Qué NO es el curso

- No son **32 notebooks de entrega** del tamaño de A1–A4.
- No son **16 notebooks de caso + 16 de HF** calificados cada semana (carga y rúbricas inviables).

### 1.2 Qué SÍ es (modelo en capas)

```text
Capa 0  Monografía          32 capítulos  ↔  sesiones de contenido
Capa 1  Labs de sesión      L01–L28       30–50 min, smoke ligero
Capa 2  Entregas Serie A    A1–A4         caso de estudio (estimación)
Capa 3  Entregas Serie B    B1–B4         producción Hugging Face
Capa 4  Proyecto final      P             S29–S32 (ensambla A+B)
```

**Intuición semanal (válida):** en la mayoría de las semanas hay **un polo causal** y **un polo de producción/sistema**.  
**Materialización:** eso se cubre con **lab de sesión + capítulo**, no con dos entregas pesadas por semana.

**Regla de oro:** un lab ensaya **un ladrillo**; una entrega A/B **ensambla el muro** del bloque.

---

## 2. Principios transversales

1. **Transparencia de datos.** Escenarios del monorepo son sintéticos con semántica de literatura; todo lab/notebook abre con el aviso `what_is_real` / `what_is_synthetic`.
2. **Capas de datos.** Estudiante: `observed_*.csv`. Truth (`y0,y1,tau`): solo evaluación final / autograder.
3. **Reproducibilidad.** `RANDOM_STATE = 42`; splits oficiales del escenario; paths vía helper monorepo (no paths absolutos de máquina).
4. **Sesión ≤ 90 min de actividad de clase.** Labs ≤ 45–50 min de trabajo activo del estudiante.
5. **Entregas quincenales = pipelines completos.** Autograder + rúbrica.
6. **SDK compartido.** `03_notebooks_caso_estudio/lib/` es la librería del curso; labs y B importan de ahí (o de un paquete extraído `course_causal/` en fase posterior).
7. **Cadena A → B.** Artefactos joblib de A alimentan B; B no reestima desde cero salvo ejercicio explícito.
8. **HITL mínimo en construcción.** Priorizar scripts kernel-less + tests; notebooks como capa pedagógica.

---

## 3. Estructura de carpetas objetivo del monorepo

```text
CAUSAL_ML_PRODUCTION/
├── PLAN_CURSO_COMPLETO.md          ← este documento (fuente de verdad)
├── README.md                       ← índice corto → apunta aquí
├── 01_silabo/
├── 02_monografia/                  ← monografía 32 caps. + PDF
├── 03_notebooks_caso_estudio/      ← Serie A + lib SDK
│   ├── lib/
│   ├── notebooks/A1…A4.ipynb
│   ├── artifacts/A2|A3|A4/
│   ├── autograder/
│   ├── scripts/
│   └── tests/
├── 04_notebooks_produccion_hf/     ← Serie B (TO DO)
│   ├── README.md
│   ├── requirements-b.txt
│   ├── B1_fastapi_dml/
│   │   ├── app.py
│   │   ├── Dockerfile
│   │   ├── notebook_smoke.ipynb
│   │   └── tests/
│   ├── B2_hub_cicd/
│   ├── B3_policy_space/
│   ├── B4_monitoring_dashboard/
│   ├── autograder/
│   └── rubrics/
├── 05_labs_sesion/                 ← Labs L01–L28 (TO DO)
│   ├── README.md
│   ├── template_lab.ipynb
│   ├── L01_…/
│   │   ├── lab.ipynb
│   │   └── checks.py               # asserts smoke
│   ├── … L28_…/
│   └── tests/test_lab_smokes.py
├── 06_proyecto_final/              ← guías S29–S32 (TO DO)
│   ├── guia_proyecto.md
│   ├── rubrica_proyecto.md
│   └── checklist_humo.md
├── 07_diapositivas/                ← 32 mazos Touying por capítulo
│   ├── plantilla_monografia.typ
│   ├── build.sh
│   └── capitulos/cap01…cap32.typ
└── data_benchmark_causal/          ← datasets (existente)
```

Migración opcional futura: extraer `lib/` a paquete `causal_course_sdk` instalable; **no bloquea** el plan.

---

## 4. Evaluación (alineada al sílabo)

| Componente | Peso | Artefactos | Criterio |
|---|---:|---|---|
| Proyecto final | 40% | Sistema HF + defensa | Humo obligatorio (endpoint + estimaciones razonables) |
| Serie A | 20% | A1–A4 | Autograder + rúbrica metodológica |
| Serie B | 15% | B1–B4 | Autograder de humo + rúbrica de ingeniería |
| Revisión por pares | 10% | 2–3 proyectos | Rúbrica estructurada |
| Quizzes | 10% | 7 quizzes | Banco aleatorizado |
| Contribución Hub | 5% | dataset o model card | Publicado y reutilizable |
| Labs L01–L28 | **0% nota** (default) | smoke checks | Obligatorios para “estar al día”; badge opcional |

**Política labs:** no reabrir pesos del sílabo en v1. Labs = práctica formativa. En v2 se puede asignar 5% desde quizzes/Hub si hace falta incentivo.

---

## 5. Datasets canónicos del monorepo

Prefijo: `data_benchmark_causal/causal_benchmark_synthetic/datasets/`

| ID uso | Ruta | scenario_id | Uso principal |
|---|---|---|---|
| JOBS | `real/jobs` | `real_jobs` | A1, L04–L06 |
| IHDP_M | `synthetic/inference/ihdp_medium` | `synthetic_inference_ihdp_medium` | A2, L09–L11, B1 |
| IHDP | `real/ihdp` | `real_ihdp` | A3, A4, L13–L15, L21–L23, B3 |
| LALONDE_M | `synthetic/inference/lalonde_medium` | … | Lab opcional / sensibilidad A1 |
| SACHS | `real/sachs` | `real_sachs` | L26 discovery |
| LG_SMALL | `synthetic/linear_gaussian/10_vars_10_edges` | … | L26 alt / demo PC |
| LATENT | `synthetic/edge_cases/latent_confounder` | … | L07 contrajemplo (no estimable) |
| TWINS | `real/twins` / `inference/twins_*` | no_scored | Solo “abstenerse” (opcional) |

**Prohibido en flujo estudiante:** descargas externas (401k, Criteo, Card) como dependencia dura. Si se citan, solo como lectura.

---

## 6. Serie A — Casos de estudio (estado: HECHO)

Ubicación: `03_notebooks_caso_estudio/`

| ID | Archivo | Sesiones ancla | Dataset | Técnica | Artefacto salida | Estado |
|---|---|---|---|---|---|---|
| **A1** | `A1_identificacion_jobs.ipynb` | S4–S6 | JOBS | Identificación, overlap, OLS, PDS | justificación escrita | ✅ |
| **A2** | `A2_dml_ihdp_medium.ipynb` | S8–S11 | IHDP_M | DML PLR, Neyman, CF | `artifacts/A2/dml_estimator.joblib` → **B1** | ✅ |
| **A3** | `A3_cate_meta_learners_ihdp.ipynb` | S13–S15 | IHDP | S/T/X/R + CF, Qini, placebo | `artifacts/A3/cate_scores_test.csv` → A4 | ✅ |
| **A4** | `A4_policy_uplift_ihdp.ipynb` | S22–S23 | IHDP | Policy top-k, uplift, equity | `artifacts/A4/policy.joblib` → **B3** | ✅ |

DoD A (ya verificado en corridas previas):

- `pytest` en verde · `grade_a1…a4` PASS · nbclient execute OK · exports kernel-less.

**Mantenimiento A en este plan:** solo bugs y contratos de interfaz hacia B; no reescritura.

---

## 7. Serie B — Producción Hugging Face (por construir)

Ubicación: `04_notebooks_produccion_hf/`

### B1 — Endpoint DML (FastAPI + Docker)

| | |
|---|---|
| **Sesiones** | S12 (lab) · entrega ~S14 |
| **Insumo** | `03_…/artifacts/A2/dml_estimator.joblib` + `feature_list.json` + `training_meta.json` |
| **Stack** | FastAPI, uvicorn, Docker, joblib, pydantic |
| **Rutas** | `GET /health` · `POST /predict` (covariables → efecto / IC si aplica) |
| **Humo** | contenedor up; `/predict` < 2 s; valor ~ ATE de A2 (± tolerancia YAML) |
| **Entregable** | `B1_fastapi_dml/` + notebook o script de prueba |
| **Carga** | 3–4 h |

### B2 — Hub + model card causal + CI/CD

| | |
|---|---|
| **Sesiones** | S17–S18 |
| **Insumo** | repo B1 |
| **Stack** | huggingface_hub, GitHub Actions, Docker |
| **Humo** | workflow Actions verde; model card con estimando, supuestos, población, límites |
| **Entregable** | URL Hub + badge CI |
| **Carga** | 3–4 h |

### B3 — Space de política (Gradio)

| | |
|---|---|
| **Sesiones** | S23–S26 (arranque S23, entrega ~S26) |
| **Insumo** | `artifacts/A4/policy.joblib` + `policy_card.md` |
| **Stack** | Gradio, HF Spaces |
| **Humo** | Space carga; 3 combinaciones de covariables devuelven `{decision, uplift_score}` |
| **Entregable** | URL Space |
| **Carga** | 3–4 h |

### B4 — Dashboard de monitoreo causal

| | |
|---|---|
| **Sesiones** | S25–S28 |
| **Insumo** | endpoint B1/B2 + tráfico simulado con drift |
| **Stack** | Streamlit o Gradio; scipy/statsmodels |
| **Métricas** | (a) KS drift covariables (b) tasa/fuerza de tratamiento en ventana (c) estabilidad del efecto en ventanas |
| **Humo** | dashboard corre; ≥1 alerta visible en escenario de drift |
| **Entregable** | Space/dashboard + notas de umbral |
| **Carga** | 4–5 h |

### Contratos de interfaz A → B (inmutables salvo versionado)

```text
A2 joblib:
  - const_marginal_ate() | ate()  → float
  - opcional predict(X)
  - feature_list.json: lista ordenada de 25 features (ihdp_medium)

A4 policy.joblib:
  - predict(X=… | scores=…) → {"decision": array-like, "uplift_score": array-like}
  - treat_rate bajo budget_fraction=0.20 (±0.02)
```

---

## 8. Labs de sesión L01–L28

### 8.1 Plantilla obligatoria de cada lab

```text
1. Título + sesión + capítulo monografía + entrega A/B que alimenta
2. Aviso transparencia de datos
3. Objetivo único (1 frase) + tiempo estimado
4. Setup (import lib / paths)
5. 3–6 celdas de trabajo
6. Auto-check (checks.py o asserts) — 3 a 8 condiciones
7. “Qué se reutiliza en A#/B#”
8. Checklist de cierre (3 ítems)
```

**Prohibido en labs:** reentrenar todo A2; pipelines Docker completos; truth en celdas centrales.

### 8.2 Catálogo completo

| Lab | Sesión | Tipo | Título corto | Dataset | Alimenta | Cap monografía |
|---|---|---|---|---|---|---|
| L01 | S1 | Causal | Correlación ≠ causación (3 casos + Simpson) | toy / tabla fija | A1 conceptual | Cap.1 |
| L02 | S2 | Prod | Entorno: Git, HF account, Docker hello | — | B* base | Cap.2 |
| L03 | S3 | Causal | Clasificar preguntas en PCH (3 niveles) | 10 ítems markdown/CSV | A1 | Cap.3 |
| L04 | S4 | Prod-datos | Roles T/Y/X + EDA en Jobs | JOBS | **A1** | Cap.4 |
| L05 | S5 | Causal | PDS en controles expandidos | JOBS | **A1** | Cap.5 |
| L06 | S6 | Prod-datos | Splits oficiales + justificación de muestreo | JOBS | **A1 entrega** | Cap.6 |
| L07 | S7 | Causal | Backdoor / contrajemplo latente | LATENT + DAG toy | A2 prep | Cap.7 |
| L08 | S8 | Prod-feat | Cazar leakage en pipeline roto | IHDP_M (features malas sintéticas) | **A2** | Cap.8 |
| L09 | S9 | Causal | Residuales de Neyman (toy + 1 fold) | IHDP_M sample | **A2** | Cap.9 |
| L10 | S10 | Causal | PLR mínimo (1 learner, K=3) | IHDP_M | **A2** | Cap.10 |
| L11 | S11 | Eval | Qini + placebo en miniatura | IHDP o IHDP_M | **A2 entrega** | Cap.11 |
| L12 | S12 | Prod | Stub FastAPI `/predict` (sin Docker full) | artefact A2 | **B1** | Cap.12 |
| L13 | S13 | Causal | Solo T-learner en IHDP | IHDP | **A3** | Cap.13 |
| L14 | S14 | Causal/Prod | CF light + empaquetar humo B1 | IHDP + A2 art. | **B1 entrega**, A3 | Cap.14 |
| L15 | S15 | Integración | Checklist A1–A3 + bugs comunes | — | **A3 entrega** | — |
| — | S16 | Exam | Sin lab nuevo | — | Checkpoint 1 | — |
| L17 | S17 | Prod | Esqueleto model card causal | meta A2 | **B2** | Cap.15 |
| L18 | S18 | Prod | Un job GHA que corre pytest humo B1 | B1 tests | **B2 entrega** | Cap.16 |
| L19 | S19 | Causal | Explicación causal vs asociativa | casos texto | Proyecto | Cap.17 |
| L20 | S20 | Causal | SHAP sobre estimador guardado | A2/A3 art. | Proyecto | Cap.18 |
| L21 | S21 | Causal | Formalizar decisión (acción, pérdida) | plantilla | **A4** | Cap.19 |
| L22 | S22 | Causal | Política top-k B=20% | scores A3 / IHDP | **A4** | Cap.20 |
| L23 | S23 | Causal/Prod | Uplift curve + stub Gradio | A4 art. | **A4 entrega**, **B3** | Cap.21 |
| L24 | S24 | Causal | Checklist de transportabilidad | 2 poblaciones sintéticas simples | Proyecto | Cap.22 |
| L25 | S25 | Prod | KS drift en 3 covariables | stream simulado desde IHDP_M | **B4** | Cap.23 |
| L26 | S26 | Causal | PC o NOTEARS en red pequeña | SACHS o LG_SMALL | B3 cierre / frontera | Cap.24 |
| L27 | S27 | Híbrido | ¿Reentrenar o alertar? umbrales | logs L25 | **B4** | Cap.25 |
| L28 | S28 | Prod-humano | Comunicar ATE a no técnicos (1 pág.) | números A2 | **B4 entrega** | Cap.26 |
| — | S29–S32 | Proyecto | Guías en `06_proyecto_final/` | A+B arts. | **P 40%** | — |

**Nota de numeración:** no hay L16 (S16 = examen). Labs = 27 archivos de práctica + guías de proyecto (L01–L15, L17–L28).

---

## 9. Mapa maestro S1–S32 (una sola tabla)

| Sem | Sesión | Tema (sílabo) | Cap. | Lab | Entrega que cierra / avanza |
|---:|---|---|---|---|---|
| 1 | S1 | Causalidad elemental | 1A | L01 | — |
| 1 | S2 | Sistema ML en producción | 2B | L02 | Lab 0 entorno |
| 2 | S3 | SCM y PCH | 3A | L03 | — |
| 2 | S4 | Ingeniería de datos causal | 4B | L04 | **arranca A1** |
| 3 | S5 | Regularización y PDS | 6A (+16 ◇) | L05 | A1 |
| 3 | S6 | Datos de entrenamiento | 7B | L06 | **entrega A1** |
| 4 | S7 | do-calculus / contrafactuales | 8A | L07 | — |
| 4 | S8 | Features sin fuga causal | 9B | L08 | **arranca A2** |
| 5 | S9 | Neyman / cross-fitting | 10A | L09 | A2 |
| 5 | S10 | DML PLR/IRM | 11A | L10 | A2 |
| 6 | S11 | Eval offline causal | 14A | L11 | **entrega A2** |
| 6 | S12 | Despliegue servicio | 15B | L12 | **arranca B1** |
| 7 | S13 | Meta-learners | 12A | L13 | **arranca A3** |
| 7 | S14 | Bosques causales | 13A | L14 | **entrega B1** · A3 |
| 8 | S15 | Integración | — | L15 | **entrega A3** |
| 8 | S16 | Checkpoint / parcial | — | — | Examen 15% |
| 9 | S17 | HF Hub + model cards | 19B | L17 | **arranca B2** |
| 9 | S18 | CI/CD causal | 20B | L18 | **entrega B2** |
| 10 | S19 | Explicación y equidad | 23A | L19 | — |
| 10 | S20 | SHAP / fairness | 24A | L20 | — |
| 11 | S21 | Decisiones estructurales | 25A | L21 | — |
| 11 | S22 | Policy learning | 21A | L22 | **arranca A4** |
| 12 | S23 | Uplift / targeting | 22A | L23 | **entrega A4** · **arranca B3** |
| 12 | S24 | Transportabilidad | 26A | L24 | — |
| 13 | S25 | Drift / monitoreo causal | 30B (+17 ◇) | L25 | **arranca B4** |
| 13 | S26 | Discovery PC/NOTEARS | 29A | L26 | **entrega B3** |
| 14 | S27 | Continual learning / RL panorama | 31B | L27 | B4 |
| 14 | S28 | Lado humano | 32B | L28 | **entrega B4** |
| 15 | S29 | Proyecto + mentoría | — | P1 | Proyecto |
| 15 | S30 | Peer review | — | P2 | 10% |
| 16 | S31 | Presentaciones finales | — | P3 | **entrega final 40%** |
| 16 | S32 | Cierre y frontera | — | P4 | Encuesta |

---

## 10. Flujo de artefactos (sistema del curso)

```text
JOBS ──L04-06──► A1 (identificación)
                      │
IHDP_M ──L08-11──► A2 (DML) ──joblib──► B1 (API) ──► B2 (Hub+CI)
                      │                    │
                      │                    └── logs/sim ──► B4 (monitor)
                      │
IHDP ──L13-15──► A3 (CATE) ──scores──► A4 (policy) ──joblib──► B3 (Space)
                      │                     │
                      └─────────────────────┴──► Proyecto final (P)
```

---

## 11. Monografía (Capa 0) — recordatorio de plantillas

| Plantilla | Uso | Estructura |
|---|---|---|
| **A** | Caps. teoría/estimación | problema → teoría → algoritmo → caso → riesgos → ejercicios |
| **B** | Caps. producción | problema de diseño → trade-offs → decisión curso → impl. ref. → validez causal → checklist |
| **Híbrida** | Caps. 11, 25 | eval offline; continual/RL |

Escritura de capítulos Typst es **track paralelo** a labs/notebooks; el plan de *código* no bloquea por monografía completa, pero cada lab **cita** el cap. correspondiente.

---

## 12. Fases de implementación (construcción del monorepo)

Esfuerzo orientativo en **días-persona** de desarrollo docente (no horas estudiante).

### Fase 0 — Gobernanza ✅

- [x] Este plan único
- [x] README raíz apunta al plan
- [x] Carpetas `05_labs_sesion/`, `06_proyecto_final/`
- [x] Convención de nombres y template de lab

### Fase 1 — Serie B núcleo ✅

- [x] **B1** FastAPI + Docker + humo + autograder
- [x] **B2** model card + Actions
- [x] **B3** Gradio Space local + instrucciones de push HF
- [x] **B4** dashboard drift simulado
- [x] `04_…/README.md` + tests de humo

### Fase 2 — Labs camino crítico A1–A2–B1 ✅

- [x] Template lab + harness `checks.py`
- [x] L04, L05, L06 (→ A1)
- [x] L08, L09, L10, L11 (→ A2)
- [x] L12, L14 (→ B1)
- [x] Smoke pytest de esos labs

### Fase 3 — Labs A3–A4–B3 ✅

- [x] L13, L15
- [x] L21, L22, L23
- [x] Integración con artefactos A3/A4 existentes

### Fase 4 — Labs B2/B4 y resto ✅

- [x] L17, L18
- [x] L25, L27, L28
- [x] L01–L03, L07, L19, L20, L24, L26
- [x] L02 como checklist de entorno (script)

### Fase 5 — Proyecto y checkpoint ✅ parcial

- [x] `06_proyecto_final/` guías P1–P4
- [x] Rúbrica proyecto + checklist humo alineado a B1–B4
- [ ] Guía S16 (qué entra en parcial) — opcional pendiente

### Fase 6 — Endurecimiento ⏳ parcial

- [x] Script `scripts/audit_repo.sh` (auditoría **local**; sin CI en la nube)
- [x] Plantilla CI educativa en `B2_hub_cicd/templates/` (no Actions del monorepo)
- [x] Pasada de consistencia de paths/artefactos (auditoría 2026-08-02)
- [ ] Actualizar sílabo Typst con labs formativos (opcional)
- [ ] Notebooks `.ipynb` de labs para estudiantes (opcional)
- [ ] Guía S16 parcial (opcional)

**Total orientativo:** 15–22 días-persona para el ecosistema completo de práctica.

---

## 13. Definition of Done global

El monorepo de práctica se considera **listo para dictar el curso** cuando:

1. A1–A4 siguen en verde (regresión).
2. B1–B4 existen, documentados, con humo automatizable **local** (HF cloud puede ser manual supervisado).
3. ≥ labs del camino crítico (Fase 2+3) ejecutan y pasan checks.
4. Mapa S1–S32 de este doc coincide con nombres de archivos en disco.
5. Proyecto final tiene rúbrica y checklist de humo.
6. Ningún notebook de entrega depende de datasets fuera del monorepo.
7. README raíz explica en <1 pantalla cómo navegar el plan.

**Listo para dictar “MVP del curso”** (más agresivo): solo **1 + 2 + labs L04–L12 + L13 + L22–L23** (Fases 0–3 mínimas). El resto de labs puede ir en oleadas durante el semestre.

---

## 14. MVP vs. completo

| Paquete | Incluye | Cuándo usarlo |
|---|---|---|
| **MVP dictable** | A1–A4 + B1–B4 + labs L04–L15 + L21–L23 + L12 + L17–L18 + L25 | Primera edición con tiempo limitado |
| **Completo** | MVP + todos L01–L28 + `06_proyecto` pulido + CI | Edición estable / materiales premium |
| **Solo código ya hecho** | A1–A4 | No cumple promesa “producción HF” del título del curso |

**Recomendación:** construir en orden **Fase 1 (B) → Fase 2–3 (labs core) → Fase 4–6**, y publicar MVP en cuanto B1+B3+camino A funcionen.

---

## 15. Riesgos y mitigaciones

| Riesgo | Mitigación |
|---|---|
| Alcance 28 labs + 8 entregas | MVP primero; labs restantes por oleada |
| EconML pesado / no instalable | Fallback sklearn ya en Serie A; B sirve joblib sklearn |
| HF tokens / red en CI | Humo local obligatorio; push HF en rúbrica manual |
| Estudiantes confunden lab con entrega | Naming L## vs A#/B#; banner en cada lab |
| Fuga de truth | Misma política A; grep en CI |
| Drift de paths monorepo | Un solo `resolve_repo_path` / DATA_ROOT |
| Sobrecarga estudiante | Labs formativos 0%; entregas siguen siendo 4+4 |

---

## 16. Orden de ejecución inmediato (checklist operativa)

```text
[x] 0.1  PLAN_CURSO_COMPLETO.md (este archivo)
[x] 0.2  README raíz → enlace canónico
[x] 0.3  Scaffold 05_labs_sesion/ + 06_proyecto_final/ + 04 estructura B
[x] 1.1  B1 app (FastAPI) + Dockerfile + tests humo cargando A2 joblib
[x] 1.2  B1 autograder (grade_b1.py — 11/11 PASS)
[x] 1.3  B3 Gradio + policy A4 (grade_b3 11/11)
[x] 1.4  B2 model card + Actions b1_smoke (grade_b2 11/11)
[x] 1.5  B4 dashboard drift Streamlit (grade_b4 8/8)
[x] 2.0  template_lab.ipynb (scaffold)
[x] 2.1  L04 L05 L06 (Jobs → A1) — smoke OK
[x] 2.2  L08–L12 + L14 (→ A2/B1) — smoke OK
[x] 3.1  L13 L15 L21–L23 — smoke OK (14 labs en suite)
[x] 4.*  resto labs L01–L03,L07,L17–L20,L24–L28
[x] 5.*  guías proyecto (guia + rúbrica + humo)
[ ] 6.*  CI + regresión A
```

---

## 17. Resumen en 10 líneas

1. El curso tiene **32 sesiones** y **32 capítulos**; la práctica calificada son **8 notebooks (4A+4B)**, no 32.
2. La intuición “cada semana causal + producción” se realiza con **labs L##** + monografía, no con 32 entregas.
3. **Serie A ya está construida** sobre JOBS / IHDP_M / IHDP del monorepo.
4. **Serie B** despliega A2→API/Hub y A4→Space, más monitoreo.
5. **Labs** son ladrillos de 30–50 min con smoke checks.
6. **Proyecto final** ensambla el sistema en S29–S32.
7. Datos **solo** `causal_benchmark_synthetic`.
8. Construcción: **B primero**, luego labs del camino A→B, luego el resto.
9. MVP dictable ≠ plan completo; este doc define ambos.
10. **Este archivo es la fuente de verdad** del diseño de práctica del monorepo.

---

*Plan único — IA Causal en Producción · monorepo CAUSAL_ML_PRODUCTION · 2026.*
