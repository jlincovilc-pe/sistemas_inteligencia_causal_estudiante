// Capítulo 2 (nuevo) — Anatomía de un sistema de ML en producción
// Plantilla B: capítulo de ingeniería/producción, estilo DMLS. Sesión 2, con Lab 0 (setup de entorno).
#import "../template/template.typ": *

#chapter[Anatomía de un sistema de ML en producción]
<cap-anatomia-sistema>

#theorem-number-reset()

#cuadrodecision[
  #table(
    columns: (auto, 1fr),
    align: (left, left),
    stroke: none,
    [*[Decisión]*], [Tratar el modelo como un componente de un sistema, no como el sistema entero],
    [*[Alternativas]*], [Enfoque centrado en el modelo (_model-centric_) vs. enfoque centrado en el sistema (_system-centric_, DMLS)],
    [*[Trade-off clave]*], [Velocidad de iteración académica vs. confiabilidad operativa],
    [*[Stack]*], [Python, Git, Docker, cuenta en Hugging Face Hub (Lab 0 de este capítulo)],
    [*[Riesgo principal]*], [Confundir "el modelo entrena bien" con "el sistema está listo para producción"],
  )
]

== El problema de diseño
<sec-anatomia-problema>

Un equipo de análisis de datos entrena un estimador de efectos causales —digamos, un modelo DML del tipo que se construirá en la Parte II de este curso— y obtiene un intervalo de confianza razonable, diagnósticos de identificación satisfactorios y una historia convincente sobre el mecanismo económico. El equipo concluye, con toda razón desde el punto de vista estadístico, que "el modelo funciona". Y sin embargo, si ese modelo se entrega tal cual a un equipo de producto para que decida a quién ofrecer un subsidio, casi con certeza algo saldrá mal en cuestión de semanas: la función que calcula las covariables en el entorno de producción no coincide exactamente con la que se usó para entrenar; nadie sabe qué hacer cuando llegan datos con un valor faltante; no existe forma de saber, tres meses después, si la población a la que se le sigue aplicando el modelo todavía se parece a la población de entrenamiento; y si el modelo empieza a fallar, nadie recibe una alerta hasta que un usuario se queja.

El problema de diseño de este capítulo es reconocer, antes de escribir una sola línea de código de estimación, que *un modelo entrenado y un sistema en producción son dos objetos distintos*, y que la distancia entre ambos no se cierra con más precisión estadística sino con decisiones de ingeniería. Como señala @huyen2022dmls, cuando la mayoría de las personas piensan en "un sistema de machine learning" piensan únicamente en el algoritmo; sin embargo, el algoritmo es apenas un componente de un sistema que también incluye la interfaz con la que interactúan usuarios y desarrolladores, el stack de datos que alimenta al modelo, el _backend_ de cómputo sobre el que corre, y la infraestructura que permite desarrollarlo, desplegarlo, monitorearlo y actualizarlo. Este curso dedica su segunda mitad a esos componentes no-algorítmicos, precisamente porque suelen ser el motivo real por el que un proyecto de ciencia de datos técnicamente correcto fracasa en producción.

== Opciones y trade-offs
<sec-anatomia-opciones>

Existen, en la práctica, dos filosofías de desarrollo que compiten por el tiempo y la atención de un equipo de datos.

*Opción 1 — Enfoque centrado en el modelo (_model-centric_).* El foco está en mejorar la especificación, el algoritmo o la arquitectura, manteniendo los datos y el entorno de despliegue relativamente fijos. Es el modo de trabajo dominante en la academia y en competencias como Kaggle: se compite por una décima de mejora en una métrica sobre un dataset fijo. Su ventaja es la velocidad de iteración sobre la pregunta metodológica; su límite es que ignora, por construcción, todo lo que ocurre antes de tener el dataset y después de tener el modelo entrenado.

*Opción 2 — Enfoque centrado en el sistema (_system-centric_, DMLS).* El foco se reparte deliberadamente entre datos, modelo e infraestructura, entendiendo que mejorar cualquiera de los tres puede mejorar el desempeño observado del sistema. Requiere invertir tiempo en aspectos que no son estadísticamente "interesantes" —formato de almacenamiento, *feature stores*, *logging*, *tests*— y por eso suele sentirse, al principio, como una desviación del trabajo "real". Su ventaja es que es, empíricamente, el único enfoque que sobrevive el contacto con datos reales que cambian con el tiempo y con usuarios reales que dependen del sistema.

Un segundo trade-off, ortogonal al anterior, es el del *proceso* de desarrollo:

#table(
  columns: (1.3fr, 2.2fr, 2.2fr),
  align: left,
  stroke: 0.5pt + gray.lighten(60%),
  table.header([*Dimensión*], [*Proceso lineal ("waterfall")*], [*Proceso iterativo (DMLS)*]),
  [Estructura], [Recolectar datos → entrenar → desplegar → fin], [Ciclo continuo: diseño → datos → desarrollo → despliegue → monitoreo → vuelve a diseño],
  [Supuesto implícito], [El mundo (los datos, los usuarios) no cambia después del despliegue], [El mundo cambia; el sistema debe detectarlo y adaptarse],
  [Cuándo falla], [En cualquier entorno de producción real, tarde o temprano], [Requiere infraestructura de monitoreo que el proceso lineal no contempla],
)

El proceso lineal no es una decisión de diseño defendible en 2026 para un sistema que opera de forma continua; se incluye en la tabla porque sigue siendo, de hecho, cómo se enseña y se ejecuta gran parte de los proyectos de ciencia de datos aplicada, y reconocerlo como la opción por defecto —y como opción inadecuada— es el primer paso para adoptar deliberadamente la alternativa.

== Decisión de referencia para el curso
<sec-anatomia-decision>

Este curso adopta explícitamente el *enfoque centrado en el sistema* y el *proceso iterativo* de DMLS como su filosofía de trabajo, formalizados en cuatro requisitos que todo sistema construido en el curso debe satisfacer —reinterpretados aquí para el caso en que el objetivo del sistema es estimar un efecto causal, no solo predecir:

#opciones[
  - *Confiabilidad*: el sistema sigue produciendo el comportamiento correcto incluso en presencia de errores de datos o de infraestructura. Para un sistema causal, esto incluye algo que un sistema puramente predictivo no necesita: que el efecto estimado siga siendo *válido bajo los supuestos de identificación declarados*, no solo que el servicio esté "arriba".
  - *Escalabilidad*: el sistema puede crecer en volumen de datos, de tratamientos o de usuarios sin un rediseño completo. Para un sistema causal, incluye poder re-estimar el efecto sobre subpoblaciones nuevas sin invalidar el pipeline de identificación existente.
  - *Mantenibilidad*: otra persona del equipo —no quien lo construyó— puede entender, auditar y modificar el sistema. Para un sistema causal, esto exige que los supuestos de identificación estén *documentados y sean auditables*, no solo el código.
  - *Adaptabilidad*: el sistema puede ajustarse a cambios en el entorno (nuevos datos, nuevas poblaciones, nuevas políticas). Para un sistema causal, incluye poder *detectar* cuándo un supuesto causal —no confusión, soporte común, fuerza del instrumento— dejó de sostenerse, tema que retomaremos en el Módulo 5.
]

Estos cuatro requisitos, y no la precisión del estimador considerada de forma aislada, son el criterio con el que se evaluará cada notebook de producción (Serie B) del curso.

== Implementación de referencia: el esqueleto del proyecto del curso
<sec-anatomia-implementacion>

Todo el trabajo práctico del curso —Serie A y Serie B de notebooks, y el proyecto final— se organiza sobre un mismo esqueleto de repositorio, que se establece en este capítulo y no vuelve a discutirse:

```
proyecto-causal/
├── data/                 # datos crudos y procesados (no versionados en git salvo muestras pequeñas)
├── notebooks/
│   ├── serie_a_caso_estudio/     # A1–A4: identificación y estimación
│   └── serie_b_produccion/       # B1–B4: despliegue en Hugging Face
├── src/
│   ├── identification/   # DAGs, diagnósticos de no confusión y soporte común
│   ├── estimation/        # DML, meta-learners, bosques causales
│   └── service/            # función de inferencia, app FastAPI
├── tests/                 # pruebas de humo y de sanidad estadística
├── .github/workflows/      # CI/CD (se detalla en el Capítulo 20)
├── Dockerfile
└── model_card.md           # plantilla del Apéndice G
```

*Lab 0 de esta sesión* consiste en dejar este esqueleto funcionando localmente: entorno de Python con las librerías del Apéndice B, repositorio Git inicializado, cuenta creada en Hugging Face Hub, y Docker instalado y verificado con `docker run hello-world`. No se estima ningún efecto causal todavía; el objetivo es puramente de infraestructura.

== Aplicación al sistema causal del curso
<sec-anatomia-aplicacion-causal>

Vale la pena ser explícitos sobre qué cambia, en esta anatomía de sistema, cuando el "modelo" no predice sino que estima un efecto. Primero, *el artefacto que se sirve no es solo un objeto entrenado*: es un estimador más un conjunto de supuestos de identificación que deben viajar junto con él —de nada sirve servir los coeficientes de un DML sin la documentación de qué variables se controlaron y bajo qué DAG supuesto, porque sin eso nadie puede saber si el efecto sigue siendo válido para una nueva observación. Segundo, *la interfaz con el usuario debe comunicar algo más que un número*: un sistema predictivo puede mostrar una predicción puntual; un sistema causal responsable debe comunicar el intervalo de confianza y, cuando sea posible, la población para la cual el efecto fue estimado, para evitar que se use fuera de su dominio de validez. Tercero, *reentrenar no es inocuo*: en un sistema predictivo, reentrenar con datos nuevos casi siempre es deseable si mejora la métrica de error. En un sistema causal, incorporar datos nuevos puede cambiar silenciosamente la población para la que el efecto estimado es representativo —un problema de validez externa, no solo de varianza— y este curso volverá sobre esto en el Capítulo 31 (aprendizaje continuo).

== Señales de alerta y checklist operativo
<sec-anatomia-alertas>

#checklist[
  - El notebook de estimación no tiene ninguna versión de los datos ni del código asociados (no hay forma de reproducir el resultado).
  - La función que calcula las covariables en el notebook de entrenamiento y la que las calculará en producción no son literalmente la misma función (riesgo de *training-serving skew*).
  - No existe ningún documento, ni siquiera informal, que declare los supuestos de identificación asumidos.
  - Nadie en el equipo, aparte de quien entrenó el modelo, podría explicar bajo qué población es válido el efecto estimado.
  - No hay ningún mecanismo, ni manual, para detectar si las covariables que llegan en producción se parecen a las de entrenamiento.
]

Si dos o más de estas señales están presentes, el sistema —por preciso que sea el estimador— no está listo para producción según los criterios de este curso.

== Ejercicios y notas bibliográficas
<sec-anatomia-ejercicios>

=== Ejercicios conceptuales
<sec-anatomia-ejercicios-conceptuales>

+ Enumere los componentes de un sistema de ML según @huyen2022dmls (más allá del algoritmo) y, para cada uno, dé un ejemplo concreto de cómo fallaría específicamente si el sistema estima un efecto causal en lugar de predecir.

+ Explique, con sus propias palabras, por qué "reentrenar con datos nuevos" es una decisión más delicada en un sistema causal que en uno puramente predictivo.

+ Revise los cuatro requisitos de la @sec-anatomia-decision (confiabilidad, escalabilidad, mantenibilidad, adaptabilidad) y ordénelos según cuál cree que es más fácil de descuidar en un proyecto real. Justifique.

=== Ejercicio de infraestructura (Lab 0)
<sec-anatomia-ejercicios-lab0>

+ Complete el Lab 0: cree el esqueleto de repositorio de la @sec-anatomia-implementacion, inicialice Git, cree una cuenta en Hugging Face Hub si no tiene una, instale Docker y verifique la instalación. Entregue una captura de pantalla de `docker run hello-world` corriendo exitosamente.

=== Notas bibliográficas
<sec-anatomia-notas>

@huyen2022dmls es la fuente principal de este capítulo y del enfoque pedagógico de todo el curso; sus Capítulos 1 y 2 ("Overview of Machine Learning Systems" e "Introduction to Machine Learning Systems Design") desarrollan en detalle la distinción entre modelo y sistema, y los cuatro requisitos aquí adaptados al caso causal. @sculley2015hiddendebt es el artículo seminal que documentó por primera vez, de forma sistemática, cómo el código del modelo de aprendizaje automático suele ser una fracción pequeña del sistema real, y cómo la "deuda técnica" se acumula en el resto de los componentes. @breck2017mltestscore ofrece una rúbrica operativa —"the ML Test Score"— que puede usarse como complemento al checklist de la @sec-anatomia-alertas para auditar la preparación de un sistema para producción.
