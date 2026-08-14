// =============================================================================
// Diapositivas · Capítulo 22 — Uplift modeling y targeting económico
// Fuente: 02_monografia/.../capitulos/cap12_uplift_targeting.typ
// Plan detallado: PLAN_SPRINT_DIAPOSITIVAS.md §3, "Cap. 22"
// Sesión S23 · Lab L23 · Entrega: A4 + B3 · Variante A · ★ camino crítico
// =============================================================================
#import "../plantilla_monografia.typ": *

#show: cap-theme

#cap-init(num: 22, titulo: "Uplift modeling y targeting económico",
  parte: "V", sesion: "S23", variant: "A", critico: true)

#cap-progreso-curso(cap-actual: 22)
#cap-portada(num: 22, titulo: "Uplift modeling y targeting económico",
  parte: "V", sesion: "S23", variant: "A", critico: true)

#cap-roadmap(
  objetivos: (
    [Distinguir cuándo basta el ranking de cuándo se necesita magnitud calibrada.],
    [Implementar net score con presupuesto y múltiples tratamientos.],
    [Publicar la política en un Space de Hugging Face.],
  ),
  agenda: (
    [Telco: SMS vs. llamada, presupuesto \$100,000],
    [Uplift = CATE, pero el foco es ranking + cost-effectiveness],
    [Qini/AUUC/coeficiente Qini],
    [Net score con costo sombra λ],
    [Un estimador de uplift POR ACCIÓN, no uno escalado],
  ),
  lectura: "Cap. 22 — Uplift (@cap-uplift-targeting)",
  lab: "L23", entrega: "A4 + B3",
)

#cap-motivacion(
  problema: "Telco: no hacer nada / SMS (\$0.5) / llamada (\$8). ¿A qué clientes
    aplicar cada acción, con presupuesto \$100,000?",
  gancho: "Ranking basta si la decisión es \"a quién tratar con presupuesto fijo\";
    magnitud calibrada es necesaria si la decisión es \"cuánto presupuesto\" o \"qué
    acción entre varias con costos distintos\".",
  caso: "Reducción de churn: SMS vs. llamada personalizada.",
)

#cap-glosario(terminos: (
  ([Uplift], [Matemáticamente igual al CATE — el foco cambia a ranking y
    cost-effectiveness.]),
  ([AUUC], [Área bajo la curva uplift — depende de n y escala de Y.]),
  ([Coeficiente Qini], [AUUC normalizada — comparable entre datasets.]),
))

#cap-teorema(
  titulo: "Net score con costo sombra",
  enunciado: "π*(x)=argmax_k {τ_k(x)−λ*·c_k(x)}, donde λ* es el multiplicador de
    Lagrange (costo sombra) que agota el presupuesto B. Bisección sobre λ garantiza
    convergencia.",
)

// Contenido central corregido: no se puede derivar tau_llamada de tau_SMS escalando.
#cap-demostracion(pasos: (
  [Cada acción tiene su propio patrón de heterogeneidad — no existe forma de derivar
   $tau_"llamada" (x)$ a partir de $tau_"SMS" (x)$ escalándolo por un factor.],
  [Se necesita UN estimador por acción, cada uno contra el brazo de control sobre su
   propia submuestra — comparar SMS contra llamada directamente estimaría
   $tau_"llamada" - tau_"SMS"$, una pregunta distinta.],
  [El net score compara $tau_k (x) - lambda c_k (x)$ entre acciones: la llamada cara
   se asigna solo donde su uplift adicional justifica la diferencia de costo.],
))

#cap-interactivo(
  tipo: "Aplicado",
  pregunta: "Multiplicar uplift_call × 3 para simular otro tratamiento — ¿cambia el
    Qini de esa acción? ¿Cambia la asignación óptima? (Ranking invariante a escala;
    asignación NO.)",
)

#cap-codigo-parte(
  titulo: "Uplift multi-tratamiento — un estimador por acción",
  snippet: "import numpy as np\n"
    + "import pandas as pd\n"
    + "from xgboost import XGBRegressor\n"
    + "from causalml.inference.meta import BaseTRegressor\n"
    + "from causalml.metrics import qini_score\n\n"
    + "FEATURES = [f\"x{i}\" for i in range(8)]\n\n"
    + "def make_churn_data(n=5000, seed=42):\n"
    + "    \"\"\"DGP sintetico de churn con TRES brazos: control, SMS, llamada.\"\"\"\n"
    + "    rng = np.random.default_rng(seed)\n"
    + "    X = rng.uniform(-1, 1, (n, 8))\n"
    + "    arm = rng.choice([\"control\", \"sms\", \"call\"], size=n, p=[0.4, 0.3, 0.3])\n"
    + "    tau_sms = 0.06 - 0.05*X[:, 0] + 0.03*X[:, 1]   # uplift del SMS\n"
    + "    tau_call = 0.12 + 0.09*X[:, 1] - 0.02*X[:, 3]  # uplift de la llamada\n"
    + "    p = 0.45 + 0.08*X[:, 2] + (arm == \"sms\")*tau_sms + (arm == \"call\")*tau_call\n"
    + "    Y = (rng.uniform(size=n) < np.clip(p, 0, 1)).astype(int)\n"
    + "    df = pd.DataFrame(X, columns=FEATURES)\n"
    + "    df[\"y\"], df[\"arm\"] = Y, arm\n"
    + "    return df\n\n"
    + "df = make_churn_data(5000)\n\n"
    + "def uplift_por_accion(df, accion, features=FEATURES):\n"
    + "    \"\"\"Estima tau_accion(x) contra el brazo de control, no entre activos.\"\"\"\n"
    + "    sub = df[df[\"arm\"].isin([\"control\", accion])]\n"
    + "    m = BaseTRegressor(learner=XGBRegressor(max_depth=3, n_estimators=200))\n"
    + "    m.fit(sub[features].values, (sub[\"arm\"] == accion).astype(int).values, sub[\"y\"].values)\n"
    + "    return m.predict(df[features].values).ravel()   # sobre TODA la muestra\n\n"
    + "# Un estimador POR ACCION -> dos columnas de uplift, ambas estimadas\n"
    + "df[\"uplift_sms\"] = uplift_por_accion(df, \"sms\")\n"
    + "df[\"uplift_call\"] = uplift_por_accion(df, \"call\")\n\n"
    + "# Ranking por accion sobre su propia submuestra {control, accion}\n"
    + "for accion in [\"sms\", \"call\"]:\n"
    + "    sub = df[df[\"arm\"].isin([\"control\", accion])].copy()\n"
    + "    sub[\"treatment\"] = (sub[\"arm\"] == accion).astype(int)\n"
    + "    print(f\"{accion}: Qini = {qini_score(sub[['y', 'treatment', f'uplift_{accion}']])}\")",
)
#cap-codigo-parte(
  titulo: "Net score con bisección de λ",
  snippet: "# Costos unitarios y presupuesto de la campana\n"
    + "COSTOS = {\"nada\": 0.0, \"sms\": 0.5, \"call\": 8.0}\n"
    + "BUDGET = 100_000\n"
    + "n = len(df)\n\n"
    + "# Estrategias A y B: una sola accion, a los de mayor uplift\n"
    + "asig_a = np.full(n, \"nada\", dtype=object)\n"
    + "asig_a[df[\"uplift_sms\"].to_numpy().argsort()[::-1][:int(BUDGET / COSTOS[\"sms\"])]] = \"sms\"\n"
    + "asig_b = np.full(n, \"nada\", dtype=object)\n"
    + "asig_b[df[\"uplift_call\"].to_numpy().argsort()[::-1][:int(BUDGET / COSTOS[\"call\"])]] = \"call\"\n\n"
    + "# Estrategia C: net score con costo sombra — biseccion de lambda\n"
    + "def asignar_net_score(df, budget, lo=0.0, hi=1.0, tol=1e-4, max_iter=60):\n"
    + "    for _ in range(max_iter):\n"
    + "        lam = (lo + hi) / 2\n"
    + "        scores = np.column_stack([np.zeros(len(df)),                 # no hacer nada\n"
    + "                                  df[\"uplift_sms\"] - lam*COSTOS[\"sms\"],\n"
    + "                                  df[\"uplift_call\"] - lam*COSTOS[\"call\"]])\n"
    + "        asig = np.array([\"nada\", \"sms\", \"call\"], dtype=object)[scores.argmax(axis=1)]\n"
    + "        gasto = np.array([COSTOS[a] for a in asig]).sum()\n"
    + "        if abs(gasto - budget) < tol * budget:\n"
    + "            break\n"
    + "        lo, hi = (lam, hi) if gasto > budget else (lo, lam)\n"
    + "    return asig\n\n"
    + "asig_c = asignar_net_score(df, BUDGET)\n\n"
    + "def uplift_total(df, asig):\n"
    + "    u = np.where(asig == \"sms\", df[\"uplift_sms\"],\n"
    + "                 np.where(asig == \"call\", df[\"uplift_call\"], 0.0))\n"
    + "    return u.sum(), np.array([COSTOS[a] for a in asig]).sum()\n\n"
    + "for nombre, asig in [(\"A (solo SMS)\", asig_a), (\"B (solo llamadas)\", asig_b),\n"
    + "                     (\"C (net score, mixto)\", asig_c)]:\n"
    + "    u, g = uplift_total(df, asig)\n"
    + "    print(f\"{nombre:20s} uplift={u:8.1f} gasto={g:10.1f}\")",
)

#cap-caso-resolucion(
  titulo: "Costo-efectividad: SMS vs. llamada",
  contexto: "Presupuesto \$100,000. Costo SMS \$0.5, llamada \$8.",
  resultado: "La estrategia C (net score, mixta) domina a A y B por separado.",
  interpretacion: "C optimiza conjuntamente A QUIÉN y CON QUÉ ACCIÓN; A y B fijan la
    acción de antemano y solo optimizan a quién alcanzar.",
)

#cap-mapeo-pch-activo(
  nivel: "L2 heterogéneo, multi-tratamiento",
  metrica: "τ_k(x) por acción; Qini/AUUC; net score con λ*",
  pregunta-activa: "Si solo predijéramos qué clientes tienen mayor probabilidad de
    irse (riesgo), ¿coincidiría con a quién conviene enviar la llamada cara?",
)

#cap-errores-transiciones(
  errores: (
    ("crítico", [Multiplicar uplift ad hoc para inferir el efecto de otro tratamiento
      — cada acción necesita su propio estimador.]),
    ("advertencia", [Optimizar solo AUUC sin validar calibración: transformed
      outcome (Cap. 14) para magnitudes insesgadas.]),
    ("advertencia", [Medir costos incorrectamente o ignorar costos hundidos.]),
  ),
  conexiones: "Las mismas curvas Qini del Cap. 14 reaparecen aquí como criterio de
    evaluación de la POLÍTICA, no solo del estimador.",
)

#cap-discusion-ejercicio(
  pregunta: "¿En qué casos el uplift modeling es preferible al policy learning formal
    (Cap. 21)?",
  ejercicio: "Sobre el DGP de tres brazos, compare el uplift promedio de cada acción
    con el ranking que produce. Verifique que la acción con mayor efecto promedio no
    es necesariamente la que conviene asignar a cada cliente.",
)

#cap-cierre-narrativo(
  resumen: (
    [Ranking basta para "a quién"; magnitud calibrada es necesaria para "cuánto" o
     "qué acción".],
    [Cada tratamiento necesita su propio estimador de uplift — no se deriva
     escalando.],
    [Net score con costo sombra optimiza conjuntamente a quién y con qué acción
     tratar.],
  ),
  refs: (
    [Radcliffe (2007), curva Qini],
    [Rzepakowski & Jaroszewicz (2012), árboles de uplift multi-tratamiento],
    [Chen et al. (2020), causalml],
  ),
  transicion: "Cap. 23 — Explicación causal y equidad algorítmica (S19 en el orden
    real de enseñanza, ya cubierto antes en el libro)",
  gancho: "Con el CATE ya usado para decidir a quién y con qué acción tratar, falta
    preguntar si esa decisión se puede explicar del mismo modo que se calculó.",
)
