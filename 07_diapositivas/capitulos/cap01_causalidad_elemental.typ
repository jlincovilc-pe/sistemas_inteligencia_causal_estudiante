// =============================================================================
// Diapositivas · Capítulo 1 — Causalidad elemental y el problema fundamental
// de la inferencia causal
// Fuente: 02_monografia/.../capitulos/cap00_causalidad_elemental.typ
// Plan detallado: 07_diapositivas/PLAN_SPRINT_DIAPOSITIVAS.md §3, "Cap. 1"
// Sesión S1 · Lab L01 · sin entrega · Variante A (ligera) · ★ camino crítico
// =============================================================================
#import "../plantilla_monografia.typ": *

#show: cap-theme

#cap-init(
  num: 1, titulo: "Causalidad elemental y el problema fundamental de la inferencia causal",
  parte: "0", sesion: "S1", variant: "A", critico: true,
)

#cap-progreso-curso(cap-actual: 1)

#cap-portada(
  num: 1, titulo: "Causalidad elemental y el problema fundamental de la inferencia causal",
  parte: "0", sesion: "S1", variant: "A", critico: true,
)

#cap-roadmap(
  objetivos: (
    [Distinguir una pregunta asociativa de una pregunta causal en un caso aplicado.],
    [Enunciar el problema fundamental de la inferencia causal (Holland, 1986) y su
     consecuencia sobre el efecto individual.],
    [Ubicar una pregunta en el nivel correcto de la escalera de Pearl (asociación /
     intervención / contrafactual).],
  ),
  agenda: (
    [Dos preguntas que parecen la misma pregunta],
    [Tres escenas clásicas: cigüeñas, tamaño del pie, Simpson],
    [El problema fundamental de la inferencia causal],
    [Un adelanto de la escalera de la causalidad],
    [Por qué el ML no es causal por defecto],
  ),
  lectura: "Cap. 1 — Causalidad elemental (@cap-causalidad-elemental)",
  lab: "L01", entrega: "—",
)

// --- Motivación --------------------------------------------------------
#cap-motivacion(
  problema: "Un modelo predictivo entrenado sobre (beca, calificación) puede tener
    excelente precisión respondiendo \"¿quién tiene mejor nota?\" y, sin embargo, dar
    una respuesta equivocada si se usa para decidir a quién becar.",
  gancho: "¿Los estudiantes becados tienen mejores calificaciones? vs. ¿dar una beca a
    un estudiante mejora sus calificaciones? — misma tabla de datos, preguntas
    radicalmente distintas.",
  caso: "Programa de becas universitarias: asociación observada vs. efecto de otorgar
    la beca.",
)

// TODO(sprint): slide de "tres escenas clásicas" — no hay función dedicada en la
// plantilla; usar cap-glosario con 3 entradas (cigüeñas/tamaño del pie/Simpson) o crear
// una tabla simple. Ver §3 del plan para el detalle de cada escena.
#cap-glosario(terminos: (
  ([Cigüeñas y nacimientos], [Correlación regional sin vínculo causal: ambas responden
    a la ruralidad de la región. TODO(sprint): cifra o cita si se agrega.]),
  ([Tamaño del pie y lectura], [Confusor: la edad afecta ambas variables. Un modelo de
    ML "aprendería" la relación con alta confianza sin que sea causal.]),
  ([Paradoja de Simpson], [El tratamiento A gana en conjunto pero B gana en cada
    subgrupo — la gravedad del caso es el confusor. (Simpson, 1951; el fenómeno ya
    descrito por Yule, 1903)]),
))

// Variante A "ligera": sin #supuestos/#theorem formales en el libro. Se usa
// cap-definicion para el problema fundamental y cap-teorema para la descomposición
// (contenido añadido en la mejora de contenido de la monografía).
#cap-definicion(
  titulo-def: "El problema fundamental de la inferencia causal (Holland, 1986)",
  cuerpo: "Para cualquier unidad i, solo se observa uno de los dos resultados
    potenciales — nunca ambos. Si i recibió el tratamiento, observamos Y_i(1) pero
    Y_i(0) permanece contrafactual, y viceversa.
    // TODO(sprint): citar @holland1986 explícitamente en la slide.",
  eq: $Y_i (1) - Y_i (0) quad "nunca calculable directamente"$,
)

#cap-teorema(
  titulo: "Resultado: por qué la comparación de grupos no es automática",
  enunciado: "Δ = E[Y|D=1] - E[Y|D=0] = ATT + sesgo de selección, donde el sesgo de
    selección es E[Y(0)|D=1] - E[Y(0)|D=0]. Los experimentos aleatorizados anulan el
    segundo término por diseño; el resto del curso trata de aproximarlo cuando no hubo
    aleatorización. // TODO(sprint): ver @sec-introcausal-problema-fundamental del
    capítulo fuente para la derivación completa.",
)

// TODO(sprint): sin demostración formal en el libro — usar 2 pasos informales:
// (1) aplicar consistencia Y = D Y(1) + (1-D) Y(0), (2) identificar el segundo término
// como no observable sin supuesto de aleatorización/no confusión.
#cap-demostracion(pasos: (
  [Aplicar la restricción de consistencia Y = D·Y(1) + (1−D)·Y(0) a la diferencia de
   medias observada.],
  [Aislar el término E[Y(0)|D=1] − E[Y(0)|D=0]: compara el resultado potencial no
   observado de los tratados contra el observado de los controles.],
  [Mostrar que la aleatorización hace ambos términos iguales en expectativa —
   comparabilidad *por diseño*, no por volumen de datos.],
))

#cap-interactivo(
  tipo: "Conceptual",
  pregunta: "Clasifique tres preguntas en Nivel 1 (asociación), Nivel 2 (intervención) o
    Nivel 3 (contrafactual): (a) ¿más médicos per cápita, menor mortalidad infantil?
    (b) ¿contratar más médicos reduciría la mortalidad? (c) ¿habría sobrevivido este
    paciente con un médico más? // TODO(sprint): del ejercicio 1 del capítulo fuente.",
)

// TODO(sprint): el capítulo no trae listados de código (es puramente conceptual).
// Si se desea una slide de "código", usar el ejemplo numérico de la caja de
// profundización 1.1 (banco/tasa de interés) como pseudocódigo o tabla.

#cap-caso-resolucion(
  titulo: "El ejemplo que abre el capítulo",
  contexto: "Ministerio de Desarrollo Social: 100 variables por hogar, presupuesto para
    30% de la población. Pregunta correcta: ¿quién experimentaría el mayor incremento
    de ingresos si recibiera el programa? — no ¿quién tendrá mayor ingreso futuro?",
  resultado: "TODO(sprint): no hay cifra numérica en este capítulo (es el gancho de
    apertura de todo el curso, se retoma con datos reales en el Cap. 5 y el Cap. 11).",
  interpretacion: "La pregunta predictiva y la causal pueden dar respuestas opuestas
    sobre a quién priorizar.",
)

#cap-mapeo-pch-activo(
  nivel: "L1 (asociación) vs. L2 (intervención) — adelanto, formalizado en el Cap. 3",
  metrica: "Δ (diferencia de medias) vs. τ = E[Y(1)−Y(0)]",
  pregunta-activa: "Si solo predijéramos quién tendrá mejor resultado, ¿a quién
    trataríamos? Con el efecto causal, ¿cambia la decisión?",
)

#cap-errores-transiciones(
  errores: (
    ("crítico", [Confundir "el modelo predice bien" con "el modelo estima el efecto
      causal" — es el error más común y más costoso del curso.]),
    ("advertencia", [Creer que más datos resuelven la falta de aleatorización: el
      sesgo de selección no se reduce con n, se elimina con diseño.]),
  ),
  conexiones: "La escalera de Pearl (adelanto aquí) se formaliza con SCM en el Cap. 3 y
    con el criterio de puerta trasera en el Cap. 8.",
)

#cap-discusion-ejercicio(
  pregunta: "¿Por qué el problema fundamental de la inferencia causal implica que
    ningún algoritmo, por sofisticado que sea, puede calcular Y_i(1)−Y_i(0) para una
    unidad específica a partir de solo datos observacionales de esa unidad?",
  ejercicio: "Un equipo entrena gradient boosting para predecir ventas a partir de si
    hubo promoción, con R²=0.95, y concluye \"la promoción explica el 95% de las
    ventas\". ¿Qué está mal en términos de los niveles de la escalera de causalidad?
    // TODO(sprint): ejercicio 4 del capítulo fuente.",
)

#cap-cierre-narrativo(
  resumen: (
    [Asociación ≠ causa; ningún volumen de datos por sí solo convierte una en otra.],
    [El problema fundamental: nunca se observan ambos resultados potenciales de una
     misma unidad.],
    [La escalera de Pearl organiza toda pregunta causal en tres niveles anidados.],
  ),
  refs: (
    [Holland (1986), "Statistics and Causal Inference"],
    [Neyman (1923) / Rubin (1974), marco de resultados potenciales],
    [Pearl & Mackenzie (2018), *The Book of Why*],
  ),
  transicion: "Cap. 2 — Anatomía de un sistema de ML en producción",
  gancho: "La pregunta causal está clara; ahora, ¿dónde vive en un sistema que hay que
    operar?",
)
