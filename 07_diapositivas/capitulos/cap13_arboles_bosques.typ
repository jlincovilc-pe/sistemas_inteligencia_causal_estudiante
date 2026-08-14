// =============================================================================
// Diapositivas · Capítulo 13 — Árboles y bosques causales
// Fuente: 02_monografia/.../capitulos/cap06_arboles_bosques.typ
// Plan detallado: PLAN_SPRINT_DIAPOSITIVAS.md §3, "Cap. 13"
// Sesión S14 · Lab L14 · Entrega: B1 entrega · Variante A · ★ camino crítico
// =============================================================================
#import "../plantilla_monografia.typ": *

#show: cap-theme

#cap-init(num: 13, titulo: "Árboles y bosques causales",
  parte: "II", sesion: "S14", variant: "A", critico: true)

#cap-progreso-curso(cap-actual: 13)
#cap-portada(num: 13, titulo: "Árboles y bosques causales",
  parte: "II", sesion: "S14", variant: "A", critico: true)

#cap-roadmap(
  objetivos: (
    [Explicar la honesty y por qué evita el sesgo de selección estructural.],
    [Describir el bosque causal como generador de pesos locales, no como promedio de
     árboles.],
    [Usar CausalForestDML con mapas de heterogeneidad.],
  ),
  agenda: (
    [Identificar subgrupos con efecto heterogéneo],
    [Honesty: splitting subsample vs. estimation subsample],
    [El bosque como pesos de vecindad — no promedio de árboles],
    [Normalidad asintótica local],
    [Caso NSW: mapas de heterogeneidad],
  ),
  lectura: "Cap. 13 — Bosques causales (@cap-causal-forests)",
  lab: "L14", entrega: "B1 entrega",
)

#cap-motivacion(
  problema: "El CATE promedio de un programa de transferencias puede ser modesto (3pp)
    mientras la heterogeneidad es grande: nulo en algunos subgrupos, >10pp en otros.",
  gancho: "La honesty evita el overfitting estructural de los árboles estándar y
    permite IC asintóticamente válidos.",
  caso: "Transferencias condicionadas y asistencia escolar por subgrupo.",
)

#cap-definicion(
  titulo-def: "Honesty",
  cuerpo: "Un árbol causal es honest si las decisiones de partición son independientes
    (en muestra) de las estimaciones de τ̂ dentro de cada hoja: S = S_split ∪ S_est,
    el árbol se construye con S_split y los efectos se estiman con S_est.",
  eq: $hat(tau)(cal(L)_m) = 1/n_(1,m) sum_(D_i=1) Y_i - 1/n_(0,m) sum_(D_i=0) Y_i$,
)

#cap-supuestos(supuestos: (
  ([Honesty], [Evita sesgo de selección: sin ella, τ̂ en hojas seleccionadas tiende a
    ser mayor en valor absoluto que el verdadero], [Comparar con/sin honesty sobre la
    misma muestra]),
  ([No confusión + soporte común], [Igual que el resto de la Parte II], [ê(x) sin
    valores cerca de 0 o 1]),
))

#cap-teorema(
  titulo: "Normalidad asintótica local (Wager & Athey, 2018)",
  enunciado: "Bajo honesty, submuestreo, soporte común y suavidad local, existe una
    varianza estimada V̂(x) tal que (τ̂_CF(x)−τ(x))/√V̂(x) →^d N(0,1). La tasa es LOCAL
    y depende de la probabilidad de caer en hojas cercanas a x — no una normalización
    √n universal.",
)

// Contenido nuevo, dedicarle un espacio propio: el bosque como generador de pesos,
// no como promedio de arboles.
#cap-demostracion(pasos: (
  [Un bosque aleatorio predictivo promedia predicciones de árboles.],
  [Un bosque CAUSAL, en su formulación canónica (GRF), NO promedia $hat(tau)_b (x)$:
   induce pesos de vecindad $omega_i (x)$ — cuán a menudo $i$ cae en la misma hoja
   que $x$.],
  [Con esos pesos, se resuelve una ecuación de momento LOCAL:
   $sum_i omega_i (x) psi_i (hat(theta)(x)) = 0$. El árbol elige qué vecinos son
   relevantes; el score causal hace la estimación.],
))

#cap-interactivo(
  tipo: "Aplicado",
  pregunta: "Policy trees son interpretables — ¿por qué su interpretabilidad es
    también la fuente de su garantía estadística (VC finita, Athey & Wager 2021) y no
    solo una concesión de comunicación?",
)

#cap-codigo-parte(
  titulo: "CausalForestDML con mapas de heterogeneidad",
  snippet: "import numpy as np\n"
    + "import pandas as pd\n"
    + "import matplotlib.pyplot as plt\n"
    + "from econml.dml import CausalForestDML\n"
    + "from sklearn.ensemble import GradientBoostingRegressor, GradientBoostingClassifier\n\n"
    + "df = pd.read_csv(\"../data/datasets/real/public_causaldata/nsw_mixtape/data.csv\")\n"
    + "Y, D = df[\"re78\"].values, df[\"treat\"].values\n"
    + "X = df[[\"age\", \"educ\", \"black\", \"hisp\", \"marr\", \"nodegree\", \"re74\", \"re75\"]].values\n\n"
    + "cf = CausalForestDML(\n"
    + "    model_y=GradientBoostingRegressor(n_estimators=200, max_depth=4, random_state=42),\n"
    + "    model_t=GradientBoostingClassifier(n_estimators=200, max_depth=4, random_state=42),\n"
    + "    discrete_treatment=True, n_estimators=400, min_samples_leaf=20, cv=5)\n"
    + "cf.fit(Y, D, X=X)\n\n"
    + "ate = cf.ate(X=X); lb, ub = cf.ate_interval(X=X, alpha=0.05)\n"
    + "print(f\"ATE: {ate:.2f}  IC 95%: [{lb:.2f}, {ub:.2f}]\")\n\n"
    + "cate = cf.effect(X)\n"
    + "cate_lb, cate_ub = cf.effect_interval(X, alpha=0.05)\n\n"
    + "# Mapas de heterogeneidad: CATE por edad y educacion\n"
    + "fig, axes = plt.subplots(1, 2, figsize=(12, 5))\n"
    + "for ax, var in zip(axes, [\"age\", \"educ\"]):\n"
    + "    ax.scatter(df[var], cate, c=cate, cmap=\"viridis\", alpha=0.6)\n"
    + "    ax.set_xlabel(var); ax.set_ylabel(\"CATE estimado\")\n"
    + "plt.tight_layout(); plt.show()",
)

#cap-caso-resolucion(
  titulo: "NSW: heterogeneidad por educación e ingreso previo",
  contexto: "n=445 (185 tratados). ATE \$2,226, IC [\$14, \$4,438].",
  resultado: "feature_importances_: age (0.43), educ (0.24), re75 (0.22), re74 (0.08).
    CATE por educación: \$1,174 (educ=7) → \$3,515 (educ=14).",
  interpretacion: "Heterogeneidad estructurada consistente con la teoría económica de
    la capacitación.",
)

#cap-mapeo-pch-activo(
  nivel: "L2 heterogéneo — inferencia asintótica local",
  metrica: "τ̂_CF(x) con V̂(x) local",
  pregunta-activa: "¿Por qué un bosque aleatorio predictivo (para Y) no puede
    convertirse en un bosque causal solo cambiando la etiqueta que predice?",
)

#cap-errores-transiciones(
  errores: (
    ("crítico", [Árbol sin honesty: sesgo de selección — comparar con/sin honesty
      sobre la misma muestra.]),
    ("advertencia", [Data dredging de subgrupos: pre-registrar subgrupos de interés,
      ajustar por Bonferroni/FDR si se comparan varios.]),
    ("advertencia", [CATE fuera del soporte común: no extrapolar a regiones sin
      solapamiento.]),
  ),
  conexiones: "Policy trees (Athey & Wager 2021) conectan directamente con el policy
    learning formal del Cap. 21.",
)

#cap-discusion-ejercicio(
  pregunta: "Compare causal forest con R-learner sobre el mismo dataset. ¿Qué método
    identifica más heterogeneidad y por qué podría diferir la respuesta según el
    tamaño muestral?",
  ejercicio: "Implemente un árbol causal honesto \"a mano\" dividiendo la muestra en
    S_split y S_est. Compare con la implementación de econml.",
)

#cap-cierre-narrativo(
  resumen: (
    [Honesty separa partición de estimación — evita el sesgo de selección
     estructural de los árboles estándar.],
    [El bosque causal genera pesos de vecindad; el score causal hace la estimación
     local.],
    [Policy trees heredan la garantía de VC finita del Cap. 21.],
  ),
  refs: (
    [Athey & Imbens (2016), causal trees],
    [Wager & Athey (2018), normalidad asintótica],
    [Athey, Tibshirani & Wager (2019), Generalized Random Forests],
  ),
  transicion: "Cap. 15 — Despliegue de un estimador causal como servicio (S12 en el
    orden de enseñanza real, ya cubierto antes — este capítulo cierra la Parte II en
    el libro)",
  gancho: "El estimador ya es robusto y validado; falta ponerlo donde alguien pueda
    consultarlo sin reabrir el notebook.",
)
