// Capítulo 23 (nuevo) — Explicación causal y equidad algorítmica
// Plantilla A (completa): Sesión 19. Abre la Parte VI.
#import "../template/template.typ": *

#chapter[Explicación causal y equidad algorítmica]
<cap-explicacion-equidad>

#theorem-number-reset()

#cuadrosinoptico[
  #table(
    columns: (auto, 1fr),
    align: (left, left),
    stroke: none,
    [*Problema:*], [Descomponer el efecto de un atributo protegido en rutas directas e indirectas],
    [*Estimando:*], [Efectos específicos por ruta (_path-specific effects_, PSE)],
    [*Identificación:*], [Grafo causal con rutas etiquetadas como legítimas o discriminatorias],
    [*Método:*], [Fórmulas de mediación de Pearl; equidad contrafactual],
    [*Garantía:*], [Descomposición exacta del efecto total en directo + indirecto + espurio bajo el grafo supuesto],
    [*Librerías:*], [`dowhy` (estimación de mediación)],
    [*Validación:*], [Sensibilidad al grafo de rutas propuesto],
  )
]

== Problema causal, estimando e identificación
<sec-explicacionequidad-problema>

El @cap-etica-interpretabilidad, que sigue a este capítulo, trata la interpretabilidad en el sentido más difundido en _machine learning_: explicaciones locales tipo SHAP que atribuyen una predicción a sus variables de entrada por su contribución estadística. Ese tipo de explicación es *asociativa*: describe cómo covarían las variables con la salida del modelo, no si esa covariación refleja un mecanismo causal legítimo o discriminatorio. Este capítulo, más cercano al programa de Bareinboim que al de interpretabilidad de modelos, pregunta algo distinto y más difícil: si un algoritmo de decisión (contratación, crédito, libertad condicional) produce resultados distintos según un atributo protegido —género, raza, origen—, *¿ese efecto pasa por una ruta legítima o por una discriminatoria?* Responder esto requiere descomponer el efecto total en sus componentes causales por ruta, no solo medirlo.

== Teoría, supuestos y garantías
<sec-explicacionequidad-teoria>

=== Efectos directos, indirectos y espurios
<sec-explicacionequidad-directoindirecto>

Considere un atributo protegido $A$ (por ejemplo, género), una variable mediadora $M$ que $A$ afecta legítimamente (por ejemplo, elección de ocupación) y un resultado $Y$ (por ejemplo, salario). El efecto total de $A$ sobre $Y$ se descompone en:

#definition(name: [Descomposición directo/indirecto])[
El *efecto directo controlado* (_controlled direct effect_, CDE) de $A$ sobre $Y$ fijando $M=m$ es $"CDE"(m) = E[Y | "do"(A=1, M=m)] - E[Y | "do"(A=0, M=m)]$: el efecto de $A$ sobre $Y$ que *no* pasa por $M$. El *efecto indirecto natural* (_natural indirect effect_, NIE) es la porción del efecto que sí pasa por el cambio que $A$ induce en $M$.
]

La pregunta de equidad no es si el efecto total de $A$ sobre $Y$ es distinto de cero —eso puede ser enteramente legítimo si pasa por una ruta que la organización considera aceptable (por ejemplo, si mujeres y hombres eligen, en promedio, ocupaciones distintas por preferencia genuina, y esas ocupaciones legítimamente pagan distinto)— sino si el *efecto directo*, la parte de $A$ sobre $Y$ que no pasa por ningún mediador legítimo, es distinto de cero. Un efecto directo significativo es la firma causal de discriminación, en el sentido más estricto y defendible del término.

=== Equidad contrafactual
<sec-explicacionequidad-contrafactual>

#cite(<kusner2017counterfactual>, form: "prose") formaliza una noción de equidad en el Nivel 3 de la PCH (@cap-scm-pch): una decisión $hat(Y)$ es *contrafactualmente justa* si, para cada individuo, $hat(Y)$ no habría sido distinta en el mundo contrafactual donde su atributo protegido fuera diferente, manteniendo todo lo demás que no dependiera causalmente de $A$ igual. Es una noción más exigente que la paridad demográfica o la igualdad de tasas de error entre grupos —ambas puramente asociativas, de Nivel 1— porque exige razonar sobre el mundo contrafactual específico de cada individuo, no solo sobre promedios poblacionales.

#cite(<kilbertus2017avoiding>, form: "prose") desarrollan la contraparte de Nivel 2 de esta idea y añaden una distinción que resulta operativa en el diseño de sistemas: la de *discriminación por proxy* frente a *influencia injusta no resuelta*. Un *proxy* es una variable que el algoritmo observa y que es descendiente del atributo protegido —el código postal como proxy de raza, el patrón de compras como proxy de género—; la discriminación por proxy se puede *eliminar por construcción*, interviniendo sobre el proxy en el modelo de decisión de modo que la ruta $A arrow.r "proxy" arrow.r hat(Y)$ quede cortada, sin necesidad de observar $A$. La *influencia no resuelta*, en cambio, es la que viaja por rutas que la organización no ha declarado legítimas pero que tampoco pasan por ninguna variable observable intervenible; esa no se puede eliminar con una restricción sobre el modelo, y exige una decisión normativa previa sobre qué rutas se aceptan.

La consecuencia práctica para el diseño de un sistema causal en producción es directa. Ante un algoritmo que discrimina, hay dos remedios de naturaleza distinta: uno *técnico*, que consiste en identificar los proxies en el grafo y neutralizarlos —factible, automatizable y verificable—; y uno *normativo*, que consiste en declarar qué rutas causales se consideran aceptables —que ningún método puede automatizar, y que este capítulo insiste en no disfrazar de decisión técnica—. Confundir ambos es el error característico de las auditorías de equidad que se limitan a eliminar variables sensibles del modelo: quitan $A$ y dejan intactos todos sus proxies, sin haber tocado ninguna de las dos fuentes reales del problema.

== Algoritmo e implementación
<sec-explicacionequidad-algoritmo>

#figure(
  kind: raw,
  caption: [Descomposición directo/indirecto con un SCM lineal simulado.],
  ```python
import numpy as np
import pandas as pd

rng = np.random.default_rng(3)
n = 20_000

# A: atributo protegido (0/1). M: mediador legitimo (ocupacion).
# Y: resultado (salario). Efecto directo deliberado (discriminacion) = 0.15
A = rng.binomial(1, 0.5, size=n)
M = 0.5 * A + rng.normal(scale=1, size=n)          # A afecta a M (legitimo)
Y = 0.15 * A + 0.6 * M + rng.normal(scale=1, size=n)  # A afecta a Y directo (0.15) + via M

df = pd.DataFrame({"A": A, "M": M, "Y": Y})

# Efecto total (asociativo, sin descomponer)
efecto_total = df.loc[df.A == 1, "Y"].mean() - df.loc[df.A == 0, "Y"].mean()

# Efecto directo controlado: fijar M en su media global y comparar A=1 vs A=0
m_fijo = df["M"].mean()
Y_directo_A1 = 0.15 * 1 + 0.6 * m_fijo
Y_directo_A0 = 0.15 * 0 + 0.6 * m_fijo
cde = Y_directo_A1 - Y_directo_A0

print(f"Efecto total A->Y:            {efecto_total:.3f}")
print(f"Efecto directo controlado:    {cde:.3f}  (deberia acercarse a 0.15)")
print(f"Efecto indirecto (via M):     {efecto_total - cde:.3f}")
# El efecto directo es la señal de discriminacion; el indirecto puede
# ser legitimo si M es una ruta que la organizacion acepta como valida.
```
) <lst-descomposicion-directo-indirecto>

En un caso real, `dowhy` implementa estimadores de mediación causal que no requieren conocer el SCM verdadero, siempre que el grafo de rutas —incluyendo cuáles se declaran legítimas— esté especificado.

== Caso empírico
<sec-explicacionequidad-caso>

Un caso clásico en la literatura de equidad algorítmica es la brecha salarial de género: el efecto total observado se descompone frecuentemente en una parte explicada por diferencias en ocupación, experiencia y sector (efecto indirecto, cuya legitimidad es en sí misma objeto de debate normativo, no solo estadístico) y un residuo no explicado por esas variables (aproximación al efecto directo). La literatura económica de descomposición salarial (Oaxaca-Blinder) es, de hecho, un antecesor estadístico de la misma idea formalizada aquí con lenguaje causal explícito —con la ventaja de que el lenguaje de rutas permite declarar explícitamente, antes de estimar, cuáles mediadores se consideran legítimos, en vez de dejarlo implícito en la elección de controles.

== Riesgos, límites y sensibilidad
<sec-explicacionequidad-riesgos>

#riesgos[
  - *Discriminación por proxy.* Una variable "legítima" $M$ puede estar, a su vez, afectada históricamente por $A$ de forma que perpetúa discriminación pasada (por ejemplo, si el acceso a cierta ocupación estuvo históricamente restringido por género). Declarar $M$ como mediador legítimo sin este análisis histórico puede blanquear discriminación indirecta.
  - *La legitimidad de una ruta es una decisión normativa, no estadística.* Ningún test estadístico determina si una ruta "debería" considerarse aceptable; esa es una decisión legal, ética y organizacional que el análisis causal formaliza pero no reemplaza.
  - *Sensibilidad al grafo.* Igual que en el @cap-intervencion-contrafactual, toda la descomposición depende de que el grafo de rutas propuesto sea correcto. Un mediador omitido puede inflar artificialmente el efecto directo estimado.
]

== Ejercicios y notas bibliográficas
<sec-explicacionequidad-ejercicios>

=== Ejercicios teóricos
<sec-explicacionequidad-ejercicios-teoricos>

+ Para el caso de la brecha salarial de género, proponga dos mediadores: uno que consideraría legítimo y uno que consideraría cuestionable de aceptar como legítimo, aun si estadísticamente media parte del efecto. Justifique la distinción normativa.

+ Explique, en sus propias palabras, por qué la equidad contrafactual de @kusner2017counterfactual es una noción de Nivel 3 de la PCH y no de Nivel 1, y por qué eso la hace más difícil de verificar empíricamente que la paridad demográfica.

=== Ejercicio computacional
<sec-explicacionequidad-ejercicios-computacionales>

+ Modifique el listado @lst-descomposicion-directo-indirecto para que el efecto directo verdadero sea 0 (ninguna discriminación directa, todo el efecto pasa por el mediador legítimo). Verifique numéricamente que el CDE estimado converge a 0 mientras el efecto indirecto se mantiene distinto de cero.

=== Notas bibliográficas
<sec-explicacionequidad-notas>

Las fórmulas de mediación causal y la descomposición directo/indirecto/espurio se desarrollan en @pearl2009causality y se sistematizan para el caso de equidad algorítmica en @bareinboim2025causalai, Capítulo 6. #cite(<kusner2017counterfactual>, form: "prose") introduce la equidad contrafactual como criterio formal de Nivel 3, y #cite(<kilbertus2017avoiding>, form: "prose") la contraparte de Nivel 2 con la distinción proxy / influencia no resuelta que estructura la @sec-explicacionequidad-contrafactual. El @cap-etica-interpretabilidad complementa este tratamiento causal con las definiciones observacionales estándar de la literatura de _fair machine learning_ —paridad demográfica, _equalized odds_, calibración— y con el resultado de imposibilidad que muestra que no pueden satisfacerse simultáneamente. La descomposición Oaxaca-Blinder, antecesora estadística de esta idea en economía laboral, se cubre en cualquier texto estándar de econometría aplicada.

=== Literatura complementaria de equidad causal

Otros enfoques incluyen:
- *Evitar discriminación mediante razonamiento causal* (@kilbertus2017avoiding, Kilbertus et al. 2017): construcción de grafos causales para identificar rutas de discriminación proxy
- *Descomposición de efectos en fairness:* trabajos de Nabi & Shpitser, y Zhang & Bareinboim sobre path-specific effects para separar discriminación directa vs. indirecta

La integración de fairness y causalidad es un área de investigación activa; ver @kusner2017counterfactual para fairness contrafactual.
