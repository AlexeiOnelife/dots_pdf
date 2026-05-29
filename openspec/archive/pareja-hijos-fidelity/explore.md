# Exploration: pareja-hijos-fidelity

**Date:** 2026-05-29
**Change:** pareja-hijos-fidelity
**Phase:** explore
**Status:** complete
**Series position:** Task 4 of 7 (`final-render-refinement`), building on Tasks 1–3 (all archived).

---

## Source PDFs (26 pages total, all read)

- `docs/templates/final_templates/pdf02_pareja_inicial.pdf` (10 pages)
- `docs/templates/final_templates/pdf03_pareja_final.pdf` (3 pages)
- `docs/templates/final_templates/pdf08_hijos_inicial.pdf` (10 pages)
- `docs/templates/final_templates/pdf09_hijos_final.pdf` (3 pages)

---

## PDF Page → Factory Map (full)

| # | PDF | Pg | Factory | Notes |
|---|-----|----|---------|-------|
| 1 | pdf02 | 1 | `cover(parejas)` | Visual sample |
| 2 | pdf02 | 2 | `cover(parejas)` | Annotated: box w=120mm, x=41.5mm, y=110.249mm |
| 3 | pdf02 | 3 | `cover(parejas)` EJEMPLO | Max-chars variant |
| 4 | pdf02 | 4 | `cover(parejas)` | Circle coords — match `kCoverCircleLayout` |
| 5 | pdf02 | 5 | `dedication(parejas)` | Right-page spec; LEFT page = solid #CDE7F2 |
| 6 | pdf02 | 6 | `dedication(parejas)` EJEMPLO | Shorter body |
| 7 | pdf02 | 7 | `dedication(parejas)` EJEMPLO | 1000-char body (two grow-direction variants) |
| 8 | pdf02 | 8 | `beforeYouStart(parejas)` | Left+right detail |
| 9 | pdf02 | 9 | `beforeYouStart(parejas)` | Full spread; Q1/Q2 titles + bodies |
| 10 | pdf02 | 10 | `closingQrSpread` | Left-page detail |
| 11 | pdf03 | 1 | `closingQrSpread` | Same as pdf02 p.10 |
| 12 | pdf03 | 2 | `closingQrSpread` | Full spread + right-page circle positions (no diameters) |
| 13 | pdf03 | 3 | `closing(parejas)` | Photo 66×86 + title 20pt + subtitle |
| 14 | pdf08 | 1 | `cover(hijos)` | Same layout as pdf02 p.1 |
| 15 | pdf08 | 2 | `cover(hijos)` | Eyebrow = "DOTBOOK DE {PROTAGONISTA}" |
| 16 | pdf08 | 3 | `cover(hijos)` EJEMPLO | |
| 17 | pdf08 | 4 | `cover(hijos)` | Circle coords identical to parejas |
| 18 | pdf08 | 5 | `dedication(hijos)` | Header center = `{Protagonista}` |
| 19 | pdf08 | 6 | `dedication(hijos)` EJEMPLO | |
| 20 | pdf08 | 7 | `dedication(hijos)` EJEMPLO | |
| 21 | pdf08 | 8 | `beforeYouStart(hijos)` | Per-category body text |
| 22 | pdf08 | 9 | `beforeYouStart(hijos)` | Q1/Q2 with hijos-specific titles |
| 23 | pdf08 | 10 | `closingQrSpread` | Category-agnostic |
| 24 | pdf09 | 1 | `closingQrSpread` | Same |
| 25 | pdf09 | 2 | `closingQrSpread` | Same circle positions |
| 26 | pdf09 | 3 | `closing(hijos)` | Subtitle uses `{Firma} y {Firma}` |

---

## `beforeYouStart` — Measurements (NEW factory)

Two-page spread (406 mm). Copy is design-owned (NOT editable by caller); `AlbumBeforeYouStartContent.titleOverride`/`bodyOverride` only override the defaults.

### Left page

| Element | Font | Size | LH | Box w | Box h | x (mm) | y (mm) |
|---|---|---|---|---|---|---|---|
| Title L1 "Antes de empezar" | P22 Mackinac Medium | 27 | 31 | 95 | 19.1 | 54.083 | 96.2 |
| Title L2 "el viaje" | P22 Mackinac Medium Italic | 27 | 31 | 95 | (same) | 54.083 | 96.2 |
| Body | Inter Book | 9 | 10.8 | 95 | 37.542 | 54.083 | 120.3 |

Per-category body text:
- **parejas**: "Encontrad un espacio donde podáis estar en calma…"
- **hijos**: "Piensa que esto no son solo fotos…"

### Right page

| Element | Font | Size | LH | Box w | Box h | x (mm) | y (mm) |
|---|---|---|---|---|---|---|---|
| Protagonist name label | Inter Book | 9 | 10.8 | 65 | 3.252 | 69.168 | ~210.8 |
| CTA "Pasad la página…" | P22 Mackinac Medium | 15 | 18 | 65 | 17.089 | 69.168 | ~219 |

### Photo-slot grid (both pages)

- 10 slots: 5 per page; each 35 × 46 mm
- Outer trim margin 8 mm; slot y-top 36 mm; slots contiguous (0 mm gap)
- Slot x positions (mm, page-local): 8, 43, 78, 113, 148

### Per-page Q1/Q2 text cluster below slots

| Element | Font | Size | LH | Box h | Gap above |
|---|---|---|---|---|---|
| NÚMERO label | P22 Mackinac Medium | 23 | 27.6 | 4.389 | 0 |
| TITULO | P22 Mackinac Medium | 23 | 27.6 | 6.635 | 7.5 |
| TEXTO | Inter Book | 9 | 10.8 | varies | 5 |

Text-block width 93 mm; x = 55.309 mm from page outer edge.

Per-category Q1/Q2 titles:
- **parejas** Q1: "Buscad vuestro momento" / Q2: "Escuchad vuestra historia"
- **hijos** Q1: "Busca un lugar tranquilo" / Q2: "Escucha los momentos especiales"

---

## `closingQrSpread` — Measurements (NEW factory)

Two-page spread; category-agnostic body. Only variable: bottom-line text `{Protagonistas}` + the `qrPayload`.

### Left page (page-local coordinates)

Content block: 143 mm wide, x = 30 mm from page left.

| Element | Font | Size | LH | Box w | Box h | x (mm) | y (mm) |
|---|---|---|---|---|---|---|---|
| Title "Porque algunos recuerdos merecen seguir vivos" | P22 Mackinac Medium | 23 | 25 | 143 | 15.454 | 30 | 50.892 |
| Body-1 "Las fotografías capturan momentos…" | Inter Book | 9 | 10.8 | 92 | 10.872 | 30 | 71.346 |
| QR block | — | — | — | 27 | 27 | 30 | 94.081 |
| QR caption "Escanea el QR y vuelve…" | P22 Mackinac Medium | 9 | 10.8 | 36.178 | 10.324 | 62 | 94.081 |
| Bottom text `{Protagonistas}, disfruta de está última experiencia.` | Inter Book | 9 | 10.8 | 143 | 3.252 | 30 | 229.42 |

### Right page (decorative circles)

27 circle positions extracted (spread-relative; right page x ≥ 203 mm). **Diameters NOT annotated** in the PDF — only X/Y positions. Visual estimation needed for Task 4 or deferred to a follow-up.

---

## Existing-Factory Drift

### `.cover(parejas|hijos)` — `dots_template.dart:1499–1588`

| Element | PDF | Code | Severity |
|---|---|---|---|
| **parejas eyebrow text** | `"DOTBOOK DE {PROTAGONISTA}"` | `'DOTBOOK'` | **CRITICAL** |
| hijos eyebrow token | `{PROTAGONISTA}` | `{NOMBREHIJO}` | **HIGH** (token mismatch) |
| Text-box width | 120 mm | full pageWidth (203 mm) | **MEDIUM** |
| Text-box x | 41.5 mm | 0 | **MEDIUM** |
| Eyebrow y | 110.249 mm | ~115 mm | MEDIUM (≈4.75 mm) |
| Title y | ~119 mm | ~127 mm | MEDIUM (≈8 mm) |
| Date y | ~130.7 mm | ~145 mm | MEDIUM (≈14.3 mm) |
| Decorative circles | match | match | OK |

### `.dedication(parejas|hijos)` — `dots_template.dart:1247–1316`

| Element | PDF | Code | Severity |
|---|---|---|---|
| All text x | 50.53 mm from right-page origin | 0 | HIGH |
| Title y | content-block top dependent on body length | fixed 60 mm | MEDIUM |
| Body width | 120 mm | 102 mm | MEDIUM |
| Body y | 6.5 mm below title bottom | fixed 90 mm (independent) | HIGH |
| Signature y | 8 mm below body bottom | fixed 160 mm (independent) | HIGH |
| Left-page solid `#CDE7F2` background | full-page fill | absent | MEDIUM (mechanism decision) |
| Signature font/angle | Biro Script Plus 12pt 2° | OK | OK |

### `.photoArc(parejas|hijos)` — `dots_template.dart:1604+`

`kPhotoArcLayout` source attribution conflicts with current PDF (its referenced "parejas p.9" is now `beforeYouStart`). **Cannot verify fidelity** in this task — likely from an older template revision.

### `.closing(parejas|hijos)` — `dots_template.dart:1328–1407`

| Element | PDF | Code | Severity |
|---|---|---|---|
| Photo y | 71.534 mm | 60 mm | MEDIUM (11.5 mm off) |
| Title y | photo_bottom + 5 mm = 162.534 mm | photo_bottom + 10 mm ≈ 156 mm | MEDIUM |
| Title x | 44 mm | 0 | MEDIUM |
| Title width | 115 mm | — (no width field) | LOW |
| Subtitle y | title_bottom + 5 mm | title_bottom + ~10.6 mm | MEDIUM |
| Subtitle x | 44 mm | 0 | MEDIUM |
| Subtitle width | 115 mm | 102 mm | MEDIUM |

---

## Approaches

### A — In-place coordinate corrections + new factory bodies (RECOMMENDED)

Fix the 4 existing factories' hardcoded coordinates; implement `beforeYouStart` and `closingQrSpread` bodies. Extract layout constants to new files mirroring `kCoverCircleLayout`.

**Pros:** established pattern; self-contained; independently testable.
**Cons:** `beforeYouStart` needs a `switch` on type for per-category copy; left-page dedication background needs mechanism decision.
**Effort:** Medium (~520 LOC).

### B — Extract `_alignedTextBlock` helper

Same as A but DRY the text-block positioning.

**Pros:** less duplication.
**Cons:** premature abstraction for 3 factories.

### C — Push all fixed copy into `AlbumBeforeYouStartContent`

**Cons:** PDF marks all text as NOT editable — design-owned copy doesn't belong in caller data.

**Recommendation: Approach A.**

---

## Open Questions

1. **`photoArc` source PDF** — current `kPhotoArcLayout` cites "parejas p.9" but that page is now `beforeYouStart`. Was the arc extracted from an older revision? Defer fidelity verification to a follow-up.
2. **Dedication left-page `#CDE7F2` background** — needs a per-page background mechanism. Options: (a) extend the parser's `_blankAlbumSpread` to accept a `pageBackgroundColor`; (b) emit a full-page rectangle element as the first element. Defer to follow-up.
3. **Cover eyebrow token for parejas** — PDF shows `{PROTAGONISTA}`; existing `contextLabelToken` for parejas is `{tiempojuntos}`. Confirm `{PROTAGONISTA}` is a separate variables-map token, not the same as `{tiempojuntos}` or `{Protagonistas}`.
4. **closingQrSpread circle diameters** — not annotated in the PDFs. Visual estimation for Task 4, or defer the right-page circles to a follow-up?
5. **closingQrSpread QR y interpretation** — 43.189 mm gap from title top (= 94.081 mm) is one reading. Confirm.
6. **`beforeYouStart` photo-slot element type** — 35×46 mm rounded-rectangle slots. `DotsImageElement` doesn't expose corner radius. Options: (a) use `DotsImageElement` without rounding for Task 4 (defer rounded corners); (b) add `cornerRadiusMm` to `DotsImageElement`; (c) use `DotsPolaroidElement` with zero frame border.
7. **`closing` single-page header** — closing is a single right page, not a spread. Should `leftPageNumber` be null? Current stub sets both — confirm chrome behaviour.
8. **"Q1"/"Q2" labels in beforeYouStart** — design-only annotations, not rendered elements. Confirm.

---

## Size Estimate (~520 LOC, single PR per user direction)

| Component | LOC |
|---|---|
| `beforeYouStart` body | 80 |
| `closingQrSpread` body | 60 |
| `kBeforeYouStartSlotLayout` constants | 50 |
| `kClosingQrCircleLayout` constants | 80 |
| Fix `cover(parejas\|hijos)` | 30 |
| Fix `dedication(parejas\|hijos)` | 40 |
| Fix `closing(parejas\|hijos)` | 30 |
| New + updated tests | 150 |
| **Total** | **~520** |

Single PR per the user's standing direction ("remove the limits in PR size").

---

## Ready for Proposal

Yes, with the 8 open questions and these scope decisions: photoArc verification deferred (Q1); dedication blue background deferred (Q2); rounded-corner photo slots deferred (Q6); right-page circles use VISUAL-ESTIMATED diameters or are deferred (Q4).
