// template.typ — Plantilla consolidada de la monografía
// Machine Learning Causal para Economistas — Edición 2026

// ============================================================
// 1. Paleta cromática
// ============================================================
#let navy    = rgb("#0F1E3D")
#let crimson = rgb("#C8102E")
#let gray    = rgb("#4A4A4A")
#let light   = rgb("#F5F7FA")
#let accent  = rgb("#1E5A8E")
#let green   = rgb("#1F7A3A")
#let orange  = rgb("#D97706")

// ============================================================
// 2. Fuentes
// ============================================================
#let serif-font = "New Computer Modern"
// Prefer a widely available UI sans (DejaVu Sans is often missing on macOS).
#let sans-font  = "Helvetica Neue"
#let mono-font  = "DejaVu Sans Mono"

// ============================================================
// 2b. Contador de teoremas (definido temprano, antes de project)
// ============================================================
#let theorem-number = counter("theorem-counter")

#let theorem-number-reset() = {
  theorem-number.update(0)
}

// ============================================================
// 3. Configuración global
// ============================================================
#let project(body) = {
  // Documento
  set document(
    title: "IA Causal en Producción",
    author: "Curso ECO-490 / ECON-540",
    date: datetime(year: 2026, month: 1, day: 1),
    keywords: "causal inference, machine learning, MLOps, Hugging Face, DML, econml",
  )

  // Página
  set page(
    paper: "a4",
    margin: (left: 2.6cm, right: 2.6cm, top: 3.5cm, bottom: 3.5cm),
    header: context {
      let page-num = here().page()
      let n = state("frontmatter-mode").at(here())
      if page-num <= 1 { return }
      let chapter-title = state("chapter-title").at(here())
      let part-title = state("part-title").at(here())
      let header-text = if chapter-title != none { chapter-title } else if part-title != none { part-title } else { "" }
      let even = calc.even(page-num)
      let title-el = text(font: sans-font, size: 9pt, fill: gray)[#header-text]
      let num-el = text(font: sans-font, size: 9pt, fill: gray)[#page-num]
      // Título siempre al margen exterior, folio siempre al margen interior;
      // h(1fr) fuerza la separación entre ambos en vez de un grid de dos
      // columnas independientes (que los pegaba en el borde compartido y
      // producía la colisión título/folio en páginas impares).
      if even {
        title-el; h(1fr); num-el
      } else {
        num-el; h(1fr); title-el
      }
      v(-6pt)
      line(length: 100%, stroke: 0.4pt + gray.lighten(60%))
    },
    numbering: "1",
  )

  // Texto
  set text(
    font: serif-font,
    size: 11pt,
    lang: "es",
    region: "ES",
    hyphenate: true,
    fill: black,
  )
  set par(
    justify: true,
    leading: 0.7em,
    first-line-indent: (amount: 1.2em, all: false),
    spacing: 1em,
  )

  // Heading numbering: por defecto desactivado para frontmatter.
  // Se reactiva con set heading(numbering: "1.1.1") en mainmatter.
  set heading(numbering: none)
  // Supplements en none para que @cap-xxx muestre solo el número, no "Sección X"
  set heading(supplement: none)

  // Heading styles (level 1 = chapter)
  show heading.where(level: 1): it => {
    let kind = state("chapter-kind").at(here())
    if kind == "frontmatter" {
      // Unnumbered chapter (frontmatter): no chapter counter step, no number displayed
      state("chapter-title").update(it.body)
      state("part-title").update(none)
      pagebreak(weak: true)
      v(2em)
      block(width: 100%)[
        #v(0.4em)
        #line(length: 100%, stroke: 0.8pt + navy)
        #v(0.4em)
        #text(font: sans-font, fill: navy, size: 26pt, weight: "bold", hyphenate: false)[#it.body]
        #v(0.4em)
        #line(length: 100%, stroke: 0.8pt + navy)
      ]
      v(1.5em)
    } else {
      // Numbered chapter (mainmatter or appendix)
      pagebreak(weak: true)
      counter("chapter").step()
      counter("section").update(0)
      counter("subsection").update(0)
      // Reset figure/table/listing counters at the start of each chapter
      // (algorithms keep global numbering as in the LaTeX original)
      counter(figure.where(kind: image)).update(0)
      counter(figure.where(kind: table)).update(0)
      counter(figure.where(kind: raw)).update(0)
      counter("equation-counter").update(0)
      theorem-number.update(0)
      state("chapter-title").update(it.body)
      state("part-title").update(none)
      v(2em)
      block(width: 100%)[
        #text(font: sans-font, fill: gray, size: 11pt, tracking: 0.05em)[
          #context {
            let num = counter("chapter").at(here()).first()
            if kind == "appendix" {
              [Apéndice #numbering("A", num)]
            } else {
              [Capítulo #numbering("1", num)]
            }
          }
        ]
        #v(0.4em)
        #line(length: 100%, stroke: 0.8pt + navy)
        #v(0.4em)
        #text(font: sans-font, fill: navy, size: 26pt, weight: "bold", hyphenate: false)[#it.body]
        #v(0.4em)
        #line(length: 100%, stroke: 0.8pt + navy)
      ]
      v(1.5em)
    }
  }

  // Level 2: section — uses chapter.counter + section.counter as numbering parent
  show heading.where(level: 2): it => {
    let kind = state("chapter-kind").at(here())
    counter("section").step()
    counter("subsection").update(0)
    v(0.8em)
    block(width: 100%)[
      #text(font: sans-font, fill: navy, size: 16pt, weight: "bold")[
        #if kind == "frontmatter" [
          #it.body
        ] else if kind == "appendix" [
          #context {
            let ch = counter("chapter").at(here()).first()
            let s = counter("section").at(here()).first()
            numbering("A.1", ch, s)
          }
          #h(0.5em)
          #it.body
        ] else [
          #context {
            let ch = counter("chapter").at(here()).first()
            let s = counter("section").at(here()).first()
            numbering("1.1", ch, s)
          }
          #h(0.5em)
          #it.body
        ]
      ]
    ]
    v(0.4em)
  }

  show heading.where(level: 3): it => {
    counter("subsection").step()
    v(0.5em)
    block(width: 100%)[
      #text(font: sans-font, fill: accent, size: 13pt, weight: "bold")[
        #context {
          let kind = state("chapter-kind").at(here())
          let ch = counter("chapter").at(here()).first()
          let s = counter("section").at(here()).first()
          let ss = counter("subsection").at(here()).first()
          if kind == "appendix" {
            numbering("A.1.1", ch, s, ss)
          } else {
            numbering("1.1.1", ch, s, ss)
          }
        }
        #h(0.4em)
        #it.body
      ]
    ]
    v(0.3em)
  }

  show heading.where(level: 4): it => {
    v(0.3em)
    text(font: sans-font, fill: gray, size: 11pt, style: "italic")[
      #it.body
    ]
  }

  show heading.where(level: 5): it => {
    v(0.2em)
    text(font: sans-font, fill: gray, size: 10pt, weight: "bold")[
      #it.body
    ]
  }

  // Math equation numbering per chapter: (1.1), (1.2), ...
  // Activate numbering globally and customize the format per chapter
  set math.equation(numbering: (n) => {
    let c = counter("chapter").at(here()).first()
    "(" + numbering("1.1", c, n) + ")"
  })

  // Figure numbering per chapter using a numbering function
  // Typst's figure() uses an internal counter; we provide a function
  // that takes the figure's own number and prepends the chapter number.
  show figure.where(kind: image): set figure(
    supplement: [Figura],
    numbering: (n) => {
      let c = counter("chapter").at(here()).first()
      numbering("1.1", c, n)
    }
  )
  show figure.where(kind: table): set figure(
    supplement: [Tabla],
    numbering: (n) => {
      let c = counter("chapter").at(here()).first()
      numbering("1.1", c, n)
    }
  )
  show figure.where(kind: raw): set figure(
    supplement: [Listado],
    numbering: (n) => {
      let c = counter("chapter").at(here()).first()
      numbering("1.1", c, n)
    }
  )
  show figure.where(kind: "algorithm"): set figure(
    supplement: [Algoritmo],
    numbering: "1."
  )

  // Lists
  set list(indent: 1.5em, body-indent: 0.5em, marker: ([•], [◦], [▪]))
  set enum(indent: 1.5em, body-indent: 0.5em, numbering: "1.")

  // Bloques de código (raw)
  show raw.where(block: true): it => {
    set align(left)
    set text(font: mono-font, size: 9pt)
    block(
      fill: light,
      stroke: 0.4pt + gray.lighten(60%),
      inset: 8pt,
      radius: 2pt,
      width: 100%,
    )[
      #it.text
    ]
  }

  // Alineación a la izquierda y título alineado para figuras tipo código/listado
  show figure.where(kind: raw): it => {
    set align(left)
    it
  }

  body
}

// ============================================================
// 4. Estructura del documento
// ============================================================

#let frontmatter(body) = {
  state("frontmatter-mode").update(true)
  state("chapter-kind").update("frontmatter")
  set page(numbering: "i")
  counter("page").update(1)
  set heading(numbering: none)
  body
}

#let mainmatter(body) = {
  state("frontmatter-mode").update(false)
  state("chapter-kind").update("chapter")
  set page(numbering: "1")
  counter("chapter").update(0)
  counter("section").update(0)
  counter("subsection").update(0)
  counter("part").update(0)
  counter("figure-counter").update(0)
  counter("table-counter").update(0)
  counter("listing-counter").update(0)
  counter("equation-counter").update(0)
  theorem-number.update(0)
  set heading(numbering: "1.1.1")
  body
}

#let appendix-mode(body) = {
  state("chapter-kind").update("appendix")
  counter("chapter").update(0)
  counter("section").update(0)
  counter("subsection").update(0)
  // Numeración nativa de Typst (usada por #outline()) debe reiniciarse y
  // usar letras para que el índice general coincida con el encabezado
  // visual de cada apéndice ("Apéndice A", "Apéndice B", ...), en vez de
  // continuar la numeración arábiga secuencial de los capítulos (33, 34...).
  counter(heading).update(0)
  set heading(numbering: "A.1.1")
  body
}

#let part(title) = {
  state("chapter-title").update(none)
  state("part-title").update(title)
  pagebreak(weak: true)
  counter("part").step()
  v(35%)
  align(center)[
    #text(font: sans-font, fill: gray, size: 14pt, tracking: 0.1em)[
      Parte #context {
        let p = counter("part").at(here()).first()
        numbering("I", p)
      }
    ]
    #v(0.6em)
    #line(length: 30%, stroke: 1pt + navy)
    #v(0.6em)
    #text(font: sans-font, fill: navy, size: 32pt, weight: "bold", hyphenate: false)[#title]
  ]
  pagebreak(weak: true)
}

#let chapter(title) = heading(level: 1, title)
#let section(title) = heading(level: 2, title)
#let subsection(title) = heading(level: 3, title)

// ============================================================
// 6. Bloques de teoremas (contador compartido, por capítulo)
// ============================================================
#let _theorem-block(kind-name, kind-color, body, name: none) = {
  theorem-number.step()
  figure(
    kind: "theorem-block",
    numbering: "1.1",
    supplement: kind-name,
    {
      // Forzamos alineación a la izquierda para evitar que la figura centre la cabecera
      set align(left)
      set par(leading: 0.6em)
      
      block(width: 100%, spacing: 1em, breakable: true)[
        #block(width: 100%)[
          #box(
            fill: kind-color,
            inset: (x: 6pt, y: 3pt),
            radius: 2pt,
          )[
            #text(font: sans-font, fill: white, weight: "bold", size: 10.5pt)[
              #kind-name #context {
                let ch = counter("chapter").at(here()).first()
                let th = theorem-number.at(here()).first()
                numbering("1.1", ch, th)
              }
            ]
          ]
          #if name != none [
            #h(6pt)
            // Aumentamos tamaño (11.5pt) y aseguramos estilo en negrita/cursiva a la izquierda
            #text(font: sans-font, size: 11.5pt, style: "italic", weight: "bold", fill: navy.darken(20%))[
              (#name)
            ]
          ]
        ]
        #v(0.4em)
        #block(inset: (left: 0em, right: 0em))[#body]
      ]
    }
  )
}

// Hide the default figure caption for theorem-block figures
#show figure.where(kind: "theorem-block"): it => it.body

// Accept either `#theorem[body]` or LaTeX-style `#theorem[body][Name]`.
#let _named-theorem(kind-name, kind-color, body, name: none, ..rest) = {
  let n = name
  let pos = rest.pos()
  if pos.len() > 0 {
    n = pos.at(0)
  }
  _theorem-block(kind-name, kind-color, body, name: n)
}

#let theorem(body, name: none, ..rest) = _named-theorem("Teorema", navy, body, name: name, ..rest)
#let proposition(body, name: none, ..rest) = _named-theorem("Proposición", accent, body, name: name, ..rest)
#let lemma(body, name: none, ..rest) = _named-theorem("Lema", accent, body, name: name, ..rest)
#let corollary(body, name: none, ..rest) = _named-theorem("Corolario", accent, body, name: name, ..rest)
#let definition(body, name: none, ..rest) = _named-theorem("Definición", green, body, name: name, ..rest)
#let assumption(body, name: none, ..rest) = _named-theorem("Supuesto", orange, body, name: name, ..rest)
#let example(body, name: none, ..rest) = _named-theorem("Ejemplo", orange, body, name: name, ..rest)
#let remark(body, name: none, ..rest) = _named-theorem("Observación", gray, body, name: name, ..rest)

#let proof(body, kind: "full") = block(width: 100%, spacing: 1em)[
  #text(font: sans-font, style: "italic", weight: "bold")[
    #if kind == "sketch" [Demostración (esquema).] else [Demostración.]
  ]
  #h(4pt)
  #body
  #h(1fr)
  $#sym.square.small$
]

// Alias en español
#let teorema = theorem
#let definicion = definition

// ============================================================
// 6. Cajas tcolorbox equivalentes
// ============================================================
#let _tbox(title, frame-color, body, fill-color: light) = block(
  breakable: true,
  fill: fill-color,
  stroke: (left: 3pt + frame-color, top: 0.4pt + frame-color.lighten(50%),
           bottom: 0.4pt + frame-color.lighten(50%), right: 0.4pt + frame-color.lighten(50%)),
  inset: (left: 10pt, right: 8pt, top: 6pt, bottom: 6pt),
  radius: 2pt,
  width: 100%,
  spacing: 1em,
)[
  #text(font: sans-font, fill: frame-color, weight: "bold", size: 11pt, hyphenate: false)[#title]
  #v(0.3em)
  #body
]

#let cuadrosinoptico(body) = _tbox("Cuadro sinóptico del capítulo", accent, body, fill-color: rgb("#EFF3F8"))
// --- Plantilla B: capítulos de ingeniería y producción (estilo DMLS) ---
#let cuadrodecision(body) = _tbox("Cuadro de decisión del capítulo", accent, body, fill-color: rgb("#EFF3F8"))
#let disenio(body) = _tbox("El problema de diseño", navy, body, fill-color: rgb("#EDF1F7"))
#let opciones(body) = _tbox("Opciones y trade-offs", accent, body, fill-color: rgb("#EFF3F8"))
#let decisionref(body) = _tbox("Decisión de referencia para el curso", green, body, fill-color: green.lighten(85%))
#let supuestos(body) = _tbox("Supuestos del capítulo", gray.darken(20%), body, fill-color: gray.lighten(85%))
#let diagnosticos(body) = _tbox("Diagnósticos recomendados", green, body, fill-color: green.lighten(85%))
#let riesgos(body) = _tbox("Riesgos, límites y mitigación", crimson, body, fill-color: crimson.lighten(88%))
#let notatecnica(body) = _tbox("Nota técnica", orange, body, fill-color: orange.lighten(85%))
#let intuicion(body) = _tbox("Intuición", green, body)
#let advertencia(body) = _tbox("Atención", orange, body)

// Callout de implementación en el monorepo del curso (integración libro ↔ código)
#let monorepo(body) = _tbox(
  "Implementación en el monorepo del curso (2026)",
  accent,
  body,
  fill-color: rgb("#EFF6FB"),
)

// ============================================================
// 7. Algoritmos (estilo algorithm2e ruled)
// ============================================================
#let algorithm(title, body) = figure(
  kind: "algorithm",
  caption: title,
  supplement: [Algoritmo],
  numbering: "1.",
  placement: top,
  {
    // Forzamos alineación a la izquierda en todo el contenido de la figura
    set align(left)
    block(
      stroke: (top: 0.8pt + black, bottom: 0.8pt + black),
      width: 100%,
      spacing: 1em,
    )[
      #block(
        stroke: (bottom: 0.4pt + black),
        inset: (top: 4pt, bottom: 4pt, left: 0pt, right: 0pt),
        width: 100%,
      )[
        #text(font: sans-font, weight: "bold", size: 11pt)[Algoritmo]
      ]
      #v(2pt)
      #set text(size: 10pt)
      #set par(leading: 0.5em, first-line-indent: 0em)
      #block(inset: (left: 0pt, right: 0pt))[#body]
    ]
  }
)

#let kwin(label, body) = {
  text(weight: "bold")[#label:]
  h(2pt)
  body
  linebreak()
}

#let kwout(label, body) = {
  text(weight: "bold")[#label:]
  h(2pt)
  body
  linebreak()
}

#let for-loop(var, from, to, body) = {
  text(weight: "bold")[for]
  h(2pt)
  var
  h(2pt)
  text(weight: "bold")[=]
  h(2pt)
  [#from]
  h(2pt)
  text(weight: "bold")[to]
  h(2pt)
  [#to]
  h(2pt)
  text(weight: "bold")[do]
  linebreak()
  block(inset: (left: 1.5em))[#body]
  linebreak()
  text(weight: "bold")[end for]
  linebreak()
}

#let if-then(cond, body) = {
  text(weight: "bold")[if]
  h(2pt)
  cond
  h(2pt)
  text(weight: "bold")[then]
  linebreak()
  block(inset: (left: 1.5em))[#body]
  linebreak()
  text(weight: "bold")[end if]
  linebreak()
}

#let return-stmt(body) = {
  text(weight: "bold")[return]
  h(2pt)
  body
  linebreak()
}

// ============================================================
// 8. Checklist (con ☐)
// ============================================================
#let checklist(body) = {
  show list.item: it => {
    box[
      #text(fill: navy)[☐] #h(4pt) #it.body
    ]
  }
  list(body)
}

// ============================================================
// 9. Comandos abreviados de notación (equivalente a macros.tex)
// ============================================================
#let code(body) = text(font: mono-font, size: 9.5pt, fill: accent)[#body]

// ============================================================
// 10. Helpers de portada y frontmatter
// ============================================================
#let portada() = page(margin: (top: 4cm, bottom: 4cm, left: 2.5cm, right: 2.5cm), numbering: none)[
  #v(2cm)
  #align(center)[
    #text(font: sans-font, fill: navy, size: 42pt, weight: "bold", hyphenate: false)[
      IA Causal
      #linebreak()
      en Producción
    ]
    #v(1cm)
    #text(font: sans-font, fill: gray, size: 20pt)[
      Monografía del Curso
    ]
    #v(0.5cm)
    #text(font: sans-font, fill: gray, size: 14pt, style: "italic")[
      De la identificación al despliegue: estimar *efectos*, no solo predicciones, \
      y poner políticas causales en producción en Hugging Face
    ]
    #v(3cm)
    #block(
      fill: light,
      stroke: 0.5pt + navy,
      radius: 2pt,
      width: 85%,
      inset: 12pt,
    )[
      #align(center)[
        #text(font: sans-font, size: 11pt)[
          *Curso ECO-490 / ECON-540* \
          Profesionales y posgrado aplicado (data / ML / product / analytics) \
          Modalidad online/asíncrona · 32 sesiones · 32 capítulos \
          Edición 2026
        ]
      ]
    ]
    #v(0.8cm)
    #block(
      fill: white,
      stroke: 0.5pt + crimson,
      radius: 2pt,
      width: 85%,
      inset: 10pt,
    )[
      #text(font: sans-font, size: 9.5pt)[
        *Promesa.* Deja de priorizar con scores que confunden correlación con impacto.
        Estima efectos, documenta supuestos y despliega en Hugging Face — con monitoreo
        de cuándo el efecto deja de ser válido.
      ]
    ]
    #v(1fr)
    #text(font: sans-font, fill: gray, size: 9pt)[
      Monorepo del curso: labs L01–L28 · Serie A (casos) · Serie B (HF) · benchmark de datos \
      Stack: #code[econml] / #code[sklearn] · #code[FastAPI] · #code[Gradio] · #code[huggingface_hub] · #code[Docker]
    ]
  ]
]

// ============================================================
// 11. Heading helpers para secciones de frontmatter no numeradas
// ============================================================
#let frontmatter-section(title) = heading(level: 2, title)
#let frontmatter-subsection(title) = heading(level: 3, title)
