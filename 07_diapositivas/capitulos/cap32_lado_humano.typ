// =============================================================================
// Diapositivas · Capítulo 32 — El lado humano de los sistemas causales
// Fuente: 02_monografia/.../capitulos/cap15d_lado_humano.typ
// Plan detallado: PLAN_SPRINT_DIAPOSITIVAS.md §3, "Cap. 32"
// Sesión S28 · Lab L28 · Entrega: B4 entrega · Variante B · ★ camino crítico
// Último capítulo del curso — no hay Cap. 33; la transición apunta al proyecto final.
// =============================================================================
#import "../plantilla_monografia.typ": *

#show: cap-theme

#cap-init(num: 32, titulo: "El lado humano de los sistemas causales",
  parte: "VIII", sesion: "S28", variant: "B", critico: true)

#cap-progreso-curso(cap-actual: 32)
#cap-portada(num: 32, titulo: "El lado humano de los sistemas causales",
  parte: "VIII", sesion: "S28", variant: "B", critico: true)

#cap-roadmap(
  objetivos: (
    [Redactar un resultado causal con la plantilla de tres capas.],
    [Aplicar las tres regularidades de comunicación de riesgo (Spiegelhalter,
     2019).],
    [Cerrar el proyecto final con el mismo estándar de honestidad de todo el
     libro.],
  ),
  agenda: (
    [La diferencia "X predice Y" / "X causa Y" se pierde primero al comunicar],
    [Comunicación simplificada vs. con supuestos e incertidumbre explícitos],
    [Plantilla de tres capas],
    [Tres regularidades de Spiegelhalter y la asimetría de costos],
    [Cierre del curso: de la Sesión 1 a la comunicación de tres capas],
  ),
  lectura: "Cap. 32 — Lado humano (@cap-lado-humano)",
  lab: "L28", entrega: "B4 entrega",
)

#cap-problema-diseno(
  decision: "Comunicar resultados causales con sus supuestos e incertidumbre
    explícitos, incluso a audiencias no técnicas.",
  alternativas: "Comunicación simplificada (solo el número/la historia) vs. con
    supuestos e incertidumbre explícitos.",
  tradeoff: "Claridad y persuasión inmediata vs. honestidad sobre los límites del
    hallazgo.",
  stack: "Plantilla de tres capas (Markdown).",
  riesgo: "Que un resultado válido bajo supuestos se comunique y use como verdad
    incondicional.",
)

#cap-opciones-tradeoffs(opciones: (
  ([Comunicación simplificada], ["El programa aumenta el ingreso en 12%." Clara y
    persuasiva; omite bajo qué supuestos, para qué población, con qué
    incertidumbre.]),
  ([Con supuestos e incertidumbre explícitos], ["...en 12% (IC 95%: 8-16%), sobre la
    población que participó, bajo no confusión." Honesta y auditable; puede sonar a
    que el equipo "no está seguro de nada" sin cuidado en la forma.]),
))

#cap-decision-referencia(
  decision: "Estructura de tres capas: (i) hallazgo en una oración, lenguaje no
    técnico; (ii) supuestos e incertidumbre en un párrafo; (iii) detalle técnico
    completo para quien audite.",
  justificacion: "Es la misma estructura de la model card causal del Cap. 19,
    aplicada ahora a la comunicación con personas y no solo a la documentación de un
    artefacto.",
)

#cap-codigo-parte(
  titulo: "Plantilla de comunicación de tres capas",
  snippet: "## Hallazgo\n"
    + "[Una oracion, en lenguaje no tecnico, sin jerga estadistica.]\n\n"
    + "## Lo que esto significa (y lo que no)\n"
    + "- Poblacion para la que es valido: [...]\n"
    + "- Principal supuesto detras del resultado: [...]\n"
    + "- Incertidumbre: [IC 95%, en unidades que la audiencia entienda]\n"
    + "- Este resultado NO implica: [el efecto no se aplica fuera del rango estudiado]\n\n"
    + "## Detalle tecnico\n"
    + "[Enlace al notebook / proyecto / model card completos]",
  nota: "Tres capas: hallazgo / supuestos e incertidumbre / detalle tecnico. Es la
    misma estructura de la model card causal del Cap. 19, aplicada a personas: quien
    audita llega a la capa 3, quien decide necesita las capas 1-2.",
)

// Contenido nuevo: tres regularidades de comunicacion de riesgo y la asimetria de
// costos entre sobre- y subestimar la certeza.
#cap-caso-resolucion(
  titulo: "Tres regularidades de Spiegelhalter (2019)",
  contexto: "La forma de comunicar la incertidumbre no es neutral.",
  resultado: "(1) Frecuencias naturales se retienen mejor que porcentajes: '8 a 16 de
    cada 100 hogares' vs. '12% (IC 8-16%)'. (2) Riesgos relativos exageran: 'duplica
    la probabilidad' engaña si la base es 0.1% — reportar siempre el cambio
    absoluto. (3) Explicitar sobre qué población aplica el número.",
  interpretacion: "Asimetría de costos: sobreestimar la certeza produce decisiones
    que fallan SILENCIOSAMENTE (se implementa, no funciona, rara vez se atribuye al
    análisis); subestimarla produce, en el peor caso, que se posponga. Solo el
    primer error se disfraza de éxito.",
)

#cap-mapeo-pch-activo(
  nivel: "Transversal — cierre del hilo completo del curso",
  metrica: "Plantilla de tres capas completa para el proyecto final",
  pregunta-activa: "El Cap. 1 abrió con \"¿asociación o causa?\". Treinta y un
    capítulos después, ¿qué parte de esa distinción sobrevive en el titular de una
    sola oración de su proyecto?",
)

#cap-checklist-alertas(items: (
  [El resumen ejecutivo no menciona ningún supuesto ni intervalo de incertidumbre.],
  [Nadie fuera del equipo técnico sabe para qué población el efecto es válido.],
  [La comunicación usa lenguaje causal para un resultado que solo respalda una
   afirmación asociativa.],
  [No existe una versión accesible (capas 1-2); solo el notebook técnico
   completo.],
))

#cap-interactivo(
  tipo: "Aplicado",
  pregunta: "Describa una comunicación simplificada que llevó, o pudo llevar, a una
    decisión que el resultado técnico no respaldaba realmente.",
)

#cap-discusion-ejercicio(
  pregunta: "Tome el resultado de su proyecto y redáctelo con la plantilla de tres
    capas. ¿Qué información se pierde en la capa 1 que un lector técnico echaría de
    menos?",
  ejercicio: "Complete la plantilla de comunicación de tres capas para el sistema
    desplegado del proyecto final, y agréguela junto con la model card del Cap. 19.",
)

#cap-cierre-narrativo(
  resumen: (
    [Comunicar en capas resuelve el trade-off claridad/honestidad — no hay que
     elegir un extremo.],
    [Las tres regularidades de Spiegelhalter son gratis de aplicar y cambian cómo se
     retiene un resultado.],
    [Sobreestimar la certeza falla en silencio; esa asimetría es una razón práctica,
     no solo ética, para preferir la comunicación explícita.],
  ),
  refs: (
    [Huyen (2022), Cap. 11, "The Human Side of Machine Learning"],
    [Spiegelhalter (2019), *The Art of Statistics*],
    [Lipton (2018), "The Mythos of Model Interpretability"],
  ),
  transicion: "Cierre del curso — Proyecto final (06_proyecto_final/, S29-S32)",
  gancho: "No hay Cap. 33. Los dos hilos del libro —identificación/estimación e
    ingeniería de sistemas— se entregan aquí, juntos, a una persona que tiene que
    decidir. El proyecto final es donde el estudiante hace lo mismo con su propio
    caso.",
)
