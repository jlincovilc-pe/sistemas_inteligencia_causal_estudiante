// Capítulo 8 (nuevo) — Razonamiento intervencional y contrafactual
// Plantilla A (completa): Sesión 7.
#import "../template/template.typ": *

#chapter[Razonamiento intervencional y contrafactual]
<cap-intervencion-contrafactual>

#theorem-number-reset()

#cuadrosinoptico[
  #table(
    columns: (auto, 1fr),
    align: (left, left),
    stroke: none,
    [*Problema:*], [Decidir, a partir de un grafo causal, qué controles identifican el efecto y cuáles lo sesgan],
    [*Estimando:*], [$P(y | "do"(x))$ y $P(y_x | e)$],
    [*Identificación:*], [Criterio de puerta trasera (_backdoor_); las tres reglas del cálculo-$"do"$; puerta delantera (_front-door_)],
    [*Método:*], [Ajuste por puerta trasera; abducción-acción-predicción para contrafactuales],
    [*Garantía:*], [Si el criterio de puerta trasera se satisface, $P(y | "do"(x)) = sum_z P(y | x,z) P(z)$. El cálculo-$"do"$ es completo: si sus reglas no identifican el efecto, ningún método lo hace con ese grafo],
    [*Librerías:*], [`dowhy`, `networkx`],
    [*Validación:*], [Verificación algorítmica del criterio sobre el DAG propuesto],
  )
]

== Problema causal, estimando e identificación
<sec-intervcontra-problema>

El @cap-scm-pch dejó pendiente una pregunta operativa: dado un grafo causal y un conjunto de variables observadas, ¿cómo se determina *qué controles incluir* para que un ajuste estadístico —una regresión, un _matching_, un DML— recupere efectivamente $P(y | "do"(x))$ en lugar de $P(y | x)$? La intuición de "controlar por todo lo que se pueda medir" es, como se muestra en este capítulo, no solo insuficiente sino activamente peligrosa: hay variables que, controladas, *introducen* sesgo donde no lo había. Este capítulo formaliza el criterio que resuelve esta pregunta —el criterio de puerta trasera— y extiende el procedimiento de cómputo contrafactual adelantado en el capítulo anterior.

== Teoría, supuestos y garantías
<sec-intervcontra-teoria>

=== El criterio de puerta trasera
<sec-intervcontra-backdoor>

#definition(name: [Criterio de puerta trasera])[
Un conjunto de variables $Z$ satisface el *criterio de puerta trasera* relativo a un par ordenado $(X,Y)$ en un grafo $G$ si: *(i)* ningún nodo de $Z$ es descendiente de $X$, y *(ii)* $Z$ bloquea todo camino entre $X$ e $Y$ que contenga una flecha *hacia* $X$ (un "camino de puerta trasera").
]

#theorem(name: [Fórmula de ajuste de puerta trasera])[
Si $Z$ satisface el criterio de puerta trasera relativo a $(X,Y)$, entonces el efecto causal de $X$ sobre $Y$ es identificable y está dado por la *fórmula de ajuste*:
$ P(y | "do"(x)) = sum_z P(y | x, z) thin P(z) $
]

#proof(kind: "sketch")[
La condición *(i)* garantiza que condicionar en $Z$ no bloquea el efecto de $X$ sobre $Y$ a través de la ruta causal directa (no se controla por un mediador). La condición *(ii)* garantiza que $Z$ bloquea toda ruta espuria —toda confusión— entre $X$ e $Y$. Bajo ambas, condicionar en $Z$ dentro de cada estrato hace que $X$ esté "como aleatorizado", y promediar sobre la distribución de $Z$ recupera la distribución interventiva poblacional.
]

El supuesto de "no confusión condicional" (_unconfoundedness_) que se ha usado sin más formalidad en los capítulos anteriores —y que sustenta a DML, a los meta-learners y a los bosques causales de la Parte II— es, exactamente, la afirmación de que las covariables observadas $X$ satisfacen el criterio de puerta trasera relativo al tratamiento y al resultado. Este capítulo no cambia ningún método de estimación posterior; cambia *cómo se justifica*, con un grafo explícito, la elección de qué controlar.

=== Buenos y malos controles
<sec-intervcontra-controles>

El criterio de puerta trasera implica una clasificación de variables candidatas a control que conviene memorizar, porque el error de incluir un mal control es, en la práctica aplicada, más frecuente que el de omitir un confusor:

#table(
  columns: (1.3fr, 2.5fr, 1.3fr),
  align: left,
  stroke: 0.5pt + gray.lighten(60%),
  table.header([*Tipo de variable*], [*Rol en el grafo*], [*¿Controlar?*]),
  [Confusor], [Causa común de $X$ e $Y$ (afecta a ambos)], [*Sí* — necesario para puerta trasera],
  [Mediador], [Está en la ruta causal $X arrow.r M arrow.r Y$], [*No* — bloquea parte del efecto que se quiere medir],
  [Collider], [Es afectado tanto por $X$ como por $Y$ (o por sus causas)], [*No* — condicionar en él *crea* una asociación espuria (ver @sec-introcausal-escenas)],
  [Instrumento], [Afecta a $Y$ solo a través de $X$, no comparte causa con $Y$], [*No* como control directo — se usa de otro modo (Parte III, DML-IV)],
  [Variable post-tratamiento], [Medida después de $X$, potencialmente afectada por él], [*No* — riesgo de ser mediador o collider sin que el analista lo note],
)

La fila de mediadores explica formalmente algo que ya se mencionó en el @cap-ingenieria-datos-causales sin desarrollar: por qué una variable "post-tratamiento" es peligrosa como control, incluso si parece un predictor razonable de $Y$ — con probabilidad no trivial es un mediador (controla por parte del efecto que se busca medir) o un collider (introduce sesgo de selección). La fila de colliders es la que más sorprende a quien viene de _machine learning_ predictivo, porque contradice el reflejo de "controlar por todo": #cite(<elwert2014endogenous>, form: "prose") documentan cómo este *sesgo de selección endógena* aparece de forma encubierta en la práctica aplicada, no solo al añadir un control explícito, sino cada vez que la muestra misma se define condicionando en una variable afectada por el tratamiento (restringir el análisis a quienes completaron el programa, a quienes siguen siendo clientes, a quienes respondieron la encuesta de seguimiento).

El tratamiento formal del **sesgo por collider** y su rol en selección de controles se desarrolla en @elwert2014endogenous (Elwert & Winship 2014).

=== Las tres reglas del cálculo-$"do"$
<sec-intervcontra-docalculus>

Este capítulo formaliza el **criterio de puerta trasera** con su prueba completa. Las tres reglas del **cálculo-$"do"$** (*do-calculus*, @pearl2009causality, Pearl 2009) proporcionan un sistema completo para determinar identificabilidad causal en grafos arbitrarios; su automatización se implementa en `dowhy` (@sharma2020dowhy).

El criterio de puerta trasera resuelve el caso más frecuente, pero no es la herramienta general. Hay grafos donde ningún conjunto observado satisface el criterio y, sin embargo, el efecto *sí* es identificable por otra vía. La herramienta completa es el *cálculo-$"do"$*: tres reglas de reescritura que permiten transformar una expresión que contiene el operador $"do"()$ en otra equivalente, con el objetivo de eliminar todos los $"do"$ y quedar con una fórmula puramente observacional —es decir, estimable con los datos.

La notación requiere dos operaciones de "cirugía" sobre el grafo $G$. Escribimos $G_(overline(X))$ para el grafo que resulta de *borrar todas las flechas que entran* a los nodos de $X$ (el grafo bajo la intervención $"do"(x)$, donde $X$ deja de responder a sus causas) y $G_(underline(Z))$ para el que resulta de *borrar todas las flechas que salen* de los nodos de $Z$. Ambas operaciones pueden combinarse. La relación $(A perp perp B | C)_G$ denota $d$-separación de $A$ y $B$ dado $C$ en el grafo $G$.

#theorem(name: [Cálculo-$"do"$])[
Sea $G$ el grafo causal de un SCM y sean $X, Y, Z, W$ conjuntos disjuntos de nodos. Las tres igualdades siguientes son válidas siempre que se cumpla la condición gráfica indicada a la derecha.

*Regla 1 (inserción/eliminación de observaciones).* Permite descartar una variable observada que es irrelevante bajo la intervención:
$
P(y | "do"(x), z, w) = P(y | "do"(x), w) quad "si" quad (Y perp perp Z | X, W)_(G_(overline(X))).
$

*Regla 2 (intercambio de acción por observación).* Permite reemplazar un $"do"$ por un condicionamiento ordinario —el paso que convierte una cantidad no estimable en una estimable:
$
P(y | "do"(x), "do"(z), w) = P(y | "do"(x), z, w) quad "si" quad (Y perp perp Z | X, W)_(G_(overline(X) underline(Z))).
$

*Regla 3 (inserción/eliminación de acciones).* Permite descartar una intervención que no afecta al resultado:
$
P(y | "do"(x), "do"(z), w) = P(y | "do"(x), w) quad "si" quad (Y perp perp Z | X, W)_(G_(overline(X) overline(Z(W)))),
$
donde $Z(W)$ es el subconjunto de nodos de $Z$ que no son ancestros de ningún nodo de $W$ en $G_(overline(X))$.
] <thm-do-calculus>

Las tres reglas son *válidas* (todo lo que derivan es correcto) y, además, *completas*: si un efecto es identificable a partir del grafo y de la distribución observacional, existe una secuencia finita de aplicaciones de estas tres reglas que produce su fórmula; y si no existe tal secuencia, el efecto no es identificable —ningún método, por sofisticado que sea, puede recuperarlo con esos datos y ese grafo—. Esta completitud es lo que convierte al cálculo-$"do"$ en un procedimiento de decisión y no solo en un conjunto de trucos: `dowhy` lo implementa internamente en `identify_effect()`, de modo que cuando la librería responde que un efecto no es identificable, esa respuesta es una afirmación matemática y no una limitación del software.

La fórmula de ajuste de puerta trasera es, desde este punto de vista, un corolario. Si $Z$ satisface el criterio, la Regla 2 justifica el paso central —reemplazar $P(y | "do"(x), z)$ por $P(y | x, z)$, legítimo porque condicionar en $Z$ bloquea todas las rutas de puerta trasera y deja por tanto a $Y$ y $X$ #box[$d$-separados] en $G_(underline(X))$— y la Regla 3 justifica que $P(z | "do"(x)) = P(z)$, porque ningún nodo de $Z$ es descendiente de $X$. Sumando sobre $z$ se obtiene $P(y | "do"(x)) = sum_z P(y | x, z) P(z)$.

=== Cuando la puerta trasera falla: el criterio de puerta delantera
<sec-intervcontra-frontdoor>

El valor práctico del cálculo-$"do"$ se aprecia mejor en un caso donde la puerta trasera *no* sirve. Suponga el grafo $X arrow.r M arrow.r Y$ con un confusor no observado $U$ que afecta a $X$ y a $Y$ pero no a $M$ salvo a través de $X$. No existe ningún conjunto observado que bloquee la ruta $X arrow.l U arrow.r Y$ —$U$ no se observa— y, por tanto, ningún ajuste por covariables identifica el efecto. Sin embargo, el mediador $M$ ofrece una vía alternativa: el efecto de $X$ sobre $M$ es identificable (no hay confusión entre ellos), el efecto de $M$ sobre $Y$ es identificable ajustando por $X$ (que bloquea la ruta $M arrow.l X arrow.l U arrow.r Y$), y encadenando ambos se recupera el efecto total:
$
P(y | "do"(x)) = sum_m P(m | x) sum_(x') P(y | m, x') P(x').
$

Esta es la *fórmula de puerta delantera* (_front-door_), derivable por aplicación sucesiva de las tres reglas. El punto conceptual, y la razón de incluirla en un curso orientado a la práctica, es doble. Primero: la identificación no se reduce a "encontrar los controles correctos"; el conocimiento sobre *mecanismos* —saber que todo el efecto de $X$ sobre $Y$ pasa por $M$— es una fuente de identificación tan legítima como el conocimiento sobre confusores, y a veces la única disponible. Segundo, y como advertencia: el supuesto de que *ninguna* ruta directa $X arrow.r Y$ escapa a $M$ es fuerte y raramente defendible en datos económicos, razón por la cual la puerta trasera, y no la delantera, sigue siendo el caballo de batalla de los métodos de la Parte II.

=== Cómputo contrafactual: abducción, acción, predicción
<sec-intervcontra-contrafactual>

El @cap-scm-pch adelantó el procedimiento de tres pasos para responder preguntas de $cal(L)_3$. Formalizado: dado un SCM $M$ y evidencia observada $e$ sobre una unidad específica, calcular $P(y_x | e)$ requiere:

+ *Abducción*: actualizar $P(u)$ a $P(u | e)$ — inferir, a partir de lo observado, qué configuración de variables exógenas es consistente con la evidencia.
+ *Acción*: construir el modelo modificado $M_x$, reemplazando la ecuación de $X$ por la constante $x$ (idéntico al paso interventivo del capítulo anterior).
+ *Predicción*: calcular $Y$ en $M_x$ usando la distribución actualizada $P(u | e)$ del paso de abducción, en lugar de la $P(u)$ original.

La diferencia crucial con el cómputo interventivo puro es el paso de abducción: una pregunta contrafactual siempre está condicionada por lo que efectivamente se observó de esa unidad específica, mientras que una pregunta interventiva pura pregunta por el efecto promedio poblacional sin condicionar en ninguna observación particular.

== Algoritmo e implementación
<sec-intervcontra-algoritmo>

#figure(
  kind: raw,
  caption: [Verificación del criterio de puerta trasera con `networkx`.],
  ```python
import networkx as nx

# Grafo: educ (X) -> wage (Y); ability (confusor) -> educ, wage;
# test_score (mediador) : educ -> test_score -> wage
G = nx.DiGraph([
    ("ability", "educ"), ("ability", "wage"),
    ("educ", "wage"),
    ("educ", "test_score"), ("test_score", "wage"),
])

def satisface_puerta_trasera(G, X, Y, Z):
    G_sin_salientes_X = G.copy()
    G_sin_salientes_X.remove_edges_from(list(G.out_edges(X)))
    # (i) ningun nodo de Z es descendiente de X
    descendientes_X = nx.descendants(G, X)
    if any(z in descendientes_X for z in Z):
        return False, "Z contiene un descendiente de X (posible mediador)"
    # (ii) Z separa X de Y en el grafo sin las aristas salientes de X
    bloqueado = not nx.has_path(G_sin_salientes_X.to_undirected(), X, Y) or \
                nx.is_d_separator(G_sin_salientes_X, {X}, {Y}, set(Z))
    if not bloqueado:
        return False, "Z no bloquea todos los caminos de puerta trasera"
    return True, "Z satisface el criterio de puerta trasera"

print(satisface_puerta_trasera(G, "educ", "wage", {"ability"}))
print(satisface_puerta_trasera(G, "educ", "wage", {"ability", "test_score"}))
# El segundo caso debe fallar: test_score es un mediador (descendiente de X)
```
) <lst-backdoor-check>

En la práctica, `dowhy` automatiza esta verificación y además identifica automáticamente conjuntos de puerta trasera válidos dado un grafo declarado por el usuario, con la función `identify_effect()`; el Apéndice B documenta su uso completo. Esa misma función busca, además, estimandos por puerta delantera (@sec-intervcontra-frontdoor) y por variable instrumental cuando la puerta trasera falla, aplicando internamente el cálculo-$"do"$ — de modo que su salida "no identificable" debe leerse con el peso que le da la completitud del cálculo: no es que la librería no sepa cómo, es que con ese grafo y esos datos no se puede.

== Caso empírico
<sec-intervcontra-caso>

Retomando el dataset de retornos a la educación: si el analista incluyera `test_score` (una prueba de habilidad tomada *después* de completar los años de educación reportados) como control en la regresión de `wage` sobre `educ`, estaría, según la clasificación de la @sec-intervcontra-controles, controlando por un mediador parcial —parte del efecto de la educación sobre el salario opera precisamente a través de habilidades que la prueba mide—, sesgando el coeficiente de `educ` hacia abajo. El listado @lst-backdoor-check verifica exactamente esto: el conjunto `{ability, test_score}` falla el criterio de puerta trasera, mientras que `{ability}` solo lo satisface.

== Riesgos, límites y sensibilidad
<sec-intervcontra-riesgos>

#riesgos[
  - *"Más controles siempre es más seguro".* Es falso en general: agregar un mediador o un collider puede introducir sesgo donde una especificación más parca no lo tenía. El criterio de puerta trasera formaliza exactamente cuándo agregar un control ayuda y cuándo perjudica.
  - *Confundir un instrumento con un confusor.* Un instrumento válido no debe controlarse directamente como si fuera una covariable de puerta trasera; su rol es distinto y se explota con métodos específicos (DML-IV, Parte III). Incluirlo como control puede, dependiendo del grafo, introducir sesgo de collider si comparte una causa no observada con $Y$.
  - *El grafo es siempre una hipótesis.* Todo lo desarrollado en este capítulo presupone que el grafo declarado es correcto. Ningún algoritmo puede generar el grafo desde los datos solos sin supuestos adicionales (el @cap-descubrimiento-grafos, más adelante en el curso, aborda qué tan lejos se puede llegar con descubrimiento automatizado, y sus límites).
]

== Ejercicios y notas bibliográficas
<sec-intervcontra-ejercicios>

=== Ejercicios teóricos
<sec-intervcontra-ejercicios-teoricos>

+ Para el grafo del listado @lst-backdoor-check, agregue una variable `neighborhood` que sea causa común de `ability` y de `wage` (pero no de `educ`). ¿Sigue `{ability}` satisfaciendo el criterio de puerta trasera? Justifique con el grafo modificado.

+ Explique, en el lenguaje de este capítulo, por qué condicionar en un collider crea una correlación espuria (retome el ejemplo del tamaño del pie y la capacidad de lectura del @cap-causalidad-elemental, agregando explícitamente un collider).

+ Aplique el procedimiento de abducción-acción-predicción a un ejemplo numérico simple: un SCM lineal $Y = 2X + U$, $X = U + epsilon$, con $U tilde N(0,1)$. Dado que se observó $X=1, Y=3$, calcule $P(Y_{X=2})$, el valor contrafactual de $Y$ si $X$ hubiera sido 2.

+ Derive la fórmula de ajuste de puerta trasera a partir de las tres reglas del cálculo-$"do"$ de la @sec-intervcontra-docalculus, indicando explícitamente qué regla justifica cada paso y qué condición de $d$-separación se invoca en cada caso.

+ Para el grafo de puerta delantera de la @sec-intervcontra-frontdoor ($X arrow.r M arrow.r Y$ con $U$ no observado afectando a $X$ e $Y$), añada una flecha directa $X arrow.r Y$. Explique por qué la fórmula de puerta delantera deja de ser válida y qué supuesto sustantivo se estaría violando.

=== Ejercicios computacionales
<sec-intervcontra-ejercicios-computacionales>

+ Instale `dowhy` (Apéndice B) y reproduzca la verificación del listado @lst-backdoor-check usando `identify_effect()` en lugar de la función manual. Compare el conjunto de ajuste que identifica automáticamente con el usado en el capítulo.

=== Notas bibliográficas
<sec-intervcontra-notas>

El criterio de puerta trasera, las tres reglas del cálculo-$"do"$, su completitud y la fórmula de puerta delantera se presentan en @pearl2009causality, Capítulo 3, que es la referencia canónica para todo el aparato de identificación gráfica de este capítulo; la clasificación de buenos y malos controles sigue la sistematización de @bareinboim2025causalai. #cite(<elwert2014endogenous>, form: "prose") es el tratamiento de referencia del sesgo por _collider_ y de sus formas encubiertas (selección muestral, atrición, condicionamiento en supervivencia), y es la lectura más útil para quien deba auditar un pipeline de datos ya construido. Para una implementación aplicada con Python, #cite(<sharma2020dowhy>, form: "prose") documenta `dowhy`, la referencia de facto, cubierta en el Apéndice B de este curso.
