# 00 — Foundation (the page-source)

> Source: `pdf01_general_base.pdf`, page 1 — the reference page that defines the
> contract every other page inherits. Verbatim Spanish callouts are quoted; the
> spec value follows.

This document is the **single inheritance root**. Per-page tables in the other
specs only list **deviations** from these values.

## 1. Page geometry

| Property | Value | Source callout |
|---|---|---|
| Trim size | **203 × 254 mm** | "Tamaño de página: 203 x 254 mm" |
| Bleed | **3 mm** all four sides | "Se necesitará un sangrado de 3 mm" |
| Crop + bleed marks | **required** | "…y poner las marcas de recorte y de sangrado" |
| Single-page media (with bleed) | 209 × 260 mm → 592.441 × 737.008 pt | — |
| Spread media (with bleed) | 412 × 260 mm → 1167.87 × 737.008 pt | — |
| Spread TrimBox | `[8.504, 8.504, 1159.37, 728.504]` pt | — |
| Gutter (spine center on spread) | X = 583.937 pt | — |

Body pages are authored as **spreads** (two facing 203×254 pages on one
1167.87×737.008 pt artboard). Some front/back-matter pages are **single**
(592.441×737.008 pt). Geometry per page is stated in each album-type spec.

## 2. Output / production

| Property | Value | Source callout |
|---|---|---|
| Export profile | **PDF/X-4:2008** | "Exportar en PDF/X-4:2008" |
| Image resolution | **300 dpi** | "Calidad de imagen: 300 dpi" |
| Crop behavior | **centered** | "El recorte… se hará centrado" |
| Background color (ALL pages) | **`#fdfefd`** | "Color de fondo de todas las páginas: #fdfefd" |

> The current renderer emits PDF 1.7, **not** PDF/X-4. PDF/X-4 + FOGRA39
> conformance is deferred work — see [AGENTS.md](../../AGENTS.md) and
> [README.md](../../README.md#known-limitations-and-follow-ups). This spec
> records the **target**, not current conformance.

## 3. Page chrome (header + footer)

Applied to body pages. Front/back-matter pages keep the footer and the page
number; some omit the centered title. Deviations noted per page.

### Header

| Element | Text / placeholder | Position | Font | Notes |
|---|---|---|---|---|
| Page number | `Nº página` | top-outer corner | — | outer = away from spine |
| Dotbook name | `{DotbookName}` | top-center (left page) | P22 Mackinac book 9 pt / 10.8 pt | |
| Context label | per album type (see below) | top-center (right page) | P22 Mackinac book 9 pt / 10.8 pt | |

Header insets: **8 mm** from the page edges, **9 mm** down.

**Right-page top-center label rule** (verbatim):
> "Boda e hijos: Protagonista/as / Pareja: tiempo juntos (en su ausencia año del
> dotbook: {año} | {año}) / Individual / otros: {año} | {año}"

| Album type | Right-page label token |
|---|---|
| boda, hijos | `{Protagonistas}` |
| pareja | `{tiempojuntos}` (or `{Año} | {Año}` in its absence) |
| individual, otros | `{Año} | {Año}` |
| general eventos | `{Año}` |

### Footer

| Element | Text | Font | Box | Notes |
|---|---|---|---|---|
| Brand | `Dots. Memories` | Inter Semibold 7 pt / 8.4 pt | height 2.392 mm, width 18.57 mm | not editable, all pages |

Footer inset: 5 mm from the bottom trim.

## 4. Typography registry

| Family | Style | Size / line-height | Used for |
|---|---|---|---|
| P22 Mackinac | book | 9 / 10.8 pt | header (name + context) |
| P22 Mackinac | medium | 11 / 13.2 pt | caption titles (body) |
| P22 Mackinac | medium | 18–27 pt | welcome / instruction / milestone titles |
| P22 Mackinac | medium / medium italic | 27 / 31 pt | "Antes de empezar el viaje" |
| P22 Mackinac | medium | 20 / 24 pt | milestone title `{Título del hito}`, closing |
| P22 Mackinac | regular | 20 / 24 pt | milestone subtitle (date) |
| Inter | Book | 9 / 10.8 pt | body text & captions |
| Inter | Semibold | 7 / 8.4 pt | footer brand |
| Biro Script Plus | Regular | 12 / 14.4 pt | dedication signature `{Firma}` (rotated 2°) |

## 5. Inheritance contract

Unless a per-page table says otherwise, every page inherits:

1. Background `#fdfefd`.
2. 3 mm bleed + crop/bleed marks.
3. Header (page number + centered name/context) and footer (`Dots. Memories`).
4. 300 dpi centered-crop imagery.
5. The font registry above.

A per-page elements table therefore lists **only the content unique to that
page** plus any chrome override.
