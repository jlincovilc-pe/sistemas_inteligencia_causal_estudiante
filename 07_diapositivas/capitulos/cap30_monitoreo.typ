// =============================================================================
// Diapositivas · Capítulo 30 — Monitoreo de supuestos causales en producción
// Fuente: 02_monografia/.../capitulos/cap15b_monitoreo.typ
// Plan detallado: PLAN_SPRINT_DIAPOSITIVAS.md §3, "Cap. 30"
// Sesión S25 · Lab L25 · Entrega: B4 arranca · Variante B · ★ camino crítico
// =============================================================================
#import "../plantilla_monografia.typ": *

#show: cap-theme

#cap-init(num: 30, titulo: "Monitoreo de supuestos causales en producción",
  parte: "VIII", sesion: "S25", variant: "B", critico: true)

#cap-progreso-curso(cap-actual: 30)
#cap-portada(num: 30, titulo: "Monitoreo de supuestos causales en producción",
  parte: "VIII", sesion: "S25", variant: "B", critico: true)

#cap-roadmap(
  objetivos: (
    [Distinguir monitoreo genérico de drift de monitoreo causal-aware.],
    [Implementar las 4 métricas del capítulo, en particular el drift del mecanismo de
     asignación.],
    [Interpretar el reporte en el orden correcto: temprano a tardío.],
  ),
  agenda: (
    [Un servicio puede responder normal con un efecto ya inválido],
    [Monitoreo genérico vs. causal-aware],
    [Las 4 métricas: PSI/ASMD, drift del mecanismo, F de instrumento, estabilidad],
    [Escenario clave: drift sin mover ninguna marginal],
  ),
  lectura: "Cap. 30 — Monitoreo (@cap-monitoreo-causal)",
  lab: "L25", entrega: "B4 arranca",
)

#cap-problema-diseno(
  decision: "Monitorear la validez de los supuestos causales, no solo la
    distribución de entradas y salidas.",
  alternativas: "Monitoreo genérico de ML (drift de inputs/outputs) vs.
    causal-aware (drift de identificación).",
  tradeoff: "Costo de cómputo del monitoreo adicional vs. riesgo de servir
    estimaciones inválidas sin saberlo.",
  stack: "scipy.stats, sklearn (LogisticRegression para propensity), Streamlit para
    el dashboard.",
  riesgo: "Que el servicio siga respondiendo con normalidad mientras el efecto que
    reporta ya no es válido.",
)

#cap-opciones-tradeoffs(opciones: (
  ([Monitoreo genérico], [KS univariado en covariables y/o predicciones. Barato, pero
    no detecta un cambio en la RELACIÓN entre covariables y tratamiento aunque
    ninguna marginal se mueva.]),
  ([Monitoreo causal-aware], [Reejecuta el chequeo de balance del Cap. 7, verifica
    soporte común, fuerza del instrumento. Más costoso, requiere el pipeline de
    estimación completo, no solo el servicio de predicción.]),
))

// Contenido central: 4 metricas, la mas importante es la (ii), drift del mecanismo
// de asignacion via AUC del propensity reestimado.
#cap-decision-referencia(
  decision: "Cuatro métricas: (i) drift marginal con PSI/ASMD, no solo KS; (ii) drift
    del MECANISMO DE ASIGNACIÓN vía AUC del propensity reestimado — detecta ruptura
    de identificación aunque NINGUNA marginal se mueva; (iii) F de primera etapa
    correcto (f_test sobre el instrumento, no el F global); (iv) estabilidad del
    efecto REESTIMADO vía contraste formal, no \"¿cae dentro del IC?\".",
  justificacion: "La no confusión no depende de la distribución marginal de cada
    covariable sino de la relación entre covariables y asignación — si esa relación
    cambia, el supuesto de identificación puede romperse sin ninguna señal marginal.",
)

#cap-codigo-parte(
  titulo: "drift_covariables y drift_mecanismo_asignacion",
  snippet: "import numpy as np, pandas as pd\n"
    + "from sklearn.linear_model import LogisticRegression\n"
    + "from sklearn.metrics import roc_auc_score\n"
    + "from sklearn.model_selection import cross_val_predict\n\n"
    + "# --- (i) Drift marginal de covariables: PSI + ASMD ---\n"
    + "def drift_covariables(df_train, df_rec, covariables, psi_bins=10):\n"
    + "    filas = []\n"
    + "    for c in covariables:\n"
    + "        a, b = df_train[c].dropna(), df_rec[c].dropna()\n"
    + "        s_pool = np.sqrt((a.var(ddof=1) + b.var(ddof=1)) / 2)\n"
    + "        asmd = abs(a.mean() - b.mean()) / s_pool if s_pool > 0 else 0.0\n"
    + "        # PSI sobre bins definidos por los cuantiles de ENTRENAMIENTO\n"
    + "        bordes = np.unique(np.quantile(a, np.linspace(0, 1, psi_bins + 1)))\n"
    + "        p = np.histogram(a, bins=bordes)[0] / len(a)\n"
    + "        q = np.histogram(b, bins=bordes)[0] / len(b)\n"
    + "        p, q = np.clip(p, 1e-6, None), np.clip(q, 1e-6, None)\n"
    + "        psi = float(((p - q) * np.log(p / q)).sum())\n"
    + "        filas.append({'covariable': c, 'asmd': asmd, 'psi': psi,\n"
    + "                       'alerta': (psi > 0.25) or (asmd > 0.25)})\n"
    + "    return pd.DataFrame(filas).sort_values('psi', ascending=False)\n\n"
    + "# --- (ii) Drift de la relacion X -> D (lo que rompe la identificacion) ---\n"
    + "def drift_mecanismo_asignacion(df_train, df_rec, covariables, tratamiento, tolerancia=0.05):\n"
    + "    def auc(df):\n"
    + "        p = cross_val_predict(LogisticRegression(max_iter=1000), df[covariables],\n"
    + "                              df[tratamiento], cv=5, method='predict_proba')[:, 1]\n"
    + "        return roc_auc_score(df[tratamiento], p)\n"
    + "    auc_train, auc_rec = auc(df_train), auc(df_rec)\n"
    + "    return {'auc_entrenamiento': auc_train, 'auc_reciente': auc_rec,\n"
    + "            'delta_auc': auc_rec - auc_train,\n"
    + "            'alerta': abs(auc_rec - auc_train) > tolerancia}",
)
#cap-codigo-parte(
  titulo: "fuerza_instrumento y estabilidad_efecto",
  snippet: "import numpy as np\n"
    + "import statsmodels.api as sm\n"
    + "from scipy import stats\n\n"
    + "# --- (iii) Fuerza del instrumento: F de PRIMERA ETAPA ---\n"
    + "def fuerza_instrumento(df_rec, instrumento, tratamiento, covariables, umbral_f=10):\n"
    + "    # Doble umbral (Etapa 2): F > 10 sano; F en (5, 10) atencion, reportar\n"
    + "    # tambien el IC de Anderson-Rubin (Cap. 17) junto al de Wald; F < 5 alerta\n"
    + "    X = sm.add_constant(df_rec[[instrumento] + covariables])\n"
    + "    modelo = sm.OLS(df_rec[tratamiento], X).fit()\n"
    + "    restriccion = np.zeros((1, X.shape[1]))\n"
    + "    restriccion[0, list(X.columns).index(instrumento)] = 1\n"
    + "    f_stat = float(modelo.f_test(restriccion).fvalue)  # sobre el instrumento, NO el F global\n"
    + "    return {'f_primera_etapa': f_stat, 'alerta_debil': f_stat < umbral_f}\n\n"
    + "# --- (iv) Estabilidad del efecto: contraste formal entre ventanas ---\n"
    + "def estabilidad_efecto(reestimar, df_rec, theta_orig, se_orig, alpha=0.05):\n"
    + "    theta_rec, se_rec = reestimar(df_rec)  # pipeline completo del Cap. 11\n"
    + "    z_estabilidad = abs(theta_rec - theta_orig) / np.sqrt(se_orig**2 + se_rec**2)\n"
    + "    p_estabilidad = 2 * (1 - stats.norm.cdf(z_estabilidad))\n"
    + "    print(f'Z: {z_estabilidad:.2f}  P-valor: {p_estabilidad:.4f}')\n"
    + "    return {'theta_original': theta_orig, 'theta_reciente': theta_rec,\n"
    + "            'z': z_estabilidad, 'p_valor': p_estabilidad,\n"
    + "            'alerta': p_estabilidad < alpha}",
)

#cap-monorepo(texto-monorepo: "04_notebooks_produccion_hf/B4_monitoring_dashboard/
  (Streamlit; KS de covariables, tasa de tratamiento, proxy de estabilidad). Labs
  L25 y L27 (reentrenar vs alertar). Humo: grade_b4.py. El monitoreo del curso es
  docente y simulado sobre el benchmark; en un sistema real se conecta al tráfico del
  endpoint B1.")

#cap-caso-resolucion(
  titulo: "El escenario que define el capítulo",
  contexto: "Dos escenarios del Notebook B4: (1) drift gradual de covariables —
    alerta temprana en (i); (2) drift del mecanismo de asignación con marginales
    IDÉNTICAS.",
  resultado: "En el escenario (2), drift_covariables no reporta nada —
    correctamente, porque nada marginal cambió— y solo drift_mecanismo_asignacion lo
    detecta.",
  interpretacion: "Es la demostración práctica de por qué un monitoreo de MLOps
    genérico, por completo que sea en su terreno, no basta para un sistema causal.",
)

#cap-mapeo-pch-activo(
  nivel: "L2 continuo (monitoreo, no una estimación nueva)",
  metrica: "PSI/ASMD, AUC del propensity, F de primera etapa, contraste z de
    estabilidad",
  pregunta-activa: "Si drift_covariables no reporta alertas, ¿es seguro asumir que el
    supuesto de no confusión sigue vigente?",
)

#cap-checklist-alertas(items: (
  [El sistema solo monitorea si el endpoint responde, no la validez de lo que
   responde.],
  [El chequeo de balance del entrenamiento nunca se vuelve a ejecutar sobre datos de
   producción.],
  [No existe una ventana de referencia fija — cada comparación usa un punto de
   referencia distinto.],
  [Las alertas se generan pero nadie las revisa — no hay proceso definido para el
   estado "requiere atención".],
))

#cap-interactivo(
  tipo: "Aplicado",
  pregunta: "Ordene las 4 métricas de más temprana a más tardía como señal de
    alerta. ¿Qué pasa si un sistema solo monitorea la más tardía?",
)

#cap-discusion-ejercicio(
  pregunta: "Proponga un escenario donde la regla de asignación cambie sin mover
    ninguna distribución marginal de covariables. ¿Qué supuesto de identificación se
    viola?",
  ejercicio: "Compare, sobre una ventana con drift leve, el veredicto del test
    formal de estabilidad del efecto con el criterio ingenuo (¿cae dentro del IC
    original?). Muestre un caso en que difieran.",
)

#cap-cierre-narrativo(
  resumen: (
    [Monitoreo genérico vigila datos; monitoreo causal-aware vigila el mecanismo de
     identificación.],
    [PSI/ASMD reemplazan al KS solo; el drift del propensity detecta lo que ninguna
     marginal revela.],
    [El contraste formal z, no la inspección visual del IC, decide si el efecto
     cambió.],
  ),
  refs: (
    [Kästner et al. (2024) / Huyen (2022), Cap. 8, drift genérico],
    [Stock & Yogo (2005), umbral F>10],
    [Rubin (2001), criterios de balance (ASMD)],
  ),
  transicion: "Cap. 31 — Aprendizaje continuo y panorama de Reinforcement Learning
    causal",
  gancho: "El reporte de monitoreo puede marcar requiere_atencion — ¿qué se hace
    entonces?",
)
