// =============================================================================
// Diapositivas · Capítulo 4 — Ingeniería de datos para sistemas causales
// Fuente: 02_monografia/.../capitulos/cap00d_ingenieria_datos.typ
// Plan detallado: PLAN_SPRINT_DIAPOSITIVAS.md §3, "Cap. 4"
// Sesión S4 · Lab L04 · Entrega: A1 arranca · Variante B · ★ camino crítico
// =============================================================================
#import "../plantilla_monografia.typ": *

#show: cap-theme

#cap-init(num: 4, titulo: "Ingeniería de datos para sistemas causales",
  parte: "I", sesion: "S4", variant: "B", critico: true)

#cap-progreso-curso(cap-actual: 4)
#cap-portada(num: 4, titulo: "Ingeniería de datos para sistemas causales",
  parte: "I", sesion: "S4", variant: "B", critico: true)

#cap-roadmap(
  objetivos: (
    [Declarar un CausalSchema con roles tratamiento/resultado/covariables/instrumentos.],
    [Explicar por qué un rol causal es una afirmación sobre identificación, no sobre
     tipo de dato.],
    [Completar el arranque del Notebook A1.],
  ),
  agenda: (
    [¿Qué rol estructural juega cada columna?],
    [Tabla ancha vs. esquema con roles etiquetados],
    [Decisión: CausalSchema obligatorio],
    [Implementación de referencia],
    [Aplicación: A1 y B1 comparten el mismo esquema],
  ),
  lectura: "Cap. 4 — Ingeniería de datos (@cap-ingenieria-datos-causales)",
  lab: "L04", entrega: "A1 arranca",
)

#cap-problema-diseno(
  decision: "Adoptar un esquema explícito de roles causales sobre los datos, no solo un
    esquema de tipos.",
  alternativas: "Tabla ancha sin metadatos vs. esquema con roles etiquetados
    (tratamiento/resultado/covariable/instrumento).",
  tradeoff: "Velocidad de prototipado vs. prevención sistemática de errores de
    identificación.",
  stack: "pandas, Parquet o CSV+metadata.json, pandera (validación de esquema).",
  riesgo: "Que el tratamiento se filtre como covariable, o que una variable
    post-tratamiento contamine X.",
)

#cap-opciones-tradeoffs(opciones: (
  ([Tabla ancha sin metadatos], [Nombres de columna hardcodeados por notebook. Rápida
    para un análisis único; dos notebooks pueden definir X de forma sutilmente
    distinta sin que nadie lo note.]),
  ([Esquema con roles etiquetados], [Se declara en un único lugar qué es D, Y, X e
    instrumentos. Fricción inicial a cambio de hacer sintácticamente imposible pasar el
    tratamiento como covariable por accidente.]),
))

#cap-decision-referencia(
  decision: "CausalSchema con 4 listas (treatment/outcome/covariates/instruments).
    Formato preferido: Parquet con metadatos embebidos; CSV + metadata.json versionado
    es aceptable si el esquema viaja siempre junto a los datos.",
  justificacion: "Lo que la decisión fija es que el esquema exista y sea la única
    fuente de verdad sobre los roles — no el formato de serialización. Etiquetar una
    columna como covariates es una afirmación causal (satisface puerta trasera), no de
    tipo de dato.",
)

#cap-codigo-parte(
  titulo: "CausalSchema — parte 1",
  snippet: "# TODO(sprint): pegar el listado @lst-causal-schema (líneas 55-94 del
# capítulo fuente): @dataclass CausalSchema con .validate(), .X(), .D(), .Y().
# Ejemplo: schema para close_college (Card, 1995).",
  invariante: "# schema.validate(df)  # lanza ValueError si D/Y quedan también en X",
)

#cap-monorepo(texto-monorepo: "data_benchmark_causal/.../datasets/ como CSV +
  metadata.json (no Parquet obligatorio). Roles resueltos con lib.data_io.load_scenario
  y lib.schema.CausalSchema.from_scenario(\"real/jobs\"). Labs: L04-L06. Entrega:
  Notebook A1 (Jobs). Stack: 03_notebooks_caso_estudio/lib/.")

#cap-caso-resolucion(
  titulo: "El mismo esquema en A1 y en B1",
  contexto: "El Notebook A1 exige construir el CausalSchema antes de correr cualquier
    estimación, forzando la pregunta de identificación a un paso de ingeniería
    verificable.",
  resultado: "El mismo esquema reaparece sin cambios en el Notebook B1 (Cap. 15): la
    función de inferencia en producción usa schema.covariates para saber exactamente
    qué columnas esperar del cliente.",
  interpretacion: "Cierra el círculo entre el notebook de entrenamiento y el servicio
    desplegado — el esquema es el contrato entre ambos.",
)

#cap-mapeo-pch-activo(
  nivel: "Transversal (precondición para cualquier estimación de L2)",
  metrica: "CausalSchema válido: D, Y, X e instrumentos sin solapamiento",
  pregunta-activa: "¿Puede el mismo dataset producir dos estimaciones distintas del
    ATE en dos notebooks solo porque cada uno definió X de forma distinta?",
)

#cap-checklist-alertas(items: (
  [El nombre de la columna de tratamiento aparece hardcodeado en más de un notebook.],
  [Ninguna función de carga valida que D e Y no estén también en covariates.],
  [No hay forma de saber, sin leer el código, si una covariable fue medida después del
   tratamiento.],
  [El esquema de roles no viaja junto con los datos (ni en el archivo ni en un
   metadata.json versionado a su lado).],
))

#cap-interactivo(
  tipo: "Aplicado",
  pregunta: "Para el dataset de becas del Cap. 1, proponga tres covariables legítimas y
    una variable post-tratamiento que sería incorrecto incluir. Justifique.",
)

#cap-discusion-ejercicio(
  pregunta: "¿Por qué un esquema de roles causales explícito importa más en un sistema
    con varios notebooks y colaboradores que en un análisis individual de una sola
    vez?",
  ejercicio: "Extienda CausalSchema con un método summary() que imprima, para cada rol,
    el número de valores faltantes y el tipo de dato. Aplíquelo al dataset del
    Notebook A1.",
)

#cap-cierre-narrativo(
  resumen: (
    [Un rol causal (D/Y/X/instrumento) es una afirmación sobre identificación, no
     sobre tipo de dato.],
    [CausalSchema hace sintácticamente imposible pasar D como covariable por
     accidente.],
    [El mismo esquema conecta A1 (entrenamiento) con B1 (servicio, Cap. 15).],
  ),
  refs: (
    [Huyen (2022), *Designing Machine Learning Systems*, Cap. 3],
    [Sculley et al. (2015), deuda técnica en sistemas de ML],
  ),
  transicion: "Cap. 6 — Regularización, selección de variables y sesgo post-selección
    (S5; el Cap. 5 es lectura de refuerzo, sin sesión propia)",
  gancho: "El esquema dice qué es cada columna; falta decidir cuáles de las
    covariables entran al modelo sin sesgar la inferencia.",
)
