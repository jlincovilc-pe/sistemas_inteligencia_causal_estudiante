// Colofón / Página de derechos
#import "../template/template.typ": *

#page(margin: (top: 6cm, bottom: 4cm, left: 3cm, right: 3cm), numbering: none)[
  #v(1fr)
  #align(center)[
    #block(width: 80%, inset: 20pt, stroke: 0.5pt + gray.lighten(40%), radius: 3pt)[
      #align(center)[
        #text(font: sans-font, size: 14pt, weight: "bold", fill: navy)[
          IA Causal en Producción
        ]
        #v(0.3em)
        #text(font: sans-font, size: 11pt, fill: gray)[
          Monografía del Curso ECO-490 / ECON-540
        ]
        #v(0.3em)
        #text(font: sans-font, size: 10pt, fill: gray)[
          Edición 2026
        ]
      ]
    ]
  ]
  #v(2cm)
  #align(center)[
    #text(font: sans-font, size: 10pt, fill: gray)[
      © 2026 Curso ECO-490 / ECON-540 \
      Todos los derechos reservados. \
      \
      Primera edición, 2026. \
      \
      Compuesto con Typst 0.15.1. \
      Tipografía: New Computer Modern (serif), Helvetica Neue (sans-serif), DejaVu Sans Mono (monoespaciada). \
      \
      Implementación de referencia en el monorepo del curso (#code[data_benchmark_causal], Serie A/B). \
      Stack Python: #code[econml], #code[DoubleML], #code[causalml], #code[dowhy], #code[PyTorch]. \
      \
      Esta monografía es material de referencia para uso docente. \
      La reproducción total o parcial requiere citación adecuada.
    ]
  ]
  #v(1fr)
]
