// =============================================================================
// Diapositivas · Capítulo 20 — CI/CD para modelos causales
// Fuente: 02_monografia/.../capitulos/cap10c_cicd.typ
// Plan detallado: PLAN_SPRINT_DIAPOSITIVAS.md §3, "Cap. 20"
// Sesión S18 · Lab L18 · Entrega: B2 entrega · Variante B · ★ camino crítico
// =============================================================================
#import "../plantilla_monografia.typ": *

#show: cap-theme

#cap-init(num: 20, titulo: "CI/CD para modelos causales",
  parte: "IV", sesion: "S18", variant: "B", critico: true)

#cap-progreso-curso(cap-actual: 20)
#cap-portada(num: 20, titulo: "CI/CD para modelos causales",
  parte: "IV", sesion: "S18", variant: "B", critico: true)

#cap-roadmap(
  objetivos: (
    [Diseñar un pipeline con etapa de software y etapa estadística separadas.],
    [Escribir una prueba de humo tipo placebo que bloquee publicación.],
    [Situar el pipeline del curso dentro del ecosistema MLOps estándar.],
  ),
  agenda: (
    [Un CI genérico no detecta que un placebo dejó de dar cero],
    [CI genérico vs. CI con pruebas estadísticas integradas],
    [Decisión: dos etapas, software + estadística],
    [Workflow + prueba de humo placebo],
    [Dónde encaja MLflow/DVC/Great Expectations/Evidently],
  ),
  lectura: "Cap. 20 — CI/CD causal (@cap-cicd-causal)",
  lab: "L18", entrega: "B2 entrega",
)

#cap-problema-diseno(
  decision: "El pipeline de CI debe correr pruebas de sanidad estadística, no solo
    pruebas de código.",
  alternativas: "CI genérico (solo tests de software) vs. CI con pruebas estadísticas
    causales integradas.",
  tradeoff: "Tiempo de ejecución del pipeline vs. riesgo de publicar automáticamente
    un modelo roto.",
  stack: "GitHub Actions, pytest, Docker.",
  riesgo: "Que un cambio de código pase todos los tests de software y aun así rompa la
    validez causal.",
)

#cap-opciones-tradeoffs(opciones: (
  ([CI genérico], [¿El código importa sin error? ¿El endpoint responde? Rápido, pero
    un cambio que introduce un mal control pasa sin ninguna advertencia.]),
  ([CI con pruebas estadísticas], [Placebo + chequeo de balance como parte del
    pipeline, con umbrales que bloquean la publicación automática. Más lento, requiere
    dataset de referencia fijo.]),
))

#cap-decision-referencia(
  decision: "Pipeline en dos etapas: software (segundos, cada push) y estadística
    (minutos, solo antes de publicar al Hub).",
  justificacion: "Evita que cada cambio menor dispare un reentrenamiento costoso, sin
    sacrificar la garantía de que nada se publica sin pasar la prueba de sanidad
    estadística.",
)

#cap-codigo-parte(
  titulo: "Workflow con dos etapas",
  snippet: "# .github/workflows/ci-cd.yml\n"
    + "name: CI/CD modelo causal\n"
    + "on: [push]\n\n"
    + "jobs:\n"
    + "  tests-software:          # segundos, en cada push\n"
    + "    runs-on: ubuntu-latest\n"
    + "    steps:\n"
    + "      - uses: actions/checkout@v4\n"
    + "      - uses: actions/setup-python@v5\n"
    + "        with: { python-version: '3.11' }\n"
    + "      - run: pip install -r requirements.txt\n"
    + "      - run: pytest tests/test_software.py -v\n\n"
    + "  tests-estadisticos:      # minutos, solo antes de publicar al Hub\n"
    + "    needs: tests-software\n"
    + "    if: github.ref == 'refs/heads/main'\n"
    + "    runs-on: ubuntu-latest\n"
    + "    steps:\n"
    + "      - uses: actions/checkout@v4\n"
    + "      - run: pip install -r requirements.txt\n"
    + "      - run: python scripts/validar_schema.py  # card vs causal-model-card-v1.schema.json (Ap. G.4)\n"
    + "      - run: pytest tests/test_placebo.py -v --tb=short\n"
    + "      - run: pytest tests/test_balance.py -v --tb=short\n\n"
    + "  publicar-hub:            # bloqueado si tests-estadisticos falla\n"
    + "    needs: tests-estadisticos\n"
    + "    if: github.ref == 'refs/heads/main'\n"
    + "    runs-on: ubuntu-latest\n"
    + "    steps:\n"
    + "      - uses: actions/checkout@v4\n"
    + "      - run: pip install huggingface_hub\n"
    + "      - run: python scripts/publicar_hub.py\n"
    + "        env:\n"
    + "          HF_TOKEN: ${{ secrets.HF_TOKEN }}",
)
#cap-codigo-parte(
  titulo: "Prueba de humo: placebo no significativo",
  snippet: "# tests/test_placebo.py\n"
    + "import joblib\n"
    + "import pandas as pd\n"
    + "import numpy as np\n\n"
    + "def test_placebo_no_significativo():\n"
    + "    modelo = joblib.load('model/dml_estimator.joblib')\n"
    + "    df = pd.read_parquet('data/referencia_ci.parquet')  # dataset fijo de referencia\n"
    + "    rng = np.random.default_rng(0)\n"
    + "    D_placebo = rng.permutation(df['educ'].values)  # tratamiento aleatorizado\n"
    + "    X = df[['exper', 'black', 'south', 'married']]\n"
    + "    efecto_placebo = modelo.effect(X).mean()\n"
    + "    ic_inf, ic_sup = modelo.effect_interval(X, alpha=0.05)\n"
    + "    assert ic_inf.mean() <= 0 <= ic_sup.mean(), (\n"
    + "        f'Placebo significativo: IC=({ic_inf.mean():.3f}, {ic_sup.mean():.3f})'\n"
    + "    )",
)

#cap-monorepo(texto-monorepo: ".github/workflows/b1_smoke.yml y
  course_practice_ci.yml (pytest Serie A, labs, humo B1-B4). Lab L18. Autograders:
  grade_b1.py...grade_b4.py. Auditoría local: bash scripts/audit_repo.sh.")

#cap-caso-resolucion(
  titulo: "Dónde encaja el ecosistema MLOps estándar",
  contexto: "MLflow/W&B para experimentos, DVC para versionar el dataset de
    referencia, Great Expectations/Pandera para validar esquema, Evidently para
    drift.",
  resultado: "Ninguna de estas herramientas sabe qué es un placebo, un chequeo de
    balance o un IC sobre un efecto — se detienen en integridad de datos y métricas
    predictivas.",
  interpretacion: "La etapa tests-estadisticos es específica del dominio causal y hay
    que escribirla; el resto del ecosistema no se reimplementa.",
)

#cap-mapeo-pch-activo(
  nivel: "Transversal (garantiza que L2 siga siendo válido tras cada cambio)",
  metrica: "Placebo + balance como gate de publicación automática",
  pregunta-activa: "Un cambio legítimo en el mundo también puede romper un umbral
    estadístico — ¿por qué el pipeline no debe \"arreglar el código hasta que pase\"
    en ese caso?",
)

#cap-checklist-alertas(items: (
  [El pipeline solo corre pruebas de software; ningún job verifica placebo o
   balance.],
  [El dataset de referencia no está versionado — las pruebas dan resultados
   distintos en ejecuciones distintas.],
  [La publicación ocurre en el mismo job que las pruebas de software.],
  [Nadie revisa manualmente los resultados de las pruebas estadísticas cuando
   fallan.],
))

#cap-interactivo(
  tipo: "Aplicado",
  pregunta: "Tres criterios de diseño de la etapa estadística: dataset congelado y
    versionado, umbrales fijados antes (no ajustados al fallar), fallo estadístico ≠
    fallo de software. ¿Cuál se viola con más frecuencia en la práctica?",
)

#cap-discusion-ejercicio(
  pregunta: "¿Por qué separar pruebas de software (cada push) de pruebas
    estadísticas (solo antes de publicar) es mejor diseño que correr ambas en cada
    commit?",
  ejercicio: "Complete el Notebook B2: implemente el workflow y las pruebas,
    verifique que remover un control clave bloquea el job publicar-hub.",
)

#cap-cierre-narrativo(
  resumen: (
    [Un CI genérico no detecta ruptura de validez causal.],
    [Dos etapas: software en cada push, estadística antes de publicar.],
    [El ecosistema MLOps estándar cubre integridad de datos y drift; la sanidad
     causal (placebo, balance) es responsabilidad del equipo.],
  ),
  refs: (
    [Huyen (2022) / Kästner et al. (2024), CI/CD para ML],
    [Breck et al. (2017), ML Test Score],
  ),
  transicion: "Cap. 23 — Explicación causal y equidad algorítmica (S19)",
  gancho: "Con el sistema desplegado, publicado y auditado automáticamente, la
    pregunta cambia de validez estadística a validez frente a personas: ¿el efecto se
    explica igual que se predice?",
)
