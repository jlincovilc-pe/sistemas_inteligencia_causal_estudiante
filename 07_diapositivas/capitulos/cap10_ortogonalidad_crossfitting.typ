// =============================================================================
// Diapositivas · Capítulo 10 — Ortogonalidad de Neyman, cross-fitting e
// influence functions
// Fuente: 02_monografia/.../capitulos/cap03_ortogonalidad_crossfitting.typ
// Plan detallado: PLAN_SPRINT_DIAPOSITIVAS.md §3, "Cap. 10"
// Sesión S9 · Lab L09 · Entrega: A2 · Variante A · ★ camino crítico
// =============================================================================
#import "../plantilla_monografia.typ": *

#show: cap-theme

#cap-init(num: 10, titulo: "Ortogonalidad de Neyman, cross-fitting e influence functions",
  parte: "II", sesion: "S9", variant: "A", critico: true)

#cap-progreso-curso(cap-actual: 10)
#cap-portada(num: 10, titulo: "Ortogonalidad de Neyman, cross-fitting e influence functions",
  parte: "II", sesion: "S9", variant: "A", critico: true)

#cap-roadmap(
  objetivos: (
    [Explicar el "doble sesgo" de los enfoques naïve al enchufar ML en una fórmula
     causal.],
    [Enunciar la ortogonalidad de Neyman y por qué reduce el error de los nuisance a
     segundo orden.],
    [Describir qué hace el cross-fitting que la ortogonalidad sola no hace.],
  ),
  agenda: (
    [El problema del doble sesgo],
    [Ortogonalidad de Neyman: definición y score de Robinson],
    [Teorema central de DML],
    [El rol del cross-fitting],
    [DML manual con Monte Carlo],
  ),
  lectura: "Cap. 10 — Ortogonalidad (@cap-ortogonalidad)",
  lab: "L09", entrega: "A2",
)

#cap-motivacion(
  problema: "5000 firmas, 200 covariables, asignación no aleatoria de una reforma
    tributaria. \"Enchufar\" estimadores de ML en una fórmula causal estándar no da
    inferencia válida: los errores de $hat(mu)_d$ y $hat(e)$ contaminan la estimación
    en primer orden.",
  gancho: "Bosques aleatorios tienen tasa a_n = n^(-2/5) — mucho más lenta que la
    n^(-1/2) que la inferencia clásica necesita.",
  caso: "Consultora evaluando efecto de reforma tributaria sobre inversión
    empresarial.",
)

#cap-glosario(terminos: (
  ([g0(X), m0(X)], [outcome regression y propensity function en el modelo PLR.]),
  ([Score ortogonal], [Derivada de Gateaux respecto a los nuisance = 0 en el valor
    verdadero.]),
  ([Cross-fitting], [Estimar los nuisance en folds distintos de donde se evalúa el
    score.]),
))

#cap-definicion(
  titulo-def: "Score ortogonal de Neyman",
  cuerpo: "Un score ψ(W,θ,η) es ortogonal de Neyman respecto a η en (θ0,η0) si la
    derivada de Gateaux respecto a η se anula para toda perturbación r.",
  eq: $partial_eta E[psi(W,theta_0,eta)]|_(eta=eta_0) [r] = 0$,
)

#cap-supuestos(supuestos: (
  ([E\[ε\|D,X\]=0], [g0 correctamente especificado], [Residuo del outcome ortogonal a D,X]),
  ([E\[v\|X\]=0], [m0 correctamente especificado], [Residuo del tratamiento ortogonal a X]),
  ([√n·a_n²→0], [El sesgo de 2.º orden desaparece], [Verificar tasa del learner elegido]),
))

#cap-teorema(
  titulo: "Teorema central de DML (Chernozhukov et al., 2018)",
  enunciado: "Si η̂0 se estima con ‖η̂0−η0‖=O_p(a_n), √n·a_n²→0, y θ̂ resuelve la
    ecuación de momento ortogonal con cross-fitting, entonces
    √n(θ̂−θ0) →^d N(0,σ²). La magia: NO se necesita estimar η a tasa √n — basta una
    tasa más lenta con a_n²=o(n^(-1/2)).",
)

// C1 (Etapa 2) -- tabla del score ortogonal canonico: PLR/IRM/DR/R/PLIV/policy
// value son instancias de un mismo psi(W,theta,eta). Conecta Caps. 10, 11, 12,
// 17 y 21 en una sola diapositiva.
#slide(title: [El score ortogonal canónico])[
  #text(fill: texto, size: 10.5pt)[Seis estimandos que el curso presenta como
    "distintos" son, en realidad, instancias de un único $psi(W,theta,eta)$ con
    $E[psi(W,theta_0,eta_0)]=0$ y ortogonalidad respecto a $eta$. Lo que cambia
    entre capítulos es $psi$ y el estimando — no el aparato de inferencia
    (cross-fitting, tasa $sqrt(n) a_n^2 -> 0$, error estándar vía influence
    function).]
  #v(0.3em)
  #set text(size: sz-table)
  #table(
    columns: (1.15fr, 1.7fr, 0.75fr),
    align: (left + top, left + top, left + top),
    stroke: 0.4pt + borde,
    fill: (_, y) => if y == 0 { navy } else if calc.odd(y) { light } else { white },
    table.header(
      text(fill: white, weight: "bold", size: 9.5pt)[Estimando],
      text(fill: white, weight: "bold", size: 9.5pt)[$psi(W,theta,eta)$],
      text(fill: white, weight: "bold", size: 9.5pt)[$eta$],
    ),
    text(fill: navy, weight: "bold", size: 8.5pt)[PLR / ATE (Cap. 11)],
      text(size: 8.5pt)[$(D-m(X))(Y-l(X)-theta(D-m(X)))$], text(size: 8.5pt)[$(l,m)$],
    text(fill: navy, weight: "bold", size: 8.5pt)[ATE bajo IRM (Cap. 11)],
      text(size: 8.5pt)[$mu(1,X)-mu(0,X)+(D(Y-mu(1,X)))/e(X)-((1-D)(Y-mu(0,X)))/(1-e(X))-theta$],
      text(size: 8.5pt)[$(mu,e)$],
    text(fill: navy, weight: "bold", size: 8.5pt)[CATE, DR-learner (Cap. 12)],
      text(size: 8.5pt)[$Gamma_i$ = score IRM antes de promediar], text(size: 8.5pt)[$(mu,e)$],
    text(fill: navy, weight: "bold", size: 8.5pt)[CATE, R-learner (Cap. 12)],
      text(size: 8.5pt)[$[(Y-m_Y (X))-tau(X)(D-e(X))]^2$], text(size: 8.5pt)[$(m_Y,e)$],
    text(fill: navy, weight: "bold", size: 8.5pt)[PLIV (Cap. 17)],
      text(size: 8.5pt)[$(Z-r(X))(Y-g(X)-theta D)$], text(size: 8.5pt)[$(g,r,m)$],
    text(fill: navy, weight: "bold", size: 8.5pt)[Policy value (Cap. 21)],
      text(size: 8.5pt)[$mu_(pi(X))(X)+(bold(1){D=pi(X)})/(e_(pi(X))(X))(Y-mu_(pi(X))(X))-V(pi)$],
      text(size: 8.5pt)[$(mu,e)$],
  )
  #v(0.2em)
  #text(fill: muted, size: 9pt, style: "italic")[Ver Cap. 10, tabla del score
    canónico — se cita de nuevo en los Caps. 11, 12, 17 y 21 en vez de
    repetirla.]
]

#cap-demostracion(pasos: (
  [Descomponer √n(θ̂−θ0) en: (a) término i.i.d. de varianza — sobrevive y fija σ²;
   (b) proceso empírico — neutralizado por cross-fitting, O_p(a_n); (c) sesgo de 2.º
   orden — neutralizado por ortogonalidad, O_p(√n·a_n²).],
  [(b): como η̂ se estima fuera del fold de evaluación, el sumando es i.i.d.
   condicional a la muestra auxiliar — sin esto, se necesitarían condiciones de
   entropía que el ML moderno no satisface.],
  [(c): Taylor de 2.º orden en η alrededor de η0 — el término de 1.er orden se anula
   exactamente por ortogonalidad.],
  [Condiciones completas (Chernozhukov et al. 2018, Teorema 3.1): (C1) ortogonalidad;
   (C2) identificabilidad local $abs(E[partial_theta psi]) >= c > 0$; (C3) tasa de
   nuisance $sqrt(n) a_n^2 -> 0$; (C4) momentos acotados. Dos variantes de agregación
   por fold: *DML1* (mediana de $hat(theta)_k$) vs. *DML2* (promedio ponderado,
   recomendada, con *repeated cross-fitting* $R=5$–10 para reducir la varianza de
   partición).],
))

#cap-interactivo(
  tipo: "Conceptual",
  pregunta: "Si se estimó l0(X)=E[Y\|X], ¿por qué el score correcto es
    (D−m)(Y−l−θ(D−m)) y no (D−m)(Y−g−θD)? — la distinción Robinson vs. forma
    estructural.",
)

#cap-codigo-parte(
  titulo: "DML manual para PLR — parte 1",
  snippet: "import numpy as np\n"
    + "from sklearn.ensemble import RandomForestRegressor\n"
    + "from sklearn.model_selection import KFold\n\n"
    + "# DML para PLR: cross-fitting K-fold con score de Robinson\n"
    + "def dml_plr_manual(Y, D, X, n_folds=5, learner=None):\n"
    + "    if learner is None:\n"
    + "        learner = lambda: RandomForestRegressor(n_estimators=100, min_samples_leaf=20, random_state=42)\n"
    + "    n = len(Y)\n"
    + "    l_hat, m_hat = np.zeros(n), np.zeros(n)  # E[Y|X], E[D|X]\n"
    + "    kf = KFold(n_splits=n_folds, shuffle=True, random_state=42)\n"
    + "    for tr, te in kf.split(X):\n"
    + "        l_hat[te] = learner().fit(X[tr], Y[tr]).predict(X[te])\n"
    + "        m_hat[te] = learner().fit(X[tr], D[tr]).predict(X[te])\n"
    + "    v_hat = D - m_hat          # residuos Robinson del tratamiento\n"
    + "    u_hat = Y - l_hat          # residuos del outcome\n"
    + "    den = np.mean(v_hat * v_hat)\n"
    + "    theta_hat = np.mean(v_hat * u_hat) / den\n"
    + "    psi = v_hat * (u_hat - theta_hat * v_hat) / den  # influence function\n"
    + "    se = np.sqrt(np.mean(psi ** 2) / n)\n"
    + "    return theta_hat, se",
)
#cap-codigo-parte(
  titulo: "DML manual para PLR — parte 2 (Monte Carlo)",
  snippet: "# DGP sintético con confusores de alta dimensión\n"
    + "def make_dgp(n=2000, p=50, theta=2.0, seed=0):\n"
    + "    rng = np.random.default_rng(seed)\n"
    + "    X = rng.standard_normal((n, p))\n"
    + "    g0 = X[:, 0] + 0.5 * X[:, 1]**2 - X[:, 2] * X[:, 3]\n"
    + "    m0 = 0.5 + 0.3 * np.tanh(X[:, 0] + X[:, 4])\n"
    + "    D = m0 + rng.standard_normal(n) * 0.5\n"
    + "    Y = theta * D + g0 + rng.standard_normal(n)\n"
    + "    return Y, D, X\n\n"
    + "# Monte Carlo: 200 réplicas\n"
    + "ests, ses = [], []\n"
    + "for b in range(200):\n"
    + "    Y, D, X = make_dgp(n=2000, p=50, theta=2.0, seed=b)\n"
    + "    th, se = dml_plr_manual(Y, D, X)\n"
    + "    ests.append(th); ses.append(se)\n"
    + "ests = np.array(ests); ses = np.array(ses)\n"
    + "print(f\"Sesgo: {ests.mean() - 2.0:.4f}\")\n"
    + "print(f\"Cobertura 95%: {np.mean(np.abs(ests - 2.0) < 1.96*ses):.3f}\")",
  salida: "theta verdadero = 2.0\nSesgo: ~0.00\nCobertura 95%: 0.94-0.96",
  invariante: "# assert 0.90 <= cobertura <= 0.98",
)

#cap-caso-resolucion(
  titulo: "NSW Lalonde",
  contexto: "Efecto del programa de capacitación sobre ingresos 1978 (re78).",
  resultado: "ATE ≈ \$1,600, IC 95% [\$800, \$2,400].",
  interpretacion: "Consistente con la estimación clásica de Dehejia & Wahba por
    matching.",
)

#cap-mapeo-pch-activo(
  nivel: "L2 (intervención) — ATE identificado bajo no confusión condicional",
  metrica: "θ0 con √n(θ̂−θ0)→N(0,σ²) — ver tabla de score canónico (6 instancias)",
  pregunta-activa: "¿Por qué un bosque aleatorio con tasa n^(-2/5) puede seguir dando
    inferencia válida sobre θ0 pese a NO tener tasa √n para η0?",
)

#cap-errores-transiciones(
  errores: (
    ("crítico", [Omitir cross-fitting: evaluar el score en la misma muestra donde se
      estimaron los nuisance produce overfitting bias y IC demasiado estrechos.]),
    ("advertencia", [Usar K=1 (single sample splitting): desperdicia información,
      estimación ineficiente.]),
    ("advertencia", [Mezclar la forma estructural g0 con la condicional l0 — rompe la
      ortogonalidad respecto de m(X).]),
  ),
  conexiones: "El Cap. 11 aplica exactamente este aparato a PLR e IRM con librerías
    reales (DoubleML, econml).",
)

#cap-discusion-ejercicio(
  pregunta: "Compare DML con y sin cross-fitting sobre el mismo Monte Carlo. ¿En
    cuánto se degrada la cobertura sin cross-fitting?",
  ejercicio: "Construya un DGP donde ĝ tenga tasa a_n=n^(-1/4) (más lento que n^(-2/5)).
    Verifique empíricamente que la cobertura de DML se degrada al no satisfacerse
    √n·a_n²→0.",
)

#cap-cierre-narrativo(
  resumen: (
    [Enchufar ML sin ortogonalizar contamina la inferencia en 1.er orden — el
     "doble sesgo".],
    [Ortogonalidad + cross-fitting neutralizan, respectivamente, el sesgo de 2.º orden
     y el sesgo de sobreajuste.],
    [El score de Robinson es la pieza que reaparece en meta-learners (Cap. 12) y
     paneles (Cap. 17).],
  ),
  refs: (
    [Chernozhukov et al. (2018), "Double/Debiased ML"],
    [Robinson (1988), score de residuo-contra-residuo],
    [Neyman (1959), test C(α) y ortogonalidad],
  ),
  transicion: "Cap. 11 — Double/Debiased Machine Learning",
  gancho: "El score ortogonal y el cross-fitting son el motor; ahora se monta en los
    dos modelos que se usan en la práctica —PLR e IRM— con librerías reales.",
)
