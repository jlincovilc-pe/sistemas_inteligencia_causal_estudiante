// =============================================================================
// Diapositivas · Capítulo 7 — Datos de entrenamiento en sistemas causales
// Fuente: 02_monografia/.../capitulos/cap02b_datos_entrenamiento.typ
// Plan detallado: PLAN_SPRINT_DIAPOSITIVAS.md §3, "Cap. 7"
// Sesión S6 · Lab L06 · Entrega: A1 entrega · Variante B · ★ camino crítico
// =============================================================================
#import "../plantilla_monografia.typ": *

#show: cap-theme

#cap-init(num: 7, titulo: "Datos de entrenamiento en sistemas causales",
  parte: "I", sesion: "S6", variant: "B", critico: true)

#cap-progreso-curso(cap-actual: 7)
#cap-portada(num: 7, titulo: "Datos de entrenamiento en sistemas causales",
  parte: "I", sesion: "S6", variant: "B", critico: true)

#cap-roadmap(
  objetivos: (
    [Documentar el mecanismo de asignación de un dataset en una ficha de procedencia.],
    [Ejecutar un chequeo de balance con SMD y criterio de Rubin — no t-tests.],
    [Distinguir un desbalance esperado de una señal de que el mecanismo real difiere
     del documentado.],
  ),
  agenda: (
    [Auditar el mecanismo de asignación antes de estimar],
    [Ficha de procedencia del tratamiento],
    [Chequeo de balance: SMD, razón de varianzas, Holm],
    [Caso: Lalonde experimental vs. observacional],
  ),
  lectura: "Cap. 7 — Datos de entrenamiento (@cap-datos-entrenamiento-causales)",
  lab: "L06", entrega: "A1 entrega",
)

#cap-problema-diseno(
  decision: "Tratar la asignación del tratamiento como parte del proceso de muestreo a
    auditar, no como un dato dado.",
  alternativas: "Usar los datos \"tal como llegan\" vs. auditar explícitamente el
    mecanismo de asignación.",
  tradeoff: "Velocidad de arranque vs. riesgo de sesgo de selección no detectado.",
  stack: "pandas, pandera, statsmodels.stats.multitest (Holm).",
  riesgo: "Confundir \"faltante al azar\" con \"faltante por selección relacionada al
    tratamiento\".",
)

#cap-opciones-tradeoffs(opciones: (
  ([Usar los datos tal como llegan], [Más rápido; el mecanismo de asignación queda
    implícito y cualquier sesgo de selección no observado nunca se detecta porque nadie
    lo buscó.]),
  ([Auditar el mecanismo antes de estimar], [Documenta si la asignación fue
    aleatorizada, cuasi-aleatorizada u observacional pura — revela qué covariables son
    plausiblemente suficientes antes de ajustar ningún modelo.]),
))

#cap-decision-referencia(
  decision: "Ficha de procedencia del tratamiento (extensión del CausalSchema, Cap. 4):
    mecanismo de asignación, unidad temporal de la asignación respecto al resultado,
    reglas de elegibilidad conocidas.",
  justificacion: "Es la versión operacional del \"problema causal, estimando e
    identificación\" que abre cada capítulo de teoría, aplicada como paso de
    ingeniería concreto y verificable.",
)

#cap-codigo-parte(
  titulo: "Chequeo de balance — SMD y criterio de Rubin",
  snippet: "# TODO(sprint): pegar el listado @lst-chequeo-balance (reescrito en la
# mejora de contenido): SMD = (media_trat - media_ctrl) / s_pool; criterio de Rubin
# |SMD|<0.25 y razon_varianzas en [0.5,2]; correccion de Holm sobre p-valores;
# faltantes diferenciales tratados/controles.",
  invariante: "# n_desbalance_smd = (smd.abs() > 0.25).sum()  # NO usar solo p<0.05",
)

#cap-caso-resolucion(
  titulo: "Lalonde/NSW: experimental vs. observacional",
  contexto: "La submuestra experimental tiene asignación aleatorizada por diseño; la
    extensión observacional de Dehejia-Wahba no la tiene. Mismo tratamiento, mismo
    resultado.",
  resultado: "Experimental: SMD pequeñas en todas las covariables. Observacional: SMD
    grandes en varias, razones de varianza fuera de [0.5, 2].",
  interpretacion: "Comparar la distribución completa de SMD entre ambas versiones es la
    forma más directa de ver qué significa \"como aleatorizado\" en números.",
)

#cap-mapeo-pch-activo(
  nivel: "Transversal (auditoría previa a cualquier estimación de L2)",
  metrica: "Distribución de SMD por covariable; razón de varianzas",
  pregunta-activa: "Un SMD de 1.5 en una covariable relevante — ¿qué le dice sobre
    cuánta extrapolación hará el estimador antes de ver un solo propensity score?",
)

#cap-checklist-alertas(items: (
  [Nadie en el equipo puede explicar en una oración cómo se decidió quién recibía el
   tratamiento.],
  [No se ejecutó ningún chequeo de balance antes de estimar el efecto.],
  [Existen faltantes en Y sistemáticamente relacionados con el tratamiento.],
  [La ficha de procedencia no distingue si la asignación fue anterior o posterior a
   alguna covariable de control.],
))

#cap-interactivo(
  tipo: "Aplicado",
  pregunta: "¿Por qué un desbalance fuerte en una covariable administrativa, sin
    relación aparente con el criterio de elegibilidad, es una señal más seria que un
    desbalance en una covariable directamente relacionada con dicho criterio?",
)

#cap-discusion-ejercicio(
  pregunta: "Sobre la submuestra experimental, compare cuántas covariables resultan
    \"significativas\" con p crudo al 5% frente a corrección de Holm. ¿Qué dice el
    primer número sobre si la aleatorización falló?",
  ejercicio: "Aplique el chequeo de balance a las dos versiones de Lalonde. Reporte la
    distribución de SMD y cuántas covariables violan cada criterio de Rubin en cada
    una.",
)

#cap-cierre-narrativo(
  resumen: (
    [El mecanismo de asignación se audita, no se asume.],
    [SMD + criterio de Rubin + Holm reemplaza al t-test sin corregir.],
    [Un desbalance no invalida el análisis por sí solo — cuantifica cuánta
     extrapolación hará el estimador.],
  ),
  refs: (
    [Rubin (2001), criterios de balance para diseño observacional],
    [LaLonde (1986) / Dehejia & Wahba (1999), el caso NSW],
    [Rubin (1976), MCAR/MAR/MNAR],
  ),
  transicion: "Cap. 8 — Razonamiento intervencional y contrafactual",
  gancho: "Con datos auditados, falta el criterio formal para decidir qué controlar —
    el error de \"controlar por todo\" es más costoso que omitir un confusor.",
)
