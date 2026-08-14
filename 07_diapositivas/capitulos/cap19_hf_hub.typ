// =============================================================================
// Diapositivas · Capítulo 19 — Model cards causales y publicación en Hugging
// Face Hub
// Fuente: 02_monografia/.../capitulos/cap10b_hf_hub.typ
// Plan detallado: PLAN_SPRINT_DIAPOSITIVAS.md §3, "Cap. 19"
// Sesión S17 · Lab L17 · Entrega: B2 arranca · Variante B · ★ camino crítico
// =============================================================================
#import "../plantilla_monografia.typ": *

#show: cap-theme

#cap-init(num: 19, titulo: "Model cards causales y publicación en Hugging Face Hub",
  parte: "IV", sesion: "S17", variant: "B", critico: true)

#cap-progreso-curso(cap-actual: 19)
#cap-portada(num: 19, titulo: "Model cards causales y publicación en Hugging Face Hub",
  parte: "IV", sesion: "S17", variant: "B", critico: true)

#cap-roadmap(
  objetivos: (
    [Completar una model card causal con estimando, diseño y supuestos.],
    [Explicar qué le falta a una model card estándar para un modelo causal.],
    [Publicar modelo + card en Hugging Face Hub.],
  ),
  agenda: (
    [La model card estándar no tiene campo para supuestos],
    [Model card estándar vs. causal extendida],
    [Decisión: campos obligatorios de la card causal],
    [Datasheets como pieza complementaria (Cap. 7)],
    [Publicación en el Hub],
  ),
  lectura: "Cap. 19 — Hub y model cards (@cap-hf-hub)",
  lab: "L17", entrega: "B2 arranca",
)

#cap-problema-diseno(
  decision: "Documentar supuestos de identificación en la model card, no solo
    métricas de desempeño.",
  alternativas: "Model card estándar (solo accuracy/desempeño) vs. model card causal
    extendida.",
  tradeoff: "Fricción de documentar más campos vs. riesgo de uso indebido del modelo
    por otros equipos.",
  stack: "huggingface_hub, Hugging Face Hub.",
  riesgo: "Que un consumidor del modelo lo use fuera de su población o supuestos de
    validez sin saberlo.",
)

#cap-opciones-tradeoffs(opciones: (
  ([Model card estándar], [Arquitectura, accuracy/F1/RMSE, consideraciones éticas
    generales. Sin campo para el DAG, la puerta trasera ni la población de
    validez.]),
  ([Model card causal extendida], [Añade estimando, supuestos declarados, diseño
    (observacional/cuasi-experimental/experimental), población, límites de validez
    externa. Costo puramente de fricción.]),
))

#cap-decision-referencia(
  decision: "Plantilla de model card causal (Apéndice G) con campos obligatorios:
    estimando, diseño de identificación, supuestos declarados, población de
    entrenamiento, sección explícita \"no usar este modelo para\".",
  justificacion: "La model card extendida domina a la estándar para cualquier modelo
    causal — la opción por defecto de las herramientas (incluido HF Hub) es la
    estándar, y usarla sin extenderla es la ruta de menor resistencia.",
)

#cap-codigo-parte(
  titulo: "Plantilla de model card causal",
  snippet: "---\n"
    + "license: mit\n"
    + "tags: [causal-inference, dml, econml]\n"
    + "---\n\n"
    + "# Estimador DML de retorno a la educacion\n\n"
    + "## Estimando\n"
    + "ATE del efecto de anios de educacion (`educ`) sobre el log salario (`wage`).\n\n"
    + "## Diseno de identificacion\n"
    + "Observacional. No confusion condicional en: exper, black, south, married\n"
    + "(ver DAG en `docs/dag.png`).\n\n"
    + "## Poblacion de entrenamiento\n"
    + "Hombres, 24-34 anios, NLS 1976 (Card, 1995). n=3,003.\n"
    + "**No valido fuera de este rango etario ni fuera de EE.UU.**\n\n"
    + "## Metricas\n"
    + "ATE estimado: 0.071 (IC 95%: [0.058, 0.084]). Cross-fitting: K=5.\n"
    + "Learner: GradientBoostingRegressor.\n\n"
    + "## No usar este modelo para\n"
    + "- Poblaciones fuera del rango de entrenamiento.\n"
    + "- Decisiones individuales sin considerar el intervalo de confianza del CATE.\n"
    + "- Reinterpretar el ATE como efecto garantizado a nivel individual.",
)
#cap-codigo-parte(
  titulo: "Publicación en el Hub",
  snippet: "from huggingface_hub import HfApi, upload_file\n\n"
    + "api = HfApi()\n"
    + "repo_id = 'curso-ia-causal/dml-retorno-educacion'\n"
    + "api.create_repo(repo_id, repo_type='model', exist_ok=True)\n\n"
    + "upload_file(path_or_fileobj='model/dml_estimator.joblib',\n"
    + "            path_in_repo='dml_estimator.joblib', repo_id=repo_id)\n"
    + "upload_file(path_or_fileobj='model/causal_schema.joblib',\n"
    + "            path_in_repo='causal_schema.joblib', repo_id=repo_id)\n"
    + "upload_file(path_or_fileobj='MODEL_CARD.md',\n"
    + "            path_in_repo='README.md', repo_id=repo_id)  # HF renderiza README.md como card",
)

#cap-monorepo(texto-monorepo: "04_notebooks_produccion_hf/B2_hub_cicd/model_card/
  MODEL_CARD.md (alineada al Apéndice G). Lab L17. Bundle para Hub:
  scripts/prepare_hub_bundle.sh. La card debe declarar estimando (ATE), supuestos,
  población del monorepo (ihdp_medium) y límites (datos sintéticos de benchmark; no
  uso clínico).")

#cap-caso-resolucion(
  titulo: "Datasheets como pieza complementaria (conexión con el Cap. 7)",
  contexto: "Gebru et al. (2021): datasheets for datasets — cómo se recolectaron los
    datos, con qué propósito, qué preprocesamiento sufrieron.",
  resultado: "La mitad de los campos de una datasheet son exactamente la ficha de
    procedencia del tratamiento del Cap. 7.",
  interpretacion: "Una model card causal sin su datasheet documenta el modelo pero no
    lo que lo hace válido.",
)

#cap-mapeo-pch-activo(
  nivel: "Transversal (documentación del contrato causal, no un nivel nuevo)",
  metrica: "Model card completa: estimando + supuestos + población + límites",
  pregunta-activa: "Si alguien descarga el modelo del Hub sin leer la card, ¿qué le
    impide usarlo fuera de su población de validez?",
)

#cap-checklist-alertas(items: (
  [La model card reporta métricas de desempeño pero no el diseño de identificación ni
   los supuestos.],
  [No existe una sección explícita de "no usar para".],
  [El repositorio del Hub no incluye el CausalSchema junto al modelo serializado.],
  [La model card no se actualizó tras reentrenar el modelo con datos nuevos.],
  [El bundle publicado no incluye el JSON Schema validado (Ap. G.4) — solo el
   Markdown, sin forma verificable por CI.],
))

#cap-interactivo(
  tipo: "Aplicado",
  pregunta: "Compare la plantilla causal con una model card estándar de un modelo de
    clasificación público. Liste tres campos presentes en la causal y ausentes en la
    estándar.",
)

#cap-discusion-ejercicio(
  pregunta: "¿Por qué la sección \"no usar para\" cita directamente el Cap. 26
    (transportabilidad)?",
  ejercicio: "Complete la primera mitad del Notebook B2: adapte la plantilla al
    modelo del Notebook A2, publique en Hugging Face Hub, verifique el renderizado.",
)

#cap-cierre-narrativo(
  resumen: (
    [Una model card causal documenta supuestos de identificación, no solo
     desempeño.],
    [Datasheets (Cap. 7) y model card son piezas complementarias, no
     intercambiables.],
    [Publicar sin la card extendida invita a usar el modelo fuera de su dominio de
     validez.],
  ),
  refs: (
    [Mitchell et al. (2019), model cards],
    [Gebru et al. (2021), datasheets for datasets],
    [Arnold et al. (2019), FactSheets],
  ),
  transicion: "Cap. 20 — CI/CD para modelos causales",
  gancho: "Documentar los supuestos no impide que alguien los rompa sin querer al
    modificar el código — falta automatizar el chequeo.",
)
