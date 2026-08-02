// Apéndice C — Datos, DGP y benchmarks
#import "../template/template.typ": *

#chapter[Datos, DGP y benchmarks]
<ap-datos-dgp>

#theorem-number-reset()

// Alias de etiqueta preservado del original LaTeX (\label{ap:datos})
== Datasets reales
<sec-apC_reales>

#figure(
  caption: [Datasets reales del repositorio.],
  table(
    columns: (1.4fr, 0.9fr, 1.1fr, 1.0fr, 1.6fr),
    align: (left, left, left, left, left),
    stroke: none,
    table.hline(stroke: 0.8pt),
    table.header([*Dataset*], [*Diseño*], [*Estimando*], [*Caps.*], [*Notas*]),
    table.hline(stroke: 0.4pt),
    [#code[nsw_mixtape]], [Obs.], [ATE, CATE], [1, 4--6, 11], [Lalonde (1986)],
    [#code[close_college]], [IV], [ATE (LATE)], [1, 4, 8, 9, 15], [Card (1995)],
    [#code[cps_mixtape]], [Obs.], [ATE], [1, 4, 8], [CPS extract],
    [#code[nhefs]], [Obs.], [ATE, CATE], [8], [51 controles útiles],
    [#code[gov_transfers]], [Obs.], [ATE, CATE], [6, 11, 12, 16], [Transferencias],
    [#code[texas]], [SCM], [ATT], [14], [Ley aborto Texas],
    [#code[castle]], [SCM], [ATT], [14], [Castle doctrine],
    [#code[abortion]], [SCM], [ATT], [14], [Legalización aborto],
    [#code[thornton_hiv]], [RCT], [ATE, CATE], [7, 12], [Tests VIH],
    [#code[close_elections_lmb]], [RDD], [LATE], [7], [Lee (2008)],
    [#code[organ_donations]], [DiD], [ATT], [14], [Donación órganos],
    [#code[mortgages]], [Obs.], [ATE], [6], [Hipotecas],
    table.hline(stroke: 0.8pt),
  )
) <tab-apC-reales>

== Datasets sintéticos
<sec-apC_sinteticos>

#figure(
  caption: [Datasets sintéticos con _ground truth_.],
  table(
    columns: (1.5fr, 1.1fr, 1.1fr, 0.8fr, 1.5fr),
    align: (left, left, left, left, left),
    stroke: none,
    table.hline(stroke: 0.8pt),
    table.header([*Dataset*], [*Diseño*], [*Estimando*], [*Caps.*], [*Notas*]),
    table.hline(stroke: 0.4pt),
    [#code[panel_fe_dynamic]], [Panel], [ATE], [9], [$tau_i$ conocido],
    [#code[did_parallel_ok]], [DiD], [ATT], [9, 14], [Tendencias paralelas],
    [#code[did_parallel_violation]], [DiD], [ATT], [9], [TP violadas],
    [#code[staggered_twfe_bias]], [DiD stag.], [ATT], [9, 14], [Sesgo TWFE],
    [#code[iv_noncompliance]], [IV], [LATE], [9], [Cumplimiento varía],
    [#code[iv_invalid_exclusion]], [IV], [LATE], [9], [Exclusión violada],
    [#code[matching_hidden_conf]], [Matching], [ATE], [1, 5], [Confusor oculto],
    [#code[mediation_post_treatment]], [Med.], [Direct eff.], [9], [Sesgo post-trat.],
    [#code[rct_attrition]], [RCT], [ATE], [7], [Attrition],
    [#code[rdd_sharp_bandwidth]], [RDD], [LATE], [7], [Sharp design],
    [#code[rdd_fuzzy_manipulation]], [RDD], [LATE], [7], [Fuzzy + manip.],
    [#code[scm_placebo]], [SCM], [ATT], [14], [Placebo sintético],
    table.hline(stroke: 0.8pt),
  )
) <tab-apC-sinteticos>

== Estructura de archivos
<sec-apC_estructura>

Cada dataset real tiene:

- #code[data.csv]: datos en formato _tidy_.
- #code[source_metadata.json]: fuente, licencia, año, _variable dictionary_.
- #code[checksums.sha256.json]: integridad verificable.

Cada dataset sintético tiene:

- #code[student.csv]: datos visibles al estudiante (sin _ground truth_).
- #code[truth_instructor_only.csv]: _ground truth_ ($tau_i$, $theta$, etc.) para evaluación del docente.
- #code[checksums.sha256.json].

== Recomendaciones de uso por capítulo
<sec-apC_recomendaciones>

- *Capítulos 1--2 (intro, regularización):* usar #code[close_college] para motivación; sintéticos para ilustrar sesgo.
- *Capítulos 3--4 (DML):* #code[nsw_mixtape] para aplicación; sintético DML para verificar cobertura.
- *Capítulos 5--6 (meta-learners, forests):* sintético con CATE heterogéneo; #code[nsw_mixtape] (aplicación).
- *Capítulo 7 (validación):* sintético con _ground truth_; #code[thornton_hiv] para _placebos_.
- *Capítulo 8 (PDS):* #code[nhefs] para alta dimensión.
- *Capítulo 9 (panel):* #code[panel_fe_dynamic].
- *Capítulos 11--12 (policy, uplift):* #code[gov_transfers], #code[thornton_hiv].
- *Capítulo 13 (deep causal):* sintético IHDP-like.
- *Capítulo 14 (SCM, MC):* #code[texas], #code[scm_placebo].
- *Capítulo 15 (discovery):* sintético con estructura causal conocida.

== Datasets complementarios sugeridos
<sec-apC_complementarios>

#figure(
  caption: [Datasets complementarios sugeridos.],
  table(
    columns: (1.4fr, 1.0fr, 1.4fr, 1.2fr),
    align: (left, left, left, left),
    stroke: none,
    table.hline(stroke: 0.8pt),
    table.header([*Dataset sugerido*], [*Diseño causal*], [*Uso en capítulo*], [*Fuente*]),
    table.hline(stroke: 0.4pt),
    [Progresa/Opportunidades], [RDD], [Capítulo 10 (RDD)], [Evaluación de impacto],
    [Minimum wage panel], [DiD], [Capítulo 9 (panel)], [Literatura salario mínimo],
    [Reemployment bonus], [RCT], [Capítulos 1, 4 (fundamentos)], [Literatura seguros desempleo],
    [Wage gap CPS], [Double lasso], [Capítulos 2, 8 (PDS)], [CPS data],
    [Growth convergence], [PDS/DML], [Capítulo 8 (alta dimensión)], [Literatura crecimiento],
    [IHDP-like], [CATE benchmark], [Capítulo 13 (deep causal)], [Literatura deep causal],
    [Text/product embeddings], [CATE con texto], [Capítulos 12--13], [NLP / embeddings],
    table.hline(stroke: 0.8pt),
  )
) <tab-apC-complementarios>

Nota: algunos de estos datasets pueden no estar disponibles en el repositorio del curso. En ese caso, se sugiere usar un DGP sintético que emule las mismas características.

== Ground truth y checksums
<sec-apC_checksums>

Los datasets sintéticos incluyen un archivo #code[truth_instructor_only.csv] que contiene los valores verdaderos de los parámetros causales ($tau_i$, $theta$, efectos directos e indirectos, etc.). Este archivo permite al instructor evaluar la precisión de las estimaciones obtenidas por los estudiantes sin revelar la solución.

Todos los datasets (reales y sintéticos) incorporan un archivo #code[checksums.sha256.json] con los hashes SHA-256 de cada fichero, calculados en el momento de la publicación. Para verificar la integridad de los datos descargados:

#figure(
  kind: raw,
  caption: [Verificación de integridad de datasets con checksums SHA-256.],
  ```bash
cd ruta/del/dataset
sha256sum -c checksums.sha256.json
```
) <lst-apC-checksums>

Si todos los ficheros coinciden, la salida mostrará #code[OK] para cada uno. Cualquier discrepancia indica que el archivo ha sido modificado o está corrupto, y se recomienda descargarlo nuevamente desde el repositorio oficial.

Los _checksums_ aplican tanto a los datos de estudiante como a los archivos de _ground truth_, garantizando que la evaluación se realice sobre la versión exacta del dataset prevista por el instructor.
