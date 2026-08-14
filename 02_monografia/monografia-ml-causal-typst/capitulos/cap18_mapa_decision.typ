// Capítulo 18 — Diseño de investigación y selección de método
#import "../template/template.typ": *

#chapter[Diseño de investigación y selección de método]
<cap-mapa-decision>

#theorem-number-reset()

// Alias de etiqueta preservado del original LaTeX (\label{cap:mapa_decision})
#cuadrosinoptico[
  #table(
    columns: (auto, 1fr),
    align: (left, left),
    stroke: none,
    [*Problema:*], [Elegir el diseño causal apropiado según características del problema],
    [*Estimando:*], [ATE, ATT, CATE, LATE, policy value],
    [*Identificación:*], [No confusión, validez de instrumentos, continuidad local, tendencias paralelas, combinación convexa],
    [*Método:*], [Mapa de decisión basado en teoría económica, supuestos de identificación y garantías estadísticas],
    [*Nuisance:*], [Dimensión ($p$ vs $n$), heterogeneidad, endogeneidad, estructura temporal],
    [*Garantía:*], [Identificación bajo supuestos propios de cada diseño; ranking por fuerza del diseño],
    [*Librerías:*], [DoubleML, econml, causalml, statsmodels],
    [*Validación:*], [Placebos, sensibilidad a supuestos, especificación jerárquica],
  )
]

#notatecnica[
Este capítulo cierra la Parte III sintetizando los tres diseños de identificación completos del libro —Post-Double-Selection (@cap-pds), DML de panel e instrumental (@cap-panel-dmliv), y el DML no estructurado de la Parte II (@cap-dml)— en un único mapa de decisión, además de anticipar los diseños de heterogeneidad y *targeting* de la Parte V.
]

== Motivación aplicada
<sec-cap18_motivacion>

Un analista del Banco Central recibe un encargo: estimar el efecto causal de una política monetaria sobre la inflación. Dispone de datos mensuales de 10 años, 30 covariables macroeconómicas, y la política se implementó en distintos momentos en distintos países. ¿Qué método usar? ¿DML? ¿DiD clásico? ¿Control sintético? ¿Causal Forest? ¿Alguno de los anteriores?

La elección metodológica es la decisión más importante en inferencia causal aplicada. Un método inadecuado produce estimaciones sesgadas y conclusiones equivocadas, sin importar cuán sofisticada sea la implementación. Este capítulo no presenta métodos nuevos: organiza los ya vistos en un _mapa de decisión_ operacional, conectando las características del problema (dimensión, heterogeneidad, diseño, disponibilidad de instrumentos) con el método apropiado.

== Problema causal, estimando e identificación
<sec-cap18_problema_causal>

=== Dimensiones del problema causal

Todo problema de inferencia causal aplicada puede caracterizarse en seis dimensiones que determinan la identificabilidad del efecto y el método apropiado:

+ *Dimensión de controles $p$ vs. tamaño muestral $n$.* Si $p << n$ y las relaciones son lineales, OLS clásico basta. Si $p ~ n$ o $p > n$, se requieren métodos de alta dimensión (PDS, DML).
+ *Heterogeneidad del efecto.* Si el CATE se asume constante, PLR es suficiente. Si hay heterogeneidad estructurada, se requiere IRM, meta-learners o causal forest.
+ *Endogeneidad del tratamiento.* Si se asume no confusión, los métodos de selección observable (matching, IPW, DML) aplican. Si hay endogeneidad por variables no observadas, se requieren instrumentos (IV, DMLIV) o diseños cuasi-experimentales (RDD, DiD).
+ *Estructura temporal.* Corte transversal, panel, serie temporal, o _staggered adoption_ determinan la elección entre métodos.
+ *Disponibilidad de instrumentos.* Si hay instrumentos válidos, IV/DMLIV. Si no, hay que justificar no confusión o usar métodos sensibles.
+ *Objetivo de la estimación.* ATE, ATT, CATE, policy value, o LATE son estimandos distintos que requieren métodos distintos.

=== Estimando e identificación

El estimando define qué cantidad poblacional queremos aprender. Los más frecuentes en la práctica son:

- *"ATE"* $= E[Y(1) - Y(0)]$: efecto promedio en toda la población. Identificable bajo no confusión y solapamiento.
- *"ATT"* $= E[Y(1) - Y(0) | D = 1]$: efecto en los tratados. Requiere no confusión para los no tratados.
- *CATE* $= E[Y(1) - Y(0) | X = x]$: efecto condicional en covariables. Requiere no confusión dentro de subgrupos.
- *"LATE"* $= E[Y(1) - Y(0) | "compliers"]$: efecto local en compliers. Identificable bajo monotonía y exclusión con IV.
- *Policy value* $= E[Y(pi(X))]$: valor de una regla de asignación. Estimable con policy learning.

La identificación—esto es, expresar el estimando como función de la distribución observada— depende de supuestos propios de cada diseño. La tabla de identificación jerárquica de la sección @sec-cap18_teoria_supuestos resume la fuerza de cada diseño y el supuesto clave que la sostiene.

== Teoría, supuestos y garantías
<sec-cap18_teoria_supuestos>

=== Mapa de decisión metodológica

La tabla @tab-decision-map organiza el mapa según diseño, dimensión y heterogeneidad, emparejando cada combinación con el método clásico y su contraparte de ML.

#figure(
  caption: [Mapa de decisión metodológica.],
  table(
    columns: (1.3fr, 1fr, 1fr, 1.4fr, 1.5fr),
    align: (left, left, left, left, left),
    stroke: none,
    table.hline(stroke: 0.8pt),
    table.header([*Diseño*], [*Dimensión*], [*Heterog.*], [*Método clásico*], [*Método ML*]),
    table.hline(stroke: 0.4pt),
    [Corte transversal], [$p << n$], [No], [OLS], [—],
    [Corte transversal], [$p ~ n$], [No], [PDS LASSO], [DML-PLR],
    [Corte transversal], [$p << n$], [Sí], [Subgrupos ad hoc], [Meta-learners, Causal Forest],
    [Corte transversal], [$p ~ n$], [Sí], [—], [DML-IRM, Causal Forest],
    [IV], [$p << n$], [No], [2SLS], [—],
    [IV], [$p ~ n$], [No], [PDS-IV], [DML-PLIV],
    [RDD], [—], [No], [Local linear], [—],
    [DiD], [—], [No], [TWFE], [—],
    [Panel staggered], [—], [No], [Callaway–Sant'Anna, Sun–Abraham, SDID (*nunca* TWFE)], [Matrix completion],
    [Panel con $X_(i t)$], [$p ~ n$], [No], [FE + controles], [DML-panel],
    [Policy optimization], [—], [Sí], [—], [Policy learning, uplift],
    table.hline(stroke: 0.8pt),
  )
) <tab-decision-map>

=== Identificación jerárquica de diseños

No todos los diseños tienen la misma _fuerza de identificación_. La tabla @tab-identificacion-jerarquica clasifica los diseños según la credibilidad del supuesto clave que los sostiene, ordenados de mayor a menor fuerza identificadora.

#figure(
  caption: [Identificación jerárquica de diseños causales.],
  table(
    columns: (1.4fr, 1fr, 2.5fr),
    align: (left, left, left),
    stroke: none,
    table.hline(stroke: 0.8pt),
    table.header([*Diseño*], [*Fuerza*], [*Supuesto clave*]),
    table.hline(stroke: 0.4pt),
    [RCT], [Alta], [Aleatorización del tratamiento],
    [IV], [Alta], [Relevancia del instrumento y restricción de exclusión],
    [RDD], [Alta], [Continuidad local de potenciales resultados en el umbral],
    [DiD], [Media], [Tendencias paralelas en ausencia del tratamiento],
    [SCM], [Media], [Combinación convexa de unidades no tratadas],
    [No confusión (selección observables)], [Media-baja], [No confusores no observados],
    table.hline(stroke: 0.8pt),
  )
) <tab-identificacion-jerarquica>

Un diseño de mayor fuerza requiere supuestos más creíbles y, por tanto, produce estimaciones más robustas. Al elegir un método, el investigador debe priorizar el diseño de mayor fuerza que sea factible dados los datos disponibles.

=== Criterios adicionales de selección

Más allá del mapa y la jerarquía de identificación, tres criterios refinan la elección:

*Calidad de los controles.* Si los controles son ruidosos o mal medidos, los métodos de ML (que los usan intensivamente) pueden empeorar la estimación. En tales casos, métodos que dependen menos de $X$ (DiD, RDD) son preferibles.

*Tamaño muestral.* Causal Forest y Deep Causal requieren $n > 1\,000$ para producir estimaciones útiles. Con $n < 500$, métodos más parsimoniosos (OLS, matching) son preferibles.

*Capacidad computacional.* Deep causal (TARNet, CFRNet) requiere GPU. En entornos limitados, métodos basados en árboles (Causal Forest) son escalables.

#intuicion[
  *Caja de profundización 10.1: Regresión Discontinua y transportabilidad*

  *Objetivo.* Completar el mapa de decisión con dos métodos adicionales: RDD y transportabilidad.

  *RDD (Regression Discontinuity).* Cuando el tratamiento se asigna según un umbral en una variable continua (ej: beca para alumnos con puntaje $> 70$), podemos comparar a quienes quedaron justo arriba vs justo abajo. Es como un experimento local alrededor del corte.
  $
  tau_"RD" = lim_(x -> c^+) E[Y | X = x] - lim_(x -> c^-) E[Y | X = x]
  $

  *RDD difuso (Fuzzy RDD).* Si el umbral no se cumple perfectamente (algunos de abajo reciben el tratamiento y viceversa), el RDD se convierte en un diseño de variables instrumentales donde el umbral es el instrumento.

  *Transportabilidad.* Una pregunta clave: si entrenamos un modelo con datos de una población (ej: Santiago), ¿sirve para otra población (ej: Temuco)?
  - *Covariate shift:* la distribución de $X$ cambia.
  - *Target shift:* la relación causal cambia.
  - Los diagramas de selección ayudan a decidir si un efecto es transportable.
]

== Implementación en Python
<sec-cap18_implementacion>

=== Función #code[choose_method]

#figure(
  kind: raw,
  caption: [Función de decisión metodológica.],
  ```python
def choose_method(n, p, has_iv, is_panel, has_heterogeneity, treatment_staggered=False):
    """Devuelve el metodo recomendado segun las caracteristicas del problema.

    ADVERTENCIA: es una heuristica de primer descarte, no un sustituto del
    analisis de identificacion. Presupone que la pregunta causal, el
    estimando y el grafo ya estan definidos (Caps. 3 y 8).
    """
    if is_panel and treatment_staggered:
        # Callaway-Sant'Anna / Sun-Abraham para el ATT(g,t); Synthetic DiD
        # (Arkhangelsky et al. 2021) o Matrix Completion (Athey et al. 2021)
        # cuando hay pocas unidades tratadas. Nunca TWFE: pesos negativos
        # (de Chaisemartin & D'Haultfoeuille 2020). Ver Cap. 17.
        return ("Callaway-Sant'Anna / Sun-Abraham; Synthetic DiD "
                "o Matrix Completion si hay pocas unidades tratadas")
    if is_panel and not treatment_staggered:
        if p > n * 0.5:
            return "DML-panel con within-transformation"
        else:
            return "FE clasico (LSDV) con controles manuales"
    # Corte transversal
    if has_iv:
        if p > n * 0.3:
            return "DML-PLIV con GBM o RF"
        else:
            return "2SLS clasico"
    # Sin IV
    if has_heterogeneity:
        if n < 1000:
            return "Meta-learners (T-learner o X-learner)"
        else:
            return "Causal Forest (CausalForestDML)"
    else:
        if p > n * 0.3:
            return "DML-PLR con LassoCV o GBM"
        elif p > 50:
            return "Post-Double-Selection LASSO"
        else:
            return "OLS con controles manuales (HC1)"

# Ejemplos
print(choose_method(n=500, p=80, has_iv=False, is_panel=False, has_heterogeneity=True))
print(choose_method(n=2000, p=5, has_iv=True, is_panel=False, has_heterogeneity=False))
print(choose_method(n=200, p=10, has_iv=False, is_panel=True, has_heterogeneity=False,
                    treatment_staggered=True))
```
) <lst-decision-map>

== Caso empírico y validación
<sec-cap18_caso_empirico>

=== Análisis crítico de 4 problemas

#figure(
  kind: raw,
  caption: [Caso 1: retorno a la educación.],
  ```python
# Problema: efecto de educacion sobre salario. n=3000, p=15, IV=nearc4
metodo = choose_method(n=3000, p=15, has_iv=True, is_panel=False, has_heterogeneity=False)
print(f"Caso 1 (Card 1995): {metodo}")
# Recomendacion: 2SLS clasico (p << n, IV disponible, sin heterogeneidad estructurada)
```
) <lst-case-1>

=== Validación de la elección metodológica

Para cada caso aplicado, la elección metodológica debe validarse mediante:
- *Placebo del tratamiento:* asignar un tratamiento falso y verificar que el estimador no encuentra efecto.
- *Sensibilidad a supuestos:* variar el método dentro del mismo diseño (ej: distintos $K$ en cross-fitting, distintos learners) y verificar estabilidad.
- *Comparación con diseños más débiles:* si es posible, estimar con un diseño de menor fuerza y documentar la diferencia.

== Errores comunes y límites
<sec-cap18_errores>

#riesgos[
  #figure(
    caption: [Riesgos comunes en la elección metodológica],
    table(
      columns: (1.5fr, 1.5fr, 1.5fr, 1.8fr),
      align: (left, left, left, left),
      stroke: none,
      table.hline(stroke: 0.8pt),
      table.header([*Riesgo*], [*Consecuencia*], [*Diagnóstico*], [*Mitigación*]),
      table.hline(stroke: 0.4pt),
      [Usar ML cuando los métodos clásicos bastan], [Complejidad innecesaria, pérdida de interpretabilidad, inferencia no exacta], [$p << n$ y linealidad razonable], [Usar OLS con errores HC1],
      [Usar DML sin justificar no confusión], [Estimaciones sesgadas por endogeneidad no resuelta], [Presencia de confusores no observados], [Usar IV, RDD, DiD o control sintético],
      [Cambiar de método según los resultados (_specification mining_)], [Sesgo de selección; inferencia inválida], [Elección metodológica posterior a ver los datos], [Preregistrar el diseño; elegir método antes de estimar],
      table.hline(stroke: 0.8pt),
    )
  ) <tab-riesgos-cap10>
]

*Límites.* El mapa es orientativo. Casos límite (panel con _staggered adoption_ y heterogeneidad, IV con muchos instrumentos débiles, RDD con covariables de alta dimensión) requieren análisis experto más allá del mapa.

Hay además un límite de fondo que conviene explicitar, porque la existencia misma de una función `choose_method` invita a olvidarlo. El mapa organiza la elección de *estimador* dando por resuelta la de *identificación*, y esa es la parte fácil del problema. Las seis dimensiones de la @sec-cap18_problema_causal son observables en los datos —$n$, $p$, si hay panel, si hay un instrumento candidato—; las condiciones que realmente determinan la validez del resultado no lo son: si las covariables observadas cierran las rutas de puerta trasera, si el instrumento satisface la restricción de exclusión, si las tendencias habrían sido paralelas. Ningún argumento de la función captura eso, y ninguna heurística puede. La jerarquía de la @tab-identificacion-jerarquica ordena diseños por la *credibilidad* de esos supuestos precisamente porque es lo que el mapa no puede decidir: elegir DML sobre OLS mejora la flexibilidad de la estimación, pero un diseño de mayor fuerza identificadora —cuando los datos lo permiten— mejora algo que ninguna cantidad de flexibilidad compensa.

== Ejercicios propuestos
<sec-cap18_ejercicios>

+ Para los siguientes cinco problemas, recomiende un método:
  - Efecto de un RCT sobre rendimiento escolar ($n = 5\,000$, $p = 10$).
  - Efecto de una reforma tributaria sobre inversión ($n = 800$, $p = 100$).
  - Efecto de un programa social sobre pobreza, con staggered adoption en panel.
  - Efecto de un medicamento sobre presión arterial, con variable instrumental.
  - Efecto heterogéneo de becas sobre deserción ($n = 20\,000$, $p = 50$).

+ Justifique por qué DML no es adecuado cuando hay confusión no observada. ¿Qué alternativas existen?

+ Discuta: ¿en qué casos el causal forest es preferible al R-learner, y viceversa?

== Lecturas complementarias
<sec-cap18_lecturas>

#cite(<athey2019econometric>, form: "prose") ofrece una revisión moderna de métodos. #cite(<imbens2015causal>, form: "prose") es la referencia canónica para métodos clásicos. #cite(<chernozhukov2018applied>, form: "prose") para DML. #cite(<athey2017beyond>, form: "prose") para una perspectiva de política.
