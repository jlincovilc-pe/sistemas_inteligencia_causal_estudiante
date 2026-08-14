// =============================================================================
// Diapositivas · Capítulo 25 — Decisiones estructurales bajo incertidumbre
// Fuente: 02_monografia/.../capitulos/cap12c_decisiones_estructurales.typ
// Plan detallado: PLAN_SPRINT_DIAPOSITIVAS.md §3, "Cap. 25"
// Sesión S21 · Lab L21 · sin entrega · Variante A · ★ camino crítico
// =============================================================================
#import "../plantilla_monografia.typ": *

#show: cap-theme

#cap-init(num: 25, titulo: "Decisiones estructurales bajo incertidumbre",
  parte: "VI", sesion: "S21", variant: "A", critico: true)

#cap-progreso-curso(cap-actual: 25)
#cap-portada(num: 25, titulo: "Decisiones estructurales bajo incertidumbre",
  parte: "VI", sesion: "S21", variant: "A", critico: true)

#cap-roadmap(
  objetivos: (
    [Formalizar una decisión como maximización de utilidad esperada sobre un conjunto
     de acciones.],
    [Aplicar maximin y minimax regret cuando el efecto solo está parcialmente
     identificado.],
    [Distinguir incertidumbre estadística de incertidumbre estructural.],
  ),
  agenda: (
    [Elegir entre acciones, no solo estimar el efecto de una dada],
    [Decisión óptima: $d^* = op("argmax")_d E[U(Y("do"(d)))]$],
    [Tres criterios bajo identificación parcial],
    [Caso: tres políticas de transferencia],
  ),
  lectura: "Cap. 25 — Decisiones estructurales (@cap-decisiones-estructurales)",
  lab: "L21", entrega: "—",
)

#cap-motivacion(
  problema: "El Cap. 21 resolvió \"tratar o no tratar\" bajo presupuesto. Este
    capítulo generaliza: la acción no tiene por qué ser binaria, y comparar acciones
    exige una función de utilidad explícita, no solo un efecto estimado.",
  gancho: "Cuando el Cap. 21 maximizaba welfare sujeto a presupuesto, ya usaba una
    función de utilidad particular — lineal en el resultado con restricción de
    costo.",
  caso: "Transferencia simple vs. con capacitación, tres políticas candidatas.",
)

#cap-definicion(
  titulo-def: "Decisión óptima",
  cuerpo: "d* = argmax_d E[U(Y(do(d)))] sobre un conjunto de acciones factibles D y una
    función de utilidad U. Distinta de estimar τ(x): esta pregunta siempre requiere U,
    aunque sea implícita.",
)

// Contenido central nuevo: tres criterios de decision bajo identificacion parcial.
#cap-teorema(
  titulo: "Tres criterios bajo identificación parcial (Manski, 2004)",
  enunciado: "Utilidad esperada: maximiza E[U] bajo la estimación puntual — defendible
    si el efecto está bien identificado y la decisión se repite muchas veces. Maximin
    (Wald): maximiza el peor resultado dentro del conjunto identificado — decisiones
    irreversibles o catastróficas en el peor caso. Minimax regret (Savage): minimiza
    la máxima pérdida respecto a la mejor acción en cada escenario — el que Manski
    defiende para reglas de tratamiento cuando el maximin resulta paralizante.",
)

#cap-demostracion(pasos: (
  [Con un efecto cuyo IC cruza el cero, la utilidad esperada puede recomendar
   intervenir (punto positivo) mientras el maximin recomienda no hacerlo (peor caso
   dañino).],
  [El minimax regret puede recomendar una acción intermedia — tratar a un
   subconjunto, o postergar y experimentar.],
  ["No decidir todavía y experimentar" debería estar en el conjunto de acciones
   factibles: el valor de un experimento que reduce la incertidumbre compite
   legítimamente con las acciones sustantivas.],
))

#cap-interactivo(
  tipo: "Conceptual",
  pregunta: "El policy learning del Cap. 21 (a quién tratar bajo presupuesto) es un
    caso particular de este marco — identifique explícitamente cuál es D y cuál es U
    en ese capítulo.",
)

#cap-codigo-parte(
  titulo: "Selección de acción óptima con incertidumbre",
  snippet: "politicas = {\n"
    + "    \"sin_intervencion\": {\"efecto\": 0.0, \"se\": 0.0, \"costo\": 0},\n"
    + "    \"transferencia_simple\": {\"efecto\": 0.12, \"se\": 0.03, \"costo\": 500},\n"
    + "    \"transferencia_mas_capacitacion\": {\"efecto\": 0.19, \"se\": 0.05, \"costo\": 900},\n"
    + "}\n\n"
    + "def utilidad_esperada(efecto, costo, valor_por_punto_efecto=3000, presupuesto=1000):\n"
    + "    \"\"\"Utilidad: valor monetario del efecto menos el costo.\"\"\"\n"
    + "    if costo > presupuesto:\n"
    + "        return -np.inf\n"
    + "    return valor_por_punto_efecto * efecto - costo\n\n"
    + "for nombre, datos in politicas.items():\n"
    + "    u = utilidad_esperada(datos[\"efecto\"], datos[\"costo\"])\n"
    + "    # bandas de utilidad con +/- 1.96 SE del efecto\n"
    + "    u_low = utilidad_esperada(datos[\"efecto\"] - 1.96*datos[\"se\"], datos[\"costo\"])\n"
    + "    u_high = utilidad_esperada(datos[\"efecto\"] + 1.96*datos[\"se\"], datos[\"costo\"])\n"
    + "    print(f\"{nombre:30s} U={u:8.1f}  IC95%=({u_low:.1f}, {u_high:.1f})\")\n\n"
    + "mejor = max(politicas, key=lambda k: utilidad_esperada(politicas[k][\"efecto\"], politicas[k][\"costo\"]))\n"
    + "print(f\"Accion optima bajo esta utilidad: {mejor}\")",
  nota: "Reportar el intervalo de utilidad, no solo el punto: una accion con mayor U
    puntual pero IC muy solapado con otra no es \"claramente superior\". La accion
    optima depende de valor_por_punto_efecto — parametro NORMATIVO que ningun dato
    determina.",
)

#cap-caso-resolucion(
  titulo: "Tres diseños de programa de transferencias",
  contexto: "Transferencia simple / con condicionalidad / con capacitación — costos
    administrativos y efectos esperados distintos.",
  resultado: "La acción óptima depende críticamente de valor_por_punto_efecto — un
    parámetro NORMATIVO que ningún dato por sí solo puede determinar.",
  interpretacion: "Dos analistas razonables pueden discrepar en ese parámetro y
    llegar a decisiones óptimas distintas con el MISMO efecto estimado.",
)

#cap-mapeo-pch-activo(
  nivel: "L2 (utilidad esperada sobre distribución interventiva)",
  metrica: "d* = argmax E[U(Y(do(d)))]; regret bajo cada criterio",
  pregunta-activa: "¿Cambia la acción óptima si se usa maximin en vez de utilidad
    esperada, y qué le dice ese cambio sobre cuánto pesa la incertidumbre en la
    decisión?",
)

#cap-errores-transiciones(
  errores: (
    ("crítico", [Función de utilidad implícita y no examinada: toda decisión
      automatizada usa alguna, aunque nadie la haya escrito — hacerla explícita
      permite auditarla.]),
    ("advertencia", [Sensibilidad de la decisión a la utilidad supuesta: reportar
      cómo cambia $d^*$ bajo utilidades alternativas.]),
    ("advertencia", [Confundir incertidumbre estadística con estructural: un IC
      estrecho no dice nada sobre si el SCM supuesto es correcto.]),
  ),
  conexiones: "Conecta con la teoría de la decisión estadística clásica (Berger,
    1985) y con el marco de identificación parcial (Manski, 2004).",
)

#cap-discusion-ejercicio(
  pregunta: "Proponga una función de utilidad alternativa que dé peso explícito a la
    equidad distributiva (penalice que el efecto se concentre en un subgrupo). ¿Cambia
    la acción óptima?",
  ejercicio: "Extienda el listado con maximin y minimax regret, tomando como
    conjunto identificado τ̂±1.96·SE de cada política. ¿Coinciden las tres
    recomendaciones? Amplíe el SE de la política más costosa y observe cuándo
    divergen.",
)

#cap-cierre-narrativo(
  resumen: (
    [Toda decisión requiere una función de utilidad, aunque sea implícita.],
    [Bajo identificación parcial, utilidad esperada / maximin / minimax regret pueden
     recomendar acciones distintas.],
    [Experimentar es una acción más del conjunto factible cuando la incertidumbre es
     la restricción vinculante.],
  ),
  refs: (
    [Manski (2004), reglas de tratamiento bajo identificación parcial],
    [Berger (1985), teoría de la decisión estadística],
  ),
  transicion: "Cap. 26 — Generalización y transportabilidad entre dominios",
  gancho: "Toda decisión estructural asume que el efecto vale para la población sobre
    la que se decide — ¿y si la política se aplica en otro mercado?",
)
