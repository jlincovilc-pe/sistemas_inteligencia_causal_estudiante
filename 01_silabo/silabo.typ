// silabo.typ — IA Causal en Producción
// Sílabo alineado a monografía 32 caps. (PDF) + monorepo (labs, Serie A/B).
// Ver PLAN_INTEGRACION_MONOGRAFIA.md y PLAN_CURSO_COMPLETO.md.
#import "template/template.typ": *

#set document(
  title: "IA Causal en Producción — Sílabo",
  author: "Curso ECO-490 / ECON-540",
  keywords: "causal inference, machine learning, MLOps, Hugging Face, DML, profesionales",
)
#set page(paper: "a4", margin: (left: 2.4cm, right: 2.4cm, top: 2.8cm, bottom: 2.8cm), numbering: "1")
#set text(font: "New Computer Modern", size: 10.5pt, lang: "es", region: "ES", hyphenate: true)
#set par(justify: true, leading: 0.65em, spacing: 0.9em)

// ------------------------------------------------------------------
// Portada
// ------------------------------------------------------------------
#page(numbering: none)[
  #v(2cm)
  #align(center)[
    #text(font: sans-font, fill: navy, size: 15pt, tracking: 0.15em)[SÍLABO DEL CURSO]
    #v(0.6cm)
    #text(font: sans-font, fill: navy, size: 36pt, weight: "bold")[IA Causal en Producción]
    #v(0.5cm)
    #text(font: sans-font, fill: crimson, size: 14pt, style: "italic")[
      De la identificación al despliegue: estimar *efectos*, no solo predicciones, \
      y poner políticas causales en producción en Hugging Face
    ]
    #v(1.8cm)
    #block(fill: light, stroke: 0.5pt + navy, radius: 2pt, width: 90%, inset: 14pt)[
      #align(center)[
        #text(font: sans-font, size: 10.5pt)[
          *Audiencia:* Profesionales (data / ML / product / analytics / risk / ops) \
          *Modalidad:* Online, asíncrona con checkpoints síncronos \
          *Duración:* 16 semanas (4 meses) · 32 sesiones de 1 h 30 \
          *Balance:* 50% teoría causal · 50% práctica (casos + HF) \
          *Curso:* ECO-490 / ECON-540 — Edición 2026
        ]
      ]
    ]
    #v(1.2cm)
    #block(fill: white, stroke: 0.5pt + crimson, radius: 2pt, width: 90%, inset: 12pt)[
      #text(font: sans-font, size: 10pt)[
        *Promesa del curso.* Deja de priorizar con scores que confunden correlación con impacto.
        Aprende a *estimar efectos*, documentar supuestos y desplegar políticas causales en
        *Hugging Face* — con monitoreo de cuándo dejan de ser válidas.
      ]
    ]
    #v(1fr)
    #text(font: sans-font, fill: gray, size: 8.5pt)[
      Monografía del curso (32 caps., Typst/PDF) · _Designing Machine Learning Systems_ (Huyen) · \
      _Causal Artificial Intelligence_ (Bareinboim) · Monorepo: labs L01–L28 · Serie A/B · datos de benchmark
    ]
  ]
]

#frontmatter[

= 1. Presentación y fundamentación

Este curso está diseñado para *profesionales* que ya usan datos o machine learning y deben *decidir o priorizar intervenciones* —no para formar investigadores básicos en econometría teórica—. Combina tres fuentes: (1) el marco de IA causal de Elias Bareinboim (_Causal Artificial Intelligence_); (2) la monografía del curso _IA Causal en Producción_ (32 capítulos, Typst/PDF en #code[02_monografia/]); (3) la filosofía de ingeniería de _Designing Machine Learning Systems_ (Chip Huyen), aplicada a *sistemas cuyo objetivo es un efecto causal*, no solo un score predictivo.

*Disrupción que se enseña.* Un modelo predictivo responde "¿quién tiene peor outcome?" Un sistema causal responde "¿a quién *cambia* el outcome si actuamos?". Esa diferencia reordena presupuestos, targeting, go/no-go de programas y riesgo de políticas injustas. Cada bloque del curso cierra con la pregunta: *si solo predijéramos, ¿a quién trataríamos? Con el efecto, ¿cambia la decisión?*

*Balance 50/50.* La teoría (identificación y estimación) se ancla en monografía + Bareinboim. La práctica sigue el ciclo DMLS (datos, features, evaluación, despliegue, monitoreo) y se materializa en el *monorepo del curso*: labs de sesión (L01–L28), notebooks de caso (Serie A) y producción en Hugging Face (Serie B). Ningún módulo termina en un análisis de notebook aislado: termina en un *artefacto operable* (estimación auditada, API, model card, Space o dashboard).

*Navegación del libro.* La monografía tiene *32 capítulos*. En este sílabo, la columna *Lectura* usa la *numeración actual del PDF* (no la de ediciones cortas anteriores). Ante duda: #code[PLAN_INTEGRACION_MONOGRAFIA.md] (tabla maestra S ↔ Cap ↔ Lab ↔ A/B).

= 2. Filosofía pedagógica: DMLS + efecto causal

<sec-filosofia-dmls>

#cuadrosinoptico[
  - *Decisiones de diseño, no tutoriales de una receta.* Online vs batch, reentrenar vs alertar, biblioteca vs servicio — aplicados a *validez del efecto*.
  - *Proceso iterativo.* Identificar → estimar → servir en HF → monitorear supuestos → actualizar.
  - *Cuatro requisitos en producción (versión causal):* confiabilidad del efecto, escalabilidad del pipeline, mantenibilidad de la identificación, adaptabilidad ante drift de supuestos.
  - *Lado humano.* Comunicar ATE/CATE a no técnicos; model cards honestas; equidad y límites de validez externa.
]

= 3. Objetivos de aprendizaje

== 3.1 Objetivo general

Capacitar a profesionales para *formular, estimar y desplegar* sistemas de IA causal en producción —con énfasis en *casos de estudio* y *Hugging Face*— de modo que puedan sustituir (o auditar) priorizaciones puramente predictivas por decisiones basadas en *efectos* documentados y monitoreables.

== 3.2 Objetivos específicos

- Distinguir asociación, intervención y contrafactual (PCH) y reconocer cuándo *no* estimar.
- Diseñar pipelines de datos con roles tratamiento / outcome / covariables sin fuga causal.
- Estimar ATE y CATE (DML, meta-learners, bosques causales) con inferencia válida y evaluación offline (Qini, placebo).
- Convertir CATE en *política* bajo presupuesto y compararla con baselines no causales.
- Empaquetar en HF: FastAPI/Docker, Hub, model card causal, CI/CD, Space, dashboard de drift.
- Comunicar resultados a audiencias de negocio con supuestos y límites explícitos.

= 4. Perfil de ingreso

Dirigido a *profesionales* (y posgrado aplicado) en datos, ML, producto, analítica, riesgo u operaciones.

#checklist[
  - Python intermedio (pandas, scikit-learn); Git básico.
  - Estadística/econometría introductoria (regresión; deseable IV o evaluación de impacto).
  - Experiencia deseable con APIs o despliegue ligero (se cubre en el curso).
  - No se exige perfil de investigación ni demostraciones teóricas avanzadas (caps. electivos del libro son opcionales).
]

= 5. Unidades temáticas

Siete módulos · 16 semanas. Cada semana combina lectura de monografía (Cap. N del PDF) + lab de sesión (L\#\#) y, en hitos, entrega Serie A o B.

- *Módulo 0* — Causalidad elemental y arranque (Semana 1)
- *Módulo 1* — Fundamentos y datos para sistemas causales (Semanas 2–4) → *A1*
- *Módulo 2* — Estimación con ML y primer despliegue HF (Semanas 5–7) → *A2, B1*
- *Checkpoint 1* — Integración (Semana 8) → *A3*
- *Módulo 3* — Hub, model cards y CI/CD (Semana 9) → *B2*
- *Módulo 4* — Explicación, decisión, policy y uplift (Semanas 10–12) → *A4, B3*
- *Módulo 5* — Monitoreo, discovery y frontera (Semanas 13–14) → *B4*
- *Módulo 6* — Proyecto final en HF (Semanas 15–16)

*Capítulos electivos del PDF (no bloquean el camino profesional):* Cap. 16 (PDS extendido), 17 (panel/DML-IV), 18 (mapa metodológico), 27 (deep causal), 28 (SCM/matrix completion). Ver plan de integración.

= 6. Metodología y materiales del monorepo

Curso online asíncrono; dos sesiones semanales de 1 h 30. Formato orientativo: 20 min concepto · 50–60 min práctica (lab) · 10–20 min cierre. Los pipelines completos son entregas quincenales, no actividades de una sola sesión.

#table(
  columns: (1.2fr, 2.5fr, 2fr),
  align: left,
  stroke: 0.5pt + gray.lighten(70%),
  fill: (x, y) => if y == 0 { light } else { white },
  table.header([*Componente*], [*Ubicación en monorepo*], [*Rol*]),
  [Monografía PDF], [#code[02_monografia/…/monografia.pdf]], [Lectura Cap. 1–32],
  [Labs L01–L28], [#code[05_labs_sesion/]], [Práctica formativa por sesión (sin L16)],
  [Serie A (casos)], [#code[03_notebooks_caso_estudio/]], [4 entregas: identificación, DML, CATE, policy],
  [Serie B (HF)], [#code[04_notebooks_produccion_hf/]], [4 entregas: API, Hub/CI, Space, monitor],
  [Datos], [#code[data_benchmark_causal/…/datasets/]], [Jobs, IHDP, etc. (benchmark documentado)],
  [Proyecto], [#code[06_proyecto_final/]], [Sistema causal en HF (40%)],
  [Planes], [#code[PLAN_CURSO_COMPLETO.md] y #code[PLAN_INTEGRACION_MONOGRAFIA.md]], [Práctica + integración libro↔repo],
  [Cronograma semanal], [#code[CHRONOGRAMA_SEMANAL.md]], [Uso de materiales por rol (profesor / estudiante)],
)

*Serie A* se evalúa por corrección metodológica; *Serie B* por humo de producción (endpoint/Space responde, artefactos auditables) más buenas prácticas. El proyecto exige *comparar ranking predictivo vs política causal* y pasar humo en HF o equivalente local documentado.

= 7. Planificación clase a clase

*Convención.* *Lectura* = capítulo de la monografía (numeración del PDF 2026). *Lab* = carpeta `05_labs_sesion/` (prefijo L). *Entrega* = A1–A4 o B1–B4.

== Módulo 0 — Causalidad elemental y arranque (Semana 1)

#table(
  columns: (auto, 1.6fr, 1.3fr, 0.9fr, 1.4fr),
  align: left,
  stroke: 0.5pt + gray.lighten(70%),
  fill: (x, y) => if y == 0 { light } else { white },
  table.header([*S*], [*Tema*], [*Lectura monografía*], [*Lab*], [*Actividad / entrega*]),
  [S1], [Correlación ≠ causación; problema fundamental; escalera de Pearl (adelanto)], [Cap. *1* Causalidad elemental], [L01], [Casos espurios + Simpson; pregunta: ¿asociación o efecto?],
  [S2], [Anatomía de un sistema ML en producción; requisitos de un sistema *causal*], [Cap. *2* Anatomía del sistema], [L02], [Lab 0: entorno Python, Git, HF, monorepo],
)

== Módulo 1 — Fundamentos y datos (Semanas 2–4)

#table(
  columns: (auto, 1.6fr, 1.3fr, 0.9fr, 1.4fr),
  align: left,
  stroke: 0.5pt + gray.lighten(70%),
  fill: (x, y) => if y == 0 { light } else { white },
  table.header([*S*], [*Tema*], [*Lectura monografía*], [*Lab*], [*Actividad / entrega*]),
  [S3], [SCM y Jerarquía Causal de Pearl (ver / hacer / imaginar)], [Cap. *3* SCM y PCH], [L03], [Clasificar 10 preguntas en la PCH],
  [S4], [Ingeniería de datos: tratamiento, outcome, covariables, trazabilidad], [Cap. *4* Ingeniería de datos], [L04], [*Arranca A1* — roles T/Y/X (Jobs)],
  [S5], [Regularización y post-selección (PDS); Cap. 16 del PDF es profundización ◇], [Cap. *6* Regularización (+ Cap. *16* PDS ◇)], [L05], [PDS vs OLS vs diff-in-means],
  [S6], [Datos de entrenamiento, muestreo, etiquetas naturales], [Cap. *7* Datos de entrenamiento], [L06], [*Entrega A1* — identificación + PDS],
  [S7], [Operador do, puertas traseras, contrafactuales], [Cap. *8* Intervención y contrafactual], [L07], [Backdoor vs confusor latente (abstenerse)],
  [S8], [Features sin fuga causal], [Cap. *9* Features sin fuga], [L08], [*Arranca A2* — cazar leakage],
)

== Módulo 2 — Estimación causal y primer despliegue HF (Semanas 5–7)

#table(
  columns: (auto, 1.6fr, 1.3fr, 0.9fr, 1.4fr),
  align: left,
  stroke: 0.5pt + gray.lighten(70%),
  fill: (x, y) => if y == 0 { light } else { white },
  table.header([*S*], [*Tema*], [*Lectura monografía*], [*Lab*], [*Actividad / entrega*]),
  [S9], [Ortogonalidad de Neyman y cross-fitting], [Cap. *10* Ortogonalidad], [L09], [Residuales OOF; partialling-out],
  [S10], [Double Machine Learning: PLR e IRM], [Cap. *11* DML], [L10], [PLR mínimo; ATE con IC],
  [S11], [Evaluación offline: baselines, Qini, placebo], [Cap. *14* Validación], [L11], [*Entrega A2* — DML serializado → B1],
  [S12], [Despliegue del estimador como servicio (FastAPI + Docker)], [Cap. *15* Despliegue servicio], [L12], [*Arranca B1* — stub /predict],
  [S13], [Meta-learners S/T/X/R], [Cap. *12* Meta-learners], [L13], [*Arranca A3* — T-learner / CATE],
  [S14], [Árboles y bosques causales], [Cap. *13* Bosques causales], [L14], [*Entrega B1* + avance A3],
)

== Checkpoint 1 (Semana 8)

#table(
  columns: (auto, 1.6fr, 1.3fr, 0.9fr, 1.4fr),
  align: left,
  stroke: 0.5pt + gray.lighten(70%),
  fill: (x, y) => if y == 0 { light } else { white },
  table.header([*S*], [*Tema*], [*Lectura monografía*], [*Lab*], [*Actividad / entrega*]),
  [S15], [Integración: identificación + estimación + primer servicio], [Repaso Caps. 1–15], [L15], [*Entrega A3* — checklist de sistema],
  [S16], [Examen parcial y defensa de avance], [—], [—], [Evaluación parcial (camino profesional ★)],
)

== Módulo 3 — Publicación y CI/CD en Hugging Face (Semana 9)

#table(
  columns: (auto, 1.6fr, 1.3fr, 0.9fr, 1.4fr),
  align: left,
  stroke: 0.5pt + gray.lighten(70%),
  fill: (x, y) => if y == 0 { light } else { white },
  table.header([*S*], [*Tema*], [*Lectura monografía*], [*Lab*], [*Actividad / entrega*]),
  [S17], [HF Hub y model cards *causales* (supuestos, no solo accuracy)], [Cap. *19* Hub y model cards · Ap. G], [L17], [*Arranca B2*],
  [S18], [CI/CD: Actions, tests de humo, publicación condicionada], [Cap. *20* CI/CD], [L18], [*Entrega B2*],
)

== Módulo 4 — Explicación, decisión, policy y uplift (Semanas 10–12)

#table(
  columns: (auto, 1.6fr, 1.3fr, 0.9fr, 1.4fr),
  align: left,
  stroke: 0.5pt + gray.lighten(70%),
  fill: (x, y) => if y == 0 { light } else { white },
  table.header([*S*], [*Tema*], [*Lectura monografía*], [*Lab*], [*Actividad / entrega*]),
  [S19], [Explicación causal vs asociativa; equidad], [Cap. *23* Explicación y equidad], [L19], [Casos: SHAP ≠ efecto],
  [S20], [Interpretabilidad y fairness sobre estimadores causales], [Cap. *24* Ética e interpretabilidad], [L20], [Auditoría de importancia (asociativa) con advertencia],
  [S21], [Decisiones estructurales bajo incertidumbre], [Cap. *25* Decisiones estructurales], [L21], [Formalizar la decisión de negocio],
  [S22], [Policy learning y presupuesto], [Cap. *21* Policy learning], [L22], [*Arranca A4* — top-k B=20%],
  [S23], [Uplift y targeting; Space de política], [Cap. *22* Uplift], [L23], [*Entrega A4* · *Arranca B3* (Gradio/Space)],
  [S24], [Transportabilidad entre dominios], [Cap. *26* Generalización], [L24], [¿El efecto vale en *mi* mercado?],
)

== Módulo 5 — Monitoreo y frontera (Semanas 13–14)

#table(
  columns: (auto, 1.6fr, 1.3fr, 0.9fr, 1.4fr),
  align: left,
  stroke: 0.5pt + gray.lighten(70%),
  fill: (x, y) => if y == 0 { light } else { white },
  table.header([*S*], [*Tema*], [*Lectura monografía*], [*Lab*], [*Actividad / entrega*]),
  [S25], [Drift de covariables y estabilidad del efecto en producción], [Cap. *30* Monitoreo], [L25], [*Arranca B4* — métricas KS],
  [S26], [Descubrimiento de estructura (PC/NOTEARS; lab con esqueleto)], [Cap. *29* Discovery], [L26], [*Entrega B3* · avanza B4],
  [S27], [Continual learning; panorama RL causal], [Cap. *31* Aprendizaje continuo], [L27], [Reentrenar vs alertar],
  [S28], [Lado humano: comunicación y responsabilidad], [Cap. *32* Lado humano], [L28], [*Entrega B4* — comunicar ATE],
)

== Módulo 6 — Proyecto final (Semanas 15–16)

#table(
  columns: (auto, 1.6fr, 1.3fr, 0.9fr, 1.4fr),
  align: left,
  stroke: 0.5pt + gray.lighten(70%),
  fill: (x, y) => if y == 0 { light } else { white },
  table.header([*S*], [*Tema*], [*Lectura monografía*], [*Lab*], [*Actividad / entrega*]),
  [S29], [Trabajo autónomo + mentoría], [Ap. E, G, H · guía #code[06_proyecto_final/]], [P1], [Repo + identificación + baseline],
  [S30], [Peer review estructurado], [Rúbrica del curso], [P2], [Evaluar 2–3 proyectos (10%)],
  [S31], [Defensa del sistema causal en HF], [—], [P3], [*Entrega final 40%* + humo],
  [S32], [Cierre y frontera (CRL, RL causal — panorama)], [Caps. electivos 27–28 si aplica], [P4], [Encuesta; límites y trabajo futuro],
)

= 8. Evaluación

#table(
  columns: (2.2fr, 0.8fr, 4.2fr),
  align: left,
  stroke: 0.5pt + gray.lighten(70%),
  fill: (x, y) => if y == 0 { light } else { white },
  table.header([*Componente*], [*Peso*], [*Descripción*]),
  [Proyecto final], [40%], [Sistema causal en Hugging Face (identificación + estimación + model card + servicio/Space + monitoreo ligero). *Obligatorio:* comparación predictivo vs causal y prueba de humo. Ver #code[06_proyecto_final/].],
  [Serie A — casos de estudio], [20%], [A1 Jobs · A2 DML · A3 CATE · A4 policy. Metodología + autograder.],
  [Serie B — producción HF], [15%], [B1 API · B2 Hub/CI · B3 Space · B4 monitor. Humo + prácticas de despliegue.],
  [Revisión por pares], [10%], [2–3 proyectos con rúbrica.],
  [Quizzes], [10%], [7 quizzes cortos (camino profesional ★).],
  [Contribución al Hub], [5%], [Dataset o model card reutilizable por la cohorte.],
)

El proyecto *no se aprueba* si el sistema no pasa la prueba de humo (endpoint o Space responde; estimaciones en rango documentado).

*Labs Lxx:* formativos (badge/consistencia); no sustituyen el peso de A/B salvo política del instructor.

= 9. Herramientas y stack

#checklist[
  - Python 3.10+, pandas, NumPy, scikit-learn; monorepo #code[lib/] del curso.
  - EconML / DoubleML (recomendados; hay fallback sklearn en el monorepo).
  - Hugging Face Hub, Spaces, Gradio; FastAPI + Docker; GitHub Actions.
  - Datos: solo #code[data_benchmark_causal/causal_benchmark_synthetic/datasets/] en entregas del curso.
  - Auditoría local: #code[bash scripts/audit_repo.sh].
]

= 10. Bibliografía y referencias

== 10.1 Fuentes principales

- Curso ECO-490/ECON-540 (2026). _IA Causal en Producción_ — monografía Typst, *32 capítulos*. #code[02_monografia/monografia_IA_Causal_en_Produccion.pdf].
- Huyen, C. (2022). _Designing Machine Learning Systems_. O'Reilly. Filosofía pedagógica y ciclo de vida.
- Bareinboim, E. (2025). _Causal Artificial Intelligence_ (v0.27). Columbia CausalAI Lab.
- Planes del monorepo: #code[PLAN_CURSO_COMPLETO.md], #code[PLAN_INTEGRACION_MONOGRAFIA.md].

== 10.2 Metodología (selección)

- Chernozhukov et al. (2018). Double/debiased machine learning. _The Econometrics Journal_.
- Wager & Athey (2018). Estimation of heterogeneous treatment effects with random forests. _JASA_.
- Künzel et al. (2019). Metalearners for heterogeneous treatment effects. _PNAS_.
- Pearl, J. (2009). _Causality_ (2.ª ed.). Cambridge University Press.

== 10.3 Producción y documentación

- EconML, DoWhy, Hugging Face Hub docs.
- Kästner et al., _Machine Learning in Production_ (CMU), Cap. 10.
- Mitchell et al. (2019). Model Cards for Model Reporting. _FAT\*_.

= 11. Mapa rápido del hilo de producto (CDS)

#table(
  columns: (auto, 1.4fr, 1.2fr, 2fr),
  align: left,
  stroke: 0.5pt + gray.lighten(70%),
  fill: (x, y) => if y == 0 { light } else { white },
  table.header([*Paso*], [*Artefacto*], [*Sesiones*], [*Pregunta de valor*]),
  [1], [A1 Identificación (Jobs)], [S4–S6], [¿Es estimable el efecto del programa?],
  [2], [A2 DML (IHDP-medium)], [S8–S11], [¿Cuánto mueve en promedio (ATE + IC)?],
  [3], [B1 API + B2 Hub/CI], [S12–S18], [¿Se puede consultar, documentar y no publicar roto?],
  [4], [A3 CATE + A4 policy], [S13–S15, S22–S23], [¿A quién priorizar con 20% de capacidad?],
  [5], [B3 Space + B4 monitor], [S23–S28], [¿Un decisor lo usa? ¿Sigue valiendo el efecto?],
  [6], [Proyecto final HF], [S29–S32], [¿Tu caso de negocio en producción?],
)

= 12. Cronograma semana a semana (profesor y estudiante)

Cómo *usar* los materiales del monorepo cada semana. Detalle ampliado (checklists, rutas de apertura): #code[CHRONOGRAMA_SEMANAL.md] en la raíz del monorepo. La planificación sesión a sesión (S1–S32) está en la §7; aquí el *cómo* por rol.

== 12.1 Rutina semanal tipo

#table(
  columns: (0.9fr, 1.4fr, 1.6fr, 1.5fr),
  align: left,
  stroke: 0.5pt + gray.lighten(70%),
  fill: (x, y) => if y == 0 { light } else { white },
  table.header([*Quién*], [*Antes*], [*Durante (1 h 30)*], [*Después*]),
  [*Profesor*], [Revisar Cap. PDF + lab; 1 pregunta de valor de negocio], [20′ concepto · 50–60′ lab guiado · 10–20′ cierre (disrupción)], [Dudas del hilo CDS; no retrasar entregas A/B],
  [*Estudiante*], [Leer Cap. del PDF (núm. índice 32)], [Lab en vivo o asíncrono], [Completar lab + avanzar A/B del bloque],
)

*Cierre obligatorio (cada semana):* si solo predijéramos el outcome, ¿a quién trataríamos? Con el efecto, ¿cambia la decisión?

== 12.2 Uso de materiales por semana

#table(
  columns: (auto, 0.7fr, 0.9fr, 0.7fr, 1.8fr, 1.8fr),
  align: left,
  stroke: 0.5pt + gray.lighten(70%),
  fill: (x, y) => if y == 0 { light } else { white },
  table.header([*Sem*], [*Ses.*], [*Cap. / Lab*], [*Entrega*], [*Profesor usa*], [*Estudiante usa*]),
  [1], [S1–S2], [1–2 / L01–L02], [—], [Sílabo + monorepo; verificar L02 entorno], [PDF Caps. 1–2; labs L01–L02; cuenta HF],
  [2], [S3–S4], [3–4 / L03–L04], [A1 arranca], [PCH (L03); Jobs como caso; abrir A1 + #code[CausalSchema]], [L03–L04; A1 EDA/DAG; #code[real/jobs]],
  [3], [S5–S6], [6(+16◇)–7 / L05–L06], [*A1*], [Rúbrica A1; Cap. 16 solo si hay tiempo], [L05–L06; *entregar A1* (solo observed)],
  [4], [S7–S8], [8–9 / L07–L08], [A2 arranca], [Abstenerse si no hay ID; demo leakage; abrir A2], [L07–L08; A2 sin fugas; #code[ihdp_medium]],
  [5], [S9–S10], [10–11 / L09–L10], [A2 curso], [Cross-fitting + ortogonalidad; ATE→go/no-go], [L09–L10; A2 PLR + K-fold],
  [6], [S11–S12], [14–15 / L11–L12], [*A2* · B1], [Cerrar A2 (joblib); demo B1 /health /predict], [*A2* + sync; L11–L12; carpeta B1],
  [7], [S13–S14], [12–13 / L13–L14], [A3 · *B1*], [CATE ≠ riesgo predicho; autograder B1], [A3 T-learner; *B1*; L13–L14],
  [8], [S15–S16], [Repaso / — · L15], [*A3* · parcial], [Checklist A1–A3+B1; parcial solo ★], [*A3*; L15; estudiar ★ (no deep)],
  [9], [S17–S18], [19–20 / L17–L18], [*B2*], [Model card = supuestos; CI que falla humo], [L17–L18; *B2* card+Actions],
  [10], [S19–S20], [23–24 / L19–L20], [—], [SHAP de Ŷ ≠ efecto; preparar policy], [L19–L20; releer card B2],
  [11], [S21–S22], [25+21 / L21–L22], [A4 arranca], [Decisión de negocio antes de λ; B=20%], [L21–L22; A4 con scores A3],
  [12], [S23–S24], [22+26 / L23–L24], [*A4* · B3], [A4: causal vs random vs outcome; demo Space], [*A4*; L23–L24; B3 Gradio],
  [13], [S25–S26], [30+29 / L25–L26], [B4 · *B3*], [200 OK ≠ efecto válido; cerrar B3], [*B3*; L25–L26; B4],
  [14], [S27–S28], [31–32 / L27–L28], [*B4*], [Ops L27; comunicación 3 capas; brief proyecto], [L27–L28; *B4*; elegir caso P],
  [15], [S29–S30], [Ap. E/G/H · guía proyecto], [P1 · P2], [Mentoría ID+humo+disrupción; pares peer], [P1 repo; P2 rúbrica; HF],
  [16], [S31–S32], [— / elect. ◇], [*P3* · P4], [Humo + sección disrupción irrenunciables], [*P3* sistema HF + video; encuesta],
)

== 12.3 Calendario de entregas (vista rápida)

#table(
  columns: (auto, 1.2fr, 2.5fr),
  align: left,
  stroke: 0.5pt + gray.lighten(70%),
  fill: (x, y) => if y == 0 { light } else { white },
  table.header([*Semana*], [*Entrega*], [*Notas*]),
  [3], [*A1*], [Identificación Jobs (Serie A 20%)],
  [6], [*A2*], [DML → artefacto B1],
  [7], [*B1*], [API + Docker (Serie B 15%)],
  [8], [*A3* · parcial], [CATE → A4; parcial camino ★],
  [9], [*B2*], [Model card + CI HF],
  [12], [*A4*], [Policy B=20% → B3],
  [13], [*B3*], [Space Gradio],
  [14], [*B4*], [Monitor drift/supuestos],
  [15], [P1 · P2], [Baseline + peer review 10%],
  [16], [*P3* (+ P4)], [Proyecto final 40% + humo],
)

== 12.4 Checklist semanal (plantilla)

*Estudiante:* (1) Cap. N del PDF; (2) lab.ipynb / checks en verde; (3) avance A/B del bloque; (4) tres líneas predictivo vs efecto; (5) no usar columnas de verdad (`truth\_*`) fuera de evaluación.

*Profesor:* (1) Cap. + lab + ejemplo de negocio de la cohorte; (2) numeración PDF (no Typst antiguo); (3) cierre con disrupción; (4) office hours si bloqueo A/B; (5) electivos ◇ no entran al parcial ★.

== 12.5 Primera apertura por rol

*Estudiante:* #code[01_silabo/silabo.pdf] → #code[CHRONOGRAMA_SEMANAL.md] (semana actual) → Cap. monografía → #code[05_labs_sesion/Lxx/lab.ipynb] → notebook A o carpeta B si hay entrega.

*Profesor:* #code[docs/NOTA_INSTRUCTORS.md] → sílabo + cronograma → #code[bash scripts/audit_repo.sh] → demo 10′ (L01 + promesa del curso).

]

