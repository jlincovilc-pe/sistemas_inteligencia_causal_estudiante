// Apéndice H — Checklist de arquitectura de despliegue
#import "../template/template.typ": *

#chapter[Checklist de arquitectura de despliegue]
<ap-checklist-despliegue>

#theorem-number-reset()

Este apéndice sintetiza, en formato de decisión rápida, las opciones de arquitectura discutidas a lo largo de la segunda mitad del libro (Capítulos 2, 15, 19, 20, 30 y 31), para usarse como referencia al diseñar el componente de producción de un sistema causal nuevo.

== Elegir el patrón de _serving_
<sec-apH-serving>

#table(
  columns: (1.6fr, 2.4fr),
  align: left,
  stroke: 0.5pt + gray.lighten(60%),
  table.header([*Si...*], [*Entonces considere...*]),
  [Las unidades a evaluar no se conocen de antemano y llegan una a la vez], [Servicio REST síncrono (@cap-despliegue-servicio)],
  [La población completa a evaluar es fija y conocida con anticipación], [_Batch_ precomputado],
  [Todos los consumidores comparten el mismo entorno de Python y necesitan latencia mínima], [Biblioteca embebida],
  [Se necesita publicar para consumidores externos al equipo, en cualquier lenguaje], [Servicio REST + publicación en Hugging Face Hub (@cap-hf-hub)],
)

== Checklist de la función de inferencia
<sec-apH-inferencia>

#checklist[
  - La función de inferencia es pura (sin estado mutable, sin efectos secundarios).
  - El cálculo de _features_ usa exactamente el mismo código en entrenamiento y en producción.
  - La función usa el `CausalSchema` (@cap-ingenieria-datos-causales) para validar las covariables de entrada, no nombres de columna hardcodeados.
  - La respuesta incluye intervalo de confianza y población de entrenamiento, no solo el efecto puntual (@cap-anatomia-sistema).
]

== Checklist de CI/CD
<sec-apH-cicd>

#checklist[
  - El pipeline corre pruebas de software en cada _push_ y pruebas estadísticas (placebo, balance) antes de publicar (@cap-cicd-causal).
  - Existe un dataset de referencia fijo y versionado para las pruebas estadísticas.
  - La publicación al Hub está condicionada al resultado de ambos tipos de prueba, no solo de las de software.
  - Ningún reentrenamiento se promueve a producción sin pasar por el proceso _champion-challenger_ (@cap-aprendizaje-continuo).
]

== Checklist de monitoreo en producción
<sec-apH-monitoreo>

#checklist[
  - Se monitorea el _drift_ de covariables individuales, no solo de las predicciones agregadas (@cap-monitoreo-causal).
  - Cuando el diseño usa un instrumento, se monitorea su fuerza en ventanas recientes.
  - Se monitorea la estabilidad del efecto estimado en ventanas móviles, comparada contra el intervalo de confianza original.
  - Existe un proceso definido y documentado de qué hacer cuando el monitoreo dispara una alerta — no solo la alerta misma.
]

== Checklist de comunicación
<sec-apH-comunicacion>

#checklist[
  - Todo resultado comunicado fuera del equipo técnico sigue la plantilla de tres capas del @cap-lado-humano.
  - La población de validez del resultado es explícita en la primera o segunda capa de la comunicación, no solo en el detalle técnico.
  - El lenguaje usado ("causa" vs. "está asociado con") es consistente con el nivel de identificación efectivamente alcanzado.
]
