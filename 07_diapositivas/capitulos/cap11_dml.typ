// =============================================================================
// Diapositivas · Capítulo 11 — Double/Debiased Machine Learning
// Fuente: 02_monografia/.../capitulos/cap04_dml.typ
// Plan detallado: PLAN_SPRINT_DIAPOSITIVAS.md §3, "Cap. 11"
// Sesión S10 · Lab L10 · Entrega: A2 · Variante A · ★ camino crítico
// =============================================================================
#import "../plantilla_monografia.typ": *

#show: cap-theme

#cap-init(num: 11, titulo: "Double/Debiased Machine Learning",
  parte: "II", sesion: "S10", variant: "A", critico: true)

#cap-progreso-curso(cap-actual: 11)
#cap-portada(num: 11, titulo: "Double/Debiased Machine Learning",
  parte: "II", sesion: "S10", variant: "A", critico: true)

#cap-roadmap(
  objetivos: (
    [Implementar DML-PLR y DML-IRM con DoubleML/econml.],
    [Elegir un learner de nuisance verificando la condición de tasa.],
    [Distinguir qué estima cada uno de OLS/IV/DML-PLIV sobre el mismo dataset — no son
     el mismo estimando.],
  ),
  agenda: (
    [PLR e IRM: score y garantías],
    [Learners de nuisance y sus tasas],
    [DoubleML y econml: dos implementaciones],
    [Verificación de leakage],
    [Card (1995): OLS, IV, DML-PLIV no son comparables sin más],
  ),
  lectura: "Cap. 11 — DML (@cap-dml)",
  lab: "L10", entrega: "A2",
)

#cap-motivacion(
  problema: "Ministerio de Educación: efecto de una beca sobre rendimiento, 60
    covariables, asignación priorizó bajo rendimiento previo pero también variables
    familiares y de contexto.",
  gancho: "El Cap. 10 mostró que el score ortogonal funciona; este capítulo lo
    implementa con librerías reales y cubre PLR e IRM.",
  caso: "Beca sobre rendimiento académico, panel con 60 covariables.",
)

#cap-definicion(
  titulo-def: "Score IRM (modelo interactivo)",
  cuerpo: "Permite heterogeneidad en D; combina la forma doubly-robust clásica de
    Robins et al. (1994) ajustada para ortogonalidad de Neyman. Es la fila 'ATE
    bajo IRM' de la tabla del score canónico del Cap. 10 — la misma versión sin
    promediar reaparece como Γᵢ del DR-learner (Cap. 12) y como EIF del policy
    value (Cap. 21).",
  eq: $psi_"IRM" = mu(1,X)-mu(0,X) + (D(Y-mu(1,X)))/e(X) - ((1-D)(Y-mu(0,X)))/(1-e(X)) - theta$,
)

#cap-supuestos(supuestos: (
  ([No confusión condicional], [$Y(0),Y(1) perp perp D | X$], [Ficha de procedencia, Cap. 7]),
  ([Soporte común], [$0 < P(D=1|X) < 1$ c.s.], [Histograma de ê(X)]),
  ([Consistencia], [Y=Y(D)], [—]),
))

#cap-teorema(
  titulo: "Doble robustez + ortogonalidad (score IRM)",
  enunciado: "El score IRM es ortogonal de Neyman respecto a η=(μ,e). Además es
    doubly robust: si μ̂ O ê es consistente (no necesariamente ambos), θ̂ es
    consistente.",
)

// C3 (Etapa 2) -- segundo teorema, distinto y complementario: doble robustez
// protege contra mala especificacion; eficiencia certifica el optimo cuando
// ambos nuisance convergen.
#cap-teorema(
  titulo: "Eficiencia semiparamétrica del estimador DML-IRM",
  enunciado: "Bajo no confusión, soporte común y Y acotado, la efficient
    influence function (EIF) del funcional θ0=E[μ(1,X)−μ(0,X)] en el modelo IRM
    es EXACTAMENTE el integrando del score IRM. Por la cota de Cramér-Rao
    semiparamétrica (Ap. A), el estimador DML-IRM es asintóticamente eficiente:
    ningún estimador regular tiene varianza asintótica menor que
    V_eff = E[(τ(X)−θ0)² + σ²₁(X)/e(X) + σ²₀(X)/(1−e(X))]. La doble robustez del
    teorema anterior protege contra mala especificación de un nuisance; la
    eficiencia certifica que, cuando ambos nuisance convergen, no se puede hacer
    mejor — son propiedades complementarias, no una versión más fuerte de la
    otra.",
)

// C4 (Etapa 2) -- diagnostico cuantitativo de soporte comun: ESS de Kish +
// trimming optimo de Crump et al. (2009).
#cap-definicion(
  titulo-def: "Diagnósticos cuantitativos de soporte común: ESS y trimming",
  cuerpo: "La alerta \"ê cerca de 0 o 1\" se vuelve operativa con dos cantidades
    medibles. ESS de Kish para la componente IPW: ESS=(Σwᵢ)²/Σwᵢ², con
    wᵢ=Dᵢ/ê(Xᵢ) — ESS/n≪1 señala que pocas unidades con ê extremo dominan la
    estimación, aunque el histograma de ê \"se vea bien\" (Kish, 1965). Trimming
    óptimo (Crump et al., 2009): recortar observaciones con ê(X)∉[α,1−α]
    minimiza la varianza asintótica para α*=(1−√(1/3))/2≈0.057. Regla operativa
    del curso: reportar ESS/n y el rango de ê en todo resultado DML. Atención al
    estimando: tras el trimming, el efecto identificado es el ATE sobre la
    población con overlap, no el ATE poblacional — declararlo en la model card
    (Cap. 19) es obligatorio.",
)

#cap-interactivo(
  tipo: "Aplicado",
  pregunta: "Un learner único sin análisis de sensibilidad — ¿qué riesgo concreto
    corre el resultado? (Divergencias grandes entre learners señalan problemas de
    especificación.)",
)

#cap-codigo-parte(
  titulo: "DML-PLR con DoubleML — parte 1",
  snippet: "import doubleml as dml\n"
    + "from sklearn.ensemble import RandomForestRegressor\n"
    + "import pandas as pd\n\n"
    + "df = pd.read_csv('../data/datasets/real/public_causaldata/nsw_mixtape/data.csv')\n"
    + "Y = df['re78'].values\n"
    + "D = df['treat'].values\n"
    + "X = df[['age','educ','black','hisp','marr','nodegree','re74','re75']].values\n\n"
    + "obj_dml = dml.DoubleMLPLR(\n"
    + "    dml.DoubleMLData.from_arrays(X, Y, D),\n"
    + "    ml_l=RandomForestRegressor(n_estimators=200, min_samples_leaf=20, random_state=42),\n"
    + "    ml_m=RandomForestRegressor(n_estimators=200, min_samples_leaf=20, random_state=42),\n"
    + "    n_folds=5,\n"
    + ")\n"
    + "obj_dml.fit()\n"
    + "print(obj_dml.summary)",
  nota: "Chequeo de sanidad: el ATE estimado debe estar en el rango de la réplica del libro y
    llevar IC reportado, no solo el coeficiente. Comparar con OLS con controles.",
)
#cap-codigo-parte(
  titulo: "Verificación de leakage — parte 2",
  snippet: "from sklearn.model_selection import KFold\n"
    + "from sklearn.ensemble import RandomForestRegressor\n\n"
    + "def verify_no_leakage(Y, D, X, n_folds=5, seed=42):\n"
    + "    \"\"\"Predicciones nuisance SOLO fuera de fold.\"\"\"\n"
    + "    kf = KFold(n_splits=n_folds, shuffle=True, random_state=seed)\n"
    + "    n = len(Y)\n"
    + "    l_hat = np.zeros(n)\n"
    + "    m_hat = np.zeros(n)\n"
    + "    fold_assigned = np.zeros(n, dtype=int)\n\n"
    + "    for k, (train, test) in enumerate(kf.split(X)):\n"
    + "        fold_assigned[test] = k\n"
    + "        m_l = RandomForestRegressor(n_estimators=50, random_state=seed).fit(X[train], Y[train])\n"
    + "        l_hat[test] = m_l.predict(X[test])\n"
    + "        m_m = RandomForestRegressor(n_estimators=50, random_state=seed).fit(X[train], D[train])\n"
    + "        m_hat[test] = m_m.predict(X[test])\n\n"
    + "    print(f\"Folds asignados correctamente: {(fold_assigned != -1).all()}\")\n"
    + "    return l_hat, m_hat\n\n"
    + "verify_no_leakage(Y, D, X)",
  invariante: "# assert (fold_assigned != -1).all()",
  nota: "Si D es binario, usar un clasificador con predict_proba; para verificar leakage basta
    estimar E[D|X]. No dejar m_hat en ceros: una celda sin predecir es un bug de folds.",
)

#cap-caso-resolucion(
  titulo: "Card (1995): OLS, IV, DML-PLIV — estimandos distintos",
  contexto: "close_college, n=3003. OLS con controles (no confusión implausible), IV
    con nearc4 (LATE de compliers), DML-PLIV (mismo LATE, nuisance flexibles).",
  resultado: "OLS 0.071, IV 2SLS 0.124, DML-PLIV 0.145 — IC de IV casi 10× más ancho
    que el de OLS.",
  interpretacion: "IV no es \"OLS corregido\": estima el efecto sobre los compliers,
    un subgrupo distinto de la población general. El intervalo ancho es el precio de
    identificar con variación limitada, no un defecto del método.",
)

#cap-mapeo-pch-activo(
  nivel: "L2 (intervención) — ATE (PLR) o heterogéneo en D (IRM)",
  metrica: "θ0 con IC vía influence function; ESS/n y trimming (α*≈0.057) para el
    diagnóstico de soporte común",
  pregunta-activa: "Si OLS, IV y DML-PLIV dan tres números distintos sobre el mismo
    dataset, ¿cuál está \"mal\"? (Ninguno — estiman objetos distintos.)",
)

#cap-errores-transiciones(
  errores: (
    ("crítico", [Asumir que DML "resuelve" la confusión no observada: DML requiere
      no confusión condicional, igual que OLS.]),
    ("advertencia", [Soporte común ignorado: ê(X) cerca de 0 o 1 hace explotar las
      ponderaciones IPW.]),
    ("advertencia", [ê extremo sin reportar ESS/trimming: la varianza se infla sin
      que el histograma de ê lo delate.]),
    ("advertencia", [Learner único sin comparar al menos uno lineal y uno no
      lineal.]),
  ),
  conexiones: "El Cap. 14 (Validación) es el siguiente paso obligatorio antes de
    servir cualquiera de estos números.",
)

#cap-discusion-ejercicio(
  pregunta: "Verifique empíricamente la doble robustez: reemplace μ̂ por una constante
    (mal especificado) y observe que el ATE sigue siendo consistente si ê es
    consistente.",
  ejercicio: "Sobre nhefs, estime el efecto de dejar de fumar con (a) OLS manual,
    (b) DML-PLR con GBM, (c) DML-IRM con GBM. Compare.",
)

#cap-cierre-narrativo(
  resumen: (
    [PLR asume efecto constante; IRM permite heterogeneidad en D.],
    [El score IRM es doblemente robusto además de ortogonal.],
    [OLS/IV/DML-PLIV sobre el mismo dataset son estimandos distintos, no una escalera
     de corrección de sesgo.],
  ),
  refs: (
    [Chernozhukov et al. (2018), paper fundacional de DML],
    [Bach et al. (2022), DoubleML],
    [Battocchi et al. (2019), econml],
    [Crump et al. (2009), trimming óptimo y $alpha^* approx 0.057$],
  ),
  transicion: "Cap. 14 — Validación, refutación y sensibilidad (S11; el orden de
    enseñanza salta a Validación antes de Meta-learners)",
  gancho: "Con un ATE estimado y una librería que lo produce en segundos, la pregunta
    que sigue no es metodológica sino de confianza: ¿cómo sé que este número es
    razonable antes de servirlo?",
)
