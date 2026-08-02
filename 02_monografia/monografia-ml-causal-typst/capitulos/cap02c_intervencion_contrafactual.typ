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
    [*[Problema]*], [Decidir, a partir de un grafo causal, qué controles identifican el efecto y cuáles lo sesgan],
    [*[Estimando]*], [$P(y mid "do"(x))$ y $P(y_x mid e)$],
    [*[Identificación]*], [Criterio de puerta trasera (_backdoor_); reglas del cálculo-$"do"$],
    [*[Método]*], [Ajuste por puerta trasera; abducción-acción-predicción para contrafactuales],
    [*[Garantía]*], [Si el criterio de puerta trasera se satisface, $P(y mid "do"(x)) = sum_z P(y mid x,z) P(z)$],
    [*[Librerías]*], [`dowhy`, `networkx`],
    [*[Validación]*], [Verificación algorítmica del criterio sobre el DAG propuesto],
  )
]

== Problema causal, estimando e identificación
<sec-intervcontra-problema>

El @cap-scm-pch dejó pendiente una pregunta operativa: dado un grafo causal y un conjunto de variables observadas, ¿cómo se determina *qué controles incluir* para que un ajuste estadístico —una regresión, un _matching_, un DML— recupere efectivamente $P(y mid "do"(x))$ en lugar de $P(y mid x)$? La intuición de "controlar por todo lo que se pueda medir" es, como se muestra en este capítulo, no solo insuficiente sino activamente peligrosa: hay variables que, controladas, *introducen* sesgo donde no lo había. Este capítulo formaliza el criterio que resuelve esta pregunta —el criterio de puerta trasera— y extiende el procedimiento de cómputo contrafactual adelantado en el capítulo anterior.

== Teoría, supuestos y garantías
<sec-intervcontra-teoria>

=== El criterio de puerta trasera
<sec-intervcontra-backdoor>

#definition(name: [Criterio de puerta trasera])[
Un conjunto de variables $Z$ satisface el *criterio de puerta trasera* relativo a un par ordenado $(X,Y)$ en un grafo $G$ si: *(i)* ningún nodo de $Z$ es descendiente de $X$, y *(ii)* $Z$ bloquea todo camino entre $X$ e $Y$ que contenga una flecha *hacia* $X$ (un "camino de puerta trasera").
]

#theorem(name: [Fórmula de ajuste de puerta trasera])[
Si $Z$ satisface el criterio de puerta trasera relativo a $(X,Y)$, entonces el efecto causal de $X$ sobre $Y$ es identificable y está dado por la *fórmula de ajuste*:
$ P(y mid "do"(x)) = sum_z P(y mid x, z) thin P(z) $
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

La fila de mediadores explica formalmente algo que ya se mencionó en el @cap-ingenieria-datos-causales sin desarrollar: por qué una variable "post-tratamiento" es peligrosa como control, incluso si parece un predictor razonable de $Y$ — con probabilidad no trivial es un mediador (controla por parte del efecto que se busca medir) o un collider (introduce sesgo de selección).

=== Cómputo contrafactual: abducción, acción, predicción
<sec-intervcontra-contrafactual>

El @cap-scm-pch adelantó el procedimiento de tres pasos para responder preguntas de $cal(L)_3$. Formalizado: dado un SCM $M$ y evidencia observada $e$ sobre una unidad específica, calcular $P(y_x mid e)$ requiere:

+ *Abducción*: actualizar $P(u)$ a $P(u mid e)$ — inferir, a partir de lo observado, qué configuración de variables exógenas es consistente con la evidencia.
+ *Acción*: construir el modelo modificado $M_x$, reemplazando la ecuación de $X$ por la constante $x$ (idéntico al paso interventivo del capítulo anterior).
+ *Predicción*: calcular $Y$ en $M_x$ usando la distribución actualizada $P(u mid e)$ del paso de abducción, en lugar de la $P(u)$ original.

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

En la práctica, `dowhy` automatiza esta verificación y además identifica automáticamente conjuntos de puerta trasera válidos dado un grafo declarado por el usuario, con la función `identify_effect()`; el Apéndice B documenta su uso completo.

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

=== Ejercicios computacionales
<sec-intervcontra-ejercicios-computacionales>

+ Instale `dowhy` (Apéndice B) y reproduzca la verificación del listado @lst-backdoor-check usando `identify_effect()` en lugar de la función manual. Compare el conjunto de ajuste que identifica automáticamente con el usado en el capítulo.

=== Notas bibliográficas
<sec-intervcontra-notas>

El criterio de puerta trasera y las reglas completas del cálculo-$"do"$ se presentan en @pearl2009causality; la clasificación de buenos y malos controles sigue la sistematización de @bareinboim2025causalai. Para una implementación aplicada con Python, `dowhy` (Sharma y Kiciman) es la referencia de facto, documentada en el Apéndice B de este curso.
