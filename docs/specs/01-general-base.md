# 01 — General Base (interior layout catalog)

> Source: `pdf01_general_base.pdf` — **85 pages, all spreads**
> (1167.87 × 737.008 pt media). This is the type-agnostic body. Every album
> type reuses these layouts between its front matter (`inicial`) and back
> matter (`final`).

Inherits everything in [00-foundation.md](00-foundation.md). All dimensions are
from the page's own mm callouts. Caption titles are P22 Mackinac medium
11 pt / 13.2 pt; body/caption text is Inter Book 9 pt / 10.8 pt unless noted.

## Layout codes

`l1`, `l1a`–`l1e`, `l2a`–`l2c`, `l3a`, `l4a`, `l4b`, `l6a`, `l7`, `l8`, `lhito`
(see [`lib/src/render/layout/`](../../lib/src/render/layout/)). The layout
solver positions photos + captions; the renderer draws. Slot kinds:
`captionTitle`, `captionDate`, `captionBody`, `qrCard`.

## Page → layout map

| Pages | Layout | Photo size (mm) | Caption | Notes |
|---|---|---|---|---|
| 2–3 | L1 protagonist | 142 × 189 | none | insets 8 / 53 / 57 mm |
| 4–6 | L1 + caption | 142 × 189 | text 86 mm wide, max 400 chars, Inter Book 9 pt; title P22 Mackinac medium 11 / 13.2 pt | 4 mm gap; caption grows upward |
| 7–8 | L1.A | 113 × 152 | text 113 mm wide, max 800 chars | |
| 9–10 | L1.A variant | 113 × 152 | — | |
| 11–12 | square-ish | 86 × 84 | — | |
| 13–18 | caption variants | — | text 100 / 175.5 mm wide, max 280 chars, centered | reflow demos |
| 19–20 | L1.B oversized | 175 × 238 | none | full-bleed |
| 21–28 | L1 + side caption | 175 × 196 | text 86 mm wide, max 400 / 300 chars | side-by-side |
| 29–30 | L1.B | 195 × 238 | — | |
| 31 | 2-photo marker | — | — | "SON DOS FOTOS / FOTO 1 / FOTO 2" |
| 32–35 | L1 pair + caption | 113 × 152 | text 100 mm wide, max 300 chars | |
| 36–44 | portrait + caption | 107 × 175 | text 86 / 132 mm wide, max 800 chars, centered/left | |
| 45–49 | L-shape | 142×104 / 91 / 60 / 105×67 | text 132 mm wide | |
| 50–51 | squares | 86 × 86 (70.5 / 39.5 / 66.25) | — | |
| 52–55 | L2 pair + caption | 86 × 110 | text 86 mm wide, max 800 chars | |
| 56–57 | landscape pair | 194 × 117.5 | — | |
| 58–62 | mixed pair + caption | 86 × 86 + 110 | text 136 mm wide | |
| 63–65 | portrait pairs | 107 × 175 | — | |
| 66–67 | **L3 row of three** | 60.27 × 82 | text 86 mm wide | 3 mm gaps between photos |
| 68–71 | **L7 four-pane** | 86 × 110 | text max **350 chars**, 1–4 descriptions | "No es necesario que todas las imágenes tengan texto" |
| 72 | mixed | 142×104 / 155 / 91 / 105 / 67 | — | |
| 73–74 | **L4 grid** | 86 × 86 (71) | — | |
| 75–76 | **L8 quad** | 86 × 115.5 | — | 4 photos |
| 77 | L3 double | 60.27 × 82 (×6) | — | two rows of three |
| 78–79 | L8 quad + double | 175×115.5 + 86×110 | — | |
| 80–81 | **L2.C framed** | 65 × 74 (62) | — | small framed |
| 82 | grid | 86 × 86 (71) | — | |
| 83–85 | **L_hito** (milestone + QR) | photo region 122 mm | see below | milestone pages |

## L_hito (milestone + QR card) — pages 83–85

Verbatim specs from the page callouts:

| Element | Text / placeholder | Box W×H (mm) | Font | Align | Limits |
|---|---|---|---|---|---|
| Title | `{Título del hito}` | 149 × 5.92 | P22 Mackinac medium 20 / 24 pt | center | max **80 chars** |
| Subtitle (date) | `{(DiadeMesdeAño)}` | 149 × 2.701 | P22 Mackinac regular 20 / 24 pt | center | |
| Body | milestone text | 122 wide | Inter Book 9 / 10.8 pt | — | max **800 chars**; > 500 chars → full box width (p84 note) |
| QR card | `qrCard` slot | box 130 wide, inner 105.5, photo region 122 | — | center | gaps 7.5 / 4 / 10 mm |
| QR stroke | — | height 5 pt, corner radius **6 pt** | color **`#f0f0f0`** | center | rounded corners |

> "El icono del código QR se modifica en función del contenido del hito: audio,
> texto o video."

## Notes for comparison

- Pages 13–18, and any page labelled **EJEMPLO**, demonstrate caption reflow at
  different character counts — verify reflow, not pixel identity.
- Page 31 is a **marker page** ("SON DOS FOTOS") indicating a two-photo layout
  follows; it is not a rendered album page.
- Photo dimensions in parentheses are secondary box sizes within composite
  (L-shape / mixed) layouts.
