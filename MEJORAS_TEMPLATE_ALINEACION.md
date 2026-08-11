# Mejoras de Alineación en template.typ

**Fecha:** 2026-08-10
**Archivo modificado:** `02_monografia/monografia-ml-causal-typst/template/template.typ`
**Motivación:** Corregir la alineación centrada no deseada en teoremas, definiciones, algoritmos y listados de código

---

## Problema Identificado

Los bloques de teoremas/definiciones, algoritmos y listados de código aparecían **centrados** en vez de alineados a la izquierda porque están envueltos en `#figure()`, que por defecto en Typst aplica `align: center` a todo su contenido.

Esto afectaba específicamente a:
- Títulos de teoremas, definiciones, proposiciones, etc. (`Definición 1.1 (Estimandos causales)`)
- Títulos y contenido de algoritmos
- Títulos y bloques de código/listados

---

## Solución Implementada

Forzar `set align(left)` dentro de cada figura afectada y mejorar la tipografía de los nombres/títulos.

---

## Cambios Aplicados

### 1. Función `_theorem-block` (Sección 6, líneas ~349-382)

**Antes:**
```typst
#let _theorem-block(kind-name, kind-color, body, name: none) = {
  theorem-number.step()
  figure(
    kind: "theorem-block",
    numbering: "1.1",
    supplement: kind-name,
    {
      set par(leading: 0.6em)
      block(width: 100%, spacing: 1em, breakable: true)[
        #block(width: 100%)[
          #box(
            fill: kind-color,
            inset: (x: 6pt, y: 2pt),
            radius: 2pt,
          )[
            #text(font: sans-font, fill: white, weight: "bold", size: 10pt)[...]
          ]
          #if name != none [
            #h(4pt)
            #text(style: "italic", weight: "bold")[(#name)]
          ]
        ]
        ...
      ]
    }
  )
}
```

**Después:**
```typst
#let _theorem-block(kind-name, kind-color, body, name: none) = {
  theorem-number.step()
  figure(
    kind: "theorem-block",
    numbering: "1.1",
    supplement: kind-name,
    {
      // ✅ NUEVO: Forzar alineación a la izquierda
      set align(left)
      set par(leading: 0.6em)
      
      block(width: 100%, spacing: 1em, breakable: true)[
        #block(width: 100%)[
          #box(
            fill: kind-color,
            inset: (x: 6pt, y: 3pt),  // ✅ CAMBIADO: y de 2pt → 3pt
            radius: 2pt,
          )[
            #text(font: sans-font, fill: white, weight: "bold", size: 10.5pt)[  // ✅ CAMBIADO: 10pt → 10.5pt
              #kind-name #context {
                let ch = counter("chapter").at(here()).first()
                let th = theorem-number.at(here()).first()
                numbering("1.1", ch, th)
              }
            ]
          ]
          #if name != none [
            #h(6pt)  // ✅ CAMBIADO: 4pt → 6pt
            // ✅ NUEVO: Tipografía mejorada para el nombre
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
```

**Mejoras:**
- ✅ Alineación a la izquierda forzada
- ✅ Tamaño del badge aumentado: 10pt → 10.5pt
- ✅ Padding vertical del badge: 2pt → 3pt
- ✅ Nombre del teorema con tamaño 11.5pt (antes heredaba el tamaño por defecto)
- ✅ Color navy.darken(20%) para mejor legibilidad
- ✅ Fuente sans-serif explícita para coherencia
- ✅ Espaciado horizontal aumentado: 4pt → 6pt

---

### 2. Bloques de Código (Sección 3, líneas ~261-272)

**Antes:**
```typst
  // Raw code blocks: styling only
  show raw.where(block: true): it => {
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
```

**Después:**
```typst
  // Bloques de código (raw)
  show raw.where(block: true): it => {
    set align(left)  // ✅ NUEVO: Alineación forzada
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

  // ✅ NUEVO: Alineación para figuras tipo código/listado
  show figure.where(kind: raw): set figure(
    align: left,
  )
```

**Mejoras:**
- ✅ Alineación a la izquierda dentro del bloque de código
- ✅ Regla adicional para alinear figuras `kind: raw` a la izquierda
- ✅ Comentario actualizado a español

---

### 3. Función `algorithm` (Sección 7, líneas ~462-484)

**Antes:**
```typst
#let algorithm(title, body) = figure(
  kind: "algorithm",
  caption: title,
  supplement: [Algoritmo],
  numbering: "1.",
  placement: top,
  block(
    stroke: (top: 0.8pt + black, bottom: 0.8pt + black),
    width: 100%,
    spacing: 1em,
  )[
    #block(
      stroke: (bottom: 0.4pt + black),
      inset: (top: 4pt, bottom: 4pt, left: 0pt, right: 0pt),
    )[
      #text(font: sans-font, weight: "bold", size: 10pt)[Algoritmo]
    ]
    #v(2pt)
    #set text(size: 10pt)
    #set par(leading: 0.5em, first-line-indent: 0em)
    #block(inset: (left: 0pt, right: 0pt))[#body]
  ]
)
```

**Después:**
```typst
#let algorithm(title, body) = figure(
  kind: "algorithm",
  caption: title,
  supplement: [Algoritmo],
  numbering: "1.",
  placement: top,
  {  // ✅ CAMBIADO: Usar bloque con contexto {...} en vez de block() directo
    // ✅ NUEVO: Forzar alineación a la izquierda
    set align(left)
    block(
      stroke: (top: 0.8pt + black, bottom: 0.8pt + black),
      width: 100%,
      spacing: 1em,
    )[
      #block(
        stroke: (bottom: 0.4pt + black),
        inset: (top: 4pt, bottom: 4pt, left: 0pt, right: 0pt),
        width: 100%,  // ✅ NUEVO: Ancho explícito
      )[
        #text(font: sans-font, weight: "bold", size: 11pt)[Algoritmo]  // ✅ CAMBIADO: 10pt → 11pt
      ]
      #v(2pt)
      #set text(size: 10pt)
      #set par(leading: 0.5em, first-line-indent: 0em)
      #block(inset: (left: 0pt, right: 0pt))[#body]
    ]
  }
)
```

**Mejoras:**
- ✅ Alineación a la izquierda forzada
- ✅ Tamaño del título aumentado: 10pt → 11pt
- ✅ Uso de bloque con contexto `{...}` para aplicar `set align(left)`
- ✅ Ancho explícito `100%` en el bloque interno para coherencia

---

## Resultado

### Compilación
```bash
✅ Compilación exitosa
📄 monografia.pdf generado
📊 Tamaño: ~5.7 MB
📄 Páginas: 354
⚠️  Advertencias: Solo fuentes (esperadas y documentadas)
```

### Impacto Visual

**Antes:**
- Títulos de teoremas/definiciones centrados (desalineados del margen)
- Nombres de teoremas en tamaño pequeño heredado
- Algoritmos con cabecera centrada
- Listados de código con título centrado

**Después:**
- ✅ Todos los títulos alineados al margen izquierdo
- ✅ Nombres de teoremas/definiciones con tipografía mejorada (11.5pt, color navy.darken(20%))
- ✅ Títulos de algoritmos más visibles (11pt)
- ✅ Badges de teoremas más legibles (10.5pt)
- ✅ Espaciado horizontal mejorado
- ✅ Coherencia tipográfica completa

---

## Archivos Afectados

- ✅ `template/template.typ` (3 secciones modificadas)
- ✅ `monografia.pdf` (recompilado)
- ✅ `02_monografia/monografia_IA_Causal_en_Produccion.pdf` (copia actualizada)

---

## Verificación

Para verificar los cambios:

1. **Compilar el libro:**
   ```bash
   cd 02_monografia/monografia-ml-causal-typst
   typst compile main.typ monografia.pdf
   ```

2. **Revisar cualquier capítulo con teoremas** (p. ej. Cap. 3, 10, 11):
   - Los títulos deben estar alineados al margen izquierdo
   - Los nombres de teoremas deben verse en 11.5pt, negrita cursiva, color navy oscuro

3. **Revisar capítulos con algoritmos** (p. ej. Cap. 10, 11, 13):
   - La palabra "Algoritmo" debe estar alineada a la izquierda en tamaño 11pt

4. **Revisar listados de código** (cualquier capítulo):
   - El título "Listado X.Y" debe estar alineado a la izquierda

---

## Reversión (si necesaria)

Para revertir los cambios, usar:
```bash
git checkout HEAD -- 02_monografia/monografia-ml-causal-typst/template/template.typ
```

O restaurar desde el commit anterior a esta modificación.

---

## Referencias

- **Typst Documentation:** https://typst.app/docs/
- **Issue de alineación de figuras:** Comportamiento por defecto de `figure()` en Typst
- **Auditoría de contenido:** `auditoria_contenido.md` (generada 2026-08-10)
