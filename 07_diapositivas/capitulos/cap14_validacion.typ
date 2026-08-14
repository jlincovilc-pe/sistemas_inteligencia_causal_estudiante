// =============================================================================
// Diapositivas · Capítulo 14 — Validación, refutación y sensibilidad
// Fuente: 02_monografia/.../capitulos/cap07_validacion.typ
// Plan detallado: PLAN_SPRINT_DIAPOSITIVAS.md §3, "Cap. 14"
// Sesión S11 · Lab L11 · Entrega: A2 entrega · Variante A · ★ camino crítico
// =============================================================================
#import "../plantilla_monografia.typ": *

#show: cap-theme

#cap-init(num: 14, titulo: "Validación, refutación y sensibilidad",
  parte: "II", sesion: "S11", variant: "A", critico: true)

#cap-progreso-curso(cap-actual: 14)
#cap-portada(num: 14, titulo: "Validación, refutación y sensibilidad",
  parte: "II", sesion: "S11", variant: "A", critico: true)

#cap-roadmap(
  objetivos: (
    [Explicar por qué la validación cruzada estándar no aplica al CATE.],
    [Construir curvas Qini/AUUC y distinguir ranking de calibración.],
    [Calcular e interpretar un E-value.],
  ),
  agenda: (
    [El problema fundamental: τ(x) nunca se observa],
    [Curva Qini, AUUC y coeficiente Qini],
    [Placebo tests y transformed outcome],
    [E-value: sensibilidad a confusión no observada],
    [Baselines obligatorios y versionado del proceso],
  ),
  lectura: "Cap. 14 — Validación (@cap-validacion)",
  lab: "L11", entrega: "A2 entrega",
)

#cap-motivacion(
  problema: "Un banco entrenó un modelo de uplift para crédito pre-aprobado. No se
    observa el CATE verdadero para ningún cliente — cada cliente recibe solo un
    tratamiento.",
  gancho: "La validación cruzada estándar de ML supervisado es inválida para el CATE:
    no hay \"y verdadero\" contra qué comparar.",
  caso: "Modelo de uplift para líneas de crédito pre-aprobadas.",
)

#cap-definicion(
  titulo-def: "Imposibilidad de validación directa",
  cuerpo: "Para cualquier estimador τ̂ y cualquier dataset real (Y,D,X), no existe
    función de los datos que permita estimar el error ‖τ̂−τ‖ sin supuestos
    adicionales. La solución: proxy metrics y placebo tests que detectan fallos
    gruesos sin medir el error directamente.",
)

#cap-glosario(terminos: (
  ([AUUC], [Área bajo la curva uplift. Métrica de RANKING, invariante a reescalar τ̂ —
    no de calibración.]),
  ([Coeficiente Qini], [AUUC normalizada — comparable entre datasets.]),
  ([Transformed outcome], [$Y^star$ con $E[Y^star|X]=tau(X)$ si ê es consistente —
    permite RMSE supervisado sobre τ̂.]),
))

#cap-teorema(
  titulo: "Sensibilidad, Nivel 1 — E-value (VanderWeele & Ding, 2017)",
  enunciado: "E = RR + √(RR(RR−1)). Un confusor no observado tendría que estar
    asociado a tratamiento Y resultado por un factor de riesgo ≥ E para explicar
    completamente la asociación observada. Condición NECESARIA, no suficiente: describe
    el confusor único más débil que explicaría el resultado — varios confusores
    moderados pueden combinarse.",
)

// C8 (Etapa 2) -- el E-value pasa de ser "la" tecnica de sensibilidad a ser el
// Nivel 1 de un protocolo de tres niveles.
#cap-definicion(
  titulo-def: "Sensibilidad, Niveles 2 y 3 — R² parcial y bounds de Manski",
  cuerpo: "Nivel 2 (Cinelli & Hazlett, 2020; Imbens, 2003): para estimaciones tipo
    PLR, ¿qué R² parcial con D y con Y tendría que tener un confusor no observado U
    para anular el efecto? Se reporta contra el benchmark del confusor observado
    más fuerte, en la escala del propio modelo — sin cambiar a razones de riesgo
    como el E-value. Nivel 3 (Manski, 1990): con Y∈[0,1] y sin ningún supuesto de
    no confusión, θ=E[Y(1)−Y(0)] queda acotado en un intervalo de ancho ≤1, que
    puede estrecharse combinando el bound con el E-value del Nivel 1. Protocolo
    del curso: todo resultado observacional reporta Nivel 1 siempre + Nivel 2 si
    el estimador es tipo PLR + Nivel 3 si el outcome está acotado y el resultado
    es próximo a cero. Un resultado que no sobrevive el Nivel 1 se reporta como
    \"no robusto\" y no se despliega.",
)

#cap-interactivo(
  tipo: "Conceptual",
  pregunta: "Un modelo puede predecir Y con R²=0.99 y producir CATE completamente
    sesgado. ¿Cómo es posible? (El R² predictivo no correlaciona con la calidad de la
    estimación causal.)",
)

#cap-codigo-parte(
  titulo: "Curva Qini sobre DGP con ground truth",
  snippet: "import numpy as np, pandas as pd, matplotlib.pyplot as plt\n"
    + "from econml.dml import CausalForestDML\n"
    + "from sklearn.ensemble import GradientBoostingRegressor, GradientBoostingClassifier\n\n"
    + "rng = np.random.default_rng(42)  # DGP con CATE conocido (ground truth)\n"
    + "X = rng.uniform(-1, 1, (3000, 5))\n"
    + "D = (rng.uniform(size=3000) < 1/(1 + np.exp(-0.5 - 0.3*X[:, 0]))).astype(int)\n"
    + "Y = X[:, 2] + X[:, 3] + D*(2 + 3*X[:, 0] - X[:, 1]**2) + rng.standard_normal(3000)*0.5\n\n"
    + "cf = CausalForestDML(model_y=GradientBoostingRegressor(n_estimators=200, random_state=42),\n"
    + "                     model_t=GradientBoostingClassifier(n_estimators=200, random_state=42),\n"
    + "                     discrete_treatment=True, n_estimators=400, cv=5).fit(Y, D, X=X)\n"
    + "tau_hat = cf.effect(X)\n\n"
    + "def qini_curve(Y, D, tau_hat):  # Qini acumulada, ranking por tau_hat\n"
    + "    df = pd.DataFrame({'Y': Y, 'D': D, 'tau_hat': tau_hat}).sort_values('tau_hat', ascending=False)\n"
    + "    cum_D, cum_n_C = df['D'].cumsum(), (np.arange(1, len(df)+1) - df['D'].cumsum()).clip(lower=1)\n"
    + "    qini = (df['Y']*df['D']).cumsum() - (df['Y']*(1-df['D'])).cumsum() * (cum_D/cum_n_C)\n"
    + "    return np.arange(1, len(df)+1)/len(df), qini\n\n"
    + "frac, qini = qini_curve(Y, D, tau_hat)\n"
    + "frac_r, qini_r = qini_curve(Y, D, np.random.permutation(tau_hat))  # baseline aleatorio\n"
    + "plt.plot(frac, qini, label='Causal Forest', lw=2)\n"
    + "plt.plot(frac_r, qini_r, label='Random', lw=2, ls='--', color='gray'); plt.legend()",
)

// C5 (Etapa 2) -- Qini evalua ranking; BLP/BEST/CLAN dan un test formal de si
// la heterogeneidad es distinguible de cero.
#cap-teorema(
  titulo: "Tests formales de heterogeneidad: BLP, BEST y CLAN (Chernozhukov et al., 2020)",
  enunciado: "La curva Qini evalúa ranking; no responde si la heterogeneidad
    detectada es estadísticamente distinguible de cero. BLP (Best Linear
    Predictor): sobre una muestra de evaluación separada (sample-splitting),
    Y*=β1·T̂+β2·(T̂−T̄)·T̂+ε; H0:β2=0 testea 'no hay heterogeneidad linealmente
    detectable por T̂'. BEST: partición por la mediana de T̂, test de diferencia
    de efectos medios entre los dos grupos. CLAN: efectos medios por cuantiles
    de T̂ con IC simultáneos, para perfilar la forma de la heterogeneidad sin
    compromiso paramétrico. Los tres están en econml.validate.DRtester. Regla
    operativa: ningún informe de heterogeneidad se publica sin el BLP; si β2 no
    es significativo, la heterogeneidad se declara exploratoria.",
)

// C6 (Etapa 2) -- puente directo hacia ic_individual en el Cap. 15 y hacia el
// Cap. 27 (mitigacion de reportar tau_hat(x) sin incertidumbre).
#cap-definicion(
  titulo-def: "Intervalos conformes para efectos individuales",
  cuerpo: "El teorema de cobertura del CATE cubre τ(x), no el efecto individual
    Yᵢ(1)−Yᵢ(0): su varianza incluye el ruido εᵢ, que la varianza del estimador
    no captura — y las decisiones individuales del servicio (Cap. 15) requieren
    justamente eso. Split conformal sobre el transformed outcome: (1) particionar
    en entrenamiento y calibración; (2) entrenar τ̂ en el primero; (3) calcular
    residuos no conformes Rᵢ=|Y*ᵢ−τ̂(Xᵢ)| en el segundo; (4)
    Ĉ(x)=[τ̂(x)−q̂, τ̂(x)+q̂] con q̂ el cuantil adecuado de {Rᵢ}. Si las
    observaciones son intercambiables, la cobertura marginal es ≥1−α sin
    supuestos distribucionales sobre (Y,D,X). Dos advertencias: la cobertura es
    del transformed outcome, no de Yᵢ(1)−Yᵢ(0) literal; y con propensity
    estimado se requiere conformal ponderado, no la versión sin ponderar.",
)

// C7 (Etapa 2) -- RATE como criterio formal de seleccion de estimadores de
// CATE en datos reales (RMSE exige ground truth sintetico, que no existe en
// produccion).
#cap-codigo-parte(
  titulo: "RATE: selección formal de estimadores de CATE",
  snippet: "# RATE: Rank-Weighted Average Treatment Effect (Yadlowsky et al., 2021)\n"
    + "# WET(alpha) = efecto promedio sobre el top-alpha bajo el ranking de tau_hat\n"
    + "# RATE(alpha) = integral_0^alpha WET(u) du\n"
    + "# Pondera las regiones del ranking donde los errores de priorizacion\n"
    + "# cuestan mas; admite inferencia via influence function: la diferencia\n"
    + "# de RATE entre dos estimadores tiene IC valido, analogo al test de\n"
    + "# diferencia de AUC entre clasificadores.\n"
    + "from econml.score import RScorer  # implementa esta comparacion (Ap. B)",
  nota: "Regla operativa: la elección entre meta-learners y causal forest en
    datos reales se documenta con la diferencia de RATE y su IC, no con la
    inspección visual de Qini. Qini sigue siendo la métrica de reporte para
    audiencias de negocio (Cap. 22); RATE es la métrica de decisión interna.",
)}

#cap-caso-resolucion(
  titulo: "thornton_hiv (experimento aleatorizado)",
  contexto: "Incentivos monetarios sobre demanda de resultados de test de VIH,
    Malaui. Tratamiento ALEATORIZADO — identificación no está en discusión.",
  resultado: "Ranking top-20% muestra uplift sustancialmente mayor que el promedio.",
  interpretacion: "Sirve como banco de pruebas de control: toda desviación en la
    suite de refutación es atribuible al estimador, no al diseño — a diferencia de
    datos observacionales donde ambas fuentes de error se confunden.",
)

#cap-mapeo-pch-activo(
  nivel: "L2 (evaluación de la estimación, no un nivel nuevo)",
  metrica: "Qini/AUUC (ranking) + BLP/BEST/CLAN (heterogeneidad formal) + RATE
    (selección de estimador) + conformal (IC individual) + sensibilidad en 3
    niveles (E-value/R²/Manski)",
  pregunta-activa: "Un AUUC excelente y un E-value bajo — ¿qué le dice cada uno que el
    otro no puede decirle?",
)

#cap-errores-transiciones(
  errores: (
    ("crítico", [Validar con R² de Y: el R² predictivo no correlaciona con la calidad
      causal — un modelo puede predecir Y perfectamente y dar CATE sesgado.]),
    ("advertencia", [Omitir placebo tests en datos reales: sin ground truth, son la
      única validación de especificación.]),
    ("advertencia", [Sobreinterpretar Qini creciente como CATE insesgado: indica buen
      ranking, no ausencia de sesgo en la magnitud.]),
  ),
  conexiones: "Baselines obligatorios (efecto constante, aleatorio, riesgo sin
    causalidad) versionados junto al modelo — precondición del Cap. 15.",
)

#cap-discusion-ejercicio(
  pregunta: "¿Por qué reportar un AUUC sin banda de confianza por bootstrap invita a
    declarar ganador a un modelo que no lo es?",
  ejercicio: "Implemente el transformed outcome Y* y calcule la correlación con τ̂.
    ¿Es alta? ¿Qué dice esto sobre la calidad del estimador?",
)

#cap-cierre-narrativo(
  resumen: (
    [τ(x) nunca se observa — la validación es siempre indirecta.],
    [Qini/AUUC miden ranking; BLP/BEST/CLAN dan un test formal de heterogeneidad;
     RATE decide entre estimadores; conformal da IC individual.],
    [La sensibilidad ya no es solo E-value: es un protocolo de tres niveles
     (E-value, R², bounds de Manski), y baselines + versionado hacen el proceso
     comparable en el tiempo.],
  ),
  refs: (
    [VanderWeele & Ding (2017), E-value],
    [Cinelli & Hazlett (2020), sensibilidad en escala R²],
    [Radcliffe (2007), curva Qini],
    [Chernozhukov et al. (2020), BLP/BEST/CLAN],
    [Yadlowsky et al. (2021), RATE],
    [Huyen (2022), Cap. 6, evaluación offline versionada],
  ),
  transicion: "Cap. 15 — Despliegue de un estimador causal como servicio",
  gancho: "Con el proceso de evaluación versionado y reproducible, la pregunta natural
    es cómo llevar el estimador que pasó esa evaluación a un servicio que otros puedan
    consultar.",
)
