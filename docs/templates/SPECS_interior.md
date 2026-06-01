# Interior-page spec (Dotbook body)

Derived from `Informacion.interiores.dotbook.2 (1).pdf` (73 pages, source
file is a 1167.87 × 737.008 pt artboard = 412 × 260 mm = two 203 × 254 mm
pages + 3 mm bleed all around).

Units are millimeters.

> **Task 3 update (`general-body-layouts-fidelity`)**: the positioning
> model is now **outer-edge aligned** — every photo block sits 8 mm
> from the OUTER (non-binding) trim edge of its page. On a left page
> the outer edge is the LEFT edge; on a right page, the RIGHT edge.
> The `DotsLayoutSolver` resolves this per-page via `isLeftPage`. The
> previous "AUTO = page-centered" convention only matched the printed
> design for L3.A by coincidence (its block width 186.81 mm leaves an
> ≈8 mm side margin when centered).

---

## Page geometry

| Property                        | Value                                         |
|---------------------------------|-----------------------------------------------|
| Trim per page                   | **203 × 254 mm**                              |
| Bleed (all sides)               | **3 mm**                                      |
| Spread artboard (2-page)        | **412 × 260 mm** (= 2 × 203 + 6, 254 + 6)     |
| Output PDF profile              | **PDF/X-4:2008**                              |
| Output color profile            | CMYK — Coated FOGRA39 (ISO 12647-2:2004)      |
| Image resolution (minimum)      | **300 dpi**                                   |
| Crop strategy when forced       | **center-crop, fill-without-deformation**     |
| Background color (page fill)    | **#fdfefd** (off-white)                       |
| Crop / bleed marks              | **Europa: YES**, **Latam: NO** (see issue)    |

The PDF is annotated in Spanish and uses `{Variable}` tokens for everything
the caller injects (page numbers, album name, dates, milestone titles).

---

## Header / footer (every body page)

The same three-element header runs across every interior page; the footer
is a single wordmark.

| Element                  | Position                                  | Style                                              |
|--------------------------|-------------------------------------------|----------------------------------------------------|
| Top outer-left `Nº página`  | outer margin (left page), 8 mm in, 9 mm down | P22 Mackinac **book** 9 pt / 10.8 pt              |
| Top-center (left page)   | left page, gutter-adjacent column, 9 mm down | `{NombreDelAlbum}` — P22 Mackinac **book** 9 pt / 10.8 pt |
| Top-center (right page)  | right page, gutter-adjacent column, 9 mm down | context label (see below) — P22 Mackinac **book** 9 pt / 10.8 pt |
| Top outer-right `Nº página` | outer margin (right page), 8 mm in, 9 mm down | P22 Mackinac **book** 9 pt / 10.8 pt              |
| **Bottom-right** wordmark   | outer margin (right page), 8 mm in, 8 mm up  | "Dots. Memories" — Inter Semibold 7 pt / 8.4 pt   |

> Source of truth: `docs/templates/final_templates/pdf01_general_base.pdf` (page 1). The footer
> moved from bottom-center to bottom-right; all header labels (page numbers
> and centre labels alike) use P22 Mackinac *book* 9 pt — not Inter Semibold.

### Right-page top-center context label, per album type

| Album type    | Context label                            |
|---------------|------------------------------------------|
| Boda          | `{Protagonistas}`                        |
| Hijos         | `{Protagonistas}` (children's names)     |
| Pareja        | `{tiempojuntos}` (falls back to `{Año}`) |
| Individual    | `{Año}`                                  |
| Otros         | `{Año}`                                  |

---

## Pagination

| Rule                          | Value                          |
|-------------------------------|--------------------------------|
| Multiple of                   | **4** (printer signatures / pliegos) |
| Minimum (Europa)              | 20                             |
| Minimum (Latam)               | 30                             |
| Maximum hard cap              | 250                            |
| Plan-included (no surcharge)  | 60                             |
| Photo input range (recommended) | 30 – 450                     |
| Photo input range (hard)      | 16 – 490 (below 16 → block)    |

---

## Photo-layout repertoire

Each layout listed below is one of the recurring page templates the PDF
documents. Coordinates are in mm. `gap` rows describe gaps between elements;
photo coordinates are top-left anchors of the photo frame on the page.

Visual margin on every page: the spreads show a consistent **binding-side
inset of 23 mm** for the header line and a vertical reading column that
runs from ~36 mm to ~238 mm. The body is full-bleed where photos extend to
3 mm beyond the trim.

### L1 — Protagonist (1 photo, large, with caption)

- Photo: **142 × 189 mm**, centered horizontally on the page. The photo can
  bleed (extends 3 mm beyond trim on outer edges) when the layout marks it
  as a bleed slot.
- Caption block (placed to the side or below):
  - Date `{DíadeMesdeAño}` — P22 Mackinac medium 11 pt / 13.2 pt
  - 4 mm gap
  - Body — Inter Book 9 pt / 10.8 pt, **max 400 chars**, grows upward,
    minimum widow size 3 words, no inter-word break, min text frame width
    7.78 mm.
- Inter-element gap: 7.5 mm (date ↔ photo).

Alternative single-photo variants observed in the source:

- **L1.A** — 113 × 152 mm photo (smaller, side caption format, **800 char** body).
- **L1.B** — 175 × 238 mm photo (oversized, edge-bleed).
- **L1.C** — 175 × 196 mm photo (oversized portrait).
- **L1.D** — 107 × 107 mm centered (square, smaller — used for opening/closing intro pages).
- **L1.E** — 107 × 152 mm with side caption.

### L2 — Two photos

- **L2.A — side-by-side**: two **86 × 110 mm** photos in one row, 16 mm
  horizontal gutter, vertically centered (AUTO above and below).
- **L2.B — stacked vertical (landscape pair)**: two **175 × 107 mm**
  photos stacked with 3 mm vertical gap.
- **L2.C — small framed pair**: two **65 × 74 mm** with 3 mm gap.

### L3 — Three photos

- **L3.A — row of 3**: three **60.27 × 82 mm** photos in a row, 3 mm
  horizontal gaps, AUTO top/bottom margins.

### L4 — Four photos

- **L4.A — 2×2 grid**: four **86 × 86 mm SQUARE** photos, 3 mm gaps, y=71 mm,
  outer margins. (The 2×2 is the most common 4-up layout in the PDF.)
- **L4.B — 2×2 stacked-pair grid**: same dimensions but rendered across a
  spread (4 photos = 2 per page).

### L5 — Five photos

Not directly named in the PDF as a "5-photo grid"; the closest is the
**5+5 instructions spread** in the per-album-type templates (5 photos on
each page of a spread), but in body pages a 5-photo arrangement is treated
as an L4 (2×2) + L1 (1 small) hybrid. **Open question.**

### L6 — Six photos

- **L6.A — 3×2 grid spanning a spread**: six **86 × 110 mm** photos
  arranged 3 across the spread × 2 rows (3 photos per page × 2 rows). Same
  3 mm gaps.

### L7 — Four-pane caption page (collage with text)

- Four **86 × 110 mm** photos arranged as 2 panes per page with 7.5 mm photo-to-caption gaps; caption columns between
  pairs, 91 mm vertical, with date + body Inter 9 pt under each.
- Caption: **350 char** body max, P22 Mackinac medium 11 pt for title,
  Inter Book 9 pt for body. "Not every photo needs text to use this
  spread."

### L8 — Quad-photo top + collage bottom

- Top: four **86 × 110 mm** photos in a row (3 mm gaps).
- Bottom: two **175 × 115.5 mm** photos, 3 mm vertical gap to top row.
- Both pages of the spread mirror the same arrangement.

### L_hito — Milestone (single-page text + QR card)

Used when the user has added a "hito" (milestone) to the album. This is a
text-dominant page, no photo slot — the photo associated with the hito
appears on the facing page in one of the L1–L6 layouts.

- TITLE `{Título del hito}` — P22 Mackinac medium **20 pt / 24 pt**, max
  80 chars, no inter-word break.
- 4 mm gap.
- SUBTITLE `{(DiadeMesdeAño)}` — P22 Mackinac book 9 pt / 10.8 pt.
- 4 mm gap.
- BODY — Inter Book 9 pt / 10.8 pt, **max 800 chars**, no break, min widow
  3 words, body width **122 mm**, padding 10 mm.
- QR card (at bottom of page):
  - Container stroke: color `#f0f0f0`, height 5 pt, corner radius 6 pt,
    align center.
  - Width 130 mm, inner box 105.5 mm.
  - QR icon: varies by hito content type — audio / text / video.
  - Caption beneath QR: P22 Mackinac book 9 pt.

---

## Text-block rules (universal)

These rules apply to **every** caption / dedication / body block:

- No inter-word hyphenation (`No se permite separación entre palabras`).
- No widow lines: every line break must leave at least **3 words** on the
  trailing line (`Eliminar viudas → los saltos de línea deberán ser mínimo
  de 3 palabras`).
- Date format token: `{DíadeMesdeAño}` (formatted by the caller).
- Default block-grow direction varies by layout; the PDF explicitly calls
  out "grows upward" vs "grows downward" per layout.

### Character caps observed in the PDF

| Layout family            | Max chars |
|--------------------------|-----------|
| Single-photo small caption (L1 default) | 400  |
| Single-photo large caption (L1.A)       | 800  |
| Hito body (L_hito)                      | 800  |
| Hito title (L_hito)                     | 80   |
| Multi-pane collage caption (L7)         | 350  |
| Closing/summary text block              | 570  |
| Compact half-caption                    | 300  |

The issue says "800 caracteres" as the front-end cap. The PDF uses 800 for
hito and large captions, and 400 for compact captions — the front-end cap
must therefore distinguish text-block kind.

---

## Content-ordering rules (issue AC1–AC4)

These are not in the PDF — they are issue requirements that affect template
selection but not page geometry:

- Chronological ascending order.
- Group by date / temporal proximity.
- Per-page photo count: min 1, max 6, optimal 1–3.
- Per-page priority for "protagonist" slot: higher resolution > faces
  detected > marked favorite > earlier chronologically.
- **Photo resolution minimum**: 150 dpi (confirm — issue says "<150 dpi"
  excluded; PDF says image quality 300 dpi is the target).

---

## Crop / fill / bleed rules

- Fill the slot without deforming the photo aspect ratio.
- Center-crop when the photo's aspect ratio differs from the slot's.
- Photos with `bleed: true` extend 3 mm beyond the trim on the marked
  edges. The slot's mm coordinates above are inside-the-trim; bleed is an
  additive 3 mm.
- The PDF explicitly forbids leaving white borders on bleed slots.

---

## Open questions

- **5-photo layouts**: no direct 5-up template in the body — handled as
  L4 + L1 hybrid, or treated as 6-up with one slot left empty? Confirm.
- **Per-layout (x, y) anchors**: the PDF documents widths and heights of
  the slots and the gaps between them, but anchors are mostly `AUTO`. The
  library will need a layout-grid solver that takes the available 203 ×
  254 mm page, subtracts the header/footer band (~12 mm top, ~12 mm
  bottom inferred from spec callouts), and centers the slot block.
- **"Latam: no marcas"**: this is a render-time toggle (`drawCropMarks:
  false`). Confirm with stakeholders whether Latam also disables bleed or
  only the marks (text says "Sangrado 3 mm" for both providers, so only
  marks).
- **Color profile**: PDF/X-4 + FOGRA39 is the target. The `pdf` package
  supports color profile attachment via `PdfPageMode` / `PdfOutput` —
  needs verification that we can attach FOGRA39 ICC.
- **Font licensing**: P22 Mackinac, Inter, and Biro Script Plus must be
  bundled into the library's font set. Inter is OFL; P22 Mackinac and
  Biro Script Plus are commercial — license confirmation needed.
- **Image resolution**: 150 dpi vs 300 dpi. Issue says ">=150 dpi" is the
  pass/fail threshold, PDF says 300 dpi is the print target. Likely:
  150 dpi = accept threshold, 300 dpi = downsample target if higher.
