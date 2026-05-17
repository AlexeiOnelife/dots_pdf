# Per-album-type spread spec

Source PDFs render at a single-page trim of **203 × 254 mm**. Two-page templates render
at **406 × 254 mm** (203 × 2). Bleed (3 mm) is implied but not drawn on the artboards.
Body pages share this trim — confirmed by visual match with the typographic grid.

Conventions used below:
- All coordinates are in **mm**, measured from the top-left of the indicated page
  (or from the top-left of the spread for two-page art where the spec callouts use
  spread coordinates, e.g. dedication arcs).
- `x, y, w, h` = top-left x, top-left y, width, height. Photo slots use rounded
  rectangles unless noted as circles.
- "P22 Mackinac" and "Inter" are the two typefaces. Body sizes are constant unless
  called out: TITULO P22 Mackinac medium, body Inter Book 9pt / 10.8pt LH.
- Header/footer common to nearly every spread:
  - Top-left `Nº página`, top-center `{NombreDelAlbum}` (left page) or context
    label (right page), top-right `Nº página` — Inter Semibold 7pt / 8.4pt.
  - Bottom-center "Dots. Memories" wordmark — Inter Semibold 7pt / 8.4pt.
- Context label in top-center of right pages varies per type:
  - boda → `{Protagonistas}`
  - parejas → `{tiempojuntos}`
  - hijos → `{Protagonistas}`
  - individuales → `{Año}`
  - otros → `{Año}`

---

## boda (wedding) — `boda.informacion.pdf` (5 pages)

The 5 pages decompose as 2 spreads + 1 single back-page:
- p.1 = first single page (recto cover-facing intro, 203 mm wide)
- p.2 = spread A (406 mm) — the "(01) Busca un lugar tranquilo / (02) Más allá del papel" instructions spread
- p.3 = spread B (406 mm) — "Antes de empezar el viaje" + decorative photo collage (collage is on the left half, text on right)
- p.4 = spread C (406×254, 4-page-wide artboard) — "Boda de Nombre&Nombre" title spread (with QR + radial photo halo)
- p.5 = final single page (verso) — closing message page

### Initial spread group (p.1 → p.4)

#### p.1 — intro single page (recto)
- Photo slot: 1 rounded-rect, centered horizontally, **w 48 mm × h 60 mm**, corner radius ~6 mm. Vertical position is `AUTO`-centered; the bottom edge sits 5 mm above the title.
- Text fields (centered, below the photo):
  - TITLE: "Bienvenido/a a tu viaje al pasado" — P22 Mackinac medium 18pt / 21pt, not editable, fixed 2 lines.
  - BODY (4 lines): "Prepárate para revivir uno de los días más bonitos de tu vida. / Este no es un álbum cualquiera: es una puerta que se abre hacia esos momentos que parecían efímeros, pero que quedaron guardados para siempre. / Antes de empezar, sigue los pasos que encontrarás a continuación. Lee despacio, sin prisa y siente cada momento de nuevo." — Inter Book 9pt / 10.8pt.
- Vertical block height between photo and top of footer area: ~86 mm.

#### p.2 — instructions spread (10 photo slots, 5+5)
Two pages of identical grid. On each page:
- 5 photo slots in a single row, each rounded-rect **w 35 mm × h 46 mm**, top y = 36 mm.
- Horizontal placement: row spans the full live area. Adjacent slots touch (gap appears to be 0 mm based on the render — visual gutter is the rounded-corner radius only).
- Below the row: section number "(01)" / "(02)" at offset y = 33 mm below the row (from top of section number block), then 7.5 mm gap, then TITLE, then 5 mm gap, then body.
- Left page (p.2L):
  - Header context label: `{NombreDelAlbum}`
  - TITLE: "Busca un lugar tranquilo" — P22 Mackinac medium 23pt / 27.6pt, centered, not editable
  - BODY width 93 mm; outer text frame width 141 mm
- Right page (p.2R):
  - Header context label: `{Protagonistas}`
  - TITLE: "Más allá del papel"
  - BODY (same metrics as left)
  - QR card: oval frame, **w 25.841 mm × h 43.127 mm**, with QR inside (caption "Escanea el QR para volver a ver el álbum y los vídeos", P22 Mackinac book 8pt / 9.6pt). Border stroke 3 mm of oval edge to QR; 4 mm padding between QR and oval cap.

#### p.3 — "Antes de empezar el viaje" spread (decorative cluster + text)
- Left page: empty (header only).
- Right page: TITLE "Antes de empezar / el viaje" (two lines; "el viaje" in medium italic), then BODY. Specs callout shows TITLE at Antes-de-empezar→medium, el-viaje→medium italic, font-size 27pt / 31pt; the spec text uses larger sizes here than other pages — but the inline callout says **23pt/27.6pt** medium with italic "el viaje" line. Body 95 mm wide, baseline 45 mm above page bottom.
- Decorative photo cluster (top-right of the right page, on the central seam): 7 rounded-rect photos of varying sizes with opacity gradients (decorative, **not user-replaceable** — these are the "wedding" signature element). All coordinates given as `X, Y` from the spread top-left of the right page:
  | # | size (w × h, mm)    | x       | y        | Notes |
  |---|---------------------|---------|----------|-------|
  | 1 | 27.517 × 33.867     | (top, near binding) | ~5 mm from top | opacity gradient bottom→top 100%→10% |
  | 2 | 4.95 × 5.844        | adjacent | —        | 1.764 mm edge feather |
  | 3 | 20.324 × 24.694     | —       | —        | — |
  | 4 | 12.848 × 15.167     | —       | —        | — |
  | 5 | 13.751 × 16.234     | —       | —        | opacity top→bottom 100%→30% starting at y+3.4 mm |
  | 6 | 8.967 × 10.586      | —       | —        | opacity top→bottom 100%→30% starting at y+1.6 mm |
  | 7 | 7.754 × 9.154       | —       | —        | opacity top→bottom 100%→0% |
  - Reference dimensions used for layout (from spec callouts): top inset 26 mm; cluster extends ~92 mm wide × ~84 mm tall along the right-page binding edge.
  - Gaps between cluster elements: 3.492, 3.038, 2.884, 11.534, 16.844, 5.292 mm (from spec callouts).
- Distances along the right edge of the right page (per spec):
  - 80.842, 82.566, 84.511, 85.986, 92.278, 92.626, 102.901, 103.772, 111.675 mm (callout for x-positions of cluster slots, measured from the page right edge).

#### p.4 — title spread "Boda de Nombre&Nombre" (4-page wide artboard, decorative halo)
- The PDF artboard for this spread is actually **2 spreads wide** (810×254 mm or similar). The actual book spread is the central 2 pages.
- Left half of artboard / left page: TITLE "Boda de" / "Nombre&Nombre" — P22 Mackinac medium 23pt / 27.6pt, ranged left, x = 19 mm from page left, y = 43 mm from top. Below it, 5 mm gap, SUBTITLE `{DiadeMesdeAñodeFechaDeInicio}` — P22 Mackinac book 9pt / 10.8pt.
- Right page: decorative **radial halo of ~12 tilted rounded-rect photos** arcing around the page center; the spec callout marks the photo at `x=37.477, y=50.388` mm (one anchor). The other ~11 slots are positioned along the arc — exact per-slot positions are not annotated in the artboard (approx from render of p.4). They are **decorative**, no user-replaceable slot count given.
- Two QR cards at bottom-center (one per page, straddling the gutter):
  - Left QR card: oval **w 25.841 × h 43.127 mm**, caption "Vuestro álbum en digital" (P22 Mackinac book 8pt / 9.6pt), 27 mm from gutter on each side, bottom-aligned 14 mm from page bottom.
  - Right QR card: same dimensions, caption "Escanea el QR para volver a ver el álbum y los vídeos".
  - 6 mm vertical gap between QR cards.

### Final single page (p.5)
- Photo slot (centered): rounded-rect **w 66 mm × h 86 mm**.
- Below photo, 5 mm gap: TITLE "Que la vida siga reencontrándoos, una y otra vez" — P22 Mackinac medium **12pt / 14pt**, 2 lines, centered.
- Footer: standard "Dots. Memories" + page number.

---

## parejas (couples) — `parejas.informacion.pdf` (10 pages, full spec)

This is the canonical/most complete template. The five-page structure that boda
condenses into is here expanded across 10 pages: 1 cover-design page +
1 cover-overlay/title page + 1 spine-title spread + 1 decorative-circle final-page
template + 1 dedication-single + 1 dedication-spread + 1 instructions-spread +
1 "Antes de empezar" spread + 1 photo-circle title spread + 1 closing single page.

Per-page breakdown:

### p.1 — Cover front (single page, 203 mm wide)
- Background: 14 decorative blue circles bleeding off all 4 edges, with diameters
  16, 28, 47 mm in three "tiers". All circles have a **1.764 mm Gaussian edge fade**.
  Specific per-circle anchors (from p.4 spec twin — same layout): see p.4 table.
- Center: TITLE "DOTBOOK" (small caps, Inter Book 9pt) then `{NombreDelAlbum}`
  (P22 Mackinac medium 23pt / 27.6pt), then 5 mm gap, then date line
  `{DiadeMesdeAñodeFechaDeInicio} | {DiadeMesdeAñodeFechaDeInicio}` (Inter Book 9pt / 10.8pt).
- "DOTBOOK" eyebrow is non-personalizable; title is single-line, no word-break.

### p.2 — Cover/title interior page (single, mirror of p.1 with no background circles)
- Same text layout as p.1 but on a clean white background (the circles only appear
  on the actual cover, not on the inside title page). Layout-AUTO centered both axes.

### p.3 — Spine/oversize title spread (single page rendered 203 mm wide, callout shows 120 mm title width)
- Three big lines of `{NombreDelAlbum}` text spanning ~120 mm centered vertically (AUTO).
- Date line beneath.
- No photo slots.

### p.4 — Final-page circle template / cover background reference (single page, full circle catalog)
This page is a spec sheet for the cover's decorative circles. Every circle is listed
with `(x, y)` of its top-left and diameter:

| # | diameter | x (mm)  | y (mm)  |
|---|----------|---------|---------|
| 1 | 47 mm    | 8       | 43      |
| 2 | 47 mm    | 141     | 4       |
| 3 | 47 mm    | 210     | 33      |
| 4 | 47 mm    | -13     | 169     |  (bleeds off left)
| 5 | 47 mm    | 200     | 240     |  (bleeds off bottom-right)
| 6 | 28 mm    | 36      | 109     |
| 7 | 28 mm    | 176     | 91      |
| 8 | 28 mm    | 49      | 193     |
| 9 | 28 mm    | 138     | 225     |
| 10| 16 mm    | 70      | 48      |
| 11| 16 mm    | 124     | 68      |
| 12| 16 mm    | 170     | 140     |
| 13| 16 mm    | 109     | 181     |
| 14| 16 mm    | 50      | 273     |  (bleeds off bottom)

All circles: 1.764 mm Gaussian-blur edge fade, color a light blue (~#CDE7F2 from render).

### p.5 — Dedication single page (203 mm wide, right-page placement)
- TITLE "Nuestro mensaje especial o {título dedicatoria}" — P22 Mackinac medium 23pt / 27.6pt, 2 lines, centered, **max 50 chars**.
- 6.5 mm gap.
- BODY block — Inter Book 9pt / 10.8pt, centered text, **width 102 mm**, **max 1000 chars / 32 lines**, no word-breaks, no widow lines (min 3 words on a line). Default placeholder copy: long love letter shown verbatim in the PDF.
- 8 mm below body: SIGNATURE — Biro Script Plus Regular 12pt / 14.4pt, rotated **2°**, e.g. "Blanqui" / `{nombre firma}`.
- Block padding: 86 mm bottom margin (AUTO above + AUTO below).

### p.6 — Dedication-spread variant (two stacked single-page dedication blocks for review)
This page is a reference showing two dedication blocks tiled vertically with
**width 137 mm** (wider, full-page) and a max of 16 lines. Layout differences vs p.5:
- 32 mm top margin to TITLE.
- 15 mm gap between the two stacked variants.
- Body width 137 mm (full-page version, used when dedication needs more horizontal room).
- Same max 16 lines.

### p.7 — Instructions spread (mirror of boda p.2)
Same geometry as boda p.2:
- 5 photo slots per page, **35 × 46 mm**, top y = 36 mm, full-row.
- Section number "(01)" / "(02)", 46 mm below row, then 7.5 mm gap, then TITLE.
- Text frames: title width is the printed line width; body 93 mm, outer 141 mm.
- Right-page header context label: `{tiempojuntos}`.
- TITLEs (couples wording, plural "vosotros"):
  - Left: "Buscad vuestro momento"
  - Right: "Escuchad vuestra historia"
- Body copy is plural-voice ("Encontrad...", "Sentaos...").

### p.8 — "Antes de empezar el viaje" spread
- Left page: TITLE "Antes de empezar / el viaje" — P22 Mackinac, line 1 medium, line 2 medium italic, **27pt / 31pt**, centered. Below: BODY (5+ lines, plural voice), max width 95 mm, baseline AUTO-centered vertically.
- Right page: solid background light-blue rectangle with transparency 100%→0% gradient (top-to-bottom), `w 134 mm × h ?`. Inside, near bottom: small caption `{NOMBRE PROTAS}` (Inter Book 9pt) and TITLE "Pasad la página para vivir la experiencia." — P22 Mackinac medium **15pt / 18pt**, width 65 mm.

### p.9 — "Un año lleno de recuerdos" title spread (4-page-wide artboard with photo-circle arc)
- Left page: TITLE "Un año lleno de recuerdos" — P22 Mackinac medium 23pt / 27.6pt, top y = 43 mm, x = 19 mm, 5 mm gap, SUBTITLE `{DiadeMesdeAñodeFechaDeInicio} | {DiadeMesdeAñodeFechaDeInicio}` (P22 Mackinac book 9pt / 10.8pt).
- Right pages: arc of 10 photo circles symmetrically straddling the gutter. Photo slot coordinates (top-left) and diameter ~44.45 mm (largest, callout):

  | side  | (x, y) mm           |
  |-------|---------------------|
  | left  | 29.59,  273.28      |
  | right | 376.17, 273.28      |
  | left  | 45.09,  224.02      |
  | right | 360.66, 224.02      |
  | left  | 77.97,  180.93      |
  | right | 327.79, 180.93      |
  | left  | 120.96, 150.11      |
  | right | 284.79, 150.11      |
  | left  | 171.04, 134.01      |
  | right | 234.72, 134.01      |

  Circle diameter 44.45 mm (only labeled on bottom-most circle; others appear same in render — approx from render of p.9).
- Two QR cards centered at gutter bottom (same oval geometry as boda p.4): captions "Vuestro álbum en digital" / "Todos tus hitos en un lugar"
  - Caption font: P22 Mackinac bold 8pt / 9pt, color **#9E9E9D**.
  - Top of QR captions: 20 mm above bottom of gutter; 27 mm horizontal distance from each QR center to the gutter.

### p.10 — Closing single page (verso back)
- Photo slot rounded-rect **66 × 86 mm**, AUTO-centered horizontally and vertically.
- 5 mm below: TITLE `{TítuloDelAlbum}` — P22 Mackinac medium **20pt / 24pt**.
- 5 mm below: SUBTITLE "Vivido con mucho amor por: / Nombre y Nombre" — P22 Mackinac book 9pt / 10.8pt, not editable label + 2-line names.
- Footer: standard.

---

## hijos (children) — `hijos.informacion.pdf` (10 pages)

Identical structure to **parejas** — same page count (10), same per-page layout,
same coordinates. Differences are wording / variable names:

| element                     | parejas                            | hijos                              |
|-----------------------------|------------------------------------|------------------------------------|
| Cover eyebrow               | `DOTBOOK`                          | `DOTBOOK DE {NOMBREHIJO}`          |
| Right-page header context   | `{tiempojuntos}`                   | `{Protagonistas}`                  |
| Dedication signature        | `Blanqui` (sample handwritten)     | `{nombre firma}`                   |
| p.7 left TITLE              | "Buscad vuestro momento"           | "Busca un lugar tranquilo"         |
| p.7 right TITLE             | "Escuchad vuestra historia"        | "Escucha los momentos especiales"  |
| p.7 voice                   | plural (vosotros)                  | singular (tú) — addressing the child |
| p.8 left TITLE-body voice   | plural                             | singular                           |
| p.8 right small label       | `{NOMBRE PROTAS}`                  | `{NOMBREHIJO}`                     |
| p.9 right QR caption        | "Vuestro álbum en digital" / "Todos tus hitos en un lugar" | "Tu album en digital" / "Todos tus hitos en un lugar" |
| p.10 SUBTITLE label         | "Vivido con mucho amor por:"       | "Creado con mucho amor por:"       |
| p.10 names                  | "Nombre y Nombre"                  | `{NombreFirma} y {NombreFirma}`    |

All photo-slot dimensions and coordinates are identical to parejas.

---

## individuales (individuals) — `indiviualesinformacion.pdf` (8 pages)

Compressed structure (no cover-circle page, no spine-title page, no dedication-spread variant page):

### p.1 — Cover/title single page (203 mm)
- **Centered photo slot** (this is the distinguishing feature) — rounded-rect.
  - Inner photo: **w 53 mm × h 66 mm**
  - Outer frame (slot bounding box / mat): **w 59 mm × h 73 mm**
  - Slot positioned ~AUTO-centered both axes.
- Below slot, 5 mm gap:
  - TITLE `{NombreDelAlbum}` — P22 Mackinac medium 23pt / 27.6pt, centered, single-line, max chars = portada-determined, no word-break.
- 5 mm gap, DATE `{DiadeMesdeAñodeFechaDeInicio} | {DiadeMesdeAñodeFechaDeInicio}` — Inter Book 9pt / 10.8pt.
- Top-right header: `{Año}` (this is the per-type identifier — instead of date/protag like other types).
- No decorative circles. Plain background.

### p.2 — Dedication single page
Identical to parejas p.5 (102 mm body, 86 mm bottom margin, signature 2° rotated, max 1000 chars / 32 lines, max title 50 chars).

### p.3 — Dedication-spread variant reference
Identical to parejas p.6 (137 mm body, 16-line max).

### p.4 — Instructions spread
Identical structure to parejas p.7 / boda p.2:
- 5+5 photo slots, **35 × 46 mm**, row top y = 36 mm.
- Right-page header context: `{Año}`.
- TITLEs (singular voice):
  - Left: "Encuentra tu momento"
  - Right: "Escucha la historia"

### p.5 — "Antes de empezar el viaje" spread (with photo-collage on right)
- Left page: same as parejas p.8 left (TITLE 27pt / 31pt, body 95 mm, singular voice).
- Right page: **distinctive design** — a collage of **tilted polaroid-style** photo cards layered around a center, the "Pasad la página para vivir la experiencia" caption sits inside the collage. The collage is a transition-tease to p.6.
  - Caption text frame: width 65 mm, label `{NOMBREHIJO}` (despite being individuales template, the variable token is `{NOMBREHIJO}` — likely an authoring leftover, see Open Questions).
  - Caption TITLE: P22 Mackinac medium 15pt / 18pt.

### p.6 — Polaroid collage spread (distinctive of individuales/otros)
8 tilted photo slots arranged in 4 facing pairs across the spread. Each is a polaroid
(white border around an inner photo). Dimensions and rotations:

| slot | inner photo (mm) | full polaroid (mm) | rotation | left/right page | x (top-left, approx, from render) | y |
|------|------------------|--------------------|----------|-----------------|------------------------------------|---|
| L-top-near-gutter   | 97 × 122 | 108 × 134 | **−2.5°** | left  | ~spec callout `21 mm` from page left edge | top y 18 mm |
| L-bottom            | 97 × 122 | 108 × 134 | **+8°**   | left  | x ~0 mm (bleeds off) | bottom edge of page (21 mm from bottom) |
| Center-top          | 97 × 122 | 108 × 134 | **+4°**   | crosses gutter | spread x ~midpoint, top y 18 mm | — |
| Center-bottom       | 97 × 122 | 108 × 134 | **−2.5°** | crosses gutter | spread x ~midpoint, bottom y at 85 mm from bottom | — |
| R-top               | 97 × 122 | 108 × 134 | **−3.5°** | right | 107 mm right-edge offset, 9 mm top inset, 48.5 mm from gutter | top y 69 mm |
| R-bottom            | 97 × 122 | 108 × 134 | unspecified | right | x ~right-edge, y mid | — |
| (3 more)            | 97 × 122 | 108 × 134 | mixed     | varies | approx from render of p.6 | — |

Spec callouts confirm: inner photo 97×122 mm, outer polaroid 108×134 mm (=> 5.5 mm
border each side top/left/right, and 6 mm bottom — classic polaroid). Rotations
specified: 4°, −3.5°, −2.5° (used twice), 8°. **All rotation centers: width & padding
calculated as if NOT rotated.**

Header-only on this page (no body text). No QR.

### p.7 — "Un año lleno de recuerdos" title spread (with photo-circle arc + QRs)
Identical to parejas/hijos p.9:
- Same 10 photo-circle positions, same diameters.
- QR captions: "Tu album en digital" / "Todos tus hitos en un lugar" (singular voice).
- Right-page header: `{Año}`.

### p.8 — Closing single page (verso back)
Same as parejas p.10 / hijos p.10:
- Rounded-rect photo slot 66 × 86 mm, AUTO-centered.
- TITLE `{TítuloDelAlbum}` (P22 Mackinac medium 20pt / 24pt).
- SUBTITLE `{Nombre}` (single name, P22 Mackinac book 9pt / 10.8pt).

---

## otros (other) — `otros.informacion.pdf` (8 pages)

**Identical to individuales**, page-for-page, coordinate-for-coordinate. Wording
differences:

| element                     | individuales                       | otros                              |
|-----------------------------|------------------------------------|------------------------------------|
| p.4 left TITLE              | "Encuentra tu momento" (sing.)     | "Encontrad vuestro momento" (pl.)  |
| p.4 right TITLE             | "Escucha la historia"              | "Escuchad la historia"             |
| p.4 voice                   | singular                           | plural                             |
| p.5 left body voice         | singular ("Cierra los ojos…")      | (same singular line in source, but right-side instructions plural) — slightly mixed |
| p.6 collage extra spec      | —                                  | adds "Pérdida de opacidad de derecha a izquierda desde 100% a 15%" gradient overlay across the left-page bottom polaroid |

p.6 has one additional design note in otros: a **right-to-left opacity falloff from
100% → 15%** applied across a polaroid (likely the bottom-left card). Otherwise the
polaroid grid is identical to individuales p.6.

p.5 right-side variable token is still `{NOMBREHIJO}` here too (same leftover).

---

## Comparison table

| Type          | Pages | Cover style                                  | Initial-spread distinctive | Final-spread distinctive                                    | Right-page header label  | Voice          |
|---------------|-------|----------------------------------------------|----------------------------|-------------------------------------------------------------|---------------------------|----------------|
| boda          | 5     | Small 48×60 photo + "Bienvenido/a" copy      | Wedding-photo halo / arc (radial cluster of ~12 tilted slots around right page; decorative cluster on "Antes de empezar") | Single photo 66×86 + "Que la vida siga reencontrándoos" 12pt | `{Protagonistas}`         | tú (singular)  |
| parejas       | 10    | Light-blue dotted circles bleeding off edges | Photo-circle arc of 10 slots on "Un año lleno de recuerdos" + 2 QR ovals at gutter | 66×86 photo + `{TítuloDelAlbum}` 20pt + "Vivido con mucho amor por: Nombre y Nombre" | `{tiempojuntos}`          | vosotros (pl.) |
| hijos         | 10    | Same circles, eyebrow `DOTBOOK DE {NOMBREHIJO}` | Same photo-circle arc; child-addressed copy   | Same 66×86 photo + "Creado con mucho amor por:"             | `{Protagonistas}`         | tú (child)     |
| individuales  | 8     | Centered single photo 53×66 (mat 59×73) on plain ground | Tilted polaroid collage (8 slots, 108×134 outer / 97×122 inner, rotations ±2.5°/4°/8°/−3.5°) | Same 66×86 photo + `{Nombre}` only                          | `{Año}`                   | tú (singular)  |
| otros         | 8     | Same as individuales                         | Same polaroid collage + extra R→L opacity gradient | Same as individuales                                        | `{Año}`                   | vosotros (pl.) |

### Shared elements (all types)
- Trim: **203 × 254 mm** per page; bleed assumed 3 mm.
- Fonts: P22 Mackinac (medium / book / italic), Inter (Book / Semibold / Light), Biro Script Plus (Regular, for signature, 2° rotation).
- Dedication block (when present): TITLE max 50 chars, body 102 mm wide, max 1000 chars / 32 lines, signature rotated 2°.
- Dedication-spread wide variant (when present): body width 137 mm, max 16 lines.
- "Instructions" spread photo grid: 5+5 slots @ **35 × 46 mm**, row top y = 36 mm.
- "Un año lleno de recuerdos" spread photo arc: 10 slots, diameter ~44.45 mm, fixed coordinates listed under parejas p.9.
- Final closing page (when present): 66 × 86 mm photo slot, centered.
- QR ovals: **25.841 × 43.127 mm**, used in pairs straddling the gutter on art pages.
- Header trio (Nº página / context / Nº página) is uniform.
- All decorative circles & cluster photos use **1.764 mm Gaussian-blur edge feather**.

---

## Open questions

- **Bleed**: assumed 3 mm (confirmed only by boda p.3 callout "3 mm"). Should be validated against the body-page templates.
- **Trim confirmation**: 203 × 254 mm inferred — body page templates should be cross-checked (caller stated "should be 203 × 254 mm + 3 mm bleed"; the artboards match this.)
- **boda page 4 ("Boda de Nombre&Nombre")**: only one slot in the radial halo has explicit `(x, y)` (`x = 37.477, y = 50.388 mm`). The other ~11 slots in the arc lack callouts — coordinates would need extraction from the source AI/Figma file or measurement from the render.
- **individuales/otros p.5 right side**: the `{NOMBREHIJO}` token is used in the "Pasad la página" caption — likely an authoring leftover from hijos; should this be renamed `{NOMBRE}` / `{Protagonista}` for these types?
- **individuales/otros p.6 polaroid coordinates**: spec gives sizes and rotations but only partial per-slot anchors (`21 mm`, `18 mm`, `48.5 mm`, `69 mm`, `82 mm`, `85 mm`, `91 mm`, `107 mm`, `9 mm`). The 8 slot top-left coordinates need to be assigned to specific slots based on render measurement.
- **boda p.3 cluster**: 7 photo sizes are given but per-slot top-left coordinates are not — only relative gap callouts and edge offsets. Reconstruction requires either the source design file or pixel-measured positions from the render.
- **boda title "Antes de empezar el viaje"**: spec lists this at 23pt/27.6pt in the boda PDF but at 27pt/31pt in parejas/hijos/individuales/otros — confirm whether boda intentionally uses smaller.
- **Photo-circle arc on "Un año lleno de recuerdos"**: diameter labelled 44.45 mm on the bottom-most circle only; render suggests larger circles (~50–60 mm) in the middle of the arc. Need to confirm whether all 10 are 44.45 mm or whether the arc tapers.
- **Voice mismatch in otros**: p.5 left body is singular while p.4 is plural; verify whether the otros copy is intentionally mixed or an authoring inconsistency.
