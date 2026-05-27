# Specification: album-type-photo-arc (Slice 5 of 5 — FINAL, ARCHIVED)

**Status:** Completed & Archived (2026-05-26)
**Slice:** 5 of 5 (FINAL slice in the album-type series)
**Archive Path:** `/Users/alexei/work/dots_pdf/openspec/archive/album-type-photo-arc/`

---

## Purpose

Delivers the "Un año lleno de recuerdos" photo-arc spread for `DotsAlbumType.parejas`, `hijos`, `individuales`, and `otros`. Introduces `DotsPhotoCircleElement`, `DotsOvalQrElement`, `AlbumPhotoArcContent`, `DotsAlbumSpreadPage.photoArc(...)`, and `buildPhotoArcPageFor(...)`. Completes the album-type series.

---

## Requirements (R1–R12, All Implemented)

### R1 — DotsPhotoCircleElement model

`DotsPhotoCircleElement` is a sealed subtype of `DotsElement` with 8 fields:
- `x`, `y` (double, pt) — position (inherited)
- `assetPath` (String) — photo asset path
- `diameter` (double, pt) — circle diameter
- `bleedLeft`, `bleedRight`, `bleedTop`, `bleedBottom` (bool, default `false`) — bleed flags

Implements value equality (`==` and `hashCode`) over all fields.

### R2 — Circular photo rendering

Renderer wraps `pw.Image` in `pw.ClipOval`, sized `width: diameter, height: diameter`. On decode failure, silently skips element and invokes `onPhotoFailure` callback.

### R3 — DotsOvalQrElement model

`DotsOvalQrElement` is a sealed subtype of `DotsElement` with 6 fields:
- `x`, `y` (double, pt) — position (inherited)
- `ovalWidth`, `ovalHeight` (double, pt) — bounding box dimensions
- `qrPayload` (String) — QR payload
- `caption` (String) — caption text (resolved by builder per-type)

**Design note:** Caption styling (font size, family, color) is hardcoded in renderer, not exposed as element fields. This is uniform across all oval QR cards.

Implements value equality (`==` and `hashCode`) over all fields.

### R4 — Oval QR rendering

Renderer produces:
1. Outlined oval frame: `pw.Container(BoxDecoration(shape: BoxShape.circle, border: ...))` at 0.5 pt stroke, `#9E9E9D` color
2. Centered QR via `pw.BarcodeWidget` (medium error correction) sized to inscribed square minus 4mm padding
3. Caption text below oval at 8pt P22 Mackinac Book, `#9E9E9D` color, centered

### R5 — AlbumPhotoArcContent value object

Immutable value object with 7 fields:
- `photoPaths` (List<String>, exactly 10 items enforced at factory)
- `qrPayloadLeft`, `qrPayloadRight` (String)
- `qrCaptionLeftOverride`, `qrCaptionRightOverride` (String?, default `null`)
- `title` (String, default `"Un año lleno de recuerdos"`)
- `dateSubtitle` (String)

Implements value equality over all fields (including list equality on `photoPaths`).

### R6 — DotsAlbumSpreadPage.photoArc factory

Named factory that composes:
- 10 `DotsPhotoCircleElement` instances at positions from `kPhotoArcLayout`
- 2 `DotsOvalQrElement` instances at gutter-bottom positions
- 2 `DotsTextElement` instances (title + date subtitle)
- Standard header trio + footer

Total: 14 elements.

Validates:
- Throws `ArgumentError` for `DotsAlbumType.boda`
- Throws `RangeError` if `photoPaths.length != 10`

### R7 — Per-type QR caption resolution

| Type | Left caption default | Right caption default |
|------|----------------------|-----------------------|
| parejas | "Vuestro álbum en digital" | "Todos tus hitos en un lugar" |
| hijos | "Tu album en digital" | "Todos tus hitos en un lugar" |
| individuales | "Tu album en digital" | "Todos tus hitos en un lugar" |
| otros | "Tu album en digital" | "Todos tus hitos en un lugar" |
| boda | n/a — `ArgumentError` | n/a |

Overrides in `AlbumPhotoArcContent` win over defaults.

### R8 — buildPhotoArcPageFor builder

Top-level function that:
- Validates type (rejects `boda` with `ArgumentError`)
- Resolves per-type caption defaults
- Dispatches to factory

Signature: `DotsAlbumSpreadPage buildPhotoArcPageFor(DotsAlbumType type, AlbumPhotoArcContent content, {required int pageNumber, required String contextLabelValue})`

### R9 — Renderer dispatch

10 new exhaustiveness arms across 5 sealed-switch sites:

| Site | PhotoCircle Arm | OvalQr Arm |
|------|-----------------|-----------|
| `album_spread_page.dart` `_buildElement` | `_buildPhotoCircleElement(...)` | `_buildOvalQrElement(...)` |
| `dots_renderer.dart` `_buildElement` (ElementsPage) | `return null;` | `return null;` |
| `dots_renderer.dart` `preloadAssetBytes` (ElementsPage) | `paths.add(element.assetPath);` | `break;` |
| `dots_renderer.dart` `preloadAssetBytes` (AlbumSpreadPage) | `paths.add(element.assetPath);` | `break;` |
| `isolate_synthesis.dart` `_buildElement` | `return null;` | `return null;` |

All arms verified exhaustive via `dart analyze` (0 issues).

### R10 — photoPaths length validation

Factory throws `RangeError` if `photoPaths.length != 10`, before any element construction.

### R11 — pageSize caller contract

Photo-arc page renders as a single `pw.Page` with format width = 406 mm spread width. Caller MUST set `DotsTemplate.pageSize.width >= 406 mm`. Runtime logger warning emitted if violated.

### R12 — Backwards compatibility and public exports

All slice-1/2/3/4 tests pass unchanged. New public symbols exported from `lib/dots_pdf.dart`:
- `DotsPhotoCircleElement`
- `DotsOvalQrElement`
- `AlbumPhotoArcContent`
- `buildPhotoArcPageFor`

---

## Layout Data

### 10-Circle Canonical Layout (kPhotoArcLayout)

| # | x (mm) | y (mm) |
|---|--------|--------|
| 1 | 29.59 | 273.28 |
| 2 | 376.17 | 273.28 |
| 3 | 45.09 | 224.02 |
| 4 | 360.66 | 224.02 |
| 5 | 77.97 | 180.93 |
| 6 | 327.79 | 180.93 |
| 7 | 120.96 | 150.11 |
| 8 | 284.79 | 150.11 |
| 9 | 171.04 | 134.01 |
|10 | 234.72 | 134.01 |

All circles: 44.45 mm diameter (uniform, locked by slice 1).

### QR Oval Layout

- Dimensions: 25.841 mm × 43.127 mm
- Gutter center: x = 203 mm
- Left oval: x = 176 mm (203 - 27)
- Right oval: x = 230 mm (203 + 27)
- Caption top: y = 234 mm (20 mm above page bottom)

---

## Test Coverage

**Final test count:** 454 passed, 0 failed
**Test suite:** 5 new test files (model, layout, factory, builder)
**Growth:** +8 tests in slice 5 (from baseline 446)
**Analyze:** 0 issues

---

## Implementation Quality

- **Design decisions:** All 12 architecture decisions (D1–D12) honored
- **Public API:** 4 new symbols exported
- **Breaking changes:** None
- **Dependencies:** None (existing `package:pdf ^3.11.1` sufficient)
- **Backwards compatibility:** 100% (all prior tests pass)

---

## Archive Details

- **Archived:** 2026-05-26
- **Change folder:** Moved to `/Users/alexei/work/dots_pdf/openspec/archive/album-type-photo-arc/`
- **Archive contents:** proposal, spec (delta), design, tasks, apply-progress, verify-report, archive-report
- **Verify verdict:** PASS WITH WARNINGS (1 CRITICAL spec/design conflict resolved; 5 WARNINGs + 3 SUGGESTIONs deferred)

---

## Series Closure

Slice 5 completes the 5-slice album-type series:
1. `album-type-foundation` — structural foundation
2. `album-type-simple-pages` — dedication + closing
3. `album-type-polaroid-collage` — polaroid grid (individuales/otros p.6)
4. `album-type-gaussian-circles` — decorative cover (parejas/hijos)
5. `album-type-photo-arc` — photo-arc spread (all 4 types, p.7–9)

parejas, hijos, individuales, and otros can now render publication-ready books end-to-end.

boda remains partially blocked on p.4 radial halo coordinate gaps (separate work).

---

## See Also

- **Main proposal:** `/Users/alexei/work/dots_pdf/openspec/archive/album-type-photo-arc/proposal.md`
- **Design details:** `/Users/alexei/work/dots_pdf/openspec/archive/album-type-photo-arc/design.md`
- **Tasks breakdown:** `/Users/alexei/work/dots_pdf/openspec/archive/album-type-photo-arc/tasks.md`
- **Verify report:** `/Users/alexei/work/dots_pdf/openspec/archive/album-type-photo-arc/verify-report.md`
- **Archive report:** `/Users/alexei/work/dots_pdf/openspec/archive/album-type-photo-arc/archive-report.md`
- **Series summary:** `/Users/alexei/work/dots_pdf/openspec/archive/album-type-series-summary.md`
