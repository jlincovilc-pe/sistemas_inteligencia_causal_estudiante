// Cómo usar este libro
#import "../template/template.typ": *

#chapter[Cómo usar este libro]
<sec-como-usar>

Esta monografía está organizada en nueve partes temáticas que agrupan los treinta y dos capítulos del curso. A diferencia de la edición anterior, no todos los capítulos siguen la misma plantilla: el libro alterna entre capítulos de teoría e identificación causal (Plantilla A) y capítulos de ingeniería y producción (Plantilla B), diseñados para enseñarse de forma distinta porque responden preguntas de naturaleza distinta.

== Dos plantillas de capítulo

*Plantilla A — teoría e identificación causal.* Sigue la estructura de siete secciones ya usada en la edición anterior del libro: (i) problema, estimando e identificación; (ii) teoría, supuestos y garantías, con definiciones y teoremas formales; (iii) algoritmo e implementación en Python; (iv) caso empírico; (v) riesgos, límites y sensibilidad; (vi) ejercicios; (vii) notas bibliográficas. Responde la pregunta "¿cómo se estima esto correctamente?".

*Plantilla B — ingeniería y producción.* Nueva en esta edición, sigue la filosofía de _Designing Machine Learning Systems_ (Huyen, 2022): no es una plantilla de recetas únicas sino de decisiones de diseño con costos y beneficios explícitos. Sus siete secciones son: (i) el problema de diseño; (ii) opciones y trade-offs, comparando al menos dos alternativas reales; (iii) la decisión de referencia adoptada para el sistema de ejemplo del curso; (iv) una implementación de referencia (código, configuración); (v) la aplicación específica al sistema causal del curso; (vi) señales de alerta y checklist operativo; (vii) ejercicios y notas bibliográficas. Responde la pregunta "¿cómo se lleva esto a producción de forma responsable?".

Ambas plantillas comparten el mismo cuadro resumen al inicio del capítulo (llamado *cuadro sinóptico* en los capítulos de Plantilla A y *cuadro de decisión* en los de Plantilla B) y el mismo sistema de referencias cruzadas, numeración de figuras/tablas/listados por capítulo, y checklists.

== Partes del libro

#table(
  columns: (auto, 3.2fr, 1fr),
  align: (left, left, center),
  stroke: 0.5pt + gray.lighten(60%),
  table.header([*Parte*], [*Contenido*], [*Caps.*]),
  [0], [Introducción: causalidad elemental y anatomía de un sistema de ML en producción.], [1–2],
  [I], [Fundamentos estructurales y de datos: SCM, Jerarquía Causal de Pearl, regularización, criterio de puerta trasera, ingeniería de datos y *features* sin fuga causal.], [3–9],
  [II], [Estimación causal flexible y primer despliegue: ortogonalidad, DML, meta-learners, bosques causales, validación, y el primer servicio desplegado del curso.], [10–15],
  [III], [Diseños de identificación con ML: Post-Double-Selection, panel e instrumentos, mapa de decisión metodológica.], [16–18],
  [IV], [Publicación y operación en producción: *model cards* causales en Hugging Face Hub, CI/CD.], [19–20],
  [V], [Heterogeneidad, políticas y *targeting*: *policy learning*, *uplift modeling*.], [21–22],
  [VI], [Explicación, equidad y decisión estructural: descomposición causal de la equidad, interpretabilidad, decisiones bajo incertidumbre, transportabilidad.], [23–26],
  [VII], [Métodos avanzados: *deep learning* causal, control sintético y *matrix completion*.], [27–28],
  [VIII], [Estructura, monitoreo y frontera: descubrimiento de grafos, monitoreo en producción, aprendizaje continuo, panorama de RL causal, y comunicación de resultados.], [29–32],
)

== Elementos pedagógicos

El libro utiliza los siguientes elementos visuales recurrentes:

- *Cuadros sinópticos / de decisión:* resumen ejecutivo del capítulo.
- *Algoritmos:* pseudocódigo numerado globalmente (capítulos de Plantilla A).
- *Opciones y trade-offs, decisión de referencia:* comparación explícita de alternativas de diseño (capítulos de Plantilla B).
- *Tablas de riesgos:* riesgos, consecuencias, diagnósticos y mitigaciones.
- *Checklists:* listas de verificación de validación o de señales de alerta operativas.
- *Notas técnicas:* detalles matemáticos opcionales o enlaces entre capítulos.
- *Apéndices:* fundamentos matemáticos (A), guía de librerías (B), datos y DGP (C), glosario (D), plantilla de proyecto (E), checklists por método (F), plantilla de *model card* causal (G) y checklist de arquitectura de despliegue (H).

== Audiencia profesional y camino crítico

Este libro se lee junto al *monorepo del curso*. El camino crítico para profesionales (★) prioriza: identificación y datos (Caps. 1–4, 6–9) → DML y validación (10–11, 14) → primer servicio HF (15) → CATE y policy (12–13, 21–22) → Hub/CI (19–20) → explicación y decisión (23–26) → monitoreo y comunicación (29–32). Los Caps. *16–18* y *27–28* son profundización electiva (◇): útiles, pero no bloquean desplegar un sistema en Hugging Face.

*Pregunta de valor (repetir en cada bloque).* Si solo predijéramos el outcome, ¿a quién trataríamos? Si estimamos el efecto, ¿cambia el ranking, el presupuesto o el riesgo?

== Mapa sesión → capítulo → lab → entrega (resumen)

La tabla completa está en el sílabo y en #code[PLAN_INTEGRACION_MONOGRAFIA.md]. Resumen del hilo de producto:

#table(
  columns: (auto, 1.4fr, auto, 1.2fr, 1.6fr),
  align: (left, left, left, left, left),
  stroke: 0.5pt + gray.lighten(60%),
  table.header([*Sesiones*], [*Caps. monografía*], [*Lab*], [*Entrega*], [*Valor de negocio*]),
  [S1–S3], [1–3], [L01–L03], [—], [Asociación vs efecto; PCH],
  [S4–S6], [4, 6–7], [L04–L06], [*A1*], [¿Es estimable el programa?],
  [S7–S11], [8–11, 14], [L07–L11], [*A2*], [ATE con IC; sin leakage],
  [S12–S14], [12–13, 15], [L12–L14], [*B1* + A3], [API del efecto; CATE],
  [S15–S16], [repaso], [L15], [*A3* · parcial], [Sistema causal integrado],
  [S17–S18], [19–20], [L17–L18], [*B2*], [Hub + model card + CI],
  [S19–S24], [21–26], [L19–L24], [*A4* · *B3*], [Policy + Space HF],
  [S25–S28], [29–32], [L25–L28], [*B4*], [Monitoreo y comunicación],
  [S29–S32], [Ap. E/G/H], [P1–P4], [*Proyecto*], [Tu caso en producción HF],
)

== Dos series de notebooks y el monorepo

El trabajo práctico se organiza en el monorepo del curso (no en un repositorio externo opcional):

- *Labs L01–L28* (#code[05_labs_sesion/]): práctica formativa por sesión (30–50 min).
- *Serie A* (#code[03_notebooks_caso_estudio/]): A1 identificación (Jobs) · A2 DML · A3 CATE · A4 policy.
- *Serie B* (#code[04_notebooks_produccion_hf/]): B1 FastAPI · B2 Hub/CI · B3 Gradio Space · B4 dashboard de drift.
- *Datos* (#code[data_benchmark_causal/.../datasets/]): CSV + #code[metadata.json] (benchmark documentado; ver callouts "monorepo" en los capítulos de ingeniería).
- *Proyecto* (#code[06_proyecto_final/]): sistema causal en HF con comparación *predictivo vs causal*.

La *Serie A* aplica la teoría a un caso con pregunta de identificación. La *Serie B* toma el artefacto de A y lo despliega en Hugging Face. El sílabo (#code[01_silabo/silabo.pdf]) fija la correspondencia exacta sesión ↔ Cap. N del PDF ↔ lab ↔ entrega.

== Cómo leer un capítulo de ingeniería (Plantilla B)

1. Cuadro de decisión (trade-offs).  
2. Problema de diseño *específico de un sistema causal*.  
3. Opciones reales (no una sola receta).  
4. Decisión de referencia del curso.  
5. Implementación (y, si aplica, el callout del monorepo).  
6. Checklist operativo / alertas.  
7. Lab o notebook de la semana.
