// Capítulo 26 (nuevo) — Generalización y transportabilidad entre dominios
// Plantilla A (completa): Sesión 24. Cierra la Parte VI.
#import "../template/template.typ": *

#chapter[Generalización y transportabilidad entre dominios]
<cap-generalizacion-transportabilidad>

#theorem-number-reset()

#cuadrosinoptico[
  #table(
    columns: (auto, 1fr),
    align: (left, left),
    stroke: none,
    [*[Problema]*], [Determinar si un efecto estimado en un dominio es válido en otro],
    [*[Estimando]*], [El efecto en el dominio destino, $P^*(y mid "do"(x))$],
    [*[Identificación]*], [Diagrama de selección: qué mecanismos difieren entre dominio fuente y destino],
    [*[Método]*], [Teoría de transportabilidad (Bareinboim y Pearl)],
    [*[Garantía]*], [Si el efecto es transportable, existe una fórmula que lo calcula combinando datos de ambos dominios],
    [*[Librerías]*], [Sin implementación estándar madura; análisis mayormente conceptual/gráfico],
    [*[Validación]*], [Replicación en el dominio destino cuando sea posible; análisis de sensibilidad a diferencias no modeladas],
  )
]

== Problema causal, estimando e identificación
<sec-generalizacion-problema>

Toda _model card_ causal de este curso (Capítulo 19) incluyó, desde su primera versión, una sección de "población de entrenamiento" con una advertencia explícita de no usar el modelo fuera de ese dominio. Este capítulo formaliza exactamente qué significa "fuera de ese dominio" y bajo qué condiciones —no nunca, no siempre— un efecto estimado en una población puede aplicarse legítimamente a otra. La noción informal de "validez externa", tratada en econometría aplicada casi siempre de forma cualitativa, tiene una versión formal y verificable en el marco de la PCH: la *transportabilidad*.

== Teoría, supuestos y garantías
<sec-generalizacion-teoria>

=== Diagramas de selección
<sec-generalizacion-diagramas>

#definition(name: [Diagrama de selección])[
Un *diagrama de selección* es un grafo causal aumentado con nodos especiales $S$ (uno por cada mecanismo que se sospecha difiere entre el dominio fuente $Pi$ y el dominio destino $Pi^*$), con una flecha $S_i arrow.r V_i$ indicando que el mecanismo que genera $V_i$ puede diferir entre dominios. Variables sin nodo $S$ entrante comparten el mismo mecanismo generador en ambos dominios.
]

Por ejemplo, si un efecto se estimó en una población urbana ($Pi$) y se quiere aplicar a una población rural ($Pi^*$), y se sospecha que la distribución de ingresos difiere entre ambas pero el mecanismo por el cual el ingreso afecta al resultado es el mismo, el diagrama de selección tendría un nodo $S$ apuntando a la variable de ingreso (su *distribución* difiere) pero no a la ecuación estructural que relaciona ingreso con el resultado (su *mecanismo* es el mismo).

#theorem(name: [Transportabilidad, versión informal])[
Dado un diagrama de selección, el efecto $P^*(y mid "do"(x))$ en el dominio destino es *transportable* desde el dominio fuente si existe una fórmula que lo expresa en términos de: *(i)* cantidades estimables con datos experimentales o cuasi-experimentales del dominio fuente $Pi$, y *(ii)* cantidades observacionales del dominio destino $Pi^*$ (típicamente, la distribución de las variables marcadas por $S$).
]

El resultado central de @bareinboimpearl2013transportability es un algoritmo completo —análogo al cálculo-$"do"$ del @cap-intervencion-contrafactual— que determina, para cualquier diagrama de selección, si el efecto es transportable y, si lo es, produce la fórmula de transporte explícita.

=== Por qué esto no es lo mismo que "reestimar con más datos"
<sec-generalizacion-noreesestimar>

Vale la pena distinguir la transportabilidad de dos prácticas más simples con las que suele confundirse. No es lo mismo que *agrupar los datos de ambos dominios y reestimar*: si los mecanismos efectivamente difieren, agrupar sin más introduce sesgo, no lo elimina. Tampoco es lo mismo que *reentrenar el modelo con datos del dominio destino*, la opción por defecto en un sistema puramente predictivo (@cap-anatomia-sistema): reentrenar requiere datos etiquetados del dominio destino, que con frecuencia no existen —es precisamente la situación en la que la teoría de transportabilidad aporta algo que el _machine learning_ estándar no ofrece, al permitir, bajo el diagrama correcto, extrapolar sin datos nuevos del destino.

== Algoritmo e implementación
<sec-generalizacion-algoritmo>

#figure(
  kind: raw,
  caption: [Chequeo simplificado: ¿el destino difiere solo en la distribución de una covariable?],
  ```python
import numpy as np
import pandas as pd

def efecto_transportado_por_reponderacion(df_fuente, df_destino, covariable, tratamiento, resultado):
    """Caso simple y frecuente de transportabilidad: el mecanismo
    Y = f(D, X) es el mismo en ambos dominios, solo difiere P(X).
    La formula de transporte es un ATE reponderado por la densidad
    de la covariable en el dominio destino."""
    efecto_por_estrato = (
        df_fuente.groupby(covariable)
        .apply(lambda g: g.loc[g[tratamiento] == 1, resultado].mean()
                        - g.loc[g[tratamiento] == 0, resultado].mean())
    )
    peso_destino = df_destino[covariable].value_counts(normalize=True)
    comunes = efecto_por_estrato.index.intersection(peso_destino.index)
    efecto_transportado = (efecto_por_estrato[comunes] * peso_destino[comunes]).sum()
    return efecto_transportado

# Ejemplo: efecto estimado por estrato de experiencia en el dominio fuente,
# reponderado por la distribucion de experiencia del dominio destino
```
) <lst-transporte-reponderacion>

Este caso —transportar reponderando por la distribución de una covariable observada en ambos dominios— es el escenario más simple y frecuente en la práctica; el algoritmo general de @bareinboimpearl2013transportability cubre casos bastante más complejos, donde el mecanismo mismo (no solo la distribución de una covariable) difiere entre dominios, y que exceden el alcance de este curso.

== Caso empírico
<sec-generalizacion-caso>

El estimador de retorno a la educación de Card (1995), usado en varios capítulos del curso y publicado como ejemplo en el Capítulo 19, se estimó sobre una población de hombres jóvenes en Estados Unidos en los años setenta. Aplicarlo, sin más, a una población de otro país o de otra década requiere preguntarse explícitamente: ¿el mecanismo por el cual la educación afecta al salario —vía productividad, señalización, redes— es razonablemente estable entre esos dominios, o solo la *distribución* de las covariables difiere? Si lo primero, ninguna fórmula de transporte simple lo resuelve, y el efecto simplemente no es transportable sin supuestos adicionales fuertes; si lo segundo, una reponderación como la del listado @lst-transporte-reponderacion podría ser defendible.

== Riesgos, límites y sensibilidad
<sec-generalizacion-riesgos>

#riesgos[
  - *Asumir transportabilidad sin diagrama.* La práctica más común en ciencia aplicada —aplicar un modelo entrenado en un contexto a otro sin justificación explícita— es, en el lenguaje de este capítulo, asumir un diagrama de selección vacío (nada difiere) sin argumentarlo.
  - *Confundir "no hay evidencia de que difiera" con "no difiere".* La ausencia de un chequeo de transportabilidad no es evidencia de que el efecto transporte; es, simplemente, ausencia de análisis.
  - *Sobreextender la fórmula de transporte a mecanismos que sí cambiaron.* Incluso cuando existe una fórmula de transporte válida para las diferencias declaradas en el diagrama de selección, cualquier diferencia de mecanismo no anticipada en el diagrama invalida la fórmula.
]

== Ejercicios y notas bibliográficas
<sec-generalizacion-ejercicios>

=== Ejercicios teóricos
<sec-generalizacion-ejercicios-teoricos>

+ Para el ejemplo de la @sec-generalizacion-teoria (población urbana a rural), dibuje el diagrama de selección descrito y explique, en sus propias palabras, qué se necesitaría medir en el dominio rural para aplicar la fórmula de transporte.

+ Explique por qué "reentrenar el modelo con datos del dominio destino" no es una opción disponible en muchos de los casos de uso reales que motivan la teoría de transportabilidad.

=== Ejercicio computacional
<sec-generalizacion-ejercicios-computacionales>

+ Simule dos dominios con la misma ecuación estructural $Y = 0.4 D + 0.5 X + epsilon$ pero distinta distribución de $X$ (por ejemplo, $X tilde N(0,1)$ en el dominio fuente y $X tilde N(1, 1.5)$ en el destino). Use el listado @lst-transporte-reponderacion para transportar el efecto y compare contra el efecto verdadero simulado en el dominio destino.

=== Notas bibliográficas
<sec-generalizacion-notas>

@bareinboimpearl2013transportability introduce la teoría formal de transportabilidad y el algoritmo de decisión completo; @bareinboim2025causalai la presenta de forma integrada con el resto de la Jerarquía Causal de Pearl en sus capítulos sobre generalización. La noción informal de validez externa en econometría aplicada, con la que conviene contrastar este tratamiento formal, se discute en @imbens2015causal.
