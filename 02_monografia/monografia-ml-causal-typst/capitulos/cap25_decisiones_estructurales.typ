// Capítulo 25 (nuevo) — Decisiones estructurales bajo incertidumbre
// Plantilla A (completa): Sesión 21.
#import "../template/template.typ": *

#chapter[Decisiones estructurales bajo incertidumbre]
<cap-decisiones-estructurales>

#theorem-number-reset()

#cuadrosinoptico[
  #table(
    columns: (auto, 1fr),
    align: (left, left),
    stroke: none,
    [*Problema:*], [Elegir entre acciones, no solo estimar el efecto de una acción dada],
    [*Estimando:*], [Utilidad esperada bajo cada acción candidata, $E[U(Y("do"(d)))]$],
    [*Identificación:*], [Identificación del efecto de cada $d$ candidato + función de utilidad declarada],
    [*Método:*], [Maximización de utilidad esperada sobre el conjunto de acciones factibles],
    [*Garantía:*], [La acción óptima estimada converge a la verdadera si los efectos de cada $d$ están correctamente identificados],
    [*Librerías:*], [`econml.policy`, optimización con `scipy.optimize`],
    [*Validación:*], [Comparación contra una decisión de referencia (_status quo_) y análisis de sensibilidad a la utilidad supuesta],
  )
]

== Problema causal, estimando e identificación
<sec-decisionesestructurales-problema>

El @cap-policy-learning (Capítulo 21) ya resolvió una versión de este problema: dado un CATE estimado, ¿a quién asignar un tratamiento binario bajo una restricción de presupuesto? Este capítulo generaliza la pregunta en dos direcciones que Bareinboim formaliza bajo el nombre de *decisiones estructurales*: primero, la acción no tiene por qué ser binaria ni consistir en "tratar o no tratar" a cada unidad — puede ser elegir entre varias políticas alternativas, fijar un parámetro continuo, o intervenir sobre más de una variable simultáneamente; segundo, la decisión requiere una *función de utilidad* explícita, no solo un efecto estimado, porque comparar acciones distintas exige poder decir cuánto vale cada resultado posible, no solo cuál es más probable.

== Teoría, supuestos y garantías
<sec-decisionesestructurales-teoria>

=== La decisión como maximización de utilidad esperada
<sec-decisionesestructurales-formalizacion>

#definition(name: [Decisión óptima])[
Dado un conjunto de acciones factibles $cal(D)$ y una función de utilidad $U: cal(Y) arrow.r RR$ que asigna un valor a cada resultado posible, la *acción óptima* es
$ d^* = op("argmax", limits: #true)_(d in cal(D)) E[U(Y("do"(d)))] $
donde $E[U(Y("do"(d)))]$ se calcula usando la distribución interventiva de Nivel 2 de la PCH (@cap-scm-pch) inducida por cada acción candidata $d$.
]

La diferencia con el problema de estimación de los capítulos anteriores es sutil pero importante: estimar $tau(x)$ responde "¿cuál es el efecto?"; resolver $d^*$ responde "¿qué debería hacerse?", y esta segunda pregunta *siempre* requiere una función de utilidad, aunque sea implícita. Cuando el @cap-policy-learning maximizaba el "valor de la política" sujeto a un presupuesto, esa era ya una función de utilidad particular —lineal en el resultado, con una restricción de costo—; este capítulo hace explícito que esa elección de utilidad es, en sí misma, una decisión de modelado con consecuencias.

=== Decisiones sobre múltiples variables y el rol de la incertidumbre
<sec-decisionesestructurales-multivariable>

Cuando la acción involucra más de una variable de intervención (por ejemplo, elegir simultáneamente el monto de una transferencia y el requisito de asistencia a capacitaciones), el conjunto $cal(D)$ deja de ser un simple binario o un umbral y se vuelve un espacio multidimensional. La incertidumbre entra por dos vías distintas, que conviene no confundir: *incertidumbre estadística* sobre el efecto de cada acción (el mismo tipo de incertidumbre que ya se cuantifica con los intervalos de confianza de capítulos anteriores) e *incertidumbre estructural* sobre si el SCM supuesto es siquiera el correcto (la que ningún intervalo de confianza captura, y que solo un análisis de sensibilidad al grafo, como el del @cap-intervencion-contrafactual, puede abordar parcialmente).

=== Criterios de decisión cuando el efecto no está identificado con precisión
<sec-decisionesestructurales-criterios>

Maximizar la utilidad esperada usando la estimación puntual $hat(E)[U(Y("do"(d)))]$ es el criterio por defecto, pero no es el único defendible, y su adopción implícita esconde un supuesto fuerte: que la incertidumbre sobre el efecto puede resumirse en una media y tratarse como si el estimador puntual fuera el valor verdadero. La teoría estadística de la decisión ofrece un vocabulario preciso para las alternativas, y #cite(<manski2004statistical>, form: "prose") lo trasladó al problema exacto de este capítulo —elegir una regla de tratamiento cuando el efecto está *parcialmente identificado*, es decir, cuando los datos y los supuestos solo acotan $tau$ dentro de un intervalo en vez de fijarlo—.

Tres criterios cubren el espectro de posturas razonables ante esa situación:

#table(
  columns: (1.2fr, 1.8fr, 2fr),
  align: left,
  stroke: 0.5pt + gray.lighten(60%),
  table.header([*Criterio*], [*Qué maximiza*], [*Cuándo es defendible*]),
  [Utilidad esperada], [$E[U(Y("do"(d)))]$ bajo la estimación puntual], [Efecto bien identificado y estimado con precisión; decisión repetida muchas veces, de modo que los promedios se realizan],
  [_Maximin_ (Wald)], [El peor resultado posible dentro del conjunto identificado: $max_d min_(tau in cal(T)) U$], [Decisiones irreversibles o con consecuencias catastróficas en el peor escenario; aversión fuerte a la ambigüedad],
  [_Minimax regret_ (Savage)], [La máxima pérdida respecto a la mejor acción posible en cada escenario], [Cuando el maximin resulta paralizante por concentrarse en escenarios extremos poco plausibles; es el criterio que Manski defiende para reglas de tratamiento],
)

La diferencia entre ellos no es académica: con un efecto cuyo intervalo de confianza cruza el cero, la utilidad esperada puede recomendar intervenir (porque el punto estimado es positivo) mientras el maximin recomienda no hacerlo (porque el peor caso es dañino), y el minimax regret puede recomendar una acción intermedia —tratar a un subconjunto, o postergar la decisión hasta recolectar más datos—. Reportar cuál de los tres criterios se aplicó es tan importante como reportar el efecto estimado, porque la recomendación de política depende de ambos.

Esto conecta además con una decisión que el marco de utilidad esperada suele dejar fuera del conjunto $cal(D)$ y que casi siempre debería estar dentro: la acción *"no decidir todavía y experimentar"*. Cuando la incertidumbre es la restricción vinculante, el valor de un experimento aleatorizado —que reduce esa incertidumbre— compite legítimamente con el valor de las acciones sustantivas, y omitirlo del conjunto de acciones factibles sesga sistemáticamente la decisión hacia intervenir con la información actual.

== Algoritmo e implementación
<sec-decisionesestructurales-algoritmo>

#figure(
  kind: raw,
  caption: [Selección de acción óptima entre tres políticas candidatas con incertidumbre.],
  ```python
import numpy as np

# Tres politicas candidatas para un programa social, cada una con un
# efecto estimado (media, error estandar) y un costo distinto
politicas = {
    "sin_intervencion": {"efecto": 0.0, "se": 0.0, "costo": 0},
    "transferencia_simple": {"efecto": 0.12, "se": 0.03, "costo": 500},
    "transferencia_mas_capacitacion": {"efecto": 0.19, "se": 0.05, "costo": 900},
}

def utilidad_esperada(efecto, costo, valor_por_punto_efecto=3000, presupuesto=1000):
    """Utilidad: valor monetario del efecto menos el costo,
    con penalizacion fuerte si excede presupuesto."""
    if costo > presupuesto:
        return -np.inf
    return valor_por_punto_efecto * efecto - costo

for nombre, datos in politicas.items():
    u = utilidad_esperada(datos["efecto"], datos["costo"])
    # bandas de utilidad usando +/- 1.96 SE del efecto, para reportar incertidumbre
    u_low = utilidad_esperada(datos["efecto"] - 1.96 * datos["se"], datos["costo"])
    u_high = utilidad_esperada(datos["efecto"] + 1.96 * datos["se"], datos["costo"])
    print(f"{nombre:30s} U={u:8.1f}  IC95%=({u_low:.1f}, {u_high:.1f})")

mejor = max(politicas, key=lambda k: utilidad_esperada(politicas[k]["efecto"], politicas[k]["costo"]))
print(f"\nAccion optima bajo esta utilidad: {mejor}")
```
) <lst-decision-optima>

El listado reporta no solo la utilidad puntual de cada acción sino su intervalo, precisamente porque una acción con mayor utilidad puntual pero con un intervalo que se solapa ampliamente con el de otra no debería declararse "claramente superior" sin más análisis — el mismo espíritu de reporte honesto de incertidumbre que el Capítulo 15 exigió en la respuesta del servicio desplegado.

== Caso empírico
<sec-decisionesestructurales-caso>

Retomando el dataset de transferencias condicionadas usado en capítulos anteriores del curso: una decisión estructural real no es solo "¿a quién dar la transferencia?" (Capítulo 21) sino, con frecuencia, "¿qué diseño de programa implementar?" entre varias alternativas con distintos costos administrativos y efectos esperados —transferencia simple, transferencia con condicionalidad, transferencia con componente de capacitación—. El listado @lst-decision-optima estiliza exactamente esta comparación, y el punto pedagógico central es que la acción óptima depende críticamente de `valor_por_punto_efecto`, un parámetro normativo (cuánto vale, en términos monetarios comparables, un punto de mejora en el resultado) que ningún dato por sí solo puede determinar.

== Riesgos, límites y sensibilidad
<sec-decisionesestructurales-riesgos>

#riesgos[
  - *Función de utilidad implícita y no examinada.* Toda decisión automatizada usa alguna función de utilidad, aunque nadie la haya escrito explícitamente (a menudo es, por defecto, "maximizar el efecto promedio sin considerar costos ni distribución"). Hacerla explícita, como en este capítulo, permite auditarla; dejarla implícita no la elimina, solo la esconde.
  - *Sensibilidad de la decisión a la utilidad supuesta.* Dos analistas razonables pueden discrepar en `valor_por_punto_efecto` y llegar a decisiones óptimas distintas con el mismo efecto estimado. Reportar cómo cambia $d^*$ bajo utilidades alternativas es una buena práctica, análoga al análisis de sensibilidad a supuestos de identificación.
  - *Confundir incertidumbre estadística con incertidumbre estructural.* Un intervalo de confianza estrecho sobre el efecto de una acción no dice nada sobre si el SCM supuesto para calcular ese efecto es correcto. Ambas fuentes de incertidumbre son relevantes para la decisión final y no deben mezclarse en un único número.
]

== Ejercicios y notas bibliográficas
<sec-decisionesestructurales-ejercicios>

=== Ejercicios teóricos
<sec-decisionesestructurales-ejercicios-teoricos>

+ Explique por qué el problema de policy learning del Capítulo 21 (a quién tratar bajo presupuesto) es un caso particular del problema de decisión estructural de este capítulo, identificando explícitamente cuál es $cal(D)$ y cuál es $U$ en ese caso.

+ Para el caso empírico de la @sec-decisionesestructurales-caso, proponga una función de utilidad alternativa que dé peso explícito a la equidad distributiva (por ejemplo, que penalice que el efecto se concentre en un subgrupo). ¿Cambiaría la acción óptima?

=== Ejercicio computacional
<sec-decisionesestructurales-ejercicios-computacionales>

+ Modifique el listado @lst-decision-optima con al menos dos valores distintos de `valor_por_punto_efecto` (uno bajo, uno alto) y reporte si la acción óptima cambia. Discuta qué implica esto para la robustez de la recomendación de política.

+ Extienda el listado @lst-decision-optima para que, además de la utilidad esperada, calcule la acción óptima según los criterios _maximin_ y _minimax regret_ de la @sec-decisionesestructurales-criterios, tomando como conjunto identificado el intervalo $hat(tau) plus.minus 1.96 dot.c "SE"$ de cada política. ¿Coinciden las tres recomendaciones? Repita ampliando el error estándar de `transferencia_mas_capacitacion` a 0.10 y explique por qué los criterios divergen cuando la incertidumbre crece.

=== Notas bibliográficas
<sec-decisionesestructurales-notas>

Este capítulo sigue la formalización de decisiones estructurales de @bareinboim2025causalai, Capítulo 7. El marco formal de *teoría de la decisión bajo incertidumbre* se trata en @berger1985statistical (Berger 1985). Para decisiones con *identificación parcial* (bounds en lugar de estimados puntuales), ver @manski2004statistical (Manski 2004), que formaliza reglas de tratamiento bajo incertidumbre estructural. Para el aparato de teoría de la decisión estadística —funciones de pérdida, criterios de admisibilidad, maximización de utilidad esperada bajo incertidumbre— la referencia estándar es #cite(<berger1985statistical>, form: "prose"). #cite(<manski2004statistical>, form: "prose") es la lectura clave de la @sec-decisionesestructurales-criterios y la que conecta ambos mundos: formula la elección de una regla de tratamiento como un problema de decisión bajo *identificación parcial*, desarrolla el criterio de minimax regret para ese contexto y deriva sus implicaciones para la asignación fraccional de tratamientos. Es también el antecedente directo de la _Empirical Welfare Maximization_ del @cap-policy-learning, que puede leerse como el caso en que el efecto sí está puntualmente identificado. El @cap-policy-learning y el @cap-uplift-targeting son los casos particulares de este marco más aplicados en la práctica de targeting.
