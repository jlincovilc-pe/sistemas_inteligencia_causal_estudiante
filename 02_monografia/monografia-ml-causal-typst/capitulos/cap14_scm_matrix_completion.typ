// Capítulo 28 — Control sintético y matrix completion
// (La numeración `cap14` del nombre de archivo es histórica: proviene de la edición corta anterior y se conserva para no romper referencias.)
#import "../template/template.typ": *

#chapter[Control sintético y matrix completion]
<cap-scm-mc>

#theorem-number-reset()

#cuadrosinoptico[
  #table(
    columns: (auto, 1fr),
    align: (left, left),
    stroke: none,
    [*Problema:*], [Estimar efecto causal en panel con una unidad tratada],
    [*Estimando:*], ["ATT" por período post-tratamiento $tau_t$],
    [*Identificación:*], [Combinación convexa (SCM), low-rank + incoherence (MC)],
    [*Método:*], [Synthetic Control (SCM), Matrix Completion (MC)],
    [*Nuisance:*], [Pesos $w_j$ (SCM), matriz $L$ (MC)],
    [*Garantía:*], [Fit pre-tratamiento exacto (SCM), $O_p(sqrt(r(N+T)\/|cal(O)|))$ (MC)],
    [*Librerías:*], [scipy.optimize, numpy],
    [*Validación:*], [Placebos espaciales y temporales, gráfico pre-tratamiento],
  )
]

#notatecnica[
Los capítulos anteriores de esta parte estiman efectos a nivel de unidad individual; este cierra la Parte VII con el caso de una sola unidad tratada observada en el tiempo (control sintético), reutilizando el lenguaje de SCM del @cap-scm-pch en su acepción original de la literatura de evaluación de políticas macro, distinta pero complementaria a la de Bareinboim usada en la primera mitad del curso.
]

== Motivación aplicada
<sec-cap14_motivacion>

Una economista del Banco Central debe estimar el efecto de una reforma tributaria implementada en una región específica sobre la recaudación. No hay región de control perfecta: todas las regiones tienen trayectorias distintas. El _synthetic control method_ (SCM) clásico de @abadie2003economic construye un "control sintético" ponderando regiones no tratadas para reproducir la trayectoria pre-tratamiento de la región tratada.

Pero SCM clásico tiene limitaciones: requiere _fit_ pre-tratamiento perfecto, no maneja múltiples unidades tratadas con staggered adoption, y no produce IC fácilmente. #cite(<athey2021matrix>, form: "prose") proponen _matrix completion_ como alternativa: modelar la matriz de outcomes $Y in R^(N times T)$ como una matriz de bajo rango con ruido, donde las entradas post-tratamiento son "missing" y se imputan.

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

#cite(<athey2021matrix>, form: "prose") reinterpretan el problema como imputación de matriz. Sea $Y in R^(N times T)$ la matriz de outcomes, donde las entradas post-tratamiento para unidades tratadas son conceptualmente "missing" (porque no observamos el counterfactual). El modelo es:
$
Y = L + epsilon,
$
donde $L$ es una matriz de bajo rango ($"rank"(L) <= r << min(N, T)$) y $epsilon$ es ruido. Se estima $hat(L)$ minimizando:
$
hat(L) = "argmin"_(L: "rank"(L) <= r) sum_((i, t) in cal(O)) (Y_(i t) - L_(i t))^2,
$ <eq-matrix-completion>
donde $cal(O)$ es el conjunto de entradas observadas (pre-tratamiento + unidades no tratadas).

El problema anterior, con la restricción de rango explícita, es no convexo y computacionalmente intratable. La solución estándar es *relajarlo* sustituyendo el rango por la norma nuclear:
$
hat(L) = "argmin"_L { sum_((i,t) in cal(O)) (Y_(i t) - L_(i t))^2 + lambda norm(L)_* },
$
donde $norm(L)_* = sum_i sigma_i (L)$ es la suma de los valores singulares. La justificación de esta sustitución es la misma que la del LASSO en el @cap-regularizacion, un piso más arriba: así como la norma $ell_1$ es la envolvente convexa de la norma $ell_0$ (número de coeficientes no nulos) y por eso induce esparsidad, la norma nuclear es la envolvente convexa del rango sobre la bola espectral y por eso induce soluciones de rango bajo. #cite(<recht2010guaranteed>, form: "prose") establecen las condiciones —análogas a la _restricted isometry_ del caso esparso— bajo las cuales la relajación convexa recupera exactamente la solución del problema de rango mínimo original. El paralelo es útil también para las advertencias: igual que el LASSO contrae los coeficientes que selecciona, la norma nuclear contrae los valores singulares que retiene, lo que sesga $hat(L)$ hacia cero y por tanto sesga el efecto estimado —razón adicional para no fiar la elección de $lambda$ al ojo.

#theorem(
  name: [Athey et al., 2021]
)[
  Bajo condiciones regulares (low-rank, incoherence), $hat(L)$ estima $L$ con error $O_p(sqrt(r(N+T)\/|cal(O)|))$.
] <thm-matrix-completion>

=== Elegir $r$ o $lambda$: el hiperparámetro que fija el contrafactual
<sec-cap14_rango>

La cota anterior es informativa sobre cómo escala el error con el rango $r$, pero deja abierta la pregunta operativa: ¿qué valor usar? Es la decisión más consecuente del método, y conviene no tratarla como un detalle de implementación, porque el hiperparámetro determina literalmente el contrafactual estimado. Con $lambda$ muy alto ($r$ efectivo bajo) el modelo es rígido y no reproduce la trayectoria pre-tratamiento —el sesgo aparece como un mal ajuste visible—. Con $lambda$ muy bajo ($r$ efectivo alto), el modelo tiene grados de libertad suficientes para ajustar el ruido pre-tratamiento y, al extrapolar al periodo post, el "efecto" estimado puede ser en buena parte ese sobreajuste proyectado.

El procedimiento estándar, y el que este curso recomienda, es *validación cruzada sobre celdas observadas*: enmascarar artificialmente un subconjunto de entradas que sí se observan (típicamente los últimos periodos pre-tratamiento de las unidades de control), imputarlas con cada valor candidato de $lambda$, y elegir el que minimiza el error de imputación fuera de muestra. La clave del diseño es que el patrón de enmascaramiento *imite la estructura del faltante real* —bloques de periodos finales, no celdas dispersas al azar—, porque el problema real es de extrapolación temporal y no de imputación aleatoria; validar con celdas dispersas produce sistemáticamente un $lambda$ demasiado bajo.

Dos diagnósticos complementarios deben acompañar a la elección. Primero, reportar la *curva de efecto estimado frente a $lambda$*, con la misma lectura que en el @cap-pds: una meseta indica robustez, una pendiente pronunciada indica que el resultado es función del hiperparámetro. Segundo, y más informativo, verificar el *ajuste pre-tratamiento* del $lambda$ elegido: si el error de imputación pre-tratamiento es comparable a la magnitud del efecto post-tratamiento estimado, no hay señal que distinguir del ruido, por bueno que sea el valor de validación cruzada.

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

=== Inferencia en synthetic control

La inferencia en synthetic control se formaliza mediante *placebos en espacio* (@abadie2015comparative, Abadie et al. 2015): se estima un SCM para cada unidad de control como si fuera tratada, generando una distribución empírica de efectos placebo contra la cual se compara el efecto observado.

*Métodos alternativos:*
- *Balancing weights* (@doudchenko2016balancing, Doudchenko & Imbens 2016): relajación convexa de SCM que permite ponderaciones negativas controladas
- *Augmented synthetic control* (@benmichael2021augmented, Ben-Michael et al. 2021): combina SCM con regresión ridge para mejorar balance y reducir sesgo

*Selección de hiperparámetros:* En matrix completion, el rango $r$ o parámetro de regularización $lambda$ se seleccionan por validación cruzada temporal (ver §28.4).

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

*Interpretación.* El SCM clásico y el matrix completion producen estimaciones consistentes del efecto post-tratamiento (cerca del valor verdadero 2.5). El placebo espacial —aplicar el mismo procedimiento a una unidad no tratada— produce un efecto cercano a cero, validando la especificación. #cite(<abadie2010synthetic>, form: "prose") aplicaron SCM al efecto de la ley de tabaco de California (Proposición 99) sobre el consumo de cigarrillos; la cifra original de reducción post-tratamiento no se reproduce aquí para evitar imprecisiones, pero el orden de magnitud (varios paquetes per cápita) es consistente con la literatura.

*Cómo se hace inferencia cuando solo hay una unidad tratada.* Conviene detenerse en el placebo espacial, porque no es un chequeo accesorio sino *el* procedimiento de inferencia del control sintético. Con una sola unidad tratada no hay muestra sobre la que aplicar un teorema central del límite, de modo que el error estándar convencional no está definido. #cite(<abadie2015comparative>, form: "prose") formalizan la alternativa: un *test de aleatorización* que aplica el mismo procedimiento a cada unidad de control como si hubiera sido tratada, construye la distribución de los efectos placebo así obtenidos, y sitúa el efecto de la unidad realmente tratada dentro de esa distribución. Si su efecto está en la cola extrema, se rechaza la hipótesis nula de efecto nulo. El $p$-valor resultante es exacto pero *discreto*: con $J$ unidades de control, el mínimo alcanzable es $1\/(J+1)$ —con 10 donantes no se puede obtener $p < 0.09$, por grande que sea el efecto—, límite que hay que reportar en vez de dejar que el lector lo suponga continuo.

La misma referencia añade un refinamiento necesario: los placebos con mal ajuste pre-tratamiento producen efectos post-tratamiento grandes por construcción y contaminan la distribución de referencia. La práctica estándar es normalizar por el error de ajuste pre-tratamiento (usar el cociente RMSPE post/pre en lugar del efecto crudo) o descartar los donantes cuyo ajuste pre-tratamiento sea sustancialmente peor que el de la unidad tratada.

*Cuándo el supuesto de combinación convexa es el problema.* El SCM clásico restringe $w_j >= 0$ y $sum_j w_j = 1$, lo que impide extrapolar: si la unidad tratada es extrema en alguna característica —el estado más rico, la región más urbana— ninguna combinación convexa de donantes la reproduce, y el ajuste pre-tratamiento será pobre haga lo que haga el optimizador. Dos líneas de trabajo relajan la restricción. #cite(<doudchenko2016balancing>, form: "prose") muestran que SCM, DiD y varios estimadores de emparejamiento son casos particulares de una misma familia de regresiones lineales sobre las unidades de control, que se distinguen exactamente por qué restricciones imponen sobre los pesos (no negatividad, suma unitaria, intercepto); ver la familia completa aclara qué se está suponiendo al elegir uno u otro. #cite(<benmichael2021augmented>, form: "prose") proponen el *control sintético aumentado*, que corrige el sesgo residual del ajuste imperfecto añadiendo un modelo de resultado —la misma lógica de _augmentation_ doblemente robusta del @cap-dml, trasladada al panel—: si el SCM ajusta bien, la corrección es despreciable; si ajusta mal, la corrige explícitamente en lugar de dejar el sesgo sin tratar.

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
      [Mal ajuste pre-tratamiento], [SCM inválido: el contrafactual no reproduce la trayectoria previa, y el "efecto" mide el error de ajuste], [Gráfico pre-tratamiento y RMSPE previo comparado con la magnitud del efecto], [Descartar SCM, ampliar el conjunto de donantes, o usar control sintético aumentado @benmichael2021augmented],
      [Pocos donantes], [Control débil *y* $p$-valor de placebo acotado por abajo en $1\/(J+1)$], [Número de donantes con ajuste pre-tratamiento comparable; distribución de pesos (¿concentrada en 1-2 unidades?)], [Ampliar el conjunto de donantes; reportar explícitamente el $p$-valor mínimo alcanzable],
      [Unidad tratada fuera de la envolvente convexa], [Ningún vector de pesos convexos la reproduce; sesgo irreducible bajo SCM clásico], [Comparar covariables de la tratada con el rango de los donantes], [Relajar restricciones sobre los pesos @doudchenko2016balancing o aumentar con un modelo de resultado],
      [Low-rank falso o $lambda$ mal elegido], [MC sesgado, o sobreajuste del ruido pre-tratamiento proyectado al post], [Validación cruzada con enmascaramiento en bloque (@sec-cap14_rango); curva efecto vs. $lambda$], [Elegir $lambda$ por CV con patrón de faltante realista; reportar la sensibilidad y placebos],
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

#cite(<abadie2003economic>, form: "prose") y #cite(<abadie2010synthetic>, form: "prose") son las referencias de SCM clásico; #cite(<abadie2015comparative>, form: "prose") desarrolla la inferencia por permutación de placebos y las correcciones por ajuste pre-tratamiento que la hacen utilizable. #cite(<doudchenko2016balancing>, form: "prose") sitúan SCM, DiD y emparejamiento dentro de una familia común de estimadores de pesos, y son la mejor lectura para entender qué se supone al elegir cada uno. #cite(<benmichael2021augmented>, form: "prose") proponen el control sintético aumentado para el caso de ajuste pre-tratamiento imperfecto. #cite(<athey2021matrix>, form: "prose") introduce matrix completion y su relación con los estimadores anteriores. #cite(<arkhangelsky2021synthetic>, form: "prose") propone Synthetic DiD como híbrido entre control sintético y diferencias-en-diferencias. Sobre la conexión con la literatura de DiD con adopción escalonada —los mismos problemas vistos desde el otro extremo del espectro de número de unidades tratadas— véase el @cap-panel-dmliv y sus referencias.
