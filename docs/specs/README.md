# dots_pdf — Print Spec Documents

These documents are the **authoritative, diffable specification** extracted
from the annotated base-truth PDFs in
[`docs/templates/final_templates/`](../templates/final_templates/). Each
base-truth PDF embeds its design intent as literal callout text (millimetre
coordinates, font specs, box dimensions). These specs transcribe that intent
into a stable schema so a render can be compared against it later — page by
page, element by element.

> If a spec disagrees with a base-truth PDF, **the PDF wins** — re-extract and
> fix the spec in the same change.

## Source mapping (base truth → spec)

| Spec | Base-truth PDF | Pages |
|---|---|---|
| [00-foundation.md](00-foundation.md) | (page-source rules, from `pdf01` p1) | — |
| [01-general-base.md](01-general-base.md) | `pdf01_general_base.pdf` | 85 |
| [02-pareja.md](02-pareja.md) | `pdf02_pareja_inicial.pdf` + `pdf03_pareja_final.pdf` | 10 + 3 |
| [03-otros.md](03-otros.md) | `pdf04_otros_inicial.pdf` + `pdf05_otros_final.pdf` | 9 + 3 |
| [04-boda.md](04-boda.md) | `pdf06_boda_inicial.pdf` + `pdf07_boda_final.pdf` | 3 + 3 |
| [05-hijos.md](05-hijos.md) | `pdf08_hijos_inicial.pdf` + `pdf09_hijos_final.pdf` | 10 + 3 |
| [06-individual.md](06-individual.md) | `pdf10_individual_inicial.pdf` + `pdf11_individual_final.pdf` | 9 + 3 |
| [07-general-eventos.md](07-general-eventos.md) | `pdf12_general_eventos_inicial.pdf` + `pdf13_general_eventos_final.pdf` | 3 + 3 |
| [08-cover.md](08-cover.md) | `docs/templates/pdf_cover/*.xlsx` | — |

## How the documents relate

```
00-foundation  ──(page size, bleed, marks, color, chrome, fonts)──►  every other spec
01-general-base ──(interior layout catalog L1–L8, L_hito)──────────►  body pages of all album types
02..07          ──(front-matter "inicial" + back-matter "final")──►  per album type
08-cover        ──(hardcover wrap geometry + provider bleed)───────►  cover pipeline (separate from interior)
```

**The first page of `general_base` is the page-source for everything**: it
defines page size, background color, bleed, crop/bleed marks, export profile,
and resolution. All other pages inherit those values unless a spec explicitly
overrides them. Inheritance is stated once in `00-foundation.md`; per-page
tables only list **deviations**.

## Inicial vs final

Album-type PDFs are split into two parts:

- **`inicial`** = front matter (cover face, title, dedication, circle
  placement, welcome + instruction spreads).
- **`final`** = back matter (QR "keep-alive" spread, photo arc/halo, closing
  page).

The **body** between front and back matter is type-agnostic and is specified
once in `01-general-base.md`.

## Per-page schema (used by every spec)

Each page is documented as:

- **Page N — role — geometry — MediaBox**
  - `role`: cover-face / title / dedication / instructions / layout-Lx / closing / EJEMPLO / …
  - `geometry`: `single` (209×260 mm media, 203×254 mm trim) or `spread` (412×260 mm media; two 203×254 mm facing pages).
  - **EJEMPLO pages are flagged explicitly.** They are not separate layouts — they
    demonstrate how a layout reflows at different character counts. Do **not**
    render them as distinct pages.
- **Elements table** with these columns:

  | Element | Type | Text / placeholder | Pos X,Y (mm) | Box W×H (mm) | Font (family / style / size / line-height) | Align | Editable | Notes |

  - `Pos X,Y` is the element origin in **page millimetres from the top-left trim
    corner** (matching the base-truth callouts) when the PDF states it;
    otherwise `—`.
  - `Editable` mirrors the PDF's `editable` / `no es editable` note.
  - Placeholders use the PDF's literal tokens, e.g. `{NombreDelAlbum}`,
    `{DiadeMesdeAñodeFechaDeInicio}`, `{Protagonistas}`, `{título dedicatoria}`,
    `{Firma}`, `{Título del hito}`, `{TítuloDelAlbum}`, `{Año}`, `{DotbookName}`.

## Units & geometry constants (global)

| Constant | Value |
|---|---|
| 1 mm | 2.834645669 pt |
| 1 pt | 0.352777778 mm |
| Page trim | 203 × 254 mm |
| Bleed | 3 mm on all four sides |
| Page media (single, with bleed) | 209 × 260 mm → 592.441 × 737.008 pt |
| Spread media (two pages, with bleed) | 412 × 260 mm → 1167.87 × 737.008 pt |
| Spread TrimBox (pt) | `[8.504, 8.504, 1159.37, 728.504]` |
| Gutter / spine center on spread (pt) | X = 583.937 (right-page left trim) |
| Background color (all pages) | `#fdfefd` |
| Export profile | PDF/X-4:2008 |
| Image resolution | 300 dpi, centered crop |

## Fonts

| Family | Styles used | Where |
|---|---|---|
| P22 Mackinac | book, medium, medium italic, regular | titles, headers, milestone/closing |
| Inter | Book, Semibold | body text, captions, footer |
| Biro Script Plus | Regular | dedication signature `{Firma}` |

> Fonts are **TrueType only** (`.ttf`). CFF/`.otf` outlines collapse to
> `.notdef`. See [AGENTS.md](../../AGENTS.md).

## Comparison protocol

1. Pick the spec matching the render's album type + part.
2. For each page: confirm geometry (single/spread) and MediaBox first.
3. Walk the elements table top-to-bottom; check position, box, font, align.
4. Classify mismatches: **Critical** (geometry / contract broken), **Major**
   (composition intent changed), **Minor** (polish).
5. EJEMPLO pages: verify reflow behavior, not pixel identity.
