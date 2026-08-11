// Capítulo 1 (nuevo) — Causalidad elemental y el problema fundamental de la inferencia causal
// Plantilla A (versión ligera): capítulo de arranque del curso, Sesión 1, sin laboratorio.
#import "../template/template.typ": *

#chapter[Causalidad elemental y el problema fundamental de la inferencia causal]
<cap-causalidad-elemental>

#theorem-number-reset()

#cuadrosinoptico[
  #table(
    columns: (auto, 1fr),
    align: (left, left),
    stroke: none,
    [*Problema:*], [Distinguir una pregunta asociativa de una pregunta causal],
    [*Idea central:*], [El problema fundamental de la inferencia causal (Holland, 1986)],
    [*Herramienta:*], [Resultados potenciales $Y(1), Y(0)$; un adelanto de la escalera de Pearl],
    [*Ejemplos:*], [Correlaciones espurias, paradoja de Simpson],
    [*Sin laboratorio:*], [Sesión puramente conceptual — el primer notebook llega en el Módulo 1],
    [*Prepara:*], [@cap-scm-pch (SCM y PCH) y @cap-prediccion-causalidad (ML no es causal por defecto)],
  )
]

== Dos preguntas que parecen la misma pregunta
<sec-introcausal-dos-preguntas>

Suponga dos preguntas sobre un programa de becas universitarias. La primera: _¿los estudiantes becados tienen, en promedio, mejores calificaciones que los no becados?_ La segunda: _¿dar una beca a un estudiante mejora sus calificaciones?_ Ambas preguntas se responden, en apariencia, con el mismo tipo de dato —una tabla de estudiantes, si recibieron beca, y sus calificaciones— y sin embargo son preguntas radicalmente distintas. La primera es una pregunta *asociativa*: describe un patrón en los datos tal como existen. La segunda es una pregunta *causal*: describe qué pasaría si _interviniéramos_ sobre el mundo, otorgando una beca que de otro modo no se habría otorgado.

La confusión entre ambas preguntas no es un error ingenuo. Es, de hecho, el error más común y más costoso en la aplicación de _machine learning_ a la toma de decisiones. Un modelo predictivo entrenado sobre $(text("beca"), text("calificación"))$ puede alcanzar una precisión excelente respondiendo la primera pregunta y, sin embargo, ofrecer una respuesta completamente equivocada si se lo usa para decidir a quién becar —porque los estudiantes que hoy reciben becas no son una muestra aleatoria de la población: probablemente ya tenían mejores calificaciones, mejor preparación, o mayor motivación *antes* de recibir la beca. La asociación observada mezcla el efecto de la beca con estas diferencias preexistentes.

Este curso completo puede resumirse en una sola tesis, que retomaremos una y otra vez bajo distintas formas técnicas: *ningún volumen de datos, por sí solo, convierte una pregunta asociativa en una pregunta causal*. Convertir una en otra requiere supuestos explícitos sobre cómo se generaron los datos —supuestos que provienen del conocimiento del dominio, no del algoritmo—. El aporte del _machine learning_ moderno, que ocupará el resto del curso, es permitir que esos supuestos se combinen con métodos flexibles y de alta dimensión sin perder validez estadística. Pero el primer paso, el de este capítulo, es aprender a *reconocer* cuándo una pregunta es causal, y por qué los datos nunca la responden solos.

== Correlación no es causación: tres escenas clásicas
<sec-introcausal-escenas>

La distinción anterior suele aceptarse en principio y olvidarse en la práctica. Tres ejemplos clásicos ayudan a que la intuición se vuelva difícil de desactivar.

*Escena 1: cigüeñas y nacimientos.* En varios países europeos, los conteos anuales de parejas de cigüeñas y de nacimientos humanos están positivamente correlacionados a nivel regional. Nadie propone que las cigüeñas traen bebés; ambas variables responden a una tercera —el tamaño y la ruralidad de la región— que las mueve en la misma dirección sin que exista ningún vínculo causal directo entre ellas.

*Escena 2: el tamaño del pie y la capacidad de lectura.* En una muestra de niños entre 2 y 12 años, el tamaño del pie predice con notable precisión el puntaje en una prueba de lectura. Un modelo de _machine learning_ entrenado sobre estos datos "aprendería" esta relación con alta confianza. La variable omitida es, por supuesto, la edad: los niños mayores tienen pies más grandes y leen mejor, sin que agrandar artificialmente el pie de un niño mejore su lectura. En el lenguaje que formalizaremos en el próximo capítulo, la edad es un _confusor_ (_confounder_): afecta tanto a la variable explicativa como al resultado, y genera una asociación que no representa ningún mecanismo causal entre ellas.

#example(name: [El problema fundamental])[
*La paradoja de Simpson.* Un hospital evalúa dos tratamientos, A y B, para una misma condición. Tomando todos los pacientes en conjunto, el tratamiento A tiene una tasa de éxito mayor que B. Sin embargo, al separar a los pacientes por gravedad del caso (leve/grave), el tratamiento B resulta superior tanto en el grupo leve como en el grupo grave. La reversión ocurre porque el tratamiento A se administró desproporcionadamente a los casos leves —que se recuperan más fácilmente por sí solos— mientras que B se reservó para los casos graves. La gravedad es, otra vez, un confusor: determina tanto qué tratamiento recibe el paciente como su probabilidad de recuperación. La paradoja de Simpson (#cite(<simpson1951>, form: "year"); el fenómeno ya había sido descrito por #cite(<yule1903>, form: "prose")) es la demostración más nítida de que una asociación puede invertir su signo por completo según qué variables se incluyan en el análisis —y de que no existe una respuesta puramente estadística sobre cuál desagregación es la "correcta": se requiere una teoría causal (¿la gravedad afecta a la asignación del tratamiento?) para saberlo.
]

Estas tres escenas comparten una estructura: una variable no observada, o no correctamente condicionada, genera una asociación que desaparece o se revierte en cuanto se controla por ella. La pregunta que este curso enseña a hacer sistemáticamente es: _¿qué tendría que ser cierto sobre cómo se generaron estos datos para que la asociación observada refleje el efecto causal que me interesa?_

== El problema fundamental de la inferencia causal
<sec-introcausal-problema-fundamental>

Formalicemos la intuición anterior con la herramienta que usaremos durante todo el curso: el marco de *resultados potenciales* (Neyman, #cite(<neyman1923>, form: "year"); Rubin, #cite(<rubin1974>, form: "year")). Para cada unidad $i$ (una persona, un hogar, una empresa) y un tratamiento binario $D_i in {0,1}$, definimos dos resultados *potenciales*: $Y_i (1)$, el resultado que se observaría si la unidad recibiera el tratamiento, y $Y_i (0)$, el resultado que se observaría si no lo recibiera. El efecto causal individual del tratamiento sobre la unidad $i$ es, por definición, la diferencia $Y_i (1) - Y_i (0)$.

#definition[
*El problema fundamental de la inferencia causal* @holland1986: para cualquier unidad $i$, solo se observa uno de los dos resultados potenciales —el correspondiente al tratamiento efectivamente recibido— y nunca ambos. Si $i$ recibió el tratamiento, observamos $Y_i (1)$ pero $Y_i (0)$ permanece contrafactual, es decir, no observado y no observable. Si no lo recibió, ocurre lo simétrico.
]

Esta afirmación, aunque elemental, tiene una consecuencia que estructura todo el campo: el efecto causal individual $Y_i(1) - Y_i(0)$ *nunca* puede calcularse directamente para ninguna unidad, sin importar cuántos datos se recolecten sobre ella. Lo que sí puede estimarse, bajo supuestos adecuados, es un efecto *poblacional* o *promedio* —por ejemplo, el efecto promedio del tratamiento (ATE), $theta = E[Y(1) - Y(0)]$— comparando grupos de unidades distintas que recibieron y no recibieron el tratamiento.

Conviene ver, ya en este capítulo introductorio, exactamente *dónde* entra el supuesto que hace legítima esa comparación, porque es la misma estructura lógica que reaparecerá, con aparato técnico creciente, en todos los métodos del curso. Lo que los datos entregan directamente es la *diferencia de medias observada*, $Delta = E[Y | D=1] - E[Y | D=0]$. Aplicando la restricción de consistencia $Y = D Y(1) + (1-D) Y(0)$, esta diferencia se reescribe como
$
Delta = underbrace(E[Y(1) - Y(0) | D=1], "efecto causal sobre los tratados (ATT)") + underbrace(E[Y(0) | D=1] - E[Y(0) | D=0], "sesgo de selección").
$
El segundo término compara el resultado que tratados y no tratados habrían tenido *en ausencia de tratamiento*: es cero solo si ambos grupos eran comparables de partida, y no hay ningún dato que permita calcularlo, porque $E[Y(0) | D=1]$ involucra el resultado potencial no observado de los tratados. Las tres escenas de la sección anterior son, todas, casos donde ese segundo término no es cero y domina la comparación.

Los experimentos aleatorizados lo anulan *por diseño*: si $D$ se asigna independientemente de $(Y(0), Y(1))$, entonces $E[Y(0) | D=1] = E[Y(0) | D=0]$ y $Delta = theta$. La aleatorización no "descubre" nada en los datos; impone, mediante el procedimiento de asignación, una condición que ningún volumen de datos observacionales garantiza. Gran parte de este curso está dedicada precisamente a los métodos que permiten *aproximar* esa condición cuando no hubo aleatorización —haciéndola plausible condicional en un conjunto de covariables observadas— usando herramientas de _machine learning_ para manejar un número grande de ellas sin perder validez estadística.

== Un adelanto de la escalera de la causalidad
<sec-introcausal-escalera>

Judea Pearl propuso organizar todas las preguntas causales en tres niveles jerárquicos, popularizados como la "escalera de la causalidad" @pearlmackenzie2018 y formalizados como la Jerarquía Causal de Pearl (PCH) en el trabajo que retomaremos en detalle en el @cap-scm-pch. Como adelanto:

- *Nivel 1 — Asociación* ("ver"): ¿qué relación existe entre las variables tal como se observan? _¿Los estudiantes becados tienen mejores notas?_
- *Nivel 2 — Intervención* ("hacer"): ¿qué pasaría si actuáramos sobre el sistema? _¿Qué pasaría con las notas si diéramos una beca a un estudiante que hoy no la tiene?_
- *Nivel 3 — Contrafactual* ("imaginar"): ¿qué habría pasado en un mundo alternativo, dado lo que efectivamente observamos? _¿Habría aprobado María si le hubieran dado la beca, sabiendo que en los hechos no se la dieron y no aprobó?_

Cada nivel requiere información y supuestos estrictamente más fuertes que el anterior: los datos observacionales puros solo permiten responder preguntas de Nivel 1 sin más; responder Nivel 2 requiere supuestos de identificación (como los que exploraremos con Post-Double-Selection y Double Machine Learning); responder Nivel 3 requiere, además, un modelo estructural completo. La pregunta con la que abrimos este capítulo —¿dar una beca mejora las calificaciones?— es una pregunta de Nivel 2, y es precisamente el tipo de pregunta que un modelo de _machine learning_ estándar, entrenado para predecir bien, *no* está diseñado para responder.

== Por qué el aprendizaje automático no es causal por defecto
<sec-introcausal-por-que-ml>

Vale la pena anticipar, en términos simples, por qué esto importa específicamente para este curso y no solo para la estadística clásica. Los algoritmos de _machine learning_ —regresión regularizada, bosques aleatorios, _gradient boosting_, redes neuronales— están diseñados y evaluados para minimizar el error de predicción fuera de muestra. Esa optimización no distingue, ni tiene por qué distinguir, entre la parte de la relación $X arrow.r Y$ que es causal y la parte que refleja confusión, como en las tres escenas de la @sec-introcausal-escenas. Un modelo que predice el tamaño del pie a partir de la capacidad de lectura (o viceversa) con gran precisión está haciendo exactamente lo que se le pidió: predecir bien. El error no está en el algoritmo, sino en usar sus resultados para responder una pregunta —la pregunta causal— que nunca se le planteó.

Este curso dedica su primera mitad a mostrar cómo, bajo supuestos de identificación explícitos, es posible usar la misma flexibilidad de alta dimensión que hace poderoso al _machine learning_ predictivo —sin heredar su ceguera ante la confusión—, y su segunda mitad a mostrar cómo llevar esos modelos, ya validados, a un sistema que opera de forma confiable en producción. El @cap-prediccion-causalidad retoma esta discusión con el aparato formal completo (resultados potenciales en alta dimensión, sesgo de regularización, el estimando CATE); el @cap-scm-pch formaliza la escalera de causalidad con modelos causales estructurales. Este capítulo solo pretende dejar instalada, de forma intuitiva y memorable, la pregunta que todo el curso responde: _¿es esto una pregunta de asociación, o una pregunta causal?_

== Ejercicios y notas bibliográficas
<sec-introcausal-ejercicios>

=== Ejercicios conceptuales
<sec-introcausal-ejercicios-conceptuales>

+ Para cada una de las siguientes preguntas, indique si es de Nivel 1 (asociación), Nivel 2 (intervención) o Nivel 3 (contrafactual), y justifique en una oración: (a) ¿Los países con más médicos per cápita tienen menor mortalidad infantil? (b) ¿Contratar más médicos reduciría la mortalidad infantil en un país específico? (c) ¿Habría sobrevivido este paciente si el hospital hubiera tenido un médico más?

+ Proponga un ejemplo propio (distinto a los del capítulo) de una correlación espuria generada por una variable confusora. Identifique explícitamente la variable confusora y explique por qué genera la asociación observada.

+ Explique con sus propias palabras por qué el problema fundamental de la inferencia causal (Holland, 1986) implica que ningún algoritmo, por sofisticado que sea, puede calcular el efecto causal individual $Y_i(1) - Y_i(0)$ para una unidad específica a partir de datos observacionales de esa unidad.

+ Un equipo de datos entrena un modelo de _gradient boosting_ para predecir ventas a partir de si un producto tuvo o no una promoción, alcanzando un $R^2$ de 0.95. El equipo concluye que "la promoción explica el 95% de las ventas" y recomienda aplicarla a todos los productos. ¿Qué está mal en este razonamiento, en términos de los niveles de la escalera de causalidad?

=== Notas bibliográficas
<sec-introcausal-notas>

El marco de resultados potenciales se origina en @neyman1923 para experimentos agrícolas aleatorizados y se extiende a estudios observacionales en @rubin1974; #cite(<holland1986>, form: "prose") formaliza el problema fundamental de la inferencia causal y sigue siendo la referencia estándar para esa formulación. La descomposición de la diferencia de medias en ATT más sesgo de selección de la @sec-introcausal-problema-fundamental es estándar; su tratamiento completo, incluida la discusión de cuándo el ATT y el ATE coinciden, está en @imbens2015causal, Capítulo 1. #cite(<pearlmackenzie2018>, form: "prose") ofrece la exposición más accesible de la escalera de causalidad para un público no especializado; el tratamiento técnico completo de la Jerarquía Causal de Pearl se encuentra en @bareinboim2022pch —la formalización canónica del resultado, que el @cap-scm-pch retoma con precisión— y, de forma integrada con el resto del programa de IA causal, en @bareinboim2025causalai y @pearl2009causality. #cite(<simpson1951>, form: "prose") es la referencia original de la paradoja que lleva su nombre, aunque el fenómeno había sido descrito antes en @yule1903. Para una introducción contemporánea y aplicada al marco contrafactual, véase @hernan2020whatif, ya citado en capítulos posteriores.
