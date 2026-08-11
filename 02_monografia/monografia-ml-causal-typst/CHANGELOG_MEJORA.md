# CHANGELOG_MEJORA — Reescritura a estándar de monografía

Registro de la ejecución del plan "Convertir *IA Causal en Producción* de documento técnico en monografía", con la modificación acordada: **no se agregan demostraciones matemáticas** (ni completas ni `sketch`); los teoremas quedan enunciados y remitidos a la bibliografía como hasta ahora.

Formato de trabajo: edición directa sobre el repositorio (no hay entrega en `.zip`; el estado vive en el árbol de trabajo git, sin commitear hasta indicación explícita).

---

## Etapa 0 — Defectos P0 (2026-08-03)

### Diagnóstico verificado (no se aceptaron los números del encargo sin comprobar)

| Defecto | Cifra del encargo | Cifra real medida | Método de verificación |
|---|---:|---:|---|
| `mid` sin renderizar | 175 | **154** ocurrencias como palabra suelta en modo matemático (21 archivos) + 2 casos adicionales `mid_(...)` con subíndice pegado, hallados tras la primera pasada (word-boundary de regex no cruza `_`) | `grep -c '\bmid\b'` sobre fuentes + inspección del PDF recompilado |
| Citas como sujeto gramatical | 51 | **105** conversiones aplicadas (98 inicio de oración + 7 sujeto compuesto con "y") + **6 casos residuales** hallados por verificación posterior a la primera pasada (separadas por "; " en vez de ". ", o con negrita `*Texto.*` interpuesta entre el punto y la cita) | Extracción de todas las claves de cita reales (`bibliografia/refs.yml`, 80 claves) cruzada contra regex de posición sintáctica; verificación final con `pdftotext` sobre el PDF compilado, no solo sobre el código fuente |
| Paréntesis dobles `(@key)` | no cuantificado | **14** casos | `grep` de `(@key)` literal, filtrado contra claves válidas |
| Colisión encabezado/folio | 143 páginas | **0** tras el fix (mecanismo raíz: `grid` de 2 columnas con alineación hacia el borde compartido, no hacia los márgenes de página) | Heurística de texto (`letra+dígitos pegados a fin de línea`) sobre las 308 páginas + inspección visual renderizada de 2 páginas consecutivas (250 par / 251 impar) |
| Guion suave visible en títulos | 94 | No se contó una cifra separada (el guion suave real de Typst en párrafos de cuerpo es tipografía normal, no bug); se desactivó `hyphenate` específicamente en los 5 puntos de render de título grande (capítulo/frontmatter, parte, portada, `_tbox`) | Inspección de los `text()` de tamaño ≥11pt en negrita en `template.typ` |
| Colofón desactualizado | — | Confirmado: título viejo, Typst 0.13.1, tipografía sans-serif mal declarada (decía DejaVu Sans; el proyecto usa Helvetica Neue), y referencia a un repo (`causal-inference-benchmarks-econ`) que no es el monorepo real del curso | Lectura directa de `frontmatter/colofon.typ` |

### Hallazgos que el encargo original no señaló

1. **Duplicación de nombre de autor**: 3 casos donde el nombre del autor ya estaba escrito en prosa (p. ej. "Bareinboim @bareinboim2025causalai enfatiza…") y la cita por defecto agregaba el nombre otra vez entre paréntesis, renderizando `Bareinboim (Bareinboim 2025) enfatiza…`. Corregido con `#cite(<key>, form: "year")` (más paréntesis manuales cuando el nombre ya estaba fuera de paréntesis) para que quede `Bareinboim (2025) enfatiza…`.
2. **Falsos positivos que había que excluir a mano** del patrón de citas: `@app.post(...)` / `@app.get(...)` (decoradores de FastAPI dentro de un bloque de código en el Cap. 15) y `@dataclass` (decorador de Python en el Cap. 4) — ninguno es una cita bibliográfica; el regex ingenuo los habría convertido incorrectamente. Se filtraron cruzando contra las 80 claves reales de `refs.yml`.
3. La cifra de "67 entradas" en el comentario de cabecera de `bibliografia/refs.yml` está desactualizada (hay 80 claves reales). No se tocó — fuera del alcance de Etapa 0, se deja anotado para una pasada de limpieza posterior.
4. `PLAN_CONSTRUCCION.md` (documento de diseño, no canónico) todavía dice *"este entorno no tiene un compilador de Typst disponible"* — ya no es cierto; no se corrigió porque no es parte del contrato de Etapa 0, pero es una inconsistencia menor a limpiar en una pasada de housekeeping.

### Errores propios cometidos y corregidos durante la etapa

- La primera pasada de conversión de citas a forma prosa usó un regex de "inicio de oración" (`. ` o `! ` o `? ` seguido de `@key`) que **no capturaba** citas separadas por punto y coma (`; @key`) ni citas después de texto en negrita cuando el asterisco de cierre se interponía entre el punto y el espacio (`*Garantías.* @key`). Se detectaron los 6 casos residuales en la verificación posterior (no en la primera pasada) y se corrigieron a mano.
- La verificación automática por regex sobre el PDF final (`\(Autor Año\) palabra`) generó varios falsos positivos (p. ej. `(Card 1995) sobre`, `(Tibshirani 1996) resuelve`) donde la cita es un inciso parentético legítimo y el sujeto real de la oración es otro ("El estimador LASSO (Tibshirani 1996) resuelve…"). Se revisó cada uno manualmente contra el texto fuente antes de descartarlo — no se aceptó la señal del regex sin leer el contexto real.

### Verificación de cierre (protocolo §9 del encargo)

- `typst compile main.typ`: **sin errores** (solo warnings preexistentes de familia tipográfica "Helvetica Neue" no instalada en este entorno, no afectan el render con la fuente de respaldo).
- `grep -c '\bmid\b'` en fuentes: **0**.
- `mid` visible en el PDF compilado (incluye variantes `mid_(...)`): **0**.
- Colisión encabezado/folio (heurística de texto sobre las 308 páginas + verificación visual en 2 páginas): **0**.
- Colofón: título, versión de Typst y tipografía actualizados y verificados en el texto extraído del PDF.
- Etiquetas duplicadas / referencias cruzadas rotas / citas huérfanas: **no verificado en esta etapa** (queda para la Etapa 7, "revisión integral", según el plan de trabajo del encargo — no se afirma que estén en cero).
- Conteo de palabras por capítulo: **no verificado en esta etapa** (Etapa 0 es solo de defectos mecánicos, no de contenido).

### Qué no se pudo verificar

- No se inspeccionaron visualmente las 308 páginas una por una; la verificación de la colisión de encabezado se hizo por heurística de texto sobre el total + inspección visual dirigida de 2 páginas de muestra (una par, una impar). Es posible que quede algún caso no capturado por la heurística (p. ej. si el título es tan largo que el `h(1fr)` no deja separación visible, aunque no se encontró ningún caso así).
- No se corrió el encargo con Typst en un entorno distinto al de este contenedor; se probó únicamente con Typst 0.15.1, la versión ya usada por el proyecto.

---

## Próximas etapas (pendientes, no iniciadas)

Etapas 1–7 del encargo original (expansión de contenido a 4.000+ palabras por capítulo, figuras nuevas, ejercicios con solución, caso conductor único, etc.) **no se iniciaron en esta sesión**. Son un trabajo de escritura de fondo, capítulo por capítulo, de una escala muy distinta a los fixes mecánicos de Etapa 0, y se abordarán en sesiones posteriores según prioridad que defina el usuario.

---

## Etapa 1 — Mejora de contenido (teoría, modelos, metodología) (2026-08-10)

Pasada capítulo a capítulo sobre la base de `auditoria_contenido.md`. Criterio de alcance: **profundizar el foco declarado de cada capítulo, sin añadir temas fuera de ese foco**. No se creó ningún capítulo nuevo ni se movió contenido entre capítulos.

Resultado: 308 → **357 pp.**; bibliografía 80 → **119 entradas**, todas citadas (verificado por script). `typst compile main.typ`: sin errores.

### 1. Bibliografía — correcciones verificadas

| Clave | Acción |
|---|---|
| `kuo2014causalml` | → `chen2020causalml` (Chen, Harinen, Lee, Yung, Zhao 2020, arXiv:2002.11631). La autoría y el año anteriores eran incorrectos. |
| `foster2023orthogonal` | Eliminada (título corrupto, "Blanchard-Qua"). Cap. 12 pasa a citar `foster2019orthogonal`, que es la obra cuyo contenido describía. |
| `kitagawa2021equality` | → `kitagawa2021constrained` (Kitagawa, Sakaguchi & Tetenov, *Constrained Classification and Policy Learning*), que es el trabajo cuyo contenido se citaba. |
| `spiegelhalter2017art` | → `spiegelhalter2019art` (fecha real 2019); tipo corregido a `book`. |
| `angrist1991` en Cap. 11 | El diseño IV con `nearc4` es de **Card (1995)**, no de Angrist & Krueger. Reescrito distinguiendo ambos diseños explícitamente. |
| `zheng2018dags` | Autores corregidos: Zheng, Aragam, Ravikumar, Xing (los listados eran erróneos). |
| `neurise2023deep` | Eliminada (entrada sin obra real detrás); Cap. 27 cita las revisiones reales. |

**Añadidas (39):** `robinson1988`, `kennedy2023towards`, `zhao2006model`, `lee2016exact`, `zhang2014confidence`, `vandegeer2014asymptotically`, `bareinboim2022pch`, `elwert2014endogenous`, `yule1903`, `kleinberg2015prediction`, `rubin1976inference`, `rubin2001using`, `rosenbaum1983central`, `vanderweele2017evalue`, `thornton2008demand`, `goodmanbacon2021`, `dechaisemartin2020twoway`, `sun2021estimating`, `borusyak2024revisiting`, `stock2005testing`, `gebru2021datasheets`, `paleyes2022challenges`, `rzepakowski2012decision`, `hardt2016equality`, `dwork2012fairness`, `kilbertus2017avoiding`, `manski2004statistical`, `berger1985statistical`, `pearl2011transportability`, `correa2020general`, `curth2021inductive`, `farrell2021deep`, `chernozhukov2022riesznet`, `abadie2015comparative`, `doudchenko2016balancing`, `benmichael2021augmented`, `kalisch2007estimating`, `chickering2002optimal`, `machlanski2024robustness`, `zhang2019near`, `lipton2018mythos`.

### 2. Promesas formales cumplidas o retiradas

- **Cálculo-*do* (Caps. 3 y 8).** Los Caps. 3 y 8 anunciaban su "formalización completa" y el Cap. 8 solo desarrollaba puerta trasera. Se **añaden las tres reglas** con la notación de cirugía de grafos ($G_(overline(X))$, $G_(underline(Z))$), su validez y **completitud**, la derivación de la fórmula de puerta trasera como corolario, y una sección nueva sobre el **criterio de puerta delantera** como caso donde la puerta trasera falla.
- **Teorema de la Jerarquía Causal (Cap. 3).** Enunciado como teorema (argumento de medida cero) con su referencia canónica `bareinboim2022pch`, más las dos consecuencias operativas que estructuran el curso.
- **Cap. 6: "consistencia de selección bajo irrepresentabilidad".** El cuadro sinóptico declaraba una garantía que el cuerpo no desarrollaba. Se **añade la condición de irrepresentabilidad y el teorema de Zhao & Yu (2006) con su recíproca**, se separa explícitamente de la *restricted eigenvalue condition* (que solo da la tasa $ell_2$), y se corrige el cuadro. Se añade el mapa de las dos familias de respuestas a la inferencia post-selección (selectiva condicional vs. *de-biasing*).
- **Cap. 10: prueba duplicada.** La "demostración (esquema)" del teorema central de DML repetía literalmente la de ortogonalidad del score. Sustituida por un **esquema real**: descomposición en término i.i.d. + proceso empírico (que neutraliza el cross-fitting) + sesgo de segundo orden (que neutraliza la ortogonalidad), dejando claro que los dos ingredientes cumplen funciones distintas.

### 3. Contenido teórico/metodológico añadido, por capítulo

| Cap. | Adición principal |
|---|---|
| 1 | Descomposición diferencia de medias = ATT + sesgo de selección, y dónde entra exactamente la aleatorización. |
| 2 | `paleyes2022challenges` como evidencia empírica del argumento del capítulo. |
| 4 | Reconciliación Parquet vs. CSV+`metadata.json` (la decisión fija *que el esquema exista*, no el formato); el rol declarado es una afirmación **causal**, no de tipo de dato. |
| 5 | *Prediction policy problems*: criterio para distinguir cuándo la pregunta de política es genuinamente predictiva. Sesgo de selección endógena con `elwert2014endogenous`. |
| 7 | Chequeo de balance reescrito: **SMD + razón de varianzas (criterios de Rubin) + corrección de Holm + faltantes diferenciales**, sustituyendo los $t$-tests sin corregir. |
| 9 | Resuelta la inconsistencia "desconocido": la auditoría produce **dos especificaciones** ($X_"base"$ y $X_"ampliada"$) en vez de excluir de facto las de rol ambiguo. |
| 11 | Lectura correcta de OLS/IV/DML-PLIV como **estimandos distintos** (LATE sobre *compliers*), no como una escalera de corrección de sesgo. |
| 12 | **Sección nueva de DR-learner** con la tasa oracle de Kennedy; tabla comparativa ampliada con la fila "dependencia de los *nuisance*" (1.er vs. 2.º orden); guía de elección práctica. |
| 13 | El bosque causal como **generador de pesos locales**, no como promedio de árboles; *policy trees* con su garantía (VC finita). |
| 14 | **Sección nueva de E-value** (definición, interpretación y sus tres límites); AUUC vs. coeficiente Qini y la distinción ranking/calibración. |
| 15 | Endpoint **`/metadata`** implementado (estaba anunciado en el callout del monorepo y ausente en el listado), con su función pura y el orden de la prueba de humo. |
| 16 | **$lambda_"CV"$ vs. $lambda_"BCH"$**: la penalización teóricamente justificada de BCH y por qué la CV optimiza el criterio equivocado. Declarada la ausencia de cross-fitting en PDS y su implicación. |
| 17 | **DiD moderno**: descomposición de Goodman-Bacon, pesos negativos de de Chaisemartin–D'Haultfœuille, y la advertencia de que la *within-transformation* de este capítulo **hereda el problema**. Instrumentos débiles con Stock–Yogo. |
| 18 | `choose_method` corregido (nunca TWFE con adopción escalonada); límite de fondo: el mapa elige estimador, no identificación. |
| 19 | *Datasheets* (Gebru et al.) como pieza complementaria, conectada con la ficha de procedencia del Cap. 7. |
| 20 | Ecosistema MLOps estándar (MLflow, DVC, Great Expectations, Evidently) y qué es lo que **ninguno** cubre; tres criterios de diseño de la etapa estadística. |
| 21 | **Atribución corregida**: EWM y la cota de regret son de Kitagawa–Tetenov; Athey–Wager añaden los *nuisance* estimados por ML. El "caso" queda etiquetado explícitamente como **DGP sintético**. |
| 22 | Listado de costo-efectividad **hecho ejecutable**: DGP de tres brazos, un estimador de uplift **por acción**, y asignación por *net score* con bisección (antes referenciaba columnas inexistentes y lanzaba `ValueError`). |
| 23 | Distinción **proxy vs. influencia no resuelta** (Kilbertus et al.) y sus dos remedios de naturaleza distinta. |
| 24 | Reestructurado sobre las **tres familias canónicas** (independencia/separación/suficiencia) y el **teorema de incompatibilidad**; *equalized CATE* reubicado como noción propia del curso, no canónica. **SHAP sobre sustituto del CATE** con contraste explícito frente a SHAP del modelo de outcome. Corregido el IC por subgrupo (usaba la dispersión de los $hat(tau)_i$ en lugar de la *influence function*) y un `NameError` en un listado. |
| 25 | Criterios de decisión bajo **identificación parcial**: utilidad esperada / maximin / minimax regret (Manski, Berger), y la acción "experimentar" como parte del conjunto factible. |
| 26 | Distinción **transportabilidad vs. generalización**; la reponderación implementada es el teorema de generalización (Pearl & Bareinboim 2011); intervenciones suaves (Correa & Bareinboim 2020); requisito de soporte entre dominios. |
| 27 | **Balancear no siempre ayuda** (Curth & van der Schaar); la inferencia válida **no** es un problema abierto: Farrell–Liang–Misra y RieszNet. Recomendación invertida: la red como *nuisance* dentro de DML. |
| 28 | Norma nuclear como envolvente convexa del rango (Recht et al.); **elección de $lambda$ por CV con enmascaramiento en bloque**; inferencia por permutación de placebos (Abadie et al. 2015) y su $p$-valor mínimo $1/(J+1)$; envolvente convexa y control sintético aumentado. |
| 29 | Kalisch–Bühlmann (consistencia en alta dimensión) y Chickering (GES) como tercera familia; **sensibilidad a hiperparámetros** (Machlanski et al.) y las dos reglas que de ahí se siguen. |
| 30 | Monitoreo reescrito a **cuatro métricas**: PSI/ASMD en vez de solo KS; **drift del mecanismo de asignación** (AUC del propensity) —el que rompe identificación sin mover ninguna marginal—; F de primera etapa correcto (`f_test` sobre el instrumento, no el F global); **test formal de estabilidad del efecto** que propaga ambos errores estándar. |
| 31 | Bandits causales: combinar observacional + interventivo **acelera** la convergencia (no solo "evitar sesgo"); regímenes dinámicos (Zhang & Bareinboim). |
| 32 | Comunicación de riesgo: frecuencias naturales, absoluto vs. relativo, y la asimetría de costos entre sobre- y subestimar la certeza. |

### 4. Housekeeping

- Comentarios de cabecera con numeración de la edición corta anterior: corregidos en los 14 archivos afectados, con nota de por qué el nombre de archivo no se renombra.
- Referencias cruzadas textuales por número (`capítulo 5`, `capítulos 1, 5 y 13`, `capítulo 17`) sustituidas por etiquetas.
- Glosario (Apéndice D) ampliado: irrepresentabilidad, RE, faithfulness, cálculo-*do*, puerta trasera/delantera, score de Robinson, EWM, net score, E-value, SMD/ASMD, PSI, descomposición de Goodman-Bacon, CPDAG, coeficiente Qini; y precisada la entrada de *equalized CATE*.

### Qué no se hizo

- **No se ejecutaron los listados de código.** Las correcciones de ejecutabilidad (Caps. 22 y 24) son por inspección estática: se eliminaron las referencias a columnas inexistentes y el `NameError`, y se completó el DGP para que las variables usadas existan, pero no se corrió el código en un entorno con `causalml`/`econml` instalados.
- **No se verificaron las cifras de las réplicas propias** (Caps. 11, 16, 12, 13). Se conservan tal como estaban, con su etiqueta de "réplica propia".
- **No se añadieron figuras nuevas.** Los capítulos con contenido nuevo (do-calculus, DR-learner, E-value) se apoyan solo en texto y fórmulas.
- **No se tocó `PLAN_CONSTRUCCION.md`** ni los notebooks del monorepo, aunque el Cap. 15 ahora documenta un endpoint `/metadata` que la implementación de referencia en `04_notebooks_produccion_hf/B1_fastapi_dml/` debería exponer para seguir siendo consistente con el libro.

---

## Etapa 2 — Mejoras editoriales C1–C11 (2026-08-11)

Ejecución de la instrucción editorial "Bloque A — núcleo semiparamétrico (Caps. 10–11), Bloque B — validación (Cap. 14), Bloque C — decisión (Cap. 21), Bloque D — producción (Caps. 15/19/20, Ap. G) + C11 (Cap. 17)". Resultado: 360 → **368 pp.**; bibliografía 119 → **132 entradas** (+13, todas citadas). `typst compile main.typ`: sin errores.

### Cambios aplicados, por cambio

| Cambio | Ubicación | Contenido |
|---|---|---|
| **C1** · Score ortogonal canónico | Cap. 10, tras la prueba del Teorema de ortogonalidad PLR | Nueva Nota técnica + tabla de las 6 instancias del score canónico (PLR, IRM, DR-learner, R-learner, PLIV, policy value) con su $eta$; consecuencias operativas y vínculo con funcionales de Riesz (Cap. 27). Frases puente añadidas en Cap. 11 (tras Ec. IRM) y Cap. 12 (DR-learner). |
| **C2** · Condiciones completas + DML2 | Cap. 10, tras la intuición del Teorema central DML | Nota técnica con las condiciones (C1)–(C4) del Teorema 3.1 de Chernozhukov et al.; distinción DML1/DML2 y *repeated cross-fitting*; pie de la Figura 11.1 y fila de la tabla de riesgos del Cap. 11 actualizados. |
| **C3** · Eficiencia semiparamétrica IRM | Cap. 11, tras el Teorema de doble robustez | Nuevo Teorema de eficiencia (EIF exacta + varianza eficiente); nota puente en Ap. A (ambas IF alcanzan la cota). |
| **C4** · ESS + trimming de Crump | Cap. 11, nueva subsección 11.2.4 | ESS de Kish y trimming óptimo ($alpha^* approx 0.057$, Crump et al. 2009) con regla operativa; fila de la tabla de riesgos y frase del DR-learner (Cap. 12) actualizadas. |
| **C5** · BLP/BEST/CLAN | Cap. 14, nueva subsección 14.2.7 | Tests formales de heterogeneidad (Chernozhukov et al. 2020) con regla operativa; fila añadida a la suite de refutación; checklist F.3 actualizado. |
| **C6** · Intervalos conformes | Cap. 14, nueva subsección 14.2.8 | *Split conformal* sobre transformed outcome con proposición de cobertura y advertencias (Lei–Candès, Tibshirani et al.); comentario `ic_individual` en el Cap. 15, fila Métricas del Ap. G y mitigación de la tabla del Cap. 27 actualizados. |
| **C7** · RATE | Cap. 14, tras los baselines obligatorios | Criterio RATE (Yadlowsky et al. 2021) con regla operativa; 4.º baseline añadido; Ap. B.2 (RScorer) actualizado. |
| **C8** · Sensibilidad en tres niveles | Cap. 14, sección E-value reestructurada | E-value (Nivel 1) + $R^2$ de Imbens/Cinelli–Hazlett (Nivel 2) + bounds de Manski (Nivel 3) con protocolo del curso; Ap. E.7 actualizado. |
| **C9** · EIF del policy value | Cap. 21, tras el estimador DR de $V(pi)$ | Nueva Proposición con EIF, normalidad y test de comparación de políticas; bloque de código de IC en el Listado 21.1; checklist F.6 actualizado. |
| **C10** · Model card machine-readable | Ap. G, nueva sección G.4 | JSON Schema `causal-model-card-v1` con campo `dml_variant`; comentario en `/metadata` (Cap. 15), checklist del Cap. 19 y job `tests-estadisticos` del Cap. 20 (paso `validar_schema.py`) actualizados. |
| **C11** · Inferencia robusta a instrumentos débiles | Cap. 17, tras el umbral $F > 10$ | Test de Anderson–Rubin con regla operativa; fila de la tabla de riesgos del Cap. 17 y docstring de `fuerza_instrumento` del Cap. 30 (doble umbral) actualizados. |

### Referencias nuevas (13)

`andrews2019robust`, `chernozhukov2020generic`, `cinellihazlett2020`, `crump2009dealing`, `imbens2003sensitivity`, `kish1965`, `leicandes2021`, `lei2018distribution`, `manski1990nonparametric`, `romano2019conformalized`, `stock2002survey`, `tibshirani2019conformal`, `yadlowsky2021rate`.

### Decisiones editoriales y de implementación

- La numeración de secciones del borrador editorial no coincide con la del libro (que es automática); las referencias cruzadas se escribieron con etiquetas (`@sec-...`, `@cap-...`) en lugar de números, siguiendo la convención del libro.
- El template no soporta referencias a teoremas/definiciones vía `@thm-...` (la figura suprime el caption y Typst no puede resolver el número); las referencias a teoremas se expresaron en prosa o vía su sección (`@sec-...`).
- C7 (RATE) se ubicó tras "_Baselines_ obligatorios" y antes de "Versionado del proceso" para no romper la transición final de la sección de evaluación offline hacia el Cap. 15.
- El operador `not.in` no existe en Typst 0.15.1; se usó el carácter Unicode `∉` (el libro ya usa Unicode).
- La sección de tests de heterogeneidad (C5) y conformal (C6) se insertaron tras "Validación con datos sintéticos", lo que las numera como subsecciones de la sección de teoría del Cap. 14.

### Qué no se hizo

- No se ejecutaron los nuevos listados de código (C9 añade un bloque de IC al Listado 21.1; validación por inspección estática).
- No se redactó la segunda ronda de mejoras anunciada (Qini como U-estadístico, s-admisibilidad en Cap. 26, linter de fuga en Cap. 9, batería CI con control de error, MMD en Cap. 30, conformal para deep models del Cap. 27).
- No se resolvieron las duplicaciones/regresiones heredadas de la sesión anterior (detectadas en la auditoría de coherencia previa a esta etapa; ver informe de diagnóstico al usuario).
