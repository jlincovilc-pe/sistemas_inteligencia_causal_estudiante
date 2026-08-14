// =============================================================================
// Diapositivas · Capítulo 21 — Aprendizaje de políticas óptimas
// Fuente: 02_monografia/.../capitulos/cap11_policy_learning.typ
// Plan detallado: PLAN_SPRINT_DIAPOSITIVAS.md §3, "Cap. 21"
// Sesión S22 · Lab L22 · Entrega: A4 arranca · Variante A · ★ camino crítico
// =============================================================================
#import "../plantilla_monografia.typ": *

#show: cap-theme

#cap-init(num: 21, titulo: "Aprendizaje de políticas óptimas",
  parte: "V", sesion: "S22", variant: "A", critico: true)

#cap-progreso-curso(cap-actual: 21)
#cap-portada(num: 21, titulo: "Aprendizaje de políticas óptimas",
  parte: "V", sesion: "S22", variant: "A", critico: true)

#cap-roadmap(
  objetivos: (
    [Formalizar policy value y welfare regret.],
    [Atribuir correctamente EWM (Kitagawa-Tetenov) vs. su extensión con nuisance de ML
     (Athey-Wager).],
    [Construir un policy tree con restricción presupuestaria.],
  ),
  agenda: (
    [Presupuesto para 30% de la población, ¿a quién tratar?],
    [Policy value y política óptima $pi^*(x)=bold(1){tau(x)>0}$],
    [EWM: regret sobre VC-dimensión finita],
    [Extensión con nuisance de ML (Athey & Wager)],
    [DGP sintético: targeting vs. aleatorio vs. tratar a todos],
  ),
  lectura: "Cap. 21 — Policy learning (@cap-policy-learning)",
  lab: "L22", entrega: "A4 arranca",
)

#cap-motivacion(
  problema: "Programa de capacitación laboral, \$1000/hogar, cubre solo 30% de la
    población. El CATE varía ampliamente: \$2500 en algunos hogares, ~0 en otros.",
  gancho: "¿Qué regla de asignación, dada una restricción presupuestaria, maximiza el
    bienestar agregado?",
  caso: "gov_transfers — DGP SINTÉTICO (advertencia del capítulo: covariables reales,
    tratamiento y resultado simulados para poder medir el regret).",
)

#cap-definicion(
  titulo-def: "Policy value y regret",
  cuerpo: "V(π)=E[Y(π(X))]=E[μ0(X)+π(X)τ(X)]. Política óptima π*(x)=1{τ(x)>0}.
    Regret(π̂)=V(π*)−V(π̂)=E[(π*(X)−π̂(X))τ(X)].",
)

// Los dos teoremas del capitulo -- la correccion mas importante: NO son el mismo
// resultado y atribuirlos mal es el error central de la version anterior.
#cap-teorema(
  titulo: "EWM (Kitagawa & Tetenov, 2018) vs. su extensión (Athey & Wager, 2021)",
  enunciado: "EWM: sobre una clase Π de VC-dimensión finita, el regret contra la
    MEJOR política de la clase (no la óptima sin restricciones) es O(√(VC(Π)/n)) —
    óptimo minimax, y NO requiere estimar bien el CATE. Athey & Wager EXTIENDEN esto
    al caso con nuisance estimados por ML: si el policy value se construye con el
    score doblemente robusto y cross-fitting, la tasa se conserva porque el error de
    los nuisance entra solo a segundo orden.",
)

#cap-demostracion(pasos: (
  [El regret de EWM se mide contra $max_(pi in Pi) V(pi)$, no contra $pi^*$ sin
   restricciones — el error de aproximación de la clase no desaparece con más datos.],
  [Athey & Wager aplican la misma estructura de DML (ortogonalidad + cross-fitting) al
   problema de OPTIMIZACIÓN sobre una clase de políticas, no solo a la estimación de
   un escalar.],
  [Consecuencia práctica: un CATE con RMSE alto puede seguir dando una política casi
   óptima — "el CATE es malo" y "la política es buena" no son afirmaciones
   contradictorias.],
))

// C9 (Etapa 2) -- EIF del policy value: normalidad asintotica del estimador DR
// de V(pi) y un test formal para comparar dos politicas, no solo reportar cada
// welfare por separado. Conecta con la tabla de score canonico del Cap. 10.
#cap-teorema(
  titulo: "Inferencia sobre el policy value (EIF)",
  enunciado: "La efficient influence function de V(π) bajo no confusión y
    soporte común es ψπ(W) = μπ(X)(X) + 1{D=π(X)}/eπ(X)(X)·(Y−μπ(X)(X)) − V(π) —
    caso particular de la forma canónica del Cap. 10 (fila 'Policy value'). Por
    tanto √n(V̂(π)−V(π))→N(0,E[ψπ²]), y la comparación de dos políticas
    candidatas π̂A, π̂B sobre el mismo hold-out usa el test
    z=(V̂(π̂A)−V̂(π̂B))/√(SE²A+SE²B−2·Cov), con varianzas estimadas por la
    influence function de cada una sobre las mismas observaciones. No basta con
    reportar cada welfare puntual con su propio IC — este es el test que falta
    para decidir si una política domina a otra.",
)

#cap-interactivo(
  tipo: "Conceptual",
  pregunta: "Si la curva de targeting NO se separa de la aleatoria, ¿cuál es la
    política óptima? (Tratar a todos o a nadie según el signo del ATE — no hay
    heterogeneidad accionable.)",
)

#cap-codigo-parte(
  titulo: "Policy tree con restricción presupuestaria — parte 1",
  snippet: "import numpy as np\n"
    + "import pandas as pd\n"
    + "from econml.dml import CausalForestDML\n"
    + "from econml.policy import PolicyTree\n"
    + "from sklearn.ensemble import GradientBoostingRegressor, GradientBoostingClassifier\n"
    + "from sklearn.linear_model import LogisticRegression\n"
    + "from sklearn.model_selection import train_test_split\n\n"
    + "# DGP SINTETICO: X reales (gov_transfers); D/tau/Y simulados para medir regret\n"
    + "df = pd.read_csv('../data/datasets/real/public_causaldata/gov_transfers/data.csv')\n"
    + "rng = np.random.default_rng(42)\n"
    + "X = df.select_dtypes(include=[np.number]).dropna(axis=1).values[:len(df)][:, :10]\n"
    + "D = rng.binomial(1, 0.5, len(df))         # asignacion aleatoria SIMULADA\n"
    + "tau_true = 2 * X[:, 0] + X[:, 1]          # CATE verdadero SIMULADO\n"
    + "Y = X[:, 2] + D * tau_true + rng.standard_normal(len(df))\n"
    + "X_tr, X_te, Y_tr, Y_te, D_tr, D_te, tau_te = train_test_split(\n"
    + "    X, Y, D, tau_true, test_size=0.3, random_state=42)\n\n"
    + "# CATE y policy tree se aprenden SOLO en train\n"
    + "cf = CausalForestDML(\n"
    + "    model_y=GradientBoostingRegressor(n_estimators=200, random_state=42),\n"
    + "    model_t=GradientBoostingClassifier(n_estimators=200, random_state=42),\n"
    + "    discrete_treatment=True, n_estimators=400, min_samples_leaf=20,\n"
    + "    cv=5, random_state=42).fit(Y_tr, D_tr, X=X_tr)\n"
    + "policy = PolicyTree(max_depth=3, min_samples_leaf=50, random_state=42)\n"
    + "policy.fit(X_tr, cf.effect(X_tr))\n\n"
    + "# Evaluacion en hold-out con ground truth sintetico\n"
    + "pi_te = policy.predict(X_te).astype(int)\n"
    + "welfare = tau_te[pi_te == 1].mean() * pi_te.mean()\n"
    + "print(f\"Welfare hold-out: {welfare:.4f} | Fraccion tratada: {pi_te.mean():.3f}\")\n\n"
    + "# IC del policy value via EIF\n"
    + "e_hat = LogisticRegression(max_iter=1000).fit(X_tr, D_tr).predict_proba(X_te)[:, 1]\n"
    + "mu_pi = np.where(pi_te == 1, cf.effect(X_te), 0.0)\n"
    + "psi = mu_pi + pi_te * (Y_te - mu_pi) / np.clip(e_hat, 0.01, 0.99) - welfare\n"
    + "print(f\"IC 95% policy value: {welfare:.4f} +/- {1.96 * psi.std(ddof=1) / np.sqrt(len(Y_te)):.4f}\")",
)
#cap-codigo-parte(
  titulo: "Restricción presupuestaria — parte 2",
  snippet: "# Restriccion: tratar maximo al 30% con mayor CATE\n"
    + "cate = cf.effect(X)                  # CATE estimado sobre toda la muestra\n"
    + "threshold = np.quantile(cate, 0.70)  # cuantil 70% = top 30%\n"
    + "pi_budget = (cate > threshold).astype(int)\n"
    + "welfare_budget = cate[pi_budget == 1].mean() * pi_budget.mean()\n"
    + "print(f\"Welfare con restriccion presupuestaria (30%): {welfare_budget:.4f}\")\n"
    + "print(f\"Welfare de tratar a todos: {cate.mean():.4f}\")\n"
    + "print(f\"Welfare de no tratar a nadie: 0.0\")",
)

#cap-caso-resolucion(
  titulo: "Targeting vs. aleatorio vs. tratar a todos",
  contexto: "gov_transfers (covariables reales, D/Y/τ simulados). Presupuesto: 30% de
    la población.",
  resultado: "Targeting por CATE obtiene welfare ~3× mayor que aleatorio al mismo
    presupuesto.",
  interpretacion: "Que la curva domine en todo el rango es mecánico si τ̂ ordena mejor
    que el azar — lo informativo sería lo contrario: si NO se separa, no hay
    heterogeneidad accionable.",
)

#cap-mapeo-pch-activo(
  nivel: "L2 (decisión basada en efecto, no en riesgo)",
  metrica: "V(π), regret sobre clase Π; IC vía EIF para comparar dos políticas",
  pregunta-activa: "Si solo predijéramos quién tiene mayor Y esperado sin tratamiento,
    ¿la asignación coincidiría con π*(x)=1{τ(x)>0}? ¿Por qué no en general?",
)

#cap-errores-transiciones(
  errores: (
    ("crítico", [Evaluar el policy value in-sample: welfare optimista por
      overfitting — usar siempre hold-out.]),
    ("advertencia", [Ignorar equidad: auditar la distribución demográfica de los
      tratados.]),
    ("advertencia", [CATE mal calibrado produce un umbral de tratamiento
      incorrecto.]),
  ),
  conexiones: "El @cap-decisiones-estructurales generaliza este marco a acciones no
    binarias y a criterios de decisión bajo identificación parcial.",
)

#cap-discusion-ejercicio(
  pregunta: "El Cap. 21 es un caso particular del marco de decisiones estructurales
    del Cap. 25 — identifique explícitamente cuál es el conjunto de acciones $cal(D)$
    y cuál la utilidad $U$ en este capítulo.",
  ejercicio: "Compare tres políticas: tratar a todos, aleatorio 30%, top 30% por CATE
    estimado. ¿En cuánto mejora el welfare?",
)

#cap-cierre-narrativo(
  resumen: (
    [Policy value y regret formalizan "a quién tratar" bajo presupuesto.],
    [EWM (Kitagawa-Tetenov) da la cota de regret; Athey-Wager la extienden con
     nuisance de ML.],
    [Un CATE mediocre puede seguir dando una política casi óptima — son preguntas
     distintas.],
  ),
  refs: (
    [Kitagawa & Tetenov (2018), Empirical Welfare Maximization],
    [Athey & Wager (2021), policy learning con nuisance de ML],
  ),
  transicion: "Cap. 22 — Uplift modeling y targeting económico",
  gancho: "Policy learning decide a quién; en marketing y programas sociales la
    pregunta se vuelve con qué acción, entre varias con costos distintos.",
)
