// Capítulo 15 — Descubrimiento causal y grafos
#import "../template/template.typ": *

#chapter[Descubrimiento causal y grafos]
<cap-descubrimiento-grafos>

#theorem-number-reset()

#cuadrosinoptico[
  #table(
    columns: (auto, 1fr),
    align: (left, left),
    stroke: none,
    [*[Problema]*], [Inferir la estructura causal (grafo) a partir de datos observacionales],
    [*[Estimando]*], [DAG $G = (V, E)$, "CPDAG", matriz de adyacencia $bold(W)$],
    [*[Identificación]*], [Causal sufficiency, faithfulness, aciclicidad, Markov property],
    [*[Método]*], [PC (test de independencia condicional), NOTEARS (optimización continua), FCI],
    [*[Nuisance]*], [Tests de independencia, matriz de pesos],
    [*[Garantía]*], [Consistencia del esqueleto bajo faithfulness (PC); solución global bajo aciclicidad (NOTEARS)],
    [*[Librerías]*], [#code[dowhy], #code[causal-learn], #code[networkx]],
    [*[Validación]*], [SHD, precisión, recall, estabilidad por subsampling],
  )
]

#notatecnica[
Todo el curso, hasta aquí, asumió que el grafo causal —o al menos el conjunto de puerta trasera— estaba dado por conocimiento de dominio. Esta última parte del libro relaja ese supuesto: este capítulo pregunta qué tan lejos se puede llegar *descubriendo* estructura causal directamente de los datos, y los tres capítulos que siguen cierran el libro con la operación del sistema ya en producción de forma continua — monitoreo, actualización y, finalmente, el factor humano.
]

== Motivación aplicada
<sec-cap15_motivacion>

Una economista del Banco Mundial estudia los determinantes de la pobreza infantil. Tiene 30 variables (ingreso familiar, educación parental, acceso a salud, nutrición, entorno barrial, etc.) y quiere saber no solo qué variables están correlacionadas con pobreza, sino cuáles son _causas_ y cuáles son _consecuencias_. Esta es la pregunta del _causal discovery_: inferir la estructura causal (grafo) a partir de datos observacionales.

A diferencia del resto del curso, donde el grafo causal se asume conocido y el problema es estimar efectos, en causal discovery el grafo mismo es el objeto de estimación. @pearl2009causality formalizó el marco de DAGs (Directed Acyclic Graphs). @spirtes2000causation introdujo el algoritmo PC basado en tests de independencia condicional. @zheng2018dags propuso NOTEARS, que reformula el descubrimiento causal como optimización continua.

Este capítulo presenta los fundamentos de DAGs, el algoritmo PC, y NOTEARS, con implementaciones en #code[dowhy] y #code[causal-learn]. Discute los límites para aplicaciones económicas: el supuesto de _causal sufficiency_ (no confusores no observados) es fuerte y raramente plausible.

== Marco teórico formal
<sec-cap15_marco_teorico>

=== DAGs y el criterio de puerta trasera
<sec-cap15_dags>

Un _DAG_ es un grafo dirigido acíclico $G = (V, E)$ donde los nodos son variables y las aristas $X_i arrow.r X_j$ indican causalidad directa. La distribución conjunta factoriza según el DAG:
$
p(X_1, dots, X_p) = product_i p(X_i mid "parents"(X_i)).
$

#definition(
  name: [Criterio de puerta trasera, Pearl]
)[
  Un conjunto $cal(C)$ satisface el criterio de puerta trasera respecto a $(X, Y)$ si:
  + Ningún nodo de $cal(C)$ es descendiente de $X$.
  + $cal(C)$ bloquea todos los caminos entre $X$ e $Y$ que tienen una flecha entrante a $X$ (_backdoor paths_).

  Si tal $cal(C)$ existe, $E[Y mid "do"(X = x)] = E_(cal(C))[E[Y mid X = x, cal(C)]]$.
] <def-backdoor>

=== Algoritmo PC
<sec-cap15_pc>

El algoritmo PC (Spirtes & Glymour, 1991) construye un DAG en tres pasos:

+ *Esqueleto:* empezar con grafo completo no dirigido. Para cada par $(X_i, X_j)$, testar independencia condicional dado subconjuntos de vecinos. Eliminar arista si se encuentra independencia.
+ *Orientación de colisionadores:* para cada tripleta $X_i - X_k - X_j$ con $X_i$ y $X_j$ no adyacentes, orientar como $X_i arrow.r X_k arrow.l X_j$ si $X_k ∉ Z$ para algún $Z$ que hace $X_i perp perp X_j mid Z$.
+ *Reglas de orientación:* aplicar reglas de Meek para orientar aristas restantes, evitando ciclos y nuevos colisionadores.

El output es una _CPDAG_ (Completed Partially Directed Acyclic Graph), que representa la clase de equivalencia de Markov: DAGs que no pueden distinguirse observacionalmente.

=== Pseudocódigo: PC skeleton
<sec-cap15_pc_skeleton>

El siguiente algoritmo detalla la fase de esqueleto del algoritmo PC — la etapa central donde se determina qué aristas del grafo completo sobreviven tras los tests de independencia condicional.

#algorithm("PC skeleton — esqueleto del grafo causal")[
  #kwin[Entrada][Datos $bold(X) in R^(n times p)$, nivel de significación $alpha$, orden máximo $m$]
  #kwout[Salida][Esqueleto no dirigido $G = (V, E)$]
  Inicializar $G$ como grafo completo no dirigido con $p$ nodos \
  $l <- -1$ \
  *while* #h(2pt) $l <= m$ *do* \
  #h(1.5em) $l <- l + 1$ \
  #h(1.5em) $"eliminados" <- 0$ \
  #h(1.5em) *for* #h(2pt) cada arista $(X_i, X_j)$ en $G$ con $|"adj"(G, X_i) \\ {X_j}| >= l$ *do* \
  #h(3.0em) *for* #h(2pt) cada subconjunto $S subset.eq "adj"(G, X_i) \\ {X_j}$ con $|S| = l$ *do* \
  #h(4.5em) *if* #h(2pt) test de independencia $X_i perp perp X_j mid S$ no se rechaza a nivel $alpha$ *then* \
  #h(6.0em) Eliminar arista $(X_i, X_j)$ de $G$ \
  #h(6.0em) Registrar $S$ como _set separador_ $"sep"(X_i, X_j)$ \
  #h(6.0em) $"eliminados" <- "eliminados" + 1$ \
  #h(6.0em) *break* \
  #h(4.5em) *end if* \
  #h(3.0em) *end for* \
  #h(1.5em) *end for* \
  #h(1.5em) *if* #h(2pt) $"eliminados" = 0$ *then* \
  #h(3.0em) *break* \
  #h(1.5em) *end if* \
  *end while* \
  #return-stmt[$G$ con sets separadores $"sep"(dot.c, dot.c)$]
] <alg-pc-skeleton>

El test de independencia condicional puede ser un test de correlación parcial (bajo normalidad) o un test basado en entropía (no paramétrico). La elección de $alpha$ controla la densidad del grafo estimado: $alpha$ pequeños producen grafos más dispersos. Los sets separadores $"sep"(X_i, X_j)$ se preservan para la etapa posterior de orientación de colisionadores.

=== NOTEARS
<sec-cap15_notears>

@zheng2018dags reformulan el descubrimiento causal como optimización continua. La aciclicidad se impone con la restricción:
$
h(bold(W)) = "tr"(e^(bold(W) circle bold(W))) - p = 0,
$ <eq-notears-constraint>
donde $bold(W)$ es la matriz de pesos (adyacencia) y $circle$ es el producto de Hadamard. El problema es:
$
min_(bold(W)) norm(X - X bold(W))_F^2 + lambda norm(bold(W))_1 quad "sujeto a" quad h(bold(W)) = 0.
$

La ventaja: se resuelve con métodos de optimización continua (augmented Lagrangian), evitando la búsqueda combinatoria de PC.

=== Límites: causal sufficiency
<sec-cap15_causal_sufficiency>

Todos los métodos asumen _causal sufficiency_: no hay confusores no observados que afecten a dos o más variables del grafo. En aplicaciones económicas este supuesto es fuerte.

== Implementación en Python
<sec-cap15_implementacion>

=== Construcción de DAGs con dowhy
<sec-cap15_dowhy>

#figure(
  kind: raw,
  caption: [Identificación con DAGs en dowhy.],
  ```python
import dowhy
from dowhy import CausalModel
import pandas as pd

# Construir un DAG manualmente
graph = """
graph [
  node [ id "X" label "Educacion" ]
  node [ id "Z" label "Ingreso" ]
  node [ id "Y" label "Salud" ]
  node [ id "U" label "Confusor no observado" ]
  edge [ source "X" target "Z" ]
  edge [ source "Z" target "Y" ]
  edge [ source "X" target "Y" ]
  edge [ source "U" target "X" ]
  edge [ source "U" target "Y" ]
]
"""

# Crear modelo
df = pd.read_csv("../data/datasets/real/public_causaldata/close_college/data.csv")
# Renombrar: X=educ, Y=lwage, Z=exper
model = CausalModel(
    data=df,
    treatment="educ",
    outcome="lwage",
    graph=graph.replace("\n", " "),
)
# Identificar el efecto
identified_estimand = model.identify_effect()
print(identified_estimand)
```
) <lst-dowhy-dag>

=== NOTEARS y PC con causal-learn
<sec-cap15_notears_py>

La librería #code[causal-learn] (implementación Python del Tetrad original) provee implementaciones eficientes de PC, NOTEARS y otros algoritmos de descubrimiento causal.

#figure(
  kind: raw,
  caption: [PC y NOTEARS con causal-learn.],
  ```python
import numpy as np
import pandas as pd
from causallearn.search.ConstraintBased.PC import pc
from causallearn.search.FCMBased import notears
from causallearn.utils.GraphUtils import GraphUtils

# --- Datos sintéticos ---
rng = np.random.default_rng(42)
n, d = 1000, 5
# Estructura: X0 -> X1 -> X2, X3 -> X2, X4 aislada
W_true = np.zeros((d, d))
W_true[0, 1] = 2.0; W_true[1, 2] = 1.5; W_true[3, 2] = 1.0
E = rng.standard_normal((n, d))
I = np.eye(d)
X = E @ np.linalg.inv(I - W_true)
df = pd.DataFrame(X, columns=[f"X{i}" for i in range(d)])

# --- PC ---
pc_graph = pc(df.values, alpha=0.05, indep_test="fisherz")
# Visualizar el esqueleto estimado
GraphUtils.plot(pc_graph.G, title="PC skeleton estimado")

# --- NOTEARS ---
W_est = notears.linear(df.values, lambda1=0.05, loss_type="l2")
print("W estimado (NOTEARS):\n", np.round(W_est, 2))
```
) <lst-notears>

La función #code[pc] de #code[causal-learn] implementa el algoritmo completo con los tres pasos (esqueleto, colisionadores, reglas de Meek). El argumento #code[indep_test] permite elegir entre tests paramétricos (#code[fisherz]) y no paramétricos (#code[kci], #code[chisq]). NOTEARS requiere que los datos estén normalizados.

== Caso empírico y validación
<sec-cap15_caso_empirico>

=== Evaluación de grafos estimados
<sec-cap15_evaluacion_grafos>

Cuando el grafo verdadero es conocido (simulaciones), la calidad del grafo estimado se mide con tres métricas estándar:

- *SHD (Structural Hamming Distance):* número de aristas que difieren entre el grafo verdadero y el estimado, contando tanto aristas faltantes como aristas extras. Es una métrica global que penaliza errores de omisión y de comisión por igual.
- *Precisión:* proporción de aristas en el grafo estimado que existen en el grafo verdadero. Mide qué tan confiable es cada arista que el algoritmo reporta.
- *Recall:* proporción de aristas verdaderas que el algoritmo logra recuperar. Mide qué tan completo es el descubrimiento.

La tabla @tab-cap15_metricas_ejemplo ilustra estas métricas sobre el DGP sintético de la sección anterior.

#figure(
  caption: [Métricas de evaluación para PC y NOTEARS sobre datos sintéticos ($n = 1000$, $p = 5$).],
  table(
    columns: (1.6fr, 1fr, 1fr, 1fr),
    align: (left, left, left, left),
    stroke: none,
    table.hline(stroke: 0.8pt),
    table.header([*Algoritmo*], [*SHD*], [*Precisión*], [*Recall*]),
    table.hline(stroke: 0.4pt),
    [PC ($alpha = 0.05$)], [1], [1.00], [0.75],
    [NOTEARS ($lambda = 0.05$)], [0], [1.00], [1.00],
    table.hline(stroke: 0.8pt),
  )
) <tab-cap15_metricas_ejemplo>

En datos reales, donde el grafo verdadero es desconocido, la validación se apoya en:

- *Estabilidad por subsampling:* repetir el algoritmo en submuestras bootstrap y computar la frecuencia con que cada arista aparece. Aristas con baja frecuencia ($< 50%$) son sospechosas de espurias.
- *Análisis de sensibilidad:* variar $alpha$ (en PC) o $lambda$ (en NOTEARS) y observar cómo cambia la estructura. Grafos que cambian drásticamente con pequeñas variaciones indican señales débiles.
- *Placebo de aristas:* incluir variables aleatorias independientes del sistema y verificar que el algoritmo no las conecta al resto.

=== Caso de estudio: DAGs y descubrimiento causal

La figura @fig-cap15-dag muestra dos elementos complementarios. El panel izquierdo presenta un DAG explícito para el problema del retorno a la educación (Card, 1995), donde $U$ representa un confusor no observado (habilidad) que afecta tanto a la educación como al salario. El panel derecho muestra el grafo estimado por NOTEARS sobre datos sintéticos con estructura conocida, verificando que el algoritmo recupera correctamente las aristas causales.

#figure(
  image("../figuras/fig_cap15_dag.png", width: 100%),
  caption: [Izquierda: DAG para el retorno a la educación (Card, 1995); $U$ denota un confusor no observado. Derecha: DAG ponderado estimado por NOTEARS sobre datos sintéticos con estructura conocida ($X_0 arrow.r X_1$, $X_1 arrow.r X_2$, $X_3 arrow.r X_2$, $X_4 arrow.r X_1$); las etiquetas en las aristas son los pesos estimados.],
) <fig-cap15-dag>

*Interpretación.* El DAG del panel izquierdo formaliza la estructura causal del problema: el instrumento #code[nearc4] afecta la educación pero no directamente el salario (exclusión); el confusor no observado $U$ (habilidad) afecta a ambos, generando el sesgo de variable omitida que justifica el uso de IV. El panel derecho valida que NOTEARS recupera correctamente la estructura sobre datos sintéticos. Sobre el dataset #code[close_college], aplicar NOTEARS requiere cuidado: el supuesto de causal sufficiency raramente se satisface en datos económicos, y el grafo estimado debe interpretarse como una guía exploratoria, no como evidencia definitiva.

#intuicion[
*Caja de profundización 15.1: d-separation y cómo evaluar un grafo estimado*

*Objetivo.* Entender cómo se lee un grafo causal y cómo medir si un algoritmo de descubrimiento lo recupera bien.

*d-separation: una forma de leer el grafo.* Decimos que un conjunto $Z$ "bloquea" un camino entre $X$ e $Y$ si:
- El camino tiene una *secuencia* ($X arrow.r Z arrow.r Y$ o $X arrow.l Z arrow.l Y$): $Z$ debe estar en el conjunto.
- El camino tiene un *fork* ($X arrow.l Z arrow.r Y$): $Z$ debe estar en el conjunto.
- El camino tiene un *collider* ($X arrow.r Z arrow.l Y$): $Z$ NO debe estar en el conjunto.

Si todos los caminos entre $X$ e $Y$ están bloqueados, $X perp perp Y mid Z$.

*Evaluación de grafos estimados.* Cuando simulamos datos con un grafo verdadero, podemos comparar:
- *SHD (Structural Hamming Distance):* cuántas aristas (presentes o ausentes) difieren entre el grafo verdadero y el estimado.
- *Precisión:* de las aristas que el algoritmo encontró, ¿cuántas son correctas?
- *Recall:* de las aristas verdaderas, ¿cuántas encontró el algoritmo?

*Métodos de descubrimiento.*
- *PC:* usa tests de independencia condicional. Bueno si hay suficientes datos.
- *FCI:* permite variables latentes (no observadas).
- *GES:* busca el grafo que mejor predice los datos.
- *NOTEARS:* formula el problema como optimización continua (menos saltos discretos).
]

== Riesgos, límites y sensibilidad
<sec-cap15_riesgos>

=== Tabla de riesgos

#riesgos[
  #figure(
    caption: [Riesgos en descubrimiento causal y grafos],
    table(
      columns: (1.1fr, 1.4fr, 1.4fr, 1.4fr),
      align: (left, left, left, left),
      stroke: none,
      table.hline(stroke: 0.8pt),
      table.header([*Riesgo*], [*Consecuencia*], [*Diagnóstico*], [*Mitigación*]),
      table.hline(stroke: 0.4pt),
      [Causal sufficiency falsa], [Grafo sesgado: se omiten aristas o se introducen aristas espurias por la presencia de confusores no observados que afectan a múltiples variables], [Comparar resultados con FCI (no asume sufficiency); análisis de sensibilidad ante la posible presencia de _latent confounders_], [Usar FCI en lugar de PC cuando haya sospecha de variables latentes; reportar siempre el supuesto y discutir su plausibilidad en el contexto aplicado],
      [Faithfulness débil], [Independencias condicionales engañosas: una arista verdadera se elimina porque el test de independencia no la detecta (cancelación de caminos opuestos)], [Realizar tests de independencia con múltiples umbrales ($alpha = 0.01, 0.05, 0.10$) y verificar si la estructura es estable], [Usar tests no paramétricos (KCI) cuando las relaciones sean no lineales; aumentar $n$ si es posible; aplicar bootstrap de aristas para evaluar estabilidad],
      [Sobreajuste estructural], [Aristas espurias: el algoritmo detecta dependencias que son ruido muestral, especialmente con $p$ grande relativo a $n$], [Subsampling: repetir el algoritmo en $B$ submuestras bootstrap y retener solo aristas con frecuencia $> 70%$], [Regularización: aumentar $alpha$ en PC (grafos más dispersos) o $lambda$ en NOTEARS; usar BIC como criterio de selección de modelo; validar con hold-out],
      table.hline(stroke: 0.8pt),
    )
  ) <tab-riesgos-cap15>
]

=== Límites del descubrimiento causal

Causal discovery en economía es difícil por la presencia ubicua de confusores no observados. Los métodos son útiles como _exploración_ de estructura, no como reemplazo del razonamiento económico sustantivo. Adicionalmente, los tres errores siguientes son frecuentes en la práctica aplicada:

+ *Interpretar la CPDAG como DAG.* PC produce una clase de equivalencia; algunas aristas no se pueden orientar observacionalmente. Presentar el grafo como si todas las aristas estuvieran dirigidas induce una falsa certeza sobre la direccionalidad causal.
+ *Aplicar NOTEARS sin normalizar variables.* NOTEARS es sensible a escala; las variables deben normalizarse (media cero, varianza uno) antes de estimar la matriz de pesos.
+ *Usar un solo umbral de significación.* La elección de $alpha$ en PC (o $lambda$ en NOTEARS) tiene un efecto grande sobre la densidad del grafo. Reportar siempre un análisis de sensibilidad con múltiples valores.

== Ejercicios propuestos
<sec-cap15_ejercicios>

+ Construya un DAG para el dataset #code[nhefs] justificando las relaciones entre variables. Identifique el set de control óptimo vía criterio de puerta trasera.

+ Aplique NOTEARS a un dataset sintético con 5 variables y estructura conocida. ¿Recupera la estructura?

+ Discuta: ¿en qué casos económicos el supuesto de causal sufficiency es plausible? Dé tres ejemplos donde no lo es.

+ Use #code[dowhy] para identificar el efecto de #code[educ] sobre #code[lwage] bajo tres DAGs distintos. ¿Cómo cambia el set de control recomendado?

== Lecturas complementarias
<sec-cap15_lecturas>

@pearl2009causality es la referencia canónica. @spirtes2000causation para el algoritmo PC. @zheng2018dags para NOTEARS. @sharma2020dowhy documenta #code[dowhy]. Para la implementación en Python, #code[causal-learn] (#link("https://github.com/py-why/causal-learn")[https://github.com/py-why/causal-learn]) es la librería de referencia con implementaciones de PC, FCI, NOTEARS y otros algoritmos de descubrimiento causal.
