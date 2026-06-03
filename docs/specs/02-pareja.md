# 02 — Pareja (couples)

> Source: `pdf02_pareja_inicial.pdf` (10 pages) + `pdf03_pareja_final.pdf`
> (3 pages). Right-page header label: `{tiempojuntos}` (or `{Año} | {Año}`).

Inherits [00-foundation.md](00-foundation.md). Body pages between front and back
matter follow [01-general-base.md](01-general-base.md). Pareja is the **most
complete front-matter template**; hijos mirrors it, otros/individual are the
shorter variant, boda/general-eventos are the short variant.

## Geometry sequence

| Part | Pages | single / spread |
|---|---|---|
| inicial | 1–4 | single |
| inicial | 5–10 | spread |
| final | 1–2 | spread |
| final | 3 | single |

---

## Inicial (front matter)

### Page 1 — cover face — single

Decorative circle field + album title. Background `#fdfefd`.

| Element | Text / placeholder | Box W×H (mm) | Font | Align | Editable | Notes |
|---|---|---|---|---|---|---|
| Eyebrow | `DOTBOOK DE {PROTAGONISTA}` | 120 × 3.785 | Inter Book 9 pt | center | no | eyebrow above title; verified against `pdf02_pareja_inicial.pdf` p1/p2 (base truth shows the personalized form for pareja too) |
| Title | `{NombreDelAlbum}` | 120 wide × 6.635 | P22 Mackinac medium 23 / 27.6 pt | center | yes | no word-break allowed |
| Date line | `{DiadeMesdeAñodeFechaDeInicio} | {DiadeMesdeAñodeFechaDeInicio}` | 120 × 3.785 | Inter Book 9 / 10.8 pt | center | yes | start/end dates |
| Circle field | decorative | dia 16 / 28 / 47 mm | — | — | no | each circle: edge fade **1.764 mm**; see circle table (p4) |

### Page 2 — title-box spec — single

Same title block, annotated: title box **120 mm** wide (not variable), height
6.635 mm, P22 Mackinac medium 23 / 27.6 pt; date box 120 × 3.785 mm, Inter Book
9 pt. "No se permite la separación de" (no hyphenation). Max-char limit on the
title.

### Page 3 — EJEMPLO máximo caracteres — single *(reflow demo)*

Title block at maximum character count. **Not a separate layout** — verify the
title reflows without word-break.

### Page 4 — COLOCACIÓN BOLAS (circle placement) — single

14 decorative circles. All circles carry a **1.764 mm** edge fade. Coordinates
(mm, design artboard):

| # | X | Y | tier (dia) |
|---|---|---|---|
| 1 | 170 | 140 | 16 |
| 2 | 109 | 181 | 16 |
| 3 | 138 | 225 | 28 |
| 4 | 200 | 240 | 47 |
| 5 | 49 | 193 | 28 |
| 6 | 50 | 273 | 16 |
| 7 | 36 | 109 | 28 |
| 8 | 70 | 48 | 16 |
| 9 | 8 | 43 | 47 |
| 10 | 124 | 68 | 16 |
| 11 | 176 | 91 | 28 |
| 12 | 210 | 33 | 47 |
| 13 | 141 | 4 | 47 |
| 14 | −13 | 169 | 47 |

> Some circles exceed the trim box (negative X, Y > 260) — they bleed off-edge
> by design.

### Page 5 — dedication — spread

| Element | Text / placeholder | Box W×H (mm) | Font | Align | Editable | Notes |
|---|---|---|---|---|---|---|
| Title | `Nuestro mensaje especial o {título dedicatoria}` | — | P22 Mackinac medium | center | yes | max **50 chars** |
| Body | dedication text | 102 wide, max 1000 chars / 32 lines | Inter Book 9 / 10.8 pt | center | yes | grows from center; 6.5 mm + 8 mm gaps |
| Signature | `{Firma}` | — | Biro Script Plus Regular 12 / 14.4 pt | center | yes | placed after 8 mm gap, rotated **2°** |

### Page 6 — EJEMPLO menos caracteres — spread *(reflow demo)*

Dedication with fewer characters. Text box 86 mm wide variant.

### Page 7 — EJEMPLO 1000 caracteres — spread *(reflow demo)*

Dedication at the 1000-char maximum: text box **137 mm** wide, 15 mm gap, grows
up + down, 33 mm block. Demonstrates the wide reflow.

### Page 8 — EJEMPLO menos caracteres (wide) — spread *(reflow demo)*

`{título dedicatoria}` + `{Firma}` + body at reduced length, 137 mm box, 33 mm,
6.5 / 8 mm gaps, 15 / 10 mm. Right-page label `{tiempojuntos}`.

### Page 9 — instructions spread — spread

Two-column instruction spread. Left = "Buscad vuestro momento" (01); right =
"Escuchad vuestra historia" (02).

| Element | Text | Box W×H (mm) | Font | Align |
|---|---|---|---|---|
| Section number | `(01)` / `(02)` | 4.389 tall | P22 Mackinac medium 23 / 27.6 pt | center |
| Title | "Buscad vuestro momento" / "Escuchad vuestra historia" | 6.635 tall | P22 Mackinac medium 23 / 27.6 pt | center |
| Body | instruction copy | 93 / 141 wide, 37.542 tall | Inter Book 9 / 10.8 pt | center |
| Photo strip | row of frames | 35 × 46 each | — | top row |

Gaps: 7.5 / 5 / 8 mm. Block 30.53 mm. Photo strip width markers 35 mm; height
46 / 36 mm.

### Page 10 — "Antes de empezar el viaje" cluster — spread

Decorative photo cluster (see boda spec [04-boda.md](04-boda.md) page 3 — same
geometry).

| Element | Text | Box W×H (mm) | Font | Align |
|---|---|---|---|---|
| Title | "Antes de empezar" (medium) + "el viaje" (medium **italic**) | 19.1 tall | P22 Mackinac 27 / 31 pt | center |
| Body | closing copy | 95 wide, 52.782 tall | Inter Book 9 / 10.8 pt | center |
| Photo cluster | 7 photos w/ opacity gradients | see [04-boda.md §p3 cluster table](04-boda.md) | — | — |

---

## Final (back matter)

### Page 1 — QR keep-alive — spread

Shared across all album-type finals (couple wording).

| Element | Text / placeholder | Box W×H (mm) | Font | Align | Editable |
|---|---|---|---|---|---|
| Title | "Porque algunos recuerdos merecen seguir vivos" | 143 × 15.454 | P22 Mackinac medium 23 / 25 pt | center | no |
| Body | "Las fotografías capturan momentos. Los vídeos conservan la emoción…" | 92 × 10.872 | Inter Book 9 / 10.8 pt | center | no |
| Caption | `{Main characters' names}, disfruta de está última experiencia.` | 143 × 3.252 | Inter Book 9 / 10.8 pt | center | yes |
| QR call | "Escanea el QR y vuelve a esta etapa siempre que quieras." | 36.178 × 10.324 | P22 Mackinac medium 9 / 10.8 pt | center | no |
| QR card | oval QR | sizes 24.58 / 50.892 / 43.189 mm; block 27 mm | — | center | transparencia 100% → 0% |

### Page 2 — photo arc — spread

Photo arc/halo around the QR. Slot coordinates (mm, spread artboard):

```
(390,57) (362,77) (338,57) (307,94) (266,102) (236,140) (202,128)
(205,160) (137,142) (149,142) (163,136) (165,154) (182,157) (177,140)
(185,132) (241,186) (389,94) (348,138) (310,194) (271,203) (291,135)
(266,151) (307,216) (348,232) (395,139) (369,182) (391,201) (389,238)
```

### Page 3 — closing — single

| Element | Text / placeholder | Box W×H (mm) | Font | Align | Notes |
|---|---|---|---|---|---|
| Title | closing line / `{TítuloDelAlbum}` | 115 × 5.793 (variable) | P22 Mackinac medium 20 / 24 pt | center | |
| Photo | closing photo | 66 × 86 | — | — | 5 mm gap; block 44 mm |
