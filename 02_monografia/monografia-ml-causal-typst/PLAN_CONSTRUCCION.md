# Plan de construcción por etapas — Monografía "IA Causal en Producción"

## Corrección importante sobre la entrega anterior

El documento `esqueleto_monografia.md` entregado antes de este plan tenía un error: al mapear capítulos nuevos a las sesiones del sílabo, **omitió silenciosamente 6 capítulos que ya existen y están completos** en la monografía original (`cap08_pds`, `cap09_panel_dmliv`, `cap10_mapa_decision`, `cap13_deep_causal`, `cap14_scm_matrix_completion`, y no integraba con claridad `cap16_etica_interpretabilidad`). Este plan lo corrige: **ningún capítulo existente se elimina**; todos se reubican dentro de la nueva estructura, y el contenido nuevo (Bareinboim + DMLS) se inserta alrededor de ellos.

## Estructura final (9 partes, 32 capítulos)

`E` = existente (se adapta/reubica, sin reescritura sustancial) · `N-A` = nuevo, Plantilla A (teoría causal) · `N-B` = nuevo, Plantilla B (ingeniería/producción) · `N-H` = nuevo, híbrido A/B

| # | Parte | Cap. | Título | Estado | Archivo |
|---|---|---|---|---|---|
| 0 | Introducción | 1 | Causalidad elemental y el problema fundamental de la inferencia causal | **N-A ✅ escrito** | `cap00_causalidad_elemental.typ` |
| 0 | Introducción | 2 | Anatomía de un sistema de ML en producción | **N-B ✅ escrito** | `cap00b_anatomia_sistema.typ` |
| I | Fundamentos estructurales y de datos | 3 | Modelos Causales Estructurales y la Jerarquía Causal de Pearl | **N-A ✅ escrito** | `cap00c_scm_pch.typ` |
| I | Fundamentos estructurales y de datos | 4 | Ingeniería de datos para sistemas causales | **N-B ✅ escrito** | `cap00d_ingenieria_datos.typ` |
| I | Fundamentos estructurales y de datos | 5 | Predicción y causalidad: por qué el ML no es causal por defecto | **E ✅ reubicado** (cap01) | `cap01_prediccion_causalidad.typ` |
| I | Fundamentos estructurales y de datos | 6 | Regularización y post-selección | **E ✅ reubicado** (cap02) | `cap02_regularizacion_postseleccion.typ` |
| I | Fundamentos estructurales y de datos | 7 | Datos de entrenamiento en sistemas causales | **N-B ✅ escrito** | `cap02b_datos_entrenamiento.typ` |
| I | Fundamentos estructurales y de datos | 8 | Razonamiento intervencional y contrafactual | **N-A ✅ escrito** | `cap02c_intervencion_contrafactual.typ` |
| I | Fundamentos estructurales y de datos | 9 | Ingeniería de *features* sin fuga causal | **N-B ✅ escrito** | `cap02d_features_sin_fuga.typ` |
| II | Estimación causal flexible y primer despliegue | 10 | Ortogonalidad de Neyman y *cross-fitting* | **E ✅ reubicado** (cap03) | `cap03_ortogonalidad_crossfitting.typ` |
| II | Estimación causal flexible y primer despliegue | 11 | Double Machine Learning: PLR e IRM | **E ✅ reubicado** (cap04) | `cap04_dml.typ` |
| II | Estimación causal flexible y primer despliegue | 12 | Meta-learners | **E ✅ reubicado** (cap05) | `cap05_metalearners.typ` |
| II | Estimación causal flexible y primer despliegue | 13 | Árboles y bosques causales | **E ✅ reubicado** (cap06) | `cap06_arboles_bosques.typ` |
| II | Estimación causal flexible y primer despliegue | 14 | Validación y evaluación *offline* de estimadores causales | **✅ ampliado** (cap07 + sección N-B) | `cap07_validacion.typ` |
| II | Estimación causal flexible y primer despliegue | 15 | Despliegue de un estimador causal como servicio | **N-B ✅ escrito** | `cap07b_despliegue_servicio.typ` |
| III | Diseños de identificación con ML | 16 | Post-Double-Selection | **E ✅ reubicado** (cap08) | `cap08_pds.typ` |
| III | Diseños de identificación con ML | 17 | Panel y DML-IV | **E ✅ reubicado** (cap09) | `cap09_panel_dmliv.typ` |
| III | Diseños de identificación con ML | 18 | Mapa de decisión metodológica | **E ✅ reubicado** (cap10) | `cap10_mapa_decision.typ` |
| IV | Publicación y operación en producción | 19 | *Model cards* causales y publicación en Hugging Face Hub | **N-B ✅ escrito** | `cap10b_hf_hub.typ` |
| IV | Publicación y operación en producción | 20 | CI/CD para modelos causales | **N-B ✅ escrito** | `cap10c_cicd.typ` |
| V | Heterogeneidad, políticas y *targeting* | 21 | Policy learning | **E ✅ reubicado** (cap11) | `cap11_policy_learning.typ` |
| V | Heterogeneidad, políticas y *targeting* | 22 | Uplift/targeting | **E ✅ reubicado** (cap12) | `cap12_uplift_targeting.typ` |
| VI | Explicación, equidad y decisión estructural | 23 | Explicación causal y equidad algorítmica | **N-A ✅ escrito** | `cap12b_explicacion_equidad.typ` |
| VI | Explicación, equidad y decisión estructural | 24 | Ética e interpretabilidad en ML causal | **E ✅ reubicado** (cap16) | `cap16_etica_interpretabilidad.typ` |
| VI | Explicación, equidad y decisión estructural | 25 | Decisiones estructurales bajo incertidumbre | **N-A ✅ escrito** | `cap12c_decisiones_estructurales.typ` |
| VI | Explicación, equidad y decisión estructural | 26 | Generalización y transportabilidad entre dominios | **N-A ✅ escrito** | `cap12d_generalizacion.typ` |
| VII | Métodos avanzados | 27 | Deep causal learning | **E ✅ reubicado** (cap13) | `cap13_deep_causal.typ` |
| VII | Métodos avanzados | 28 | SCM y *matrix completion* | **E ✅ reubicado** (cap14) | `cap14_scm_matrix_completion.typ` |
| VIII | Estructura, monitoreo y frontera | 29 | Descubrimiento de estructura causal | E (cap15) | `cap15_descubrimiento_grafos.typ` |
| VIII | Estructura, monitoreo y frontera | 30 | Monitoreo de supuestos causales en producción | N-B | `cap15b_monitoreo.typ` |
| VIII | Estructura, monitoreo y frontera | 31 | Aprendizaje continuo y panorama de RL causal | N-H | `cap15c_aprendizaje_continuo.typ` |
| VIII | Estructura, monitoreo y frontera | 32 | El lado humano de los sistemas causales | N-B | `cap15d_lado_humano.typ` |

Apéndices nuevos: **G** (plantilla de *model card* causal), **H** (checklist de arquitectura de despliegue). Los apéndices A–F existentes se conservan; se revisan en la Etapa 10 por consistencia de referencias cruzadas.

## Etapas de construcción

| Etapa | Contenido | Estado |
|---|---|---|
| 0 | Plan (este documento) + funciones Typst de Plantilla B en `template.typ` + entradas de bibliografía nuevas | **✅ completa** |
| 1 | Parte 0 — Cap. 1 y Cap. 2 | **✅ completa** |
| 2 | Parte I — Cap. 3, 4, 7, 8, 9 (nuevos) · reubicar Cap. 5 y 6 (E) a su nueva posición | **✅ completa** |
| 3 | Parte II — adaptar Cap. 10–13 (E) · escribir Cap. 14 (ampliación N-B de validación) y Cap. 15 (N-B) | pendiente (siguiente) |
| 3 | Parte II — adaptar Cap. 10–13 (E) · escribir Cap. 14 (ampliación N-B de validación) y Cap. 15 (N-B) | **✅ completa** |
| 4 | Parte III — adaptar Cap. 16–18 (E), solo renumeración y enlaces cruzados | **✅ completa** (hecha antes que la Etapa 3, a pedido) |
| 5 | Parte IV — Cap. 19–20 (N-B, íntegramente nuevos) | **✅ completa** |
| 6 | Parte V — adaptar Cap. 21–22 (E) | **✅ completa** |
| 7 | Parte VI — Cap. 23, 25, 26 (N-A) · adaptar Cap. 24 (E) | **✅ completa** |
| 8 | Parte VII — adaptar Cap. 27–28 (E) | **✅ completa** |
| 9 | Parte VIII — adaptar Cap. 29 (E) · Cap. 30–32 (N-B/N-H) | **✅ completa** |
| 10 | Apéndices G–H nuevos · revisión de apéndices A–F · `main.typ` final con todos los `#include` · `partes/*.typ` renombradas y renumeradas (0 a VIII) · bibliografía final · compilación y entrega del proyecto completo | **✅ completa** |

**Nota sobre compilación:** este entorno no tiene un compilador de Typst disponible, así que no se puede verificar visualmente (PDF) en cada etapa. Cada archivo se revisa manualmente (balance de paréntesis/corchetes, pares de énfasis, existencia de las claves de bibliografía citadas) antes de entregarse, pero la verificación definitiva de compilación queda del lado del usuario, idealmente al cierre de cada etapa o al final. `main.typ` no se reescribe hasta la Etapa 10 para evitar dejarlo en un estado roto entre etapas; los capítulos nuevos se entregan como archivos sueltos, listos para integrarse.

## Hallazgos incidentales durante la construcción

- **`cap09_panel_dmliv.typ`, línea 133** (ahora Capítulo 17): se encontró y corrigió un paréntesis de cierre sobrante en la fórmula del estimador DML-panel dentro del bloque `#algorithm`, preexistente en el archivo original (no introducido durante esta construcción). Detectado por el chequeo automatizado de balance de paréntesis por línea al verificar el Capítulo 17 en la Etapa 4.
- **Etapa 3:** al insertar la nota de transición en `cap05_metalearners.typ` (ahora Capítulo 12), un primer intento duplicó accidentalmente la etiqueta `<sec-cap05_problema>`; se detectó con el chequeo de etiquetas duplicadas y se corrigió antes de empaquetar. También se perdió por error la línea de encabezado `== Ejercicios y notas bibliográficas` en `cap07_validacion.typ` al insertar la nueva sección de evaluación *offline*; ambos errores quedaron corregidos y verificados (balance de paréntesis, encabezados, etiquetas duplicadas, referencias cruzadas y citas — sobre las 41 archivos del proyecto) antes de esta entrega.


## Cierre del proceso — estado final

**Las 11 etapas están completas.** El libro tiene su estructura final: 9 partes, 32 capítulos, 8 apéndices, 56 archivos `.typ` en total. Resumen de lo construido:

- **16 capítulos enteramente nuevos**: Caps. 1, 2, 3, 4, 7, 8, 9, 15, 19, 20, 23, 25, 26, 30, 31, 32 — combinan Plantilla B (ingeniería/producción, todos nuevos) con teoría causal pura de Bareinboim no cubierta en la monografía original (Plantilla A: Caps. 1, 3, 8, 23, 25, 26).
- **16 capítulos reubicados** de la monografía original (Caps. 5, 6, 10, 11, 12, 13, 14, 16, 17, 18, 21, 22, 24, 27, 28, 29), sin reescritura sustancial, cada uno con una nota de transición breve conectándolo a sus nuevos vecinos.
- **2 apéndices nuevos** (G: plantilla de *model card* causal: H: checklist de arquitectura de despliegue), más los 6 apéndices originales conservados sin cambios de contenido.
- **9 páginas de parte** reescritas para la nueva estructura (la anterior tenía 6).
- **Frontmatter actualizado**: portada, metadata del documento, prefacio y "cómo usar este libro" reflejan la nueva estructura de dos plantillas y el balance teoría/práctica.
- **21 entradas bibliográficas nuevas** agregadas a `refs.yml` a lo largo del proceso.

**Verificación final (sin compilador de Typst disponible en este entorno):** se corrió, sobre los 56 archivos `.typ` del proyecto completo, un chequeo de (a) balance de paréntesis/corchetes por archivo, respetando bloques de código en bruto; (b) unicidad de las 32 etiquetas de capítulo y de todas las demás etiquetas del proyecto (cero duplicados); (c) que las ~90 citas bibliográficas usadas en el texto existen en `refs.yml` (cero huérfanas); (d) que las referencias cruzadas entre capítulos (`@cap-...`, `@sec-...`, `@lst-...`) apuntan a una etiqueta real (cero rotas, con una única falsa alarma dentro de un comentario de código, no en texto real); y (e) que los 54 `#include` de `main.typ` apuntan todos a un archivo que existe en disco. Esto da alta confianza de que el proyecto compila, pero **no reemplaza una compilación real** — se recomienda correr `typst compile main.typ` como último paso antes de considerar el libro definitivamente cerrado.
