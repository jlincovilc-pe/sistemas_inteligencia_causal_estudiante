// =============================================================================
// Diapositivas · Capítulo 15 — Despliegue de un estimador causal como servicio
// Fuente: 02_monografia/.../capitulos/cap07b_despliegue_servicio.typ
// Plan detallado: PLAN_SPRINT_DIAPOSITIVAS.md §3, "Cap. 15"
// Sesión S12 · Lab L12 · Entrega: B1 arranca · Variante B · ★ camino crítico
// =============================================================================
#import "../plantilla_monografia.typ": *

#show: cap-theme

#cap-init(num: 15, titulo: "Despliegue de un estimador causal como servicio",
  parte: "II", sesion: "S12", variant: "B", critico: true)

#cap-progreso-curso(cap-actual: 15)
#cap-portada(num: 15, titulo: "Despliegue de un estimador causal como servicio",
  parte: "II", sesion: "S12", variant: "B", critico: true)

#cap-roadmap(
  objetivos: (
    [Justificar biblioteca vs. servicio vs. batch para un caso dado.],
    [Separar la función de inferencia pura del framework web.],
    [Explicar qué expone /metadata que /health no expone.],
  ),
  agenda: (
    [Cómo poner el estimador a disposición de otros],
    [Biblioteca / servicio REST / batch precomputado],
    [Decisión: FastAPI + Docker],
    [inference.py puro + app.py + /metadata],
    [Por qué la respuesta incluye IC y población de entrenamiento],
  ),
  lectura: "Cap. 15 — Despliegue como servicio (@cap-despliegue-servicio)",
  lab: "L12", entrega: "B1 arranca",
)

#cap-problema-diseno(
  decision: "Servir el estimador como un servicio REST síncrono, no como biblioteca
    embebida ni como batch.",
  alternativas: "Biblioteca embebida vs. servicio web vs. predicciones batch
    precomputadas.",
  tradeoff: "Latencia y simplicidad de biblioteca vs. desacoplamiento y reutilización
    de un servicio.",
  stack: "FastAPI, Docker, joblib.",
  riesgo: "Training-serving skew: que el cálculo de features en producción difiera
    del usado al entrenar.",
)

#cap-opciones-tradeoffs(opciones: (
  ([Biblioteca embebida], [Menor latencia, más simple de depurar. Cada consumidor
    necesita el mismo entorno; actualizar exige redistribuir.]),
  ([Servicio REST/gRPC], [Consumidores en cualquier lenguaje; un solo lugar para
    actualizar. Costo: latencia de red y operar el servicio.]),
  ([Batch precomputado], [Menor latencia de consulta, más auditable. No sirve para
    unidades nuevas ni covariables que cambiaron desde el cómputo.]),
))

#cap-decision-referencia(
  decision: "Servicio REST síncrono con FastAPI, containerizado con Docker. La función
    de inferencia (inference.py) se separa del framework web (app.py) y reutiliza el
    CausalSchema del Cap. 4.",
  justificacion: "Publicar en Hugging Face Hub (Cap. 19) requiere que cualquiera lo
    consulte sin instalar el entorno del curso; los Notebooks A2/A4 requieren estimar
    para unidades nuevas, no solo una población fija.",
)

#cap-codigo-parte(
  titulo: "inference.py — función pura",
  snippet: "# inference.py -- funcion pura, sin dependencias de FastAPI\n"
    + "import joblib\n"
    + "import pandas as pd\n\n"
    + "_modelo = joblib.load('model/dml_estimator.joblib')\n"
    + "_schema = joblib.load('model/causal_schema.joblib')\n\n"
    + "def estimar_efecto(covariables: dict) -> dict:\n"
    + "    \"\"\"Funcion pura: mismas entradas producen la misma salida,\n"
    + "    sin efectos secundarios. Se prueba igual en notebook y en produccion.\"\"\"\n"
    + "    faltantes = set(_schema.covariates) - set(covariables.keys())\n"
    + "    if faltantes:\n"
    + "        raise ValueError(f'Faltan covariables requeridas: {faltantes}')\n"
    + "    X = pd.DataFrame([covariables])[_schema.covariates]\n"
    + "    efecto = _modelo.effect(X)[0]\n"
    + "    ic_inf, ic_sup = _modelo.effect_interval(X, alpha=0.05)\n"
    + "    return {\n"
    + "        'efecto_estimado': float(efecto),\n"
    + "        'ic_95_inferior': float(ic_inf[0]),\n"
    + "        'ic_95_superior': float(ic_sup[0]),\n"
    + "        # ic_individual: solo si hay calibracion conforme (Cap. 14)\n"
    + "        'poblacion_entrenamiento': _schema.covariates,  # transparencia\n"
    + "    }",
)
#cap-codigo-parte(
  titulo: "app.py — /health, /metadata, /predict",
  snippet: "# app.py -- FastAPI delgado alrededor de inference.py\n"
    + "from fastapi import FastAPI, HTTPException\n"
    + "from pydantic import BaseModel\n"
    + "from inference import estimar_efecto, metadatos_modelo\n\n"
    + "app = FastAPI(title='Servicio de estimacion causal')\n\n"
    + "class Covariables(BaseModel):\n"
    + "    exper: float; black: int; south: int; married: int\n\n"
    + "@app.post('/predict')\n"
    + "def predict(cov: Covariables):\n"
    + "    try:\n"
    + "        return estimar_efecto(cov.model_dump())\n"
    + "    except ValueError as e:\n"
    + "        raise HTTPException(status_code=422, detail=str(e))\n\n"
    + "@app.get('/health')\n"
    + "def health():\n"
    + "    return {'status': 'ok'}  # liveness; no valida el contrato causal\n\n"
    + "@app.get('/metadata')\n"
    + "def metadata():\n"
    + "    # Contrato causal legible por maquina: estimando, supuestos, poblacion,\n"
    + "    # version, hash_datos_entrenamiento; valida contra\n"
    + "    # causal-model-card-v1.schema.json (Ap. G.4)\n"
    + "    return metadatos_modelo()",
  nota: "El orden de la prueba de humo es health → metadata → predict: un fallo en
    metadata con éxito en health es el escenario silencioso que este capítulo hace
    visible.",
)

#cap-monorepo(texto-monorepo: "04_notebooks_produccion_hf/B1_fastapi_dml/ (FastAPI,
  inference.py pura, Docker). Artefacto de entrada: artifacts/A2/dml_estimator.joblib +
  feature_list.json. Labs: L12, L14. Humo: autograder/grade_b1.py.")

#cap-caso-resolucion(
  titulo: "Por qué la respuesta incluye IC y población",
  contexto: "El Cap. 2 comprometió que la interfaz debe comunicar algo más que un
    número.",
  resultado: "estimar_efecto() devuelve efecto_estimado, ic_95_inferior,
    ic_95_superior, poblacion_entrenamiento — no solo el punto.",
  interpretacion: "Ningún consumidor del servicio puede usar el efecto fuera de su
    población sin, al menos, tener esa información disponible en la propia
    respuesta.",
)

#cap-mapeo-pch-activo(
  nivel: "Transversal (sirve una estimación de L2 ya validada)",
  metrica: "/predict con efecto + IC; /metadata con contrato causal legible por
    máquina",
  pregunta-activa: "Si /health responde 200 OK pero /metadata expone un hash de datos
    distinto al esperado, ¿el sistema está \"arriba\"?",
)

#cap-checklist-alertas(items: (
  [La función de inferencia calcula features con código distinto al de
   entrenamiento.],
  [El endpoint devuelve solo el efecto puntual, sin IC ni población.],
  [No existe una ruta /health verificable independientemente de /predict.],
  [No hay forma de saber, consultando el servicio, qué versión del modelo responde ni
   sobre qué datos se entrenó.],
))

#cap-interactivo(
  tipo: "Aplicado",
  pregunta: "¿Por qué separar inference.py de app.py facilita probar la lógica de
    inferencia sin levantar el servidor web?",
)

#cap-discusion-ejercicio(
  pregunta: "Para el caso del Notebook A4 (política óptima, número fijo de clientes
    cada mes), ¿cuál de las tres opciones sería más apropiada? Justifique.",
  ejercicio: "Complete el Notebook B1: serialice el estimador del Notebook A2, adapte
    los tres listados, construya la imagen Docker y verifique /health + /metadata +
    /predict con curl.",
)

#cap-cierre-narrativo(
  resumen: (
    [La decisión de despliegue (biblioteca/servicio/batch) depende del caso de uso, no
     hay opción universalmente correcta.],
    [inference.py puro + app.py delgado evita training-serving skew y facilita testear
     la lógica sin servidor.],
    [/metadata expone el contrato causal en tiempo de ejecución — versión, supuestos,
     población — legible por máquina.],
  ),
  refs: (
    [Huyen (2022), Cap. 7, "Model Deployment and Prediction Service"],
    [Kästner, Kang & Hilton (2024), Cap. 10, "Deploying a Model"],
  ),
  transicion: "Cap. 16 — Post-Double-Selection LASSO (◇, ampliación de S5; en el libro
    cierra la Parte II)",
  gancho: "El servicio ya expone un ATE; la Parte III retoma la pregunta de
    identificación con diseños completos, empezando por la que ya se usó en S5 en su
    versión avanzada.",
)
