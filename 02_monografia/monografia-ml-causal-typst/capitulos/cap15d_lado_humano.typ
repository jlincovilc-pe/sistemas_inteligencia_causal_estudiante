// Capítulo 32 (nuevo, último) — El lado humano de los sistemas causales
// Plantilla B: Sesión 28. Cierra el libro.
#import "../template/template.typ": *

#chapter[El lado humano de los sistemas causales]
<cap-lado-humano>

#theorem-number-reset()

#cuadrodecision[
  #table(
    columns: (auto, 1fr),
    align: (left, left),
    stroke: none,
    [*Decisión:*], [Comunicar resultados causales con sus supuestos e incertidumbre explícitos, incluso a audiencias no técnicas],
    [*Alternativas:*], [Comunicación simplificada (solo el número/la historia) vs. comunicación con supuestos e incertidumbre explícitos],
    [*Trade-off clave:*], [Claridad y persuasión inmediata vs. honestidad sobre los límites del hallazgo],
    [*Riesgo principal:*], [Que un resultado válido *bajo supuestos* se comunique y se use como si fuera una verdad incondicional],
  )
]

== El problema de diseño
<sec-ladohumano-problema>

Cada capítulo de este libro terminó con una advertencia sobre límites y supuestos —la sección de "riesgos" en los capítulos de teoría, la de "señales de alerta" en los de ingeniería—. Ese cuidado se pierde con facilidad en el último paso, casi nunca técnico, del ciclo de vida de un sistema causal: comunicar el resultado a quien debe tomar una decisión con él. #cite(<huyen2022dmls>, form: "prose") dedica su último capítulo a un punto que la formación técnica rara vez cubre: la mayoría de los proyectos de ML no fallan por un error de modelado, sino por una desconexión entre lo que el equipo técnico sabe sobre las limitaciones de su sistema y lo que la organización termina entendiendo y usando. Para un sistema causal, este riesgo es todavía mayor, porque la diferencia entre "$X$ predice $Y$" y "$X$ causa $Y$" —el problema con el que abrió este libro en el @cap-causalidad-elemental— es exactamente el tipo de matiz que se pierde primero en una comunicación simplificada.

== Opciones y trade-offs
<sec-ladohumano-opciones>

#opciones[
  - *Comunicación simplificada.* "El programa aumenta el ingreso en 12%." Es clara, memorable y persuasiva —y es, con frecuencia, la única versión que sobrevive varias capas de resumen entre el equipo de datos y quien decide—. Su costo es que omite exactamente lo que este libro pasó 31 capítulos formalizando: bajo qué supuestos, para qué población, con qué incertidumbre.
  - *Comunicación con supuestos e incertidumbre explícitos.* "El programa aumenta el ingreso en 12% (IC 95%: 8%–16%), estimado sobre la población que efectivamente participó, bajo el supuesto de que no hay factores no observados que determinen tanto la participación como el ingreso." Es honesta y auditable, pero es más difícil de retener y, sin cuidado en la forma, puede sonar a que el equipo técnico "no está seguro de nada" — un riesgo real de que el matiz se interprete como debilidad del hallazgo en lugar de rigor.
]

La resolución de este trade-off no es elegir un extremo sino *estructurar* la comunicación en capas: un titular memorable, respaldado inmediatamente por los supuestos y la incertidumbre en un lugar visible y accesible, no enterrado en un apéndice que nadie lee.

Vale la pena añadir que la forma de comunicar la incertidumbre no es neutral, y que la literatura de comunicación de riesgo ha establecido regularidades que conviene aprovechar en lugar de redescubrir. #cite(<spiegelhalter2019art>, form: "prose") documenta tres que aplican directamente aquí. Primera, las *frecuencias naturales* se comprenden mejor que las probabilidades o los porcentajes: "de cada 100 hogares que reciben el programa, entre 8 y 16 salen de la pobreza" se retiene y se razona mejor que "el efecto es del 12% (IC 95%: 8–16%)", aunque digan lo mismo. Segunda, los *riesgos relativos exageran sistemáticamente* la percepción del efecto: "duplica la probabilidad" es correcto y engañoso si la probabilidad basal es del 0.1%; reportar siempre el cambio absoluto junto al relativo. Tercera, y la más relevante para un resultado causal: la comunicación debe explicitar *sobre qué población* aplica el número, porque la audiencia asumirá por defecto que aplica a la suya.

Hay además una asimetría que conviene tener presente al decidir cuánto matizar. Sobreestimar la certeza de un resultado causal produce decisiones que fallan de forma silenciosa —el programa se implementa, no funciona, y rara vez se atribuye el fracaso al análisis—. Subestimarla produce, en el peor caso, que la decisión se posponga o se tome sin el análisis. Los dos errores tienen costos, pero solo el primero se disfraza de éxito, y esa es una razón práctica, no solo ética, para inclinarse por la comunicación con supuestos explícitos.

== Decisión de referencia para el curso
<sec-ladohumano-decision>

El proyecto final del curso exige que todo resultado se comunique con una estructura de tres capas: *(i)* el hallazgo en una oración, en lenguaje no técnico; *(ii)* los supuestos de identificación y la población de validez, en un párrafo; *(iii)* el detalle técnico completo (el propio proyecto/notebook), para quien necesite auditarlo. Es, en esencia, la misma estructura de la _model card_ causal del Capítulo 19, aplicada ahora a la comunicación con personas y no solo a la documentación de un artefacto.

== Implementación de referencia: plantilla de comunicación
<sec-ladohumano-implementacion>

#figure(
  kind: raw,
  caption: [Plantilla de tres capas para comunicar un resultado causal.],
  ```markdown
## Hallazgo
[Una oracion, en lenguaje no tecnico, sin jerga estadistica.]

## Lo que esto significa (y lo que no)
- Poblacion para la que es valido: [...]
- Principal supuesto detras del resultado: [...]
- Incertidumbre: [IC 95%, en unidades que la audiencia entienda]
- Este resultado NO implica: [ej.: "no implica que el efecto sea
  el mismo para poblaciones fuera del rango estudiado"]

## Detalle tecnico
[Enlace al notebook / proyecto / model card completos]
```
) <lst-plantilla-comunicacion>

== Aplicación al sistema causal del curso: cierre
<sec-ladohumano-cierre>

Este capítulo cierra el libro donde el Capítulo 1 lo abrió: con la distinción entre una pregunta asociativa y una pregunta causal. En el trayecto, el libro desarrolló dos hilos en paralelo. El primero, de identificación y estimación —SCM, criterio de puerta trasera, ortogonalidad de Neyman, DML, meta-learners, bosques causales, diseños de panel e instrumentales, descubrimiento de estructura— responde *qué tan bien* se puede responder una pregunta causal con los datos disponibles. El segundo, de ingeniería de sistemas siguiendo a @huyen2022dmls y @kastner2024mlip —anatomía de un sistema, datos de entrenamiento, *features* sin fuga, despliegue, *model cards*, CI/CD, monitoreo, aprendizaje continuo— responde *cómo* llevar esa respuesta, de forma responsable y verificable, hasta quien la necesita. Ninguno de los dos hilos es completo sin el otro: un estimador impecable que nadie puede auditar en producción es tan poco útil como un servicio impecablemente desplegado que estima la pregunta equivocada. Este último capítulo, y esta plantilla de comunicación, son el punto donde ambos hilos finalmente le entregan algo a una persona que tiene que decidir.

== Señales de alerta y checklist operativo
<sec-ladohumano-alertas>

#checklist[
  - El resumen ejecutivo de un resultado causal no menciona ningún supuesto ni intervalo de incertidumbre.
  - Nadie fuera del equipo técnico sabe cuál es la población para la que el efecto estimado es válido.
  - La comunicación usa lenguaje causal ("X causa Y") para un resultado que, honestamente, solo respalda una afirmación asociativa o condicional.
  - No existe una versión accesible (capa 1–2 de la plantilla) del resultado; solo existe el notebook técnico completo.
]

== Ejercicios y notas bibliográficas
<sec-ladohumano-ejercicios>

=== Ejercicios conceptuales
<sec-ladohumano-ejercicios-conceptuales>

+ Tome el resultado del Notebook A2 de su proyecto (o cualquier estimación de este curso) y redáctelo usando la plantilla de tres capas del listado @lst-plantilla-comunicacion.

+ Describa una situación —real o hipotética— en la que una comunicación simplificada de un resultado causal llevó, o podría llevar, a una decisión que el resultado técnico no respaldaba realmente.

=== Ejercicio de cierre (proyecto final)
<sec-ladohumano-ejercicios-cierre>

+ Complete la plantilla de comunicación de tres capas para el sistema desplegado de su proyecto final, y agréguela como parte de la entrega junto con la *model card* del Capítulo 19.

=== Notas bibliográficas
<sec-ladohumano-notas>

#cite(<huyen2022dmls>, form: "prose"), Capítulo 11 ("The Human Side of Machine Learning"), es la referencia central de este capítulo. Sobre comunicación de incertidumbre estadística a audiencias no técnicas, #cite(<spiegelhalter2019art>, form: "prose") es la referencia práctica más útil —frecuencias naturales, riesgos absolutos frente a relativos, representación visual de la incertidumbre— y la fuente de las tres regularidades de la @sec-ladohumano-opciones. #cite(<lipton2018mythos>, form: "prose") complementa la discusión desde el otro lado: qué se le está pidiendo realmente a un modelo cuando se pide que sea "interpretable" o "explicable", y por qué esas demandas encubren objetivos distintos (confianza, causalidad, transferibilidad) que conviene separar antes de intentar satisfacerlos. Sobre las buenas prácticas de reporte de resultados causales en particular, véase @imbens2015causal.

== Comunicación efectiva de incertidumbre

La comunicación de incertidumbre causal a stakeholders no técnicos requiere visualizaciones claras y narrativas accesibles. @spiegelhalter2019art (Spiegelhalter 2019) proporciona un marco para comunicar resultados estadísticos con transparencia. Para visualización de riesgo y gráficos de incertidumbre, ver @galesic2011 (Galesic & Garcia-Retamero 2011) sobre alfabetización gráfica cross-cultural.

**Principios clave:**
- Usar intervalos de confianza visuales en lugar de solo estimados puntuales
- Comunicar bounds cuando la identificación es parcial
- Explicar supuestos de identificación en lenguaje no técnico
- Proveer contexto sobre magnitud práctica (¿es el efecto grande?)
