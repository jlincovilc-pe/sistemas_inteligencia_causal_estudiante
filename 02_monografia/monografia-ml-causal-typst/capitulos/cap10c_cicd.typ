// Capítulo 20 (nuevo) — CI/CD para modelos causales
// Plantilla B: Sesión 18. Cierra la Parte IV. Notebook de producción HF #2 (parte 2).
#import "../template/template.typ": *

#chapter[CI/CD para modelos causales]
<cap-cicd-causal>

#theorem-number-reset()

#cuadrodecision[
  #table(
    columns: (auto, 1fr),
    align: (left, left),
    stroke: none,
    [*[Decisión]*], [El pipeline de CI debe correr pruebas de sanidad estadística, no solo pruebas de código],
    [*[Alternativas]*], [CI genérico (solo tests de software) vs. CI con pruebas estadísticas causales integradas],
    [*[Trade-off clave]*], [Tiempo de ejecución del pipeline vs. riesgo de publicar automáticamente un modelo roto],
    [*[Stack]*], [GitHub Actions, `pytest`, Docker],
    [*[Riesgo principal]*], [Que un cambio de código pase todos los tests de software y aun así rompa la validez causal],
  )
]

#monorepo[
  Workflows de referencia: #code[.github/workflows/b1_smoke.yml] y #code[course_practice_ci.yml] (pytest Serie A, labs, humo B1–B4). Lab #code[L18]. Autograders: #code[grade_b1.py]…#code[grade_b4.py]. Auditoría local de un comando: #code[bash scripts/audit_repo.sh]. CI genérico de software *no basta*: el pipeline del curso exige humo de efecto/API/política.
]

== El problema de diseño
<sec-cicd-problema>

El Capítulo 15 construyó el servicio; el Capítulo 19 lo publicó en el Hub. Ninguno de los dos automatizó lo que ocurre *después*: cuando alguien modifica el código —agrega una covariable, cambia el _learner_ de _nuisance_, actualiza los datos de entrenamiento— ¿qué garantiza que la nueva versión no rompió algo antes de que se publique automáticamente? Un pipeline de CI/CD genérico —el que prueba, por ejemplo, que el endpoint responde con el código HTTP correcto— no detecta absolutamente nada sobre si el efecto estimado sigue siendo razonable. El problema de diseño de este capítulo es que un sistema causal necesita, además de las pruebas de software estándar, pruebas que sean sensibles a *lo que este curso entiende por "romperse"*: que un placebo deje de dar cero, que el intervalo de confianza colapse o se dispare, que el soporte común desaparezca con los nuevos datos.

== Opciones y trade-offs
<sec-cicd-opciones>

#opciones[
  - *CI genérico.* Corre únicamente pruebas de software: ¿el código importa sin error?, ¿el endpoint responde?, ¿el contenedor construye? Es rápido (segundos a minutos) y es lo que la mayoría de las plantillas de GitHub Actions ofrecen por defecto. No detecta ningún problema de validez estadística: un cambio que introduce un mal control (@cap-intervencion-contrafactual) pasa este CI sin ninguna advertencia.
  - *CI con pruebas estadísticas integradas.* Además de las pruebas de software, ejecuta la prueba placebo y el chequeo de balance ya usados en capítulos anteriores (@cap-datos-entrenamiento-causales, @cap-validacion) como parte del pipeline automatizado, con umbrales que, si se violan, bloquean la publicación automática. Es más lento (minutos, porque implica reentrenar o reestimar sobre datos de prueba) y requiere mantener un dataset de referencia fijo para que las pruebas sean reproducibles, pero es la única opción que previene que una regresión estadística llegue a producción sin supervisión humana.
]

== Decisión de referencia para el curso
<sec-cicd-decision>

El pipeline de referencia del curso corre en dos etapas: una etapa rápida de pruebas de software (segundos) en cada _push_, y una etapa de pruebas estadísticas (la prueba placebo del @cap-validacion sobre un dataset de referencia fijo) que se ejecuta antes de cualquier publicación al Hub, no en cada _commit_. Esta separación —común en la práctica de CI/CD general y aquí adaptada al caso causal— evita que cada cambio menor de código dispare un reentrenamiento costoso, sin sacrificar la garantía de que nada se publica sin pasar la prueba de sanidad estadística.

== Implementación de referencia
<sec-cicd-implementacion>

#figure(
  kind: raw,
  caption: [_Workflow_ de GitHub Actions con pruebas de software y estadísticas en etapas separadas.],
  ```yaml
# .github/workflows/ci-cd.yml
name: CI/CD modelo causal

on: [push]

jobs:
  tests-software:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-python@v5
        with: { python-version: "3.11" }
      - run: pip install -r requirements.txt
      - run: pytest tests/test_software.py -v
      - name: Build Docker image
        run: docker build -t causal-service:${{ github.sha }} .

  tests-estadisticos:
    needs: tests-software
    if: github.ref == 'refs/heads/main'
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-python@v5
        with: { python-version: "3.11" }
      - run: pip install -r requirements.txt
      - name: Prueba placebo (Cap. 14)
        run: pytest tests/test_placebo.py -v --tb=short
      - name: Chequeo de balance (Cap. 7)
        run: pytest tests/test_balance.py -v --tb=short

  publicar-hub:
    needs: tests-estadisticos
    if: github.ref == 'refs/heads/main'
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: pip install huggingface_hub
      - name: Publicar en Hugging Face Hub
        env:
          HF_TOKEN: ${{ secrets.HF_TOKEN }}
        run: python scripts/publicar_hub.py
```
) <lst-cicd-workflow>

#figure(
  kind: raw,
  caption: [Prueba estadística de humo: el placebo no debe ser significativo.],
  ```python
# tests/test_placebo.py
import joblib
import pandas as pd
import numpy as np

def test_placebo_no_significativo():
    modelo = joblib.load("model/dml_estimator.joblib")
    df = pd.read_parquet("data/referencia_ci.parquet")  # dataset fijo de referencia
    rng = np.random.default_rng(0)
    D_placebo = rng.permutation(df["educ"].values)  # tratamiento aleatorizado
    efecto_placebo = modelo.effect(df[["exper", "black", "south", "married"]]).mean()
    ic_inf, ic_sup = modelo.effect_interval(
        df[["exper", "black", "south", "married"]], alpha=0.05
    )
    assert ic_inf.mean() <= 0 <= ic_sup.mean(), (
        f"Placebo significativo: IC=({ic_inf.mean():.3f}, {ic_sup.mean():.3f}). "
        "El pipeline no publica automaticamente -- revisar antes de forzar merge."
    )
```
) <lst-test-placebo>

== Aplicación al sistema causal del curso
<sec-cicd-aplicacion>

El _job_ `publicar-hub` del listado @lst-cicd-workflow solo se ejecuta si `tests-estadisticos` pasó — es decir, la publicación automática al Hub (Capítulo 19) queda condicionada a que el placebo y el balance sigan siendo razonables, no solo a que el código compile. Esta es, en términos concretos, la implementación de la *confiabilidad* como requisito de sistema que el @cap-anatomia-sistema definió al inicio del curso: el sistema "sigue produciendo el comportamiento correcto" porque el pipeline se lo exige mecánicamente, no porque alguien se acuerde de verificarlo manualmente antes de cada publicación.

== Señales de alerta y checklist operativo
<sec-cicd-alertas>

#checklist[
  - El pipeline de CI/CD solo corre pruebas de software; ningún job verifica placebo, balance o cobertura de intervalos.
  - El dataset de referencia usado en las pruebas estadísticas no está versionado, por lo que las pruebas pueden dar resultados distintos en ejecuciones distintas sin que nadie lo note.
  - La publicación al Hub ocurre en el mismo job que las pruebas de software, sin depender del resultado de las pruebas estadísticas.
  - Nadie revisa manualmente los resultados de las pruebas estadísticas cuando fallan; el pipeline solo las corre pero no las reporta de forma visible al equipo.
]

== Ejercicios y notas bibliográficas
<sec-cicd-ejercicios>

=== Ejercicios conceptuales
<sec-cicd-ejercicios-conceptuales>

+ Explique por qué separar las pruebas de software (rápidas, en cada _push_) de las pruebas estadísticas (lentas, solo antes de publicar) es un mejor diseño que correr ambas en cada _commit_. ¿Qué se pierde con esta separación?

+ Proponga una tercera prueba estadística, además del placebo y el balance, que tenga sentido incluir en el pipeline de CI para un estimador DML-IV (Capítulo 17). Justifique qué supuesto específico protege.

=== Ejercicio de infraestructura (cierra el Notebook B2)
<sec-cicd-ejercicios-infra>

+ Complete el Notebook de producción B2: implemente el _workflow_ del listado @lst-cicd-workflow y las pruebas del listado @lst-test-placebo adaptadas a su modelo, verifique que un cambio que rompe el placebo deliberadamente (por ejemplo, remover una covariable de control clave) efectivamente bloquea el job `publicar-hub`, y documente el resultado.

=== Notas bibliográficas
<sec-cicd-notas>

La práctica general de CI/CD para sistemas de ML se documenta en @huyen2022dmls y @kastner2024mlip, ya citados en capítulos anteriores; @breck2017mltestscore (citado en el @cap-anatomia-sistema) incluye explícitamente pruebas de "reproducibilidad del pipeline de entrenamiento" en su rúbrica, que este capítulo extiende con pruebas específicas de validez causal.
