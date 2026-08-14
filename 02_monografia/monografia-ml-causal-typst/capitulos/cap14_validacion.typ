// Capítulo 14 — Validación, refutación y sensibilidad
#import "../template/template.typ": *

#chapter[Validación, refutación y sensibilidad]
<cap-validacion>

#theorem-number-reset()

#cuadrosinoptico[
  #table(
    columns: (auto, 1fr),
    align: (left, left),
    stroke: none,
    [*Problema:*], [Validar modelos causales sin ground truth],
    [*Estimando:*], [CATE, ranking por efecto],
    [*Identificación:*], [No confusión, placebos, refutación],
    [*Método:*], [Curvas Qini y AUUC, transformed outcome, placebos, E-value],
    [*Nuisance:*], [$hat(e)(X), hat(mu)_(d)(X)$],
    [*Garantía:*], [Detección de fallos gruesos bajo refutación; cota de sensibilidad a confusión no observada (E-value)],
    [*Librerías:*], [econml, scikit-learn, causalml],
    [*Validación:*], [Suite de refutación, placebos, sensibilidad],
  )
]

#notatecnica[
Los tres capítulos anteriores (@cap-ortogonalidad, @cap-dml, @cap-meta-learners, @cap-causal-forests) presentaron estimadores; este capítulo cierra el bloque de estimación preguntando cómo saber si un estimador de CATE, en ausencia de _ground truth_, es confiable — y extiende la pregunta, en su última sección, a cómo organizar ese proceso de evaluación como parte de un sistema versionado y no solo como un chequeo puntual.
]

== Motivación aplicada
<sec-cap14_motivacion>

Un banco ha entrenado un modelo de uplift para decidir a qué clientes ofrecer una línea de crédito pre-aprobada. El modelo produce un CATE estimado para cada cliente. Antes de desplegarlo, el equipo de riesgo debe validar que el modelo realmente distingue clientes con alto uplift de clientes con bajo uplift. El problema fundamental: *no se observa el CATE verdadero* para ningún cliente, porque cada cliente recibe solo un tratamiento (no ambos resultados potenciales).

Esta es la situación estándar en aplicaciones reales de ML causal: el estimando de interés (CATE, policy value) no es observable, lo que hace inválida la validación cruzada estándar de ML supervisado. Este capítulo desarrolla estrategias de validación indirecta: curvas Qini, curvas uplift, transformed outcomes, validación con placebos, y comparación con benchmarks clásicos. Para datasets sintéticos con ground truth, también discutimos métricas directas de error (RMSE en $tau$, cobertura del IC).

== Teoría, supuestos y garantías
<sec-cap14_teoria>

=== El problema fundamental
<sec-cap14_problema_fundamental>

En ML supervisado estándar, la validación se basa en comparar predicciones $hat(Y)$ con observaciones $Y$. Para estimadores de CATE, el análogo sería comparar $hat(tau)(x)$ con $tau(x)$, pero $tau(x)$ no se observa. La única excepción son los datos sintéticos con DGP conocido, donde $tau(x)$ se computa analíticamente.

#proposition(name: [Imposibilidad de validación directa])[
  Para cualquier estimador $hat(tau)$ y cualquier dataset real $(Y, D, X)$, no existe función de los datos que permita estimar el error $norm(hat(tau) - tau)$ sin supuestos adicionales.
] <prop-no-direct-validation>

La solución es recurrir a _proxy metrics_ y a _placebo tests_ que, aunque no miden el error directamente, sí detectan fallos gruesos del estimador.

=== Curva Qini (versión acumulada)
<sec-cap14_qini>

La curva Qini evalúa el ranking por $hat(tau)$. Una versión acumulada ordena las unidades por $hat(tau)$ descendente y compara el uplift acumulado contra una asignación aleatoria:

$
Q_("cum")(q) = sum_(i in T(q)) Y_i - (|T(q)|) / (|C(q)|) sum_(i in C(q)) Y_i,
$

cuando $|C(q)| > 0$. Si $|C(q)| = 0$, la cantidad no está definida y debe regularizarse o excluirse del gráfico.

También puede definirse un uplift promedio top-$q$:

$
Q_("avg")(q) = 1/|T(q)| sum_(i in T(q)) Y_i - 1/|C(q)| sum_(i in C(q)) Y_i.
$

*Supuestos.* La curva Qini no requiere conocer $tau(x)$, pero su validez como proxy de ranking supone que los residuos $epsilon_i = Y_i - mu_(D_i)(X_i)$ son intercambiables entre tratados y controles. No garantiza ausencia de sesgo en la magnitud de $hat(tau)$, solo calidad de ranking.

*Garantías.* Bajo no confusión y soporte común, si $hat(tau)$ es monótono respecto a $tau$, la curva Qini es creciente y domina al baseline aleatorio. La pendiente inicial alta indica concentración de unidades con alto efecto en el top del ranking.

Interpretación:

- Si $hat(tau)$ es informativo, la curva acumulada debe ubicarse por encima del baseline aleatorio, con pendiente inicial alta.
- El uplift promedio top-$q$ no tiene por qué crecer con $q$; si el ranking es correcto, suele decrecer a medida que se incorporan unidades con menor efecto.
- Una curva Qini creciente en términos acumulados indica buen ranking, pero no garantiza ausencia de sesgo en la magnitud de $hat(tau)$.

*Resumen escalar: AUUC y coeficiente Qini.* Comparar dos curvas visualmente no escala cuando hay que evaluar muchos modelos o automatizar la decisión en un pipeline de CI (@cap-cicd-causal). Se usan por eso dos resúmenes escalares, que conviene no confundir. El *AUUC* (_Area Under the Uplift Curve_) es simplemente el área bajo la curva de uplift acumulado; depende de la escala de $Y$ y del tamaño muestral, por lo que solo tiene sentido comparar AUUC entre modelos evaluados sobre exactamente la misma muestra. El *coeficiente Qini* normaliza esa área restando el _baseline_ aleatorio y dividiendo por el área del modelo perfecto, produciendo un número comparable entre datasets, análogo al coeficiente de Gini del que toma el nombre.

Dos advertencias operativas. Primera: ambos son métricas de *ranking*, no de calibración —un modelo que multiplique todos sus $hat(tau)$ por 10 tiene exactamente el mismo AUUC y produciría un presupuesto de campaña diez veces mal dimensionado—. Segunda: ambos son estadísticos muestrales con varianza no despreciable, especialmente en las colas del ranking donde $|C(q)|$ es pequeño; reportar un AUUC sin banda de confianza por _bootstrap_ invita a declarar ganador a un modelo que no lo es. El @cap-uplift-targeting retoma estas métricas como criterio de evaluación de la política y no solo del estimador.

=== Curva uplift y transformed outcome
<sec-cap14_uplift_transformed>

La _uplift curve_ normaliza por el tamaño total:
$
U(q) = 1/n sum_(i in T(q)) Y_i - 1/n sum_(i in C(q)) Y_i dot.c (|T(q)|) / (|C(q)|).
$

El _transformed outcome_ @athey2019using construye una variable $Y^star$ cuya esperanza es $tau(X)$:
$
Y_i^star = Y_i dot.c (D_i - hat(e)(X_i)) / (hat(e)(X_i)(1 - hat(e)(X_i))).
$ <eq-transformed-outcome>

#proposition[
  Si $hat(e) = e_0$, entonces $E[Y^star | X] = tau(X)$.
] <prop-transformed-outcome>

*Supuestos.* La validez de $Y^star$ como proxy requiere que $hat(e)$ sea consistente para el verdadero propensity score $e_0$. Si $hat(e)$ está mal especificado, $E[Y^star | X] != tau(X)$.

*Garantías.* $Y^star$ permite usar métricas de ML supervisado (RMSE, correlación) sobre $hat(tau)$. La desventaja: $Y^star$ tiene alta varianza, especialmente cuando $hat(e)$ es cercano a 0 o 1. La varianza de $Y^star$ condicional en $X$ es:
$
"Var"(Y^star | X) = sigma^2(X) + (tau(X)^2) / (e_0(X)(1 - e_0(X))),
$
que explota cuando $e_0(X) -> 0$ o $e_0(X) -> 1$.

=== Placebo tests
<sec-cap14_placebo_tests>

Un _placebo test_ estima el efecto causal en un contexto donde debería ser cero. La lógica es simple: si el estimador produce un efecto no nulo donde sabemos que no debería haberlo, el estimador está sesgado.

*Supuestos.* El placebo test requiere que en el contexto placebo se cumplan los mismos supuestos de identificación que en el contexto real. Si no, un resultado no nulo podría deberse a violación de supuestos en el placebo y no a un problema del estimador.

*Garantías.* Bajo la hipótesis nula de efecto nulo y correcta especificación, el estimador debe producir un efecto indistinguible de cero. Un resultado significativo en un placebo es evidencia de mala especificación.

Tres variantes comunes:

- *Placebo temporal:* estimar el efecto en un periodo pre-tratamiento. Si el estimador es válido, el efecto debe ser cercano a cero.
- *Placebo por subgrupo:* estimar el efecto en un subgrupo que no debería responder al tratamiento (p. ej., efecto de un programa escolar sobre jubilados).
- *Placebo por outcome:* estimar el efecto sobre un outcome que no debería responder (p. ej., efecto de becas sobre altura).

=== Sensibilidad a confusión no observada: protocolo de tres niveles
<sec-cap14_evalue>

Los placebos detectan mala especificación, pero no responden la pregunta que más importa y que ningún test puede responder con los datos disponibles: *¿cuán fuerte tendría que ser un confusor no observado para anular el resultado?* La literatura de análisis de sensibilidad la convierte en una pregunta cuantitativa y reportable. La formulación más difundida hoy es el *E-value* de #cite(<vanderweele2017evalue>, form: "prose").

#definition(name: [E-value])[
Para una razón de riesgos estimada $"RR" > 1$, el *E-value* es
$
"E" = "RR" + sqrt("RR" ("RR" - 1)),
$
y se interpreta así: un confusor no observado tendría que estar asociado *tanto* al tratamiento *como* al resultado por un factor de riesgo de al menos $"E"$ —cada uno, y por encima de los confusores ya medidos— para explicar completamente la asociación observada. Para el límite del intervalo de confianza más cercano a la nulidad se calcula un segundo E-value, que indica la fuerza necesaria para volver el resultado estadísticamente no significativo.
]

La virtud del E-value es que traduce la amenaza a la identificación a una escala que un experto de dominio puede juzgar. Decir "el resultado es sensible a confusión no observada" no es accionable; decir "haría falta un confusor no medido asociado al tratamiento y al resultado con RR $>= 3.2$, cuando el confusor observado más fuerte de que disponemos tiene RR $= 1.6$" invita a una discusión sustantiva concreta: ¿existe una variable plausible de esa magnitud que no hayamos medido?

Sus límites deben declararse con la misma claridad. El E-value es una condición *necesaria* mínima, no suficiente: describe el confusor único más débil capaz de explicar el resultado, y varios confusores moderados pueden combinarse para lograr lo mismo. No incorpora información sobre qué confusores son plausibles en el dominio —es una cota, no una probabilidad—. Y su formulación estándar está definida sobre razones de riesgo; aplicarlo a un efecto en diferencias requiere transformar primero la escala, paso que se omite con frecuencia y que invalida el número reportado.

*Nivel 2 — Sensibilidad en escala $R^2$.* Para estimaciones tipo PLR (DML-PLR, PDS), la pregunta equivalente es: ¿qué $R^2$ parcial con $D$ y con $Y$ tendría que tener un confusor no observado $U$ para anular el efecto? Si $r_(Y dot.op U | X, D)^2$ y $r_(D dot.op U | X)^2$ denotan las fracciones de varianza residual explicadas por $U$, el efecto deja de ser significativo cuando ambas superan un umbral derivable del $t$-estadístico observado (#cite(<cinellihazlett2020>, form: "prose"), Teorema 1; la formulación en escala $R^2$ se remonta a #cite(<imbens2003sensitivity>, form: "prose")). La ventaja sobre el E-value: se reporta contra _benchmarks_ observados — el $R^2$ parcial del confusor medido más fuerte — en la misma escala del modelo estimado, sin cambio de escala a razones de riesgo.

*Nivel 3 — Identificación parcial.* Cuando el supuesto puede fallar parcialmente, el reporte correcto es un intervalo de _bounds_. Con $Y in [0, 1]$ y sin ningún supuesto de no confusión, #cite(<manski1990nonparametric>, form: "prose") muestran que
$
theta = E[Y(1) - Y(0)] in [ E[Y|D=1]P(D=1) - E[Y|D=0]P(D=0) - P(D=0), thin E[Y|D=1]P(D=1) - E[Y|D=0]P(D=0) + P(D=1) ],
$
de ancho $<= 1$, que puede estrecharse combinando _bounds_ con el E-value del Nivel 1 (un confusor acotado en fuerza acota el desplazamiento de $theta$).

*Protocolo del curso.* Todo resultado observacional del proyecto final (@sec-apE_sensibilidad) reporta: Nivel 1 (E-value, siempre) + Nivel 2 ($R^2$ de Imbens / Cinelli--Hazlett, cuando el estimador sea tipo PLR) + Nivel 3 cuando el _outcome_ esté acotado y el resultado sea próximo a cero. Un resultado que no sobrevive el Nivel 1 se reporta como "no robusto" y no se despliega.

=== Validación con datos sintéticos
<sec-cap14_sinteticos>

Para datasets sintéticos con $tau(x)$ conocido, se reportan:

- *Sesgo:* $E[hat(tau)(X) - tau(X)]$.
- *RMSE:* $sqrt(E[(hat(tau)(X) - tau(X))^2])$.
- *Cobertura del IC:* fracción de $x$ tales que $tau(x) in [hat(tau)(x) plus.minus 1.96 hat(sigma)(x)]$.
- *Policy regret:* diferencia entre $V(pi^*)$ y $V(hat(pi))$ donde $pi^*$ es la política óptima y $hat(pi)$ se deriva de $hat(tau)$.

=== Tests formales de heterogeneidad: BLP, BEST y CLAN
<sec-cap14_tests_heterogeneidad>

La curva Qini evalúa _ranking_; no responde si la heterogeneidad detectada es estadísticamente distinguible de cero. #cite(<chernozhukov2020generic>, form: "prose") proveen tests con control de tipo I, sin _ground truth_, mediante _sample-splitting_ (la misma lógica del _cross-fitting_ del @cap-ortogonalidad).

*BLP (Best Linear Predictor).* Sea $hat(T)(X)$ un score de prioridad (p. ej. $hat(tau)$ de un _causal forest_). En la muestra de evaluación, con el _transformed outcome_ $Y^star$ (Ec. @eq-transformed-outcome):
$
Y_i^star = beta_1 hat(T)_i + beta_2 (hat(T)_i - overline(T)) dot.op hat(T)_i + epsilon_i.
$
El test $H_0: beta_2 = 0$ es un test válido de "no hay heterogeneidad linealmente detectable por $hat(T)$"; $beta_1$ estima el efecto promedio ponderado por $hat(T)$.

*BEST (Best subgroup Treatment Effect).* Particionar por la mediana de $hat(T)$ en los dos grupos de mayor/menor score estimado y testear la diferencia de sus efectos medios, con IC construidos sobre la muestra de evaluación separada.

*CLAN (Classification Analysis).* Efectos medios por cuantiles de $hat(T)$ con IC simultáneos (corrección de Bonferroni o _bootstrap_ multiplicador), para perfilar la forma de la heterogeneidad sin compromiso paramétrico.

Los tres están implementados en #code[econml.validate.DRtester].

*Regla operativa del curso:* ningún informe que reporte heterogeneidad se publica sin el BLP; si $beta_2$ no es significativo, la heterogeneidad reportada se declara exploratoria.

=== Intervalos conformes para efectos individuales
<sec-cap14_conformal>

*El problema.* El teorema de cobertura del CATE del @cap-causal-forests da cobertura para $tau(x)$, no para el efecto individual $Y_(i)(1) - Y_(i)(0)$: la varianza del efecto individual incluye el ruido $epsilon_i$, que la varianza del estimador no captura. Las decisiones individuales del servicio del @cap-despliegue-servicio requieren lo segundo.

*Procedimiento (split conformal sobre transformed outcome).* Bajo asignación aleatorizada o _propensity_ conocido, $Y_i^star$ (Ec. @eq-transformed-outcome) satisface $E[Y^star | X] = tau(X)$:

+ Particionar en entrenamiento $cal(D)_1$ y calibración $cal(D)_2$.
+ Entrenar $hat(tau)$ en $cal(D)_1$.
+ En $cal(D)_2$ calcular residuos no conformes $R_i = abs(Y_i^star - hat(tau)(X_i))$.
+ $hat(C)(x) = [hat(tau)(x) - hat(q), thin hat(tau)(x) + hat(q)]$, con $hat(q)$ el cuantil $ceil((m+1)(1-alpha))/m$ de ${R_i}$.

#proposition(name: [Cobertura conforme])[
  Si las observaciones son intercambiables, $P(Y_"nuevo"^star in hat(C)(X_"nuevo")) >= 1 - alpha$, sin supuestos distribucionales sobre $(Y, D, X)$.
] <prop-conformal-coverage>

Dos advertencias. Primera: la cobertura es para el _transformed outcome_ —proxy insesgado del efecto—, no para $Y_(i)(1) - Y_(i)(0)$ literal (#cite(<leicandes2021>, form: "prose") tratan la versión con contrafactuales imputados). Segunda: con _propensity_ estimado se requiere _conformal_ ponderado (#cite(<tibshirani2019conformal>, form: "prose")); la versión sin ponderar es válida solo si $hat(e) approx e_0$. Para la base de predicción conforme libre de distribución, ver #cite(<lei2018distribution>, form: "prose"), y #cite(<romano2019conformalized>, form: "prose") para la variante de regresión cuantílica conforme.

*Integración en producción:* el endpoint `/predict` (@lst-inference-pura) puede añadir el campo `ic_individual` cuando exista calibración conforme. La _model card_ (@cap-hf-hub) debe declarar qué garantiza cada intervalo: `ic_95` es cobertura del estimando poblacional; `ic_individual` es cobertura marginal no paramétrica.

== Implementación en Python
<sec-cap14_implementacion>

=== Curva Qini sobre datos sintéticos
<sec-cap14_impl_qini>

#figure(
  kind: raw,
  caption: [Curva Qini sobre dataset sintético con ground truth.],
  ```python
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
from econml.dml import CausalForestDML
from sklearn.ensemble import GradientBoostingRegressor, GradientBoostingClassifier

# DGP con CATE conocido
def make_dgp(n=3000, seed=0):
    rng = np.random.default_rng(seed)
    X = rng.uniform(-1, 1, (n, 5))
    e = 1/(1 + np.exp(-0.5 - 0.3*X[:, 0]))
    D = (rng.uniform(size=n) < e).astype(int)
    tau = 2 + 3*X[:, 0] - X[:, 1]**2
    mu0 = X[:, 2] + X[:, 3]
    Y = mu0 + D * tau + rng.standard_normal(n)*0.5
    return Y, D, X, tau

Y, D, X, tau_true = make_dgp(3000, seed=42)
cf = CausalForestDML(model_y=GradientBoostingRegressor(n_estimators=200, random_state=42),
                     model_t=GradientBoostingClassifier(n_estimators=200, random_state=42),
                     discrete_treatment=True, n_estimators=400, random_state=42,
                     min_samples_leaf=20, cv=5).fit(Y, D, X=X)
tau_hat = cf.effect(X)

# Metricas directas (solo posibles con ground truth)
rmse = np.sqrt(np.mean((tau_hat - tau_true)**2))
bias = np.mean(tau_hat - tau_true)
print(f"RMSE: {rmse:.4f}  Bias: {bias:.4f}")

# Curva Qini
def qini_curve(Y, D, tau_hat, n_bins=20):
    df = pd.DataFrame({"Y": Y, "D": D, "tau_hat": tau_hat})
    df = df.sort_values("tau_hat", ascending=False).reset_index(drop=True)
    df["cum_n"] = np.arange(1, len(df)+1)
    df["cum_D"] = df["D"].cumsum()
    df["cum_Y_T"] = (df["Y"] * df["D"]).cumsum()
    df["cum_Y_C"] = (df["Y"] * (1-df["D"])).cumsum()
    df["cum_n_C"] = df["cum_n"] - df["cum_D"]
    # Qini acumulada, no uplift promedio top-q
    df["qini"] = df["cum_Y_T"] - df["cum_Y_C"] * (df["cum_D"] / df["cum_n_C"].clip(lower=1))
    return df["cum_n"] / len(df), df["qini"]

frac, qini = qini_curve(Y, D, tau_hat)
# Random baseline
frac_r, qini_r = qini_curve(Y, D, np.random.permutation(tau_hat))
plt.figure(figsize=(8, 5))
plt.plot(frac, qini, label="Causal Forest", lw=2)
plt.plot(frac_r, qini_r, label="Random", lw=2, ls="--", color="gray")
plt.xlabel("Fracción de muestra (top por CATE estimado)")
plt.ylabel("Uplift acumulado (Qini)")
plt.legend()
plt.title("Curva Qini acumulada: validación de ranking por CATE")
plt.tight_layout()
plt.savefig("figuras/qini_curve.png", dpi=120, bbox_inches="tight")
plt.show()
```
) <lst-qini>

=== Placebo test
<sec-cap14_impl_placebo>

#figure(
  kind: raw,
  caption: [Placebo temporal sobre panel sintético.],
  ```python
import pandas as pd
df = pd.read_csv("../data/datasets/synthetic/panel/panel_fe_dynamic/student.csv")
# Placebo: estimar el efecto en periodo t=1 sobre el "outcome" en t=0
df_pre = df[df["time"] == 0].copy()
df_pre["D_fake"] = (df_pre["treated_group"] == 1).astype(int)  # tratamiento "placebo"
# Si el metodo es valido, el efecto placebo debe ser cercano a 0
from econml.dml import LinearDML
from sklearn.ensemble import RandomForestRegressor, RandomForestClassifier
est = LinearDML(model_y=RandomForestRegressor(n_estimators=100, random_state=42),
                model_t=RandomForestClassifier(n_estimators=100, random_state=42),
                discrete_treatment=True, cv=3, random_state=42)
# No usar unit_id como covariable: es un identificador, no una variable pre-tratamiento.
# Si no hay covariables pre-tratamiento, usar solo intercepto
X_pre = np.ones((len(df_pre), 1))
est.fit(df_pre["y_outcome"].values, df_pre["D_fake"].values,
        X=X_pre)
ate_placebo = est.ate(X=X_pre)
lb, ub = est.ate_interval(X=X_pre, alpha=0.05)
print(f"ATE placebo: {ate_placebo:.4f}  IC: [{lb:.4f}, {ub:.4f}]")
print("Debe contener al 0 si el metodo es valido.")
```
) <lst-placebo>

== Caso empírico y validación
<sec-cap14_caso>

=== Suite de refutación
<sec-cap14_refutation>

La tabla @tab-refutation-suite resume las pruebas de refutación estándar para validar modelos causales sin ground truth. Estas pruebas no garantizan que el modelo sea correcto, pero detectan fallos gruesos de especificación.

#figure(
  caption: [Suite de refutación para modelos causales.],
  table(
    columns: (1.2fr, 1.8fr, 1.8fr),
    align: (left, left, left),
    stroke: none,
    table.hline(stroke: 0.8pt),
    table.header([*Prueba*], [*Qué hace*], [*Interpretación*]),
    table.hline(stroke: 0.4pt),
    [Placebo treatment], [Reemplaza $D$ por variable aleatoria], [El efecto estimado debe caer a cero; si no, el modelo detecta señal espuria],
    [Random common cause], [Agrega una covariable ruido independiente de $Y$ y $D$], [El efecto estimado debe ser estable; un cambio grande indica sensibilidad a ruido],
    [Subset validation], [Remuestrea los datos (bootstrap) y reestima], [La distribución bootstrap del efecto debe ser estable; varianza alta sugiere sobreajuste],
    [Transformed outcome], [Construye $Y^star$ y evalúa $hat(tau)$ con métricas supervisadas], [$E[Y^star | X] = tau(X)$ bajo $hat(e)$ correcto; permite RMSE y correlación],
    [BLP/BEST], [Test de heterogeneidad sobre $hat(T)$], [$beta_2$ no significativo $=>$ la heterogeneidad no supera el ruido (@sec-cap14_tests_heterogeneidad)],
    table.hline(stroke: 0.8pt),
  )
) <tab-refutation-suite>

=== Curva Qini comparativa
<sec-cap14_qini_comparativa>

La figura @fig-cap14-qini compara dos modelos causales (Causal Forest y T-learner con GBM) sobre un dataset sintético con CATE conocido. Un modelo informativo produce una curva Qini creciente y claramente por encima del baseline aleatorio; un modelo no informativo produce una curva plana o ruidosa.

#figure(
  image("../figuras/fig_cap14_qini.png", width: 85%),
  caption: [Curva Qini comparativa: Causal Forest vs. T-learner (GBM) vs. baseline aleatorio. Dataset sintético con CATE conocido $tau(x) = 2 + 3x_1 - x_2^2$, $n = 3\,000$. El Causal Forest domina al T-learner, especialmente en el rango 20–60% de la muestra.],
) <fig-cap14-qini>

*Interpretación.* El Causal Forest (azul) produce una curva Qini más pronunciada que el T-learner (rojo), lo que indica que su ranking por CATE estimado es más informativo. Ambos dominan al baseline aleatorio (gris punteado), confirmando que ambos modelos capturan señal causal real. La diferencia entre modelos es mayor en el rango 20–60% de la muestra, donde el Causal Forest aprovecha mejor la estructura local de heterogeneidad.

El dataset #code[thornton_hiv] @thornton2008demand evalúa el efecto de incentivos monetarios sobre la demanda de resultados de test de VIH en Malaui. Su valor para este capítulo es que el tratamiento fue *aleatorizado*, de modo que la identificación no está en discusión y toda desviación detectada por la suite de refutación es atribuible al estimador y no al diseño — la situación de control que permite calibrar qué tan informativas son las métricas indirectas antes de aplicarlas a datos observacionales, donde ambas fuentes de error se confunden. Aplicando el mismo protocolo de validación, el modelo produce un ranking cuyas unidades top-20% muestran un uplift sustancialmente mayor que el promedio, validando empíricamente la utilidad del estimador.

#intuicion[
  *Caja de profundización 7.1: Pruebas de refutación y análisis de sensibilidad*

  *Objetivo.* Aprender a poner a prueba un modelo causal cuando no tenemos el efecto verdadero.

  *Pruebas de placebo.*
  - *Placebo treatment:* asignar el tratamiento aleatoriamente y reestimar. El ATE debería ser cero.
  - *Placebo outcome:* usar una variable que sabemos que no es afectada por el tratamiento como si fuera $Y$.
  - *Placebo temporal:* en datos de panel, aplicar el método a un período prepolíticas donde no debería haber efecto.

  *¿Qué tan sensible es mi resultado a un confusor no observado?* Incluso si controlamos por muchos confusores observados, siempre puede haber uno no observado. El *E-value* (@sec-cap14_evalue) responde: ¿qué tan fuerte tendría que ser ese confusor para explicar mi resultado? Un E-value grande sugiere robustez —pero "grande" solo tiene sentido *comparado con la fuerza de los confusores que sí se midieron*, no contra un umbral universal.

  *Bootstrap para curvas Qini.* Podemos remuestrear los datos muchas veces y recalcular la curva Qini cada vez. Esto nos da bandas de confianza alrededor de la curva y permite comparar modelos formalmente.
]

== Riesgos, límites y sensibilidad
<sec-cap14_riesgos>

=== Tabla de riesgos
<sec-cap14_tabla_riesgos>

La tabla @tab-riesgos-cap07 resume los principales riesgos al validar modelos causales sin ground truth, junto con sus consecuencias, diagnóstico y mitigación.

#riesgos[
  #figure(
    caption: [Riesgos en la validación de modelos causales sin ground truth.],
    table(
      columns: (1.4fr, 1.4fr, 1.4fr, 1.8fr),
      align: (left, left, left, left),
      stroke: none,
      table.hline(stroke: 0.8pt),
      table.header([*Riesgo*], [*Consecuencia*], [*Diagnóstico*], [*Mitigación*]),
      table.hline(stroke: 0.4pt),
      [Validar con $R^2$ de $Y$],
      [Falsa confianza en estimaciones sesgadas],
      [Comparar $R^2$ predictivo con métricas causales (Qini, placebos)],
      [Usar placebos, Qini y ground truth sintético. El $R^2$ predictivo de $Y$ no correlaciona con la calidad de la estimación causal. Un modelo puede predecir $Y$ perfectamente y producir CATEs totalmente sesgados],
      table.hline(stroke: 0.4pt),
      [Omitir placebo tests en datos reales],
      [No detectar mala especificación del estimador],
      [Verificar que se aplicaron placebos antes de desplegar],
      [Sin ground truth, los placebos son la única validación de especificación. Son obligatorios],
      table.hline(stroke: 0.4pt),
      [Sobreinterpretar la curva Qini],
      [Creer que un ranking informativo implica CATE insesgado],
      [Comparar magnitud de $hat(tau)$ con benchmarks o transformed outcome],
      [Una curva Qini creciente indica que el ranking es informativo, pero no que el CATE estimado sea insesgado. Puede haber sesgo uniforme que preserve el ranking],
      table.hline(stroke: 0.8pt),
    )
  ) <tab-riesgos-cap07>
]

=== Límites
<sec-cap14_limites>

Las métricas indirectas (Qini, uplift, transformed outcome) solo detectan fallos gruesos. No garantizan ausencia de sesgo. La validación definitiva requiere replicación en experimentos controlados o datasets sintéticos con ground truth.

*¿Cuándo no usar este enfoque?* La validación indirecta no reemplaza un diseño de identificación creíble. Si el supuesto de no confusión es cuestionable, ninguna suite de refutación lo rescata. En esos casos, priorizar diseños cuasi-experimentales (RDD, DID, IV) sobre la validación post-hoc.

== Evaluación offline en el ciclo de vida del sistema
<sec-cap14_evaluacion_offline>

Las secciones anteriores de este capítulo responden una pregunta estadística: ¿el estimador de CATE es razonable? Esta sección, que extiende el capítulo con una perspectiva de ingeniería de sistemas siguiendo a @huyen2022dmls (Capítulo 6, "Model Development and Offline Evaluation"), responde una pregunta distinta y complementaria: *¿cómo se organiza el proceso de evaluación offline para que sea comparable a través del tiempo y de distintas versiones del modelo?*

=== _Baselines_ obligatorios

#cite(<huyen2022dmls>, form: "prose") insiste en que ningún modelo se evalúa en el vacío: siempre debe compararse contra al menos un _baseline_ simple. Para un sistema de estimación causal, se recomiendan tres _baselines_ mínimos antes de aceptar cualquier estimador de CATE como el de producción:

#table(
  columns: (1.3fr, 2.7fr),
  align: left,
  stroke: 0.5pt + gray.lighten(60%),
  table.header([*Baseline*], [*Qué revela*]),
  [Efecto constante (ATE vía DML, @cap-dml)], [Si el CATE estimado no supera a un efecto constante en la curva Qini, la heterogeneidad modelada no aporta valor accionable.],
  [Regla aleatoria], [Piso de referencia: cualquier estimador debe superar claramente a targetear al azar.],
  [Regla basada en riesgo (sin causalidad)], [Detecta si el "efecto heterogéneo" estimado es, en realidad, una reformulación de quién tiene mayor $Y$ esperado sin tratamiento — un error de confusión entre pronóstico de riesgo y efecto causal, ya discutido en el @cap-causalidad-elemental.],
  [RATE del estimador candidato vs. efecto constante], [Si RATE no supera al efecto constante, la heterogeneidad no aporta valor (consistente con la advertencia de la Figura @fig-cap21-policy-value).],
)

=== Selección formal de estimadores de CATE: RATE

El @cap-meta-learners compara meta-learners por RMSE sobre $tau$, métrica disponible solo con _ground truth_ sintético. En datos reales, el criterio formal es RATE (_Rank-Weighted Average Treatment Effect_, #cite(<yadlowsky2021rate>, form: "prose")):
$
"WET"(alpha) &= "efecto promedio sobre el top-" alpha " de la población bajo el ranking de " hat(tau), \\
"RATE"(alpha) &= integral_0^alpha "WET"(u) dif u.
$
RATE pondera las regiones del _ranking_ donde los errores de priorización cuestan más, y admite inferencia vía _influence function_: la diferencia de RATE entre dos estimadores tiene IC válido, análogo al test de diferencia de AUC entre clasificadores. El #code[RScorer] (#code[econml.score.RScorer], @sec-apB_econml) implementa exactamente esta comparación.

*Regla operativa del curso:* la elección entre meta-learners y _causal forest_ en datos reales se documenta con la diferencia de RATE y su IC, no con la inspección visual de la curva Qini. Qini sigue siendo la métrica de reporte para audiencias de negocio (@cap-uplift-targeting); RATE es la métrica de decisión interna.

=== Versionado del proceso de evaluación

Un segundo punto que DMLS enfatiza y que la literatura puramente estadística de validación causal rara vez menciona: el *proceso* de evaluación offline —qué _baselines_, qué partición de datos, qué semilla aleatoria— debe versionarse junto con el modelo, no solo el modelo mismo. Sin esto, comparar "la nueva versión del estimador es mejor que la anterior" es una afirmación no verificable: dos evaluaciones hechas con particiones distintas de los datos no son comparables, sin importar cuán rigurosa sea cada una por separado. El esqueleto de repositorio del @cap-anatomia-sistema incluye la carpeta `tests/` exactamente para fijar este proceso una vez y reutilizarlo.

Esta perspectiva de sistema es la que conecta este capítulo con el siguiente: una vez que el proceso de evaluación offline está versionado y es reproducible, la pregunta natural es cómo llevar el estimador que pasó esa evaluación a un servicio que otros puedan consultar — el tema del Capítulo 15.

== Ejercicios y notas bibliográficas
<sec-cap14_ejercicios>

=== Ejercicios propuestos
<sec-cap14_ejercicios_propuestos>

+ Replique el listado @lst-qini con tres estimadores: causal forest, X-learner, T-learner. ¿Cuál produce la curva Qini más pronunciada?

+ Construya un DGP donde el CATE sea constante ($tau(x) = tau$ para todo $x$). Verifique que la curva Qini es plana.

+ Sobre el dataset #code[cps_mixtape], estime el CATE con causal forest y aplique un placebo temporal si hay datos de años previos disponibles.

+ Implemente el transformed outcome $Y_i^star$ de la ecuación @eq-transformed-outcome y calcule la correlación entre $Y_i^star$ y $hat(tau)$. ¿Es alta? ¿Qué dice esto sobre la calidad del estimador?

=== Lecturas complementarias
<sec-cap14_lecturas>

#cite(<gutierrez2017causal>, form: "prose") revisa la literatura de uplift e introduce el _transformed outcome_ usado en la @sec-cap14_uplift_transformed. #cite(<athey2019using>, form: "prose") formaliza la validación causal aplicada. #cite(<schuler2018comparison>, form: "prose") compara sistemáticamente estrategias de selección de modelo para CATE y es la referencia empírica más útil para decidir con qué métrica quedarse. Para Qini, @radcliffe2007using. #cite(<vanderweele2017evalue>, form: "prose") es la referencia del E-value (@sec-cap14_evalue) y contiene las tablas de conversión de escala necesarias para aplicarlo fuera de razones de riesgo. #cite(<thornton2008demand>, form: "prose") documenta el experimento aleatorizado usado como banco de pruebas con identificación no discutida. Sobre el versionado del proceso de evaluación de la @sec-cap14_evaluacion_offline, véase @huyen2022dmls, Capítulo 6.
