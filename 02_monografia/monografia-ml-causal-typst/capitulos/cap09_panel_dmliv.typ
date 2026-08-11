// Capítulo 17 — Machine learning causal en datos de panel
// (La numeración `cap09` del nombre de archivo es histórica: proviene de la edición corta anterior y se conserva para no romper referencias.)
#import "../template/template.typ": *

#chapter[Machine learning causal en datos de panel]
<cap-panel-dmliv>

#theorem-number-reset()

// Alias de etiqueta preservado del original LaTeX (\label{cap:panel-dml})
#cuadrosinoptico[
  #table(
    columns: (auto, 1fr),
    align: (left, left),
    stroke: none,
    [*Problema:*], [Estimar efecto causal en panel con controles de alta dimensión],
    [*Estimando:*], [$theta_0$, efecto parcial en PLR de panel con efectos fijos],
    [*Identificación:*], [Exogeneidad + within-transformation + FE],
    [*Método:*], [DML-panel (within + cross-fitting), DMLIV],
    [*Nuisance:*], [$tilde(g)(tilde(X))$, $tilde(m)(tilde(X))$ en espacio within-transformado],
    [*Garantía:*], [$sqrt(n)(hat(theta) - theta_0) arrow.r^(d) N(0, cal(V))$ con errores cluster-robustos],
    [*Condición clave:*], [Within-transformation + cross-fitting por clúster],
    [*Librerías:*], [DoubleML (DoubleMLClusterData), econml],
    [*Validación:*], [FE vs DML, placebos, event study, sensibilidad a $K$],
  )
]

#notatecnica[
Con Post-Double-Selection (@cap-pds) como primer diseño de identificación completo, este capítulo extiende el mismo espíritu —controlar rigurosamente por confusión en alta dimensión— a dos estructuras de datos que rompen el supuesto de observaciones independientes de Double Machine Learning (@cap-dml): datos de panel con efectos fijos, y variables instrumentales.
]

== Problema causal, estimando e identificación
<sec-cap09_problema>

Una consultora evalúa el efecto de una reforma laboral sobre el empleo formal en 32 regiones observadas durante 10 años. La reforma se adoptó en distintas regiones en distintos años, generando un panel con _staggered adoption_. La pregunta de política es: ¿cuál es el efecto promedio de la reforma sobre el empleo formal?

Los métodos clásicos—efectos fijos (FE), DiD, _synthetic DiD_— funcionan bien cuando hay pocos controles y se asume linealidad. Pero si hay muchas características regionales (sectoriales, demográficas, macroeconómicas) que afectan tanto la adopción de la reforma como el empleo, los FE clásicos pueden no bastar. #cite(<chernozhukov2018double>, form: "prose") extienden DML a datos de panel combinando _within-transformation_ con _cross-fitting_.

Este capítulo desarrolla DML para paneles: la _within-transformation_ que elimina efectos fijos, el _cross-fitting_ que preserva inferencia válida, y la extensión a instrumentos (DMLIV). Aplicamos el método al dataset #code[panel_fe_dynamic] del repositorio, que tiene CATE verdadero conocido.

== Teoría, supuestos y garantías
<sec-cap09_teoria>

=== Modelo de panel con efectos fijos
<sec-cap09_fe_model>

Consideramos un panel balanceado con $N$ unidades observadas durante $T$ periodos. El modelo es:
$
Y_(i t) = D_(i t) theta_0 + g_0(X_(i t)) + alpha_i + delta_t + epsilon_(i t),
$ <eq-panel-model>
donde $alpha_i$ es efecto fijo de unidad, $delta_t$ es efecto fijo de periodo, $g_0(X_(i t))$ es una función desconocida de covariables _time-varying_, y $epsilon_(i t)$ es el error. El parámetro causal es $theta_0$.

En panel, $n = N dot.c T$ observaciones, con $N$ unidades y $T$ periodos.

La _within-transformation_ elimina los efectos fijos:
$
tilde(Y)_(i t) = Y_(i t) - overline(Y)_(i dot.c) - overline(Y)_(dot.c t) + overline(Y)_(dot.c dot.c),
$ <eq-within>
donde $overline(Y)_(i dot.c)$ es el promedio temporal para la unidad $i$, $overline(Y)_(dot.c t)$ es el promedio _cross-sectional_ para el periodo $t$, y $overline(Y)_(dot.c dot.c)$ es la gran media. Aplicando esto a la ecuación @eq-panel-model:
$
tilde(Y)_(i t) = tilde(D)_(i t) theta_0 + tilde(g)_0(X_(i t)) + tilde(epsilon)_(i t).
$ <eq-within-plr>

Ahora el modelo está en forma PLR y se le puede aplicar DML directamente.

=== Supuestos
<sec-cap09_supuestos>

Para que el estimador DML-panel sea $sqrt(n)$-consistente y asintóticamente normal, se requieren los siguientes supuestos:

#assumption(name: [Exogeneidad del tratamiento])[
  $E[epsilon_(i t) | D_(i 1), dots, D_(i T), X_(i 1), dots, X_(i T), alpha_i, delta_t] = 0$ para todo $i, t$.
] <asu-panel-exogeneity>

El supuesto de exogeneidad del panel es la versión para panel de la no confusión condicional: una vez que controlamos por efectos fijos de unidad ($alpha_i$) y periodo ($delta_t$), y por las covariables observadas $X_(i t)$, la asignación del tratamiento es tan buena como aleatoria condicional en esos factores.

#assumption(name: [Efecto constante])[
  El efecto causal del tratamiento es constante: $theta_0$ no varía entre unidades ni periodos.
] <asu-panel-constant-effect>

Este supuesto es restrictivo pero necesario para la formulación PLR estándar. En la sección de riesgos discutimos extensiones para efectos dinámicos o heterogéneos.

#assumption(name: [Condición de producto para DML])[
  Los estimadores _nuisance_ $hat(tilde(g))$ y $hat(tilde(m))$ satisfacen $sqrt(n) a_n^2 -> 0$, donde $a_n = max{norm(hat(tilde(g)) - tilde(g)_0), norm(hat(tilde(m)) - tilde(m)_0)}$.
] <asu-panel-product>

Esta condición es la misma del DML estándar (capítulo @cap-ortogonalidad): los errores de estimación de las _nuisance_ deben converger más rápido que $n^(-1/4)$ para que el sesgo de regularización sea de segundo orden.

=== Estimador y score
<sec-cap09_estimador>

==== DML para panel
<sec-cap09_dml_panel>

Una vez aplicada la within-transformation, el modelo @eq-within-plr es un PLR estándar en los datos transformados ${tilde(Y)_(i t), tilde(D)_(i t), tilde(X)_(i t)}$. El score ortogonal de Neyman para este modelo es:
$
psi(W, theta, eta) = (tilde(D) - m(tilde(X)))(tilde(Y) - g(tilde(X)) - theta tilde(D)),
$ <eq-score-panel>

donde $eta = (g, m)$ son las funciones _nuisance_: $g(tilde(X)) = E[tilde(Y) | tilde(X)]$ y $m(tilde(X)) = E[tilde(D) | tilde(X)]$. La ortogonalidad del score garantiza que los errores de estimación de $hat(g)$ y $hat(m)$ no contaminan la estimación de $theta_0$ en primer orden.

El estimador DML-panel se obtiene resolviendo la ecuación de momento $sum_(i, t) psi(W_(i t), hat(theta), hat(eta)) = 0$ tras aplicar _cross-fitting_ por clúster (unidad).

==== DML con instrumentos (DMLIV)
<sec-cap09_dmliv>

Cuando $D$ es endógeno y se dispone de un instrumento $Z$, el modelo es:
$
Y = D theta_0 + g_0(X) + epsilon, quad Z = r_0(X) + zeta, quad D = m_0(Z, X) + v,
$ <eq-dmliv-system>
con $E[epsilon | Z, X] = 0$ (exclusión) y $"Cov"(Z, v) != 0$ (relevancia). El score ortogonal correspondiente, derivado por @chernozhukov2018double, es:
$
psi_(t "PLIV")(W, theta, eta) = (Z - r(X))(Y - g(X) - theta D),
$ <eq-score-pliv>
con $eta = (g, r, m)$.

#theorem(name: [DML-PLIV])[
  Bajo los supuestos de exclusión, relevancia, y tasas apropiadas para $hat(eta)$, el estimador DML-PLIV es $sqrt(n)$-consistente y asintóticamente Gaussiano.
] <thm-dml-pliv>

*La relevancia no es un supuesto binario.* El teorema pide $"Cov"(Z, v) != 0$, pero la aproximación asintótica que lo respalda se degrada continuamente a medida que esa covarianza se acerca a cero. Con instrumentos *débiles*, el estimador IV es sesgado hacia OLS, su distribución muestral deja de ser aproximadamente normal, y los intervalos de confianza convencionales sub-cubren de forma severa —el problema es de la aproximación asintótica misma, no del tamaño de muestra—. El diagnóstico convencional es el estadístico $F$ de la primera etapa sobre los instrumentos excluidos, con el umbral $F > 10$ que #cite(<stock2005testing>, form: "prose") derivaron: no es una regla arbitraria, sino el valor que acota el sesgo relativo del 2SLS respecto al OLS por debajo del 10% en el caso de un instrumento. Reportar ese $F$ es obligatorio en cualquier diseño IV de este curso, y el @cap-monitoreo-causal lo convierte además en una métrica de monitoreo continuo, porque la fuerza de un instrumento puede erosionarse con el tiempo sin que ninguna otra señal lo advierta.

Dos advertencias específicas del contexto de este capítulo. Primera: con muchos instrumentos —el escenario natural cuando se generan instrumentos con ML— el umbral de 10 deja de ser adecuado y hay que recurrir a diagnósticos para muchos instrumentos; #cite(<belloni2012sparse>, form: "prose") tratan precisamente el caso de selección de instrumentos óptimos con LASSO. Segunda: usar ML para estimar $hat(r)(X) = E[Z | X]$ y luego calcular el $F$ sobre los residuos ortogonalizados no es lo mismo que el $F$ de una primera etapa lineal, y las tablas de Stock–Yogo no son directamente aplicables; conviene reportar ambos y no presentar el segundo como si tuviera la garantía del primero.

El complemento del diagnóstico de primera etapa es la *inferencia robusta a instrumentos débiles*. El test de *Anderson--Rubin* invierte tests de hipótesis sobre $theta$: el IC se construye como el conjunto de valores $theta_0$ para los que no se rechaza $H_0: theta = theta_0$, y es válido cualquiera sea la fuerza del instrumento — a costa de poder ser un conjunto, no un intervalo, cuando la identificación es débil. Con muchos instrumentos, los tests de *Kleibergen--Paap* y el criterio de *Stock--Yogo* para tamaño de test (#cite(<stock2002survey>, form: "prose"); #cite(<andrews2019robust>, form: "prose")) reemplazan al $F$ de un solo instrumento.

*Regla operativa del curso:* si $F <= 10$, el reporte del diseño IV incluye el IC de Anderson--Rubin junto al de Wald; si el IC-AR difiere materialmente del IC-Wald, la estimación se declara sensible a la fuerza del instrumento y el @cap-monitoreo-causal la monitorea con doble umbral.

#algorithm("DML-panel con within-transformation")[
  #kwin[Entrada][Panel ${(Y_(i t), D_(i t), X_(i t))}_{i=1, dots, N}^{t=1, dots, T}$, $K$ folds, learners $cal(L)_g$, $cal(L)_m$ para estimar nuisance.]
  #kwout[Salida][$hat(theta)$ y error estándar cluster-robusto $hat("se")(hat(theta))$.]
  Aplicar within-transformation a $Y$, $D$, $X$ para obtener $tilde(Y)$, $tilde(D)$, $tilde(X)$ mediante @eq-within. \
  Dividir las $N$ unidades en $K$ folds por clúster (_cluster cross-fitting_). \
  #for-loop(`k`, 1, `K`)[
    Estimar $hat(g)^(k)(tilde(X))$ con $cal(L)_g$ en datos fuera del fold $k$. \
    Estimar $hat(m)^(k)(tilde(X))$ con $cal(L)_m$ en datos fuera del fold $k$. \
    Calcular los residuos ortogonales en el fold $k$:
    $hat(v)_(i t) = tilde(D)_(i t) - hat(m)^(k)(tilde(X)_(i t))$,
    $hat(u)_(i t) = tilde(Y)_(i t) - hat(g)^(k)(tilde(X)_(i t))$.
  ]
  Construir el estimador DML:
  $hat(theta) = (sum_(i, t) hat(v)_(i t) tilde(D)_(i t))^(-1) sum_(i, t) hat(v)_(i t) hat(u)_(i t)$. \
  Estimar la varianza cluster-robusta:
  $hat("Var")(hat(theta)) = (1 / n^2) sum_(c=1)^N (sum_(t=1)^T hat(psi)_(c t))^2$. \
  #return-stmt[$hat(theta)$, $sqrt(hat("Var")(hat(theta)))$ como error estándar.]
] <alg-dml-panel-within>

=== Garantías
<sec-cap09_garantias>

El algoritmo anterior hereda las garantías del DML estándar (capítulo @cap-dml) sobre los datos within-transformados. Específicamente:

- $sqrt(n)(hat(theta) - theta_0) arrow.r^(d) N(0, cal(V))$ cuando $n -> infinity$, donde $cal(V)$ es la semiparamétrica eficiente para el PLR.
- La varianza asintótica se estima consistentemente mediante la agregación por clúster de la _influence function_, capturando la correlación intra-unidad.
- La within-transformation elimina el sesgo por $alpha_i$ y $delta_t$ sin requerir estimación directa de $N + T$ efectos fijos, lo que sería inviable con ML en paneles largos.

El teorema de DML-PLIV extiende estas garantías al caso con instrumentos, siempre que se cumplan las condiciones de exclusión y relevancia.

== Implementación en Python
<sec-cap09_implementacion>

=== DML sobre panel sintético con ground truth
<sec-cap09_panel_sintetico>

#figure(
  kind: raw,
  caption: [DML sobre panel sintético.],
  ```python
# Requiere DoubleML >= 0.6.0
# pip install doubleml>=0.6.0
import pandas as pd
import numpy as np
from doubleml import DoubleMLPLR, DoubleMLData
from sklearn.ensemble import RandomForestRegressor

df = pd.read_csv("../data/datasets/synthetic/panel/panel_fe_dynamic/student.csv")
truth = pd.read_csv("../data/datasets/synthetic/panel/panel_fe_dynamic/truth_instructor_only.csv")
# Panel: unit_id, time, treated_group, treated, y_outcome
# Verdad: tau_i_truth (CATE por unidad)

# Within-transformation
def within_transform(df, var, unit="unit_id", time="time"):
    """Y_it - Y_i. - Y_.t + Y_.."""
    g_i = df.groupby(unit)[var].transform("mean")
    g_t = df.groupby(time)[var].transform("mean")
    g_global = df[var].mean()
    return df[var] - g_i - g_t + g_global

df["Y_tilde"] = within_transform(df, "y_outcome")
df["D_tilde"] = within_transform(df, "treated")

# Crear covariables: usar tiempo y unidad como proxy (en la practica se usarian X reales)
# Aqui usamos interacciones time x unit como controles sinteticos
df["time_x_unit"] = df["time"] * df["unit_id"]
X = df[["time", "unit_id", "time_x_unit"]].values

# DML con cross-fitting por cluster (unidad)
# Nota: Si la libreria no soporta cluster cross-fitting para PLR en la version usada,
# implementar DML manual con GroupKFold y varianza cluster-robusta.
from doubleml import DoubleMLClusterData, DoubleMLPLR

obj_dml = DoubleMLPLR(
    DoubleMLClusterData.from_arrays(
        x=X,
        y=df["Y_tilde"].values,
        d=df["D_tilde"].values,
        cluster_vars=df["unit_id"].values,
    ),
    ml_l=RandomForestRegressor(n_estimators=100, min_samples_leaf=10, random_state=42),
    ml_m=RandomForestRegressor(n_estimators=100, min_samples_leaf=10, random_state=42),
    n_folds=5,
)
obj_dml.fit()
print(obj_dml.summary)
# Verdad
print(f"ATE verdadero: {truth['tau_i_truth'].mean():.4f}")
```
) <lst-dml-panel>

=== DMLIV sobre close_college
<sec-cap09_dmliv_closecollege>

#figure(
  kind: raw,
  caption: [DML-PLIV sobre close\_college.],
  ```python
import pandas as pd
from doubleml import DoubleMLPLIV, DoubleMLData
from sklearn.ensemble import RandomForestRegressor, GradientBoostingRegressor

df = pd.read_csv("../data/datasets/real/public_causaldata/close_college/data.csv")
# Y=lwage, D=educ, Z=nearc4, X=controles
Y = df["lwage"].values
D = df["educ"].values
Z = df["nearc4"].values
X = df[["black", "smsa", "south", "married", "exper"]].values

obj = DoubleMLPLIV(
    DoubleMLData.from_arrays(X, Y, D, z=Z),
    ml_l=GradientBoostingRegressor(n_estimators=200, random_state=42),
    ml_m=GradientBoostingRegressor(n_estimators=200, random_state=42),
    # Verificar version de DoubleML:
    # - Si PLIV requiere ml_g, especificar ml_g=GradientBoostingRegressor(...)
    # - Para Z binario, usar E[Z|X] (regresor) o clasificador con predict_proba[:,1]
    ml_r=GradientBoostingRegressor(n_estimators=200, random_state=42),  # E[Z|X] como regresion (Z binario)
    ml_g=None,  # No se usa para PLIV simple
    n_folds=5,
)
obj.fit()
print(obj.summary)
```
) <lst-dml-pliv>

== Caso empírico y validación
<sec-cap09_caso>

*Réplica propia sobre el dataset del repositorio.* Sobre el dataset sintético #code[panel_fe_dynamic] (con ground truth conocido), el DML-panel produce un estimado ATE consistente con el valor verdadero $tau approx 1.0$. El estimador FE clásico (LSDV) puede sobreestimar el efecto al no capturar no linealidades en $X_(i t)$. La figura @fig-cap9-dml-panel muestra la sensibilidad de DML-panel al número de folds $K$ del cross-fitting.

#figure(
  image("../figuras/fig_cap9_dml_panel.png", width: 85%),
  caption: [DML-panel vs. FE clásico (LSDV): sensibilidad al número de folds $K$ del cross-fitting. Las barras indican IC al 95%. La línea verde punteada es el ATE verdadero; la naranja punteada es el estimador FE clásico. Dataset: #code[panel_fe_dynamic] (sintético con ground truth).],
) <fig-cap9-dml-panel>

La figura muestra que el estimador DML-panel es estable en $K$ y consistente con el valor verdadero, mientras que el FE clásico (LSDV) exhibe un sesgo sistemático atribuible a la omisión de la estructura no lineal en $X_(i t)$. Esto valida la recomendación de usar DML-panel cuando se sospecha no linealidad sustantiva en los controles.

#riesgos[
  #figure(
    caption: [Riesgos comunes en DML-panel],
    table(
      columns: (1.4fr, 1.4fr, 1.4fr, 1.6fr),
      align: (left, left, left, left),
      stroke: none,
      table.hline(stroke: 0.8pt),
      table.header([*Riesgo*], [*Consecuencia*], [*Diagnóstico*], [*Mitigación*]),
      table.hline(stroke: 0.4pt),
      [No hacer within-transformation], [Sesgo por $alpha_i$ no observado], [Comparar FE vs DML sin within], [Aplicar within-transformation siempre],
      [Cross-fitting por observación en lugar de por clúster], [Errores estándar incorrectos (subestimación)], [Verificar cluster folds en código (#code[cluster_vars])], [Usar #code[GroupKFold] o #code[DoubleMLClusterData]],
      [Adopción escalonada con efectos heterogéneos], [*Estimando mal definido*: pesos negativos en TWFE; el coeficiente puede tener signo opuesto al efecto verdadero], [_Event study_ con leads y lags; descomposición de Goodman-Bacon para cuantificar las comparaciones ``prohibidas'' y sus pesos], [Cambiar de estimador, no de _learner_: Callaway–Sant'Anna, Sun–Abraham o Borusyak et al. Ningún ajuste de $hat(g), hat(m)$ corrige un peso negativo],
      [Instrumento débil (DML-PLIV)], [Sesgo hacia OLS, distribución no normal, IC que sub-cubren], [$F$ de primera etapa sobre instrumentos excluidos; umbral convencional $F > 10$ @stock2005testing], [Reportar siempre el $F$; IC de Anderson--Rubin junto al Wald si $F <= 10$; con muchos instrumentos usar diagnósticos específicos],
      [Varianza IID en presencia de correlación intra-clúster], [Errores estándar subestimados, inferencia inválida], [Calcular SE cluster-robustos y comparar con IID], [Agregar influence function por clúster: $hat("Var")(hat(theta)) = (1 / n^2) sum_c (sum_(i in c) hat(psi)_i)^2$],
      [Within-transformar $Y$ y $D$ pero no $X$], [Interpretación incorrecta de los controles], [Verificar que $X_(i t)$ también se transforme o justificar su inclusión cruda], [Aplicar within-transformation también a $X_(i t)$ o explicitar que #code[unit_id] es proxy de FE],
      table.hline(stroke: 0.8pt),
    )
  ) <tab-riesgos-cap09>
]

#intuicion[
  *Caja de profundización 9.1: Diferencias-en-Diferencias moderno*

  *Objetivo.* Entender los problemas del DiD clásico cuando el tratamiento se adopta en distintos momentos, y por qué la within-transformation de este capítulo no los resuelve.

  *El problema de la adopción escalonada.* Cuando distintas unidades reciben el tratamiento en distintos períodos (``staggered adoption''), el estimador de Two-Way Fixed Effects (TWFE) no estima el ATT sino un promedio ponderado de comparaciones $2 times 2$. #cite(<goodmanbacon2021>, form: "prose") descompone exactamente ese promedio (la *descomposición de Goodman-Bacon*) y muestra que incluye comparaciones ``prohibidas'': unidades recién tratadas contra unidades *ya tratadas antes*, que actúan como controles pese a estar bajo tratamiento.

  *La consecuencia es más grave de lo que parece.* #cite(<dechaisemartin2020twoway>, form: "prose") demuestran que, con efectos heterogéneos en el tiempo, algunos de esos pesos son *negativos*: el coeficiente TWFE puede tener signo opuesto al efecto verdadero *aunque el efecto sea del mismo signo para todas las unidades y todos los períodos*. No es un problema de precisión que más datos resuelvan; es un problema de que el estimando implícito no es el que se quiere.

  *Qué implica esto para el DML-panel de este capítulo.* La within-transformation de la @sec-cap09_fe_model es TWFE, y por tanto *hereda el problema completo* si la adopción es escalonada y los efectos heterogéneos. El supuesto de efecto constante de la @sec-cap09_supuestos no es una simplificación pedagógica menor: es exactamente lo que sostiene la validez del procedimiento. Flexibilizar los _nuisance_ con ML no repara un estimando mal definido — ninguna cantidad de _gradient boosting_ en $hat(g)$ y $hat(m)$ corrige un peso negativo.

  *Estimadores robustos.*
  - *Event study:* graficar el efecto en cada período alrededor del tratamiento. Permite ver tendencias pre-tratamiento y dinámica post-tratamiento. Punto de partida obligatorio.
  - *#cite(<callaway2021difference>, form: "prose"):* estimar el $"ATT"(g,t)$ para cada cohorte de adopción $g$ y período $t$ usando solo controles nunca tratados o aún no tratados, y agregarlos con pesos explícitos y declarados.
  - *#cite(<sun2021estimating>, form: "prose"):* corrección análoga para especificaciones de _event study_, mediante interacciones cohorte $times$ período (estimador ``interaction-weighted'').
  - *#cite(<borusyak2024revisiting>, form: "prose"):* enfoque de imputación —estimar el contrafactual con los datos no tratados y imputar— eficiente bajo homocedasticidad.

  *Recomendación.* Comenzar siempre con un _event study_. Si hay adopción escalonada, no usar TWFE (ni DML-panel sobre datos within-transformados) sin antes verificar la descomposición de Goodman-Bacon; si hay pesos negativos materiales, cambiar de estimador antes de preocuparse por la flexibilidad de los controles.
]

=== Diseños con tiempos de tratamiento escalonados

Para diseños con **staggered adoption** (tratamiento adoptado en diferentes periodos), los estimadores de efectos fijos bidireccionales (TWFE) pueden producir ponderaciones negativas y sesgo de heterogeneidad (@goodmanbacon2021, Goodman-Bacon 2021; @dechaisemartin2020twoway, de Chaisemartin & D'Haultfœuille 2020). 

Extensiones modernas que corrigen este problema:
- **Estimador de Callaway & Sant'Anna** (@callaway2021difference): agregación de ATT(g,t) por cohorte
- **Estimador de Sun & Abraham** (@sun2021estimating): interacción de cohorte × periodo
- **Estimador de Borusyak et al.** (@borusyak2024revisiting): imputación de contrafactuales

En la práctica, usar el paquete `did` (Callaway & Sant'Anna) o `fixest` (Sun & Abraham) para DiD con tratamiento heterogéneo en tiempo.

== Ejercicios propuestos
<sec-cap09_ejercicios>

+ Replique el listado @lst-dml-panel usando #code[GradientBoostingRegressor] en lugar de #code[RandomForestRegressor]. ¿Mejora la precisión?

+ Sobre el dataset #code[did_parallel_ok] (sintético), estime el efecto DiD usando DML-panel y compárelo con el DiD clásico.

+ Aplique DML-PLIV al dataset #code[iv_noncompliance] (sintético con IV) y verifique que el estimado se acerca al verdadero LATE.

+ Construya un panel donde el supuesto de tendencias paralelas se vulnere. Muestre que DML-panel produce un estimado sesgado en ese caso.

== Lecturas complementarias
<sec-cap09_lecturas>

#cite(<chernozhukov2018double>, form: "prose") cubre DML-PLIV; #cite(<bach2021doubleml>, form: "prose") documenta la implementación en `DoubleML`, incluida la variante con _cluster cross-fitting_ usada en la @sec-cap09_dml_panel. Sobre instrumentos débiles, #cite(<stock2005testing>, form: "prose") es la referencia del umbral $F > 10$ y #cite(<belloni2012sparse>, form: "prose") la del caso con muchos instrumentos seleccionados por LASSO.

La literatura de DiD con adopción escalonada es donde más ha cambiado el estado del arte en los últimos años, y conviene leerla en orden: #cite(<goodmanbacon2021>, form: "prose") descompone el estimador TWFE y muestra de dónde vienen las comparaciones problemáticas; #cite(<dechaisemartin2020twoway>, form: "prose") establecen el resultado de pesos negativos que hace inservible a TWFE bajo heterogeneidad; y las tres propuestas correctivas principales son #cite(<callaway2021difference>, form: "prose") (agregación explícita de $"ATT"(g,t)$), #cite(<sun2021estimating>, form: "prose") (event study con interacciones cohorte–período) y #cite(<borusyak2024revisiting>, form: "prose") (imputación del contrafactual). Para el diagnóstico de tendencias pre-tratamiento en diseños de event study, @freyaldenhoven2021local. El @cap-scm-mc retoma esta misma familia de problemas desde el ángulo del control sintético y la _matrix completion_.
