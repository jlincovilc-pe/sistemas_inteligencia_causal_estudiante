# Plan de sprint — Diapositivas de *IA Causal en Producción*

Plan de contenido, capítulo a capítulo, para los 32 mazos de diapositivas del curso
(ECO-490/ECON-540). Este documento es el artefacto de planificación; la implementación
Typst vive en `07_diapositivas/capitulos/capNN_slug.typ` (stubs ya creados, ver §0) y se
construye sobre `07_diapositivas/plantilla_monografia.typ`.

**Cómo usar este documento en el sprint:** cada entrada de capítulo trae (a) metadata de
sesión/lab/entrega tomada de la tabla maestra del sílabo, (b) objetivos y agenda ya
transcritos a los stubs, y (c) un bloque **"Puntero de contenido fuente"** que es el
trabajo real de la próxima sesión: abrir el `.typ` de la monografía en la ruta indicada,
tomar la definición/teorema/listing/tabla de riesgos/ejercicio señalado, y convertirlo a
la slide correspondiente reemplazando el `// TODO(sprint): ...` del stub.

> **La monografía recibió una Etapa 2 de mejoras (C1–C11) después de que se escribió
> este plan.** Antes de trabajar cualquier capítulo, revisar el **§5 "Plan de
> actualización — Etapa 2"** — 11 de los 32 capítulos tienen contenido nuevo que el
> §3 todavía no refleja (Caps. 10, 11, 12, 14, 15, 17, 19, 20, 21, 27, 30). El §3 sigue
> siendo válido como esqueleto; el §5 son los *deltas* a aplicar sobre él.

---

## 0. Convenciones

- **Numeración de capítulo:** la del PDF de la monografía (1–32), no el nombre de archivo
  histórico (`cap00_…`, `cap02b_…`). La tabla del §1 mapea ambas.
- **★ camino crítico / ◇ profundización electiva:** igual que
  `PLAN_INTEGRACION_MONOGRAFIA.md` §3. Los capítulos ◇ (5, 16, 17, 18, 27, 28) no tienen
  sesión `S#` dedicada — se leen como refuerzo u oficina de proyecto. Sus mazos son más
  cortos (10–12 slides: portada, roadmap, motivación, 1–2 slides de contenido, cierre) y
  se marcan explícitamente "sin sesión" en el roadmap.
- **Variante A / B:** las dos plantillas que ya usa la monografía misma.
  - **A (teoría e identificación):** capítulos con `#cuadrosinoptico[...]` en el libro —
    llevan definición formal, supuestos, teorema y (cuando el libro trae una) demostración
    o esquema de demostración.
  - **B (ingeniería y producción):** capítulos con `#cuadrodecision[...]` — llevan
    problema de diseño, opciones y trade-offs, decisión de referencia, checklist de
    señales de alerta en vez de teorema/demostración.
  - **Cap. 31 es híbrida (A/B):** la Parte I (aprendizaje continuo) es variante B: la
    Parte II (panorama RL causal) es variante A ligera (sin teorema formal, el propio
    libro lo declara panorama conceptual).
- **Duración:** las sesiones son de 90 min y comparten tiempo con el lab (`05_labs_sesion/L##`)
  y, en varias sesiones, con la entrega Serie A/B. Un mazo ★ típico apunta a
  **20–25 min de exposición** (16–20 slides a ritmo de 1–1.5 min/slide, con la slide
  interactiva y la de discusión consumiendo más tiempo real); el resto de la sesión es
  lab guiado. Los mazos ◇ apuntan a 8–10 min si se usan en vivo, o se dejan como lectura.
- **Paleta y mapeo PCH:** ver cabecera de `plantilla_monografia.typ`. La pregunta activa
  fija de cada capítulo ("si solo predijéramos, ¿cambia la decisión con el efecto
  estimado?") viene de `01_silabo/silabo.typ` §2 y se reutiliza tal cual salvo que se
  indique una variante específica.

---

## 1. Tabla maestra (sesión ↔ capítulo ↔ archivo ↔ variante)

| # | Título | Archivo monografía | Slide (`07_diapositivas/capitulos/`) | Parte | Sesión | Lab | Entrega | Var. | ★/◇ |
|--:|---|---|---|:-:|:-:|:-:|---|:-:|:-:|
| 1 | Causalidad elemental | `cap00_causalidad_elemental` | `cap01_causalidad_elemental.typ` | 0 | S1 | L01 | — | A | ★ |
| 2 | Anatomía del sistema | `cap00b_anatomia_sistema` | `cap02_anatomia_sistema.typ` | 0 | S2 | L02 | Lab 0 | B | ★ |
| 3 | SCM y PCH | `cap00c_scm_pch` | `cap03_scm_pch.typ` | I | S3 | L03 | — | A | ★ |
| 4 | Ingeniería de datos | `cap00d_ingenieria_datos` | `cap04_ingenieria_datos.typ` | I | S4 | L04 | A1 arranca | B | ★ |
| 5 | Predicción y causalidad | `cap01_prediccion_causalidad` | `cap05_prediccion_causalidad.typ` | I | refuerzo de S1 | — | — | A | ◇ |
| 6 | Regularización y post-selección | `cap02_regularizacion_postseleccion` | `cap06_regularizacion_postseleccion.typ` | I | S5 | L05 | A1 | A | ★ |
| 7 | Datos de entrenamiento | `cap02b_datos_entrenamiento` | `cap07_datos_entrenamiento.typ` | I | S6 | L06 | A1 entrega | B | ★ |
| 8 | Intervención y contrafactual | `cap02c_intervencion_contrafactual` | `cap08_intervencion_contrafactual.typ` | I | S7 | L07 | — | A | ★ |
| 9 | Features sin fuga | `cap02d_features_sin_fuga` | `cap09_features_sin_fuga.typ` | I | S8 | L08 | A2 arranca | B | ★ |
| 10 | Ortogonalidad y cross-fitting | `cap03_ortogonalidad_crossfitting` | `cap10_ortogonalidad_crossfitting.typ` | II | S9 | L09 | A2 | A | ★ |
| 11 | DML | `cap04_dml` | `cap11_dml.typ` | II | S10 | L10 | A2 | A | ★ |
| 12 | Meta-learners | `cap05_metalearners` | `cap12_metalearners.typ` | II | S13 | L13 | A3 arranca | A | ★ |
| 13 | Árboles y bosques causales | `cap06_arboles_bosques` | `cap13_arboles_bosques.typ` | II | S14 | L14 | B1 entrega | A | ★ |
| 14 | Validación | `cap07_validacion` | `cap14_validacion.typ` | II | S11 | L11 | A2 entrega | A | ★ |
| 15 | Despliegue como servicio | `cap07b_despliegue_servicio` | `cap15_despliegue_servicio.typ` | II | S12 | L12 | B1 arranca | B | ★ |
| 16 | Post-Double-Selection | `cap08_pds` | `cap16_pds.typ` | III | ampliación de S5 | — | — | A | ◇ |
| 17 | Panel y DML-IV | `cap09_panel_dmliv` | `cap17_panel_dmliv.typ` | III | electivo | — | — | A | ◇ |
| 18 | Mapa de decisión | `cap10_mapa_decision` | `cap18_mapa_decision.typ` | III | guía de proyecto | — | — | A | ◇ |
| 19 | Hub y model cards | `cap10b_hf_hub` | `cap19_hf_hub.typ` | IV | S17 | L17 | B2 arranca | B | ★ |
| 20 | CI/CD causal | `cap10c_cicd` | `cap20_cicd.typ` | IV | S18 | L18 | B2 entrega | B | ★ |
| 21 | Policy learning | `cap11_policy_learning` | `cap21_policy_learning.typ` | V | S22 | L22 | A4 arranca | A | ★ |
| 22 | Uplift y targeting | `cap12_uplift_targeting` | `cap22_uplift_targeting.typ` | V | S23 | L23 | A4 + B3 | A | ★ |
| 23 | Explicación y equidad | `cap12b_explicacion_equidad` | `cap23_explicacion_equidad.typ` | VI | S19 | L19 | — | A | ★ |
| 24 | Ética e interpretabilidad | `cap16_etica_interpretabilidad` | `cap24_etica_interpretabilidad.typ` | VI | S20 | L20 | — | A | ★ |
| 25 | Decisiones estructurales | `cap12c_decisiones_estructurales` | `cap25_decisiones_estructurales.typ` | VI | S21 | L21 | — | A | ★ |
| 26 | Generalización | `cap12d_generalizacion` | `cap26_generalizacion.typ` | VI | S24 | L24 | — | A | ★ |
| 27 | Deep causal | `cap13_deep_causal` | `cap27_deep_causal.typ` | VII | electivo | — | — | A | ◇ |
| 28 | SCM / matrix completion | `cap14_scm_matrix_completion` | `cap28_scm_matrix_completion.typ` | VII | electivo | — | — | A | ◇ |
| 29 | Descubrimiento de grafos | `cap15_descubrimiento_grafos` | `cap29_descubrimiento_grafos.typ` | VIII | S26 | L26 | B3 cierre | A | ★ |
| 30 | Monitoreo en producción | `cap15b_monitoreo` | `cap30_monitoreo.typ` | VIII | S25 | L25 | B4 arranca | B | ★ |
| 31 | Aprendizaje continuo / RL | `cap15c_aprendizaje_continuo` | `cap31_aprendizaje_continuo.typ` | VIII | S27 | L27 | B4 | A/B | ★ |
| 32 | Lado humano | `cap15d_lado_humano` | `cap32_lado_humano.typ` | VIII | S28 | L28 | B4 entrega | B | ★ |

**Nota de orden.** El orden de *enseñanza* (columna Sesión) no es estrictamente el orden
del libro entre S9–S14: el sílabo enseña DML (Cap. 11, S10) → Validación (Cap. 14, S11) →
Despliegue (Cap. 15, S12) → Meta-learners (Cap. 12, S13) → Bosques (Cap. 13, S14), para
que A2 se valide y despliegue como B1 *antes* de abrir la heterogeneidad de CATE. Los
archivos de diapositivas se numeran por capítulo de libro (trazabilidad 1:1 con la
monografía); quien arme el temario del curso debe recorrerlos en orden de **Sesión**, no
de nombre de archivo.

---

## 2. Esqueletos estándar

Para no repetir la secuencia completa en cada capítulo, el plan de cada uno solo lista
**desvíos** respecto de estos dos esqueletos. Los stubs de `capitulos/` ya siguen el
esqueleto correspondiente a su variante.

### Esqueleto Variante A — teoría e identificación (≈18 slides)
1. `cap-progreso-curso` 2. `cap-portada` 3. `cap-roadmap` 4. `cap-motivacion`
5. `cap-glosario` 6. `cap-definicion` 7. `cap-supuestos` 8. `cap-teorema`
9. `cap-demostracion` 10. `cap-interactivo` 11–12. `cap-codigo-parte` ×2
13. `cap-caso-resolucion` 14. `cap-validacion` 15. `cap-mapeo-pch-activo`
16. `cap-errores-transiciones` 17. `cap-discusion-ejercicio` 18. `cap-cierre-narrativo`

### Esqueleto Variante B — ingeniería y producción (≈15 slides)
1. `cap-progreso-curso` 2. `cap-portada` 3. `cap-roadmap` 4. `cap-problema-diseno`
5. `cap-opciones-tradeoffs` 6. `cap-decision-referencia` 7–8. `cap-codigo-parte` ×2
9. `cap-monorepo` (solo si el capítulo trae `#monorepo[]` en el libro — Caps. 4, 9, 15,
19, 20, 30; si no, se omite) 10. `cap-caso-resolucion` ("aplicación al sistema del
curso") 11. `cap-mapeo-pch-activo` 12. `cap-checklist-alertas` 13. `cap-interactivo`
14. `cap-discusion-ejercicio` 15. `cap-cierre-narrativo`

Capítulos ◇ (electivos, sin sesión): esqueleto reducido a `cap-portada` → `cap-roadmap`
→ `cap-motivacion`/`cap-problema-diseno` → 1 slide de contenido central (la idea que
justifica leerlo) → `cap-cierre-narrativo`. No llevan `cap-progreso-curso` propio (se
mencionan como recuadro "◇" dentro del capítulo ★ que los referencia).

---

## 3. Plan capítulo a capítulo

### Parte 0 — Introducción

#### Cap. 1 — Causalidad elemental y el problema fundamental de la inferencia causal
`cap00_causalidad_elemental.typ` · S1 · L01 · sin entrega · **Variante A (ligera)** · ★

**Objetivos:** (1) distinguir una pregunta asociativa de una causal en un caso aplicado;
(2) enunciar el problema fundamental de la inferencia causal (Holland 1986) y su
consecuencia sobre el efecto individual; (3) ubicar una pregunta en el nivel correcto de
la escalera de Pearl.

**Desvíos del esqueleto A:** capítulo "ligero", sin `#supuestos`/`#theorem` formales en
el libro. Omitir `cap-supuestos`. Usar `cap-definicion` para el problema fundamental y
`cap-teorema` (títulalo "Resultado") para la descomposición Δ = ATT + sesgo de selección
que el capítulo desarrolla en prosa. Omitir la 2.ª `cap-codigo-parte` (el capítulo no
trae listados de código, es puramente conceptual). Añadir una slide extra tipo
`cap-glosario` con las tres escenas (cigüeñas / tamaño del pie / paradoja de Simpson) en
vez de una sola definición de términos.

**Contenido fuente:**
- Motivación: becas y calificaciones (líneas 27–31); gancho: "¿asociación o efecto?".
- Definición: problema fundamental de la inferencia causal, `@holland1986` (línea 53).
- Resultado (ex-teorema): Δ = ATT + sesgo de selección, `@sec-introcausal-problema-fundamental`.
- Ejemplo: paradoja de Simpson, `@simpson1951`/`@yule1903` (línea 43).
- Interactivo: clasificar 3 preguntas del ejercicio 1 (línea 88) en vivo con la clase.
- Discusión/ejercicio: ejercicio 4 (línea 89) — gradient boosting con R²=0.95 y la
  promoción "explica el 95% de las ventas".
- Sin caso empírico/validación/riesgos en este capítulo — comprimir esas 3 slides del
  esqueleto en una sola de cierre reforzando "ningún dato por sí solo resuelve esto".

**Transición** → Cap. 2: "la pregunta causal está clara; ahora, ¿dónde vive en un sistema
que hay que operar?"

#### Cap. 2 — Anatomía de un sistema de ML en producción
`cap00b_anatomia_sistema.typ` · S2 · L02 · **Lab 0** · **Variante B** · ★

**Objetivos:** (1) enumerar los componentes de un sistema de ML más allá del algoritmo
(Huyen 2022); (2) explicar por qué "reentrenar" es más delicado en un sistema causal que
en uno predictivo; (3) dejar el esqueleto de repositorio del curso funcionando
localmente (Lab 0).

**Desvíos:** sin `cap-monorepo` (el esqueleto de repo se presenta en
`cap-decision-referencia`, no hay callout `#monorepo[]` en este capítulo). Añadir una
slide de código mostrando el árbol de directorios del esqueleto (línea 72–86) en vez de
un listado Python.

**Contenido fuente:**
- Problema de diseño: modelo entrenado ≠ sistema en producción (líneas 26–28).
- Opciones: *model-centric* vs. *system-centric* (DMLS) + proceso lineal vs. iterativo
  (tabla línea 41–49).
- Decisión de referencia: los 4 requisitos DMLS reinterpretados en versión causal
  (confiabilidad/escalabilidad/mantenibilidad/adaptabilidad, líneas 58–63).
- Código/implementación: árbol del esqueleto de repositorio (línea 72–86) — usar como
  "código" aunque no sea Python ejecutable.
- Caso ("aplicación al sistema del curso"): qué cambia cuando el modelo estima un efecto
  en vez de predecir (líneas 93).
- Checklist de alertas: 5 ítems de la sección "Señales de alerta" (líneas 98–104).
- Ejercicio: ejercicio de infraestructura — completar Lab 0 y entregar captura de
  `docker run hello-world` (línea 123).

**Transición** → Cap. 3: "con el sistema listo, falta el lenguaje formal para razonar
sobre el efecto que ese sistema va a operar."

---

### Parte I — Fundamentos estructurales y de datos

#### Cap. 3 — Modelos Causales Estructurales y la Jerarquía Causal de Pearl
`cap00c_scm_pch.typ` · S3 · L03 · sin entrega · **Variante A** · ★

**Objetivos:** (1) escribir la definición formal de un SCM; (2) distinguir los tres
niveles de la PCH y qué información mínima requiere cada uno; (3) enunciar el Teorema de
la Jerarquía Causal y explicar por qué es la razón *formal* (no solo intuitiva) de la
tesis del Cap. 1.

**Contenido fuente:**
- Definición: SCM, `@def:SCM` (tupla ⟨U,V,F,P(u)⟩, línea 38).
- Supuestos/tabla: los tres niveles de la PCH y qué se necesita para calcular cada uno
  (tabla línea 51–59, $cal(L)_1/cal(L)_2/cal(L)_3$).
- Teorema: Jerarquía Causal (`@thm-cht`, línea 71) — medida cero, dos consecuencias
  operativas (línea 73–75 del cuerpo reescrito).
- Demostración/esquema: no hay demostración completa en el libro (se remite a
  `@bareinboim2022pch`); usar `cap-demostracion` con los 2 pasos informales: (1) definir
  la medida sobre el espacio de SCM, (2) el conjunto de SCM colapsables tiene medida cero.
- Código: listado `@lst-scm-do-simulacion` (línea 119) — simulación de becas con
  confusor U, P(y|D=1) vs. P(y|do(D=1)).
- Caso: verificación de consistencia del grafo con `close_college` (Card 1995), test de
  independencia `nearc4 ⊥ wage | educ` (línea 123).
- Interactivo: "¿este filtro `df[df.D==1]` es una observación o una intervención?"
- Riesgos: los 3 de la sección "Riesgos, límites y sensibilidad" (línea 128) — confundir
  P(y|x) con P(y|do(x)) es el primero y el más frecuente.
- Ejercicio: ejercicio computacional 1 (línea 149) — modificar el listado para efecto
  causal verdadero = 0 y verificar que la asociación no converge a 0 pero la intervención sí.

**Transición** → Cap. 4: "el SCM formaliza qué es una variable causal; el siguiente
capítulo formaliza qué rol juega cada *columna* de un dataset real."

#### Cap. 4 — Ingeniería de datos para sistemas causales
`cap00d_ingenieria_datos.typ` · S4 · L04 · **A1 arranca** · **Variante B** · ★

**Objetivos:** (1) declarar un `CausalSchema` con roles tratamiento/resultado/covariables/
instrumentos; (2) explicar por qué un rol causal no es una afirmación sobre tipo de dato
sino sobre identificación; (3) completar el arranque del Notebook A1.

**Contenido fuente:**
- Problema de diseño: ¿qué rol estructural juega cada columna? (líneas 27–32).
- Opciones: tabla ancha sin metadatos vs. esquema con roles etiquetados (línea 37–39).
- Decisión de referencia: `CausalSchema` con 4 listas (`treatment`/`outcome`/
  `covariates`/`instruments`) — Parquet preferido, CSV+`metadata.json` aceptado si el
  esquema viaja con los datos (línea 47, ampliado).
- Código: listado `@lst-causal-schema` (línea 55–94) — clase `CausalSchema` con
  `.validate()`, `.X()`, `.D()`, `.Y()`.
- Monorepo: callout `#monorepo[]` (línea 23) — `data_benchmark_causal/.../datasets/`,
  CSV+`metadata.json`, `lib.data_io.load_scenario`, Labs L04–L06, Notebook A1.
- Caso: A1 exige construir el `CausalSchema` *antes* de estimar; el mismo esquema
  reaparece sin cambios en B1 (Cap. 15) — buen gancho para mostrar la reutilización.
- Checklist: 4 ítems de "Señales de alerta" (línea 107).
- Ejercicio: ejercicio de infraestructura — extender `CausalSchema` con `.summary()`
  (línea 127).

**Transición** → Cap. 6 (S5; el Cap. 5 es lectura de refuerzo, no sesión propia): "el
esquema dice qué es cada columna; falta decidir cuáles de las covariables entran al
modelo sin sesgar la inferencia."

#### Cap. 5 — Predicción y causalidad: por qué el ML no es causal por defecto
`cap01_prediccion_causalidad.typ` · refuerzo tras S1 (sin sesión propia) · **Variante A** · ◇

**Uso recomendado:** lectura de refuerzo tras S1; solapa con el Cap. 1. En cohortes con
poca base econométrica, usar como repaso de 8–10 min antes de S5 (regularización).

**Objetivos:** (1) diferenciar formalmente régimen predictivo vs. régimen causal (tabla
Predicción/Causalidad); (2) reconocer cuándo una pregunta de política es genuinamente
predictiva y no causal (Kleinberg et al. 2015).

**Esqueleto reducido (◇):**
1. `cap-portada` 2. `cap-roadmap` 3. `cap-motivacion` (transferencias condicionadas,
líneas 33–37) 4. `cap-definicion` (tabla predicción vs. causalidad, `@tab-pred-causal`,
línea 41–61) 5. contenido central: el criterio de Kleinberg et al. — "si la decisión
cambia la variable sobre la que se razona, la pregunta es causal; si no, es predictiva"
(línea añadida en la mejora de contenido) 6. `cap-cierre-narrativo`.

**Contenido fuente:**
- Teorema/resultado citable: sesgo de regularización en T-learner, `@thm-reg-bias`
  (línea 125) — mencionar sin demostrar.
- Caso: Card (1995), OLS vs. bosque aleatorio, coeficientes 0.07 vs. 0.04 (línea 192).
- Ejemplo de collider: listado `@lst-collider-simulation` (línea 228) — útil como slide
  de código si se usa la versión completa del capítulo.

**Transición** → (vuelve al camino ★) Cap. 6: "vale para régimen causal en baja
dimensión; con 80+ covariables candidatas, ¿cómo seleccionar sin sesgar la inferencia?"

#### Cap. 6 — Regularización, selección de variables y sesgo post-selección
`cap02_regularizacion_postseleccion.typ` · S5 (+ Cap. 16 ◇ como ampliación) · L05 · **A1** · **Variante A** · ★

**Objetivos:** (1) enunciar LASSO/Ridge/Elastic Net y la diferencia de qué garantiza
cada uno; (2) distinguir la tasa de convergencia ℓ₂ (restricted eigenvalue) de la
consistencia de *selección* (irrepresentabilidad) — y por qué la segunda casi nunca se
puede verificar; (3) explicar por qué Post-Double-Selection no necesita que LASSO acierte
el soporte exacto.

**Contenido fuente:**
- Definiciones: LASSO/Ridge/Elastic Net, `@def-lasso` `@def-ridge` `@def-elasticnet`
  (líneas 57–77).
- Supuesto: sparsity aproximada, `@asu-sparsity` (línea 48).
- Teorema 1: tasa de convergencia del LASSO, `@thm-lasso-rate` (línea 87) —
  *restricted eigenvalue*, condición débil, solo da la tasa ℓ₂.
- Teorema 2 (el que faltaba en la edición anterior): irrepresentabilidad y consistencia
  de *selección*, `@asu-irrepresentable` + `@thm-irrepresentable` (líneas 101–110) — usar
  esta pareja como el "Teorema central" de la slide 8, es el punto pedagógico fuerte del
  capítulo.
- Demostración/esquema: no hay prueba completa; usar como "pasos" la intuición de Leeb &
  Pötscher (línea 104, caja `#intuicion`).
- Código: listado `@lst-post-selection-bias` (línea 167) — Monte Carlo de sesgo
  post-selección, sesgo ≈ −0.05 a −0.10, cobertura ≈ 0.85–0.90.
- Caso: réplica propia sobre `close_college` y `nhefs` (línea 289 y 268 respectivamente).
- Riesgos: tabla de riesgos (línea 301) — inferir después de seleccionar → PDS/DML.
- Interactivo: "¿por qué el LASSO puede tener buena tasa ℓ₂ y aun así seleccionar mal?"
- Ejercicio: ejercicio 1 (variar p en {20,50,100,200} y verificar sesgo/cobertura).

**Transición** → Cap. 7: "seleccionar controles no basta si no sabemos si los datos con
los que se seleccionó fueron, siquiera, comparables entre tratados y controles."

#### Cap. 7 — Datos de entrenamiento en sistemas causales
`cap02b_datos_entrenamiento.typ` · S6 · L06 · **A1 entrega** · **Variante B** · ★

**Objetivos:** (1) documentar el mecanismo de asignación de un dataset en una ficha de
procedencia; (2) ejecutar un chequeo de balance con SMD y criterio de Rubin (no
t-tests); (3) distinguir un desbalance esperado de una señal de que el mecanismo de
asignación real difiere del documentado.

**Contenido fuente:**
- Problema de diseño: auditar el mecanismo de asignación antes de estimar (líneas 26–33).
- Decisión de referencia: ficha de procedencia del tratamiento (línea 41).
- Código: listado `@lst-chequeo-balance` (reescrito en la mejora de contenido) — SMD,
  razón de varianzas, corrección de Holm, faltantes diferenciales.
- Caso: Lalonde/NSW — submuestra experimental (balanceada) vs. extensión observacional
  de Dehejia–Wahba (desbalanceada), mismo tratamiento y resultado (línea 84 ampliada).
- Checklist: 4 ítems de "Señales de alerta" (línea 89).
- Interactivo: "¿un desbalance en una covariable *administrativa* sin relación con la
  elegibilidad es más o menos grave que uno en una covariable relacionada?"
- Ejercicio: ejercicio computacional — aplicar el chequeo a ambas versiones de Lalonde y
  comparar distribuciones de SMD (línea 109, ampliado).

**Transición** → Cap. 8: "con datos auditados, falta el criterio formal para decidir qué
controlar y qué no — el error de "controlar por todo" es más costoso que omitir un
confusor."

#### Cap. 8 — Razonamiento intervencional y contrafactual
`cap02c_intervencion_contrafactual.typ` · S7 · L07 · sin entrega · **Variante A** · ★

**Objetivos:** (1) aplicar el criterio de puerta trasera para validar un conjunto de
control; (2) enunciar las tres reglas del cálculo-*do* y explicar su completitud;
(3) ejecutar el procedimiento de abducción-acción-predicción sobre un ejemplo numérico.

**Contenido fuente:**
- Definición: criterio de puerta trasera, `@def-backdoor` (línea 36).
- Teorema 1: fórmula de ajuste de puerta trasera (línea 40), con esquema de prueba
  (línea 45).
- Tabla de supuestos: buenos y malos controles — confusor/mediador/collider/instrumento/
  post-tratamiento (línea 56–66).
- Teorema 2 (contenido nuevo, el más importante de este capítulo): las tres reglas del
  cálculo-*do*, `@thm-do-calculus` (sección `@sec-intervcontra-docalculus`, línea 70–99)
  — completitud, derivación de puerta trasera como corolario, puerta delantera como
  caso donde la puerta trasera falla (línea 101).
- Demostración: derivar la fórmula de puerta trasera a partir de las 3 reglas — usar el
  ejercicio teórico 2 (línea 187) como guion de la slide de demostración.
- Código: listado `@lst-backdoor-check` (línea 87) — verificación con `networkx`.
- Caso: `test_score` como mediador parcial en el dataset de Card (línea 161).
- Interactivo: collider — retomar tamaño del pie/lectura del Cap. 1 con un collider
  explícito (ejercicio teórico 2 de la lista original, línea 142).
- Riesgos: 3 de "Riesgos, límites y sensibilidad" (línea 166) — "más controles siempre
  es más seguro" es falso.
- Ejercicio: ejercicio computacional — reproducir con `dowhy.identify_effect()` (línea 149).

**Transición** → Cap. 9: "puerta trasera dice qué controlar en el grafo; falta la
versión operacional en el pipeline de *features* real, donde el grafo no viene etiquetado."

#### Cap. 9 — Ingeniería de *features* sin fuga causal
`cap02d_features_sin_fuga.typ` · S8 · L08 · **A2 arranca** · **Variante B** · ★

**Objetivos:** (1) auditar una *feature* candidata por su rol causal, no solo por su
poder predictivo; (2) construir las dos especificaciones $X_"base"$/$X_"ampliada"$ para
variables de rol ambiguo; (3) detectar fuga temporal con marca de tiempo.

**Contenido fuente:**
- Problema de diseño: una *feature* puede mejorar la predicción y sesgar el efecto
  (líneas 27–30).
- Decisión de referencia: auditoría obligatoria antes de construir X; dos
  especificaciones $X_"base"$/$X_"ampliada"$ (línea 40, reescrito en la mejora).
- Código: listado `@lst-auditoria-features` (línea 51, reescrito) — `auditar_features`
  con `ROLES_PROHIBIDOS`, `incluir_en_X_base`/`incluir_en_X_ampliada`, y helper
  `columnas_X`.
- Monorepo: callout `#monorepo[]` (línea 23) — Lab L08 con fugas deliberadas, escenario
  `ihdp_medium`, no usar `y0`/`y1`/`tau` fuera de evaluación.
- Caso: Notebook A2 exige correr la auditoría antes de estimar PLR/IRM (Cap. 11).
- Checklist: 4 ítems (línea 88).
- Interactivo: "¿por qué un 'promedio móvil del resultado en las últimas 4 semanas' es
  casi siempre fuga en un sistema causal aunque sea una *feature* razonable en uno
  predictivo?" (ejercicio conceptual 2, línea 103).
- Ejercicio: comparar $X_"base"$ vs. $X_"ampliada"$ y decidir qué hacer si los IC no se
  solapan (ejercicio 2 nuevo de la mejora de contenido).

**Transición** → Cap. 10 (Parte II): "con datos, controles y features auditados, llega
la pregunta puramente estadística que estructura toda la Parte II: ¿cómo usar ML
flexible sin que su propio sesgo contamine la inferencia?"


---

### Parte II — Estimación causal flexible y primer despliegue

#### Cap. 10 — Ortogonalidad de Neyman, cross-fitting e influence functions
`cap03_ortogonalidad_crossfitting.typ` · S9 · L09 · A2 · **Variante A** · ★

**Objetivos:** (1) explicar el "doble sesgo" de los enfoques naïve; (2) enunciar la
condición de ortogonalidad de Neyman y por qué reduce el error de los *nuisance* a
segundo orden; (3) describir qué hace el cross-fitting que la ortogonalidad sola no hace.

**Contenido fuente:**
- Definición: score ortogonal de Neyman, `@def-neyman-orth` (línea 83).
- Supuestos: modelo PLR (línea 44) — $E[epsilon|D,X]=0$, $E[v|X]=0$.
- Teorema central: `@thm-plr-orth` (ortogonalidad del score PLR, línea 139) y
  `@thm-dml-main` (teorema central de DML, línea 157) — este último es "el mejor
  capítulo teórico" según la auditoría; dedicarle la slide de teorema principal.
- Demostración: usar el esquema nuevo de 3 pasos (a) término i.i.d., (b) proceso
  empírico neutralizado por cross-fitting, (c) sesgo de 2.º orden neutralizado por
  ortogonalidad — es la corrección más importante de la mejora de contenido en este
  capítulo, dedicarle 3–4 "pasos" en `cap-demostracion`.
- Código: listado `@lst-dml-manual` (línea 254) — `dml_plr_manual` con Monte Carlo.
- Caso: NSW Lalonde, ATE ≈ \$1,600, IC [\$800, \$2,400] (línea 348).
- Interactivo: "¿por qué el score $(D-m)(Y-l-theta(D-m))$ y no $(D-m)(Y-g-theta D)$ si
  se estimó $l_0(X)=E[Y|X]$?" (la distinción Robinson vs. forma estructural, línea 107).
- Riesgos: tabla `@tab-riesgos-dml` (línea 353) — omitir cross-fitting, un solo fold,
  score incorrecto para $l_0$.
- Ejercicio: ejercicio 1 (línea 377) — comparar DML con y sin cross-fitting.

**Transición** → Cap. 11: "el score ortogonal y el cross-fitting son el motor; ahora se
monta en los dos modelos que se usan en la práctica — PLR e IRM — con librerías reales."

#### Cap. 11 — Double/Debiased Machine Learning
`cap04_dml.typ` · S10 · L10 · A2 · **Variante A** · ★

**Objetivos:** (1) implementar DML-PLR y DML-IRM con `DoubleML`/`econml`; (2) elegir un
*learner* de *nuisance* verificando la condición de tasa; (3) distinguir qué estima cada
uno de OLS/IV/DML-PLIV sobre el mismo dataset (no son el mismo estimando).

**Contenido fuente:**
- Definición: score IRM, `@eq-irm-score` (línea 82).
- Teorema: doble robustez + ortogonalidad, `@thm-dr` (línea 86).
- Supuestos: no confusión condicional, soporte común, consistencia (línea 44).
- Tabla: *learners* comunes y su tasa $a_n$, `@tab-learners` (línea 107).
- Código parte 1: `@lst-doubleml-nsw` (línea 149) — PLR con `DoubleML`.
- Código parte 2: verificación de *leakage*, `verify_no_leakage` (línea 241).
- Caso: Card (1995) — **usar el contenido corregido**: OLS 0.071, IV 2SLS 0.124, DML-PLIV
  0.145, y la lectura correcta de que son *estimandos distintos* (LATE de los
  *compliers*, no una escalera de corrección de sesgo) — línea 302, texto reescrito en
  la mejora de contenido. Distinguir explícitamente Card (1995) de Angrist–Krueger
  (1991), error de citación ya corregido en el libro.
- Interactivo: "IV da un intervalo casi 10× más ancho que OLS — ¿es eso un defecto del
  método?" (respuesta: es el precio de identificar con la variación limitada del
  instrumento).
- Riesgos: tabla `@tab-riesgos_dml` (línea 320) — *learner* único, *folds*
  insuficientes, soporte común ignorado, confusión no observada.
- Ejercicio: ejercicio 4 (línea 366) — verificar doble robustez reemplazando $hat(mu)$
  por una constante.

**Transición** → Cap. 14 (S11; el orden de enseñanza salta a Validación antes de
Meta-learners): "con un ATE estimado y una librería que lo produce en segundos, la
pregunta que sigue no es metodológica sino de confianza: ¿cómo sé que este número es
razonable antes de servirlo?"

#### Cap. 12 — Meta-learners para efectos de tratamiento heterogéneos
`cap05_metalearners.typ` · S13 · L13 · **A3 arranca** · **Variante A** · ★

**Objetivos:** (1) implementar S/T/X/R/DR-learner; (2) explicar por qué R- y DR-learner
dependen de los *nuisance* a 2.º orden y S/T/X a 1.er orden; (3) elegir un meta-learner
según soporte común y muestra disponible.

**Contenido fuente:**
- Definiciones: S-learner (línea 46), T-learner (línea 58), X-learner (línea 71,
  `@alg-x-learner` línea 147).
- Teorema 1: R-learner cuasi-oracle, `@thm-r-learner` (línea 91) — score de Robinson.
- Teorema 2 (contenido nuevo, dedicarle la slide de "teorema central"): DR-learner,
  `@thm-dr-learner` (Kennedy 2023, tasa oracle bajo producto de errores) —
  `@sec-cap05_drlearner`, con el pseudo-resultado $Gamma_i$.
- Tabla comparativa ampliada: `@tab-meta-comparison` (línea 100, con la fila nueva
  "dependencia de los nuisance": 1.er orden S/T/X vs. 2.º orden R/DR).
- Código: listado `@lst-meta-comparison` (línea 166) — comparación de 4 meta-learners
  con RMSE respecto al CATE verdadero.
- Caso: NSW, `CausalForestDML`, CATE medio \$2,226 por subgrupo educativo (línea 240).
- Interactivo: "el S-learner con regularización fuerte colapsa el CATE a cero —
  ¿por qué eso no es un problema del algoritmo sino del diseño del método?" (listado
  `@lst-s-learner-bias`, línea 222).
- Riesgos: tabla `@tab-riesgos_metalearners` (línea 266).
- Ejercicio: ejercicio 4 (línea 293) — implementar el R-learner "a mano" con
  cross-fitting.
- Guía de elección: la regla de trabajo nueva al final de "Riesgos, límites" (DR/R
  primero si hay soporte común y muestra; T-learner como *baseline* obligatorio;
  S-learner solo con *learners* poco regularizados).

**Transición** → Cap. 13: "los meta-learners reutilizan *learners* genéricos; el
siguiente capítulo presenta una familia diseñada específicamente para CATE, con
garantías de inferencia mejores."

#### Cap. 13 — Árboles y bosques causales
`cap06_arboles_bosques.typ` · S14 · L14 · **B1 entrega** · **Variante A** · ★

**Objetivos:** (1) explicar la *honesty* y por qué evita el sesgo de selección
estructural; (2) describir el bosque causal como generador de pesos locales, no como
promedio de árboles; (3) usar `CausalForestDML` con mapas de heterogeneidad.

**Contenido fuente:**
- Definición: *honesty*, `@def-honesty` (línea 52); criterio de *splitting*,
  `@eq-causal-tree-criterion` (línea 79).
- Teorema: normalidad asintótica local del Causal Forest, `@thm-cf-normality` (línea 106).
- Contenido nuevo (dedicarle una slide propia, es la corrección más importante del
  capítulo): el bosque como generador de *pesos de vecindad* $omega_i(x)$ que resuelven
  una ecuación de momento local — no un promedio de $hat(tau)_b(x)$ — `@sec-cap06_grf`.
- Código: listado `@lst-causal-forest-nsw` (línea 145) — mapas de heterogeneidad por
  edad/educación.
- Caso: NSW, ATE \$2,226, CATE por educación \$1,174 (educ=7) → \$3,515 (educ=14)
  (línea 249).
- Interactivo: "*policy trees* son interpretables — ¿por qué su interpretabilidad es
  también la fuente de su garantía estadística y no solo una concesión de comunicación?"
  (Athey & Wager 2021, VC finita — contenido nuevo de la sección de profundización).
- Riesgos: tabla `@tab-riesgos-cap06` (línea 294) — árbol sin *honesty*, *data dredging*,
  múltiples subgrupos, CATE fuera de soporte común.
- Ejercicio: ejercicio 4 (línea 347) — implementar un árbol causal honesto "a mano".

**Transición** → Cap. 15 (S12 en el orden de enseñanza real, ya cubierto — este capítulo
cierra la Parte II en el libro): "el estimador ya es robusto y validado; falta ponerlo
donde alguien pueda consultarlo sin reabrir el notebook."

#### Cap. 14 — Validación, refutación y sensibilidad
`cap07_validacion.typ` · S11 · L11 · **A2 entrega** · **Variante A** · ★

**Objetivos:** (1) explicar por qué la validación cruzada estándar no aplica al CATE;
(2) construir curvas Qini/AUUC y distinguir ranking de calibración; (3) calcular e
interpretar un E-value.

**Contenido fuente:**
- Proposición: imposibilidad de validación directa, `@prop-no-direct-validation` (línea 44).
- Definición: curva Qini acumulada (línea 53–65) y AUUC/coeficiente Qini (contenido
  nuevo, `@sec-cap07_uplift_transformed` ampliada).
- Teorema/resultado central (contenido nuevo, dedicarle la slide central): **E-value**,
  `@sec-cap07_evalue` — definición, interpretación relativa a los confusores medidos, y
  sus dos límites (condición necesaria no suficiente; requiere transformar la escala).
- Código: listado `@lst-qini` (línea 136) — curva Qini sobre DGP con *ground truth*.
- Caso: `thornton_hiv` (línea 262, ampliado) — experimento aleatorizado, banco de
  pruebas con identificación no discutida.
- Interactivo: "un modelo puede predecir Y con R²=0.99 y producir CATE completamente
  sesgado — ¿cómo es posible?" (tabla de riesgos, línea 297).
- Riesgos: tabla `@tab-riesgos-cap07` (línea 287).
- Ejercicio: ejercicio 4 (línea 359) — implementar el *transformed outcome* y correlacionarlo con $hat(tau)$.
- Slide extra (variante A con contenido de sistema, sección `@sec-cap07_evaluacion_offline`):
  *baselines* obligatorios (efecto constante, regla aleatoria, riesgo sin causalidad) y
  versionado del proceso de evaluación — mencionar en `cap-caso-resolucion` o una slide
  adicional si el tiempo lo permite.

**Transición** → Cap. 15: "con el proceso de evaluación versionado y reproducible, la
pregunta natural es cómo llevar el estimador que pasó esa evaluación a un servicio que
otros puedan consultar."

#### Cap. 15 — Despliegue de un estimador causal como servicio
`cap07b_despliegue_servicio.typ` · S12 · L12 · **B1 arranca** · **Variante B** · ★

**Objetivos:** (1) justificar biblioteca vs. servicio vs. *batch* para un caso dado;
(2) separar la función de inferencia pura del framework web; (3) explicar qué expone
`/metadata` que `/health` no expone.

**Contenido fuente:**
- Problema de diseño: cómo poner el estimador a disposición de alguien sin reabrir el
  notebook (líneas 27–30).
- Opciones: biblioteca embebida / servicio REST / *batch* precomputado (línea 35–39).
- Decisión de referencia: FastAPI + Docker, servicio REST síncrono (línea 46).
- Código parte 1: `@lst-inference-pura` (línea 56) — función pura `estimar_efecto`.
- Código parte 2: `@lst-fastapi-app` (línea 84, con `/metadata` ya añadido en la mejora
  de contenido) + `@lst-metadata-endpoint` (nuevo) — el contrato causal expuesto en
  tiempo de ejecución.
- Monorepo: callout `#monorepo[]` (línea 23) — `04_notebooks_produccion_hf/B1_fastapi_dml/`,
  artefacto `artifacts/A2/dml_estimator.joblib` + `feature_list.json`, Labs L12/L14.
- Caso: por qué la respuesta de `estimar_efecto()` incluye IC y población de
  entrenamiento, no solo el punto (línea 133).
- Checklist: 4 ítems, incluido el nuevo sobre `/metadata` (línea 138).
- Interactivo: "¿por qué separar `inference.py` de `app.py` facilita probar la lógica
  sin levantar el servidor?" (ejercicio conceptual 2, línea 153).
- Ejercicio: ejercicio de infraestructura — completar Notebook B1 y verificar
  `/health`+`/metadata`+`/predict` con `curl` (línea 158).

**Transición** → Cap. 16 (◇, ampliación de S5; en el libro cierra la Parte II): "el
servicio ya expone un ATE; la Parte III retoma la pregunta de identificación con
diseños completos, empezando por la que ya se usó en S5 en su versión avanzada."

---

### Parte III — Diseños de identificación con ML

#### Cap. 16 — Post-Double-Selection LASSO
`cap08_pds.typ` · ampliación opcional de S5 (sin sesión propia) · **Variante A** · ◇

**Uso recomendado:** ampliar S5 si el cohorte es muy econométrico; si no, L05 + Cap. 6
bastan y este capítulo queda como lectura de referencia.

**Esqueleto reducido (◇):**
1. `cap-portada` 2. `cap-roadmap` 3. `cap-motivacion` (NHEFS, dejar de fumar y peso,
líneas 31–37) 4. contenido central: Teorema BCH 2014, `@thm-pds-formal` (línea 61) +
la elección de $lambda$ teórico vs. CV (`@sec-cap08_lambda`, contenido nuevo — es la
corrección más importante del capítulo: reportar $lambda_"CV"$ *y* $lambda_"BCH"$, no
solo uno) 5. `cap-caso-resolucion` (NHEFS: OLS 2.54, manual 3.20, PDS 3.22, DML 3.13 kg,
línea 232) 6. `cap-cierre-narrativo`.

**Contenido fuente adicional (si se expande a mazo completo):**
- Código: `@lst-pds-nhefs` (línea 149).
- Comparación PDS vs. DML: `@tab-pds-vs-dml` (línea 103).
- Riesgos: tabla `@tab-riesgos-cap08` (línea 301) — *dense confounding*, $lambda$
  inestable, controles post-tratamiento.

**Transición** → Cap. 6 / Cap. 17: "PDS resuelve alta dimensión bajo linealidad y
esparsidad; cuando los datos son un panel o hay endogeneidad, se necesita otra
estructura."

#### Cap. 17 — Machine learning causal en datos de panel
`cap09_panel_dmliv.typ` · electivo / oficina de proyectos sectoriales · **Variante A** · ◇

**Esqueleto reducido (◇):**
1. `cap-portada` 2. `cap-roadmap` 3. `cap-motivacion` (reforma laboral en 32 regiones,
líneas 32–36) 4. contenido central, dos bloques:
   - *within-transformation* + DML-panel, `@eq-within` (línea 55) y
     `@alg-dml-panel-within` (línea 120);
   - **advertencia nueva (la corrección más importante):** la *within-transformation*
     es TWFE y hereda el problema de pesos negativos con adopción escalonada
     (Goodman-Bacon / de Chaisemartin–D'Haultfœuille) — caja de profundización 9.1,
     reescrita en la mejora de contenido.
   - Instrumentos débiles: F de primera etapa, umbral $F>10$ (Stock & Yogo 2005),
     contenido nuevo tras `@thm-dml-pliv` (línea 116).
5. `cap-cierre-narrativo`.

**Contenido fuente adicional:** tabla de riesgos ampliada `@tab-riesgos-cap09` (línea
255, con las dos filas nuevas de adopción escalonada e instrumento débil).

**Transición** → Cap. 18: "con tres diseños completos (DML llano, PDS, panel/IV), falta
organizar cuándo usar cada uno — y sus alternativas de mayor fuerza identificadora."

#### Cap. 18 — Diseño de investigación y selección de método
`cap10_mapa_decision.typ` · guía de proyecto, sin sesión extra · **Variante A** · ◇

**Uso recomendado:** no es una sesión — es la guía que el estudiante consulta al elegir
método para su proyecto final (S29–S32).

**Esqueleto reducido (◇):**
1. `cap-portada` 2. `cap-roadmap` 3. `cap-motivacion` (Banco Central, política monetaria,
líneas 33) 4. `cap-definicion` con la tabla de mapa de decisión, `@tab-decision-map`
(línea 70, con la corrección: "nunca TWFE" en panel *staggered*) 5. `cap-supuestos` con
la jerarquía de identificación, `@tab-identificacion-jerarquica` (línea 98) 6. contenido
nuevo: el límite de fondo — el mapa elige *estimador*, no *identificación*, y esa
distinción es la que ningún `choose_method()` puede automatizar (párrafo final añadido
en la mejora de contenido) 7. `cap-cierre-narrativo`.

**Transición** → Cap. 19 (Parte IV, S17): "con el estimador elegido y validado, el
capítulo 15 ya lo sirvió — falta publicarlo donde otros lo encuentren y lo audite un
pipeline, no solo una persona."


---

### Parte IV — Publicación y operación en producción

#### Cap. 19 — *Model cards* causales y publicación en Hugging Face Hub
`cap10b_hf_hub.typ` · S17 · L17 · **B2 arranca** · **Variante B** · ★

**Objetivos:** (1) completar una *model card* causal con estimando, diseño y supuestos;
(2) explicar qué le falta a una *model card* estándar para un modelo causal;
(3) publicar modelo + card en Hugging Face Hub.

**Contenido fuente:**
- Problema de diseño: la *model card* estándar no tiene campo para supuestos de
  identificación (líneas 27–30).
- Opciones: *model card* estándar vs. causal extendida (línea 36–38).
- Decisión de referencia: campos obligatorios — estimando, diseño, supuestos, población,
  "no usar para" (línea 42).
- Código parte 1: `@lst-model-card-causal` (línea 51) — plantilla Markdown.
- Código parte 2: `@lst-publicar-hub` (línea 84) — `HfApi`, `upload_file`.
- Monorepo: callout `#monorepo[]` (línea 23) — `04_notebooks_produccion_hf/B2_hub_cicd/
  model_card/MODEL_CARD.md`, Lab L17, `scripts/prepare_hub_bundle.sh`.
- Contenido nuevo (dedicarle una slide, conecta con Cap. 7): *datasheets for datasets*
  (Gebru et al. 2021) como pieza complementaria a la *model card* — la mitad de los
  campos de una datasheet son la ficha de procedencia del Cap. 7.
- Caso: la sección "no usar para" cita directamente el Cap. 26 (transportabilidad) —
  buen gancho de cierre.
- Checklist: 4 ítems (línea 107).
- Ejercicio: ejercicio de infraestructura — publicar el modelo del Notebook A2 (línea 130).

**Transición** → Cap. 20: "documentar los supuestos no impide que alguien los rompa sin
querer al modificar el código — falta automatizar el chequeo."

#### Cap. 20 — CI/CD para modelos causales
`cap10c_cicd.typ` · S18 · L18 · **B2 entrega** · **Variante B** · ★

**Objetivos:** (1) diseñar un pipeline con etapa de software y etapa estadística
separadas; (2) escribir una prueba de humo tipo placebo que bloquee publicación;
(3) situar el pipeline propio del curso dentro del ecosistema MLOps estándar.

**Contenido fuente:**
- Problema de diseño: un CI genérico no detecta que un placebo dejó de dar cero (líneas
  27–30).
- Opciones: CI genérico vs. CI con pruebas estadísticas integradas (línea 33–37).
- Decisión de referencia: dos etapas — software en cada *push*, estadística antes de
  publicar (línea 40–43).
- Código parte 1: `@lst-cicd-workflow` (línea 51) — YAML de GitHub Actions.
- Código parte 2: `@lst-test-placebo` (línea 99) — prueba de humo estadística.
- Monorepo: callout `#monorepo[]` (línea 23) — `.github/workflows/b1_smoke.yml`,
  `course_practice_ci.yml`, `scripts/audit_repo.sh`.
- Contenido nuevo (dedicarle una slide): ecosistema MLOps estándar (MLflow/DVC/Great
  Expectations/Evidently) y qué es lo que *ninguno* de ellos cubre — la etapa
  `tests-estadisticos` es específica del dominio causal y hay que escribirla.
- Caso: `publicar-hub` condicionado a `tests-estadisticos` (línea 122).
- Checklist: 4 ítems (línea 131).
- Interactivo: 3 criterios de diseño de la etapa estadística (dataset congelado,
  umbrales fijados antes, fallo estadístico ≠ fallo de software) — contenido nuevo.
- Ejercicio: ejercicio de infraestructura — verificar que remover un control clave
  bloquea `publicar-hub` (línea 147).

**Transición** → Cap. 23: "con el sistema desplegado, publicado y auditado
automáticamente, la pregunta cambia de validez estadística a validez frente a
personas: ¿el efecto se explica igual que se predice?"

---

### Parte V — Heterogeneidad, políticas y *targeting*

#### Cap. 21 — Aprendizaje de políticas óptimas
`cap11_policy_learning.typ` · S22 · L22 · **A4 arranca** · **Variante A** · ★

**Objetivos:** (1) formalizar *policy value* y *welfare regret*; (2) atribuir
correctamente EWM (Kitagawa–Tetenov) vs. su extensión con *nuisance* de ML
(Athey–Wager); (3) construir un *policy tree* con restricción presupuestaria.

**Contenido fuente:**
- Definición: *policy value*, política óptima $pi^*(x)=bold(1){tau(x)>0}$ (línea 44–56).
- Teorema 1 (contenido nuevo, dedicarle la slide central): **EWM de Kitagawa & Tetenov
  (2018)**, `@thm-ewm` — regret $O(sqrt("VC"(Pi)/n))$ contra la mejor política *de la
  clase*, no la óptima sin restricciones.
- Teorema 2: extensión con *nuisance* estimados por ML, `@thm-policy-learning` (Athey &
  Wager 2021) — mismo tipo de argumento ortogonalidad+cross-fitting que DML.
- Código parte 1: `@lst-policy-learning` (línea 108, **ahora etiquetado explícitamente
  como DGP sintético** — usar la advertencia añadida en la mejora de contenido como
  parte de la narrativa, no ocultarla).
- Código parte 2: `@lst-budget-policy` (línea 178) — restricción presupuestaria 30%.
- Caso: `gov_transfers`, welfare 3× mayor que aleatorio al 30% de presupuesto (línea 196,
  con la advertencia nueva sobre por qué la curva domina "mecánicamente").
- Interactivo: "si la curva de targeting NO se separa de la aleatoria, ¿qué política es
  la óptima?" (respuesta: tratar a todos o a nadie según el signo del ATE).
- Riesgos: tabla `@tab-riesgos-cap11` (línea 208) — evaluar *in-sample*, ignorar
  equidad, CATE mal calibrado.
- Ejercicio: ejercicio 2 (línea 233) — comparar tratar a todos / aleatorio 30% / top 30%
  por CATE.

**Transición** → Cap. 22: "policy learning decide *a quién*; en *marketing* y programas
sociales la pregunta se vuelve *con qué acción*, entre varias con costos distintos."

#### Cap. 22 — Uplift *modeling* y *targeting* económico
`cap12_uplift_targeting.typ` · S23 · L23 · **A4 + B3** · **Variante A** · ★

**Objetivos:** (1) distinguir cuándo basta el *ranking* de cuándo se necesita magnitud
calibrada; (2) implementar *net score* con presupuesto y múltiples tratamientos;
(3) publicar la política en un *Space* de Hugging Face.

**Contenido fuente:**
- Definición: uplift = CATE, `@eq-uplift_cate` (línea 46) — y la distinción nueva
  ranking vs. calibración (`@sec-cap12_uplift_cate`, ampliada) como marco de todo el
  capítulo.
- Definición 2: curva Qini/AUUC y coeficiente Qini, `@eq-qini` `@eq-auuc` (línea 58–67).
- Algoritmo/teorema: *net score* con costo sombra $lambda$, `@alg-net-score`
  `@eq-net-score-opt` (línea 106–126).
- Código parte 1: `@lst-uplift` (línea **reescrito** — DGP de tres brazos, un
  `BaseTRegressor` por acción, corrigiendo el bug de columnas inexistentes de la
  edición anterior). Enfatizar en la slide: "no se puede derivar $tau_"llamada"$ de
  $tau_"SMS"$ escalando".
- Código parte 2: `@lst-cost-effectiveness` (**reescrito**, bisección de $lambda$ sobre
  3 acciones reales) — mostrar por qué la estrategia mixta domina.
- Caso: costo-efectividad SMS \$0.5 vs. llamada \$8, presupuesto \$100,000.
- Interactivo: "multiplicar `uplift_sms` × 3 para simular otro tratamiento — ¿cambia el
  Qini? ¿cambia la asignación?" (ejercicio 3 nuevo de la mejora de contenido).
- Riesgos: tabla `@tab-riesgos-cap12` (línea 251).
- Ejercicio: ejercicio 4 (línea discusión sobre uplift vs. policy learning formal).

**Transición** → Cap. 23 (S19 en el orden real de enseñanza, ya cubierto antes en el
libro): "con el CATE ya usado para decidir a quién y con qué acción tratar, falta
preguntar si esa decisión se puede *explicar* del mismo modo que se calculó."

---

### Parte VI — Explicación, equidad y decisión estructural

#### Cap. 23 — Explicación causal y equidad algorítmica
`cap12b_explicacion_equidad.typ` · S19 · L19 · **Variante A** · ★

**Objetivos:** (1) descomponer un efecto en directo/indirecto/espurio; (2) aplicar
equidad contrafactual (Kusner et al. 2017); (3) distinguir discriminación por *proxy* de
influencia no resuelta (Kilbertus et al. 2017).

**Contenido fuente:**
- Definición: descomposición directo/indirecto, `@sec-explicacionequidad-directoindirecto`
  (línea 33–42) — CDE, NIE.
- Definición 2: equidad contrafactual, `@sec-explicacionequidad-contrafactual` (línea 44).
- Contenido nuevo (dedicarle la slide central): **proxy vs. influencia no resuelta**
  (Kilbertus et al. 2017) — dos remedios de naturaleza distinta: técnico (neutralizar el
  proxy en el grafo) vs. normativo (declarar qué rutas se aceptan); el error típico de
  auditorías que solo quitan la variable sensible del modelo.
- Código: listado `@lst-descomposicion-directo-indirecto` (línea 55) — SCM lineal
  simulado, efecto directo 0.15.
- Caso: brecha salarial de género y descomposición Oaxaca-Blinder (línea 92).
- Interactivo: "declarar $M$ (ocupación) como mediador legítimo sin análisis histórico —
  ¿qué se puede estar blanqueando?" (riesgo 1, línea 97).
- Riesgos: los 3 de `@sec-explicacionequidad-riesgos` (línea 97).
- Ejercicio: ejercicio computacional — modificar el listado para efecto directo 0 (línea 116).

**Transición** → Cap. 24: "la descomposición por rutas es el aparato causal de equidad;
el capítulo siguiente lo complementa con la caja de herramientas que de verdad se usa en
la práctica — SHAP y las tres familias observacionales de *fair ML*."

#### Cap. 24 — Ética, interpretabilidad y comunicación de resultados
`cap16_etica_interpretabilidad.typ` · S20 · L20 · **Variante A** · ★

**Objetivos:** (1) ubicar un criterio de equidad en la familia correcta (independencia/
separación/suficiencia) y explicar por qué no pueden satisfacerse a la vez; (2) explicar
SHAP sobre un sustituto del CATE, no sobre el modelo de *outcome*; (3) reportar
resultados con IC correcto por subgrupo.

**Contenido fuente:**
- Definiciones: las tres familias canónicas — independencia (`@def-demo-parity`),
  separación (`@def-eq-odds`), suficiencia (`@def-calibracion`) — reescritas en la
  mejora de contenido (línea 38–56).
- Teorema central (contenido nuevo, es la corrección más importante del capítulo):
  **teorema de incompatibilidad**, `@thm-imposibilidad-fairness` (línea 58) — el caso
  COMPAS como ejemplo de por qué la discusión no se resuelve con más datos.
- Definición adicional: *equalized CATE* reubicada como noción propia del curso, no
  canónica (`@def-eq-cate`, línea 76) — con el trade-off de Kitagawa–Sakaguchi–Tetenov
  (`@sec-cap16-equidad-causal`).
- Código (contenido nuevo, es la 2.ª corrección más importante): `@lst-shap` reescrito
  — SHAP sobre un **sustituto** de $hat(tau)(X)$ con $R^2$ de fidelidad, contrastado
  explícitamente contra SHAP sobre $hat(mu)_Y$ (tabla de 3 modelos internos,
  `@sec-cap16-interpretabilidad`).
- Código 2: `@lst-fairness` corregido — IC por subgrupo vía `ate_interval`/*bootstrap*
  del pipeline completo, no *t*-test sobre los $hat(tau)_i$.
- Caso: `gov_transfers`, CATE rural 30% menor — no es sesgo del modelo, es desigualdad
  estructural (línea 178).
- Interactivo: "¿por qué un $t$-test sobre los $hat(tau)_i$ subestima la incertidumbre
  de la brecha entre grupos?"
- Riesgos: tabla `@tab-riesgos-cap16` (línea 211, con las 2 filas nuevas: SHAP sobre el
  modelo equivocado, IC con *t*-test).
- Ejercicio: ejercicio 3 (línea 245) — usar SHAP sobre un Causal Forest en `nhefs`.

**Transición** → Cap. 25: "explicar y auditar el efecto asume que ya se decidió qué
hacer con él; el capítulo siguiente formaliza esa decisión misma, más allá de 'tratar o
no tratar'."

#### Cap. 25 — Decisiones estructurales bajo incertidumbre
`cap12c_decisiones_estructurales.typ` · S21 · L21 · **Variante A** · ★

**Objetivos:** (1) formalizar una decisión como maximización de utilidad esperada sobre
un conjunto de acciones; (2) aplicar los criterios maximin y *minimax regret* cuando el
efecto solo está parcialmente identificado; (3) distinguir incertidumbre estadística de
incertidumbre estructural.

**Contenido fuente:**
- Definición: decisión óptima, `@sec-decisionesestructurales-formalizacion` (línea
  36–39) — $d^* = "argmax"_d E[U(Y("do"(d)))]$.
- Contenido nuevo (dedicarle la slide central): **tres criterios de decisión bajo
  identificación parcial** — utilidad esperada / maximin (Wald) / *minimax regret*
  (Savage), con la tabla de cuándo es defendible cada uno (`@sec-decisionesestructurales-criterios`,
  Manski 2004).
- Código: `@lst-decision-optima` (línea 55) — tres políticas candidatas con IC de
  utilidad.
- Caso: transferencia simple / con capacitación, `valor_por_punto_efecto` como parámetro
  normativo que ningún dato determina (línea 90).
- Interactivo: policy learning del Cap. 21 como caso particular de este marco —
  identificar $cal(D)$ y $U$ (ejercicio teórico 1, línea 107).
- Riesgos: los 3 de `@sec-decisionesestructurales-riesgos` (línea 95) — función de
  utilidad implícita, sensibilidad a la utilidad supuesta, confundir incertidumbre
  estadística con estructural.
- Ejercicio: ejercicio computacional nuevo — maximin y *minimax regret* sobre el mismo
  listado, variando el error estándar (línea 116).

**Transición** → Cap. 26: "toda decisión estructural asume que el efecto vale para la
población sobre la que se decide — ¿y si la política se aplica en otro mercado?"

#### Cap. 26 — Generalización y transportabilidad entre dominios
`cap12d_generalizacion.typ` · S24 · L24 · **Variante A** · ★

**Objetivos:** (1) construir un diagrama de selección; (2) distinguir transportabilidad
de generalización (selección muestral); (3) aplicar la fórmula de transporte por
reponderación y verificar su condición de soporte.

**Contenido fuente:**
- Definición: diagrama de selección, `@sec-generalizacion-diagramas` (línea 36–38).
- Teorema (contenido nuevo, dedicarle la slide central): **transportabilidad vs.
  generalización** — el teorema de generalización de Pearl & Bareinboim (2011) es el
  que justifica la reponderación del listado, no el algoritmo general de
  Bareinboim–Pearl (2013); y las intervenciones suaves (Correa & Bareinboim 2020) para
  cuando se transporta una *política*, no un efecto puntual.
- Código: `@lst-transporte-reponderacion` (línea 63, con la condición de soporte entre
  dominios explicitada en la mejora de contenido).
- Caso: retorno a la educación de Card (1995) — mecanismo estable vs. distribución de
  covariables distinta (línea 88).
- Interactivo: "¿por qué 'reentrenar con datos del destino' no está disponible en la
  mayoría de los casos que motivan la transportabilidad?" (ejercicio teórico 2, línea 107).
- Riesgos: los 3 de `@sec-generalizacion-riesgos` (línea 93) — asumir transportabilidad
  sin diagrama, "no hay evidencia de que difiera" ≠ "no difiere".
- Ejercicio: ejercicio computacional — dos dominios con la misma ecuación estructural y
  distinta distribución de X (línea 112).

**Transición** → Cap. 27 (◇, electivo; en el libro abre la Parte VII): "hasta aquí, el
curso cubrió estimación, decisión, equidad y generalización con los métodos 'estándar'.
La Parte VII reúne dos familias más especializadas, empezando por *deep learning*."


---

### Parte VII — Métodos avanzados

#### Cap. 27 — Deep learning para inferencia causal
`cap13_deep_causal.typ` · electivo avanzado (no bloquea HF) · **Variante A** · ◇

**Esqueleto reducido (◇):**
1. `cap-portada` 2. `cap-roadmap` 3. `cap-motivacion` (adherencia a medicamentos,
recordatorios personalizados, líneas 30–34) 4. contenido central, dos bloques:
   - TARNet/CFRNet, `@thm-cfrnet` (línea 68) — representación balanceada $Phi(X)$.
   - **Contenido nuevo, el más importante si se expande el mazo:** (a) balancear no
     siempre ayuda — Curth & van der Schaar (2021), `@sec-cap13_limites_balance`, $alpha$
     como hiperparámetro a validar y no un interruptor; (b) la inferencia válida **no**
     es un problema abierto — Farrell–Liang–Misra (2021) da tasas para redes como
     *nuisance* dentro de DML, y RieszNet automatiza el score ortogonal
     (`@sec-cap13_inferencia`). Este es el giro pedagógico más fuerte del capítulo:
     "en vez de estimar τ directamente con una red y luego buscar IC, usar la red
     donde aporta —los *nuisance*— y dejar la inferencia al aparato ortogonal."
5. `cap-cierre-narrativo`.

**Contenido fuente adicional:** tabla de riesgos ampliada `@tab-riesgos-cap13` (con las
2 filas nuevas: $alpha$ sin validar, $hat(tau)(x)$ sin incertidumbre).

**Transición** → Cap. 28: "TARNet/CFRNet estiman a nivel de unidad; el capítulo
electivo que sigue trata el caso de una sola unidad tratada observada en el tiempo."

#### Cap. 28 — Control sintético y *matrix completion*
`cap14_scm_matrix_completion.typ` · electivo (evaluación de programas con paneles) · **Variante A** · ◇

**Esqueleto reducido (◇):**
1. `cap-portada` 2. `cap-roadmap` 3. `cap-motivacion` (reforma tributaria regional, sin
control perfecto, líneas 30–34) 4. contenido central, dos bloques:
   - SCM clásico, `@alg-scm_clasico` (línea 105) y *matrix completion*,
     `@thm-matrix-completion` (línea 70).
   - **Contenido nuevo:** norma nuclear como envolvente convexa del rango (Recht et al.
     2010) — mismo principio que LASSO/ℓ1 pero para rango en vez de esparsidad; elección
     de $r$/$lambda$ por CV con enmascaramiento en bloque (`@sec-cap14_rango`); inferencia
     por permutación de placebos (Abadie et al. 2015) con su $p$-valor mínimo $1/(J+1)$.
5. `cap-cierre-narrativo`.

**Contenido fuente adicional:** control sintético aumentado (Ben-Michael et al. 2021)
para el caso de ajuste pre-tratamiento imperfecto; tabla de riesgos ampliada
`@tab-riesgos-cap14` (3 filas nuevas: mal ajuste pre-tratamiento, pocos donantes con
cota del $p$-valor, unidad fuera de la envolvente convexa).

**Transición** → Cap. 29 (Parte VIII, S26): "hasta aquí, todo el curso asumió el grafo
causal dado por conocimiento de dominio. La última parte relaja ese supuesto."

---

### Parte VIII — Estructura, monitoreo y frontera

#### Cap. 29 — Descubrimiento causal y grafos
`cap15_descubrimiento_grafos.typ` · S26 · L26 · **B3 cierre** · **Variante A** · ★

**Objetivos:** (1) ejecutar PC y NOTEARS y leer una CPDAG correctamente; (2) explicar la
sensibilidad a hiperparámetros y por qué invalida comparaciones ingenuas entre
algoritmos; (3) situar el descubrimiento como exploración, no como reemplazo del
razonamiento causal sustantivo.

**Contenido fuente:**
- Definición: criterio de puerta trasera en DAGs, `@def-backdoor` (línea 49, distinto
  del `@def-backdoor` del Cap. 8 aunque mismo nombre — verificar colisión de labels al
  escribir el `.typ`, usar alias si Typst se queja).
- Algoritmo: PC *skeleton*, `@alg-pc-skeleton` (línea 75).
- Teorema/resultado: CPDAG como clase de equivalencia de Markov — conectar
  explícitamente con el Teorema de la Jerarquía Causal del Cap. 3 (mismo fenómeno visto
  desde la estructura, contenido nuevo de la mejora de contenido).
- Contenido nuevo adicional: GES como tercera familia (basada en *score*), consistente
  pese a ser voraz (Chickering 2002) — más robusta que PC en muestras pequeñas.
- Código: `@lst-notears` (línea 173) — PC + NOTEARS con `causal-learn`.
- Caso: DAG de Card (1995) con confusor no observado $U$ (habilidad) — panel izquierdo
  de la figura (línea 241).
- Interactivo: "sensibilidad a hiperparámetros (Machlanski et al. 2024): el efecto de
  $alpha$/$lambda$ puede ser mayor que la diferencia entre algoritmos — ¿qué implica
  para un *benchmark* publicado?" (contenido nuevo, `@sec-cap15_riesgos`).
- Riesgos: tabla `@tab-riesgos-cap15` (línea 282).
- Ejercicio: ejercicio 1 (línea 308) — DAG para `nhefs` con criterio de puerta trasera.

**Transición** → Cap. 30: "con o sin grafo descubierto, el sistema ya está en
producción. La pregunta cambia de identificación puntual a identificación continua:
¿sigue siendo válida mañana?"

#### Cap. 30 — Monitoreo de supuestos causales en producción
`cap15b_monitoreo.typ` · S25 · L25 · **B4 arranca** · **Variante B** · ★

**Objetivos:** (1) distinguir monitoreo genérico de *drift* de monitoreo causal-aware;
(2) implementar las 4 métricas del capítulo, en particular el *drift* del mecanismo de
asignación; (3) interpretar el reporte en el orden correcto (temprano → tardío).

**Contenido fuente:**
- Problema de diseño: un servicio puede seguir respondiendo con normalidad mientras el
  efecto que reporta ya no es válido (líneas 27–30).
- Opciones: monitoreo genérico vs. causal-aware (línea 33–37).
- Decisión de referencia (**contenido nuevo, reescrito por completo — es el capítulo con
  más correcciones de todo el libro**): 4 métricas, no 3 — (i) *drift* marginal con
  PSI/ASMD, no solo KS; (ii) *drift* del **mecanismo de asignación** vía AUC del
  *propensity* reestimado — la métrica que detecta ruptura de identificación sin mover
  ninguna marginal; (iii) fuerza del instrumento con `f_test` correcto sobre el
  instrumento excluido (no el F global); (iv) estabilidad del efecto vía contraste
  formal $z=(hat(theta)_"rec"-hat(theta)_"orig")/sqrt("SE"_"rec"^2+"SE"_"orig"^2)$, no
  "¿cae dentro del IC?".
- Código: `@lst-monitoreo-causal` (reescrito íntegramente) — 4 funciones +
  `reporte_monitoreo`.
- Monorepo: callout `#monorepo[]` (línea 23) — `04_notebooks_produccion_hf/B4_monitoring_dashboard/`,
  Streamlit, Labs L25/L27.
- Caso: dos escenarios del Notebook B4 — *drift* gradual de covariables (alerta
  temprana en (i)) y *drift* del mecanismo de asignación sin mover ninguna marginal
  (solo lo detecta (ii)) — este segundo escenario es el argumento central del capítulo,
  dedicarle la slide de "aplicación al sistema del curso".
- Checklist: 4 ítems (línea 102).
- Interactivo: "¿por qué monitorear solo el efecto final deja al sistema reaccionando
  tarde?"
- Ejercicio: ejercicio 2 nuevo — construir el escenario de *drift* del mecanismo de
  asignación con marginales idénticas (línea 118).

**Transición** → Cap. 31: "el reporte de monitoreo puede marcar `requiere_atencion` —
¿qué se hace entonces?"

#### Cap. 31 — Aprendizaje continuo y panorama de *Reinforcement Learning* causal
`cap15c_aprendizaje_continuo.typ` · S27 · L27 · **B4** · **Variante híbrida A/B** · ★

**Objetivos:** (1) implementar el patrón *champion-challenger* con doble validación
(placebo + comparación de poblaciones); (2) explicar por qué un placebo no significativo
no basta para promover un reentrenamiento; (3) describir por qué combinar datos
observacionales e interventivos acelera la convergencia en *bandits* causales.

**Agenda (mazo híbrido, no sigue un único esqueleto):**
Parte I (variante B): `cap-problema-diseno` (reentrenar sin poner en riesgo el sistema,
líneas 28–31) → `cap-opciones-tradeoffs` (reentrenamiento automático vs.
*champion-challenger*, línea 33–38) → `cap-decision-referencia` (línea 41) →
`cap-codigo-parte` (`@lst-champion-challenger`, línea 49) → `cap-interactivo` ("¿por qué
un placebo no significativo no es evidencia suficiente de que el reentrenado sea
seguro?", ejercicio conceptual 1, línea 92).
Parte II (variante A ligera, sin teorema formal — el libro lo declara panorama):
`cap-motivacion` (de decisiones únicas a secuenciales, líneas 73–76) →
`cap-definicion`/contenido (bandits causales, `@bareinboim2015bandits`, línea 78 —
**contenido nuevo**: combinar observacional + interventivo acelera la convergencia, no
solo evita sesgo — y regímenes de tratamiento dinámicos, Zhang & Bareinboim 2019) →
`cap-cierre-narrativo` con la explicación de por qué el curso se detiene ahí (línea 83).

**Transición** → Cap. 32: "el sistema ya sabe cuándo y cómo actualizarse. Falta el
último paso, casi nunca técnico: comunicar el resultado a quien debe decidir con él."

#### Cap. 32 — El lado humano de los sistemas causales
`cap15d_lado_humano.typ` · S28 · L28 · **B4 entrega** · **Variante B** · ★

**Objetivos:** (1) redactar un resultado causal con la plantilla de tres capas;
(2) aplicar las tres regularidades de comunicación de riesgo (Spiegelhalter 2019);
(3) cerrar el proyecto final con el mismo estándar de honestidad de todo el libro.

**Contenido fuente:**
- Problema de diseño: la diferencia "X predice Y" / "X causa Y" es la que primero se
  pierde en una comunicación simplificada (líneas 22–25).
- Opciones: comunicación simplificada vs. con supuestos e incertidumbre explícitos
  (línea 30–32).
- Decisión de referencia: estructura de tres capas — hallazgo / supuestos e
  incertidumbre / detalle técnico (línea 37).
- Código: `@lst-plantilla-comunicacion` (línea 46).
- Contenido nuevo (dedicarle una slide): **tres regularidades de Spiegelhalter (2019)**
  — frecuencias naturales, riesgo absoluto vs. relativo, población explícita — y la
  asimetría de costos entre sobre- y subestimar la certeza de un resultado causal.
- Caso: cierre narrativo del libro completo — de la distinción asociación/causa del
  Cap. 1 a la comunicación de tres capas (línea 65–67), usar en `cap-caso-resolucion`
  como "recapitulación del curso" en vez de un caso numérico nuevo.
- Checklist: 4 ítems (línea 73).
- Interactivo: "describa una comunicación simplificada que llevó, o pudo llevar, a una
  decisión que el resultado técnico no respaldaba" (ejercicio conceptual 2, línea 87).
- Ejercicio: ejercicio de cierre — plantilla de tres capas para el proyecto final (línea 90).

**Transición:** cierre del curso — no hay Cap. 33; la slide final debe apuntar a
`06_proyecto_final/` y a S29–S32 (defensa del sistema causal en HF).

---

## 4. Checklist de sprint (una fila por capítulo)

Usar esta tabla para llevar el estado del sprint. Estados sugeridos: `stub` (solo
metadata + TODOs, estado inicial de todos) → `contenido` (TODOs resueltos con el
puntero de §3) → `revisado` (compila, se leyó en voz alta, cabe en el tiempo de sesión)
→ `listo`.

| # | Capítulo | Estado |
|--:|---|---|
| 1 | Causalidad elemental | stub |
| 2 | Anatomía del sistema | stub |
| 3 | SCM y PCH | stub |
| 4 | Ingeniería de datos | stub |
| 5 | Predicción y causalidad ◇ | stub |
| 6 | Regularización y post-selección | stub |
| 7 | Datos de entrenamiento | stub |
| 8 | Intervención y contrafactual | stub |
| 9 | Features sin fuga | stub |
| 10 | Ortogonalidad y cross-fitting | stub |
| 11 | DML | stub |
| 12 | Meta-learners | stub |
| 13 | Árboles y bosques causales | stub |
| 14 | Validación | stub |
| 15 | Despliegue como servicio | stub |
| 16 | Post-Double-Selection ◇ | stub |
| 17 | Panel y DML-IV ◇ | stub |
| 18 | Mapa de decisión ◇ | stub |
| 19 | Hub y model cards | stub |
| 20 | CI/CD causal | stub |
| 21 | Policy learning | stub |
| 22 | Uplift y targeting | stub |
| 23 | Explicación y equidad | stub |
| 24 | Ética e interpretabilidad | stub |
| 25 | Decisiones estructurales | stub |
| 26 | Generalización | stub |
| 27 | Deep causal ◇ | stub |
| 28 | SCM / matrix completion ◇ | stub |
| 29 | Descubrimiento de grafos | stub |
| 30 | Monitoreo en producción | stub |
| 31 | Aprendizaje continuo / RL | stub |
| 32 | Lado humano | stub |

---

## 5. Plan de actualización — Etapa 2 de la monografía (C1–C11)

**Contexto.** Los 32 stubs de `capitulos/` y las secciones §1–§4 de este documento se
construyeron sobre el estado de la monografía tras la mejora de contenido de "Etapa 1"
(2026-08-10, ver `CHANGELOG_MEJORA.md` de la monografía). El **11 de agosto de 2026**
se aplicó una **Etapa 2** (commit `81152e7`, "Auditoria de contenido, mejoras C1-C11 y
material de sesiones") con 11 mejoras editoriales puntuales (C1–C11), 13 referencias
nuevas (133 en total, verificado — el changelog de la monografía dice 132; la cifra
exacta actual es 133 entradas en `bibliografia/refs.yml`) y un cambio cosmético global
de formato. **Ningún capítulo cambió de número, título o parte** — la tabla maestra del
§1 sigue siendo válida sin cambios. Lo que cambió es contenido *dentro* de 11
capítulos y 3 apéndices.

Esta sección es el mismo tipo de artefacto que el §3: por capítulo afectado, qué
cambió en la fuente, qué stub de `capitulos/` hay que tocar, y qué slide(s) nuevas o
editadas hacen falta. Los capítulos **no** listados aquí no requieren ninguna acción
por causa de Etapa 2 (su contenido no fue tocado).

### 5.0 Cambio cosmético global — sin acción requerida

Etapa 2 estandarizó las etiquetas de `#cuadrosinoptico[]`/`#cuadrodecision[]` a la
forma `[*Clave:*]` (con dos puntos) en los 32 capítulos, y ajustó alineación/tamaños en
`template.typ` (teoremas, algoritmos, código). Ninguno de los dos afecta a las
diapositivas: los stubs no copian el formato de esas cajas, solo su contenido como
parámetros de texto independientes (`decision:`, `alternativas:`, etc.), y
`plantilla_monografia.typ` es un archivo propio, no comparte `template.typ` con el
libro. **No hay nada que actualizar por este cambio.**

### 5.1 Resumen de C1–C11 y su alcance

| # | Nombre | Capítulo(s) afectado(s) | Tipo de cambio |
|---|---|---|---|
| C1 | Score ortogonal canónico | **10** (nuevo), 11 y 12 (puente) | Tabla nueva + nota técnica |
| C2 | Condiciones completas + DML1/DML2 | **10** (nuevo), 11 (pie de figura + riesgos) | Nota técnica nueva |
| C3 | Eficiencia semiparamétrica IRM | **11** (nuevo) | Teorema nuevo |
| C4 | ESS + trimming de Crump | **11** (nuevo, subsección 11.2.4), 12 (puente) | Sección nueva |
| C5 | Tests de heterogeneidad BLP/BEST/CLAN | **14** (nuevo, 14.2.7) | Sección nueva |
| C6 | Intervalos conformes | **14** (nuevo, 14.2.8), 15 y 27 (puente) | Sección nueva |
| C7 | RATE | **14** (nuevo, tras baselines) | Sección nueva + 4.º baseline |
| C8 | Sensibilidad en tres niveles | **14** (reestructura el E-value existente) | Sección reescrita |
| C9 | EIF del policy value | **21** (nuevo) | Proposición nueva + código |
| C10 | Model card machine-readable | **Ap. G** (nuevo, G.4), 15/19/20 (puente) | Apéndice + puentes |
| C11 | Inferencia robusta a IV débil | **17** (nuevo), 30 (puente) | Sección nueva |

**Capítulos con acción requerida en `07_diapositivas/`:** 10, 11, 12, 14, 15, 17, 19,
20, 21, 27, 30. Once capítulos de 32 — el resto no se tocó en Etapa 2.

### 5.2 Actualizaciones por capítulo

#### Cap. 10 — Ortogonalidad de Neyman, cross-fitting e influence functions
`capitulos/cap10_ortogonalidad_crossfitting.typ` · **C1 + C2, ambos contenido nuevo**

- **C1 — Tabla del score canónico** (`@tab-score-canonico`, tras la prueba de
  `@thm-plr-orth`): PLR, IRM, DR-learner, R-learner, PLIV y *policy value* son
  instancias de un único $psi(W,theta,eta)$. **Añadir una slide nueva** entre la actual
  `cap-teorema` (ortogonalidad PLR) y `cap-demostracion`, con `cap-definicion` o una
  tabla (`cap-supuestos` reutilizada con columnas Estimando/$psi$/$eta$) listando las 6
  filas. Es la slide más rentable de añadir: conecta visualmente Caps. 10, 11, 12, 17 y
  21 en una sola diapositiva — vale la pena citarla de nuevo en esos capítulos como "ver
  Cap. 10, tabla del score canónico" en vez de repetirla.
- **C2 — Condiciones completas (C1)–(C4) + DML1 vs. DML2** (nota técnica tras
  `@thm-dml-main`): las 4 condiciones del Teorema 3.1 de Chernozhukov et al., y la
  distinción DML1 (mediana por *fold*) vs. DML2 (promedio ponderado, recomendado, con
  *repeated cross-fitting* $R=5$–10). **Añadir a `cap-demostracion`** un 4.º paso, o una
  slide nueva de tipo `cap-supuestos` con las 4 condiciones como filas.
- **Ejercicio nuevo a considerar:** relacionar la varianza creciente a $K$ bajo
  (Fig. 11.1, ya citada en el Cap. 11) con el *repeated cross-fitting* como mitigación
  formal — mencionar en `cap-interactivo` o en la discusión.
- **`cap-mapeo-pch-activo`:** añadir a la métrica "— ver tabla de score canónico
  (6 instancias)".
- **`cap-cierre-narrativo` refs:** ninguna referencia nueva (C1/C2 no traen citas
  nuevas, son reorganización de Chernozhukov et al. 2018, ya citado).

#### Cap. 11 — Double/Debiased Machine Learning
`capitulos/cap11_dml.typ` · **C1 (puente) + C2 (puente) + C3 (nuevo) + C4 (nuevo)**

- **C1 — puente:** tras `@eq-irm-score`, el libro señala que el score IRM es la
  instancia de la tabla del Cap. 10 y que su versión sin promediar reaparece como
  $Gamma_i$ (DR-learner, Cap. 12) y como EIF del *policy value* (Cap. 21). Añadir una
  frase en `cap-definicion` (score IRM) apuntando a "ver tabla del Cap. 10".
- **C2 — puente:** el pie de la Figura 11.1 (sensibilidad a $K$) y la tabla de riesgos
  se actualizaron para mencionar DML1/DML2. Revisar el `salida:`/`nota:` del
  `cap-codigo-parte` de DML y la tabla de `cap-errores-transiciones` si se cita esa
  figura.
- **C3 — Teorema de eficiencia semiparamétrica** (`@thm-efficiency-irm`, nuevo, tras
  `@thm-dr`): la EIF del ATE-IRM es exactamente el integrando del score IRM; cota de
  Cramér–Rao semiparamétrica; $V_"eff"$ explícita. **Añadir una segunda `cap-teorema`**
  inmediatamente después de la actual (doble robustez) — son dos teoremas distintos y
  complementarios, no uno solo: la doble robustez protege contra mala especificación,
  la eficiencia certifica el óptimo cuando ambos *nuisance* convergen.
- **C4 — ESS + trimming de Crump** (nueva subsección `@sec-cap04_soporte_comun`,
  "Diagnósticos cuantitativos de soporte común"): ESS de Kish
  ($"ESS" = (sum w_i)^2/sum w_i^2$) y $alpha^* approx 0.057$ (Crump et al., 2009), con
  la advertencia de que tras el *trimming* el estimando es el ATE sobre la población
  con *overlap*, no el poblacional. **Añadir una slide nueva** (tipo `cap-definicion` o
  `cap-validacion`) entre la tabla de *learners* y el bloque de código — es contenido
  con regla operativa clara ("reportar ESS/n y el rango de ê en todo resultado DML"),
  buen candidato también para `cap-checklist-alertas` si se prefiere formato checklist.
- **`cap-errores-transiciones`:** añadir una fila — "ê extremo sin reportar ESS/trimming
  → varianza inflada sin que el histograma lo delate" (@kish1965, @crump2009dealing).
- **`cap-mapeo-pch-activo`:** métrica actual "θ0 con IC vía influence function" →
  ampliar a "...; ESS/n y trimming ($alpha^*≈0.057$) para el diagnóstico de soporte
  común".
- **`cap-cierre-narrativo` refs:** añadir Crump et al. (2009) y, si se detalla la
  eficiencia, mencionar la cota de Cramér-Rao semiparamétrica del Ap. A.

#### Cap. 12 — Meta-learners para efectos de tratamiento heterogéneos
`capitulos/cap12_metalearners.typ` · **C1 + C4, ambos puente (sin sección nueva)**

- **C1 — puente:** el DR-learner ($Gamma_i$) se identifica explícitamente como la
  instancia sin promediar del score canónico del Cap. 10. Añadir una frase en la
  `cap-teorema` del DR-learner: "Γ_i es la fila 'CATE, DR-learner' de la tabla de score
  canónico del Cap. 10 — el mismo objeto, sin promediar."
- **C4 — puente:** el mismo diagnóstico ESS/trimming del Cap. 11 se hereda en el
  DR-learner (denominadores $hat(e)(X)$ y $1-hat(e)(X)$ en $Gamma_i$). Añadir una
  cláusula en `cap-errores-transiciones` ("propensity extremo") apuntando al ESS del
  Cap. 11 en vez de solo mencionar *trimming* en abstracto.
- No se requiere ninguna slide nueva en este capítulo — son dos frases-puente.

#### Cap. 14 — Validación, refutación y sensibilidad
`capitulos/cap14_validacion.typ` · **C5 + C6 + C7 + C8, los cuatro contenido nuevo —
el capítulo con más cambios de Etapa 2**

Este capítulo pasa de ~14 a probablemente 18–20 slides si se incorpora todo C5–C8 con
el mismo nivel de detalle que el resto del mazo. Evaluar si conviene dividirlo en dos
sesiones de contenido (ranking/Qini + E-value, ya cubierto; heterogeneidad/conformal/
RATE, todo nuevo) para no saturar los 20-25 min de exposición del esqueleto estándar.

- **C8 — Sensibilidad en tres niveles** (`@sec-cap07_evalue` **reescrita**, ya no es
  solo "E-value" sino "Sensibilidad a confusión no observada: protocolo de tres
  niveles"): Nivel 1 = E-value (ya cubierto en el stub actual); **Nivel 2 nuevo** = $R^2$
  parcial de Cinelli–Hazlett/Imbens — benchmarking contra el confusor observado más
  fuerte, en la escala del propio modelo; **Nivel 3 nuevo** = *bounds* de Manski bajo
  $Y in [0,1]$ sin supuesto de no confusión. **Actualizar la slide `cap-teorema`
  existente** (actualmente solo E-value) para declarar los tres niveles, o dividirla en
  `cap-teorema` (Nivel 1, ya escrito) + una `cap-definicion` nueva (Niveles 2 y 3).
- **C5 — BLP/BEST/CLAN** (nueva subsección `@sec-cap07_tests_heterogeneidad`): Qini
  evalúa *ranking*; BLP/BEST/CLAN (Chernozhukov et al., 2020) dan tests con control de
  tipo I sobre si la heterogeneidad detectada es distinguible de cero, vía
  *sample-splitting*. **Añadir una `cap-teorema` o `cap-codigo-parte` nueva** después de
  la sección de Qini/AUUC — fila nueva en la suite de refutación
  (`@tab-refutation-suite`) y en el checklist F.3 del Apéndice F (sin diapositiva
  propia, pero mencionar el vínculo en `cap-checklist-alertas` si se añade una).
- **C6 — Intervalos conformes** (nueva subsección `@sec-cap07_conformal`,
  "Intervalos conformes para efectos individuales"): *split conformal* sobre el
  *transformed outcome*, con `@prop-conformal-coverage` y dos advertencias (cobertura es
  del *transformed outcome*, no de $Y_i(1)-Y_i(0)$ literal; requiere *conformal*
  ponderado si $hat(e)$ es estimado). **Añadir una `cap-definicion` o `cap-teorema`
  nueva** — es el puente directo hacia `ic_individual` en el Cap. 15 y hacia el Cap. 27
  (mitigación de "reportar $hat(tau)(x)$ sin incertidumbre").
- **C7 — RATE** (nueva sección tras *baselines* obligatorios, antes de "Versionado del
  proceso"): *Rank-Weighted Average Treatment Effect* (Yadlowsky et al., 2021) como
  criterio formal de selección de estimadores de CATE en datos reales, complementando
  al RMSE (que exige *ground truth* sintético). **Añadir como 4.º baseline** en la
  slide/tabla de *baselines* obligatorios si el stub la desarrolla, o como
  `cap-codigo-parte` nueva.
- **`cap-mapeo-pch-activo`:** métrica actual "Qini/AUUC (ranking), E-value
  (sensibilidad), transformed outcome (RMSE)" → ampliar a "...; BLP/BEST/CLAN
  (heterogeneidad formal); RATE (selección de estimador); conformal (IC individual);
  sensibilidad en 3 niveles (E-value/R²/Manski)".
- **`cap-cierre-narrativo` refs:** añadir Chernozhukov et al. (2020, BLP/BEST/CLAN),
  Yadlowsky et al. (2021, RATE), y al menos una de {Lei & Candès / Tibshirani et al.,
  conformal}; Cinelli & Hazlett (2020) para el Nivel 2 de sensibilidad.
- **Nuevo `cap-discusion-ejercicio` candidato:** "¿Por qué el Nivel 2 (R² parcial) se
  reporta contra un *benchmark* observado y el E-value (Nivel 1) no?" — contraste que
  no estaba disponible cuando se escribió el stub original.

#### Cap. 15 — Despliegue de un estimador causal como servicio
`capitulos/cap07b_despliegue_servicio.typ` · **C6 (puente) + C10 (puente)**

- **C6 — puente:** el endpoint `/predict` puede incluir `ic_individual` cuando existe
  calibración conforme del Cap. 14. Añadir una línea al `cap-codigo-parte` de
  `app.py`/`inference.py`: comentario `# ic_individual: solo si hay calibracion
  conforme (Cap. 14)`.
- **C10 — puente:** `/metadata` ahora declara explícitamente que valida contra
  `causal-model-card-v1.schema.json` (Ap. G.4). Añadir esa línea al
  `cap-codigo-parte` de `/metadata` ya existente en el stub (`@lst-metadata-endpoint`).
- No se requiere ninguna slide nueva — dos líneas de código a sumar en los bloques ya
  planificados.

#### Cap. 17 — Machine learning causal en datos de panel
`capitulos/cap17_panel_dmliv.typ` · **C11, contenido nuevo**

- **C11 — Anderson–Rubin y alternativas para muchos instrumentos**: el IC de
  Anderson–Rubin es válido cualquiera sea la fuerza del instrumento (a costa de poder
  ser un conjunto, no un intervalo); con muchos instrumentos, Kleibergen–Paap y
  Stock–Yogo (tamaño de test) reemplazan al $F$ de un solo instrumento. **Regla
  operativa del libro:** si $F <= 10$, reportar el IC-AR junto al de Wald; si difieren
  materialmente, declarar sensibilidad y que el Cap. 30 lo monitorea con doble umbral.
  **Añadir una `cap-teorema` o `cap-demostracion` nueva** inmediatamente después del
  contenido de instrumentos débiles ya planificado (Stock & Yogo, $F>10$) — es una
  extensión directa de esa misma slide, no un tema nuevo.
- **Nota de housekeeping (no requiere acción):** la fuente tiene una sección
  "Diseños con tiempos de tratamiento escalonados" que repite, casi literalmente, el
  contenido de la caja de profundización sobre Goodman-Bacon/TWFE que el stub ya
  cubre — es una duplicación conocida y no resuelta del lado del libro (ver
  `CHANGELOG_MEJORA.md` Etapa 2, "Qué no se hizo"). No añadir una segunda slide por
  esto; el stub actual ya captura el contenido sustantivo.
- **`cap-errores-transiciones`:** la fila de "instrumento débil" ya planificada debe
  actualizarse: mitigación pasa de "reportar el F" a "reportar el F; IC de
  Anderson–Rubin junto al Wald si $F<=10$; con muchos instrumentos, diagnósticos
  específicos (Kleibergen-Paap/Stock-Yogo)".
- **`cap-cierre-narrativo` refs:** añadir Andrews et al. (2019) y/o Stock (2002) para
  Anderson-Rubin y el caso de muchos instrumentos.

#### Cap. 19 — Model cards causales y publicación en Hugging Face Hub
`capitulos/cap19_hf_hub.typ` · **C10, puente**

- El checklist del libro añadió: "El *bundle* publicado incluye el JSON Schema
  validado (Ap. G.4), no solo el Markdown." **Añadir este ítem** a
  `cap-checklist-alertas` (el stub ya tiene 4 ítems; este sería el 5.º, o reemplaza uno
  si se prefiere mantener 4).
- Sin slide nueva — un ítem de checklist.

#### Cap. 20 — CI/CD para modelos causales
`capitulos/cap20_cicd.typ` · **C10, puente**

- El *workflow* de CI ahora incluye un paso `python scripts/validar_schema.py` (valida
  el JSON Schema de la *model card* contra `causal-model-card-v1.schema.json`) dentro
  del job `tests-estadisticos`. **Añadir esa línea** al `cap-codigo-parte` del workflow
  YAML ya planificado en el stub.
- Sin slide nueva.

#### Cap. 21 — Aprendizaje de políticas óptimas
`capitulos/cap21_policy_learning.typ` · **C9, contenido nuevo**

- **C9 — EIF del policy value** (`@prop-policy-value-inference`, nueva, tras
  `@eq-policy-value-dr`): normalidad asintótica del estimador DR de $V(pi)$ vía su
  *efficient influence function*, y un test formal para comparar dos políticas
  ($V(pi_1)$ vs. $V(pi_2)$) — no solo reportar cada *welfare* por separado. **Añadir una
  `cap-teorema` nueva** (o extender la actual "EWM vs. Athey-Wager" con un tercer
  bloque) inmediatamente después de la fórmula de policy value doblemente robusta.
  Conecta directamente con la tabla de score canónico del Cap. 10 (fila "Policy
  value").
- **`cap-codigo-parte` (parte 1, policy learning):** el Listado 21.1 ahora incluye un
  bloque de código para el IC del policy value — añadir esas líneas al snippet ya
  planificado.
- **`cap-mapeo-pch-activo`:** métrica actual "V(π), regret sobre clase Π" → añadir
  "; IC vía EIF para comparar dos políticas".
- **`cap-discusion-ejercicio` candidato nuevo:** "¿Cuándo un test formal de
  comparación de políticas cambia la decisión que tomaría comparar solo los dos
  *welfare* estimados con sus IC individuales?"
- **`cap-cierre-narrativo` refs:** sin referencia nueva propia (C9 es resultado del
  propio libro, aplicando la EIF ya introducida en el Cap. 11/Ap. A).

#### Cap. 27 — Deep learning para inferencia causal
`capitulos/cap27_deep_causal.typ` · **C6, puente**

- La fila de riesgos "reportar $hat(tau)(x)$ sin incertidumbre" ahora incluye, además de
  "usar la red como *nuisance* dentro de DML" y "*bootstrap*", una tercera mitigación:
  **intervalos conformes para decisiones individuales** (Cap. 14, `@sec-cap07_conformal`).
  Añadir esa cláusula a `cap-errores-transiciones`.
- Sin slide nueva — una cláusula adicional en una fila ya planificada.

#### Cap. 30 — Monitoreo de supuestos causales en producción
`capitulos/cap30_monitoreo.typ` · **C11, puente**

- El docstring de `fuerza_instrumento()` ahora documenta un **doble umbral**: además de
  `F < 10` (alerta simple), el monitoreo puede reportar también el IC de
  Anderson–Rubin (Cap. 17) cuando $F<=10$. **Actualizar el `cap-codigo-parte`** de
  `fuerza_instrumento` en el stub para reflejar el doble umbral, no solo el `F<10`
  binario ya planificado.
- Sin slide nueva.

### 5.3 Apéndices — sin slides propias, pero citados desde capítulos ★

El curso no tiene mazos de diapositivas por apéndice (A–H), pero tres cambios de
Etapa 2 viven en apéndices y se citan desde capítulos que sí tienen slides — quedan
cubiertos como referencias/puentes en el §5.2 de arriba, no requieren un mazo nuevo:

- **Ap. A** (`apA_notacion_fundamentos.typ`): nota-puente de C3 (ambas *influence
  functions*, PLR e IRM, alcanzan la cota semiparamétrica) — referenciada desde el Cap.
  11.
- **Ap. B** (`apB_librerias_entorno.typ`): actualización de C7 (RScorer) — referenciada
  desde el Cap. 14.
- **Ap. E** (`apE_proyecto_rubrica.typ`): actualización de C8 (protocolo de tres
  niveles) — referenciada desde el Cap. 14.
- **Ap. G** (`apG_model_card_causal.typ`): **sección G.4 completa, nueva** — JSON
  Schema `causal-model-card-v1` con campo `dml_variant`. Es la fuente de los puentes en
  Caps. 15, 19 y 20 (§5.2). Si en algún momento se decide dar una slide propia a la
  *model card* como artefacto (fuera del Cap. 19), G.4 es el contenido a usar.

### 5.4 Bibliografía — 13 referencias nuevas de Etapa 2

Ninguna de las 32 diapositivas cita claves bibliográficas directamente (los stubs usan
prosa: "Chernozhukov et al., 2020", no `@chernozhukov2020generic`), así que esta lista
es solo para completar las líneas de `refs:` en `cap-cierre-narrativo` de los
capítulos afectados (ya indicado capítulo por capítulo en el §5.2):

`andrews2019robust`, `chernozhukov2020generic`, `cinellihazlett2020`,
`crump2009dealing`, `imbens2003sensitivity`, `kish1965`, `leicandes2021`,
`lei2018distribution`, `manski1990nonparametric`, `romano2019conformalized`,
`stock2002survey`, `tibshirani2019conformal`, `yadlowsky2021rate`.

### 5.5 Checklist de sincronización Etapa 2 (independiente del §4)

El §4 rastrea avance de contenido general (`stub` → `contenido` → `revisado` →
`listo`). Esta tabla rastrea, aparte, si cada capítulo afectado por Etapa 2 ya
incorporó su contenido nuevo — un capítulo puede estar "listo" en §4 con una versión
pre-Etapa 2 y aun así necesitar esta sincronización.

| Cap. | Cambios a incorporar | Slides nuevas est. | Estado |
|--:|---|:-:|---|
| 10 | C1 (tabla score canónico) + C2 (condiciones + DML1/DML2) | +1 (tabla nueva; DML1/DML2 fue 4.º paso en `cap-demostracion`) | listo |
| 11 | C1 (puente) + C2 (puente) + C3 (teorema eficiencia) + C4 (ESS/trimming) | +2 | listo |
| 12 | C1 (puente) + C4 (puente) | +0 (solo frases) | listo |
| 14 | C5 (BLP/BEST/CLAN) + C6 (conformal) + C7 (RATE) + C8 (3 niveles) | +4 (18 slides totales) | listo |
| 15 | C6 (puente) + C10 (puente) | +0 (solo líneas de código) | listo |
| 17 | C11 (Anderson-Rubin) | +1 | listo |
| 19 | C10 (puente) | +0 (1 ítem de checklist) | listo |
| 20 | C10 (puente) | +0 (1 línea de YAML) | listo |
| 21 | C9 (EIF policy value) | +1 | listo |
| 27 | C6 (puente) | +0 (1 cláusula) | listo |
| 30 | C11 (puente) | +0 (actualizar docstring) | listo |

Verificado: `./build.sh` → 32 OK, 0 FAIL (2026-08-12). Los 11 capítulos afectados
compilan limpio con el contenido de Etapa 2 incorporado; el resto de `capitulos/`
sigue con `// TODO(sprint)` sin tocar, como antes de esta sincronización.

**Total estimado:** 5 capítulos con al menos una slide nueva (10, 11, 14, 17, 21 — el
Cap. 14 suma 3–4 slides nuevas por sí solo, el resto del listado); 6 capítulos con solo
actualizaciones puntuales de texto/código, sin slide nueva (12, 15, 19, 20, 27, 30).
Ningún capítulo requiere reescribir slides ya planificadas desde cero; todos los
cambios son *aditivos* sobre el plan del §3.
