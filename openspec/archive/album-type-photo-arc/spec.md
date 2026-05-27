# Specification: album-type-photo-arc (Slice 5 of 5 — FINAL)

**Status:** Completed & Archived
**Slice:** 5 of 5 (FINAL slice in the album-type series)
**Depends on:** album-type-foundation (archived), album-type-simple-pages (archived), album-type-polaroid-collage (archived), album-type-gaussian-circles (archived)

## Purpose

Delivers the "Un año lleno de recuerdos" photo-arc spread for `DotsAlbumType.parejas`, `hijos`, `individuales`, and `otros`. Introduces `DotsPhotoCircleElement`, `DotsOvalQrElement`, `AlbumPhotoArcContent`, `DotsAlbumSpreadPage.photoArc(...)`, and `buildPhotoArcPageFor(...)`. Completes the album-type series — after this slice the library can produce publication-ready books for all four supported types.

---

## Requirements (R1-R12)

### Requirement: R1 — DotsPhotoCircleElement model

`DotsPhotoCircleElement` MUST be a sealed subtype of `DotsElement` with fields: `x` (double, pt), `y` (double, pt), `diameter` (double, pt), `assetPath` (String), `bleedLeft` (bool, default `false`), `bleedRight` (bool, default `false`), `bleedTop` (bool, default `false`), `bleedBottom` (bool, default `false`). The type MUST implement value equality (`==` and `hashCode`) based on all fields. It MUST be constructible via named parameters in a single constructor.

#### Scenarios
- `DotsPhotoCircleElement` constructs with all fields
- `DotsPhotoCircleElement` equality and `hashCode` are based on all field values
- `DotsPhotoCircleElement` inequality when any field differs
- Bleed flags default to `false`

---

### Requirement: R2 — Circular photo rendering

For any `DotsPhotoCircleElement` in a `DotsAlbumSpreadPage.elements` list, the renderer MUST decode the photo from `assetPath` via `bytesResolver` and wrap the resulting `pw.Image` in `pw.ClipOval`. The clipped region MUST be a circle of `diameter` centered at `(x + diameter/2, y + diameter/2)` in PDF pt. The `pw.ClipOval` widget MUST be sized `width: diameter, height: diameter`.

When `bytesResolver` cannot decode `assetPath` (null bytes, I/O error, or unrecognized format), the renderer MUST silently skip that element — no widget is emitted for it — and MUST invoke the `onPhotoFailure` callback with the failing `assetPath`. The rest of the page MUST continue to render.

#### Scenarios
- Photo is wrapped in `pw.ClipOval`
- Decode failure skips element and fires `onPhotoFailure` callback
- 10 valid photos all produce `ClipOval` widgets

---

### Requirement: R3 — DotsOvalQrElement model

`DotsOvalQrElement` MUST be a sealed subtype of `DotsElement` with fields: `x` (double, pt), `y` (double, pt), `ovalWidth` (double, pt), `ovalHeight` (double, pt), `qrPayload` (String), `caption` (String). The type MUST implement value equality (`==` and `hashCode`) based on all fields. It MUST be constructible via named parameters in a single constructor.

**Design note (D2 alignment):** Caption styling (font size, family, color) is resolved as renderer-side constants, NOT exposed as element fields. Caption styling is uniform across all oval QR cards and is not caller-configurable per element. The element carries only the resolved caption text via the `caption` field.

#### Scenarios
- `DotsOvalQrElement` constructs with all fields
- `DotsOvalQrElement` equality and `hashCode` are based on all field values
- `DotsOvalQrElement` inequality when any field differs

---

### Requirement: R4 — Oval QR rendering

For any `DotsOvalQrElement` in a `DotsAlbumSpreadPage.elements` list, the renderer MUST produce a composite at position `(x, y)` consisting of:

1. An outlined oval frame drawn at `ovalWidth × ovalHeight`. The frame is a stroked ellipse (no fill). Stroke colour and width are renderer-side constants (0.5 pt, `#9E9E9D`).
2. A `pw.BarcodeWidget` generating a QR code for `qrPayload`, centered inside the oval, using medium error correction (`BarcodeQRCorrectionLevel.medium`). The QR widget is sized to the inscribed square of the oval minus padding.
3. A caption text line rendered below the oval at 8pt in P22 Mackinac Book. Caption color is `#9E9E9D`.

#### Scenarios
- Oval QR renders oval frame and QR widget at specified dimensions
- Caption text appears below the oval frame boundary
- QR uses medium error correction

---

### Requirement: R5 — AlbumPhotoArcContent value object

`AlbumPhotoArcContent` MUST be an immutable value object with fields: `photoPaths` (`List<String>`, exactly 10 items enforced), `qrPayloadLeft` (String), `qrPayloadRight` (String), `qrCaptionLeftOverride` (String?, default `null`), `qrCaptionRightOverride` (String?, default `null`), `title` (String, default `"Un año lleno de recuerdos"`), `dateSubtitle` (String). It MUST implement value equality (`==` and `hashCode`) based on all fields.

#### Scenarios
- Constructs with required fields; optional fields default correctly
- Equality and `hashCode` are based on all field values
- Inequality when any field differs

---

### Requirement: R6 — DotsAlbumSpreadPage.photoArc factory

`DotsAlbumSpreadPage.photoArc(type, pageNumber, contextLabelValue, content)` MUST accept a `DotsAlbumType`, an `int pageNumber`, a `String contextLabelValue`, and an `AlbumPhotoArcContent`. It MUST return a `DotsAlbumSpreadPage` whose `elements` list contains:

- Exactly 10 `DotsPhotoCircleElement` instances at positions defined by `kPhotoArcLayout` (uniform diameter 44.45 mm converted to pt)
- Exactly 2 `DotsOvalQrElement` instances at bottom-gutter positions (27 mm each side of gutter at x = 203 mm; top of QR captions 20 mm above page bottom)
- 1 `DotsTextElement` for title at `(19 mm, 43 mm)` — P22 Mackinac Medium 23pt
- 1 `DotsTextElement` for date subtitle at `(19 mm, 43 mm + 23pt × 1.2 + 5 mm)` — P22 Mackinac Book 9pt

Total elements: 14.

The `header.centerLabel` MUST equal `contextLabelValue`. The `header.leftPageNumber` and `header.rightPageNumber` MUST be derived from `pageNumber` per slice-2 convention. The factory MUST throw `ArgumentError` for `DotsAlbumType.boda`.

#### Scenarios
- Photo-arc page has exactly 14 elements (composition verified)
- Photo-circle elements match `kPhotoArcLayout` coordinates
- Header center label equals `contextLabelValue`
- Factory throws `ArgumentError` for `boda`

---

### Requirement: R7 — Per-type QR caption resolution

`buildPhotoArcPageFor` MUST resolve left and right QR captions according to this table. When the corresponding override in `AlbumPhotoArcContent` is non-null, the override wins; otherwise the per-type default applies.

| Type          | Left caption default              | Right caption default                  |
|---------------|-----------------------------------|----------------------------------------|
| `parejas`     | "Vuestro álbum en digital"        | "Todos tus hitos en un lugar"          |
| `hijos`       | "Tu album en digital"             | "Todos tus hitos en un lugar"          |
| `individuales`| "Tu album en digital"             | "Todos tus hitos en un lugar"          |
| `otros`       | "Tu album en digital"             | "Todos tus hitos en un lugar"          |
| `boda`        | n/a — throws `ArgumentError`      | n/a                                    |

#### Scenarios
- Per-type default captions are applied correctly
- Right caption is shared across all 4 types
- Caption overrides win over per-type defaults

---

### Requirement: R8 — buildPhotoArcPageFor builder

A top-level function `buildPhotoArcPageFor(DotsAlbumType type, AlbumPhotoArcContent content, {required int pageNumber, required String contextLabelValue})` MUST exist and MUST return a single `DotsAlbumSpreadPage`. It MUST support `DotsAlbumType.parejas`, `hijos`, `individuales`, and `otros`. Calling it with `DotsAlbumType.boda` MUST throw an `ArgumentError`.

The builder resolves per-type caption defaults (R7) before dispatching to the factory. Defense-in-depth: the factory ALSO throws `ArgumentError` for `boda`.

#### Scenarios
- Returns `DotsAlbumSpreadPage`
- Throws `ArgumentError` for `boda`
- Geometry is identical for all 4 supported types given same content

---

### Requirement: R9 — Renderer dispatch

The shared `buildAlbumSpreadPage` helper's `_buildElement` switch MUST gain two new arms — one for `DotsPhotoCircleElement` and one for `DotsOvalQrElement`. Each arm MUST call a private helper. After adding these arms, `dart analyze` MUST report no non-exhaustive pattern match errors. The 3 exhaustiveness sites in `dots_renderer.dart` and 1 in `isolate_synthesis.dart` MUST all be updated.

#### Scenarios
- Photo-arc page renders to non-empty PDF buffer
- Sealed switch is exhaustive after slice 5
- Photo-arc page renders via both main-isolate and worker-isolate paths

---

### Requirement: R10 — photoPaths length validation

`AlbumPhotoArcContent` factory dispatching on it MUST throw a `RangeError` when `photoPaths.length != 10`. This is a hard contract. The error MUST be thrown before any element is constructed.

#### Scenarios
- `photoPaths` length 9 throws `RangeError`
- `photoPaths` length 11 throws `RangeError`
- `photoPaths` length 10 does not throw

---

### Requirement: R11 — pageSize caller contract

The photo-arc page renders as a single `pw.Page` whose format width MUST be at least 406 mm (the spread width). This width MUST be set by the caller on the `DotsTemplate.pageSize` that wraps this page. The `DotsAlbumSpreadPage.photoArc` factory cannot read or enforce `pageFormat` at construction time.

**Consequence of violation:** if the caller sets `pageSize.width < 406 mm`, elements whose `x` coordinate exceeds the declared page width will be silently clipped by the PDF renderer. No exception is raised by the library.

This requirement is documented as a caller obligation. A render-time logger warning is emitted when page width is detected to be insufficient.

#### Scenarios
- Page renders correctly when `pageSize.width == 406 mm`

---

### Requirement: R12 — Backwards compatibility and public exports

All slice-1, slice-2, slice-3, and slice-4 tests MUST pass without modification after this slice is applied. `DotsPhotoCircleElement` and `DotsOvalQrElement` MUST NOT affect any existing element type, switch arm, or public API. All new public symbols (`DotsPhotoCircleElement`, `DotsOvalQrElement`, `AlbumPhotoArcContent`, `buildPhotoArcPageFor`) MUST be re-exported from `lib/dots_pdf.dart`.

#### Scenarios
- All prior slice tests pass unchanged
- New symbols are exported from public API

---

## 10-Circle Canonical Layout (kPhotoArcLayout)

Source: parejas p.9 table. Coordinates in mm from top-left of the 406 mm-wide spread. All circles share diameter 44.45 mm (uniform — locked by slice 1 decision).

| # | x (mm)  | y (mm)  |
|---|---------|---------|
| 1 | 29.59   | 273.28  |
| 2 | 376.17  | 273.28  |
| 3 | 45.09   | 224.02  |
| 4 | 360.66  | 224.02  |
| 5 | 77.97   | 180.93  |
| 6 | 327.79  | 180.93  |
| 7 | 120.96  | 150.11  |
| 8 | 284.79  | 150.11  |
| 9 | 171.04  | 134.01  |
|10 | 234.72  | 134.01  |

---

## QR Oval Layout

Source: parejas p.9 / boda p.4 shared geometry. Dimensions: `25.841 × 43.127 mm`.

- Gutter x = 203 mm (spread center)
- Left QR center x = 176 mm (203 - 27)
- Right QR center x = 230 mm (203 + 27)
- Top of QR caption: 20 mm above page bottom
- Both QR ovals share `ovalWidth: 25.841 mm`, `ovalHeight: 43.127 mm`

Caption font: P22 Mackinac Book 8pt / 9.6pt line height.
