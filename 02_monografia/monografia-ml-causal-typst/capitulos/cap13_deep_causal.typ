// Capítulo 27 — Deep learning para inferencia causal
// (La numeración `cap13` del nombre de archivo es histórica: proviene de la edición corta anterior y se conserva para no romper referencias.)
#import "../template/template.typ": *

#chapter[Deep learning para inferencia causal]
<cap-deep-causal>

#theorem-number-reset()

#cuadrosinoptico[
  #table(
    columns: (auto, 1fr),
    align: (left, left),
    stroke: none,
    [*Problema:*], [Estimar CATE con no linealidades complejas usando redes neuronales],
    [*Estimando:*], [$tau(x) = E[Y(1)-Y(0) | X=x]$],
    [*Identificación:*], [No confusión, soporte común, SUTVA],
    [*Método:*], [TARNet, CFRNet (IPM), DeepIV],
    [*Nuisance:*], [$mu_1(x), mu_0(x), Phi(x)$],
    [*Garantía:*], [Bound de error bajo no confusión y representación balanceada],
    [*Librerías:*], [PyTorch, econml],
    [*Validación:*], [Balance de representación, MMD, comparación con meta-learners],
  )
]

#notatecnica[
Con la Parte VI completa —el curso ya cubrió estimación, decisión, equidad y generalización con los métodos "estándar" de ML causal— esta Parte VII reúne dos familias de métodos más especializados. Este capítulo extiende los meta-learners y bosques causales (Capítulos 12–13) con arquitecturas de _deep learning_ diseñadas específicamente para balancear representaciones entre grupos de tratamiento.
]

== Motivación aplicada
<sec-cap13_motivacion>

Una plataforma de salud digital desea estimar el efecto de un programa de recordatorios personalizados sobre la adherencia a medicamentos. Cada usuario tiene cientos de características (historial médico, comportamiento en la app, demografía). El efecto del tratamiento es altamente no lineal: para algunos subgrupos el recordatorio es muy efectivo, para otros es nulo. Los métodos basados en árboles (Causal Forest) pueden no capturar la estructura compleja; una red neuronal podría.

El _deep causal learning_ aplica redes neuronales al problema de estimación causal. La innovación central, introducida por @shalit2017estimating con TARNet y CFRNet, es aprender una _representación balanceada_ $Phi(X)$ tal que las distribuciones de $Phi(X)$ para tratados y controles sean similares, permitiendo estimar $mu_0(Phi(X))$ y $mu_1(Phi(X))$ con la misma red.

Este capítulo desarrolla TARNet y CFRNet con implementación nativa en PyTorch, presenta DeepIV @hartford2017deep para variables instrumentales, y discute las extensiones modernas (CEVAE, contrastive balance).

== Teoría, supuestos y garantías
<sec-cap13_teoria>

=== TARNet: representación compartida
<sec-cap13_tarnet>

TARNet (_Treatment-Agnostic Representation Network_) tiene arquitectura:

+ *Capa de representación* $Phi: R^p arrow.r R^k$ que mapea covariables a un embedding.
+ *Cabezas de outcome* $h_0, h_1: R^k arrow.r R$ separadas para tratados y controles.

La predicción es $hat(mu)_d (x) = h_d(Phi(x))$. El CATE estimado es $hat(tau)(x) = h_1(Phi(x)) - h_0(Phi(x))$.

La _loss_ es el error cuadrático medio:
$
cal(L)_"TARNet" = (1 / n) sum_i (Y_i - h_(D_i)(Phi(X_i)))^2.
$

=== CFRNet: balance integral probability metric
<sec-cap13_cfrnet>

CFRNet (_Counterfactual Regression with IPM_) añade a TARNet una penalización de _Integral Probability Metric_ (IPM) que fuerza el balance entre las distribuciones de $Phi(X)$ para tratados y controles:
$
cal(L)_"CFRNet" = cal(L)_"TARNet" + alpha dot.c "IPM"(Phi(X | D = 0), Phi(X | D = 1)).
$ <eq-cfrnet-loss>

Aquí $alpha$ es el peso de la penalización IPM, no el nivel de significación.

El IPM puede ser la distancia Wasserstein, la divergencia MMD, o la _adversarial loss_ (como en DOMAIN-ADVERSARIAL neural networks).

#theorem(
  name: [Shalit, Johansson & Sontag, 2017]
)[
  Bajo no confusión, soporte común, y regularidad estándar, el estimador CFRNet satisface un _bound_ de error esperado en $tau$ que se descompone en: (i) error de estimación, (ii) complejidad de la clase de funciones, (iii) IPM entre las distribuciones de $Phi(X)$ para tratados y controles.
] <thm-cfrnet>

=== DeepIV
<sec-cap13_deepiv>

Para casos con variable instrumental, @hartford2017deep proponen DeepIV: una red neuronal que modela la distribución del tratamiento dado el instrumento y covariables, y luego estima el structural function. La arquitectura es:

+ *Red de tratamiento* $g(z, x)$ que modela la densidad $p(D | Z, X)$.
+ *Red estructural* $h(d, x)$ que estima $E[Y | D, X]$.

La loss combina la verosimilitud del tratamiento y el error del outcome.

== Algoritmo de entrenamiento TARNet/CFRNet
<sec-cap13_algoritmo>

El siguiente pseudocódigo describe el procedimiento de entrenamiento de TARNet y su extensión CFRNet. La diferencia clave es la penalización IPM que fuerza el balance de la representación latente $Phi(X)$ entre grupos de tratamiento y control.

#algorithm("Entrenamiento TARNet/CFRNet")[
  #kwin[Entrada][Datos $(X_i, D_i, Y_i)_(i=1)^n$, red de representación $Phi$ con cabezas $h_0, h_1$, épocas $E$, tasa de aprendizaje $eta$, peso IPM $alpha >= 0$]
  #kwout[Salida][Estimación del CATE $hat(tau)(x) = h_1(Phi(x)) - h_0(Phi(x))$]
  #for-loop(`epoch`, 1, `E`)[
    Calcular representación $Phi_i = Phi(X_i)$ para todo $i$ \
    Predecir $hat(Y)_i = h_(D_i)(Phi_i)$ \
    $cal(L)_"MSE" <- (1 / n) sum_(i=1)^n (Y_i - hat(Y)_i)^2$ \
    *if* #h(2pt) CFRNet *then* \
    #h(1.5em) $"IPM" <- "MMD"({Phi_i : D_i = 0}, {Phi_i : D_i = 1})$ \
    #h(1.5em) $cal(L) <- cal(L)_"MSE" + alpha dot.c "IPM"$ \
    *else* \
    #h(1.5em) $cal(L) <- cal(L)_"MSE"$ \
    *end if* \
    Actualizar parámetros con $nabla cal(L)$ vía Adam($eta$)
  ]
  #return-stmt[$hat(tau)(x) = h_1(Phi(x)) - h_0(Phi(x))$]
] <alg-tarnet-cfrnet-training>

== Implementación en Python
<sec-cap13_implementacion>

#figure(
  kind: raw,
  caption: [Implementación de TARNet en PyTorch.],
  ```python
import torch
import torch.nn as nn
import torch.optim as optim
import numpy as np
from torch.utils.data import DataLoader, TensorDataset

class TARNet(nn.Module):
    def __init__(self, in_dim, rep_dim=64, hidden=128):
        super().__init__()
        # Representacion compartida
        self.rep = nn.Sequential(
            nn.Linear(in_dim, hidden), nn.ReLU(),
            nn.Linear(hidden, hidden), nn.ReLU(),
            nn.Linear(hidden, rep_dim),
        )
        # Cabezas separadas para D=0 y D=1
        self.h0 = nn.Sequential(
            nn.Linear(rep_dim, hidden), nn.ReLU(),
            nn.Linear(hidden, 1),
        )
        self.h1 = nn.Sequential(
            nn.Linear(rep_dim, hidden), nn.ReLU(),
            nn.Linear(hidden, 1),
        )
    def forward(self, X, D):
        Phi = self.rep(X)
        out = torch.where(D.unsqueeze(-1) == 1, self.h1(Phi), self.h0(Phi))
        return out.squeeze(-1)
    def predict_cate(self, X):
        Phi = self.rep(X)
        return (self.h1(Phi) - self.h0(Phi)).squeeze()

# DGP
def make_dgp(n=3000, seed=0):
    rng = np.random.default_rng(seed)
    X = rng.uniform(-1, 1, (n, 10))
    e = 1/(1 + np.exp(-1.0 - 0.5*X[:, 0]))
    D = (rng.uniform(size=n) < e).astype(np.float32)
    tau = 2 + 3*X[:, 0] - X[:, 1]**2
    mu0 = np.sin(X[:, 2]) + X[:, 3]
    Y = mu0 + D * tau + rng.standard_normal(n) * 0.5
    return X.astype(np.float32), D.astype(np.float32), Y.astype(np.float32), tau

X, D, Y, tau_true = make_dgp(3000, seed=42)
X_t = torch.from_numpy(X); D_t = torch.from_numpy(D); Y_t = torch.from_numpy(Y)

# Entrenamiento
torch.manual_seed(42)
model = TARNet(in_dim=X.shape[1])
opt = optim.Adam(model.parameters(), lr=1e-3, weight_decay=1e-4)
for epoch in range(200):
    model.train()
    opt.zero_grad()
    pred = model(X_t, D_t)
    loss = ((pred - Y_t)**2).mean()
    loss.backward()
    opt.step()
    if epoch % 50 == 0:
        print(f"Epoch {epoch}: loss={loss.item():.4f}")

# Evaluacion
model.eval()
with torch.no_grad():
    cate_hat = model.predict_cate(X_t).numpy()
rmse = np.sqrt(np.mean((cate_hat - tau_true)**2))
print(f"RMSE en CATE: {rmse:.4f}")
```
) <lst-tarnet>

=== CFRNet con penalización MMD
<sec-cap13_cfrnet_mmd>

#figure(
  kind: raw,
  caption: [CFRNet con penalización MMD.],
  ```python
def mmd_loss(Phi0, Phi1, sigma=1.0):
    """Maximum Mean Discrepancy entre representaciones de tratados y controles."""
    def kernel(A, B):
        # RBF kernel
        diff = A.unsqueeze(1) - B.unsqueeze(0)
        return torch.exp(-diff.pow(2).sum(-1) / (2 * sigma**2))
    K00 = kernel(Phi0, Phi0); K11 = kernel(Phi1, Phi1); K01 = kernel(Phi0, Phi1)
    return K00.mean() + K11.mean() - 2 * K01.mean()

class CFRNet(TARNet):
    def forward_loss(self, X, D, Y, alpha=1.0):
        Phi = self.rep(X)
        pred = torch.where(D.unsqueeze(-1) == 1, self.h1(Phi), self.h0(Phi)).squeeze(-1)
        mse = ((pred - Y)**2).mean()
        Phi0 = Phi[D == 0]; Phi1 = Phi[D == 1]
        if len(Phi0) > 1 and len(Phi1) > 1:
            mmd = mmd_loss(Phi0, Phi1)
        else:
            mmd = torch.tensor(0.0)
        return mse + alpha * mmd

# Entrenamiento CFRNet
model_cfr = CFRNet(in_dim=X.shape[1])
opt = optim.Adam(model_cfr.parameters(), lr=1e-3, weight_decay=1e-4)
for epoch in range(200):
    model_cfr.train(); opt.zero_grad()
    loss = model_cfr.forward_loss(X_t, D_t, Y_t, alpha=1.0)
    loss.backward(); opt.step()
    if epoch % 50 == 0:
        print(f"Epoch {epoch}: loss={loss.item():.4f}")

model_cfr.eval()
with torch.no_grad():
    cate_cfr = model_cfr.predict_cate(X_t).numpy()
print(f"CFRNet RMSE: {np.sqrt(np.mean((cate_cfr - tau_true)**2)):.4f}")
```
) <lst-cfrnet>

== Arquitectura de TARNet/CFRNet
<sec-cap13_arquitectura>

La figura @fig-cap13-tarnet muestra la arquitectura común de TARNet y CFRNet. Una red de representación compartida $Phi(X)$ mapea las covariables a un embedding de menor dimensión; dos cabezas separadas $h_0, h_1$ estiman $mu_0(Phi(X))$ y $mu_1(Phi(X))$ respectivamente. El CATE se obtiene por diferencia: $hat(tau)(X) = h_1(Phi(X)) - h_0(Phi(X))$. CFRNet añade a TARNet una penalización IPM (Integral Probability Metric) que fuerza el balance entre las distribuciones de $Phi(X)$ para tratados y controles, reduciendo el desbalance observado de covariables en el espacio de representación, bajo el supuesto previo de no confusión.

#figure(
  image("../figuras/fig_cap13_tarnet_arch.png", width: 95%),
  caption: [Arquitectura de TARNet / CFRNet (Shalit, Johansson & Sontag, 2017). La capa de representación compartida $Phi$ es seguida por dos cabezas separadas $h_0, h_1$ para $D = 0$ y $D = 1$. CFRNet añade una penalización IPM (Wasserstein o MMD) que fuerza el balance entre las distribuciones de $Phi(X)$ condicionales al tratamiento.],
) <fig-cap13-tarnet>

== Caso empírico y validación
<sec-cap13_caso_empirico>

Sobre el dataset sintético con no linealidades, TARNet y CFRNet producen un RMSE en CATE competitivo con X-learner y T-learner (con GBM). La ventaja de los métodos deep es mayor cuando el DGP tiene no linealidades complejas o interacciones de alto orden; para DGPs simples o con muestras pequeñas ($n < 1\,000$), los métodos basados en árboles son competitivos y más rápidos de entrenar.

#intuicion[
*Caja de profundización 13.1: Representaciones balanceadas y diagnóstico de balance*

*Objetivo.* Entender por qué TARNet/CFRNet aprenden una representación intermedia y cómo verificar si está bien balanceada.

*La idea.* En lugar de estimar $mu_1(X)$ y $mu_0(X)$ directamente sobre las covariables originales, la red primero aprende una "representación" compacta $Phi(X)$. Luego estima los outcomes a partir de esa representación.

*¿Por qué balancear?* Si la distribución de $Phi(X)$ es similar entre tratados y controles, cualquier diferencia en outcomes se debe más probablemente al tratamiento y no a confusores observados. CFRNet agrega una penalización que fuerza este balance.

*Cómo diagnosticar el balance.* Una vez entrenada la red, podemos calcular:
- Diferencia de medias de $Phi(X)$ entre tratados y controles (debe ser cercana a cero).
- MMD (Maximum Mean Discrepancy): distancia entre las dos distribuciones.
- Si el MMD es grande, la red no está balanceando bien y podemos aumentar el peso de la penalización.

*Advertencia importante.* El balance de $Phi(X)$ NO garantiza identificación causal. Si hay confusores no observados que no están en $X$, ninguna red puede solucionarlo.
]

== Límites y errores comunes
<sec-cap13_limites>

#riesgos[
  #figure(
    caption: [Riesgos comunes en deep causal learning],
    table(
      columns: (1fr, 1fr, 1fr, 1fr),
      align: (left, left, left, left),
      stroke: none,
      table.hline(stroke: 0.8pt),
      table.header([*Riesgo*], [*Consecuencia*], [*Diagnóstico*], [*Mitigación*]),
      table.hline(stroke: 0.4pt),
      [Balance sin identificación], [Falsa seguridad: balancear $Phi(X)$ no crea el supuesto de no confusión], [DAG y supuestos declarados; el balance es sobre covariables *observadas*], [No confusión explícita y justificada; ningún ajuste arquitectónico la sustituye],
      [Overfitting profundo], [Mala generalización], [Train/test loss], [Regularización, _early stopping_, validación],
      [$alpha$ (peso IPM) fijado sin validar], [Representación sobre-balanceada y poco informativa; error en $tau$ mayor que sin penalización @curth2021inductive], [Barrido de $alpha$ incluyendo $alpha = 0$ (TARNet) y comparación de RMSE en $tau$ sobre un DGP con _ground truth_], [Tratar $alpha$ como hiperparámetro a validar y reportar su valor; no asumir que CFRNet domina a TARNet],
      [Reportar $hat(tau)(x)$ sin cuantificar incertidumbre], [Decisiones individuales basadas en un punto sin intervalo], [Verificar si el pipeline produce algún IC], [Usar la red como _nuisance_ dentro de DML (@sec-cap13_inferencia), o _bootstrap_ asumiendo su costo; para decisiones individuales, intervalos conformes (@sec-cap07_conformal)],
      table.hline(stroke: 0.8pt),
    )
  ) <tab-riesgos-cap13>
]

Deep causal requiere muestras grandes ($n > 5\,000$) y ajuste cuidadoso de hiperparámetros. Para muestras pequeñas, los métodos basados en árboles son preferibles. Dos límites merecen un tratamiento más detenido, porque la literatura reciente los ha precisado y en ambos casos la lectura ingenua del método es la equivocada.

=== ¿Balancear la representación ayuda realmente?
<sec-cap13_limites_balance>

La penalización IPM de CFRNet se presenta habitualmente como una mejora inequívoca sobre TARNet, y la ecuación @eq-cfrnet-loss lo sugiere: forzar $Phi(X | D=0)$ y $Phi(X | D=1)$ a parecerse debería reducir el término de discrepancia del _bound_ de #cite(<shalit2017estimating>, form: "prose"). #cite(<curth2021inductive>, form: "prose") muestran que el argumento es más frágil de lo que parece, y por una razón instructiva: la cota que justifica la penalización es *laxa*, y minimizarla no equivale a minimizar el error en $tau$.

El mecanismo del problema es directo. El balance es una restricción sobre la representación compartida; hacerla más fuerte reduce la información sobre $X$ que $Phi$ conserva, y parte de esa información puede ser necesaria para estimar bien $mu_0$ y $mu_1$. Con $alpha$ grande, la red aprende una representación tan balanceada como poco informativa —en el extremo, $Phi$ constante logra balance perfecto y error máximo—. Empíricamente, el $alpha$ óptimo depende del DGP y con frecuencia es cercano a cero; TARNet sin penalización es un competidor serio, no un _baseline_ trivial.

La lección que Curth y van der Schaar extraen, y que este capítulo adopta, es que lo determinante no es la penalización IPM sino los *sesgos inductivos* de la arquitectura: cómo se comparte información entre las dos cabezas, si se modela $tau$ directamente o por diferencia, si se usa el _propensity_ como entrada. Operativamente: $alpha$ debe tratarse como un hiperparámetro a validar, no como un interruptor que se activa porque "balancear es bueno", y su valor óptimo debe reportarse.

== Inferencia válida con redes neuronales profundas

La inferencia estadística válida (construcción de intervalos de confianza, tests) con DNNs para estimación causal se ha resuelto recientemente mediante dos enfoques:

1. *Representers de Riesz* (@chernozhukov2022riesznet, Chernozhukov et al. 2022): RieszNet aprende una representación dual que permite inferencia asintótica válida para funcionales de Riesz en modelos semiparámétricos.

2. *Estimación semiparámétrica eficiente con DNNs* (@farrell2021deep, Farrell et al. 2021): demuestran que las DNNs pueden alcanzar el bound de varianza de Cramér-Rao en modelos semiparétricos bajo condiciones de regularidad.

*Limitaciones de representaciones balanceadas:* @curth2021inductive (Curth & van der Schaar 2021) muestran que las arquitecturas con representación compartida $Phi(X)$ para $mu_0$ y $mu_1$ introducen sesgos inductivos que pueden ser subóptimos para HTE estimation cuando los outcomes potenciales tienen estructuras heterogéneas.

=== Detalles técnicos
<sec-cap13_inferencia>

Es cierto que TARNet y CFRNet, tal como se han presentado, no producen intervalos de confianza: se optimiza una pérdida predictiva y no hay ninguna garantía distribucional sobre $hat(tau)(x)$. Pero sería inexacto concluir que la inferencia con redes neuronales sea un problema sin tratamiento teórico. Dos líneas de trabajo lo abordan directamente y conviene conocerlas.

#cite(<farrell2021deep>, form: "prose") establecen tasas de convergencia no asintóticas para redes profundas con activaciones ReLU y, sobre esa base, demuestran normalidad asintótica e inferencia válida para funcionales semiparámétricos —incluido el ATE— estimados con redes como _nuisance_. El resultado es exactamente la pieza que faltaba: muestra que las redes satisfacen la condición de tasa $sqrt(n) a_n^2 -> 0$ del @cap-ortogonalidad bajo condiciones explícitas sobre profundidad, anchura y suavidad de la función objetivo. La consecuencia práctica es que *usar una red como `model_y` o `model_t` dentro de DML es teóricamente respaldado*, y probablemente la forma más sensata de combinar _deep learning_ e inferencia causal en producción hoy.

La segunda línea automatiza el paso de ortogonalización. #cite(<chernozhukov2022riesznet>, form: "prose") observan que el término de corrección de un score ortogonal es siempre un *representador de Riesz* del funcional de interés, y proponen aprenderlo directamente con una red (RieszNet) o un bosque (ForestRiesz), en lugar de derivarlo a mano para cada estimando. Esto convierte la construcción del score —que en los Capítulos 10 y 11 se hizo analíticamente para PLR e IRM— en un problema de aprendizaje, y extiende DML a funcionales para los que nadie ha derivado la fórmula.

La conclusión operativa para este capítulo es una inversión de la práctica habitual: en vez de usar una red para estimar $tau$ directamente y luego buscar cómo hacer inferencia sobre ella, conviene usar la red donde su capacidad de aproximación aporta —los _nuisance_ de alta dimensión— y dejar la inferencia al aparato ortogonal que ya la tiene resuelta. El _bootstrap_ sobre TARNet/CFRNet sigue siendo una opción práctica para cuantificar incertidumbre, pero es costoso y sus garantías bajo regularización y optimización no convexa son mucho menos claras.

== Ejercicios propuestos
<sec-cap13_ejercicios>

+ Replique el listado @lst-tarnet variando la profundidad de la red (1, 2, 3 capas ocultas). ¿Cuándo aparece overfitting?

+ Implemente CFRNet con penalización Wasserstein en lugar de MMD (usar #code[geomloss] o #code[POT]).

+ Compare TARNet, CFRNet y Causal Forest sobre un DGP con no linealidades crecientes. ¿En qué punto el deep causal supera a los árboles?

+ Barra el peso de la penalización IPM en $alpha in {0, 0.1, 1, 10, 100}$ y grafique el RMSE en $tau$ contra el MMD de la representación. Verifique que el $alpha$ que minimiza el MMD *no* es el que minimiza el RMSE, y relacione el resultado con la @sec-cap13_limites_balance.

+ Use la red TARNet (sin las cabezas causales: solo la representación más una cabeza) como #code[model_y] y #code[model_t] dentro de #code[LinearDML], y compare el ATE con IC obtenido así frente al ATE que produce TARNet directamente por promedio de $hat(tau)(x)$. ¿Cuál de los dos permite reportar un intervalo con respaldo teórico, y por qué (@sec-cap13_inferencia)?

+ Implemente DeepIV sobre el dataset #code[iv_noncompliance] (sintético) y verifique que recupera el "LATE".

== Lecturas complementarias
<sec-cap13_lecturas>

#cite(<shalit2017estimating>, form: "prose") es la referencia fundacional de TARNet/CFRNet y del _bound_ de error con IPM. #cite(<hartford2017deep>, form: "prose") introduce DeepIV. #cite(<louizos2017causal>, form: "prose") propone CEVAE. #cite(<shi2019adaptively>, form: "prose") extiende a DragonNet, que incorpora el _propensity_ como cabeza adicional y aplica una corrección dirigida al estimando.

Tres lecturas son indispensables para no quedarse en el estado del arte de 2017. #cite(<curth2021inductive>, form: "prose") revisan críticamente la familia completa desde el ángulo de los sesgos inductivos y son la fuente del análisis de la @sec-cap13_limites_balance sobre los límites de la representación balanceada; su comparación empírica sistemática es también el mejor punto de partida para elegir arquitectura. #cite(<farrell2021deep>, form: "prose") establecen las tasas y la teoría de inferencia que hacen de las redes profundas un _nuisance learner_ legítimo dentro de DML. #cite(<chernozhukov2022riesznet>, form: "prose") proponen aprender el representador de Riesz —y con él, el score ortogonal— en lugar de derivarlo analíticamente, extendiendo el aparato de la Parte II a funcionales arbitrarios.
