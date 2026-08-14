// =============================================================================
// Diapositivas · Capítulo 12 — Meta-learners para efectos de tratamiento
// heterogéneos
// Fuente: 02_monografia/.../capitulos/cap05_metalearners.typ
// Plan detallado: PLAN_SPRINT_DIAPOSITIVAS.md §3, "Cap. 12"
// Sesión S13 · Lab L13 · Entrega: A3 arranca · Variante A · ★ camino crítico
// =============================================================================
#import "../plantilla_monografia.typ": *

#show: cap-theme

#cap-init(num: 12, titulo: "Meta-learners para efectos de tratamiento heterogéneos",
  parte: "II", sesion: "S13", variant: "A", critico: true)

#cap-progreso-curso(cap-actual: 12)
#cap-portada(num: 12, titulo: "Meta-learners para efectos de tratamiento heterogéneos",
  parte: "II", sesion: "S13", variant: "A", critico: true)

#cap-roadmap(
  objetivos: (
    [Implementar S/T/X/R/DR-learner.],
    [Explicar por qué R- y DR-learner dependen de los nuisance a 2.º orden y S/T/X a
     1.er orden.],
    [Elegir un meta-learner según soporte común y muestra disponible.],
  ),
  agenda: (
    [S-learner, T-learner, X-learner],
    [R-learner: score de Robinson aplicado a τ(x)],
    [DR-learner: pseudo-resultado y tasa oracle],
    [Comparación de propiedades],
    [Caso NSW: CATE por subgrupo],
  ),
  lectura: "Cap. 12 — Meta-learners (@cap-meta-learners)",
  lab: "L13", entrega: "A3 arranca",
)

#cap-motivacion(
  problema: "ONG decide entre dos variantes de microcrédito por cliente — no
    \"¿cuál es el efecto promedio?\" sino \"¿a qué clientes conviene asignar A y a
    cuáles B?\".",
  gancho: "Ningún meta-learner domina uniformemente: S sufre sesgo de regularización,
    T sufre varianza en grupo pequeño, X mitiga ambos, R es eficiente pero complejo.",
  caso: "Microcrédito grupal (A) vs. individual (B), efecto heterogéneo sobre repago.",
)

#cap-glosario(terminos: (
  ([S-learner], [Un solo modelo con D como covariable — riesgo: D puede ser ignorado
    bajo regularización.]),
  ([T-learner], [Dos modelos separados — riesgo: varianza alta si un grupo es
    pequeño.]),
  ([X-learner], [Imputa efectos cruzados y pondera por ê(x).]),
))

#cap-definicion(
  titulo-def: "R-learner (score de Robinson aplicado a τ(x))",
  cuerpo: "Optimiza directamente una loss que aísla el CATE usando el score ortogonal
    de Robinson (1988), con τ como función en vez de escalar.",
  eq: $hat(tau)_R = "argmin"_tau {1/n sum_i [(Y_i-hat(m)_Y (X_i)) - tau(X_i)(D_i-hat(e)(X_i))]^2 + Lambda(tau)}$,
)

#cap-teorema(
  titulo: "DR-learner: tasa oracle (Kennedy, 2023)",
  enunciado: "El pseudo-resultado Γ_i es el score IRM antes de promediar — la fila
    'CATE, DR-learner' de la tabla de score canónico del Cap. 10: el mismo objeto,
    sin promediar. El error del DR-learner se acota por el error de un oracle que
    observara los Γ_i verdaderos, más un término de 2.º orden proporcional al
    PRODUCTO de los errores de μ̂_d y ê — no a su suma, como en S/T/X. Por eso
    tolera nuisance mediocres si no fallan los dos a la vez.",
)

#cap-supuestos(supuestos: (
  ([S/T/X-learner], [Dependencia de 1.er orden en los nuisance], [Tasa a_n heredada
    directamente]),
  ([R/DR-learner], [Dependencia de 2.º orden (producto de errores)], [Cuasi-oracle /
    tasa oracle bajo condición de producto]),
))

#cap-interactivo(
  tipo: "Conceptual",
  pregunta: "El S-learner con regularización fuerte colapsa el CATE a cero — ¿por qué
    eso no es un problema del algoritmo sino del diseño del método?",
)

#cap-codigo-parte(
  titulo: "Comparación de 4 meta-learners — RMSE vs. CATE verdadero",
  snippet: "import numpy as np\n"
    + "from sklearn.ensemble import GradientBoostingRegressor\n"
    + "from sklearn.linear_model import LogisticRegressionCV\n"
    + "from econml.metalearners import SLearner, TLearner, XLearner\n"
    + "from econml.dml import CausalForestDML\n\n"
    + "def make_dgp(n=2000, p=10, seed=0):\n"
    + "    rng = np.random.default_rng(seed)\n"
    + "    X = rng.uniform(-1, 1, (n, p))\n"
    + "    e = 1 / (1 + np.exp(-1.0 - 0.5*X[:, 0]))\n"
    + "    D = (rng.uniform(size=n) < e).astype(int)\n"
    + "    tau = 2 + 3*X[:, 0] - X[:, 1]**2  # CATE verdadero\n"
    + "    Y = X[:, 2] + 0.5*X[:, 3] + D*tau + rng.standard_normal(n)*0.5\n"
    + "    return Y, D, X, tau\n\n"
    + "Y, D, X, tau_true = make_dgp(n=2000, seed=42)\n"
    + "ml = lambda: GradientBoostingRegressor(n_estimators=200, max_depth=4, random_state=42)\n"
    + "e_model = LogisticRegressionCV(cv=5)\n"
    + "tau_s = SLearner(overall_model=ml()).fit(Y, D, X).effect(X)\n"
    + "tau_t = TLearner(models=ml()).fit(Y, D, X).effect(X)\n"
    + "tau_x = XLearner(models=ml(), propensity_model=e_model).fit(Y, D, X).effect(X)\n"
    + "tau_r = CausalForestDML(model_y=ml(), model_t=e_model, discrete_treatment=True,\n"
    + "                        n_estimators=200, random_state=42).fit(Y, D, X=X).effect(X)\n\n"
    + "for name, tau_hat in [(\"S\", tau_s), (\"T\", tau_t), (\"X\", tau_x), (\"R\", tau_r)]:\n"
    + "    rmse = np.sqrt(np.mean((tau_hat - tau_true)**2))\n"
    + "    print(f\"{name}-learner: RMSE={rmse:.4f}  Bias={np.mean(tau_hat - tau_true):.4f}\")",
  salida: "S-learner: RMSE=... Bias=...\nT-learner: RMSE=...\nX-learner: RMSE=...\nR-learner: RMSE=...",
)

#cap-caso-resolucion(
  titulo: "NSW: CausalForestDML por subgrupo educativo",
  contexto: "n=445, 185 tratados. CATE medio \$2,226, IC 95% [\$14, \$4,438].",
  resultado: "CATE por educación: \$1,174 (educ=7) → \$3,515 (educ=14). Consistente con
    que individuos con más educación previa aprovechan mejor la capacitación.",
  interpretacion: "La regla naïve \"tratar a los más pobres\" no es óptima — conviene
    incorporar la educación como criterio adicional.",
)

#cap-mapeo-pch-activo(
  nivel: "L2 heterogéneo — τ(x) = E[Y(1)−Y(0)\|X=x]",
  metrica: "RMSE(τ̂, τ) sobre DGP sintético; CATE medio por subgrupo en NSW",
  pregunta-activa: "Si solo predijéramos quién tiene mayor Y esperado, ¿coincidiría
    con a quién conviene asignar el microcrédito grupal? ¿Por qué no necesariamente?",
)

#cap-errores-transiciones(
  errores: (
    ("crítico", [S-learner regularizado: CATE colapsa a cero — verificar la fracción
      de CATE estimados en exactamente cero.]),
    ("advertencia", [Propensity extremo: varianza alta en X/R/DR-learner sin
      trimming — mismo diagnóstico ESS/$alpha^*$ del Cap. 11, heredado por los
      denominadores ê(X) y 1−ê(X) en Γᵢ.]),
    ("advertencia", [Subgrupos sin IC: bootstrap o forest, nunca reportar CATE por
      subgrupo sin incertidumbre.]),
  ),
  conexiones: "Guía de elección: DR/R primero si hay soporte común y muestra; T-learner
    como baseline obligatorio; S-learner solo con learners poco regularizados.",
)

#cap-discusion-ejercicio(
  pregunta: "¿Por qué el R- y el DR-learner tienen garantías más fuertes con
    nuisance mediocres que el T-learner, pese a usar el mismo tipo de learners
    internamente?",
  ejercicio: "Implemente el R-learner \"a mano\" con cross-fitting (K=5) para m̂_Y y ê,
    y un RandomForestRegressor para τ̂. Compare con la implementación de econml.",
)

#cap-cierre-narrativo(
  resumen: (
    [Cuatro estrategias reutilizan learners genéricos para estimar τ(x): S, T, X, R,
     y el DR-learner las extiende con tasa oracle.],
    [La distinción de fondo es la dependencia de 1.er vs. 2.º orden en los nuisance.],
    [Ningún meta-learner domina siempre — la elección depende de soporte común y
     muestra.],
  ),
  refs: (
    [Künzel et al. (2019), S/T/X-learners],
    [Nie & Wager (2021), R-learner],
    [Kennedy (2023), DR-learner y tasa oracle],
  ),
  transicion: "Cap. 13 — Árboles y bosques causales",
  gancho: "Los meta-learners reutilizan learners genéricos; el siguiente capítulo
    presenta una familia diseñada específicamente para CATE, con mejores garantías de
    inferencia.",
)
