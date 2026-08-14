// Capítulo 3 (nuevo) — Modelos Causales Estructurales y la Jerarquía Causal de Pearl
// Plantilla A (completa): Sesión 3.
#import "../template/template.typ": *

#chapter[Modelos Causales Estructurales y la Jerarquía Causal de Pearl]
<cap-scm-pch>

#theorem-number-reset()

#cuadrosinoptico[
  #table(
    columns: (auto, 1fr),
    align: (left, left),
    stroke: none,
    [*Problema:*], [Formalizar matemáticamente qué significa "causa" y qué pregunta responde cada nivel de causalidad],
    [*Estimando:*], [Distribuciones $P(v)$, $P(y | "do"(x))$ y $P(y_x | "evidencia")$],
    [*Identificación:*], [Un Modelo Causal Estructural (SCM) más su grafo asociado],
    [*Método:*], [Do-calculus (adelanto; formalización completa en el @cap-intervencion-contrafactual)],
    [*Garantía:*], [Cada nivel de la PCH requiere estrictamente más supuestos que el anterior],
    [*Librerías:*], [#code[networkx], #code[dowhy], #code[causal-learn]],
    [*Validación:*], [Verificación de que el grafo supuesto es consistente con las independencias observadas],
  )
]

== El problema: formalizar "causa" matemáticamente
<sec-scmpch-problema>

El @cap-causalidad-elemental introdujo, de forma intuitiva, la distinción entre preguntas de asociación, de intervención y de contrafactual. Este capítulo formaliza esa distinción con dos herramientas que se usan indistintamente en la literatura moderna de inferencia causal: el marco de *resultados potenciales* (ya presentado en el capítulo anterior) y el marco de *Modelos Causales Estructurales* (SCM) de Judea Pearl, que Elias Bareinboim y su escuela extienden hasta la *Jerarquía Causal de Pearl* (PCH). Los dos marcos son formalmente equivalentes bajo condiciones generales, pero difieren en qué hacen explícito: los resultados potenciales son más naturales para razonar sobre un tratamiento y un resultado; los SCM son más naturales para razonar sobre sistemas con muchas variables relacionadas entre sí —precisamente el tipo de sistema que aparece en un pipeline de datos de producción—, y por eso son el lenguaje que usaremos en la segunda mitad de este curso al hablar de arquitecturas de datos y de despliegue.

La pregunta que este capítulo responde es doble: *(i)* ¿qué objeto matemático representa completamente un sistema causal?, y *(ii)* dado ese objeto, ¿qué tres tipos de pregunta —y solo tres— se le pueden hacer, y qué información mínima requiere responder cada una?

== Teoría: SCM y la Jerarquía Causal de Pearl
<sec-scmpch-teoria>

=== Modelos Causales Estructurales
<sec-scmpch-scm>

#definition(name: [SCM])[
Un *Modelo Causal Estructural* (SCM) es una tupla $M = ⟨U, V, F, P(u)⟩$ donde: $U$ es un conjunto de variables exógenas (no modeladas, "de fondo"); $V = {V_1, ..., V_n}$ es un conjunto de variables endógenas (las que el modelo explica); $F = {f_1, ..., f_n}$ es un conjunto de funciones estructurales tales que cada $V_i = f_i ("pa"_i, U_i)$, donde $"pa"_i subset.eq V without {V_i}$ son los "padres" de $V_i$ (sus causas directas dentro del modelo) y $U_i subset.eq U$; y $P(u)$ es una distribución de probabilidad sobre las variables exógenas.
]

Cada SCM induce un *grafo causal* $G$: un nodo por cada variable en $V$, y una flecha $V_j arrow.r V_i$ si $V_j in "pa"_i$. Este grafo —el mismo objeto que se usó informalmente en el @cap-causalidad-elemental para hablar de confusores— no es una descripción estadística sino una afirmación sobre *mecanismos*: cada ecuación $V_i = f_i ("pa"_i, U_i)$ representa un proceso físico, biológico, económico o social real, no simplemente una relación estadística ajustada a los datos. Esta es la diferencia esencial entre un modelo causal y un modelo predictivo: un modelo predictivo puede ajustar $Y$ en función de $X$ sin comprometerse con ninguna afirmación sobre mecanismos; un SCM afirma que si se *intervinieran* las causas de $Y$, $Y$ cambiaría exactamente según su ecuación estructural.

La conexión con el marco de resultados potenciales del capítulo anterior es directa: dado un SCM con variable de tratamiento $D$ y resultado $Y = f_Y (D, X, U_Y)$, el resultado potencial $Y(d)$ se define como el valor que toma la ecuación estructural de $Y$ al fijar $D = d$: $Y(d) := f_Y (d, X, U_Y)$. Los dos marcos son, bajo esta correspondencia, dos lenguajes para el mismo objeto.

=== Los tres niveles de la Jerarquía Causal de Pearl
<sec-scmpch-pch>

Cada SCM $M$ induce tres distribuciones de probabilidad distintas, que corresponden exactamente a los tres niveles adelantados en el @cap-causalidad-elemental:

#table(
  columns: (1fr, 2.3fr, 2.3fr),
  align: left,
  stroke: 0.5pt + gray.lighten(60%),
  table.header([*Nivel (PCH)*], [*Distribución inducida*], [*Se calcula con*]),
  [$cal(L)_1$ — Asociación], [$P(v)$: la distribución observacional conjunta de $V$], [Los datos observados, sin modificar $M$],
  [$cal(L)_2$ — Intervención], [$P(y | "do"(x))$: la distribución de $Y$ tras _reemplazar_ la ecuación de $X$ por la constante $x$], [El SCM "quirúrgicamente modificado" $M_x$ (se borra $f_X$ y se fija $X=x$)],
  [$cal(L)_3$ — Contrafactual], [$P(y_x | e)$: la distribución de "$Y$ hubiera sido $y$ si $X$ hubiera sido $x$", dada la evidencia $e$ efectivamente observada], [Un procedimiento de tres pasos: abducción, acción, predicción (ver más abajo)],
)

El operador $"do"(x)$ formaliza matemáticamente qué significa "intervenir": no es lo mismo *observar* que $X=x$ (lo que simplemente selecciona el subconjunto de unidades con $X=x$, y por tanto puede estar contaminado por confusión, como en las tres escenas del capítulo anterior) que *forzar* $X=x$ mediante una intervención externa que anula el mecanismo natural por el que $X$ se determinaba. Formalmente, $P(y | "do"(x)) != P(y | X=x)$ en general; ambas coinciden si y solo si no hay confusión entre $X$ y $Y$ —la condición que el resto del curso dedica tanto esfuerzo a verificar o inducir.

#example[
*Los tres niveles sobre el mismo SCM.* Considere el SCM simplificado $D = f_D (U_D)$, $Y = f_Y (D, X, U_Y)$, $X = f_X (U_X)$, con $U_D$ y $U_Y$ correlacionados (confusión no observada entre $D$ y $Y$). En $cal(L)_1$, $P(y | D=d)$ mezcla el efecto de $D$ sobre $Y$ con la correlación espuria inducida por $U_D, U_Y$ compartidos. En $cal(L)_2$, $P(y | "do"(D=d))$ se calcula sobre el modelo modificado donde $f_D$ se reemplaza por la constante $d$, cortando el vínculo entre $U_D$ y $D$ —y por tanto elimina exactamente la confusión—. En $cal(L)_3$, dado que se observó a un individuo específico con $D=0, Y=y_0$, la pregunta "¿qué $Y$ habría tenido si $D$ hubiera sido 1?" requiere primero *inferir* la distribución de $U_D, U_Y$ compatible con lo observado (abducción), luego *forzar* $D=1$ en el modelo (acción), y finalmente *propagar* para predecir $Y$ (predicción) — de ahí el nombre del procedimiento de tres pasos de Pearl para cómputo contrafactual.
]

Hay aquí un punto que suele perderse en presentaciones más elementales de esta jerarquía: la separación entre niveles no es una limitación práctica de los métodos disponibles, sino un resultado formal.

#theorem(name: [Teorema de la Jerarquía Causal])[
Sea $Omega$ el espacio de SCM sobre un conjunto de variables $V$, equipado con una medida de probabilidad natural sobre las funciones estructurales y las distribuciones exógenas. El conjunto de SCM para los cuales las distribuciones de nivel $cal(L)_(k+1)$ quedan *determinadas* por las de nivel $cal(L)_k$ tiene medida cero en $Omega$, para $k = 1, 2$.
] <thm-cht>

En términos operativos: salvo en un conjunto de casos excepcional (de medida nula), dos SCM distintos pueden inducir exactamente la misma distribución observacional $P(v)$ y, sin embargo, distintas distribuciones interventivas $P(y | "do"(x))$ —y análogamente entre $cal(L)_2$ y $cal(L)_3$—. Por eso ningún procedimiento que opere únicamente sobre $P(v)$ puede, sin supuestos adicionales, recuperar $P(y | "do"(x))$: la información simplemente no está ahí. El *Teorema de la Jerarquía Causal* (@bareinboim2022pch, Bareinboim et al. 2022) establece que las tres capas de la escalera causal son estrictamente disjuntas. Este resultado, presentado de forma integrada con el resto del programa de IA causal en @bareinboim2025causalai, es la razón formal —y no solo intuitiva— de la tesis del @cap-causalidad-elemental: los datos observacionales solos no responden preguntas causales.

Dos consecuencias prácticas se siguen inmediatamente, y estructuran el resto del curso. Primera: todo método de estimación causal a partir de datos observacionales —DML, PDS, meta-learners, bosques causales— debe importar información extra-datos, y esa información es siempre un supuesto de identificación (típicamente, la afirmación de que las covariables observadas cierran todas las rutas de puerta trasera, @cap-intervencion-contrafactual). Segunda: ese supuesto no se puede validar con los datos que se están usando, porque su función es precisamente suplir lo que los datos no contienen; a lo sumo puede *refutarse* si genera implicaciones observacionales que los datos contradicen (@sec-scmpch-caso), o someterse a análisis de sensibilidad (@cap-validacion). Ninguna cantidad de datos, ni ningún algoritmo, cambia esta situación.

== Algoritmo e implementación
<sec-scmpch-algoritmo>

El siguiente listado construye un SCM simple en Python —una versión estilizada del ejemplo de becas y calificaciones del Capítulo 1, con una variable de motivación $U$ no observada que confunde la relación entre beca ($D$) y calificación ($Y$)— y calcula numéricamente $P(y | D=1)$ ($cal(L)_1$) frente a $P(y | "do"(D=1))$ ($cal(L)_2$), mostrando que difieren.

#figure(
  kind: raw,
  caption: [SCM simulado: divergencia entre asociación e intervención.],
  ```python
import numpy as np
import pandas as pd

rng = np.random.default_rng(7)
n = 50_000

# U: motivación no observada (confusor de D y de Y)
U = rng.normal(size=n)

# D (beca): depende de U -- estudiantes mas motivados piden mas becas
D_obs = (U + rng.normal(size=n) > 0.3).astype(int)

# Y (calificacion): depende de D (efecto causal verdadero = 0.4) y de U
Y_obs = 0.4 * D_obs + 0.9 * U + rng.normal(scale=0.5, size=n)

df = pd.DataFrame({"U": U, "D": D_obs, "Y": Y_obs})

# Nivel 1 (asociacion): P(Y | D=1) observacional
assoc = df.loc[df["D"] == 1, "Y"].mean() - df.loc[df["D"] == 0, "Y"].mean()

# Nivel 2 (intervencion): simular do(D=1) para TODA la poblacion,
# reemplazando la ecuacion estructural de D por la constante 1
Y_do1 = 0.4 * 1 + 0.9 * U + rng.normal(scale=0.5, size=n)
Y_do0 = 0.4 * 0 + 0.9 * U + rng.normal(scale=0.5, size=n)
intervencion = Y_do1.mean() - Y_do0.mean()

print(f"Diferencia asociativa  P(Y|D=1)-P(Y|D=0):  {assoc:.3f}")
print(f"Efecto interventivo    P(Y|do(D=1))-do(0): {intervencion:.3f}")
print(f"Efecto causal verdadero (por construccion): 0.400")
# La diferencia asociativa esta inflada por la confusion via U;
# el efecto interventivo recupera el 0.4 verdadero porque do()
# anula el mecanismo que generaba D a partir de U.
```
) <lst-scm-do-simulacion>

En la práctica, no observamos $U$ ni podemos, literalmente, "reemplazar la ecuación de $D$" como en el listado —eso solo es posible porque el ejemplo es una simulación donde conocemos el SCM verdadero—. El problema aplicado de identificación, que el resto del curso desarrolla, es precisamente cómo estimar $P(y | "do"(x))$ *sin* conocer el SCM completo, usando solo datos observacionales más supuestos sobre el grafo (por ejemplo, con Post-Double-Selection o DML, si se asume no confusión condicional en las covariables observadas).

== Caso empírico: consistencia del grafo supuesto
<sec-scmpch-caso>

Antes de estimar cualquier efecto, es buena práctica verificar que el grafo causal supuesto sea *consistente* con las independencias condicionales observadas en los datos. El chequeo es *necesario pero no suficiente*, y el Teorema de la Jerarquía Causal explica por qué: varios grafos distintos pueden inducir exactamente el mismo conjunto de independencias condicionales —son observacionalmente equivalentes, y forman lo que el @cap-descubrimiento-grafos llamará su *clase de equivalencia de Markov*— de modo que pasar el test no distingue entre ellos. Lo que el test sí puede hacer es *refutar*: si el grafo implica una independencia que los datos rechazan, el grafo es incorrecto. Con el dataset de retornos a la educación de @card1995, ya usado en capítulos posteriores, un grafo que supone que la cercanía a una universidad (`nearc4`) afecta la educación pero no directamente el salario, controlando por educación, implica una independencia condicional testeable: `nearc4` y `wage` deberían ser independientes dado `educ` y el resto de covariables. `dowhy` y `causal-learn` implementan estos chequeos de forma automatizada (`refutar` en el primero, tests de independencia condicional en el segundo); ambos se detallan en el Apéndice B.

== Riesgos, límites y sensibilidad
<sec-scmpch-riesgos>

#riesgos[
  - *Confundir $P(y | X=x)$ con $P(y | "do"(x))$.* Es, con diferencia, el error más frecuente entre practicantes de _machine learning_ que se acercan por primera vez a la inferencia causal: tratar un filtro (`df[df.D==1]`) como si fuera una intervención. Son el mismo objeto solo si no hay confusión.
  - *Asumir que el grafo es "el verdadero".* Un SCM formaliza supuestos, no los verifica. Ningún test estadístico puede confirmar que un grafo causal es correcto —solo puede refutarlo si es inconsistente con los datos—. La responsabilidad de argumentar el grafo es del analista, no del algoritmo.
  - *Tratar $cal(L)_3$ como si fuera $cal(L)_2$.* Una pregunta contrafactual ("¿habría aprobado María si...?") no se responde con el mismo procedimiento que una pregunta interventiva poblacional ("¿qué pasaría si becáramos a todos?"). Colapsar ambas —muy común en comunicación de resultados a audiencias no técnicas— puede llevar a promesas que el modelo no puede respaldar.
]

== Ejercicios y notas bibliográficas
<sec-scmpch-ejercicios>

=== Ejercicios teóricos
<sec-scmpch-ejercicios-teoricos>

+ Escriba el SCM (variables, ecuaciones estructurales, grafo) para el ejemplo de la paradoja de Simpson del @cap-causalidad-elemental (tratamiento, gravedad del caso, recuperación). Indique cuál nodo es el confusor.

+ Para el SCM del ejercicio anterior, escriba explícitamente el modelo modificado $M_{"do"(D=1)}$ y explique, en términos del grafo, qué arista(s) desaparece(n).

+ Explique por qué, en general, $P(y | "do"(x))$ no puede calcularse a partir de $P(v)$ sin supuestos adicionales sobre el grafo (Teorema de la Jerarquía Causal). Dé un ejemplo de dos SCM distintos que induzcan la misma $P(v)$ pero distinta $P(y | "do"(x))$.

=== Ejercicios computacionales
<sec-scmpch-ejercicios-computacionales>

+ Modifique el listado @lst-scm-do-simulacion para que el efecto causal verdadero de $D$ sobre $Y$ sea 0 (sin efecto), manteniendo la confusión vía $U$. Verifique que la diferencia asociativa sigue siendo distinta de cero mientras que el efecto interventivo converge a 0.

+ Usando `causal-learn` o `dowhy` (Apéndice B), cargue el dataset `close_college` (Card, 1995) y ejecute un test de independencia condicional entre `nearc4` y `wage` dado `educ` y los controles estándar del @cap-prediccion-causalidad. ¿El resultado es consistente con el grafo supuesto en la @sec-scmpch-caso?

=== Notas bibliográficas
<sec-scmpch-notas>

La referencia canónica del Teorema de la Jerarquía Causal, incluida la construcción precisa de la medida sobre el espacio de SCM que da sentido a la expresión "medida cero", es #cite(<bareinboim2022pch>, form: "prose"); su enunciado aquí es deliberadamente informal en ese punto. El capítulo sigue por lo demás la formalización de @bareinboim2025causalai, fuente principal de contenido teórico-causal del curso, y la exposición clásica de @pearl2009causality, que introduce el operador $"do"()$, el procedimiento de tres pasos para cómputo contrafactual, y el cálculo-$"do"$ que se enuncia formalmente en el @cap-intervencion-contrafactual. #cite(<imbens2015causal>, form: "prose") discute en detalle la equivalencia formal entre el marco de resultados potenciales y el de SCM. Para una introducción visual y menos técnica a la jerarquía, véase nuevamente @pearlmackenzie2018, ya citado en el capítulo anterior.
