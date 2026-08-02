// Apéndice G — Plantilla de model card causal
#import "../template/template.typ": *

#chapter[Plantilla de _model card_ causal]
<ap-model-card-causal>

#theorem-number-reset()

Este apéndice desarrolla en detalle la plantilla de _model card_ causal introducida en el @cap-hf-hub, con la explicación de cada campo y un ejemplo completo. Se usa para todo modelo publicado en Hugging Face Hub a lo largo del curso, incluido el proyecto final.

== Campos obligatorios y su propósito
<sec-apG-campos>

#table(
  columns: (1.3fr, 2.7fr),
  align: left,
  stroke: 0.5pt + gray.lighten(60%),
  table.header([*Campo*], [*Qué debe responder*]),
  [Estimando], [¿Qué cantidad exacta se estima? (ATE, CATE$(x)$, LATE, política óptima). No basta con nombrar la variable de resultado.],
  [Diseño de identificación], [¿Experimental, cuasi-experimental (panel, IV, RDD) u observacional puro? Determina qué tan defendible es el resultado sin supuestos adicionales.],
  [Supuestos declarados], [Lista explícita: no confusión condicional en qué covariables, soporte común, exclusión del instrumento si aplica, tendencias paralelas si aplica. Referencia al DAG cuando exista uno (@cap-intervencion-contrafactual).],
  [Población de entrenamiento], [Las variables que delimitan la población (edad, geografía, período temporal, criterio de elegibilidad) — la información mínima para aplicar el criterio de transportabilidad del @cap-generalizacion-transportabilidad antes de reusar el modelo.],
  [Métricas], [Efecto puntual, intervalo de confianza, tamaño de muestra, especificación del estimador (_learner_, número de _folds_).],
  [Resultados de validación], [Resultado de la prueba placebo (@cap-validacion) y del chequeo de balance (@cap-datos-entrenamiento-causales) más recientes.],
  [No usar este modelo para], [Lista explícita de usos indebidos previsibles: poblaciones fuera de rango, decisiones individuales sin considerar el intervalo, reinterpretación del ATE como efecto garantizado.],
  [Historial de versiones], [Fecha de cada reentrenamiento, resultado del proceso _champion-challenger_ (@cap-aprendizaje-continuo) que lo promovió.],
)

== Plantilla completa
<sec-apG-plantilla>

#figure(
  kind: raw,
  caption: [Plantilla completa de _model card_ causal, para copiar como `README.md` del repositorio en Hugging Face Hub.],
  ```markdown
---
license: mit
tags: [causal-inference, <metodo-usado>]
---

# <Nombre del modelo>

## Estimando
<Que cantidad causal exacta estima este modelo.>

## Diseno de identificacion
<Experimental / cuasi-experimental / observacional. Justificacion breve.>

## Supuestos declarados
- No confusion condicional en: <lista de covariables>
- Soporte comun: <verificado / no verificado, como>
- <Otros supuestos especificos del diseno: exclusion del instrumento,
  tendencias paralelas, etc.>
- DAG (si existe): <enlace o referencia>

## Poblacion de entrenamiento
<Variables que delimitan la poblacion. Rango temporal. Fuente de datos.>
**No valido fuera de esta poblacion sin verificar transportabilidad.**

## Metricas
- Efecto estimado: <valor> (IC 95%: [<inf>, <sup>])
- n = <tamano de muestra>
- Especificacion: <learner, K-folds, etc.>

## Resultados de validacion
- Prueba placebo: <paso / no paso, fecha>
- Chequeo de balance: <resultado, fecha>

## No usar este modelo para
- <Uso indebido 1>
- <Uso indebido 2>

## Historial de versiones
| Version | Fecha | Cambio | Promovido por |
|---------|-------|--------|----------------|
| v1.0    | <fecha> | Version inicial | — |
```
) <lst-apG-plantilla-completa>

== Checklist antes de publicar
<sec-apG-checklist>

#checklist[
  - Todos los campos obligatorios de la @sec-apG-campos están completos, ninguno dice "N/A" sin justificación.
  - La sección "No usar este modelo para" incluye al menos un uso indebido específico del dominio del modelo, no solo genérico.
  - El `CausalSchema` (@cap-ingenieria-datos-causales) del modelo se subió junto con el artefacto serializado.
  - La _model card_ se actualizó en la misma publicación que cualquier reentrenamiento (ninguna versión del modelo circula con una _model card_ desactualizada).
]
