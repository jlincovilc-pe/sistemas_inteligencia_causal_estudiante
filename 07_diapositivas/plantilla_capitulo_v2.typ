// =============================================================================
// plantilla_capitulo_v2.typ — Plantilla Touying V2 reutilizable
// Touying 0.5.5 + Typst 0.15 · cetz 0.3.4
//
// Layout V2.1 (proporciones de aula 16:9):
//   - Cuerpo 13pt (Metropolis default 20pt desborda con contenido denso)
//   - Alineación superior (no horizon) para evitar “huecos” y solapes
//   - Código 8pt mono · tablas 10–11pt · márgenes con hueco para header/footer
//   - Contadores de agenda/refs con enumerate (el `let n = n+1` de Typst no muta)
//   - Portada como slide normal (evita página fantasma del title-slide)
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

// ─── Paleta UNI granate + púrpura interactivo ─────────────────────────────────
#let uni-granate    = rgb("#6B1A1A")
#let uni-granate-os = rgb("#8B0000")
#let uni-accent     = rgb("#B22222")
#let uni-accent2    = rgb("#2F5496")
#let uni-crema      = rgb("#EFE9E2")
#let uni-borde      = rgb("#C9BBA8")
#let uni-texto      = rgb("#1F1B16")
#let uni-muted      = rgb("#6F655A")
#let uni-success    = rgb("#3E7B4F")
#let uni-warning    = rgb("#B58A1F")
#let uni-error      = rgb("#9A2A2A")
#let uni-interact   = rgb("#7B3F8D")
#let uni-interact-bg = rgb("#F3E8F9")

// Tipografía de proporciones (referencia)
#let sz-body   = 12.5pt
#let sz-title  = 18pt
#let sz-h      = 12pt
#let sz-small  = 10pt
#let sz-tiny   = 9pt
#let sz-code   = 7.8pt
#let sz-table  = 10pt

// ─── Estado global del capítulo ───────────────────────────────────────────────
#let cap-state = (num: 1, titulo: "", bloque: "", nivel-gce: "", variant: "", pair-with: "")

#let cap-init(num: 1, titulo: "", bloque: "", nivel-gce: "", variant: "", pair-with: "") = {
  state("cap-state").update((num: num, titulo: titulo, bloque: bloque,
                              nivel-gce: nivel-gce, variant: variant,
                              pair-with: pair-with))
}

// ─── Tema base: Metropolis con paleta UNI + proporciones de aula ─────────────
// align: top — crítico: horizon centra y deja slides “vacíos” o desborda.
// El wrapper re-aplica text size tras el 20pt de Metropolis.
#let cap-theme(body) = {
  show: metropolis-theme.with(
    aspect-ratio: "16-9",
    align: top,
    footer-progress: true,
    config-colors(
      primary: uni-granate,
      primary-light: uni-crema,
      secondary: uni-accent2,
      neutral-light: uni-crema,
      neutral-lightest: rgb("#FAFAF8"),
      neutral-darkest: uni-texto,
      foreground: uni-texto,
    ),
    config-common(
      slide-level: 1,
    ),
    config-page(
      // top: hueco del header Metropolis; bottom: footer + progress bar
      margin: (left: 1.35cm, right: 1.35cm, top: 2.0cm, bottom: 1.35cm),
      footer: context {
        text(size: 7.5pt, fill: uni-muted)[
          #text(fill: uni-granate, weight: "bold")[Inferencia Causal · DES504]
          · |τATE| ≤ W₁ ≤ W^(G,1) · UNI 2026 · V2
        ]
      },
    ),
    config-methods(node-radius: 4pt, node-fill: uni-crema),
  )

  // Overrides de proporción (van dentro del body del tema → ganan a 20pt)
  set text(
    font: ("New Computer Modern", "Libertinus Serif", "Georgia"),
    size: sz-body,
    lang: "es",
    fill: uni-texto,
  )
  set par(leading: 0.42em, spacing: 0.5em)
  set list(tight: true, marker: text(fill: uni-granate)[•])
  set enum(tight: true, numbering: "1.")
  set table(
    inset: (x: 0.4em, y: 0.28em),
    stroke: 0.4pt + uni-borde,
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
  // Títulos de slide (header Metropolis usa 1.2em del cuerpo → ~15pt)
  body
}

// =============================================================================
// S00 · Progreso del curso
// =============================================================================
#let cap-progreso-curso(cap-actual: 1) = {
  let bloques = (
    ("I",  (1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12), "Fundamentación"),
    ("II", (13, 14, 15, 16, 17, 18, 19),             "Formalización"),
    ("III",(20, 21, 22, 23, 24, 25, 26, 27),         "Descubrimiento/ML"),
    ("IV", (28, 29, 30, 31, 32),                     "Causal AI"),
  )
  slide(title: [Progreso del curso · 32 capítulos], align: horizon)[
    #grid(
      columns: 4,
      column-gutter: 0.45em,
      row-gutter: 0.45em,
      ..bloques.map(((bname, caps, bdesc)) => {
        block(fill: uni-crema, inset: 0.55em, radius: 3pt, width: 100%)[
          #text(fill: uni-granate, weight: "bold", size: 12pt)[Bloque #bname]
          #v(0.15em)
          #text(size: 8.5pt, fill: uni-muted)[#bdesc]
          #v(0.35em)
          #grid(
            columns: 4, row-gutter: 0.22em, column-gutter: 0.22em,
            ..caps.map(c => {
              let col = if c == cap-actual { uni-granate }
                        else if c < cap-actual { uni-borde }
                        else { white }
              let txtcol = if c == cap-actual or c < cap-actual { white } else { uni-texto }
              let st = if c > cap-actual { 0.4pt + uni-borde } else { none }
              block(fill: col, inset: (x: 0.35em, y: 0.2em), radius: 2pt, stroke: st)[
                #text(
                  fill: txtcol, size: 8.5pt,
                  weight: if c == cap-actual { "bold" } else { "regular" },
                )[#c]
              ]
            }),
          )
        ]
      }),
    )
    #v(0.7em)
    #align(center)[
      #text(fill: uni-muted, size: 9.5pt)[
        #box(fill: uni-borde, width: 0.75em, height: 0.75em) #h(0.25em) previos ·
        #box(fill: uni-granate, width: 0.75em, height: 0.75em) #h(0.25em) actual ·
        #box(stroke: 0.4pt + uni-borde, width: 0.75em, height: 0.75em) #h(0.25em) próximos
      ]
    ]
  ]
}

// =============================================================================
// S01 · Portada (slide normal — evita página fantasma del title-slide)
// =============================================================================
#let cap-portada(num: 1, titulo: "", bloque: "", nivel-gce: "", variant: "") = {
  slide(title: none, align: horizon)[
    #align(center)[
      #box(fill: uni-granate, inset: (x: 0.7em, y: 0.3em), radius: 2pt)[
        #text(fill: white, weight: "bold", size: 12pt)[CAPÍTULO #num]
      ]
      #v(0.55em)
      #text(fill: uni-granate, weight: "bold", size: 26pt)[#titulo]
      #v(0.45em)
      #line(length: 55%, stroke: 1.2pt + uni-granate)
      #v(0.4em)
      #text(fill: uni-muted, size: 12pt)[Bloque #bloque · Nivel GCE: #nivel-gce]
      #v(0.25em)
      #text(fill: uni-accent2, size: 11pt)[Variante: #variant]
      #v(0.9em)
      #text(fill: uni-texto, size: 12pt)[Inferencia Causal Aplicada con Python]
      #v(0.2em)
      #text(fill: uni-muted, size: 10.5pt)[DES504 · Dr. Jaime Lincovil · UNI · 2026]
    ]
  ]
}

// =============================================================================
// S02 · Roadmap + prerequisitos
// =============================================================================
#let cap-roadmap(objetivos: (), agenda: (), lectura: "", notebook: "", notebook-jb: "") = {
  slide(title: [Roadmap del capítulo])[
    #grid(
      columns: (1.05fr, 0.95fr), column-gutter: 0.85em,
      [
        #text(fill: uni-granate, weight: "bold", size: sz-h)[Objetivos de aprendizaje]
        #v(0.25em)
        #enum(
          numbering: "1.",
          tight: true,
          ..objetivos.map(o => text(size: 11pt)[#o]),
        )
        #v(0.35em)
        #block(
          fill: uni-interact-bg,
          stroke: (left: 3pt + uni-interact),
          inset: 0.45em, radius: 2pt, width: 100%,
        )[
          #text(fill: uni-interact, weight: "bold", size: sz-small)[★ Prerequisitos]
          #v(0.15em)
          #set text(size: 8.5pt, fill: uni-texto)
          #set par(leading: 0.38em)
          *Lectura:* #lectura \
          *Notebook (pack):* #notebook
          #if notebook-jb != "" [
            \
            *Notebook (JB):* #notebook-jb
          ]
        ]
      ],
      [
        #text(fill: uni-granate, weight: "bold", size: sz-h)[Agenda]
        #v(0.25em)
        #for (i, a) in agenda.enumerate() [
          #block(
            fill: uni-crema,
            inset: (x: 0.45em, y: 0.22em),
            radius: 2pt, width: 100%,
          )[
            #text(fill: uni-granate, weight: "bold", size: 9pt)[
              S#if i + 1 < 10 [0]#str(i + 1)
            ]
            #text(fill: uni-texto, size: 10pt)[ · #a]
          ]
          #v(0.12em)
        ]
      ],
    )
  ]
}

// =============================================================================
// S03 · Motivación + caso
// =============================================================================
#let cap-motivacion(problema: "", gancho: "", caso: none) = {
  slide(title: [Motivación: el problema central])[
    #block(fill: uni-crema, inset: (x: 0.7em, y: 0.5em), radius: 3pt, width: 100%)[
      #text(fill: uni-granate, weight: "bold", size: sz-h)[Problema]
      #v(0.2em)
      #text(fill: uni-texto, size: 11.5pt)[#problema]
    ]
    #v(0.4em)
    #text(fill: uni-accent2, weight: "bold", size: sz-h)[Gancho empírico]
    #v(0.15em)
    #text(fill: uni-texto, size: 11.5pt)[#gancho]
    #if caso != none [
      #v(0.4em)
      #block(fill: rgb("#FFF3E0"), stroke: (left: 3pt + uni-warning),
             inset: 0.45em, radius: 2pt, width: 100%)[
        #text(fill: uni-warning, weight: "bold", size: 11pt)[Caso del curso]
        #text(fill: uni-texto, size: 11pt)[ · #caso]
      ]
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
        text(fill: uni-granate, weight: "bold", size: 11pt)[#t],
        text(fill: uni-texto, size: 11pt)[#d],
      )).flatten(),
    )
  ]
}

// =============================================================================
// Cajas teorema / lema / axioma
// =============================================================================
#let caja-teorema(titulo: "Teorema", cuerpo: "", ref-apendice: none) = {
  block(
    fill: uni-crema,
    stroke: (left: 3pt + uni-granate, rest: 0.4pt + uni-borde),
    inset: (x: 0.7em, y: 0.45em), radius: 2pt, width: 100%,
  )[
    #text(fill: uni-granate, weight: "bold", size: 12pt)[#titulo]
    #v(0.25em)
    #text(fill: uni-texto, size: 11pt)[#cuerpo]
    #if ref-apendice != none [
      #v(0.25em)
      #text(fill: uni-muted, size: 9pt)[Demostración: Apéndice de Demostraciones, #ref-apendice.]
    ]
  ]
}
#let caja-lema(titulo: "Lema", cuerpo: "") = caja-teorema(titulo: titulo, cuerpo: cuerpo)
#let caja-axioma(titulo: "Axioma", cuerpo: "") = caja-teorema(titulo: titulo, cuerpo: cuerpo)

// =============================================================================
// S05 · Definición formal
// =============================================================================
#let cap-definicion(titulo-def: "", cuerpo: "", eq: none) = {
  slide(title: [Marco teórico I: definición formal])[
    #text(fill: uni-granate, weight: "bold", size: sz-h)[#titulo-def]
    #v(0.3em)
    #text(fill: uni-texto, size: 11.5pt)[#cuerpo]
    #if eq != none [
      #v(0.4em)
      #align(center)[
        #block(fill: uni-crema, inset: (x: 0.8em, y: 0.45em), radius: 2pt)[#eq]
      ]
    ]
  ]
}

// =============================================================================
// S06 · Supuestos
// =============================================================================
#let cap-supuestos(supuestos: ()) = {
  slide(title: [Marco teórico II: supuestos de identificación])[
    #set text(size: sz-table)
    #table(
      columns: (0.95fr, 1.15fr, 1.15fr),
      align: (left + top, left + top, left + top),
      stroke: 0.4pt + uni-borde,
      fill: (_, y) => if y == 0 { uni-granate } else if calc.odd(y) { uni-crema } else { white },
      table.header(
        text(fill: white, weight: "bold", size: 10pt)[Supuesto],
        text(fill: white, weight: "bold", size: 10pt)[Implicación],
        text(fill: white, weight: "bold", size: 10pt)[Chequeo en el caso],
      ),
      ..supuestos.map(((s, i, c)) => (
        text(fill: uni-granate, weight: "bold", size: 9.5pt)[#s],
        text(fill: uni-texto, size: 9.5pt)[#i],
        text(fill: uni-accent2, size: 9.5pt)[#c],
      )).flatten(),
    )
  ]
}

// =============================================================================
// S07 · Teorema central
// =============================================================================
#let cap-teorema(titulo: "Teorema", enunciado: "", ref-apendice: none) = {
  // horizon: teoremas cortos no quedan pegados al header
  slide(title: [Teorema central], align: horizon)[
    #caja-teorema(titulo: titulo, cuerpo: enunciado, ref-apendice: ref-apendice)
  ]
}

// =============================================================================
// S08 · Demostración guiada
// =============================================================================
#let cap-demostracion(pasos: ()) = {
  slide(title: [Demostración: idea principal])[
    #for (i, p) in pasos.enumerate() [
      #block(width: 100%, inset: (y: 0.08em))[
        #text(fill: uni-granate, weight: "bold", size: 11.5pt)[Paso #(i + 1).]
        #text(fill: uni-texto, size: 11pt)[ #p]
      ]
      #if i + 1 < pasos.len() [
        #align(center)[#text(fill: uni-accent, size: 11pt)[↓]]
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
      fill: uni-interact-bg,
      stroke: (left: 4pt + uni-interact, rest: 0.5pt + uni-interact),
      inset: (x: 0.9em, y: 0.7em), radius: 3pt, width: 100%,
    )[
      #grid(
        columns: (auto, 1fr), column-gutter: 0.7em,
        text(fill: uni-interact, weight: "bold", size: 22pt)[★],
        [
          #text(fill: uni-interact, weight: "bold", size: 13pt)[Punto de quiebre · #tipo]
          #v(0.25em)
          #text(fill: uni-texto, size: 12.5pt)[#pregunta]
          #v(0.4em)
          #text(fill: uni-muted, size: 10pt)[⏱ #duracion · Votación mano alzada o Mentimeter]
        ],
      )
    ]
  ]
}

// =============================================================================
// S09-S10 · Bloque de implementación
// =============================================================================
#let cap-codigo-parte(titulo: "Implementación Python · parte 1",
                      snippet: "", salida: none, nota: none, assert: none) = {
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
    #if assert != none [
      #v(0.22em)
      #block(fill: rgb("E8F5E9"), stroke: (left: 3pt + uni-success),
             inset: (x: 0.45em, y: 0.25em), radius: 2pt, width: 100%)[
        #text(fill: uni-success, weight: "bold", size: 9pt)[Invariante (cadena maestra GCE)]
        #v(0.08em)
        #block(fill: rgb("1e1e1e"), inset: (x: 0.4em, y: 0.22em), radius: 2pt, width: 100%)[
          #set text(size: 7.5pt, fill: rgb("#D4D4D4"),
                    font: ("DejaVu Sans Mono", "Menlo", "Courier New"))
          #raw(assert, lang: "python", block: true)
        ]
      ]
    ]
    #if salida != none [
      #v(0.25em)
      #text(fill: uni-granate, weight: "bold", size: 10pt)[Salida]
      #block(fill: uni-crema, inset: (x: 0.5em, y: 0.25em),
             radius: 2pt, width: 100%)[
        #set text(size: 8pt, font: ("DejaVu Sans Mono", "Menlo", "Courier New"))
        #set par(leading: 0.36em)
        #raw(salida, lang: "text", block: true)
      ]
    ]
    #if nota != none [
      #v(0.2em)
      #text(fill: uni-muted, size: 9pt)[💡 #nota]
    ]
  ]
}

#let cap-codigo(lenguaje: "python", snippet: "", salida: none) = {
  cap-codigo-parte(titulo: "Implementación Python · Proofs-to-Python",
                   snippet: snippet, salida: salida)
}

// =============================================================================
// S09 · Diagrama (escala para caber en el cuerpo útil ~10×5.5 cm)
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
    #text(fill: uni-accent2, weight: "bold", size: 11pt)[Recordatorio del caso (S03)]
    #v(0.12em)
    #text(fill: uni-texto, size: 10.5pt)[#contexto]
    #v(0.35em)
    #text(fill: uni-accent2, weight: "bold", size: 11pt)[Resultado numérico]
    #v(0.12em)
    #block(fill: uni-crema, inset: (x: 0.55em, y: 0.35em),
           radius: 2pt, width: 100%)[
      #text(fill: uni-texto, size: 10.5pt)[#resultado]
    ]
    #v(0.35em)
    #block(fill: rgb("#E8F5E9"), stroke: (left: 3pt + uni-success),
           inset: 0.45em, radius: 2pt, width: 100%)[
      #text(fill: uni-success, weight: "bold", size: 11pt)[Lectura de política]
      #text(fill: uni-texto, size: 10.5pt)[ · #interpretacion]
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
    #text(fill: uni-granate, weight: "bold", size: sz-h)[Técnica: #tipo]
    #v(0.25em)
    #text(fill: uni-texto, size: 11pt)[#descripcion]
    #v(0.45em)
    #block(fill: rgb("#E8F5E9"), stroke: (left: 3pt + uni-success),
           inset: 0.45em, radius: 2pt, width: 100%)[
      #text(fill: uni-success, weight: "bold", size: 11pt)[Conclusión]
      #text(fill: uni-texto, size: 11pt)[ · #conclusion]
    ]
  ]
}

// =============================================================================
// S13 · Mapeo GCE ACTIVO
// =============================================================================
#let cap-mapeo-gce-activo(nivel: "", metrica: "", pregunta-activa: "") = {
  slide(title: [Mapeo GCE del capítulo · pregunta activa])[
    #block(fill: uni-granate, inset: (x: 0.55em, y: 0.4em),
           radius: 3pt, width: 100%)[
      #grid(
        columns: (1fr, 1fr), column-gutter: 0.5em, row-gutter: 0.25em,
        text(fill: white, weight: "bold", size: 11pt)[Nivel GCE],
        text(fill: white, weight: "bold", size: 11pt)[Métrica principal],
        text(fill: uni-crema, size: 11.5pt)[#nivel],
        text(fill: uni-crema, size: 11.5pt)[#metrica],
      )
    ]
    #v(0.45em)
    #block(fill: uni-interact-bg, stroke: (left: 3pt + uni-interact),
           inset: 0.55em, radius: 2pt, width: 100%)[
      #text(fill: uni-interact, weight: "bold", size: 11.5pt)[Pregunta activa (1 min)]
      #v(0.15em)
      #text(fill: uni-texto, size: 11.5pt)[#pregunta-activa]
    ]
    #v(0.35em)
    #align(center)[
      #text(fill: uni-muted, size: 9pt)[
        Cadena maestra: |τATE| ≤ W₁ ≤ W^(G,1) — ¿localización, forma o geometría?
        El Nivel 3 subsume al 2 y al 1, no al revés.
      ]
    ]
  ]
}

#let cap-mapeo-gce(nivel: "", metrica: "", cadena: "") = {
  cap-mapeo-gce-activo(nivel: nivel, metrica: metrica,
                       pregunta-activa: "¿Por qué este método pertenece a este nivel GCE y no a otro?")
}

// =============================================================================
// S14 · Errores comunes + transiciones
// =============================================================================
#let cap-errores-transiciones(errores: (), conexiones: none) = {
  slide(title: [Errores comunes y conexiones])[
    #text(fill: uni-granate, weight: "bold", size: sz-h)[Errores comunes]
    #v(0.15em)
    #for ((tipo, desc)) in errores [
      #block(
        fill: if tipo == "crítico" { rgb("#FFEBEE") }
              else if tipo == "advertencia" { rgb("#FFF8E1") }
              else { uni-crema },
        stroke: (left: 3pt + if tipo == "crítico" { uni-error }
                              else if tipo == "advertencia" { uni-warning }
                              else { uni-accent2 }),
        inset: (x: 0.45em, y: 0.28em), radius: 2pt, width: 100%,
      )[#text(fill: uni-texto, size: 10pt)[#desc]]
      #v(0.15em)
    ]
    #if conexiones != none [
      #v(0.2em)
      #text(fill: uni-accent2, weight: "bold", size: 11pt)[Conexiones conceptuales]
      #v(0.1em)
      #text(fill: uni-texto, size: 10pt)[#conexiones]
    ]
  ]
}

#let cap-errores(errores: ()) = cap-errores-transiciones(errores: errores, conexiones: none)

// =============================================================================
// S15 · Síntesis + discusión + ejercicio
// =============================================================================
#let cap-discusion-ejercicio(pregunta: "", ejercicio: "") = {
  slide(title: [Discusión y ejercicio])[
    #block(fill: uni-crema, inset: (x: 0.55em, y: 0.4em),
           radius: 2pt, width: 100%)[
      #text(fill: uni-granate, weight: "bold", size: sz-h)[Pregunta de discusión]
      #v(0.15em)
      #text(fill: uni-texto, size: 11pt)[#pregunta]
    ]
    #v(0.4em)
    #block(fill: rgb("#E3F2FD"), stroke: (left: 3pt + uni-accent2),
           inset: 0.45em, radius: 2pt, width: 100%)[
      #text(fill: uni-accent2, weight: "bold", size: sz-h)[Ejercicio (5-10 min)]
      #v(0.15em)
      #text(fill: uni-texto, size: 11pt)[#ejercicio]
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
        #text(fill: uni-granate, weight: "bold", size: sz-h)[Resumen]
        #v(0.15em)
        #for r in resumen [
          #block(inset: (y: 0.06em))[
            #text(fill: uni-granate, weight: "bold", size: 10.5pt)[•]
            #text(fill: uni-texto, size: 10.5pt)[ #r]
          ]
        ]
      ],
      [
        #text(fill: uni-granate, weight: "bold", size: sz-h)[Referencias clave]
        #v(0.15em)
        #for (i, r) in refs.enumerate() [
          #block(inset: (y: 0.05em))[
            #text(fill: uni-muted, size: 9.5pt)[(#(i + 1))]
            #text(fill: uni-texto, size: 9.5pt)[ #r]
          ]
        ]
      ],
    )
    #v(0.4em)
    #block(fill: uni-granate, inset: (x: 0.55em, y: 0.4em),
           radius: 2pt, width: 100%)[
      #text(fill: white, weight: "bold", size: 11.5pt)[Próximo episodio]
      #text(fill: uni-crema, size: 11pt)[ · #transicion]
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
