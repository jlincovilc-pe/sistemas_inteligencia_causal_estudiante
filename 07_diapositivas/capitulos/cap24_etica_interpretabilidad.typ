// =============================================================================
// Diapositivas · Capítulo 24 — Ética, interpretabilidad y comunicación de
// resultados
// Fuente: 02_monografia/.../capitulos/cap16_etica_interpretabilidad.typ
// Plan detallado: PLAN_SPRINT_DIAPOSITIVAS.md §3, "Cap. 24"
// Sesión S20 · Lab L20 · sin entrega · Variante A · ★ camino crítico
// =============================================================================
#import "../plantilla_monografia.typ": *

#show: cap-theme

#cap-init(num: 24, titulo: "Ética, interpretabilidad y comunicación de resultados",
  parte: "VI", sesion: "S20", variant: "A", critico: true)

#cap-progreso-curso(cap-actual: 24)
#cap-portada(num: 24, titulo: "Ética, interpretabilidad y comunicación de resultados",
  parte: "VI", sesion: "S20", variant: "A", critico: true)

#cap-roadmap(
  objetivos: (
    [Ubicar un criterio de equidad en su familia correcta (independencia/separación/
     suficiencia) y explicar por qué no pueden satisfacerse a la vez.],
    [Explicar SHAP sobre un sustituto del CATE, no sobre el modelo de outcome.],
    [Reportar resultados con IC correcto por subgrupo.],
  ),
  agenda: (
    [Un ministerio usa ML causal para focalizar un subsidio],
    [Tres familias: independencia, separación, suficiencia],
    [Teorema de incompatibilidad — el caso COMPAS],
    [SHAP: ¿sobre qué modelo interno?],
    [IC por subgrupo: t-test vs. influence function],
  ),
  lectura: "Cap. 24 — Ética e interpretabilidad (@cap-etica-interpretabilidad)",
  lab: "L20", entrega: "—",
)

#cap-motivacion(
  problema: "Un modelo de ML causal decide qué hogares reciben subsidio, entrenado
    sobre datos que reflejan desigualdades preexistentes. Puede perpetuar o amplificar
    esas desigualdades.",
  gancho: "La calidad técnica de un modelo causal no se mide solo en precisión
    estadística sino en sus consecuencias sociales.",
  caso: "gov_transfers: CATE rural 30% menor que urbano.",
)

#cap-definicion(
  titulo-def: "Tres familias canónicas de equidad",
  cuerpo: "Independencia (demographic parity): π(X)⊥G. Separación (equalized odds):
    π(X)⊥G|Y*. Suficiencia (calibración por grupo): Y*⊥G|π(X). Barocas, Hardt &
    Narayanan organizan toda la literatura de fair ML en estas tres.",
)

#cap-teorema(
  titulo: "Teorema de incompatibilidad",
  enunciado: "Salvo predicción perfecta o tasas base idénticas entre grupos, NO existe
    ninguna regla de decisión que satisfaga simultáneamente separación y suficiencia a
    la vez. El debate COMPAS (falsos positivos desiguales = injusto, bajo separación;
    calibrado por grupo = justo, bajo suficiencia) no se resuelve con más datos:
    ambas partes tenían razón bajo su propio criterio.",
)

#cap-demostracion(pasos: (
  [No hay una definición de equidad que se "active" en el pipeline — elegir un
   criterio es descartar los otros.],
  [Equidad EN EL EFECTO (equalized CATE) es una noción propia de este curso, no
   canónica: responde "¿quién se beneficia?", no "¿a quién se asigna?".],
  [Si el CATE es genuinamente menor en un grupo por razones estructurales, imponer
   equidad en el efecto no es posible ni deseable — la métrica hace visible la
   desigualdad, no la corrige por decreto.],
))

#cap-interactivo(
  tipo: "Conceptual",
  pregunta: "¿Por qué un t-test sobre los τ̂_i subestima la incertidumbre de la
    brecha de efecto entre grupos?",
)

// Contenido central corregido: SHAP sobre el modelo equivocado es el error mas
// grave y mas comun.
#cap-codigo-parte(
  titulo: "SHAP sobre el modelo equivocado (incorrecto) — parte 1",
  snippet: "import shap\n"
    + "import numpy as np\n"
    + "from econml.dml import CausalForestDML\n"
    + "from sklearn.ensemble import GradientBoostingRegressor, GradientBoostingClassifier\n\n"
    + "# Dataset simulado: mu0 depende de x1; tau = 2 + 3*x0 - 1.5*A\n"
    + "rng = np.random.default_rng(42)\n"
    + "X = rng.uniform(-1, 1, (5000, 5))\n"
    + "A = rng.binomial(1, 0.3, 5000)              # 30% es minoria\n"
    + "tau = 2 + 3*X[:, 0] - 1.5*A\n"
    + "e = 0.4 + 0.2*np.tanh(X[:, 0]) - 0.1*A\n"
    + "D = (rng.uniform(size=5000) < e).astype(int)\n"
    + "Y = X[:, 1] + D*tau + rng.standard_normal(5000)*0.5\n\n"
    + "cf = CausalForestDML(model_y=GradientBoostingRegressor(random_state=42),\n"
    + "                     model_t=GradientBoostingClassifier(random_state=42),\n"
    + "                     discrete_treatment=True, random_state=42, cv=5).fit(Y, D, X=X)\n"
    + "cate_hat = cf.effect(X)\n\n"
    + "# (a) INCORRECTO: SHAP sobre cf.model_y — explica que predice Y, NO el efecto\n"
    + "expl_y = shap.TreeExplainer(cf.model_y)\n"
    + "shap_y = expl_y.shap_values(X[:200])\n"
    + "# Solo para contrastar; no reportar esto como \"drivers del CATE\".",
  nota: "μ̂_Y, ê y τ̂ son tres modelos internos distintos — explicar el equivocado
    produce conclusiones sistemáticamente engañosas.",
)
#cap-codigo-parte(
  titulo: "SHAP sobre un sustituto del CATE (correcto) — parte 2",
  snippet: "import shap\n"
    + "import numpy as np\n"
    + "import pandas as pd\n"
    + "from sklearn.ensemble import RandomForestRegressor\n"
    + "from sklearn.model_selection import cross_val_score\n\n"
    + "# (b) CORRECTO: SHAP sobre un sustituto del CATE (usa X, cate_hat, shap_y de la parte 1)\n"
    + "surrogate = RandomForestRegressor(n_estimators=300, min_samples_leaf=20, random_state=42)\n"
    + "r2 = cross_val_score(surrogate, X, cate_hat, cv=5, scoring=\"r2\").mean()\n"
    + "surrogate.fit(X, cate_hat)\n"
    + "print(f\"Fidelidad del sustituto al CATE (R2 CV): {r2:.3f}\")\n"
    + "if r2 < 0.8:\n"
    + "    print(\"ADVERTENCIA: el sustituto no reproduce bien el CATE\")\n\n"
    + "expl_tau = shap.TreeExplainer(surrogate)\n"
    + "shap_tau = expl_tau.shap_values(X[:200])\n"
    + "shap.summary_plot(shap_tau, X[:200], feature_names=[f\"x{i}\" for i in range(5)], show=False)\n\n"
    + "# Contraste explicito de los dos rankings de importancia\n"
    + "imp_y = np.abs(shap_y).mean(axis=0)\n"
    + "imp_tau = np.abs(shap_tau).mean(axis=0)\n"
    + "pd.DataFrame({\"feature\": [f\"x{i}\" for i in range(5)],\n"
    + "              \"importancia_para_Y\": imp_y / imp_y.sum(),\n"
    + "              \"importancia_para_CATE\": imp_tau / imp_tau.sum()}\n"
    + "             ).sort_values(\"importancia_para_CATE\", ascending=False)",
  invariante: "# if r2 < 0.8: print('ADVERTENCIA: sustituto no reproduce el CATE')",
)

#cap-caso-resolucion(
  titulo: "gov_transfers: CATE rural 30% menor",
  contexto: "CausalForestDML, comparación urbano/rural.",
  resultado: "No es sesgo del modelo — es desigualdad estructural (falta de acceso a
    mercados).",
  interpretacion: "La recomendación NO es excluir hogares rurales (amplificaría la
    desigualdad) sino complementar con inversión en infraestructura.",
)

#cap-mapeo-pch-activo(
  nivel: "L1 (SHAP es asociativo) vs. L2 (el CATE que se está explicando)",
  metrica: "R² de fidelidad del sustituto; IC por subgrupo vía influence function",
  pregunta-activa: "Si SHAP sobre el modelo de outcome y SHAP sobre el sustituto del
    CATE dan rankings de importancia DISTINTOS, ¿cuál responde \"qué determina el
    efecto\"?",
)

#cap-errores-transiciones(
  errores: (
    ("crítico", [SHAP sobre el modelo equivocado: reportar los predictores de Y como
      si fueran los determinantes del efecto — error de categoría, no
      aproximación.]),
    ("crítico", [IC por subgrupo con t-test sobre los $hat(tau)_i$: ignora el error de
      estimación, produce intervalos demasiado estrechos.]),
    ("advertencia", [SHAP como causal incluso sobre el CATE correcto: sigue siendo
      asociativo dentro del modelo, no autoriza afirmaciones de mecanismo.]),
  ),
  conexiones: "Para preguntas de mecanismo, usar la descomposición por rutas del
    Cap. 23, no una atribución de importancia.",
)

#cap-discusion-ejercicio(
  pregunta: "La equidad causal es un campo activo — las tres familias pueden entrar
    en conflicto. ¿Qué significa entonces \"hacer una auditoría de equidad
    responsable\" si no hay solución técnica única?",
  ejercicio: "Use SHAP sobre un sustituto de un Causal Forest entrenado en nhefs.
    ¿Qué variables son más importantes para la heterogeneidad del efecto de dejar de
    fumar?",
)

#cap-cierre-narrativo(
  resumen: (
    [Independencia, separación y suficiencia son mutuamente incompatibles salvo
     casos degenerados.],
    [SHAP debe aplicarse a un sustituto del CATE, nunca al modelo de outcome, si se
     quiere explicar el EFECTO.],
    [El IC por subgrupo requiere la influence function del estimador, no un t-test
     sobre predicciones.],
  ),
  refs: (
    [Barocas, Hardt & Narayanan (2019), *Fairness and Machine Learning*],
    [Hardt et al. (2016), equalized odds],
    [Lundberg & Lee (2017), SHAP],
  ),
  transicion: "Cap. 25 — Decisiones estructurales bajo incertidumbre",
  gancho: "Explicar y auditar el efecto asume que ya se decidió qué hacer con él; el
    capítulo siguiente formaliza esa decisión misma, más allá de \"tratar o no
    tratar\".",
)
