// Capítulo 14 — Control sintético y matrix completion
#import "../template/template.typ": *

#chapter[Control sintético y matrix completion]
<cap-scm-mc>

#theorem-number-reset()

#cuadrosinoptico[
  #table(
    columns: (auto, 1fr),
    align: (left, left),
    stroke: none,
    [*[Problema]*], [Estimar efecto causal en panel con una unidad tratada],
    [*[Estimando]*], ["ATT" por período post-tratamiento $tau_t$],
    [*[Identificación]*], [Combinación convexa (SCM), low-rank + incoherence (MC)],
    [*[Método]*], [Synthetic Control (SCM), Matrix Completion (MC)],
    [*[Nuisance]*], [Pesos $w_j$ (SCM), matriz $L$ (MC)],
    [*[Garantía]*], [Fit pre-tratamiento exacto (SCM), $O_p(sqrt(r(N+T)\/|cal(O)|))$ (MC)],
    [*[Librerías]*], [scipy.optimize, numpy],
    [*[Validación]*], [Placebos espaciales y temporales, gráfico pre-tratamiento],
  )
]

#notatecnica[
Los capítulos anteriores de esta parte estiman efectos a nivel de unidad individual; este cierra la Parte VII con el caso de una sola unidad tratada observada en el tiempo (control sintético), reutilizando el lenguaje de SCM del @cap-scm-pch en su acepción original de la literatura de evaluación de políticas macro, distinta pero complementaria a la de Bareinboim usada en la primera mitad del curso.
]

== Motivación aplicada
<sec-cap14_motivacion>

Una economista del Banco Central debe estimar el efecto de una reforma tributaria implementada en una región específica sobre la recaudación. No hay región de control perfecta: todas las regiones tienen trayectorias distintas. El _synthetic control method_ (SCM) clásico de @abadie2003economic construye un "control sintético" ponderando regiones no tratadas para reproducir la trayectoria pre-tratamiento de la región tratada.

Pero SCM clásico tiene limitaciones: requiere _fit_ pre-tratamiento perfecto, no maneja múltiples unidades tratadas con staggered adoption, y no produce IC fácilmente. @athey2021matrix proponen _matrix completion_ como alternativa: modelar la matriz de outcomes $Y in R^(N times T)$ como una matriz de bajo rango con ruido, donde las entradas post-tratamiento son "missing" y se imputan.

Este capítulo desarrolla ambos métodos, los compara, y aplica al dataset #code[texas] (efecto de una ley de aborto sobre mortalidad materna) y al sintético #code[scm_placebo].

== Teoría, supuestos y garantías
<sec-cap14_teoria>

=== SCM clásico
<sec-cap14_scm>

Para una unidad tratada $i = 1$ y controles $i = 2, dots, N+1$ observadas en $t = 1, dots, T$ con tratamiento en $t = T_0+1, dots, T$ para la unidad 1, SCM busca pesos $bold(w) = (w_2, dots, w_(N+1))$ con $w_j >= 0$ y $sum_j w_j = 1$ que minimicen:
$
sum_(t=1)^(T_0) (Y_(1 t) - sum_(j=2)^(N+1) w_j Y_(j t))^2.
$

El estimador del efecto es $hat(tau)_t = Y_(1 t) - sum_j hat(w)_j Y_(j t)$ para $t > T_0$.

=== Matrix completion
<sec-cap14_matrix_completion>

@athey2021matrix reinterpretan el problema como imputación de matriz. Sea $Y in R^(N times T)$ la matriz de outcomes, donde las entradas post-tratamiento para unidades tratadas son conceptualmente "missing" (porque no observamos el counterfactual). El modelo es:
$
Y = L + epsilon,
$
donde $L$ es una matriz de bajo rango ($"rank"(L) <= r << min(N, T)$) y $epsilon$ es ruido. Se estima $hat(L)$ minimizando:
$
hat(L) = "argmin"_(L: "rank"(L) <= r) sum_((i, t) in cal(O)) (Y_(i t) - L_(i t))^2,
$ <eq-matrix-completion>
donde $cal(O)$ es el conjunto de entradas observadas (pre-tratamiento + unidades no tratadas).

La solución convexa relajada (nuclear norm):
$
hat(L) = "argmin"_L { sum_((i,t) in cal(O)) (Y_(i t) - L_(i t))^2 + lambda norm(L)_* },
$
donde $norm(L)_*$ es la norma nuclear (suma de valores singulares).

#theorem(
  name: [Athey et al., 2021]
)[
  Bajo condiciones regulares (low-rank, incoherence), $hat(L)$ estima $L$ con error $O_p(sqrt(r(N+T)\/|cal(O)|))$.
] <thm-matrix-completion>

=== Comparación SCM vs. matrix completion
<sec-cap14_comparacion>

#figure(
  caption: [SCM clásico vs. matrix completion],
  table(
    columns: (1.2fr, 1fr, 1fr),
    align: (left, left, left),
    stroke: none,
    table.hline(stroke: 0.8pt),
    table.header([Dimensión], [SCM clásico], [Matrix completion]),
    table.hline(stroke: 0.4pt),
    [Múltiples tratadas], [Difícil], [Natural],
    [Staggered adoption], [Difícil], [Natural],
    [Fit pre-tratamiento], [Exigido], [Flexible],
    [IC], [Placebos], [Bootstrap],
    [Supuesto estructural], [Convex combination], [Low-rank],
    table.hline(stroke: 0.8pt),
  )
) <tab-scm-vs-mc>

== Algoritmo e implementación
<sec-cap14_algoritmo>

=== Algoritmo: Synthetic control clásico
<sec-cap14_algoritmo_scm>

El algoritmo siguiente formaliza el procedimiento de estimación por control sintético para una unidad tratada y un panel de donantes.

#algorithm("Synthetic control clásico")[
  #kwin[Entrada][Outcome pre-tratamiento de la unidad tratada $bold(Y)_(1, "pre") in R^(T_0)$; matriz de donantes pre-tratamiento $bold(Y)_(0, "pre") in R^(T_0 times N)$; matriz de donantes post-tratamiento $bold(Y)_(0, "post") in R^((T-T_0) times N)$; outcome observado post-tratamiento de la unidad tratada $bold(Y)_(1, "post") in R^(T-T_0)$.]
  #kwout[Salida][Pesos $hat(bold(w)) in R^N$; contrafactual sintético $hat(bold(Y))_(1, "post") in R^(T-T_0)$; efecto estimado $hat(bold(tau)) in R^(T-T_0)$.]
  Resolver el problema de optimización restringida: \
  #h(1.5em) $hat(bold(w)) = "argmin"_bold(w) norm(bold(Y)_(1, "pre") - bold(Y)_(0, "pre") bold(w))^2$ \
  sujeto a $w_j >= 0$ para todo $j$ y $sum_(j=1)^N w_j = 1$ \
  Calcular el contrafactual sintético en el período post-tratamiento: \
  #h(1.5em) $hat(bold(Y))_(1, "post") = bold(Y)_(0, "post") hat(bold(w))$ \
  Estimar el efecto causal para cada período post-tratamiento: \
  #h(1.5em) $hat(tau)_t = Y_(1 t) - hat(Y)_(1, "post", t), quad t = T_0+1, dots, T$ \
  #return-stmt[$hat(bold(w)), hat(bold(Y))_(1, "post"), hat(bold(tau))$]
] <alg-scm_clasico>

=== SCM clásico sobre Texas
<sec-cap14_scm_texas>

#figure(
  kind: raw,
  caption: [SCM clásico sobre dataset Texas.],
  ```python
import pandas as pd
import numpy as np
from scipy.optimize import minimize

df = pd.read_csv("../data/datasets/real/public_causaldata/texas/data.csv")
print(df.columns.tolist()[:15])
# Identificar columnas: unidad, tiempo, tratamiento, outcome
# Texas tiene una columna "treat" indicando adopcion de ley
# Para SCM clasico: usar otras unidades como donantes

# Implementacion simplificada de SCM
def synthetic_control(Y_treated_pre, Y_donors_pre, Y_donors_post):
    """Encuentra pesos w que minimizan ||Y_treated_pre - Y_donors_pre @ w||^2."""
    N = Y_donors_pre.shape[1]
    # Restricciones: w >= 0, sum(w) = 1
    constraints = [{"type": "eq", "fun": lambda w: np.sum(w) - 1}]
    bounds = [(0, 1)] * N
    w0 = np.ones(N) / N
    obj = lambda w: np.sum((Y_treated_pre - Y_donors_pre @ w)**2)
    res = minimize(obj, w0, method="SLSQP", bounds=bounds, constraints=constraints)
    w = res.x
    Y_synth_post = Y_donors_post @ w
    return w, Y_synth_post

# Aplicar (formato depende del dataset exacto)
# Aqui se muestra el esqueleto; adaptar columnas segun dataset real
```
) <lst-scm-texas>

=== Matrix completion
<sec-cap14_mc_implementacion>

#figure(
  kind: raw,
  caption: [Matrix completion con nuclear norm.],
  ```python
import numpy as np
from scipy.linalg import svd

def matrix_completion(Y, mask, lam=1.0, n_iter=100, tol=1e-4):
    """Imputa entradas faltantes de Y usando nuclear-norm regularization.
    mask[i,j] = 1 si (i,j) observado, 0 si faltante.
    """
    Y_obs = Y * mask
    M = Y_obs.copy()
    for it in range(n_iter):
        # SVD soft-thresholding
        U, s, Vt = svd(M, full_matrices=False)
        s_thresh = np.maximum(s - lam, 0)
        M_new = (U * s_thresh) @ Vt
        # Mantener entradas observadas
        M_new = Y_obs * mask + M_new * (1 - mask)
        if np.linalg.norm(M_new - M) < tol:
            break
        M = M_new
    return M

# Ejemplo sintetico
rng = np.random.default_rng(42)
N, T, r = 30, 20, 3
L_true = rng.standard_normal((N, r)) @ rng.standard_normal((r, T))
Y = L_true + 0.5 * rng.standard_normal((N, T))
# Enmascarar post-tratamiento de unidades tratadas
mask = np.ones((N, T))
treated_units = [0, 5, 10]
T0 = 10
for i in treated_units:
    mask[i, T0:] = 0

L_hat = matrix_completion(Y, mask, lam=2.0)
# Efecto estimado para unidades tratadas
effect = (Y - L_hat)[treated_units, T0:].mean()
print(f"Efecto estimado (matrix completion): {effect:.4f}")
```
) <lst-matrix-completion>

== Caso empírico y validación
<sec-cap14_caso_empirico>

La figura @fig-cap14-scm-mc ilustra el ajuste pre/post-tratamiento con SCM clásico y matrix completion, sobre un panel sintético con efecto verdadero conocido ($tau = 2.5$). El panel izquierdo muestra que ambos métodos reproducen razonablemente la trayectoria pre-tratamiento de la unidad tratada; el panel derecho muestra el efecto estimado en el periodo post-tratamiento, comparado con un placebo espacial (aplicar SCM a una unidad no tratada).

#figure(
  image("../figuras/fig_cap14_scm_mc.png", width: 100%),
  caption: [Izquierda: trayectoria de la unidad tratada vs. control sintético (SCM) y matrix completion (MC), con periodo pre-tratamiento $T_0 = 15$. Derecha: efecto estimado post-tratamiento para la unidad tratada (efecto verdadero = 2.5) y para un placebo espacial (unidad no tratada, debe ser $approx 0$). Panel sintético $N = 20$, $T = 30$.],
) <fig-cap14-scm-mc>

*Interpretación.* El SCM clásico y el matrix completion producen estimaciones consistentes del efecto post-tratamiento (cerca del valor verdadero 2.5). El placebo espacial—aplicar el mismo procedimiento a una unidad no tratada— produce un efecto cercano a cero, validando la especificación. @abadie2010synthetic aplicaron SCM al efecto de la ley de tabaco de California (Proposición 99) sobre el consumo de cigarrillos; la cifra original de reducción post-tratamiento no se reproduce aquí para evitar imprecisiones, pero el orden de magnitud (varios paquetes per cápita) es consistente con la literatura.

== Riesgos, límites y mitigación
<sec-cap14_riesgos>

#riesgos[
  #figure(
    caption: [Riesgos en SCM y matrix completion],
    table(
      columns: (1fr, 1fr, 1fr, 1fr),
      align: (left, left, left, left),
      stroke: none,
      table.hline(stroke: 0.8pt),
      table.header([*Riesgo*], [*Consecuencia*], [*Diagnóstico*], [*Mitigación*]),
      table.hline(stroke: 0.4pt),
      [Mal pre-trend], [SCM inválido], [Gráfico pre-tratamiento], [Descartar SCM],
      [Pocos donantes], [Control débil], [Pesos], [Más unidades],
      [Low-rank falso], [MC sesgado], [Validación], [Placebos],
      table.hline(stroke: 0.8pt),
    )
  ) <tab-riesgos-cap14>
]

#intuicion[
*Caja de profundización 14.1: Synthetic Difference-in-Differences y placebos*

*Objetivo.* Extender el control sintético combinándolo con DiD, y aprender a hacer inferencia con placebos.

*Synthetic DiD.* Combina lo mejor del control sintético (pesos por unidad) con DiD (pesos por tiempo):
- Busca pesos por unidad que balanceen covariables pre-tratamiento.
- Busca pesos por tiempo que balanceen el período post-tratamiento.
- El efecto se estima como: $("post"_("tratado") - "pre"_("tratado")) - ("post"_("sintético") - "pre"_("sintético"))$
- Es más robusto que SCM cuando las tendencias paralelas no son perfectas.

*Placebo inference.* Para saber si el efecto estimado es significativo:
- *Placebo in-space:* re-asignar el tratamiento a otra unidad y recalcular. Repetir para cada unidad no tratada.
- *Placebo in-time:* aplicar el método a un período anterior al tratamiento (donde no debería haber efecto).
- La distribución de placebos nos da un p-valor empírico.
]

== Ejercicios propuestos
<sec-cap14_ejercicios>

+ Replique el listado @lst-scm-texas sobre el dataset #code[texas] completo. Reporte el efecto post-tratamiento.

+ Sobre #code[scm_placebo] (sintético con ground truth), compare SCM clásico con matrix completion en términos de RMSE.

+ Modifique el listado @lst-matrix-completion para incluir efectos fijos de unidad y de tiempo. ¿Mejora la imputación?

+ Aplique matrix completion al dataset #code[abortion] (efecto de legalización del aborto sobre fertilidad).

== Lecturas complementarias
<sec-cap14_lecturas>

@abadie2003economic y @abadie2010synthetic son las referencias de SCM clásico. @athey2021matrix introduce matrix completion. @arkhangelsky2021synthetic propone Synthetic DiD como híbrido.
