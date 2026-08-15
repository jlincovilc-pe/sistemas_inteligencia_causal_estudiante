# Diapositivas — *IA Causal en Producción* (ECO-490 / ECON-540)

Mazos de diapositivas Typst/Touying para los 32 capítulos de la monografía del curso.
Los 32 mazos están **completos**: metadata, agenda, contenido profundo (definiciones,
teoremas, listados, casos) y cierre, con el contenido real de la monografía. Cada mazo
compila a PDF con `./build.sh`.

## Estado

- ✅ `plantilla_monografia.typ` — plantilla Touying adaptada, compila limpio.
- ✅ `PLAN_SPRINT_DIAPOSITIVAS.md` — plan de contenido capítulo a capítulo (32
  entradas) con punteros exactos a labels del `.typ` fuente en `02_monografia/`.
- ✅ `capitulos/cap01_*.typ` … `cap32_*.typ` — 32 mazos **completos** (sin
  `// TODO(sprint)`), todos compilan (`./build.sh` → 32 OK). Contenido profundo
  trasladado de la monografía (definiciones, teoremas, listados, casos).
- ⏳ Diagramas (cetz/fletcher) — ninguno se generó todavía; `cap-diagrama()` existe en
  la plantilla pero ningún mazo la usa aún.
- ⏳ Revisión de que cada mazo cabe en el tiempo real de su sesión (90 min compartidos
  con el lab).

## Cómo compilar

```bash
cd 07_diapositivas
./build.sh                  # los 32 capítulos -> build/*.pdf (ignorado por git)
./build.sh cap11            # solo los que matcheen "cap11" (por prefijo de archivo)
./build.sh --watch cap11_dml   # recompila al guardar, útil mientras se edita
```

Requiere Typst ≥ 0.15 con `touying 0.5.5`, `cetz 0.3.4` y `fletcher 0.5.3` (cacheados
en `~/.cache/typst/packages` o con red disponible la primera vez). Compilar siempre
con `--root .` desde `07_diapositivas/` — si se invoca `typst compile` a mano desde
otra carpeta, los `#import "../plantilla_monografia.typ"` fallan con *"path would
escape the project root"*.

## Estructura

```
07_diapositivas/
├── plantilla_monografia.typ   # plantilla Touying — TODO el motor vive aquí
├── plantilla_capitulo_v2.typ  # plantilla de ejemplo original (otro curso; no tocar)
├── PLAN_SPRINT_DIAPOSITIVAS.md# plan de contenido, capítulo a capítulo
├── build.sh
├── README.md                  # este archivo
└── capitulos/
    ├── cap01_causalidad_elemental.typ
    ├── cap02_anatomia_sistema.typ
    ├── ...
    └── cap32_lado_humano.typ
```

**Convención de numeración:** los archivos usan el número de capítulo del **PDF de la
monografía** (1–32), no el nombre de archivo histórico de
`02_monografia/monografia-ml-causal-typst/capitulos/` (`cap00_…`, `cap02b_…`, etc.).
La tabla de `PLAN_SPRINT_DIAPOSITIVAS.md` §1 mapea ambos, más la sesión real (`S1`–
`S28`) y el lab. El **orden de enseñanza no siempre coincide con el número de
capítulo** entre S9 y S14 (ver la nota al pie de esa tabla) — arme el temario por
columna *Sesión*, no por nombre de archivo.

## Mantenimiento de los mazos

1. Abrir el mazo del capítulo en `capitulos/capNN_*.typ`.
2. El contenido profundo ya está trasladado de la monografía; para ajustar una slide,
   editar el `.typ` y recompilar (`./build.sh --watch capNN`).
3. Si una slide desborda, recortar prosa (el cuerpo útil es de ≈10×5.5 cm a 12.5pt), no
   agrandar el layout.
4. Si la monografía cambia (nueva edición), revisar los labels citados en el mazo
   (`@thm-...`, `@lst-...`, `@tab-...`) contra el capítulo fuente.

## Catálogo de funciones (`plantilla_monografia.typ`)

Compartidas por ambas variantes:

| Función | Uso |
|---|---|
| `cap-init(...)` | Registra metadata del capítulo en `cap-state` (usada por el footer). |
| `cap-progreso-curso(cap-actual:)` | Grid de 9 partes × 32 capítulos con ★/◇. Se omite en capítulos ◇ (sin sesión propia). |
| `cap-portada(...)` | Portada con número, título, parte, sesión, variante. |
| `cap-roadmap(objetivos:, agenda:, lectura:, lab:, entrega:)` | Objetivos + agenda de la sesión. |
| `cap-glosario(terminos:)` | Tabla término/definición de 2 columnas. |
| `caja-teorema/proposicion/lema/corolario/definicion/supuesto/ejemplo/observacion` | Ocho cajas con los mismos colores que `template.typ` del libro (teorema=navy, proposición/lema/corolario=accent, definición=green, supuesto/ejemplo=orange, observación=gray). |
| `cap-interactivo(tipo:, pregunta:, duracion:)` | Slide de pausa activa. |
| `cap-codigo-parte(titulo:, snippet:, salida:, nota:, invariante:, invariante-titulo:)` | Bloque de código con salida y chequeo de sanidad opcionales. |
| `cap-diagrama(titulo:, cuerpo-diagrama:)` | Envoltorio para figuras cetz/fletcher — sin usar todavía en ningún mazo. |
| `cap-caso-resolucion(titulo:, contexto:, resultado:, interpretacion:)` | Caso aplicado / aplicación al sistema del curso. |
| `cap-validacion(tipo:, descripcion:, conclusion:)` | Slide de validación/robustez (variante A). |
| `cap-mapeo-pch-activo(nivel:, metrica:, pregunta-activa:)` | Ver "Mapeo PCH" abajo. |
| `cap-errores-transiciones(errores:, conexiones:)` | Tabla de riesgos (variante A). |
| `cap-checklist-alertas(items:)` | Checklist ☐ (variante B, espeja `#checklist[]` del libro). |
| `cap-monorepo(texto-monorepo:)` | Solo capítulos con `#monorepo[]` en el libro (4, 9, 15, 19, 20, 30). |
| `cap-discusion-ejercicio(pregunta:, ejercicio:)` | Cierre de contenido, antes del resumen. |
| `cap-cierre-narrativo(resumen:, refs:, transicion:, gancho:)` | Última slide: resumen + referencias + gancho al siguiente capítulo. |

Solo variante A (teoría — `cap-definicion`, `cap-supuestos`, `cap-teorema`,
`cap-demostracion`) y solo variante B (ingeniería — `cap-problema-diseno`,
`cap-opciones-tradeoffs`, `cap-decision-referencia`) espejan las dos plantillas que ya
usa la propia monografía (`#cuadrosinoptico[]` vs. `#cuadrodecision[]`). Ver el
esqueleto completo de cada variante en `PLAN_SPRINT_DIAPOSITIVAS.md` §2.

### Mapeo PCH (reemplaza al "mapeo GCE" del ejemplo original)

`plantilla_capitulo_v2.typ` traía un `cap-mapeo-gce-activo` atado al marco de otro
curso (DES504, "GCE", una cadena `|τATE| ≤ W1 ≤ W^(G,1)` sin equivalente aquí). No
existe un marco así en *IA Causal en Producción*; el eje que el sílabo repite en cada
módulo es la Jerarquía Causal de Pearl y la pregunta de si el efecto cambia la
decisión frente a solo predecir (`01_silabo/silabo.typ` §2). `cap-mapeo-pch-activo`
reemplaza esa slide con: nivel de la PCH (L1/L2/L3), estimando/métrica del capítulo, y
esa pregunta activa. Está fijada como texto de apoyo en la propia función — no hace
falta repetirla en cada mazo.

## ⚠️ Trampa de sintaxis Typst a tener presente

Los parámetros de tipo **string** (`problema:`, `gancho:`, `cuerpo:`, `enunciado:`,
`contexto:`, `resultado:`, `pregunta:`, `decision:`, `justificacion:`, `titulo:`, …)
aceptan `_`, `<`, `>`, `*`, `|` sin problema porque Typst inserta el string tal cual,
sin volver a parsearlo como *markup*.

Los parámetros de tipo **arreglo de bloques de contenido** —
`cap-glosario(terminos:)`, `cap-supuestos(supuestos:)`,
`cap-demostracion(pasos:)`, `cap-errores-transiciones(errores:)`,
`cap-checklist-alertas(items:)`, `cap-opciones-tradeoffs(opciones:)`,
`cap-cierre-narrativo(resumen:, refs:)`, y la `agenda:` de `cap-roadmap` — llevan
literales `[...]`, y **ahí Typst SÍ vuelve a parsear el texto como markup**:

- `_algo` → intenta abrir cursiva; sin un `_` de cierre en el mismo bloque, error
  `unclosed delimiter`.
- `*algo` → lo mismo con negrita.
- `<algo` → intenta abrir una referencia `<label>`; error `unclosed label`.
- `\|` → combinación de escape inválida, produce errores en cascada.

**Regla práctica:** dentro de un bloque `[...]` de esos parámetros, cualquier
notación con subíndices, desigualdades o asteriscos va en modo matemático
(`$tau_i$`, `$0 < P(D=1|X) < 1$`, `$d^*$`), nunca como texto plano. Si hace falta
texto plano con esos caracteres, se escapan (`\_`, `\<`, `\>`) o se reformula en
palabras. Los 32 mazos ya siguen esta regla — úsenla de referencia si algo no
compila.

## Decisiones de diseño (por qué se ve así)

- **Paleta idéntica a la del libro** (`navy`/`crimson`/`accent`/`green`/`orange` de
  `02_monografia/.../template/template.typ`) — para que diapositivas y monografía se
  lean como un mismo sistema visual, no como dos artefactos separados.
- **Progreso de curso en 9 partes**, no 4 bloques — espeja la estructura real de
  `main.typ` de la monografía, con marca ★/◇ igual que la tabla maestra de
  `PLAN_INTEGRACION_MONOGRAFIA.md`.
- **Variante A/B explícita por capítulo** — la monografía ya distingue capítulos de
  teoría (`#cuadrosinoptico[]`) de capítulos de ingeniería (`#cuadrodecision[]`); las
  diapositivas heredan esa distinción en vez de forzar un único esqueleto a los 32.
- **`cap-monorepo()`** — nuevo respecto al ejemplo original; los capítulos con
  callout `#monorepo[]` en el libro (rutas reales de `03_notebooks_caso_estudio/`,
  `04_notebooks_produccion_hf/`, `05_labs_sesion/`) lo muestran en una slide propia,
  porque son los capítulos donde arranca o se entrega una pieza de la Serie A/B.
- **Capítulos ◇ con mazo corto** — 5, 16, 17, 18, 27 y 28 no tienen sesión `S#`
  propia (tabla maestra del sílabo); sus mazos usan el esqueleto reducido de
  `PLAN_SPRINT_DIAPOSITIVAS.md` §2 en vez de forzar 18 slides a un capítulo que se
  lee como refuerzo.

## Qué NO se hizo en esta pasada (a propósito)

- No se generó ningún diagrama cetz/fletcher.
- No se verificó tiempo real de exposición leyendo cada mazo en voz alta.
- No se tocó `plantilla_capitulo_v2.typ` (el ejemplo original) — queda como
  referencia de otro curso, no se reutiliza directamente en ningún mazo.
