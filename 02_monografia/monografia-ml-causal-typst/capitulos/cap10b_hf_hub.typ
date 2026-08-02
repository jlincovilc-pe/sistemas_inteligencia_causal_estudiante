// Capítulo 19 (nuevo) — Model cards causales y publicación en Hugging Face Hub
// Plantilla B: Sesión 17. Abre la Parte IV. Notebook de producción HF #2 (parte 1).
#import "../template/template.typ": *

#chapter[_Model cards_ causales y publicación en Hugging Face Hub]
<cap-hf-hub>

#theorem-number-reset()

#cuadrodecision[
  #table(
    columns: (auto, 1fr),
    align: (left, left),
    stroke: none,
    [*[Decisión]*], [Documentar supuestos de identificación en la _model card_, no solo métricas de desempeño],
    [*[Alternativas]*], [_Model card_ estándar (solo _accuracy_/desempeño) vs. _model card_ causal extendida],
    [*[Trade-off clave]*], [Fricción de documentar más campos vs. riesgo de uso indebido del modelo por otros equipos],
    [*[Stack]*], [`huggingface_hub`, Hugging Face Hub],
    [*[Riesgo principal]*], [Que un consumidor del modelo lo use fuera de su población o supuestos de validez sin saberlo],
  )
]

#monorepo[
  Plantilla de _model card_ causal del curso: #code[04_notebooks_produccion_hf/B2_hub_cicd/model_card/MODEL_CARD.md] (alineada al Apéndice G). Lab #code[L17]. Bundle para Hub: #code[scripts/prepare_hub_bundle.sh]. La card debe declarar estimando (ATE), supuestos, población del monorepo (#code[ihdp_medium]) y límites (datos sintéticos de benchmark; no uso clínico).
]

== El problema de diseño
<sec-hfhub-problema>

El Capítulo 15 sirvió el estimador DML como un endpoint que cualquiera puede consultar. Pero "poder consultarlo" no es lo mismo que "poder usarlo correctamente". Una _model card_ —la práctica, ya estándar en la comunidad de ML, de documentar un modelo junto con sus métricas, datos de entrenamiento y limitaciones (@mitchell2019modelcards)— resuelve ese problema para modelos predictivos. El problema de diseño de este capítulo es que la _model card_ estándar no tiene ningún campo para lo que más importa en un modelo *causal*: bajo qué supuestos de identificación es válido, para qué población se estimó el efecto, y qué covariables se controlaron. Publicar un estimador causal en Hugging Face Hub con una _model card_ genérica es, en la práctica, invitar a que se use fuera de su dominio de validez.

== Opciones y trade-offs
<sec-hfhub-opciones>

#opciones[
  - *_Model card_ estándar.* Documenta arquitectura, métricas de desempeño (_accuracy_, F1, RMSE) y, en el mejor de los casos, algunas consideraciones éticas generales. Es el formato que produce por defecto la plantilla de Hugging Face Hub. Para un modelo causal, es *insuficiente*: no hay campo para el DAG supuesto, ni para el conjunto de covariables de puerta trasera, ni para la población sobre la que el efecto es válido.
  - *_Model card_ causal extendida.* Añade explícitamente los campos que un modelo predictivo no necesita: estimando ($tau(x)$, ATE, LATE), supuestos de identificación declarados, diseño (observacional/cuasi-experimental/experimental), población de entrenamiento y límites de validez externa. El costo es puramente de fricción —completar más campos antes de publicar—; no hay costo técnico ni de infraestructura.
]

La decisión no es realmente una disyuntiva difícil —la _model card_ extendida domina a la estándar para cualquier modelo causal—, pero vale la pena presentarla como *trade-off* precisamente porque la opción por defecto de la mayoría de las herramientas (incluido el propio Hugging Face Hub) es la estándar, y usarla sin extenderla es la ruta de menor resistencia.

== Decisión de referencia para el curso
<sec-hfhub-decision>

Todo modelo publicado en el curso usa la plantilla de *model card causal* del Apéndice G, con los siguientes campos obligatorios más allá del formato estándar de Hugging Face: estimando, diseño de identificación, supuestos declarados (con referencia al DAG cuando exista uno), población de entrenamiento (con las variables que la delimitan), y una sección explícita de "no usar este modelo para" — el equivalente causal de las limitaciones de una _model card_ estándar.

== Implementación de referencia
<sec-hfhub-implementacion>

#figure(
  kind: raw,
  caption: [Plantilla mínima de _model card_ causal.],
  ```markdown
---
license: mit
tags: [causal-inference, dml, econml]
---

# Estimador DML de retorno a la educacion

## Estimando
ATE del efecto de anios de educacion (`educ`) sobre el logaritmo del salario (`wage`).

## Diseno de identificacion
Observacional. Supuesto de no confusion condicional en:
exper, black, south, married (ver DAG en `docs/dag.png`).

## Poblacion de entrenamiento
Hombres, 24-34 anios, encuesta NLS 1976 (Card, 1995). n=3,003.
**No valido fuera de este rango etario ni fuera de EE.UU.**

## Metricas
ATE estimado: 0.071 (IC 95%: [0.058, 0.084])
Cross-fitting: K=5. Learner: GradientBoostingRegressor.

## No usar este modelo para
- Poblaciones fuera del rango de entrenamiento (ver @cap-generalizacion-transportabilidad).
- Decisiones individuales sin considerar el intervalo de confianza del CATE.
- Cualquier uso que reinterprete el ATE como un efecto garantizado a nivel individual.
```
) <lst-model-card-causal>

#figure(
  kind: raw,
  caption: [Publicación del modelo y su _model card_ en el Hub.],
  ```python
from huggingface_hub import HfApi, upload_file

api = HfApi()
repo_id = "curso-ia-causal/dml-retorno-educacion"
api.create_repo(repo_id, repo_type="model", exist_ok=True)

upload_file(path_or_fileobj="model/dml_estimator.joblib",
            path_in_repo="dml_estimator.joblib", repo_id=repo_id)
upload_file(path_or_fileobj="model/causal_schema.joblib",
            path_in_repo="causal_schema.joblib", repo_id=repo_id)
upload_file(path_or_fileobj="MODEL_CARD.md",
            path_in_repo="README.md", repo_id=repo_id)  # HF renderiza README.md como model card
```
) <lst-publicar-hub>

== Aplicación al sistema causal del curso
<sec-hfhub-aplicacion>

La sección "No usar este modelo para" del listado @lst-model-card-causal cita directamente el capítulo de generalización y transportabilidad (Capítulo 26, más adelante en el curso), que formaliza precisamente cuándo un efecto estimado en una población es válido en otra. Documentar la población de entrenamiento en la _model card_ no es un ejercicio de transparencia general: es la información mínima que otro analista necesitaría para aplicar, correctamente, el criterio de transportabilidad de ese capítulo antes de reutilizar el modelo.

== Señales de alerta y checklist operativo
<sec-hfhub-alertas>

#checklist[
  - La _model card_ reporta métricas de desempeño pero no menciona el diseño de identificación ni los supuestos.
  - No existe una sección explícita de "no usar para", dejando implícito el dominio de validez.
  - El repositorio del Hub no incluye el `CausalSchema` (@cap-ingenieria-datos-causales) junto al modelo serializado, obligando a cualquier consumidor a adivinar qué covariables espera.
  - La _model card_ no se actualizó tras reentrenar el modelo con datos nuevos (riesgo ya anticipado en el @cap-anatomia-sistema).
]

== Ejercicios y notas bibliográficas
<sec-hfhub-ejercicios>

=== Ejercicios conceptuales
<sec-hfhub-ejercicios-conceptuales>

+ Compare la plantilla de _model card_ causal del listado @lst-model-card-causal con una _model card_ estándar de un modelo de clasificación de Hugging Face Hub (busque un ejemplo público). Liste tres campos presentes en la causal y ausentes en la estándar, y explique por qué cada uno importa específicamente para un modelo causal.

+ @arnold2019factsheets propone una idea relacionada pero distinta a las _model cards_: las FactSheets como "declaración de conformidad del proveedor". Investigue brevemente la diferencia de enfoque y discuta si sería más o menos apropiada que una _model card_ para un estimador causal publicado por un equipo interno (no un proveedor externo).

=== Ejercicio de infraestructura
<sec-hfhub-ejercicios-infra>

+ Complete la primera mitad del Notebook de producción B2: adapte la plantilla del listado @lst-model-card-causal al modelo de su Notebook A2, publique el repositorio en Hugging Face Hub con el listado @lst-publicar-hub, y verifique que la _model card_ se renderiza correctamente en la página del repositorio.

=== Notas bibliográficas
<sec-hfhub-notas>

@mitchell2019modelcards introduce el formato de _model card_ que este capítulo extiende. @arnold2019factsheets propone un formato relacionado, orientado a proveedores de servicios de IA, con más énfasis en cumplimiento normativo. La discusión de documentación de interfaces de inferencia en general se retoma de @kastner2024mlip, Capítulo 10.
