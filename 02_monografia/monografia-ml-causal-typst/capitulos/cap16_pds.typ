// Capítulo 16 — Post-Double-Selection LASSO
#import "../template/template.typ": *

#chapter[Post-Double-Selection LASSO]
<cap-pds>

#theorem-number-reset()

// Alias de etiqueta preservado del original LaTeX (\label{cap:seleccion-confusores})
#cuadrosinoptico[
  #table(
    columns: (auto, 1fr),
    align: (left, left),
    stroke: none,
    [*Problema:*], [Selección de confusores en alta dimensión para estimación causal],
    [*Estimando:*], [$theta_0$ en el modelo $Y = D theta_0 + X^T gamma_0 + epsilon$],
    [*Identificación:*], [Sparsity aproximada, restricted eigenvalue condition],
    [*Método:*], [PDS LASSO: doble selección (LASSO de $Y$ y $D$) + OLS final],
    [*Nuisance:*], [Coeficientes LASSO de $Y$ y $D$],
    [*Garantía:*], [$sqrt(n)(hat(theta)_"PDS" - theta_0) arrow.r^(d) cal(N)(0, cal(V))$],
    [*Librerías:*], [scikit-learn, statsmodels],
    [*Validación:*], [Sensibilidad a $lambda$, comparación con DML],
  )
]

#notatecnica[
Este capítulo abre la Parte III del libro, dedicada a diseños de identificación completos. El @cap-intervencion-contrafactual formalizó el criterio de puerta trasera de forma general; Post-Double-Selection es el procedimiento concreto para aplicarlo cuando el conjunto de controles candidatos es de alta dimensión y no se sabe, a priori, cuáles son verdaderamente confusores.
]

== Motivación aplicada
<sec-cap16_motivacion>

Una economista de la salud desea estimar el efecto de dejar de fumar sobre el cambio de peso, usando el dataset #code[nhefs] (NHANES I Epidemiologic Followup Study). El dataset tiene 51 covariables utilizables tras excluir variables post-tratamiento y de fecha: características demográficas, hábitos, condiciones médicas, factores socioeconómicos. No todas son confusoras: algunas no afectan ni al tratamiento ni al resultado, otras afectan solo al resultado. La pregunta metodológica es: ¿cómo seleccionar automáticamente las confusoras relevantes sin inducir el sesgo post-selección del capítulo @cap-regularizacion?

#cite(<belloni2014inference>, form: "prose") proponen el Post-Double-Selection (PDS) LASSO como solución. La idea es elegante: las confusoras son las variables que predicen _tanto_ al tratamiento _como_ al resultado. Seleccionando por separado cada conjunto con LASSO y tomando la unión, se capturan las confusoras relevantes con alta probabilidad, mientras que el sesgo de selección individual se diluye.

Este capítulo desarrolla PDS formalmente, lo compara con DML (capítulo @cap-dml)—que no requiere sparsity explícita— y muestra una aplicación al dataset #code[nhefs].

== Teoría, supuestos y garantías
<sec-cap16_teoria>

=== Modelo de alta dimensión con efecto causal
<sec-cap16_modelo>

Consideramos el modelo:
$
Y = D theta_0 + X^T gamma_0 + epsilon, quad D = X^T beta_0 + v,
$ <eq-hd-model>
donde $X in R^p$ con $p$ potencialmente mayor que $n$, $gamma_0$ y $beta_0$ son _sparse_ (pocas componentes no nulas), y $theta_0$ es el parámetro causal de interés. Suponemos $E[epsilon | D, X] = 0$ y $E[v | X] = 0$.

=== Post-Double-Selection (PDS)
<sec-cap16_pds>

El procedimiento PDS consiste en tres pasos:

+ *Selección de controles para $Y$:* LASSO de $Y$ sobre $X$ (sin $D$), obtener conjunto $S_Y$.
+ *Selección de controles para $D$:* LASSO de $D$ sobre $X$, obtener conjunto $S_D$.
+ *OLS final:* regredir $Y$ sobre $D$ y $S = S_Y union S_D$. Reportar IC al 95% basados en la distribución $t$-Student estándar.

#theorem(name: [Belloni, Chernozhukov & Hansen, 2014])[
  Bajo sparsity aproximada de $gamma_0$ y $beta_0$, _restricted eigenvalue condition_, y regularidad estándar, el estimador PDS es asintóticamente Gaussiano:
  $
  sqrt(n)(hat(theta)_"PDS" - theta_0) arrow.r^(d) cal(N)(0, cal(V)),
  $
  donde $cal(V) = E[v^2 epsilon^2] / E[v^2]^2$. La inferencia basada en la distribución $t$-Student es válida.
] <thm-pds-formal>

=== Pseudocódigo: Post-Double-Selection

El siguiente algoritmo formaliza los pasos del procedimiento PDS.

#algorithm("Post-Double-Selection (PDS)")[
  #kwin[Entrada][Datos ${(Y_i, D_i, X_i)}_(i=1)^n$, hiperparámetro de penalización $lambda >= 0$ (o $K$ folds para validación cruzada).]
  #kwout[Salida][Estimador $hat(theta)_"PDS"$ y error estándar HC1 $hat(sigma)_"HC1"$]
  Ejecutar LASSO de $Y$ sobre $X$ con penalización $lambda$. \
  Identificar $S_Y = {j : hat(beta)_(Y,j) != 0}$. \
  Ejecutar LASSO de $D$ sobre $X$ con penalización $lambda$. \
  Identificar $S_D = {j : hat(beta)_(D,j) != 0}$. \
  Unión: $S = S_Y union S_D$. \
  Estimar OLS de $Y$ sobre $D$ y las variables en $S$ (con constante). \
  Calcular errores estándar robustos HC1. \
  #return-stmt[$hat(theta)_"PDS", hat(sigma)_"HC1"$.]
] <alg-pds>

=== La elección de $lambda$ no es un detalle de implementación
<sec-cap16_lambda>

El teorema anterior se enuncia "para un $lambda$ apropiadamente elegido", y conviene detenerse en esa cláusula porque es donde la implementación práctica se aparta con más frecuencia de la teoría que la respalda.

La validación cruzada —el método por defecto de `LassoCV` y el que usa el listado @lst-pds-nhefs— elige $lambda$ minimizando el error de *predicción* fuera de muestra. Es el criterio correcto si el objetivo es predecir, pero no es el criterio bajo el cual se demuestra el teorema. El $lambda$ óptimo para predicción tiende a ser más pequeño que el teóricamente justificado, porque incluir variables ligeramente informativas reduce el error cuadrático aunque introduzca sesgo en los coeficientes individuales; el resultado es un $hat(S)$ más grande de lo necesario y, en muestras pequeñas, un OLS final con demasiados regresores.

#cite(<belloni2014inference>, form: "prose") derivan en cambio un nivel de penalización *teóricamente justificado*, de la forma
$
lambda = (c dot.c sigma) / sqrt(n) dot.c Phi^(-1)(1 - gamma \/ (2 p)),
$
con $c approx 1.1$ y $gamma -> 0$ lentamente (típicamente $gamma = 0.1 \/ log n$). La estructura de la fórmula tiene una lectura directa: la penalización se calibra para dominar el "ruido máximo" entre las $p$ variables candidatas —de ahí el $Phi^(-1)$ evaluado en una cola corregida por el número de comparaciones, un ajuste de Bonferroni disfrazado— de modo que ninguna variable irrelevante entre por azar con probabilidad no despreciable. Como $sigma$ es desconocida, se estima iterativamente, o se usa la variante *rigurosa* con penalización por variable que además corrige heterocedasticidad.

En la práctica, la recomendación operativa del curso es reportar ambas: la estimación con $lambda_"CV"$ y la estimación con $lambda_"BCH"$. Si coinciden —el caso frecuente cuando $n$ es cómodo y la señal es clara— la elección era inmaterial y conviene decirlo. Si difieren, la discrepancia es información: señala que el resultado depende de cuántos controles se admitan, y ninguna de las dos cifras debería reportarse sola. La @sec-cap16_validacion desarrolla esta comparación como análisis de sensibilidad estándar. En Python, `hdmpy` implementa la penalización rigurosa de BCH; con `scikit-learn` puede construirse a mano fijando `alpha` en lugar de usar `LassoCV`.

=== Intuición: por qué la doble selección funciona
<sec-cap16_intuicion>

El sesgo post-selección del capítulo @cap-regularizacion surge porque LASSO puede _omitir_ variables confusoras relevantes si estas tienen poco poder predictivo marginal. La doble selección mitiga esto:

- Una variable confusora afecta _tanto_ a $D$ _como_ a $Y$. Aparece en $S_Y$ o en $S_D$ con alta probabilidad (no necesariamente en ambos).
- Tomando la unión, se captura con alta probabilidad toda confusora relevante.
- Las variables no confusoras (afectan solo a $Y$ o solo a $D$) se seleccionan con probabilidad menor y, aun si se incluyen, no sesgan la estimación.

#intuicion[
  Imagine que $X_j$ es una confusora fuerte: afecta a $D$ y a $Y$. LASSO sobre $Y$ puede omitirla si $D$ ya explica $Y$ suficientemente bien. Pero LASSO sobre $D$ la seleccionará con alta probabilidad. Tomando la unión, $X_j$ entra en el modelo final. El sesgo de omisión se evita.
]

=== Comparación con DML
<sec-cap16_comparacion_dml>

PDS y DML atacan el mismo problema (estimación causal en alta dimensión) con estrategias distintas:

#figure(
  caption: [PDS vs. DML.],
  table(
    columns: (1.3fr, 1.6fr, 1.6fr),
    align: (left, left, left),
    stroke: none,
    table.hline(stroke: 0.8pt),
    table.header([*Dimensión*], [*PDS LASSO*], [*DML*]),
    table.hline(stroke: 0.4pt),
    [Supuesto estructural], [Sparsity aproximada], [Ninguno explícito],
    [Forma funcional], [Lineal en $X$], [Flexible (RF, GBM, etc.)],
    [Heterogeneidad en $X$], [No], [Sí (con IRM/CATE)],
    [Inferencia], [$t$-Student estándar], [Asintótica vía IF],
    [Implementación], [#code[scikit-learn] + OLS], [#code[DoubleML]/#code[econml]],
    [Caso ideal], [$p >> n$, lineal, sparse], [$p approx n$, no lineal],
    table.hline(stroke: 0.8pt),
  )
) <tab-pds-vs-dml>

#intuicion[
  *Caja de profundización 8.1: PDS-IV y comparación PDS vs DML*

  *Objetivo.* Extender PDS a variables instrumentales y entender cuándo preferir PDS sobre DML.

  *PDS con instrumentos (PDS-IV).* Si tenemos un instrumento $Z$, la doble selección se hace así:
  + LASSO de $Y$ sobre $X$ $arrow.r S_Y$
  + LASSO de $D$ sobre $X$ y $Z$ $arrow.r S_D$
  + 2SLS: $Y$ sobre $D$, usando $Z$ como instrumento, con controles $S = S_Y union S_D$

  *PDS vs DML: ¿cuándo usar cada uno?*
  - *PDS:* mejor cuando $n$ es pequeña, el modelo es lineal y la esparsidad es fuerte (pocos controles relevantes).
  - *DML:* mejor cuando hay no linealidades, dudas sobre la forma funcional, o muchas variables con efectos pequeños.
  - *Regla práctica:* si no estás seguro, usa DML. Si $n < 500$ y confías en la linealidad, considera PDS.

  *Límite de PDS:* si hay *confusión densa* (muchas variables con efectos pequeños que en conjunto importan), PDS puede omitir variables importantes y sesgar el resultado. Ahí DML es preferible.
]

== Implementación en Python
<sec-cap16_implementacion>

=== Implementación de PDS
<sec-cap16_impl_pds>

#figure(
  kind: raw,
  caption: [Post-Double-Selection LASSO sobre NHEFS.],
  ```python
import pandas as pd
import numpy as np
from sklearn.linear_model import LassoCV
import statsmodels.api as sm

df = pd.read_csv("../data/datasets/real/public_causaldata/nhefs/data.csv")
# Outcome: cambio de peso. Treatment: qsmk (quit smoking)
# Seleccionar columnas numericas como controles
Y_col = "wt82_71"   # cambio de peso
D_col = "qsmk"      # dejo de fumar
X_cols = [c for c in df.columns if c not in [Y_col, D_col, "seqn", "death"]]
# Limpiar
df_clean = df.dropna(subset=[Y_col, D_col] + X_cols).reset_index(drop=True)
Y = df_clean[Y_col].values
D = df_clean[D_col].values.astype(float)
X = df_clean[X_cols].select_dtypes(include=[np.number]).fillna(0).values

def pds_lasso(Y, D, X, cv=5):
    """Post-Double-Selection LASSO."""
    # Paso 1: LASSO Y ~ X
    lasso_Y = LassoCV(cv=cv, max_iter=10000, random_state=42).fit(X, Y)
    S_Y = np.where(np.abs(lasso_Y.coef_) > 1e-8)[0]
    # Paso 2: LASSO D ~ X
    lasso_D = LassoCV(cv=cv, max_iter=10000, random_state=42).fit(X, D)
    S_D = np.where(np.abs(lasso_D.coef_) > 1e-8)[0]
    # Union
    S = sorted(set(S_Y) | set(S_D))
    print(f"Seleccionadas: {len(S)} variables (de {X.shape[1]})")
    # Paso 3: OLS Y ~ D + X_S
    if len(S) == 0:
        X_final = sm.add_constant(D)
    else:
        X_final = sm.add_constant(np.column_stack([D, X[:, S]]))
    ols = sm.OLS(Y, X_final).fit(cov_type="HC1")
    theta = ols.params[1]
    se = ols.bse[1]
    return theta, se, S

theta_pds, se_pds, S = pds_lasso(Y, D, X)
print(f"PDS: theta={theta_pds:.4f}  SE={se_pds:.4f}  IC=[{theta_pds-1.96*se_pds:.4f}, {theta_pds+1.96*se_pds:.4f}]")
```
) <lst-pds-nhefs>

#notatecnica[
  No forzar la inclusión de una covariable arbitraria. PDS usa la unión de variables seleccionadas en los pasos de $Y$ y $D$. La constante se agrega por separado con #code[add_constant]. Si la primera columna de $X$ no es una constante, forzarla puede introducir ruido, colisionadores o variables post-tratamiento.
]

== Caso empírico y validación
<sec-cap16_empirico>

=== Comparación PDS vs DML vs selección manual
<sec-cap16_comparacion>

#figure(
  kind: raw,
  caption: [Comparación PDS vs. DML vs. selección manual.],
  ```python
from econml.dml import LinearDML
from sklearn.ensemble import GradientBoostingRegressor, GradientBoostingClassifier

# DML con GBM
est = LinearDML(model_y=GradientBoostingRegressor(n_estimators=200, random_state=42),
                model_t=GradientBoostingClassifier(n_estimators=200, random_state=42),
                discrete_treatment=True, cv=5, random_state=42).fit(Y, D, X=X)
ate_dml = est.ate(X=X)
lb, ub = est.ate_interval(X=X, alpha=0.05)
print(f"DML:  theta={ate_dml:.4f}  IC=[{lb:.4f}, {ub:.4f}]")

# Seleccion manual (5 controles obvios)
manual_cols = ["age", "sex", "race", "smokeintensity", "smokeyrs"]
X_manual = df_clean[manual_cols].fillna(0).values
X_final_m = sm.add_constant(np.column_stack([D, X_manual]))
ols_m = sm.OLS(Y, X_final_m).fit(cov_type="HC1")
print(f"Manual: theta={ols_m.params[1]:.4f}  SE={ols_m.bse[1]:.4f}")
```
) <lst-pds-vs-dml-code>

=== Caso de estudio: efecto de dejar de fumar sobre peso (NHEFS)
<sec-cap16_caso>

#cite(<belloni2014inference>, form: "prose") aplicaron PDS a este dataset en su _paper_ original. Su tabla reporta un estimado de 2.5–3.5 kg de ganancia de peso al dejar de fumar, dependiendo del set de controles. La aplicación con selección manual (5 controles) suele subestimar el efecto, mientras que PDS captura confusoras adicionales (edad de inicio de fumador, intensidad, etc.) que elevan el estimado.

*Réplica propia sobre el dataset del repositorio.* Hemos replicado el ejercicio sobre #code[nhefs] con $n = 1\,566$ observaciones y 51 controles potenciales (excluyendo variables post-tratamiento y de fecha). Los resultados obtenidos son:

- OLS sin controles: $theta = 2.54$ kg, IC 95% $[1.59, 3.50]$.
- OLS con 5 controles manuales (#code[age, sex, race, smokeintensity, smokeyrs]): $theta = 3.20$ kg, IC 95% $[2.26, 4.14]$.
- Naive LASSO + OLS: $theta = 3.21$ kg, IC 95% $[2.28, 4.13]$ (18 variables seleccionadas).
- PDS LASSO: $theta = 3.22$ kg, IC 95% $[2.29, 4.14]$ (18 variables seleccionadas).
- DML con GBM: $theta = 3.13$ kg, IC 95% $[2.16, 4.10]$.

Las estimaciones son consistentes entre métodos (entre 3.13 y 3.22 kg para los métodos con controles), lo que valida la robustez del efecto. La cifra original de @belloni2014inference no pudo verificarse cifra por cifra en su tabla, pero el orden de magnitud coincide.

#figure(
  image("../figuras/fig_cap16_pds_sensibilidad.png", width: 85%),
  caption: [Sensibilidad de la estimación PDS al hiperparámetro $lambda$ de LASSO. Las barras indican IC al 95% (HC1). La línea verde punteada marca el $lambda$ óptimo por cross-validation. Dataset: #code[nhefs], $n = 1\,566$, $p = 51$ controles.],
) <fig-cap16-pds-sensibilidad>

La figura @fig-cap16-pds-sensibilidad muestra que la estimación PDS es relativamente estable para $lambda < 0.1$, pero colapsa hacia el estimador sin controles cuando $lambda$ es muy alto (todas las variables son penalizadas y el conjunto seleccionado se vacía). La forma de esta curva es en sí misma un diagnóstico y conviene saber leerla: una *meseta amplia* alrededor del $lambda$ elegido, como la de esta figura, indica que el resultado no depende de cuántos controles se admitan y es la situación en que reportar una sola cifra es defendible. Una curva con pendiente pronunciada en el entorno del $lambda$ elegido indicaría lo contrario —que el efecto estimado es función de una decisión de hiperparámetro— y obligaría a reportar el rango completo en lugar de un punto. Por eso el gráfico de sensibilidad no es un apéndice opcional del análisis PDS sino parte del resultado, junto con la comparación $lambda_"CV"$ frente a $lambda_"BCH"$ de la @sec-cap16_lambda.

*Una limitación del PDS estándar que conviene declarar.* A diferencia de DML, el procedimiento PDS tal como se presenta aquí no usa _cross-fitting_: las dos selecciones LASSO y el OLS final se calculan sobre la misma muestra. La teoría de #cite(<belloni2014inference>, form: "prose") no lo necesita, porque la estructura lineal y la penalización rigurosa controlan el sesgo de sobreajuste por otra vía —el argumento descansa en la esparsidad y en cotas uniformes, no en independencia entre etapas—. La contrapartida es que esa garantía es exactamente tan fuerte como el supuesto de linealidad y esparsidad: si alguno falla, PDS no tiene la red de seguridad que el cross-fitting da a DML. Es una razón adicional, junto a la de confusión densa discutida más abajo, para preferir DML cuando no se tiene una convicción sustantiva sobre la forma funcional.

=== Validación
<sec-cap16_validacion>

==== Sensibilidad a la elección de $lambda$

#figure(
  kind: raw,
  caption: [Sensibilidad al hiperparametro lambda.],
  ```python
import matplotlib.pyplot as plt
from sklearn.linear_model import Lasso

lasso_Y_cv = LassoCV(cv=5, max_iter=10000).fit(X, Y)
lambda_cv = lasso_Y_cv.alpha_

lambdas = np.logspace(
    -3,
    max(0, np.log10(lambda_cv * 1.5)),
    30
)
thetas = []
for lam in lambdas:
    lY = Lasso(alpha=lam, max_iter=10000).fit(X, Y)
    lD = Lasso(alpha=lam, max_iter=10000).fit(X, D)
    S = sorted(set(np.where(np.abs(lY.coef_) > 1e-8)[0]) |
               set(np.where(np.abs(lD.coef_) > 1e-8)[0]))
    if len(S) == 0:
        continue
    X_f = sm.add_constant(np.column_stack([D, X[:, S]]))
    ols = sm.OLS(Y, X_f).fit(cov_type="HC1")
    thetas.append((lam, ols.params[1], ols.bse[1]))

thetas = np.array(thetas)
plt.figure(figsize=(8, 5))
plt.errorbar(thetas[:, 0], thetas[:, 1], yerr=1.96*thetas[:, 2], fmt="o-")
if lambdas.min() <= lambda_cv <= lambdas.max():
    plt.axvline(lambda_cv, color="green", ls="--", label=r"$\lambda_{CV}$")
plt.xscale("log")
plt.xlabel("Lambda (penalizacion LASSO)")
plt.ylabel("Estimacion PDS del efecto causal")
plt.title("Sensibilidad de PDS a la eleccion de $\\lambda$")
plt.legend()
plt.tight_layout()
plt.savefig("figuras/pds_sensitivity.png", dpi=120, bbox_inches="tight")
plt.show()
```
) <lst-pds-sensitivity>

==== Tabla de riesgos

La tabla @tab-riesgos-cap08 resume los principales riesgos al aplicar PDS, junto con sus consecuencias, diagnósticos y estrategias de mitigación.

#riesgos[
  #figure(
    caption: [Riesgos al aplicar PDS LASSO.],
    table(
      columns: (1.4fr, 1.4fr, 1.4fr, 1.8fr),
      align: (left, left, left, left),
      stroke: none,
      table.hline(stroke: 0.8pt),
      table.header([*Riesgo*], [*Consecuencia*], [*Diagnóstico*], [*Mitigación*]),
      table.hline(stroke: 0.4pt),
      [Dense confounding],
      [Selección incompleta de confusoras relevantes],
      [Simulación con DGP de confusión densa],
      [Usar DML en lugar de PDS],
      table.hline(stroke: 0.4pt),
      [Lambda inestable],
      [Resultados frágiles que cambian drásticamente con $lambda$],
      [Gráfico de sensibilidad (Fig. @fig-cap16-pds-sensibilidad): buscar meseta vs. pendiente en el entorno del $lambda$ elegido],
      [Reportar el rango completo, y contrastar $lambda_"CV"$ (criterio predictivo) con $lambda_"BCH"$ (criterio teórico, @sec-cap16_lambda) en lugar de confiar en uno solo],
      table.hline(stroke: 0.4pt),
      [Controles post-tratamiento],
      [Sesgo por condicionar en variables afectadas por el tratamiento],
      [Construir un DAG del problema],
      [Excluir variables posteriores al tratamiento],
      table.hline(stroke: 0.8pt),
    )
  ) <tab-riesgos-cap08>
]

== Ejercicios propuestos
<sec-cap16_ejercicios>

+ Replique el listado @lst-pds-nhefs sobre el dataset #code[close_college] (educación sobre salario, IV = #code[nearc4]). ¿Cambia el estimado IV al usar PDS para seleccionar controles?

+ Modifique el DGP del capítulo @cap-regularizacion para tener 20 confusoras y 80 variables irrelevantes. Compare PDS con selección simple en términos de cobertura.

+ Sobre el dataset #code[cps_mixtape], estime el retorno a la educación con PDS y compare con DML.

+ Construya un DGP donde la estructura de confusión sea densa (100 variables pequeñas, cada una con coeficiente 0.1). Verifique que PDS falla pero DML funciona.

+ Implemente la penalización teórica de #cite(<belloni2014inference>, form: "prose") descrita en la @sec-cap16_lambda y compare, sobre #code[nhefs], el $lambda_"BCH"$ resultante con el $lambda_"CV"$ del listado @lst-pds-nhefs. ¿Cuántas variables selecciona cada uno? ¿Cambia el efecto estimado o solo el tamaño del conjunto seleccionado?

== Lecturas complementarias
<sec-cap16_lecturas>

#cite(<belloni2014inference>, form: "prose") es el _paper_ fundacional. #cite(<belloni2012sparse>, form: "prose") extiende a IV. #cite(<chernozhukov2018double>, form: "prose") (capítulo @cap-dml) presenta el enfoque alternativo. #cite(<chernozhukov2018applied>, form: "prose") ofrece un tratamiento pedagógico.
