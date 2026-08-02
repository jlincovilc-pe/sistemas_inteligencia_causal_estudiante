// Capítulo 13 — Deep learning para inferencia causal
#import "../template/template.typ": *

#chapter[Deep learning para inferencia causal]
<cap-deep-causal>

#theorem-number-reset()

#cuadrosinoptico[
  #table(
    columns: (auto, 1fr),
    align: (left, left),
    stroke: none,
    [*[Problema]*], [Estimar CATE con no linealidades complejas usando redes neuronales],
    [*[Estimando]*], [$tau(x) = E[Y(1)-Y(0) mid X=x]$],
    [*[Identificación]*], [No confusión, soporte común, SUTVA],
    [*[Método]*], [TARNet, CFRNet (IPM), DeepIV],
    [*[Nuisance]*], [$mu_1(x), mu_0(x), Phi(x)$],
    [*[Garantía]*], [Bound de error bajo no confusión y representación balanceada],
    [*[Librerías]*], [PyTorch, econml],
    [*[Validación]*], [Balance de representación, MMD, comparación con meta-learners],
  )
]

#notatecnica[
Con la Parte VI completa —el curso ya cubrió estimación, decisión, equidad y generalización con los métodos "estándar" de ML causal— esta Parte VII reúne dos familias de métodos más especializados. Este capítulo extiende los meta-learners y bosques causales (Capítulos 12–13) con arquitecturas de _deep learning_ diseñadas específicamente para balancear representaciones entre grupos de tratamiento.
]

== Motivación aplicada
<sec-cap13_motivacion>

Una plataforma de salud digital desea estimar el efecto de un programa de recordatorios personalizados sobre la adherencia a medicamentos. Cada usuario tiene cientos de características (historial médico, comportamiento en la app, demografía). El efecto del tratamiento es altamente no lineal: para algunos subgrupos el recordatorio es muy efectivo, para otros es nulo. Los métodos basados en árboles (Causal Forest) pueden no capturar la estructura compleja; una red neuronal podría.

El _deep causal learning_ aplica redes neuronales al problema de estimación causal. La innovación central, introducida por @shalit2017estimating con TARNet y CFRNet, es aprender una _representación balanceada_ $Phi(X)$ tal que las distribuciones de $Phi(X)$ para tratados y controles sean similares, permitiendo estimar $mu_0(Phi(X))$ y $mu_1(Phi(X))$ con la misma red.

Este capítulo desarrolla TARNet y CFRNet con implementación nativa en PyTorch, presenta DeepIV (@hartford2017deep) para variables instrumentales, y discute las extensiones modernas (CEVAE, contrastive balance).

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
cal(L)_"CFRNet" = cal(L)_"TARNet" + alpha dot.c "IPM"(Phi(X mid D = 0), Phi(X mid D = 1)).
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

+ *Red de tratamiento* $g(z, x)$ que modela la densidad $p(D mid Z, X)$.
+ *Red estructural* $h(d, x)$ que estima $E[Y mid D, X]$.

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
      [Balance sin identificación], [Falsa seguridad], [DAG/supuestos], [No confusión explícita],
      [Overfitting profundo], [Mala generalización], [Train/test loss], [Regularización],
      [MMD mal calibrado], [Balance artificial], [Diagnóstico de representación], [Sensibilidad],
      table.hline(stroke: 0.8pt),
    )
  ) <tab-riesgos-cap13>
]

Las redes neuronales no producen intervalos de confianza naturalmente. Es recomendable usar _bootstrap_ o _Bayesian neural networks_ para inferencia.

Deep causal requiere muestras grandes ($n > 5\,000$) y ajuste cuidadoso de hiperparámetros. Para muestras pequeñas, métodos basados en árboles son preferibles. La inferencia válida sobre $tau(x)$ sigue siendo un problema abierto.

== Ejercicios propuestos
<sec-cap13_ejercicios>

+ Replique el listado @lst-tarnet variando la profundidad de la red (1, 2, 3 capas ocultas). ¿Cuándo aparece overfitting?

+ Implemente CFRNet con penalización Wasserstein en lugar de MMD (usar #code[geomloss] o #code[POT]).

+ Compare TARNet, CFRNet y Causal Forest sobre un DGP con no linealidades crecientes. ¿En qué punto el deep causal supera a los árboles?

+ Implemente DeepIV sobre el dataset #code[iv_noncompliance] (sintético) y verifique que recupera el "LATE".

== Lecturas complementarias
<sec-cap13_lecturas>

@shalit2017estimating es la referencia fundacional de TARNet/CFRNet. @hartford2017deep introduce DeepIV. @louizos2017causal propone CEVAE. @shi2019adaptively extiende a DragonNet. Para una revisión, @neurise2023deep.
