// Capítulo 15 (nuevo) — Despliegue de un estimador causal como servicio
// Plantilla B: Sesión 12. Cierra la Parte II. Corresponde al Notebook de producción HF #1.
#import "../template/template.typ": *

#chapter[Despliegue de un estimador causal como servicio]
<cap-despliegue-servicio>

#theorem-number-reset()

#cuadrodecision[
  #table(
    columns: (auto, 1fr),
    align: (left, left),
    stroke: none,
    [*Decisión:*], [Servir el estimador como un servicio REST síncrono, no como biblioteca embebida ni como batch],
    [*Alternativas:*], [Biblioteca embebida vs. servicio web vs. predicciones _batch_ precomputadas],
    [*Trade-off clave:*], [Latencia y simplicidad de biblioteca vs. desacoplamiento y reutilización de un servicio],
    [*Stack:*], [FastAPI, Docker, `joblib`],
    [*Riesgo principal:*], [_Training-serving skew_: que el cálculo de _features_ en producción difiera del usado al entrenar],
  )
]

#monorepo[
  Implementación de referencia: #code[04_notebooks_produccion_hf/B1_fastapi_dml/] (FastAPI, #code[inference.py] pura, Docker). Artefacto de entrada: #code[artifacts/A2/dml_estimator.joblib] + #code[feature_list.json] (lista de covariables; análogo operativo a #code[schema.covariates]). Labs: #code[L12], #code[L14]. Humo: #code[autograder/grade_b1.py]. El endpoint expone #code[/health], #code[/metadata] y #code[/predict].
]

== El problema de diseño
<sec-despliegue-problema>

El @cap-dml produjo un estimador DML entrenado y validado según los criterios del @cap-validacion. El problema de este capítulo, que cierra la Parte II, es distinto: ¿cómo se pone ese estimador a disposición de alguien —un compañero de equipo, otro servicio, una aplicación— que necesita una estimación puntual sin tener que reabrir el notebook de entrenamiento? La respuesta no es única; @huyen2022dmls (Capítulo 7) y @kastner2024mlip (Capítulo 10) describen varios patrones de _serving_ con distintos costos y beneficios, y elegir entre ellos es, otra vez, una decisión de diseño y no un detalle de implementación menor.

== Opciones y trade-offs
<sec-despliegue-opciones>

#opciones[
  - *Biblioteca embebida.* El modelo serializado se distribuye como un paquete de Python que cualquier proceso importa directamente (`from causal_lib import estimar_efecto`). Es la opción de menor latencia (no hay llamada de red) y la más simple de depurar. Su costo: cada consumidor necesita el mismo entorno de Python con las mismas versiones de dependencias, y actualizar el modelo requiere redistribuir el paquete a todos los consumidores.
  - *Servicio web (REST/gRPC).* El modelo vive detrás de un endpoint HTTP; los consumidores envían covariables y reciben una estimación, sin necesidad de tener Python ni las dependencias del modelo instaladas. Permite actualizar el modelo en un solo lugar y servir a consumidores en cualquier lenguaje. Su costo es la latencia de red y la necesidad de operar un servicio (disponibilidad, escalado, versionado de la API).
  - *_Batch_ precomputado.* Las estimaciones se calculan por adelantado para toda la población conocida y se almacenan en una tabla que se consulta por clave. Es la opción de menor latencia de consulta y la más simple de auditar (todas las estimaciones existen antes de cualquier consulta), pero no sirve para unidades nuevas no vistas al momento del cómputo _batch_, y el "efecto estimado" puede quedar desactualizado si las covariables de una unidad cambian entre el cómputo y la consulta.
]

Un segundo trade-off es la función de inferencia misma: @kastner2024mlip enfatiza que esta función debe ser *pura* —sin efectos secundarios, sin estado mutable entre llamadas— precisamente para que el mismo código pueda ejecutarse de forma idéntica en el notebook de entrenamiento y en el servicio de producción, evitando el problema de _training-serving skew_ ya anticipado en el @cap-anatomia-sistema.

== Decisión de referencia para el curso
<sec-despliegue-decision>

El curso adopta un *servicio REST síncrono con FastAPI*, containerizado con Docker, como patrón de referencia para todos los notebooks de producción de la Serie B. Se prefiere sobre la biblioteca embebida porque el objetivo pedagógico incluye publicar el modelo en Hugging Face Hub (Capítulo 19) para que cualquiera pueda consultarlo sin instalar el entorno del curso; se prefiere sobre el _batch_ precomputado porque los casos de uso del curso (Notebooks A2 y A4) requieren estimar el efecto para unidades nuevas, no solo para una población fija conocida de antemano.

== Implementación de referencia
<sec-despliegue-implementacion>

La función de inferencia se separa explícitamente del servicio HTTP, reutilizando el `CausalSchema` del @cap-ingenieria-datos-causales para garantizar que las covariables se interpreten exactamente igual que en el entrenamiento:

#figure(
  kind: raw,
  caption: [Función de inferencia pura, desacoplada del framework web.],
  ```python
# inference.py -- funcion pura, sin dependencias de FastAPI
import joblib
import numpy as np
import pandas as pd

_modelo = joblib.load("model/dml_estimator.joblib")
_schema = joblib.load("model/causal_schema.joblib")

def estimar_efecto(covariables: dict) -> dict:
    """Funcion pura: mismas entradas siempre producen la misma salida,
    sin efectos secundarios. Se prueba igual en notebook y en produccion."""
    faltantes = set(_schema.covariates) - set(covariables.keys())
    if faltantes:
        raise ValueError(f"Faltan covariables requeridas por el schema: {faltantes}")
    X = pd.DataFrame([covariables])[_schema.covariates]
    efecto = _modelo.effect(X)[0]
    ic_inf, ic_sup = _modelo.effect_interval(X, alpha=0.05)
    return {
        "efecto_estimado": float(efecto),
        "ic_95_inferior": float(ic_inf[0]),
        "ic_95_superior": float(ic_sup[0]),
        # ic_individual: anadir solo si existe calibracion conforme (Cap. 14);
        # nunca reutilizar ic_95 como intervalo para decisiones individuales
        "poblacion_entrenamiento": _schema.covariates,  # transparencia sobre validez
    }
```
) <lst-inference-pura>

#figure(
  kind: raw,
  caption: [Servicio FastAPI que envuelve la función de inferencia.],
  ```python
# app.py
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from inference import estimar_efecto, metadatos_modelo

app = FastAPI(title="Servicio de estimacion causal - curso IA Causal en Produccion")

class Covariables(BaseModel):
    exper: float
    black: int
    south: int
    married: int

@app.post("/predict")
def predict(cov: Covariables):
    try:
        return estimar_efecto(cov.model_dump())
    except ValueError as e:
        raise HTTPException(status_code=422, detail=str(e))

@app.get("/health")
def health():
    """Liveness: el proceso responde. No dice nada sobre validez causal."""
    return {"status": "ok"}

@app.get("/metadata")
def metadata():
    """Contrato causal del servicio: estimando, supuestos, poblacion y
    version. Es lo que permite a un consumidor decidir si el efecto es
    aplicable a su caso ANTES de llamar a /predict."""
    return metadatos_modelo()
```
) <lst-fastapi-app>

El endpoint `/metadata` no es decorativo ni redundante con la _model card_ del Capítulo 19. Una _model card_ es documentación para personas y vive en el repositorio; `/metadata` es el mismo contrato expuesto *en tiempo de ejecución y de forma legible por máquina*, de modo que un consumidor automatizado pueda verificar programáticamente qué versión del modelo está respondiendo y bajo qué supuestos, sin depender de que alguien haya leído el README. Es también lo que permite que el monitoreo del @cap-monitoreo-causal compare la población que efectivamente consulta el servicio contra la población declarada de entrenamiento:

#figure(
  kind: raw,
  caption: [Metadatos del modelo, servidos desde el mismo artefacto que la inferencia.],
  ```python
# inference.py (continuacion del listado anterior)
def metadatos_modelo() -> dict:
    """Funcion pura: describe el contrato causal del artefacto servido.
    El dict devuelto valida contra causal-model-card-v1.schema.json (Ap. G.4);
    el CI del curso lo verifica antes de publicar."""
    return {
        "estimando": _meta["estimando"],              # p.ej. "ATE" o "CATE(x)"
        "diseno_identificacion": _meta["diseno"],     # observacional / IV / RCT
        "supuestos": _meta["supuestos"],              # lista declarada, ver Cap. 19
        "covariables_requeridas": _schema.covariates,
        "poblacion_entrenamiento": _meta["poblacion"],
        "version_modelo": _meta["version"],
        "hash_datos_entrenamiento": _meta["hash_datos"],
    }
```
) <lst-metadata-endpoint>

#figure(
  kind: raw,
  caption: [`Dockerfile` para contenerizar el servicio.],
  ```dockerfile
FROM python:3.11-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY inference.py app.py ./
COPY model/ ./model/
EXPOSE 8000
CMD ["uvicorn", "app:app", "--host", "0.0.0.0", "--port", "8000"]
```
) <lst-dockerfile>

La prueba de humo del Notebook de producción B1 verifica los tres endpoints en ese orden, y el orden es deliberado: `/health` comprueba que el proceso vive, `/metadata` que el artefacto cargado es el esperado (versión y hash de datos), y solo entonces `/predict` que la estimación es razonable. Un fallo en el segundo con éxito en el primero es exactamente el escenario silencioso que este capítulo busca hacer visible: el servicio responde, pero está sirviendo un modelo distinto del que el equipo cree.

== Aplicación al sistema causal del curso
<sec-despliegue-aplicacion>

Nótese que la respuesta de `estimar_efecto()` en el listado @lst-inference-pura no devuelve solo el efecto puntual: incluye el intervalo de confianza y la lista de covariables de la población de entrenamiento. Esto no es una decisión estética. El @cap-anatomia-sistema comprometió, como parte de la anatomía de un sistema causal responsable, que la interfaz debe comunicar algo más que un número —precisamente para que ningún consumidor del servicio use el efecto estimado como si fuera válido para una población distinta a la de entrenamiento sin, al menos, tener esa información disponible en la propia respuesta de la API.

== Señales de alerta y checklist operativo
<sec-despliegue-alertas>

#checklist[
  - La función de inferencia calcula las _features_ con código distinto al usado durante el entrenamiento (riesgo directo de _training-serving skew_).
  - El endpoint devuelve solo el efecto puntual, sin intervalo de confianza ni información de la población de entrenamiento.
  - No existe una ruta `/health` verificable independientemente de `/predict`.
  - No hay forma de saber, consultando el servicio, qué versión del modelo está respondiendo ni sobre qué datos se entrenó (`/metadata` ausente o sin `version_modelo`/`hash_datos_entrenamiento`).
  - El `Dockerfile` no fija versiones exactas de las dependencias (`requirements.txt` sin _pinning_), con riesgo de que el contenedor se comporte distinto según cuándo se construya.
]

== Ejercicios y notas bibliográficas
<sec-despliegue-ejercicios>

=== Ejercicios conceptuales
<sec-despliegue-ejercicios-conceptuales>

+ Para el caso de uso del Notebook A4 (política óptima de targeting, Módulo 4), ¿cuál de las tres opciones de la @sec-despliegue-opciones sería más apropiada si el número de clientes a evaluar es fijo y conocido cada mes? Justifique.

+ Explique, con sus propias palabras, por qué separar `inference.py` de `app.py` (listados @lst-inference-pura y @lst-fastapi-app) facilita probar la lógica de inferencia sin necesidad de levantar el servidor web.

=== Ejercicio de infraestructura (Lab, Notebook B1)
<sec-despliegue-ejercicios-lab>

+ Complete el Notebook de producción B1: serialice el estimador DML entrenado en el Notebook A2, adapte los listados @lst-inference-pura, @lst-fastapi-app y @lst-dockerfile a su dataset, construya la imagen Docker y verifique que `/health` y `/predict` responden correctamente con `curl` o el cliente HTTP de su elección.

=== Notas bibliográficas
<sec-despliegue-notas>

#cite(<huyen2022dmls>, form: "prose"), Capítulo 7 ("Model Deployment and Prediction Service"), y @kastner2024mlip, Capítulo 10 ("Deploying a Model"), son las dos referencias principales de este capítulo; el segundo desarrolla en particular la discusión de _features_ dentro/fuera del servicio y el _training-serving skew_ retomada en la @sec-despliegue-aplicacion.
