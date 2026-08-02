// Capítulo 7 — Validación, refutación y sensibilidad
#import "../template/template.typ": *

#chapter[Validación, refutación y sensibilidad]
<cap-validacion>

#theorem-number-reset()

#cuadrosinoptico[
  #table(
    columns: (auto, 1fr),
    align: (left, left),
    stroke: none,
    [*[Problema]*], [Validar modelos causales sin ground truth],
    [*[Estimando]*], [CATE, ranking por efecto],
    [*[Identificación]*], [No confusión, placebos, refutación],
    [*[Método]*], [Curvas Qini, transformed outcome, placebos],
    [*[Nuisance]*], [$hat(e)(X), hat(mu)_d(X)$],
    [*[Garantía]*], [Detección de fallos gruesos bajo refutación],
    [*[Librerías]*], [econml, scikit-learn, causalml],
    [*[Validación]*], [Suite de refutación, placebos, sensibilidad],
  )
]

#notatecnica[
Los tres capítulos anteriores (@cap-ortogonalidad, @cap-dml, @cap-meta-learners, @cap-causal-forests) presentaron estimadores; este capítulo cierra el bloque de estimación preguntando cómo saber si un estimador de CATE, en ausencia de _ground truth_, es confiable — y extiende la pregunta, en su última sección, a cómo organizar ese proceso de evaluación como parte de un sistema versionado y no solo como un chequeo puntual.
]

== Motivación aplicada
<sec-cap07_motivacion>

Un banco ha entrenado un modelo de uplift para decidir a qué clientes ofrecer una línea de crédito pre-aprobada. El modelo produce un CATE estimado para cada cliente. Antes de desplegarlo, el equipo de riesgo debe validar que el modelo realmente distingue clientes con alto uplift de clientes con bajo uplift. El problema fundamental: *no se observa el CATE verdadero* para ningún cliente, porque cada cliente recibe solo un tratamiento (no ambos resultados potenciales).

Esta es la situación estándar en aplicaciones reales de ML causal: el estimando de interés (CATE, policy value) no es observable, lo que hace inválida la validación cruzada estándar de ML supervisado. Este capítulo desarrolla estrategias de validación indirecta: curvas Qini, curvas uplift, transformed outcomes, validación con placebos, y comparación con benchmarks clásicos. Para datasets sintéticos con ground truth, también discutimos métricas directas de error (RMSE en $tau$, cobertura del IC).

== Teoría, supuestos y garantías
<sec-cap07_teoria>

=== El problema fundamental
<sec-cap07_problema_fundamental>

En ML supervisado estándar, la validación se basa en comparar predicciones $hat(Y)$ con observaciones $Y$. Para estimadores de CATE, el análogo sería comparar $hat(tau)(x)$ con $tau(x)$, pero $tau(x)$ no se observa. La única excepción son los datos sintéticos con DGP conocido, donde $tau(x)$ se computa analíticamente.

#proposition(name: [Imposibilidad de validación directa])[
  Para cualquier estimador $hat(tau)$ y cualquier dataset real $(Y, D, X)$, no existe función de los datos que permita estimar el error $norm(hat(tau) - tau)$ sin supuestos adicionales.
] <prop-no-direct-validation>

La solución es recurrir a _proxy metrics_ y a _placebo tests_ que, aunque no miden el error directamente, sí detectan fallos gruesos del estimador.

=== Curva Qini (versión acumulada)
<sec-cap07_qini>

La curva Qini evalúa el ranking por $hat(tau)$. Una versión acumulada ordena las unidades por $hat(tau)$ descendente y compara el uplift acumulado contra una asignación aleatoria:

$
Q_"cum"(q) = sum_(i in T(q)) Y_i - (|T(q)|) / (|C(q)|) sum_(i in C(q)) Y_i,
$

cuando $|C(q)| > 0$. Si $|C(q)| = 0$, la cantidad no está definida y debe regularizarse o excluirse del gráfico.

También puede definirse un uplift promedio top-$q$:

$
Q_"avg"(q) = 1/|T(q)| sum_(i in T(q)) Y_i - 1/|C(q)| sum_(i in C(q)) Y_i.
$

*Supuestos.* La curva Qini no requiere conocer $tau(x)$, pero su validez como proxy de ranking supone que los residuos $epsilon_i = Y_i - mu_(D_i)(X_i)$ son intercambiables entre tratados y controles. No garantiza ausencia de sesgo en la magnitud de $hat(tau)$, solo calidad de ranking.

*Garantías.* Bajo no confusión y soporte común, si $hat(tau)$ es monótono respecto a $tau$, la curva Qini es creciente y domina al baseline aleatorio. La pendiente inicial alta indica concentración de unidades con alto efecto en el top del ranking.

Interpretación:

- Si $hat(tau)$ es informativo, la curva acumulada debe ubicarse por encima del baseline aleatorio, con pendiente inicial alta.
- El uplift promedio top-$q$ no tiene por qué crecer con $q$; si el ranking es correcto, suele decrecer a medida que se incorporan unidades con menor efecto.
- Una curva Qini creciente en términos acumulados indica buen ranking, pero no garantiza ausencia de sesgo en la magnitud de $hat(tau)$.

=== Curva uplift y transformed outcome
<sec-cap07_uplift_transformed>

La _uplift curve_ normaliza por el tamaño total:
$
U(q) = 1/n sum_(i in T(q)) Y_i - 1/n sum_(i in C(q)) Y_i dot.c (|T(q)|) / (|C(q)|).
$

El _transformed outcome_ (@athey2019using) construye una variable $Y^star$ cuya esperanza es $tau(X)$:
$
Y_i^star = Y_i dot.c (D_i - hat(e)(X_i)) / (hat(e)(X_i)(1 - hat(e)(X_i))).
$ <eq-transformed-outcome>

#proposition[
  Si $hat(e) = e_0$, entonces $E[Y^star mid X] = tau(X)$.
] <prop-transformed-outcome>

*Supuestos.* La validez de $Y^star$ como proxy requiere que $hat(e)$ sea consistente para el verdadero propensity score $e_0$. Si $hat(e)$ está mal especificado, $E[Y^star mid X] != tau(X)$.

*Garantías.* $Y^star$ permite usar métricas de ML supervisado (RMSE, correlación) sobre $hat(tau)$. La desventaja: $Y^star$ tiene alta varianza, especialmente cuando $hat(e)$ es cercano a 0 o 1. La varianza de $Y^star$ condicional en $X$ es:
$
"Var"(Y^star mid X) = sigma^2(X) + (tau(X)^2) / (e_0(X)(1 - e_0(X))),
$
que explota cuando $e_0(X) -> 0$ o $e_0(X) -> 1$.

=== Placebo tests
<sec-cap07_placebo_tests>

Un _placebo test_ estima el efecto causal en un contexto donde debería ser cero. La lógica es simple: si el estimador produce un efecto no nulo donde sabemos que no debería haberlo, el estimador está sesgado.

*Supuestos.* El placebo test requiere que en el contexto placebo se cumplan los mismos supuestos de identificación que en el contexto real. Si no, un resultado no nulo podría deberse a violación de supuestos en el placebo y no a un problema del estimador.

*Garantías.* Bajo la hipótesis nula de efecto nulo y correcta especificación, el estimador debe producir un efecto indistinguible de cero. Un resultado significativo en un placebo es evidencia de mala especificación.

Tres variantes comunes:

- *Placebo temporal:* estimar el efecto en un periodo pre-tratamiento. Si el estimador es válido, el efecto debe ser cercano a cero.
- *Placebo por subgrupo:* estimar el efecto en un subgrupo que no debería responder al tratamiento (p. ej., efecto de un programa escolar sobre jubilados).
- *Placebo por outcome:* estimar el efecto sobre un outcome que no debería responder (p. ej., efecto de becas sobre altura).

=== Validación con datos sintéticos
<sec-cap07_sinteticos>

Para datasets sintéticos con $tau(x)$ conocido, se reportan:

- *Sesgo:* $E[hat(tau)(X) - tau(X)]$.
- *RMSE:* $sqrt(E[(hat(tau)(X) - tau(X))^2])$.
- *Cobertura del IC:* fracción de $x$ tales que $tau(x) in [hat(tau)(x) plus.minus 1.96 hat(sigma)(x)]$.
- *Policy regret:* diferencia entre $V(pi^*)$ y $V(hat(pi))$ donde $pi^*$ es la política óptima y $hat(pi)$ se deriva de $hat(tau)$.

== Implementación en Python
<sec-cap07_implementacion>

=== Curva Qini sobre datos sintéticos
<sec-cap07_impl_qini>

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
<sec-cap07_impl_placebo>

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
<sec-cap07_caso>

=== Suite de refutación
<sec-cap07_refutation>

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
    [Transformed outcome], [Construye $Y^star$ y evalúa $hat(tau)$ con métricas supervisadas], [$E[Y^star mid X] = tau(X)$ bajo $hat(e)$ correcto; permite RMSE y correlación],
    table.hline(stroke: 0.8pt),
  )
) <tab-refutation-suite>

=== Curva Qini comparativa
<sec-cap07_qini_comparativa>

La figura @fig-cap7-qini compara dos modelos causales (Causal Forest y T-learner con GBM) sobre un dataset sintético con CATE conocido. Un modelo informativo produce una curva Qini creciente y claramente por encima del baseline aleatorio; un modelo no informativo produce una curva plana o ruidosa.

#figure(
  image("../figuras/fig_cap7_qini.png", width: 85%),
  caption: [Curva Qini comparativa: Causal Forest vs. T-learner (GBM) vs. baseline aleatorio. Dataset sintético con CATE conocido $tau(x) = 2 + 3x_1 - x_2^2$, $n = 3\,000$. El Causal Forest domina al T-learner, especialmente en el rango 20–60% de la muestra.],
) <fig-cap7-qini>

*Interpretación.* El Causal Forest (azul) produce una curva Qini más pronunciada que el T-learner (rojo), lo que indica que su ranking por CATE estimado es más informativo. Ambos dominan al baseline aleatorio (gris punteado), confirmando que ambos modelos capturan señal causal real. La diferencia entre modelos es mayor en el rango 20–60% de la muestra, donde el Causal Forest aprovecha mejor la estructura local de heterogeneidad.

El dataset #code[thornton_hiv] (Thornton, 2008) evalúa el efecto de incentivos monetarios sobre la demanda de resultados de test de VIH. Aplicando el mismo protocolo de validación, el modelo produce un ranking cuyas unidades top-20% muestran un uplift sustancialmente mayor que el promedio, validando empíricamente la utilidad del estimador.

#intuicion[
  *Caja de profundización 7.1: Pruebas de refutación y análisis de sensibilidad*

  *Objetivo.* Aprender a poner a prueba un modelo causal cuando no tenemos el efecto verdadero.

  *Pruebas de placebo.*
  - *Placebo treatment:* asignar el tratamiento aleatoriamente y reestimar. El ATE debería ser cero.
  - *Placebo outcome:* usar una variable que sabemos que no es afectada por el tratamiento como si fuera $Y$.
  - *Placebo temporal:* en datos de panel, aplicar el método a un período prepolíticas donde no debería haber efecto.

  *¿Qué tan sensible es mi resultado a un confusor no observado?* Incluso si controlamos por muchos confusores observados, siempre puede haber uno no observado. El *E-value* responde: ¿qué tan fuerte tendría que ser ese confusor para explicar mi resultado? Un E-value grande ($> 2$) sugiere que el resultado es robusto.

  *Bootstrap para curvas Qini.* Podemos remuestrear los datos muchas veces y recalcular la curva Qini cada vez. Esto nos da bandas de confianza alrededor de la curva y permite comparar modelos formalmente.
]

== Riesgos, límites y sensibilidad
<sec-cap07_riesgos>

=== Tabla de riesgos
<sec-cap07_tabla_riesgos>

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
<sec-cap07_limites>

Las métricas indirectas (Qini, uplift, transformed outcome) solo detectan fallos gruesos. No garantizan ausencia de sesgo. La validación definitiva requiere replicación en experimentos controlados o datasets sintéticos con ground truth.

*¿Cuándo no usar este enfoque?* La validación indirecta no reemplaza un diseño de identificación creíble. Si el supuesto de no confusión es cuestionable, ninguna suite de refutación lo rescata. En esos casos, priorizar diseños cuasi-experimentales (RDD, DID, IV) sobre la validación post-hoc.

== Evaluación offline en el ciclo de vida del sistema
<sec-cap07_evaluacion_offline>

Las secciones anteriores de este capítulo responden una pregunta estadística: ¿el estimador de CATE es razonable? Esta sección, que extiende el capítulo con una perspectiva de ingeniería de sistemas siguiendo a @huyen2022dmls (Capítulo 6, "Model Development and Offline Evaluation"), responde una pregunta distinta y complementaria: *¿cómo se organiza el proceso de evaluación offline para que sea comparable a través del tiempo y de distintas versiones del modelo?*

=== _Baselines_ obligatorios

@huyen2022dmls insiste en que ningún modelo se evalúa en el vacío: siempre debe compararse contra al menos un _baseline_ simple. Para un sistema de estimación causal, se recomiendan tres _baselines_ mínimos antes de aceptar cualquier estimador de CATE como el de producción:

#table(
  columns: (1.3fr, 2.7fr),
  align: left,
  stroke: 0.5pt + gray.lighten(60%),
  table.header([*Baseline*], [*Qué revela*]),
  [Efecto constante (ATE vía DML, @cap-dml)], [Si el CATE estimado no supera a un efecto constante en la curva Qini, la heterogeneidad modelada no aporta valor accionable.],
  [Regla aleatoria], [Piso de referencia: cualquier estimador debe superar claramente a targetear al azar.],
  [Regla basada en riesgo (sin causalidad)], [Detecta si el "efecto heterogéneo" estimado es, en realidad, una reformulación de quién tiene mayor $Y$ esperado sin tratamiento — un error de confusión entre pronóstico de riesgo y efecto causal, ya discutido en el @cap-causalidad-elemental.],
)

=== Versionado del proceso de evaluación

Un segundo punto que DMLS enfatiza y que la literatura puramente estadística de validación causal rara vez menciona: el *proceso* de evaluación offline —qué _baselines_, qué partición de datos, qué semilla aleatoria— debe versionarse junto con el modelo, no solo el modelo mismo. Sin esto, comparar "la nueva versión del estimador es mejor que la anterior" es una afirmación no verificable: dos evaluaciones hechas con particiones distintas de los datos no son comparables, sin importar cuán rigurosa sea cada una por separado. El esqueleto de repositorio del @cap-anatomia-sistema incluye la carpeta `tests/` exactamente para fijar este proceso una vez y reutilizarlo.

Esta perspectiva de sistema es la que conecta este capítulo con el siguiente: una vez que el proceso de evaluación offline está versionado y es reproducible, la pregunta natural es cómo llevar el estimador que pasó esa evaluación a un servicio que otros puedan consultar — el tema del Capítulo 15.

== Ejercicios y notas bibliográficas
<sec-cap07_ejercicios>

=== Ejercicios propuestos
<sec-cap07_ejercicios_propuestos>

+ Replique el listado @lst-qini con tres estimadores: causal forest, X-learner, T-learner. ¿Cuál produce la curva Qini más pronunciada?

+ Construya un DGP donde el CATE sea constante ($tau(x) = tau$ para todo $x$). Verifique que la curva Qini es plana.

+ Sobre el dataset #code[cps_mixtape], estime el CATE con causal forest y aplique un placebo temporal si hay datos de años previos disponibles.

+ Implemente el transformed outcome $Y_i^star$ de la ecuación @eq-transformed-outcome y calcule la correlación entre $Y_i^star$ y $hat(tau)$. ¿Es alta? ¿Qué dice esto sobre la calidad del estimador?

=== Lecturas complementarias
<sec-cap07_lecturas>

@gutierrez2017causal introduce el transformed outcome. @athey2019using formaliza la validación causal. @schuler2018comparison compara estrategias de validación. Para Qini, @radcliffe2007using.
