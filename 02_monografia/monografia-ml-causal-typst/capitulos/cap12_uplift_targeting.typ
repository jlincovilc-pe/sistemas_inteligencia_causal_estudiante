// Capítulo 22 — Uplift modeling y targeting económico
// (La numeración `cap12` del nombre de archivo es histórica: proviene de la edición corta anterior y se conserva para no romper referencias.)
#import "../template/template.typ": *

#chapter[Uplift modeling y targeting económico]
<cap-uplift-targeting>

#theorem-number-reset()

#cuadrosinoptico[
  #table(
    columns: (auto, 1fr),
    align: (left, left),
    stroke: none,
    [*Problema:*], [Asignación óptima de tratamientos con costos diferenciales y presupuesto],
    [*Estimando:*], [CATE por tratamiento $tau_k(x)$, policy value $V(pi)$],
    [*Identificación:*], [No confusión condicional + soporte común],
    [*Método:*], [Uplift modeling, net score, Qini optimization],
    [*Nuisance:*], [$hat(mu)_k(x)$, $hat(e)_k(x)$, costos $c_k$],
    [*Garantía:*], [Convergencia de $hat(tau)_k$ a $tau_k$ bajo cross-fitting],
    [*Librerías:*], [causalml, econml],
    [*Validación:*], [Curva Qini, AUUC, análisis de costo-efectividad],
  )
]

#notatecnica[
El @cap-policy-learning formalizó la política óptima como problema de decisión restringido; este capítulo cierra la Parte V con la práctica de *targeting* de marketing y programas sociales, y con las mismas curvas Qini ya usadas para validación en el @cap-validacion, ahora como criterio de evaluación de la política y no solo del estimador.
]

== Motivación aplicada
<sec-cap12_motivacion>

Una empresa de telecomunicaciones desea reducir la _churn_ (baja de clientes). Dispone de tres acciones: (a) no hacer nada, (b) enviar un SMS con descuento, (c) llamar por teléfono con oferta personalizada. El costo de cada acción es distinto: SMS cuesta \$0.5, llamada cuesta \$8. El efecto sobre retención varía por cliente. La pregunta de política: ¿a qué clientes aplicar cada acción, sujeto a un presupuesto total de \$100\,000?

El _uplift modeling_ es el análogo del policy learning en contextos de marketing. La métrica clave es el _uplift_: la diferencia en la probabilidad de conversión (o retención) entre recibir y no recibir el tratamiento. Los métodos se han desarrollado en la industria [@radcliffe2007using; @gutierrez2017causal] y se han integrado con la literatura académica de ML causal [@athey2021policy].

Este capítulo presenta los métodos clásicos de uplift (two-model, transformed outcome, Qini optimization), su implementación con #code[causalml], y la extensión a múltiples tratamientos y restricciones presupuestarias.

== Marco teórico formal
<sec-cap12_marco_teorico>

=== Uplift y CATE
<sec-cap12_uplift_cate>

El _uplift_ es matemáticamente equivalente al CATE:
$
"uplift"(x) = E[Y(1) - Y(0) | X = x] = tau(x).
$ <eq-uplift_cate>

La diferencia con el capítulo @cap-meta-learners es el foco aplicado: uplift modeling se pregunta por el _ranking_ (qué clientes tienen mayor uplift) y por la _cost-effectiveness_ (cuánto uplift se obtiene por dólar invertido), no solo por la estimación puntual del CATE.

Esa diferencia de foco tiene una consecuencia práctica que conviene fijar desde el principio, porque determina qué se puede y qué no se puede hacer con un modelo de uplift. Si la decisión es *a quién tratar con un presupuesto fijo*, basta con que el ranking sea correcto: la escala de $hat(tau)$ es irrelevante, y las métricas de ranking (Qini, AUUC) son el criterio adecuado. Si la decisión es *cuánto presupuesto asignar*, o *qué acción elegir entre varias con costos distintos*, el ranking no basta: hace falta que la *magnitud* de $hat(tau)$ esté bien calibrada, porque el punto de corte óptimo compara $tau_k(x)$ contra un costo $c_k$ medido en las mismas unidades. Un modelo puede tener un AUUC excelente y estar tan mal calibrado que la regla de asignación por _net score_ de la @sec-cap12_algoritmo gaste el doble de lo proyectado. Por eso este capítulo reporta siempre las dos cosas —ranking y calibración— y por eso el _transformed outcome_ del @cap-validacion, que sí da magnitudes insesgadas, reaparece aquí como diagnóstico obligatorio.

=== Qini y AUUC: teoría, supuestos y garantías
<sec-cap12_qini_auuc>

La curva Qini y el AUUC (_Area Under Uplift Curve_) son las métricas estándar para evaluar modelos de uplift en ausencia de _ground truth_ individual.

*Definición.* Sea $cal(D)$ una muestra con $n$ unidades, cada una con tratamiento $D_i in {0, 1}$ y outcome observado $Y_i$. Ordenamos las unidades por $hat(tau)(x_i)$ descendente. Para cada punto de corte $p in [0, 1]$, el uplift acumulado se define como:
$
"uplift"(p) = (1 / n) sum_(i=1)^(floor(n p))
  (Y_i D_i / hat(e)(x_i) - (Y_i (1 - D_i)) / (1 - hat(e)(x_i))),
$ <eq-qini>
donde $hat(e)(x)$ es la propensión estimada. El AUUC integra esta curva sobre $p in [0, 1]$ y normaliza respecto a una asignación aleatoria:
$
"AUUC" = integral_0^1 ("uplift"(p) - "uplift"_"aleatorio"(p)) dif p.
$ <eq-auuc>

*Supuestos.* La validez de la curva Qini y el AUUC requiere:
- *Inconfundibilidad (unconfoundedness):* $Y(1), Y(0) perp perp D | X$.
- *Soporte común (overlap):* $0 < e(x) < 1$ para todo $x$.
- *Propensity score correcto:* $hat(e)(x)$ es una estimación consistente de $e(x) = P(D = 1 | X = x)$.

Bajo estos supuestos, la curva Qini ordena correctamente las unidades por su CATE esperado y permite comparar modelos de forma válida.

*Garantías.* #cite(<radcliffe2007using>, form: "prose") demuestra que la pendiente de la curva Qini en el origen es proporcional al CATE promedio en la cola superior de la ordenación. #cite(<gutierrez2017causal>, form: "prose") establece que el AUUC es equivalente al coeficiente de Gini del uplift bajo normalización. En la práctica, la curva Qini permite comparar modelos de uplift: curvas más arriba indican mejor capacidad de ranking. Cuando se utilizan intervalos de confianza por bootstrap, es posible evaluar si las diferencias entre modelos son estadísticamente significativas.

*Cost-weighted uplift.* Cuando los costos del tratamiento varían entre individuos, se pondera el uplift por el costo unitario:
$
"CW-uplift"(x) = (hat(tau)(x)) / (c(x)),
$ <eq-cw-uplift>
donde $c(x)$ es el costo del tratamiento para el cliente $x$. Esta métrica permite priorizar acciones con mayor retorno por dólar invertido.

=== Multi-treatment uplift
<sec-cap12_multitreatment>

Cuando hay $K$ tratamientos posibles, el problema se extiende a estimar $tau_k(x) = E[Y(k) - Y(0) | X = x]$ para $k = 1, ..., K$. La política óptima asigna a cada cliente el tratamiento con mayor $tau_k(x) - c_k(x)$, donde $c_k$ es el costo del tratamiento $k$.

#intuicion[
  *Caja de profundización 12.1: Bootstrap para la curva Qini y embeddings como covariables*

  *Bootstrap para la curva Qini.* Una forma de comparar modelos de uplift con incertidumbre:
  + Remuestrear los datos 200 veces.
  + Cada vez, recalcular la curva Qini y el AUUC.
  + Reportar el AUUC promedio con intervalo de confianza.

  Esto evita confiar en un solo número que puede ser ruidoso.

  *Embeddings como covariables.* Si tenemos texto, imágenes o datos no estructurados, podemos usar embeddings (representaciones numéricas) como covariables $X$ para estimar CATE. Pero cuidado: un embedding puede ser proxy de variables sensibles como género o raza.
]

== Algoritmo: Asignación por net score con presupuesto
<sec-cap12_algoritmo>

Resolver la asignación óptima de tratamientos con costos distintos y un presupuesto limitado requiere un enfoque de optimización. El método de _net score_ introduce un costo sombra $lambda$ que equilibra el beneficio marginal del tratamiento con su costo.

El problema formal: tenemos $K$ tratamientos con costos $c_k$ y un presupuesto $B$. Queremos asignar a cada persona el tratamiento que maximice el uplift neto—beneficio menos costo— sin exceder $B$.

#algorithm("Asignación por net score con presupuesto")[
  #kwin[Entrada][$hat(tau)_k(x)$ para cada tratamiento $k = 1, dots, K$, costos $c_k$, presupuesto $B$, datos $cal(D)$ con $N$ observaciones]
  #kwout[Salida][Asignación $pi(x) in {0, 1, dots, K}$ que maximiza el uplift total sujeto a $sum_(i=1)^N c_(pi(x_i)) <= B$]
  Inicializar $lambda <- 0$ y $lambda_"max" <- max_k c_k^(-1) B$ \
  *repeat* #h(2pt) hasta $|G - B| < epsilon$ o $lambda_"max" - lambda_"min" < delta$: \
  #h(1.5em) $lambda <- (lambda + lambda_"max") / 2$ \
  #h(1.5em) Calcular net score $s_k(x) = hat(tau)_k(x) - lambda dot.c c_k(x)$ para cada $x$ y $k$ \
  #h(1.5em) Asignar $pi(x) = "argmax"_k s_k(x)$ \
  #h(1.5em) Calcular gasto total $G = sum_(i=1)^N c_(pi(x_i))$ \
  #h(1.5em) *if* #h(2pt) $G > B$ *then* #h(2pt) $lambda_"min" <- lambda$ \
  #h(1.5em) *else if* #h(2pt) $G < B$ *then* #h(2pt) $lambda_"max" <- lambda$ \
  #return-stmt[$pi(x)$ para cada $x$.]
] <alg-net-score>

El parámetro $lambda$ es el multiplicador de Lagrange (costo sombra) de la restricción presupuestaria. Cuando $lambda = 0$, el algoritmo asigna según el uplift bruto; al aumentar $lambda$, se penalizan los tratamientos costosos, favoreciendo acciones más baratas. La búsqueda por bisección garantiza convergencia al valor de $lambda$ que satura la restricción.

La solución de net score es equivalente a resolver:
$
pi^*(x) = "argmax"_k { tau_k(x) - lambda^* c_k(x) },
$ <eq-net-score-opt>
donde $lambda^*$ es el costo sombra que agota el presupuesto $B$. Nótese que $lambda^*$ no es una penalización de regularización (como en LASSO), sino el precio implícito de relajar la restricción presupuestaria en una unidad.

== Aplicación con Python
<sec-cap12_python>

=== Uplift modeling con causalml
<sec-cap12_causalml>

La biblioteca #code[causalml] @chen2020causalml proporciona implementaciones de meta-learners (S-, T-, X-, R- y DR-learner) y herramientas de validación como la curva Qini y el AUUC. El siguiente listado muestra un flujo completo de estimación y evaluación *con los dos tratamientos del caso* —SMS y llamada—, porque el análisis de costo-efectividad de la sección siguiente requiere una estimación de uplift *por acción*, no una sola.

Este es el punto donde más se equivoca la práctica aplicada, y conviene decirlo explícitamente: no existe forma de derivar $tau_"llamada"(x)$ a partir de $tau_"SMS"(x)$ escalándolo por un factor. Cada acción tiene su propio efecto heterogéneo, con su propio patrón de heterogeneidad, y estimarlo requiere que los datos contengan variación en esa acción. Si el histórico solo tiene SMS, no hay uplift de llamada que estimar, por más columnas que se creen.

#figure(
  kind: raw,
  caption: [Uplift modeling multi-tratamiento con `causalml`: un estimador por acción.],
  ```python
import numpy as np
import pandas as pd
from xgboost import XGBRegressor
from causalml.inference.meta import BaseTRegressor
from causalml.metrics import plot_qini, qini_score

FEATURES = [f"x{i}" for i in range(8)]

def make_churn_data(n=5000, seed=42):
    """DGP sintetico de churn con TRES brazos: control, SMS, llamada.

    Los dos tratamientos tienen patrones de heterogeneidad distintos --
    ese es justamente el punto: no se derivan uno del otro.
    """
    rng = np.random.default_rng(seed)
    X = rng.uniform(-1, 1, (n, 8))
    # Asignacion a tres brazos (aleatoria: es una campana experimental)
    arm = rng.choice(["control", "sms", "call"], size=n, p=[0.4, 0.3, 0.3])
    tau_sms = 0.06 - 0.05 * X[:, 0] + 0.03 * X[:, 1]   # uplift del SMS
    tau_call = 0.12 + 0.09 * X[:, 1] - 0.02 * X[:, 3]  # uplift de la llamada
    base = 0.45 + 0.08 * X[:, 2]                        # retencion basal
    p = base + (arm == "sms") * tau_sms + (arm == "call") * tau_call
    Y = (rng.uniform(size=n) < np.clip(p, 0, 1)).astype(int)
    df = pd.DataFrame(X, columns=FEATURES)
    df["y"], df["arm"] = Y, arm
    df["tau_sms_true"], df["tau_call_true"] = tau_sms, tau_call  # solo eval.
    return df

df = make_churn_data(5000)

def uplift_por_accion(df, accion, features=FEATURES):
    """Estima tau_accion(x) contra el brazo de control.

    Se restringe la muestra a {control, accion}: comparar dos brazos
    activos entre si estimaria una diferencia de efectos, no un uplift.
    """
    sub = df[df["arm"].isin(["control", accion])]
    learner = BaseTRegressor(learner=XGBRegressor(max_depth=3, n_estimators=200))
    learner.fit(X=sub[features].values,
                treatment=(sub["arm"] == accion).astype(int).values,
                y=sub["y"].values)
    return learner.predict(df[features].values).ravel()  # sobre TODA la muestra

# Un estimador por accion -> dos columnas de uplift, ambas estimadas
df["uplift_sms"] = uplift_por_accion(df, "sms")
df["uplift_call"] = uplift_por_accion(df, "call")

# Evaluacion de ranking, por accion, sobre su propia submuestra
for accion in ["sms", "call"]:
    sub = df[df["arm"].isin(["control", accion])].copy()
    sub["treatment"] = (sub["arm"] == accion).astype(int)
    col = f"uplift_{accion}"
    print(f"{accion:>5}: Qini = {qini_score(sub[['y', 'treatment', col]])}")

sub_sms = df[df["arm"].isin(["control", "sms"])].copy()
sub_sms["treatment"] = (sub_sms["arm"] == "sms").astype(int)
plot_qini(sub_sms[["y", "treatment", "uplift_sms"]], uplift_col="uplift_sms",
          treatment_col="treatment", outcome_col="y")
```
) <lst-uplift>

Nótese que cada uplift se *estima* contra el brazo de control sobre su propia submuestra, y solo después se *predice* sobre toda la población. Comparar directamente el brazo de SMS contra el de llamada estimaría $tau_"call" - tau_"SMS"$, una diferencia de efectos que responde una pregunta distinta ("¿cuánto mejor es llamar que enviar un SMS?") y que no sirve para el problema de asignación, donde la alternativa relevante de cada acción es *no hacer nada*.

=== Caso empírico y validación: costo-efectividad
<sec-cap12_costo_efectividad>

El análisis de costo-efectividad extiende la evaluación más allá del ranking: incorpora costos reales de las acciones y restricciones presupuestarias para derivar políticas concretas. El listado @lst-cost-effectiveness implementa la comparación de tres estrategias de targeting (SMS, llamada y mixta) utilizando el algoritmo de net score.

#box(fill: light.lighten(50%), width: 100%, inset: 8pt, radius: 2pt)[
  *Nota:* El siguiente ejemplo es *ilustrativo con datos simulados*. En un caso real, `uplift_sms` y `uplift_call` se estiman mediante X-learner o otro metalearner (ver Cap. 12) entrenado en datos históricos con tratamientos observados.
]

#figure(
  kind: raw,
  caption: [Análisis costo-efectividad: tres estrategias sobre las columnas de uplift estimadas en el listado @lst-uplift.],
  ```python
# Costos unitarios y presupuesto de la campana
COSTOS = {"nada": 0.0, "sms": 0.5, "call": 8.0}
BUDGET = 100_000

def uplift_total(df, asignacion):
    """Uplift esperado y gasto de una asignacion accion-por-cliente."""
    u = np.where(asignacion == "sms", df["uplift_sms"],
        np.where(asignacion == "call", df["uplift_call"], 0.0))
    gasto = np.array([COSTOS[a] for a in asignacion]).sum()
    return u.sum(), gasto

n = len(df)

# --- Estrategia A: solo SMS, a los de mayor uplift_sms ---
n_sms = min(int(BUDGET / COSTOS["sms"]), n)
orden_sms = df["uplift_sms"].to_numpy().argsort()[::-1]
asig_a = np.full(n, "nada", dtype=object)
asig_a[orden_sms[:n_sms]] = "sms"

# --- Estrategia B: solo llamadas, a los de mayor uplift_call ---
n_call = min(int(BUDGET / COSTOS["call"]), n)
orden_call = df["uplift_call"].to_numpy().argsort()[::-1]
asig_b = np.full(n, "nada", dtype=object)
asig_b[orden_call[:n_call]] = "call"

# --- Estrategia C: net score con costo sombra (Algoritmo de la seccion
#     anterior). Bisecta lambda hasta agotar el presupuesto. ---
def asignar_net_score(df, budget, lo=0.0, hi=1.0, tol=1e-4, max_iter=60):
    for _ in range(max_iter):
        lam = (lo + hi) / 2
        scores = np.column_stack([
            np.zeros(len(df)),                                  # no hacer nada
            df["uplift_sms"] - lam * COSTOS["sms"],
            df["uplift_call"] - lam * COSTOS["call"],
        ])
        idx = scores.argmax(axis=1)
        asig = np.array(["nada", "sms", "call"], dtype=object)[idx]
        gasto = np.array([COSTOS[a] for a in asig]).sum()
        if abs(gasto - budget) < tol * budget:
            break
        lo, hi = (lam, hi) if gasto > budget else (lo, lam)
    return asig

asig_c = asignar_net_score(df, BUDGET)

for nombre, asig in [("A (solo SMS)", asig_a), ("B (solo llamadas)", asig_b),
                     ("C (net score, mixto)", asig_c)]:
    u, gasto = uplift_total(df, asig)
    print(f"Estrategia {nombre:22s} uplift={u:8.1f}  gasto={gasto:10.1f}")
```
) <lst-cost-effectiveness>

La estrategia C domina a las otras dos por una razón que el multiplicador $lambda^*$ hace transparente: al comparar $tau_k(x) - lambda^* c_k(x)$ entre acciones, la regla asigna la llamada cara solo donde su uplift adicional sobre el SMS justifica los \$7.5 de diferencia, y el SMS barato en el resto. Las estrategias A y B fijan la acción de antemano y solo optimizan a quién alcanzar; C optimiza conjuntamente ambas decisiones, que es el problema real.

La figura @fig-cap12-uplift ilustra dos elementos clave del uplift modeling aplicado. El panel izquierdo muestra la curva de uplift acumulado: al ordenar la muestra por $hat(tau)$ descendente, el uplift acumulado crece rápidamente al inicio y se estabiliza, indicando que las unidades top concentran la mayor parte del uplift total. El panel derecho muestra el análisis de costo-efectividad: dada una mezcla presupuestaria entre dos acciones (SMS barato vs. llamada cara), existe una asignación óptima que maximiza el uplift total.

#figure(
  image("../figuras/fig_cap12_uplift.png", width: 100%),
  caption: [Izquierda: curva de uplift acumulado ordenando la muestra por CATE estimado (Causal Forest). Derecha: análisis de costo-efectividad de la mezcla entre SMS (\$0.5/unidad) y llamada (\$8/unidad) bajo un presupuesto total de \$100\,000. Dataset sintético tipo churn, $n = 5\,000$.],
) <fig-cap12-uplift>

*Interpretación.* La curva de uplift acumulado (panel izquierdo) muestra que el top 20% de la muestra por CATE estimado captura aproximadamente el 60% del uplift total, lo que justifica el targeting. El análisis de costo-efectividad (panel derecho) identifica la mezcla óptima: con un presupuesto fijo, conviene asignar la mayoría del presupuesto a SMS (más barato, mayor cobertura) y reservar llamadas para los casos de mayor uplift.

== Riesgos, límites y mitigación
<sec-cap12_riesgos>

El uso de uplift modeling para targeting con múltiples tratamientos y restricciones presupuestarias presenta riesgos metodológicos que deben diagnosticarse y mitigarse.

#riesgos[
  #figure(
    caption: [Riesgos comunes en uplift modeling y targeting],
    table(
      columns: (1.5fr, 1.5fr, 1.5fr, 1.8fr),
      align: (left, left, left, left),
      stroke: none,
      table.hline(stroke: 0.8pt),
      table.header([*Riesgo*], [*Consecuencia*], [*Diagnóstico*], [*Mitigación*]),
      table.hline(stroke: 0.4pt),
      [Multiplicar uplift ad hoc para inferir el efecto de otro tratamiento], [Comparación inválida entre acciones y política subóptima], [Verificar que cada tratamiento tiene su propia columna de $hat(tau)_k$ en los datos], [Estimar $tau_k(x)$ por separado para cada acción $k$ usando meta-learners],
      [Optimizar solo el ranking (AUUC) sin validar la magnitud del uplift], [Mala calibración; el gasto real no coincide con el proyectado], [Comparar _calibration_ del CATE: $E[Y | D = 1, X] - E[Y | D = 0, X]$ vs.\ $hat(tau)$], [Usar _transformed outcome_ para obtener estimaciones de magnitud insesgadas],
      [Medir costos de forma incorrecta o ignorar costos hundidos], [Política de asignación errónea; se gastan recursos en acciones con retorno negativo], [Análisis de sensibilidad variando $c_k$ en $plus.minus 20%$ y observando cambios en la política óptima], [Utilizar costos reales (contables u operativos) y modelar incertidumbre con bootstrap],
      table.hline(stroke: 0.8pt),
    )
  ) <tab-riesgos-cap12>
]

Además de los riesgos anteriores, es importante considerar la equidad: una estrategia que maximiza el uplift puede excluir sistemáticamente a grupos vulnerables. Se recomienda reportar la distribución demográfica de los tratados y evaluar si existen disparidades injustificadas en la asignación.

== Ejercicios propuestos
<sec-cap12_ejercicios>

+ Replique el listado @lst-uplift sobre #code[thornton_hiv] (un solo tratamiento). ¿Cuál es el Qini score?

+ Sobre el DGP del listado @lst-uplift, compare el uplift promedio de cada acción ($overline(tau)_"SMS")$ frente a $overline(tau)_"llamada"$) con el ranking que produce cada una. Verifique que la acción con mayor efecto promedio *no* es necesariamente la que conviene asignar a cada cliente, y explique por qué en términos del net score.

+ Verifique la calibración de ambos estimadores de uplift contra los valores verdaderos (#code[tau_sms_true], #code[tau_call_true] del DGP). Luego multiplique artificialmente #code[uplift_call] por 3 y vuelva a correr el listado @lst-cost-effectiveness. ¿Cambia el Qini de esa acción? ¿Cambia la asignación óptima y el gasto? Relacione el resultado con la distinción entre ranking y calibración de la @sec-cap12_uplift_cate.

+ Modifique el listado @lst-cost-effectiveness para imponer la restricción de tratar al menos al 20% de cada grupo demográfico. ¿Cómo cambia el uplift total?

+ Discuta: ¿en qué casos el uplift modeling es preferible al policy learning formal?

== Lecturas complementarias
<sec-cap12_lecturas>

#cite(<radcliffe2007using>, form: "prose") introduce la curva Qini en el contexto de marketing directo, que es donde nace toda esta literatura. #cite(<rzepakowski2012decision>, form: "prose") desarrollan los árboles de uplift con criterios de división específicos (basados en divergencias entre las distribuciones de respuesta de tratados y controles) y son la referencia canónica del caso multi-tratamiento tratado en la @sec-cap12_multitreatment. #cite(<gutierrez2017causal>, form: "prose") revisan la literatura y conectan el vocabulario de uplift de la industria con el de inferencia causal académica —lectura recomendada para quien llegue desde cualquiera de los dos lados—. #cite(<chen2020causalml>, form: "prose") documentan #code[causalml], la librería de Uber usada en este capítulo. Para policy learning con restricciones presupuestarias tratado formalmente, @athey2021policy y el @cap-policy-learning.
