// =============================================================================
// plantilla_monografia.typ — Plantilla Touying reutilizable para las
// diapositivas de "IA Causal en Producción" (Curso ECO-490 / ECON-540).
//
// Adaptada de plantilla_capitulo_v2.typ (mismo motor: Touying 0.5.5 + Typst
// 0.15 + cetz 0.3.4 + fletcher 0.5.3). Cambios respecto al original:
//
//   - Paleta idéntica a la de la monografía (template.typ: navy / crimson /
//     accent / green / orange) para que libro y diapositivas se lean como
//     un mismo sistema visual.
//   - "Mapeo GCE" (marco de otro curso, sin equivalente en el nuestro)
//     sustituido por "Mapeo PCH": nivel de la Jerarquía Causal de Pearl
//     (L1 asociación ⊆ L2 intervención ⊆ L3 contrafactual) + estimando/
//     métrica del capítulo + la pregunta que el sílabo repite en cada
//     módulo (§2): "si solo predijéramos, ¿cambia la decisión con el
//     efecto estimado?".
//   - cap-progreso-curso reorganizado en 9 partes (Parte 0 + I–VIII, 32
//     capítulos) con marca ★ camino crítico / ◇ profundización electiva,
//     igual que la tabla maestra de PLAN_INTEGRACION_MONOGRAFIA.md.
//   - Dos familias de contenido, espejando las dos plantillas de la
//     monografía misma:
//       · Variante A (capítulos de teoría: SCM, DML, meta-learners...):
//         motivación → definición → supuestos → teorema → demostración.
//       · Variante B (capítulos de ingeniería: despliegue, CI/CD,
//         monitoreo...): problema de diseño → opciones/trade-offs →
//         decisión de referencia → checklist de alertas.
//     Ambas comparten portada/roadmap/glosario/código/caso/validación/
//     mapeo-PCH/discusión/cierre.
//   - cap-monorepo: nueva slide para los capítulos con callout #monorepo[]
//     en el libro (Caps. 4, 9, 15, 19, 20, 30) — ruta real del monorepo,
//     lab y entrega, para que la sesión conecte directo con la práctica.
//
// Ver 07_diapositivas/README.md para el catálogo completo de funciones y
// 07_diapositivas/PLAN_SPRINT_DIAPOSITIVAS.md para el plan de contenido
// capítulo a capítulo que este archivo implementa.
// =============================================================================

#import "@preview/touying:0.5.5": *
#import "@preview/cetz:0.3.4": canvas, draw
#import "@preview/fletcher:0.5.3" as fletcher

// Re-exportar funciones del tema metropolis
#let metropolis-theme = themes.metropolis.metropolis-theme
#let slide = themes.metropolis.slide
#let title-slide = themes.metropolis.title-slide
#let new-section-slide = themes.metropolis.new-section-slide
#let focus-slide = themes.metropolis.focus-slide

// ─── Paleta — idéntica a 02_monografia/.../template/template.typ ────────────
#let navy    = rgb("#0F1E3D")
#let crimson = rgb("#C8102E")
#let gray    = rgb("#4A4A4A")
#let light   = rgb("#F5F7FA")
#let accent  = rgb("#1E5A8E")
#let green   = rgb("#1F7A3A")
#let orange  = rgb("#D97706")
// Colores solo-diapositivas, sin equivalente en el libro
#let borde     = rgb("#C9BBA8")
#let texto     = rgb("#1F1B16")
#let muted     = rgb("#6F655A")
#let error     = rgb("#9A2A2A")
#let interact    = rgb("#7B3F8D")
#let interact-bg = rgb("#F3E8F9")

// Tipografía de proporciones (referencia)
#let sz-body   = 12.5pt
#let sz-title  = 18pt
#let sz-h      = 12pt
#let sz-small  = 10pt
#let sz-tiny   = 9pt
#let sz-code   = 7.8pt
#let sz-table  = 10pt

// ─── Estado global del capítulo ───────────────────────────────────────────────
#let cap-state = (
  num: 1, titulo: "", parte: "", sesion: "", variant: "A", critico: true,
)

#let cap-init(
  num: 1, titulo: "", parte: "", sesion: "", variant: "A", critico: true,
) = {
  state("cap-state").update((
    num: num, titulo: titulo, parte: parte, sesion: sesion,
    variant: variant, critico: critico,
  ))
}

// ─── Tema base: Metropolis con paleta de la monografía ───────────────────────
// align: top — crítico: horizon centra y deja slides "vacíos" o desborda.
#let cap-theme(body) = {
  show: metropolis-theme.with(
    aspect-ratio: "16-9",
    align: top,
    footer-progress: true,
    config-colors(
      primary: navy,
      primary-light: light,
      secondary: accent,
      neutral-light: light,
      neutral-lightest: rgb("#FAFAF8"),
      neutral-darkest: texto,
      foreground: texto,
    ),
    config-common(
      slide-level: 1,
    ),
    config-page(
      // top: hueco del header Metropolis; bottom: footer + progress bar
      margin: (left: 1.35cm, right: 1.35cm, top: 2.0cm, bottom: 1.35cm),
      footer: context {
        let cs = state("cap-state").at(here())
        text(size: 7.5pt, fill: muted)[
          #text(fill: navy, weight: "bold")[IA Causal en Producción]
          · Cap. #cs.num #if cs.critico [★] else [◇] · ECO-490/ECON-540 · Ed. 2026
        ]
      },
    ),
    config-methods(node-radius: 4pt, node-fill: light),
  )

  // Overrides de proporción (van dentro del body del tema → ganan a 20pt)
  set text(
    font: ("New Computer Modern", "Libertinus Serif", "Georgia"),
    size: sz-body,
    lang: "es",
    fill: texto,
  )
  set par(leading: 0.42em, spacing: 0.5em)
  set list(tight: true, marker: text(fill: navy)[•])
  set enum(tight: true, numbering: "1.")
  set table(
    inset: (x: 0.4em, y: 0.28em),
    stroke: 0.4pt + borde,
    align: left + top,
  )
  show table: set text(size: sz-table)
  show raw.where(block: true): it => {
    set text(size: sz-code, font: ("DejaVu Sans Mono", "Menlo", "Courier New"))
    set par(leading: 0.38em)
    it
  }
  show raw.where(block: false): set text(
    size: 0.88em,
    font: ("DejaVu Sans Mono", "Menlo", "Courier New"),
  )
  body
}

// =============================================================================
// S00 · Progreso del curso — 9 partes, 32 capítulos, ★ camino crítico / ◇ electivo
// =============================================================================
#let cap-progreso-curso(cap-actual: 1) = {
  let partes = (
    ("0",    (1, 2),                     "Introducción"),
    ("I",    (3, 4, 5, 6, 7, 8, 9),       "Fundamentos estructurales y de datos"),
    ("II",   (10, 11, 12, 13, 14, 15),    "Estimación flexible y primer despliegue"),
    ("III",  (16, 17, 18),                "Diseños de identificación con ML"),
    ("IV",   (19, 20),                    "Publicación y operación en producción"),
    ("V",    (21, 22),                    "Heterogeneidad, políticas y targeting"),
    ("VI",   (23, 24, 25, 26),            "Explicación, equidad y decisión"),
    ("VII",  (27, 28),                    "Métodos avanzados"),
    ("VIII", (29, 30, 31, 32),            "Estructura, monitoreo y frontera"),
  )
  let electivos = (5, 16, 17, 18, 27, 28)
  slide(title: [Progreso del curso · 32 capítulos, 9 partes], align: horizon)[
    #grid(
      columns: 3,
      column-gutter: 0.4em,
      row-gutter: 0.4em,
      ..partes.map(((pname, caps, pdesc)) => {
        block(fill: light, inset: 0.5em, radius: 3pt, width: 100%)[
          #text(fill: navy, weight: "bold", size: 10.5pt)[Parte #pname]
          #v(0.1em)
          #text(size: 7.5pt, fill: muted)[#pdesc]
          #v(0.3em)
          #grid(
            columns: 6, row-gutter: 0.2em, column-gutter: 0.2em,
            ..caps.map(c => {
              let col = if c == cap-actual { navy }
                        else if c < cap-actual { borde }
                        else { white }
              let txtcol = if c == cap-actual or c < cap-actual { white } else { texto }
              let st = if c > cap-actual { 0.4pt + borde } else { none }
              block(fill: col, inset: (x: 0.3em, y: 0.16em), radius: 2pt, stroke: st)[
                #text(fill: txtcol, size: 7.5pt,
                      weight: if c == cap-actual { "bold" } else { "regular" })[
                  #c#if c in electivos [◇]
                ]
              ]
            }),
          )
        ]
      }),
    )
    #v(0.6em)
    #align(center)[
      #text(fill: muted, size: 9pt)[
        #box(fill: borde, width: 0.7em, height: 0.7em) #h(0.2em) previos ·
        #box(fill: navy, width: 0.7em, height: 0.7em) #h(0.2em) actual ·
        #box(stroke: 0.4pt + borde, width: 0.7em, height: 0.7em) #h(0.2em) próximos ·
        #h(0.4em) ◇ profundización electiva (no bloquea el camino ★)
      ]
    ]
  ]
}

// =============================================================================
// S01 · Portada (slide normal — evita página fantasma del title-slide)
// =============================================================================
#let cap-portada(
  num: 1, titulo: "", parte: "", sesion: "", variant: "A", critico: true,
) = {
  slide(title: none, align: horizon)[
    #align(center)[
      #box(fill: navy, inset: (x: 0.7em, y: 0.3em), radius: 2pt)[
        #text(fill: white, weight: "bold", size: 12pt)[
          CAPÍTULO #num #if critico [· CAMINO ★] else [· PROFUNDIZACIÓN ◇]
        ]
      ]
      #v(0.55em)
      #text(fill: navy, weight: "bold", size: 25pt)[#titulo]
      #v(0.45em)
      #line(length: 55%, stroke: 1.2pt + navy)
      #v(0.4em)
      #text(fill: muted, size: 12pt)[Parte #parte · Sesión #sesion]
      #v(0.25em)
      #text(fill: accent, size: 11pt)[
        Plantilla #variant #if variant == "A" [(teoría e identificación)] else [(ingeniería y producción)]
      ]
      #v(0.9em)
      #text(fill: texto, size: 12pt)[IA Causal en Producción]
      #v(0.2em)
      #text(fill: muted, size: 10.5pt)[Curso ECO-490 / ECON-540 · Edición 2026]
    ]
  ]
}

// =============================================================================
// S02 · Roadmap + prerequisitos
// =============================================================================
#let cap-roadmap(objetivos: (), agenda: (), lectura: "", lab: "", entrega: "") = {
  slide(title: [Roadmap del capítulo])[
    #grid(
      columns: (1.05fr, 0.95fr), column-gutter: 0.85em,
      [
        #text(fill: navy, weight: "bold", size: sz-h)[Objetivos de aprendizaje]
        #v(0.25em)
        #enum(
          numbering: "1.",
          tight: true,
          ..objetivos.map(o => text(size: 11pt)[#o]),
        )
        #v(0.35em)
        #block(
          fill: interact-bg,
          stroke: (left: 3pt + interact),
          inset: 0.45em, radius: 2pt, width: 100%,
        )[
          #text(fill: interact, weight: "bold", size: sz-small)[★ Antes de clase]
          #v(0.15em)
          #set text(size: 8.5pt, fill: texto)
          #set par(leading: 0.38em)
          *Lectura:* #lectura \
          *Lab:* #lab
          #if entrega != "" [
            \
            *Entrega/hito:* #entrega
          ]
        ]
      ],
      [
        #text(fill: navy, weight: "bold", size: sz-h)[Agenda]
        #v(0.25em)
        #for (i, a) in agenda.enumerate() [
          #block(
            fill: light,
            inset: (x: 0.45em, y: 0.22em),
            radius: 2pt, width: 100%,
          )[
            #text(fill: navy, weight: "bold", size: 9pt)[
              #if i + 1 < 10 [0]#str(i + 1)
            ]
            #text(fill: texto, size: 10pt)[ · #a]
          ]
          #v(0.1em)
        ]
      ],
    )
  ]
}

// =============================================================================
// S03A · Motivación + caso (Variante A — teoría)
// =============================================================================
#let cap-motivacion(problema: "", gancho: "", caso: none) = {
  slide(title: [Problema causal, estimando e identificación])[
    #block(fill: light, inset: (x: 0.7em, y: 0.5em), radius: 3pt, width: 100%)[
      #text(fill: navy, weight: "bold", size: sz-h)[Problema]
      #v(0.2em)
      #text(fill: texto, size: 11.5pt)[#problema]
    ]
    #v(0.4em)
    #text(fill: accent, weight: "bold", size: sz-h)[Gancho aplicado]
    #v(0.15em)
    #text(fill: texto, size: 11.5pt)[#gancho]
    #if caso != none [
      #v(0.4em)
      #block(fill: rgb("#FFF3E0"), stroke: (left: 3pt + orange),
             inset: 0.45em, radius: 2pt, width: 100%)[
        #text(fill: orange, weight: "bold", size: 11pt)[Caso del curso]
        #text(fill: texto, size: 11pt)[ · #caso]
      ]
    ]
  ]
}

// =============================================================================
// S03B · Problema de diseño (Variante B — ingeniería)
// =============================================================================
#let cap-problema-diseno(
  decision: "", alternativas: "", tradeoff: "", stack: "", riesgo: "",
) = {
  slide(title: [El problema de diseño])[
    #table(
      columns: (auto, 1fr),
      align: (left, left),
      stroke: none,
      fill: (x, y) => if calc.odd(y) { light } else { white },
      [*Decisión*], [#decision],
      [*Alternativas*], [#alternativas],
      [*Trade-off clave*], [#tradeoff],
      [*Stack*], [#stack],
      [*Riesgo principal*], [#riesgo],
    )
  ]
}

// =============================================================================
// S03B' · Opciones y trade-offs (Variante B)
// =============================================================================
#let cap-opciones-tradeoffs(opciones: ()) = {
  slide(title: [Opciones y trade-offs])[
    #for (nombre, desc) in opciones [
      #block(fill: light, stroke: (left: 3pt + accent),
             inset: (x: 0.5em, y: 0.3em), radius: 2pt, width: 100%)[
        #text(fill: accent, weight: "bold", size: 11pt)[#nombre]
        #v(0.1em)
        #text(fill: texto, size: 10pt)[#desc]
      ]
      #v(0.2em)
    ]
  ]
}

// =============================================================================
// S03B'' · Decisión de referencia del curso (Variante B)
// =============================================================================
#let cap-decision-referencia(decision: "", justificacion: "") = {
  slide(title: [Decisión de referencia para el curso], align: horizon)[
    #block(fill: green.lighten(85%), stroke: (left: 4pt + green),
           inset: (x: 0.8em, y: 0.55em), radius: 3pt, width: 100%)[
      #text(fill: green, weight: "bold", size: 13pt)[Decisión adoptada]
      #v(0.25em)
      #text(fill: texto, size: 12pt)[#decision]
      #v(0.35em)
      #text(fill: muted, size: 10.5pt, style: "italic")[#justificacion]
    ]
  ]
}

// =============================================================================
// S04 · Glosario
// =============================================================================
#let cap-glosario(terminos: ()) = {
  slide(title: [Definiciones clave])[
    #grid(
      columns: (auto, 1fr), column-gutter: 0.55em, row-gutter: 0.28em,
      ..terminos.map(((t, d)) => (
        text(fill: navy, weight: "bold", size: 11pt)[#t],
        text(fill: texto, size: 11pt)[#d],
      )).flatten(),
    )
  ]
}

// =============================================================================
// Cajas teorema / definición / proposición / lema / corolario / supuesto /
// ejemplo / observación — mismos ocho tipos y mismos colores que
// template.typ del libro (theorem=navy, proposition/lemma/corollary=accent,
// definition=green, assumption/example=orange, remark=gray).
// =============================================================================
#let caja-generica(titulo: "", color: navy, cuerpo: "", ref-apendice: none, fill-color: none) = {
  block(
    fill: if fill-color != none { fill-color } else { light },
    stroke: (left: 3pt + color, rest: 0.4pt + borde),
    inset: (x: 0.7em, y: 0.45em), radius: 2pt, width: 100%,
  )[
    #text(fill: color, weight: "bold", size: 12pt)[#titulo]
    #v(0.25em)
    #text(fill: texto, size: 11pt)[#cuerpo]
    #if ref-apendice != none [
      #v(0.25em)
      #text(fill: muted, size: 9pt)[Ver: #ref-apendice en la monografía.]
    ]
  ]
}
#let caja-teorema(titulo: "Teorema", cuerpo: "", ref-apendice: none) = caja-generica(titulo: titulo, color: navy, cuerpo: cuerpo, ref-apendice: ref-apendice)
#let caja-proposicion(titulo: "Proposición", cuerpo: "", ref-apendice: none) = caja-generica(titulo: titulo, color: accent, cuerpo: cuerpo, ref-apendice: ref-apendice)
#let caja-lema(titulo: "Lema", cuerpo: "", ref-apendice: none) = caja-generica(titulo: titulo, color: accent, cuerpo: cuerpo, ref-apendice: ref-apendice)
#let caja-corolario(titulo: "Corolario", cuerpo: "", ref-apendice: none) = caja-generica(titulo: titulo, color: accent, cuerpo: cuerpo, ref-apendice: ref-apendice)
#let caja-definicion(titulo: "Definición", cuerpo: "") = caja-generica(titulo: titulo, color: green, cuerpo: cuerpo, fill-color: green.lighten(90%))
#let caja-supuesto(titulo: "Supuesto", cuerpo: "") = caja-generica(titulo: titulo, color: orange, cuerpo: cuerpo, fill-color: orange.lighten(88%))
#let caja-ejemplo(titulo: "Ejemplo", cuerpo: "") = caja-generica(titulo: titulo, color: orange, cuerpo: cuerpo, fill-color: orange.lighten(88%))
#let caja-observacion(titulo: "Observación", cuerpo: "") = caja-generica(titulo: titulo, color: gray, cuerpo: cuerpo, fill-color: light)
#let caja-axioma(titulo: "Axioma", cuerpo: "") = caja-teorema(titulo: titulo, cuerpo: cuerpo)

// =============================================================================
// S05 · Definición formal (Variante A)
// =============================================================================
#let cap-definicion(titulo-def: "", cuerpo: "", eq: none) = {
  slide(title: [Marco teórico I: definición formal])[
    #text(fill: navy, weight: "bold", size: sz-h)[#titulo-def]
    #v(0.3em)
    #text(fill: texto, size: 11.5pt)[#cuerpo]
    #if eq != none [
      #v(0.4em)
      #align(center)[
        #block(fill: light, inset: (x: 0.8em, y: 0.45em), radius: 2pt)[#eq]
      ]
    ]
  ]
}

// =============================================================================
// S06 · Supuestos (Variante A)
// =============================================================================
#let cap-supuestos(supuestos: ()) = {
  slide(title: [Marco teórico II: supuestos de identificación])[
    #set text(size: sz-table)
    #table(
      columns: (0.95fr, 1.15fr, 1.15fr),
      align: (left + top, left + top, left + top),
      stroke: 0.4pt + borde,
      fill: (_, y) => if y == 0 { navy } else if calc.odd(y) { light } else { white },
      table.header(
        text(fill: white, weight: "bold", size: 10pt)[Supuesto],
        text(fill: white, weight: "bold", size: 10pt)[Implicación],
        text(fill: white, weight: "bold", size: 10pt)[Chequeo en el caso],
      ),
      ..supuestos.map(((s, i, c)) => (
        text(fill: navy, weight: "bold", size: 9.5pt)[#s],
        text(fill: texto, size: 9.5pt)[#i],
        text(fill: accent, size: 9.5pt)[#c],
      )).flatten(),
    )
  ]
}

// =============================================================================
// S07 · Teorema central (Variante A)
// =============================================================================
#let cap-teorema(titulo: "Teorema", enunciado: "", ref-apendice: none) = {
  // horizon: teoremas cortos no quedan pegados al header
  slide(title: [Teorema central], align: horizon)[
    #caja-teorema(titulo: titulo, cuerpo: enunciado, ref-apendice: ref-apendice)
  ]
}

// =============================================================================
// S08 · Demostración / esquema guiado (Variante A)
// =============================================================================
#let cap-demostracion(pasos: ()) = {
  slide(title: [Demostración: idea principal])[
    #for (i, p) in pasos.enumerate() [
      #block(width: 100%, inset: (y: 0.08em))[
        #text(fill: navy, weight: "bold", size: 11.5pt)[Paso #(i + 1).]
        #text(fill: texto, size: 11pt)[ #p]
      ]
      #if i + 1 < pasos.len() [
        #align(center)[#text(fill: crimson, size: 11pt)[↓]]
      ]
    ]
  ]
}

// =============================================================================
// ★ INTER · Punto interactivo
// =============================================================================
#let cap-interactivo(tipo: "Conceptual", pregunta: "", duracion: "2-4 min") = {
  slide(title: [★ Punto interactivo], align: horizon)[
    #block(
      fill: interact-bg,
      stroke: (left: 4pt + interact, rest: 0.5pt + interact),
      inset: (x: 0.9em, y: 0.7em), radius: 3pt, width: 100%,
    )[
      #grid(
        columns: (auto, 1fr), column-gutter: 0.7em,
        text(fill: interact, weight: "bold", size: 22pt)[★],
        [
          #text(fill: interact, weight: "bold", size: 13pt)[Punto de quiebre · #tipo]
          #v(0.25em)
          #text(fill: texto, size: 12.5pt)[#pregunta]
          #v(0.4em)
          #text(fill: muted, size: 10pt)[⏱ #duracion · Votación mano alzada o Mentimeter]
        ],
      )
    ]
  ]
}

// =============================================================================
// S09-S10 · Bloque de implementación
// =============================================================================
#let cap-codigo-parte(
  titulo: "Implementación Python · parte 1", snippet: "", salida: none,
  nota: none, invariante: none, invariante-titulo: "Chequeo de sanidad",
) = {
  slide(title: titulo)[
    #block(
      fill: rgb("#1e1e1e"),
      inset: (x: 0.5em, y: 0.35em),
      radius: 3pt, width: 100%,
    )[
      #set text(size: sz-code, fill: rgb("#D4D4D4"),
                font: ("DejaVu Sans Mono", "Menlo", "Courier New"))
      #set par(leading: 0.36em)
      #raw(snippet, lang: "python", block: true)
    ]
    #if invariante != none [
      #v(0.22em)
      #block(fill: rgb("E8F5E9"), stroke: (left: 3pt + green),
             inset: (x: 0.45em, y: 0.25em), radius: 2pt, width: 100%)[
        #text(fill: green, weight: "bold", size: 9pt)[#invariante-titulo]
        #v(0.08em)
        #block(fill: rgb("1e1e1e"), inset: (x: 0.4em, y: 0.22em), radius: 2pt, width: 100%)[
          #set text(size: 7.5pt, fill: rgb("#D4D4D4"),
                    font: ("DejaVu Sans Mono", "Menlo", "Courier New"))
          #raw(invariante, lang: "python", block: true)
        ]
      ]
    ]
    #if salida != none [
      #v(0.25em)
      #text(fill: navy, weight: "bold", size: 10pt)[Salida]
      #block(fill: light, inset: (x: 0.5em, y: 0.25em),
             radius: 2pt, width: 100%)[
        #set text(size: 8pt, font: ("DejaVu Sans Mono", "Menlo", "Courier New"))
        #set par(leading: 0.36em)
        #raw(salida, lang: "text", block: true)
      ]
    ]
    #if nota != none [
      #v(0.2em)
      #text(fill: muted, size: 9pt)[💡 #nota]
    ]
  ]
}

#let cap-codigo(lenguaje: "python", snippet: "", salida: none) = {
  cap-codigo-parte(titulo: "Implementación Python", snippet: snippet, salida: salida)
}

// =============================================================================
// S09' · Diagrama (escala para caber en el cuerpo útil ~10×5.5 cm)
// =============================================================================
#let cap-diagrama(titulo: "Diagrama", cuerpo-diagrama: []) = {
  // horizon: centra figuras que no llenan el alto útil
  slide(title: titulo, align: horizon)[
    #align(center)[
      #scale(x: 95%, y: 95%, reflow: true)[#cuerpo-diagrama]
    ]
  ]
}

// =============================================================================
// S11 · Caso aplicado: resolución
// =============================================================================
#let cap-caso-resolucion(titulo: "", contexto: "", resultado: "", interpretacion: "") = {
  slide(title: [Caso aplicado · #titulo])[
    #text(fill: accent, weight: "bold", size: 11pt)[Recordatorio del caso]
    #v(0.12em)
    #text(fill: texto, size: 10.5pt)[#contexto]
    #v(0.35em)
    #text(fill: accent, weight: "bold", size: 11pt)[Resultado numérico]
    #v(0.12em)
    #block(fill: light, inset: (x: 0.55em, y: 0.35em),
           radius: 2pt, width: 100%)[
      #text(fill: texto, size: 10.5pt)[#resultado]
    ]
    #v(0.35em)
    #block(fill: rgb("#E8F5E9"), stroke: (left: 3pt + green),
           inset: 0.45em, radius: 2pt, width: 100%)[
      #text(fill: green, weight: "bold", size: 11pt)[Lectura de política]
      #text(fill: texto, size: 10.5pt)[ · #interpretacion]
    ]
  ]
}

#let cap-caso(titulo: "", contexto: "", resultado: "") = {
  cap-caso-resolucion(titulo: titulo, contexto: contexto,
                      resultado: resultado, interpretacion: "")
}

// =============================================================================
// S12 · Validación / robustez
// =============================================================================
#let cap-validacion(tipo: "", descripcion: "", conclusion: "") = {
  slide(title: [Validación y robustez])[
    #text(fill: navy, weight: "bold", size: sz-h)[Técnica: #tipo]
    #v(0.25em)
    #text(fill: texto, size: 11pt)[#descripcion]
    #v(0.45em)
    #block(fill: rgb("#E8F5E9"), stroke: (left: 3pt + green),
           inset: 0.45em, radius: 2pt, width: 100%)[
      #text(fill: green, weight: "bold", size: 11pt)[Conclusión]
      #text(fill: texto, size: 11pt)[ · #conclusion]
    ]
  ]
}

// =============================================================================
// S13 · Mapeo PCH del capítulo · pregunta activa
// (sustituye al "mapeo GCE" del ejemplo original: no hay marco GCE en este
// curso; el eje que se repite capítulo a capítulo es la Jerarquía Causal de
// Pearl y la pregunta de si el efecto estimado cambia la decisión frente a
// solo predecir — silabo.typ §2.)
// =============================================================================
#let cap-mapeo-pch-activo(nivel: "", metrica: "", pregunta-activa: "") = {
  slide(title: [Mapeo PCH del capítulo · pregunta activa])[
    #block(fill: navy, inset: (x: 0.55em, y: 0.4em),
           radius: 3pt, width: 100%)[
      #grid(
        columns: (1fr, 1fr), column-gutter: 0.5em, row-gutter: 0.25em,
        text(fill: white, weight: "bold", size: 11pt)[Nivel PCH],
        text(fill: white, weight: "bold", size: 11pt)[Estimando / métrica principal],
        text(fill: light, size: 11.5pt)[#nivel],
        text(fill: light, size: 11.5pt)[#metrica],
      )
    ]
    #v(0.45em)
    #block(fill: interact-bg, stroke: (left: 3pt + interact),
           inset: 0.55em, radius: 2pt, width: 100%)[
      #text(fill: interact, weight: "bold", size: 11.5pt)[Pregunta activa (1 min)]
      #v(0.15em)
      #text(fill: texto, size: 11.5pt)[#pregunta-activa]
    ]
    #v(0.35em)
    #align(center)[
      #text(fill: muted, size: 9pt)[
        Escalera PCH: L1 (asociación) ⊆ L2 (intervención) ⊆ L3 (contrafactual) —
        cada nivel exige supuestos estrictamente más fuertes que el anterior.
        Si solo predijéramos, ¿a quién trataríamos? Con el efecto, ¿cambia la decisión?
      ]
    ]
  ]
}

#let cap-mapeo-pch(nivel: "", metrica: "") = {
  cap-mapeo-pch-activo(nivel: nivel, metrica: metrica,
    pregunta-activa: "¿Por qué este método pertenece a este nivel de la PCH y no a otro?")
}

// =============================================================================
// S14 · Errores comunes + transiciones (Variante A — tablas de riesgos del libro)
// =============================================================================
#let cap-errores-transiciones(errores: (), conexiones: none) = {
  slide(title: [Errores comunes y conexiones])[
    #text(fill: navy, weight: "bold", size: sz-h)[Errores comunes]
    #v(0.15em)
    #for ((tipo, desc)) in errores [
      #block(
        fill: if tipo == "crítico" { rgb("#FFEBEE") }
              else if tipo == "advertencia" { rgb("#FFF8E1") }
              else { light },
        stroke: (left: 3pt + if tipo == "crítico" { error }
                              else if tipo == "advertencia" { orange }
                              else { accent }),
        inset: (x: 0.45em, y: 0.28em), radius: 2pt, width: 100%,
      )[#text(fill: texto, size: 10pt)[#desc]]
      #v(0.15em)
    ]
    #if conexiones != none [
      #v(0.2em)
      #text(fill: accent, weight: "bold", size: 11pt)[Conexiones conceptuales]
      #v(0.1em)
      #text(fill: texto, size: 10pt)[#conexiones]
    ]
  ]
}

#let cap-errores(errores: ()) = cap-errores-transiciones(errores: errores, conexiones: none)

// =============================================================================
// S14B · Checklist de señales de alerta (Variante B — espeja #checklist[] del libro)
// =============================================================================
#let cap-checklist-alertas(items: ()) = {
  slide(title: [Señales de alerta y checklist operativo])[
    #for it in items [
      #block(inset: (y: 0.12em))[
        #text(fill: crimson, size: 12pt)[☐] #h(0.3em)
        #text(fill: texto, size: 10.5pt)[#it]
      ]
    ]
    #v(0.3em)
    #text(fill: muted, size: 9pt, style: "italic")[
      Si dos o más señales están presentes, el sistema no está listo según los
      criterios de este curso.
    ]
  ]
}

// =============================================================================
// S14C · Callout del monorepo — solo capítulos con #monorepo[] en el libro
// (Caps. 4, 9, 15, 19, 20, 30)
// =============================================================================
#let cap-monorepo(texto-monorepo: "") = {
  slide(title: [Implementación en el monorepo del curso], align: horizon)[
    #block(fill: rgb("#EFF6FB"), stroke: (left: 4pt + accent),
           inset: (x: 0.8em, y: 0.55em), radius: 3pt, width: 100%)[
      #text(fill: accent, weight: "bold", size: 12.5pt)[
        02_monografia → 03_notebooks_caso_estudio / 04_notebooks_produccion_hf / 05_labs_sesion
      ]
      #v(0.3em)
      #text(fill: texto, size: 11pt)[#texto-monorepo]
    ]
  ]
}

// =============================================================================
// S15 · Síntesis + discusión + ejercicio
// =============================================================================
#let cap-discusion-ejercicio(pregunta: "", ejercicio: "") = {
  slide(title: [Discusión y ejercicio])[
    #block(fill: light, inset: (x: 0.55em, y: 0.4em),
           radius: 2pt, width: 100%)[
      #text(fill: navy, weight: "bold", size: sz-h)[Pregunta de discusión]
      #v(0.15em)
      #text(fill: texto, size: 11pt)[#pregunta]
    ]
    #v(0.4em)
    #block(fill: rgb("#E3F2FD"), stroke: (left: 3pt + accent),
           inset: 0.45em, radius: 2pt, width: 100%)[
      #text(fill: accent, weight: "bold", size: sz-h)[Ejercicio (5-10 min)]
      #v(0.15em)
      #text(fill: texto, size: 11pt)[#ejercicio]
    ]
  ]
}

#let cap-discusion = cap-discusion-ejercicio

// =============================================================================
// S16 · Cierre narrativo
// =============================================================================
#let cap-cierre-narrativo(resumen: (), refs: (), transicion: "", gancho: "") = {
  slide(title: [Cierre del capítulo])[
    #grid(
      columns: (1.15fr, 0.85fr), column-gutter: 0.7em,
      [
        #text(fill: navy, weight: "bold", size: sz-h)[Resumen]
        #v(0.15em)
        #for r in resumen [
          #block(inset: (y: 0.06em))[
            #text(fill: navy, weight: "bold", size: 10.5pt)[•]
            #text(fill: texto, size: 10.5pt)[ #r]
          ]
        ]
      ],
      [
        #text(fill: navy, weight: "bold", size: sz-h)[Referencias clave]
        #v(0.15em)
        #for (i, r) in refs.enumerate() [
          #block(inset: (y: 0.05em))[
            #text(fill: muted, size: 9.5pt)[(#(i + 1))]
            #text(fill: texto, size: 9.5pt)[ #r]
          ]
        ]
      ],
    )
    #v(0.4em)
    #block(fill: navy, inset: (x: 0.55em, y: 0.4em),
           radius: 2pt, width: 100%)[
      #text(fill: white, weight: "bold", size: 11.5pt)[Próximo episodio]
      #text(fill: light, size: 11pt)[ · #transicion]
      #if gancho != "" [
        #v(0.15em)
        #text(fill: white, size: 10.5pt, style: "italic")[Gancho: #gancho]
      ]
    ]
  ]
}

#let cap-cierre(resumen: (), refs: (), transicion: "") = {
  cap-cierre-narrativo(resumen: resumen, refs: refs, transicion: transicion, gancho: "")
}
