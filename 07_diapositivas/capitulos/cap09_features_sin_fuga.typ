// =============================================================================
// Diapositivas · Capítulo 9 — Ingeniería de features sin fuga causal
// Fuente: 02_monografia/.../capitulos/cap02d_features_sin_fuga.typ
// Plan detallado: PLAN_SPRINT_DIAPOSITIVAS.md §3, "Cap. 9"
// Sesión S8 · Lab L08 · Entrega: A2 arranca · Variante B · ★ camino crítico
// =============================================================================
#import "../plantilla_monografia.typ": *

#show: cap-theme

#cap-init(num: 9, titulo: "Ingeniería de features sin fuga causal",
  parte: "I", sesion: "S8", variant: "B", critico: true)

#cap-progreso-curso(cap-actual: 9)
#cap-portada(num: 9, titulo: "Ingeniería de features sin fuga causal",
  parte: "I", sesion: "S8", variant: "B", critico: true)

#cap-roadmap(
  objetivos: (
    [Auditar una feature candidata por su rol causal, no solo por su poder
     predictivo.],
    [Construir las dos especificaciones X_base / X_ampliada para variables de rol
     ambiguo.],
    [Detectar fuga temporal con marca de tiempo.],
  ),
  agenda: (
    [Una feature puede mejorar la predicción y sesgar el efecto],
    [Selección por importancia predictiva vs. por rol causal],
    [Auditoría obligatoria: X_base y X_ampliada],
    [Aplicación: Notebook A2 y ortogonalidad de Neyman],
  ),
  lectura: "Cap. 9 — Features sin fuga (@cap-features-sin-fuga)",
  lab: "L08", entrega: "A2 arranca",
)

#cap-problema-diseno(
  decision: "Auditar cada feature candidata contra el grafo causal antes de incluirla,
    no solo contra su poder predictivo.",
  alternativas: "Selección de features por importancia predictiva vs. selección por
    rol causal.",
  tradeoff: "Una feature que mejora el ajuste predictivo puede empeorar la estimación
    causal.",
  stack: "pandas, el CausalSchema del Cap. 4.",
  riesgo: "Fuga (leakage) de información post-tratamiento disfrazada de covariable.",
)

#cap-opciones-tradeoffs(opciones: (
  ([Importancia predictiva], [Agregar features mientras mejoren CV (RMSE/AUC). Un
    modelo puede predecir excelente y estimar el efecto con sesgo severo.]),
  ([Rol causal, informado por el grafo], [Clasificar primero cada candidata
    (confusor/mediador/collider/post-tratamiento, Cap. 8) y solo después evaluar su
    aporte predictivo dentro de la categoría legítima.]),
))

#cap-decision-referencia(
  decision: "Etapa de auditoría de features obligatoria antes de construir X. Cada
    columna se anota con su rol supuesto y produce DOS especificaciones:
    X_base (solo confusores pre-tratamiento) y X_ampliada (+ rol desconocido
    pre-tratamiento, para análisis de sensibilidad).",
  justificacion: "Las dos decisiones posibles sobre una variable de rol desconocido
    tienen riesgos opuestos y no comparables (excluir arriesga confusión omitida,
    incluir arriesga mal control). Reportar ambas estimaciones convierte la duda en
    información.",
)

#cap-codigo-parte(
  titulo: "auditar_features — dos especificaciones",
  snippet: "import pandas as pd\n"
    + "\n"
    + "# Roles que NUNCA entran en X: su inclusion sesga la estimacion\n"
    + "ROLES_PROHIBIDOS = {\"mediador\", \"collider\", \"post_tratamiento\"}\n"
    + "\n"
    + "def auditar_features(df, treatment_time_col, feature_time_cols, roles):\n"
    + "    filas = []\n"
    + "    for feature, t_col in feature_time_cols.items():\n"
    + "        posterior = (df[t_col] > df[treatment_time_col]).mean()\n"
    + "        rol = roles.get(feature, \"desconocido\")\n"
    + "        pre = posterior == 0.0  # medida antes del tratamiento\n"
    + "        conf = rol == \"confusor\"\n"
    + "        # \"desconocido\" NO se excluye: entra en X_ampliada (sensibilidad)\n"
    + "        filas.append({\"feature\": feature, \"rol\": rol,\n"
    + "                      \"riesgo_temporal\": not pre,\n"
    + "                      \"incluir_en_X_base\": conf and pre,\n"
    + "                      \"incluir_en_X_ampliada\": (conf or rol == \"desconocido\")\n"
    + "                                                and pre and rol not in ROLES_PROHIBIDOS})\n"
    + "    return pd.DataFrame(filas)\n"
    + "\n"
    + "def columnas_X(resultado, especificacion=\"base\"):\n"
    + "    col = f\"incluir_en_X_{especificacion}\"\n"
    + "    return resultado.loc[resultado[col], \"feature\"].tolist()",
  invariante: "# assert set(columnas_X(r,'base')) <= set(columnas_X(r,'ampliada'))",
)

#cap-monorepo(texto-monorepo: "Lab L08 planta fugas deliberadas (outcome, tratamiento,
  interacciones) y las detecta antes de estimar. La Serie A2 (DML) y el escenario
  ihdp_medium asumen covariables solo pre-tratamiento. No usar columnas de ground truth
  (y0, y1, tau) fuera de celdas de evaluación. Rutas: 05_labs_sesion/L08_leakage_ihdp/ y
  notebook A2 en 03_notebooks_caso_estudio/notebooks/.")

#cap-caso-resolucion(
  titulo: "Notebook A2: auditoría antes de estimar",
  contexto: "El Notebook A2 (DML) exige ejecutar la auditoría sobre la matriz de
    covariables antes de estimar el modelo PLR/IRM (Cap. 11).",
  resultado: "Conecta directamente con un punto que el Cap. 10 asume resuelto: la
    validez de la ortogonalidad de Neyman depende de que X contenga controles
    legítimos, no mediadores ni colliders disfrazados.",
  interpretacion: "La auditoría de features es la precondición silenciosa de todo el
    aparato de la Parte II.",
)

#cap-mapeo-pch-activo(
  nivel: "Transversal (precondición para L2, conecta con Cap. 8)",
  metrica: "X_base vs. X_ampliada; % de features con riesgo temporal",
  pregunta-activa: "Si los IC de X_base y X_ampliada no se solapan, ¿qué capítulo hay
    que reabrir antes de reportar cualquiera de las dos estimaciones?",
)

#cap-checklist-alertas(items: (
  [Una feature mejora sustancialmente el ajuste predictivo sin razón causal clara para
   incluirla.],
  [Ninguna columna tiene marca de tiempo para verificar si fue medida antes o después
   del tratamiento.],
  [Se agregó una feature "porque funcionaba mejor en las pruebas" sin revisar el DAG.],
  [Existen features derivadas cuya fórmula usa, aunque indirectamente, el propio
   resultado Y.],
))

#cap-interactivo(
  tipo: "Conceptual",
  pregunta: "¿Por qué un \"promedio móvil del resultado en las últimas 4 semanas\" es
    casi siempre fuga en un sistema causal, aunque en uno predictivo sea razonable?",
)

#cap-discusion-ejercicio(
  pregunta: "Estime el efecto con X_base y con X_ampliada. Si los IC no se solapan,
    ¿por qué ninguna de las dos estimaciones es defendible sin resolver antes la
    pregunta de identificación?",
  ejercicio: "Aplique la auditoría al dataset del Notebook A1, declarando roles
    causales para al menos 6 covariables, con al menos una \"desconocido\". Reporte
    X_base vs. X_ampliada.",
)

#cap-cierre-narrativo(
  resumen: (
    [Auditar por rol causal, no solo por poder predictivo.],
    [Rol desconocido ⇒ dos especificaciones, no una exclusión de facto.],
    [La fuga temporal se detecta con marca de tiempo, de forma mecánica y
     verificable.],
  ),
  refs: (
    [Huyen (2022), *Designing Machine Learning Systems*, Cap. 5],
    [Bareinboim (2025) / Pearl (2009), clasificación de controles],
  ),
  transicion: "Cap. 10 — Ortogonalidad de Neyman, cross-fitting e influence functions
    (Parte II)",
  gancho: "Con datos, controles y features auditados, llega la pregunta puramente
    estadística que estructura toda la Parte II: ¿cómo usar ML flexible sin que su
    propio sesgo contamine la inferencia?",
)
