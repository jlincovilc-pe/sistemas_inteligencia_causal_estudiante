// =============================================================================
// Diapositivas · Capítulo 3 — Modelos Causales Estructurales y la Jerarquía
// Causal de Pearl
// Fuente: 02_monografia/.../capitulos/cap00c_scm_pch.typ
// Plan detallado: PLAN_SPRINT_DIAPOSITIVAS.md §3, "Cap. 3"
// Sesión S3 · Lab L03 · sin entrega · Variante A · ★ camino crítico
// =============================================================================
#import "../plantilla_monografia.typ": *

#show: cap-theme

#cap-init(num: 3, titulo: "Modelos Causales Estructurales y la Jerarquía Causal de Pearl",
  parte: "I", sesion: "S3", variant: "A", critico: true)

#cap-progreso-curso(cap-actual: 3)
#cap-portada(num: 3, titulo: "Modelos Causales Estructurales y la Jerarquía Causal de Pearl",
  parte: "I", sesion: "S3", variant: "A", critico: true)

#cap-roadmap(
  objetivos: (
    [Escribir la definición formal de un SCM.],
    [Distinguir los tres niveles de la PCH y qué información mínima requiere cada uno.],
    [Enunciar el Teorema de la Jerarquía Causal y explicar por qué es la razón formal
     — no solo intuitiva — de la tesis del Cap. 1.],
  ),
  agenda: (
    [Formalizar "causa" matemáticamente],
    [Definición de SCM],
    [Los tres niveles de la PCH],
    [Teorema de la Jerarquía Causal],
    [Verificación de consistencia del grafo],
  ),
  lectura: "Cap. 3 — SCM y PCH (@cap-scm-pch)",
  lab: "L03", entrega: "—",
)

#cap-motivacion(
  problema: "¿Qué objeto matemático representa completamente un sistema causal, y qué
    tres tipos de pregunta —y solo tres— se le pueden hacer?",
  gancho: "Los resultados potenciales del Cap. 1 son naturales para un tratamiento y un
    resultado; los SCM son naturales para sistemas con muchas variables relacionadas —
    el tipo de sistema que aparece en un pipeline de producción.",
  caso: "SCM simulado de becas y calificaciones con motivación no observada U.",
)

#cap-glosario(terminos: (
  ([SCM], [Tupla ⟨U, V, F, P(u)⟩: exógenas, endógenas, funciones estructurales,
    distribución de fondo.]),
  ([L1 — Asociación], [P(v): la distribución observacional, sin modificar M.]),
  ([L2 — Intervención], [P(y | do(x)): distribución tras reemplazar la ecuación de X por
    la constante x.]),
  ([L3 — Contrafactual], [P(y_x | e): abducción → acción → predicción.]),
))

#cap-definicion(
  titulo-def: "SCM (Modelo Causal Estructural)",
  cuerpo: "M = ⟨U, V, F, P(u)⟩. Cada V_i = f_i(pa_i, U_i). El grafo inducido no es una
    descripción estadística: cada ecuación representa un mecanismo real, no una
    relación ajustada a los datos.",
  eq: $M = (U, V, F, P(u))$,
)

// TODO(sprint): no hay #assumption formal en este capítulo; usar cap-supuestos con la
// tabla de los tres niveles (P(v) / P(y|do(x)) / P(y_x|e), líneas 51-59 del capítulo
// fuente) en vez de una tabla de supuestos de identificación.
#cap-supuestos(supuestos: (
  ([L1 — Asociación], [Se calcula con los datos observados, sin modificar M],
   [Filtrar df[df.D==1] ≠ intervenir]),
  ([L2 — Intervención], [Requiere el SCM "quirúrgicamente modificado"],
   [do(D=1): se borra f_D y se fija D=1]),
  ([L3 — Contrafactual], [Requiere abducción-acción-predicción],
   [Condiciona en evidencia observada de una unidad específica]),
))

#cap-teorema(
  titulo: "Teorema de la Jerarquía Causal (Causal Hierarchy Theorem)",
  enunciado: "El conjunto de SCM para los cuales las distribuciones de nivel L_(k+1)
    quedan determinadas por las de nivel L_k tiene medida cero, para k=1,2. Salvo un
    conjunto excepcional, dos SCM distintos pueden inducir la misma P(v) y distintas
    P(y|do(x)). Bareinboim, Correa, Ibeling & Icard (2022).",
  ref-apendice: "sección @thm-cht del capítulo fuente",
)

#cap-demostracion(pasos: (
  [Definir una medida de probabilidad natural sobre el espacio Ω de SCM (funciones
   estructurales + distribuciones exógenas).],
  [Mostrar que el subconjunto de SCM "colapsables" (donde un nivel determina al
   siguiente) tiene medida cero en Ω.],
  [Consecuencia operativa: todo método de estimación causal debe importar información
   extra-datos — un supuesto de identificación — porque la información simplemente no
   está en P(v).],
))

#cap-interactivo(
  tipo: "Conceptual",
  pregunta: "¿Es \"df[df.D==1]\" una observación o una intervención? ¿Cuándo coinciden
    P(y|X=x) y P(y|do(x))?",
)

#cap-codigo-parte(
  titulo: "SCM simulado: asociación vs. intervención — parte 1",
  snippet: "# TODO(sprint): pegar el listado @lst-scm-do-simulacion (líneas 77-110 del
# capítulo fuente): U motivación no observada, D_obs depende de U, Y_obs depende de
# D_obs y U (efecto causal verdadero = 0.4). Calcular P(Y|D=1) vs. P(Y|do(D=1)).",
  invariante: "# assert abs(intervencion - 0.4) < 0.05  # recupera el efecto verdadero",
)

#cap-caso-resolucion(
  titulo: "Consistencia del grafo con close_college (Card, 1995)",
  contexto: "Un grafo que supone que nearc4 afecta educ pero no directamente wage,
    controlando por educ, implica una independencia condicional testeable.",
  resultado: "nearc4 ⊥ wage | educ + controles — verificable con dowhy/causal-learn
    (test de independencia condicional). Necesario, no suficiente: varios grafos pueden
    ser observacionalmente equivalentes (CPDAG, Cap. 29).",
  interpretacion: "Un test estadístico puede refutar un grafo, nunca confirmarlo como
    \"el verdadero\".",
)

#cap-mapeo-pch-activo(
  nivel: "L1, L2 y L3 — los tres formalizados por primera vez en este capítulo",
  metrica: "P(v), P(y | do(x)), P(y_x | evidencia)",
  pregunta-activa: "¿Por qué ningún test de independencia condicional puede confirmar
    que un grafo es \"el verdadero\", solo refutarlo?",
)

#cap-errores-transiciones(
  errores: (
    ("crítico", [Confundir P(y|X=x) con P(y|do(x)) — el error más frecuente al empezar
      en inferencia causal.]),
    ("advertencia", [Asumir que el grafo es "el verdadero": un SCM formaliza supuestos,
      no los verifica.]),
    ("advertencia", [Tratar L3 como si fuera L2: una pregunta contrafactual individual
      no se responde con el procedimiento de una pregunta interventiva poblacional.]),
  ),
  conexiones: "El criterio de puerta trasera (Cap. 8) es la versión operacional de
    'qué controlar' para llegar de L1 a L2 en la práctica.",
)

#cap-discusion-ejercicio(
  pregunta: "Dé un ejemplo de dos SCM distintos que induzcan la misma P(v) pero
    distinta P(y|do(x)).",
  ejercicio: "Modifique el listado de simulación para que el efecto causal verdadero
    sea 0 (sin efecto), manteniendo la confusión vía U. Verifique que la diferencia
    asociativa sigue siendo distinta de cero mientras el efecto interventivo converge a
    0.",
)

#cap-cierre-narrativo(
  resumen: (
    [Un SCM es una tupla ⟨U,V,F,P(u)⟩; equivalente formalmente a resultados
     potenciales.],
    [Los tres niveles de la PCH requieren información estrictamente creciente.],
    [El Teorema de la Jerarquía Causal es la razón formal de que los datos
     observacionales solos no respondan preguntas causales.],
  ),
  refs: (
    [Bareinboim, Correa, Ibeling & Icard (2022), "On Pearl's Hierarchy..."],
    [Pearl (2009), *Causality*, 2.ª ed.],
    [Imbens & Rubin (2015), equivalencia SCM ↔ resultados potenciales],
  ),
  transicion: "Cap. 4 — Ingeniería de datos para sistemas causales",
  gancho: "El SCM formaliza qué es una variable causal; falta formalizar qué rol juega
    cada columna de un dataset real.",
)
