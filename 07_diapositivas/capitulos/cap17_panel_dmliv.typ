// =============================================================================
// Diapositivas · Capítulo 17 — Machine learning causal en datos de panel
// Fuente: 02_monografia/.../capitulos/cap09_panel_dmliv.typ
// Plan detallado: PLAN_SPRINT_DIAPOSITIVAS.md §3, "Cap. 17"
// Sin sesión propia — electivo / oficina de proyectos sectoriales. Variante A · ◇
// =============================================================================
#import "../plantilla_monografia.typ": *

#show: cap-theme

#cap-init(num: 17, titulo: "Machine learning causal en datos de panel",
  parte: "III", sesion: "electivo", variant: "A", critico: false)

#cap-portada(num: 17, titulo: "Machine learning causal en datos de panel",
  parte: "III", sesion: "electivo", variant: "A", critico: false)

#cap-roadmap(
  objetivos: (
    [Aplicar within-transformation + cross-fitting para paneles con efectos fijos.],
    [Explicar por qué DML-panel hereda el problema de pesos negativos de TWFE bajo
     adopción escalonada.],
    [Verificar la fuerza de un instrumento con el F de primera etapa.],
  ),
  agenda: (
    [Reforma laboral en 32 regiones, staggered adoption],
    [Within-transformation + score ortogonal],
    [Advertencia: TWFE y pesos negativos (Goodman-Bacon)],
    [DML-IV: F de primera etapa y el umbral de Stock & Yogo],
  ),
  lectura: "Cap. 17 — Panel y DML-IV (@cap-panel-dmliv) — electivo, sin sesión
    dedicada",
  lab: "—", entrega: "—",
)

#cap-motivacion(
  problema: "Reforma laboral adoptada en distintos años en 32 regiones (staggered
    adoption). Con muchas características regionales que afectan tanto la adopción
    como el empleo, los efectos fijos clásicos pueden no bastar.",
  gancho: "La within-transformation deja el modelo en forma PLR estándar — pero es
    exactamente TWFE, y hereda sus problemas bajo heterogeneidad.",
  caso: "Panel sintético con CATE conocido (panel_fe_dynamic).",
)

// Contenido nuevo — la correccion mas importante del capitulo.
#cap-teorema(
  titulo: "Advertencia: within-transformation = TWFE",
  enunciado: "Con adopción escalonada y efectos heterogéneos, TWFE compara unidades
    recién tratadas contra unidades YA tratadas antes (Goodman-Bacon, 2021) —
    generando pesos potencialmente NEGATIVOS (de Chaisemartin & D'Haultfœuille, 2020):
    el coeficiente puede tener signo opuesto al efecto verdadero aunque el efecto sea
    del mismo signo en todas las unidades. Flexibilizar los nuisance con ML NO repara
    un estimando mal definido.",
)

#cap-demostracion(pasos: (
  [Si hay adopción escalonada y efectos heterogéneos: NO usar TWFE (ni DML-panel sobre
   datos within-transformados) sin antes verificar la descomposición de
   Goodman-Bacon.],
  [Alternativas robustas: Callaway-Sant'Anna, Sun-Abraham, o Borusyak et al. (2024) —
   agregación explícita del efecto por cohorte de adopción.],
  [Para instrumentos: el F de primera etapa (umbral $F>10$, Stock & Yogo 2005) —
   calculado sobre el instrumento EXCLUIDO, no el F global del modelo.],
))

// C11 (Etapa 2) -- inferencia robusta a instrumentos debiles: el IC de
// Anderson-Rubin es valido cualquiera sea la fuerza del instrumento.
#cap-teorema(
  titulo: "Inferencia robusta a instrumentos débiles: Anderson–Rubin",
  enunciado: "El test de Anderson–Rubin invierte tests de hipótesis sobre θ: el
    IC se construye como el conjunto de valores θ0 para los que NO se rechaza
    H0:θ=θ0, y es válido cualquiera sea la fuerza del instrumento — a costa de
    poder ser un conjunto, no un intervalo, cuando la identificación es débil.
    Con muchos instrumentos, los tests de Kleibergen–Paap y el criterio de
    Stock–Yogo para tamaño de test reemplazan al F de un solo instrumento.
    Regla operativa del curso: si F≤10, el reporte del diseño IV incluye el IC
    de Anderson–Rubin junto al de Wald; si difieren materialmente, la estimación
    se declara sensible a la fuerza del instrumento y el Cap. 30 la monitorea
    con doble umbral.",
)

#cap-caso-resolucion(
  titulo: "DML-panel vs. FE clásico",
  contexto: "panel_fe_dynamic (sintético, ground truth conocido, τ≈1.0).",
  resultado: "DML-panel: consistente con el valor verdadero, estable en K. FE clásico
    (LSDV): sesgo sistemático por no capturar no linealidades en X_it.",
  interpretacion: "Válido bajo efecto constante — el supuesto que la advertencia de
    arriba pone en cuestión si hay adopción escalonada.",
)

#cap-mapeo-pch-activo(
  nivel: "L2 (panel, exogeneidad tras controlar efectos fijos)",
  metrica: "θ0 panel con SE cluster-robusto; F de primera etapa para IV; IC de
    Anderson-Rubin si F≤10",
  pregunta-activa: "Si el coeficiente TWFE tiene el signo opuesto al de todos los
    efectos individuales, ¿el problema es de datos o del estimando mismo?",
)

#cap-discusion-ejercicio(
  pregunta: "¿Por qué un $F>10$ en la primera etapa no garantiza inferencia válida si
    los nuisance se estimaron con ML en vez de una primera etapa lineal?",
  ejercicio: "Construya un panel donde el supuesto de tendencias paralelas se
    vulnere. Muestre que DML-panel produce un estimado sesgado en ese caso.",
)

#cap-cierre-narrativo(
  resumen: (
    [Within-transformation resuelve efectos fijos pero es TWFE — hereda pesos
     negativos bajo adopción escalonada.],
    [Callaway-Sant'Anna / Sun-Abraham / Borusyak et al. son las alternativas
     robustas.],
    [El F de primera etapa se calcula sobre el instrumento excluido, no el F global.],
  ),
  refs: (
    [Goodman-Bacon (2021), descomposición de TWFE],
    [de Chaisemartin & D'Haultfœuille (2020), pesos negativos],
    [Stock & Yogo (2005), instrumentos débiles],
    [Andrews et al. (2019) / Stock (2002), Anderson-Rubin y muchos instrumentos],
  ),
  transicion: "Cap. 18 — Diseño de investigación y selección de método",
  gancho: "Con tres diseños completos (DML llano, PDS, panel/IV), falta organizar
    cuándo usar cada uno — y sus alternativas de mayor fuerza identificadora.",
)
