// =============================================================================
// Diapositivas · Capítulo 18 — Diseño de investigación y selección de método
// Fuente: 02_monografia/.../capitulos/cap10_mapa_decision.typ
// Plan detallado: PLAN_SPRINT_DIAPOSITIVAS.md §3, "Cap. 18"
// Sin sesión propia — guía de proyecto (S29-S32). Variante A · ◇
// =============================================================================
#import "../plantilla_monografia.typ": *

#show: cap-theme

#cap-init(num: 18, titulo: "Diseño de investigación y selección de método",
  parte: "III", sesion: "guía de proyecto", variant: "A", critico: false)

#cap-portada(num: 18, titulo: "Diseño de investigación y selección de método",
  parte: "III", sesion: "guía de proyecto", variant: "A", critico: false)

#cap-roadmap(
  objetivos: (
    [Ubicar un problema en el mapa de decisión metodológica (dimensión, heterogeneidad,
     endogeneidad, estructura temporal).],
    [Priorizar el diseño de mayor fuerza identificadora que sea factible.],
    [Reconocer el límite del mapa: elige estimador, no identificación.],
  ),
  agenda: (
    [¿DML? ¿DiD? ¿Control sintético? ¿Causal Forest?],
    [Mapa de decisión metodológica],
    [Jerarquía de identificación: RCT > IV/RDD > DiD/SCM > selección observable],
    [El límite de fondo del mapa],
  ),
  lectura: "Cap. 18 — Mapa de decisión (@cap-mapa-decision) — guía de proyecto, no es
    una sesión",
  lab: "—", entrega: "—",
)

#cap-motivacion(
  problema: "Banco Central: efecto de política monetaria sobre inflación, 10 años
    mensuales, 30 covariables, implementada en distintos momentos en distintos
    países. ¿DML? ¿DiD clásico? ¿Control sintético? ¿Causal Forest?",
  gancho: "La elección metodológica es la decisión más importante en inferencia
    causal aplicada — un método inadecuado produce conclusiones equivocadas sin
    importar la sofisticación de la implementación.",
  caso: "Guía que el estudiante consulta al elegir método para su proyecto final.",
)

#cap-definicion(
  titulo-def: "Mapa de decisión metodológica",
  cuerpo: "Seis dimensiones determinan el método: dimensión p vs. n, heterogeneidad,
    endogeneidad del tratamiento, estructura temporal, disponibilidad de instrumentos,
    objetivo de estimación (ATE/ATT/CATE/LATE/policy value). CORRECCIÓN: panel con
    staggered adoption → Callaway-Sant'Anna/Sun-Abraham/SDID — nunca TWFE.",
)

#cap-supuestos(supuestos: (
  ([RCT], [Fuerza alta], [Aleatorización del tratamiento]),
  ([IV / RDD], [Fuerza alta], [Relevancia+exclusión / continuidad local]),
  ([DiD / SCM], [Fuerza media], [Tendencias paralelas / combinación convexa]),
  ([Selección observable], [Fuerza media-baja], [No confusores no observados]),
))

// Contenido nuevo: el limite de fondo del mapa.
#cap-teorema(
  titulo: "El límite de fondo: el mapa elige estimador, no identificación",
  enunciado: "Las seis dimensiones son observables en los datos (n, p, si hay panel,
    si hay instrumento candidato). Las condiciones que determinan la VALIDEZ del
    resultado —si X cierra las rutas de puerta trasera, si el instrumento satisface
    exclusión, si las tendencias habrían sido paralelas— NO lo son. Un diseño de
    mayor fuerza identificadora mejora algo que ninguna cantidad de flexibilidad
    estadística compensa.",
)

#cap-mapeo-pch-activo(
  nivel: "Transversal (organiza todos los diseños de la Parte III)",
  metrica: "choose_method() como heurística de primer descarte",
  pregunta-activa: "Entre dos proyectos con el mismo n y p, uno con un RCT y otro con
    DML sobre datos observacionales — ¿cuál recomendaría empezar, y por qué la
    respuesta no depende de cuál estimador es \"más avanzado\"?",
)

#cap-discusion-ejercicio(
  pregunta: "¿Por qué DML no es adecuado cuando hay confusión no observada? ¿Qué
    alternativas existen?",
  ejercicio: "Para 5 problemas dados (RCT, reforma tributaria con p=100,
    staggered adoption, IV, heterogeneidad con n=20000), recomiende un método y
    justifique con la jerarquía de identificación.",
)

#cap-cierre-narrativo(
  resumen: (
    [El mapa organiza los diseños ya vistos; no introduce métodos nuevos.],
    [La jerarquía de identificación prioriza credibilidad del supuesto sobre
     sofisticación del estimador.],
    [El mapa no puede automatizar la pregunta de identificación — esa sigue siendo
     responsabilidad del analista.],
  ),
  refs: (
    [Athey & Imbens (2019), revisión de métodos modernos],
    [Imbens & Rubin (2015), métodos clásicos],
  ),
  transicion: "Cap. 19 — Model cards causales y publicación en Hugging Face Hub
    (Parte IV, S17)",
  gancho: "Con el estimador elegido y validado, el Cap. 15 ya lo sirvió — falta
    publicarlo donde otros lo encuentren y lo audite un pipeline, no solo una
    persona.",
)
