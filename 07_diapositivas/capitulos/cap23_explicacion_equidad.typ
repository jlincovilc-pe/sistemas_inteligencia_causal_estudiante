// =============================================================================
// Diapositivas · Capítulo 23 — Explicación causal y equidad algorítmica
// Fuente: 02_monografia/.../capitulos/cap12b_explicacion_equidad.typ
// Plan detallado: PLAN_SPRINT_DIAPOSITIVAS.md §3, "Cap. 23"
// Sesión S19 · Lab L19 · sin entrega · Variante A · ★ camino crítico
// =============================================================================
#import "../plantilla_monografia.typ": *

#show: cap-theme

#cap-init(num: 23, titulo: "Explicación causal y equidad algorítmica",
  parte: "VI", sesion: "S19", variant: "A", critico: true)

#cap-progreso-curso(cap-actual: 23)
#cap-portada(num: 23, titulo: "Explicación causal y equidad algorítmica",
  parte: "VI", sesion: "S19", variant: "A", critico: true)

#cap-roadmap(
  objetivos: (
    [Descomponer un efecto en directo/indirecto/espurio.],
    [Aplicar equidad contrafactual (Kusner et al., 2017).],
    [Distinguir discriminación por proxy de influencia no resuelta (Kilbertus et al.,
     2017).],
  ),
  agenda: (
    [¿El efecto de un atributo protegido pasa por una ruta legítima?],
    [CDE / NIE: descomposición directo/indirecto],
    [Equidad contrafactual],
    [Proxy vs. influencia no resuelta — dos remedios distintos],
    [Caso: brecha salarial y Oaxaca-Blinder],
  ),
  lectura: "Cap. 23 — Explicación y equidad (@cap-explicacion-equidad)",
  lab: "L19", entrega: "—",
)

#cap-motivacion(
  problema: "Un algoritmo de decisión (contratación, crédito, libertad condicional)
    produce resultados distintos según un atributo protegido — ¿ese efecto pasa por
    una ruta legítima o por una discriminatoria?",
  gancho: "Distinto del Cap. 24: SHAP es asociativo (atribuye contribución
    estadística); este capítulo pregunta si esa covariación refleja un mecanismo
    legítimo.",
  caso: "Brecha salarial de género, ocupación como mediador.",
)

#cap-definicion(
  titulo-def: "Descomposición directo/indirecto/espurio",
  cuerpo: "CDE(m)=E[Y|do(A=1,M=m)]−E[Y|do(A=0,M=m)]: efecto de A sobre Y que NO pasa
    por M. NIE: la porción que sí pasa por el cambio que A induce en M. La pregunta de
    equidad no es si el efecto total es distinto de cero, sino si el efecto DIRECTO lo
    es.",
)

#cap-teorema(
  titulo: "Proxy vs. influencia no resuelta (Kilbertus et al., 2017)",
  enunciado: "Un PROXY es una variable observada, descendiente del atributo protegido
    (código postal ≈ raza) — la discriminación por proxy se elimina por CONSTRUCCIÓN,
    cortando la ruta A→proxy→Ŷ, sin observar A. La INFLUENCIA NO RESUELTA viaja por
    rutas no declaradas legítimas que no pasan por ninguna variable observable
    intervenible — exige una decisión NORMATIVA, no técnica. Confundir ambas es el
    error típico de auditorías que solo quitan la variable sensible del modelo.",
)

#cap-demostracion(pasos: (
  [Identificar los proxies del atributo protegido en el grafo (variables observadas,
   descendientes de A).],
  [Neutralizar técnicamente los proxies: cortar su ruta hacia Ŷ en el modelo de
   decisión.],
  [Para la influencia no resuelta: declarar explícitamente qué rutas se consideran
   legítimas — una decisión normativa que ningún algoritmo puede automatizar.],
))

#cap-interactivo(
  tipo: "Conceptual",
  pregunta: "Declarar M (ocupación) como mediador legítimo sin análisis histórico —
    ¿qué se puede estar blanqueando si el acceso a esa ocupación estuvo
    históricamente restringido por género?",
)

#cap-codigo-parte(
  titulo: "Descomposición directo/indirecto — SCM simulado",
  snippet: "import numpy as np\n"
    + "import pandas as pd\n\n"
    + "rng = np.random.default_rng(3)\n"
    + "n = 20_000\n\n"
    + "# A: atributo protegido (0/1); M: mediador legitimo (ocupacion);\n"
    + "# Y: salario. Efecto directo deliberado (discriminacion) = 0.15\n"
    + "A = rng.binomial(1, 0.5, size=n)\n"
    + "M = 0.5 * A + rng.normal(scale=1, size=n)  # A -> M (legitimo)\n"
    + "Y = 0.15 * A + 0.6 * M + rng.normal(scale=1, size=n)  # directo 0.15 + via M\n\n"
    + "df = pd.DataFrame({\"A\": A, \"M\": M, \"Y\": Y})\n\n"
    + "# Efecto total (asociativo, sin descomponer)\n"
    + "efecto_total = df.loc[df.A == 1, \"Y\"].mean() - df.loc[df.A == 0, \"Y\"].mean()\n\n"
    + "# CDE: fijar M en su media global y comparar A=1 vs A=0\n"
    + "m_fijo = df[\"M\"].mean()\n"
    + "cde = (0.15 * 1 + 0.6 * m_fijo) - (0.15 * 0 + 0.6 * m_fijo)\n\n"
    + "print(f\"Efecto total A->Y:          {efecto_total:.3f}\")\n"
    + "print(f\"Efecto directo controlado:  {cde:.3f}  (deberia acercarse a 0.15)\")\n"
    + "print(f\"Efecto indirecto (via M):   {efecto_total - cde:.3f}\")",
  invariante: "# assert abs(cde - 0.15) < 0.02",
)

#cap-caso-resolucion(
  titulo: "Brecha salarial de género y Oaxaca-Blinder",
  contexto: "Efecto total observado se descompone en: parte explicada por
    ocupación/experiencia/sector (indirecto) y un residuo no explicado (aprox. al
    directo).",
  resultado: "Oaxaca-Blinder es un antecesor estadístico de esta idea en economía
    laboral.",
  interpretacion: "El lenguaje de rutas permite declarar EXPLÍCITAMENTE, antes de
    estimar, qué mediadores se consideran legítimos — en vez de dejarlo implícito en
    la elección de controles.",
)

#cap-mapeo-pch-activo(
  nivel: "L2/L3 (rutas interventivas; equidad contrafactual es L3)",
  metrica: "CDE, NIE; equidad contrafactual (Kusner et al.)",
  pregunta-activa: "¿Por qué la equidad contrafactual de Kusner et al. es de Nivel 3
    de la PCH y no de Nivel 1, y por qué eso la hace más difícil de verificar
    empíricamente que la paridad demográfica?",
)

#cap-errores-transiciones(
  errores: (
    ("crítico", [Declarar un mediador legítimo sin análisis histórico de si esa ruta
      perpetúa discriminación pasada.]),
    ("advertencia", [La legitimidad de una ruta es una decisión normativa, no
      estadística — ningún test la determina.]),
    ("advertencia", [Sensibilidad al grafo: un mediador omitido infla artificialmente
      el efecto directo estimado.]),
  ),
  conexiones: "El Cap. 24 complementa esto con la caja de herramientas de uso más
    frecuente en la práctica: SHAP y las tres familias observacionales de fair ML.",
)

#cap-discusion-ejercicio(
  pregunta: "Proponga dos mediadores para la brecha salarial: uno que consideraría
    legítimo y uno cuestionable de aceptar, aun si estadísticamente media parte del
    efecto. Justifique la distinción normativa.",
  ejercicio: "Modifique el listado para que el efecto directo verdadero sea 0.
    Verifique que el CDE estimado converge a 0 mientras el efecto indirecto se
    mantiene distinto de cero.",
)

#cap-cierre-narrativo(
  resumen: (
    [El efecto total se descompone en directo (potencial discriminación) e indirecto
     (potencialmente legítimo).],
    [Proxy y influencia no resuelta requieren remedios de naturaleza distinta: técnico
     vs. normativo.],
    [La legitimidad de una ruta es siempre una decisión normativa que el análisis
     causal formaliza pero no reemplaza.],
  ),
  refs: (
    [Pearl (2009), fórmulas de mediación causal],
    [Kusner et al. (2017), equidad contrafactual],
    [Kilbertus et al. (2017), proxy vs. influencia no resuelta],
  ),
  transicion: "Cap. 24 — Ética, interpretabilidad y comunicación de resultados",
  gancho: "La descomposición por rutas es el aparato causal de equidad; el capítulo
    siguiente lo complementa con la caja de herramientas que de verdad se usa en la
    práctica.",
)
