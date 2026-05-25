# Specification: album-type-photo-arc (Slice 5 of 5)

**Status:** Draft
**Slice:** 5 of 5 (FINAL slice in the album-type series)
**Depends on:** album-type-foundation (archived), album-type-simple-pages (archived), album-type-polaroid-collage (archived), album-type-gaussian-circles (archived)

## Purpose

Delivers the "Un año lleno de recuerdos" photo-arc spread for
`DotsAlbumType.parejas`, `hijos`, `individuales`, and `otros`. Introduces
`DotsPhotoCircleElement`, `DotsOvalQrElement`, `AlbumPhotoArcContent`,
`DotsAlbumSpreadPage.photoArc(...)`, and `buildPhotoArcPageFor(...)`. Completes
the album-type series — after this slice the library can produce publication-ready
books for all four supported types.

---

## Requirements

### Requirement: R1 — DotsPhotoCircleElement model

`DotsPhotoCircleElement` MUST be a sealed subtype of `DotsElement` with fields:
`x` (double, pt), `y` (double, pt), `diameter` (double, pt), `assetPath` (String),
`bleedLeft` (bool, default `false`), `bleedRight` (bool, default `false`),
`bleedTop` (bool, default `false`), `bleedBottom` (bool, default `false`). The type
MUST implement value equality (`==` and `hashCode`) based on all fields. It MUST be
constructible via named parameters in a single constructor.

#### Scenario: DotsPhotoCircleElement constructs with all fields

- GIVEN `DotsPhotoCircleElement(x: 83.82, y: 774.42, diameter: 125.98, assetPath: 'a.jpg', bleedLeft: false, bleedRight: false, bleedTop: false, bleedBottom: false)`
- WHEN constructed
- THEN no exception is thrown
- AND all field values are accessible and equal to the supplied values

#### Scenario: DotsPhotoCircleElement equality and hashCode

- GIVEN two `DotsPhotoCircleElement` instances constructed with identical field values
- WHEN compared with `==`
- THEN they are equal
- AND their `hashCode` values are equal

#### Scenario: DotsPhotoCircleElement inequality when diameter differs

- GIVEN two `DotsPhotoCircleElement` instances that differ only in `diameter`
- WHEN compared with `==`
- THEN they are NOT equal

#### Scenario: bleed flags default to false

- GIVEN `DotsPhotoCircleElement(x: 0, y: 0, diameter: 125.98, assetPath: 'a.jpg')`
- WHEN constructed without explicit bleed flag values
- THEN all four bleed flags (`bleedLeft`, `bleedRight`, `bleedTop`, `bleedBottom`) are `false`

---

### Requirement: R2 — Circular photo rendering

For any `DotsPhotoCircleElement` in a `DotsAlbumSpreadPage.elements` list, the
renderer MUST decode the photo from `assetPath` via `bytesResolver` and wrap the
resulting `pw.Image` in `pw.ClipOval`. The clipped region MUST be a circle of
`diameter` centered at `(x + diameter/2, y + diameter/2)` in PDF pt. The
`pw.ClipOval` widget MUST be sized `width: diameter, height: diameter`.

When `bytesResolver` cannot decode `assetPath` (null bytes, I/O error, or
unrecognized format), the renderer MUST silently skip that element — no widget is
emitted for it — and MUST invoke the `onPhotoFailure` callback with the failing
`assetPath`. The rest of the page MUST continue to render.

#### Scenario: photo is wrapped in pw.ClipOval

- GIVEN a `DotsPhotoCircleElement(diameter: 125.98, assetPath: 'photo.jpg', ...)`
- WHEN rendered
- THEN the produced widget tree contains a `pw.ClipOval` of `width: 125.98, height: 125.98`
- AND the circle center is placed at `(x + 62.99, y + 62.99)` in pt

#### Scenario: decode failure skips element and fires onPhotoFailure

- GIVEN a `DotsPhotoCircleElement` whose `assetPath` resolves to null bytes
- WHEN rendered
- THEN no widget is emitted for that element
- AND `onPhotoFailure` is called with the failing `assetPath`
- AND all other elements on the page are still rendered

#### Scenario: 10 valid photos all produce ClipOval widgets

- GIVEN a photo-arc page with 10 `DotsPhotoCircleElement` instances each backed by valid image bytes
- WHEN rendered
- THEN the rendered output contains 10 `pw.ClipOval` instances

---

### Requirement: R3 — DotsOvalQrElement model

`DotsOvalQrElement` MUST be a sealed subtype of `DotsElement` with fields:
`x` (double, pt), `y` (double, pt), `ovalWidth` (double, pt), `ovalHeight` (double,
pt), `qrPayload` (String), `caption` (String), `captionFontSize` (double, pt),
`captionColorHex` (String). The type MUST implement value equality (`==` and
`hashCode`) based on all fields. It MUST be constructible via named parameters in
a single constructor.

#### Scenario: DotsOvalQrElement constructs with all fields

- GIVEN `DotsOvalQrElement(x: 10.0, y: 20.0, ovalWidth: 73.24, ovalHeight: 122.27, qrPayload: 'https://example.com', caption: 'Vuestro álbum en digital', captionFontSize: 8.0, captionColorHex: '#9E9E9D')`
- WHEN constructed
- THEN no exception is thrown
- AND all field values are accessible and equal to the supplied values

#### Scenario: DotsOvalQrElement equality and hashCode

- GIVEN two `DotsOvalQrElement` instances constructed with identical field values
- WHEN compared with `==`
- THEN they are equal
- AND their `hashCode` values are equal

#### Scenario: DotsOvalQrElement inequality when caption differs

- GIVEN two `DotsOvalQrElement` instances that differ only in `caption`
- WHEN compared with `==`
- THEN they are NOT equal

---

### Requirement: R4 — Oval QR rendering

For any `DotsOvalQrElement` in a `DotsAlbumSpreadPage.elements` list, the renderer
MUST produce a composite at position `(x, y)` consisting of:

1. An outlined oval frame drawn at `ovalWidth × ovalHeight`. The frame is a stroked
   ellipse (no fill). Stroke colour and width are renderer-side constants
   (suggested: 0.5 pt, `#9E9E9D`).
2. A `pw.BarcodeWidget` generating a QR code for `qrPayload`, centered inside the
   oval, using medium error correction (`BarcodeQRCorrectionLevel.medium`). The QR
   widget is sized to the inscribed square of the oval minus padding.
3. A caption text line rendered below the oval at `captionFontSize` in P22 Mackinac
   Book. Caption color is `captionColorHex`.

#### Scenario: oval QR renders oval frame and QR widget

- GIVEN a `DotsOvalQrElement(ovalWidth: 73.24, ovalHeight: 122.27, qrPayload: 'https://example.com', caption: 'Test', captionFontSize: 8.0, captionColorHex: '#9E9E9D')`
- WHEN rendered
- THEN the output contains an outlined ellipse of the specified dimensions
- AND the output contains a QR barcode widget inside the ellipse

#### Scenario: caption text appears below the oval frame

- GIVEN a `DotsOvalQrElement(caption: 'Vuestro álbum en digital', ...)`
- WHEN rendered
- THEN caption text appears vertically below the oval frame boundary

#### Scenario: QR uses medium error correction

- GIVEN any `DotsOvalQrElement`
- WHEN rendered
- THEN the `pw.BarcodeWidget` is configured with `BarcodeQRCorrectionLevel.medium`

---

### Requirement: R5 — AlbumPhotoArcContent value object

`AlbumPhotoArcContent` MUST be an immutable value object with fields:
`photoPaths` (`List<String>`, exactly 10 items enforced at construction time —
see R10 for the enforcement contract),
`qrPayloadLeft` (String),
`qrPayloadRight` (String),
`qrCaptionLeftOverride` (String?, default `null`),
`qrCaptionRightOverride` (String?, default `null`),
`title` (String, default `"Un año lleno de recuerdos"`),
`dateSubtitle` (String).
It MUST implement value equality (`==` and `hashCode`) based on all fields.

#### Scenario: AlbumPhotoArcContent constructs with required fields

- GIVEN `AlbumPhotoArcContent(photoPaths: [10 paths], qrPayloadLeft: 'https://l.example.com', qrPayloadRight: 'https://r.example.com', dateSubtitle: '01/01/2024 | 31/12/2024')`
- WHEN constructed
- THEN `title` equals `"Un año lleno de recuerdos"` (default)
- AND `qrCaptionLeftOverride` is `null`
- AND `qrCaptionRightOverride` is `null`
- AND `photoPaths.length` equals `10`

#### Scenario: AlbumPhotoArcContent equality and hashCode

- GIVEN two `AlbumPhotoArcContent` instances with identical field values
- WHEN compared with `==`
- THEN they are equal
- AND their `hashCode` values are equal

#### Scenario: AlbumPhotoArcContent inequality when qrCaptionLeftOverride differs

- GIVEN two instances where one has `qrCaptionLeftOverride: null` and the other `qrCaptionLeftOverride: 'CUSTOM'`
- WHEN compared with `==`
- THEN they are NOT equal

---

### Requirement: R6 — DotsAlbumSpreadPage.photoArc factory

`DotsAlbumSpreadPage.photoArc(type, pageNumber, contextLabelValue, content)` MUST
accept a `DotsAlbumType`, an `int pageNumber`, a `String contextLabelValue`, and an
`AlbumPhotoArcContent`. It MUST return a `DotsAlbumSpreadPage` whose `elements` list
contains:

- exactly 10 `DotsPhotoCircleElement` instances at the positions defined by
  `kPhotoArcLayout` (uniform diameter 44.45 mm converted to pt),
- exactly 2 `DotsOvalQrElement` instances at the bottom-gutter positions (27 mm each
  side of the gutter at x = 203 mm; top of QR captions 20 mm above page bottom),
- 1 `DotsTextElement` for the title at `(19 mm, 43 mm)` — P22 Mackinac Medium 23pt,
- 1 `DotsTextElement` for the date subtitle at `(19 mm, 43 mm + 23pt * 1.2 + 5 mm)`
  — P22 Mackinac Book 9pt.

Total elements: 14.

The `header.centerLabel` MUST equal `contextLabelValue`. The `header.leftPageNumber`
and `header.rightPageNumber` MUST be derived from `pageNumber` per the slice-2
convention. The factory MUST throw `ArgumentError` for `DotsAlbumType.boda`.

#### Scenario: photo-arc page has exactly 14 elements

- GIVEN `DotsAlbumSpreadPage.photoArc(type: DotsAlbumType.parejas, pageNumber: 9, contextLabelValue: '5 años juntos', content: AlbumPhotoArcContent(photoPaths: [10 paths], qrPayloadLeft: 'L', qrPayloadRight: 'R', dateSubtitle: '2024'))`
- WHEN constructed
- THEN `page.elements.length` equals `14`
- AND exactly 10 elements are `DotsPhotoCircleElement` instances
- AND exactly 2 elements are `DotsOvalQrElement` instances
- AND exactly 2 elements are `DotsTextElement` instances

#### Scenario: photo-circle elements match kPhotoArcLayout

- GIVEN the page constructed as above
- WHEN `elements` is inspected for `DotsPhotoCircleElement` instances
- THEN the 10 elements have `(x, y, diameter)` matching `kPhotoArcLayout` converted to pt

#### Scenario: header.centerLabel equals contextLabelValue

- GIVEN `DotsAlbumSpreadPage.photoArc(contextLabelValue: '5 años juntos', ...)`
- WHEN constructed
- THEN `page.header.centerLabel` equals `'5 años juntos'`

#### Scenario: factory throws ArgumentError for boda

- GIVEN `DotsAlbumSpreadPage.photoArc(type: DotsAlbumType.boda, ...)`
- WHEN called
- THEN an `ArgumentError` is thrown

---

### Requirement: R7 — Per-type QR caption resolution

`buildPhotoArcPageFor` MUST resolve the left and right QR captions according to
the following table. When the corresponding override in `AlbumPhotoArcContent` is
non-null, the override wins; otherwise the per-type default applies.

| Type          | Left caption default              | Right caption default                  |
|---------------|-----------------------------------|----------------------------------------|
| `parejas`     | "Vuestro álbum en digital"        | "Todos tus hitos en un lugar"          |
| `hijos`       | "Tu album en digital"             | "Todos tus hitos en un lugar"          |
| `individuales`| "Tu album en digital"             | "Todos tus hitos en un lugar"          |
| `otros`       | "Tu album en digital"             | "Todos tus hitos en un lugar"          |
| `boda`        | n/a — throws `ArgumentError`      | n/a                                    |

#### Scenario: parejas default left caption

- GIVEN `buildPhotoArcPageFor(DotsAlbumType.parejas, content, pageNumber: 9, contextLabelValue: 'x')`
- AND `content.qrCaptionLeftOverride` is `null`
- WHEN executed
- THEN the left `DotsOvalQrElement` has `caption == "Vuestro álbum en digital"`

#### Scenario: hijos default left caption

- GIVEN `buildPhotoArcPageFor(DotsAlbumType.hijos, content, pageNumber: 9, contextLabelValue: 'x')`
- AND `content.qrCaptionLeftOverride` is `null`
- WHEN executed
- THEN the left `DotsOvalQrElement` has `caption == "Tu album en digital"`

#### Scenario: individuales default left caption matches hijos

- GIVEN `buildPhotoArcPageFor(DotsAlbumType.individuales, content, pageNumber: 7, contextLabelValue: 'x')`
- AND `content.qrCaptionLeftOverride` is `null`
- WHEN executed
- THEN the left `DotsOvalQrElement` has `caption == "Tu album en digital"`

#### Scenario: otros default left caption matches hijos and individuales

- GIVEN `buildPhotoArcPageFor(DotsAlbumType.otros, content, pageNumber: 7, contextLabelValue: 'x')`
- AND `content.qrCaptionLeftOverride` is `null`
- WHEN executed
- THEN the left `DotsOvalQrElement` has `caption == "Tu album en digital"`

#### Scenario: right caption default is shared by all 4 types

- GIVEN `buildPhotoArcPageFor` called with any of the 4 supported types
- AND `content.qrCaptionRightOverride` is `null`
- WHEN executed
- THEN the right `DotsOvalQrElement` has `caption == "Todos tus hitos en un lugar"`

#### Scenario: qrCaptionLeftOverride wins over per-type default for parejas

- GIVEN `buildPhotoArcPageFor(DotsAlbumType.parejas, content, ...)` where `content.qrCaptionLeftOverride == 'CUSTOM'`
- WHEN executed
- THEN the left `DotsOvalQrElement` has `caption == "CUSTOM"`

#### Scenario: qrCaptionRightOverride wins over per-type default

- GIVEN `buildPhotoArcPageFor(DotsAlbumType.parejas, content, ...)` where `content.qrCaptionRightOverride == 'MI QR'`
- WHEN executed
- THEN the right `DotsOvalQrElement` has `caption == "MI QR"`

---

### Requirement: R8 — buildPhotoArcPageFor builder

A top-level function `buildPhotoArcPageFor(DotsAlbumType type, AlbumPhotoArcContent content, {required int pageNumber, required String contextLabelValue})` MUST exist and MUST return a single `DotsAlbumSpreadPage`. It MUST support `DotsAlbumType.parejas`, `hijos`, `individuales`, and `otros`. Calling it with `DotsAlbumType.boda` MUST throw an `ArgumentError`.

The builder resolves per-type caption defaults (R7) before dispatching to the factory. Defense-in-depth: the factory (`DotsAlbumSpreadPage.photoArc`) ALSO throws `ArgumentError` for `boda`.

#### Scenario: buildPhotoArcPageFor returns a DotsAlbumSpreadPage

- GIVEN `buildPhotoArcPageFor(DotsAlbumType.parejas, content, pageNumber: 9, contextLabelValue: '5 años juntos')`
- WHEN executed
- THEN the return type is `DotsAlbumSpreadPage`

#### Scenario: buildPhotoArcPageFor throws ArgumentError for boda

- GIVEN `buildPhotoArcPageFor(DotsAlbumType.boda, content, pageNumber: 9, contextLabelValue: 'x')`
- WHEN executed
- THEN an `ArgumentError` is thrown

#### Scenario: geometry is identical for all 4 supported types given same content

- GIVEN `buildPhotoArcPageFor` called with `parejas`, `hijos`, `individuales`, and `otros` using identical `content` and `pageNumber`
- WHEN all four pages are compared structurally
- THEN all 10 `DotsPhotoCircleElement` instances have identical `(x, y, diameter)` across all four pages
- AND the two `DotsOvalQrElement` instances have identical `(x, y, ovalWidth, ovalHeight)` across all four pages
- AND only `caption` values on the QR elements differ between `parejas` and the other three types

---

### Requirement: R9 — Renderer dispatch

The shared `buildAlbumSpreadPage` helper's `_buildElement` switch MUST gain two new
arms — one for `DotsPhotoCircleElement` and one for `DotsOvalQrElement`. Each arm
MUST call a private helper (`_buildPhotoCircleElement` and `_buildOvalQrElement`
respectively). After adding these arms, `dart analyze` MUST report no non-exhaustive
pattern match errors. The 3 exhaustiveness sites in `dots_renderer.dart` and 1 in
`isolate_synthesis.dart` MUST all be updated.

#### Scenario: photo-arc page renders to a non-empty PDF buffer

- GIVEN a photo-arc page produced by `buildPhotoArcPageFor(DotsAlbumType.parejas, ...)`
- AND all 10 photo paths resolve to valid image bytes
- WHEN rendered via `buildAlbumSpreadPage`
- THEN the output is a non-empty valid PDF byte buffer

#### Scenario: sealed switch is exhaustive after slice 5

- GIVEN the sealed `DotsElement` hierarchy updated with `DotsPhotoCircleElement` and `DotsOvalQrElement`
- WHEN `dart analyze` is run
- THEN no non-exhaustive pattern match errors are reported

#### Scenario: photo-arc page renders without error via worker isolate path

- GIVEN the same photo-arc page rendered through `useIsolate: true`
- WHEN the generator is called
- THEN it produces a non-empty valid PDF byte buffer without throwing

---

### Requirement: R10 — photoPaths length validation

`AlbumPhotoArcContent` (or the factory dispatching on it) MUST throw a `RangeError`
when `photoPaths.length != 10`. This is a hard contract. The error MUST be thrown
before any element is constructed.

#### Scenario: photoPaths length 9 throws RangeError

- GIVEN `AlbumPhotoArcContent(photoPaths: [9 paths], ...)`
- WHEN constructed or when the factory is called
- THEN a `RangeError` is thrown

#### Scenario: photoPaths length 11 throws RangeError

- GIVEN `AlbumPhotoArcContent(photoPaths: [11 paths], ...)`
- WHEN constructed or when the factory is called
- THEN a `RangeError` is thrown

#### Scenario: photoPaths length 10 does not throw

- GIVEN `AlbumPhotoArcContent(photoPaths: [exactly 10 paths], ...)`
- WHEN constructed
- THEN no exception is thrown

---

### Requirement: R11 — pageSize caller contract (documented, not enforced at construction time)

The photo-arc page renders as a single `pw.Page` whose format width MUST be at least
406 mm (the spread width). This width MUST be set by the caller on the
`DotsTemplate.pageSize` that wraps this page. The `DotsAlbumSpreadPage.photoArc`
factory cannot read or enforce `pageFormat` at construction time.

**Consequence of violation**: if the caller sets `pageSize.width < 406 mm`, elements
whose `x` coordinate exceeds the declared page width (circles in the right half of
the arc: slots 2, 4, 6, 8, 10 from `kPhotoArcLayout`) will be silently clipped by
the PDF renderer. No exception is raised by the library.

This requirement is a documented caller obligation, not a runtime check. A future
slice may add a runtime guard.

#### Scenario: page renders correctly when pageSize.width == 406 mm

- GIVEN a photo-arc page with 10 valid photos
- AND the caller has set `DotsTemplate.pageSize.width` to `406 mm` (in pt)
- WHEN rendered
- THEN all 10 circles are visible in the output (none clipped)

---

### Requirement: R12 — Backwards compatibility and public exports

All slice-1, slice-2, slice-3, and slice-4 tests MUST pass without modification
after this slice is applied. `DotsPhotoCircleElement` and `DotsOvalQrElement` MUST
NOT affect any existing element type, switch arm, or public API. All new public
symbols (`DotsPhotoCircleElement`, `DotsOvalQrElement`, `AlbumPhotoArcContent`,
`buildPhotoArcPageFor`) MUST be re-exported from `lib/dots_pdf.dart`.

#### Scenario: existing tests pass unchanged

- GIVEN the slice-5 changes applied to the codebase
- WHEN all slice-1/2/3/4 test files are run without modification
- THEN all tests pass

#### Scenario: new symbols exported from lib/dots_pdf.dart

- GIVEN the public API barrel file `lib/dots_pdf.dart`
- WHEN inspected for exports
- THEN `DotsPhotoCircleElement`, `DotsOvalQrElement`, `AlbumPhotoArcContent`, and `buildPhotoArcPageFor` are all exported

---

## 10-Circle Canonical Layout (kPhotoArcLayout)

Source: parejas p.9 table. Coordinates in mm from top-left of the **406 mm-wide spread**.
All circles share diameter 44.45 mm (uniform — locked by slice 1 decision).
Bleed flags are all `false` (all 10 circles are fully within the 406 × 254 mm spread).

| # | x (mm)  | y (mm)  | side   |
|---|---------|---------|--------|
| 1 | 29.59   | 273.28  | left   |
| 2 | 376.17  | 273.28  | right  |
| 3 | 45.09   | 224.02  | left   |
| 4 | 360.66  | 224.02  | right  |
| 5 | 77.97   | 180.93  | left   |
| 6 | 327.79  | 180.93  | right  |
| 7 | 120.96  | 150.11  | left   |
| 8 | 284.79  | 150.11  | right  |
| 9 | 171.04  | 134.01  | left   |
|10 | 234.72  | 134.01  | right  |

`kPhotoArcLayout` is a `const List<({double xMm, double yMm, double diameterMm})>`.
The factory converts each entry to pt at construction time (`mm * 72 / 25.4`).

## QR Oval Layout

Source: parejas p.9 / boda p.4 shared geometry (`25.841 × 43.127 mm`).

- Gutter x = 203 mm (spread center).
- Left QR center x = 203 - 27 = 176 mm → top-left x = 176 - 25.841/2 = 163.08 mm.
- Right QR center x = 203 + 27 = 230 mm → top-left x = 230 - 25.841/2 = 217.08 mm.
- Top of QR caption: 20 mm above page bottom (page height = 254 mm) → y bottom boundary = 234 mm. QR oval top-left y = 234 - 43.127 = 190.87 mm.
- Both QR ovals share `ovalWidth: 25.841 mm`, `ovalHeight: 43.127 mm`, `captionFontSize: 8 pt`, `captionColorHex: '#9E9E9D'`.

Caption font: P22 Mackinac Book 8pt / 9.6pt line height. (Note: the proposal
corrects a previous prompt that suggested Inter; canonical spec says P22 Mackinac
Book for QR captions on this page.)

---

## Acceptance Test List

The following tests MUST exist in `test/render/photo_arc_page_test.dart`:

- `DotsPhotoCircleElement — constructs with all named fields`
- `DotsPhotoCircleElement — equality: identical instances are equal`
- `DotsPhotoCircleElement — equality: differs when diameter changes`
- `DotsPhotoCircleElement — equality: differs when assetPath changes`
- `DotsPhotoCircleElement — bleed flags default to false`
- `DotsOvalQrElement — constructs with all named fields`
- `DotsOvalQrElement — equality: identical instances are equal`
- `DotsOvalQrElement — inequality when caption differs`
- `AlbumPhotoArcContent — constructs with required fields; title defaults to "Un año lleno de recuerdos"`
- `AlbumPhotoArcContent — equality: identical instances are equal`
- `AlbumPhotoArcContent — inequality when qrCaptionLeftOverride differs`
- `AlbumPhotoArcContent — throws RangeError when photoPaths.length == 9`
- `AlbumPhotoArcContent — throws RangeError when photoPaths.length == 11`
- `AlbumPhotoArcContent — accepts photoPaths.length == 10 without error`
- `DotsAlbumSpreadPage.photoArc — elements list has exactly 14 entries`
- `DotsAlbumSpreadPage.photoArc — exactly 10 elements are DotsPhotoCircleElement`
- `DotsAlbumSpreadPage.photoArc — exactly 2 elements are DotsOvalQrElement`
- `DotsAlbumSpreadPage.photoArc — exactly 2 elements are DotsTextElement`
- `DotsAlbumSpreadPage.photoArc — circle elements match kPhotoArcLayout`
- `DotsAlbumSpreadPage.photoArc — header.centerLabel equals contextLabelValue`
- `DotsAlbumSpreadPage.photoArc — throws ArgumentError for DotsAlbumType.boda`
- `buildPhotoArcPageFor — returns DotsAlbumSpreadPage`
- `buildPhotoArcPageFor — throws ArgumentError for DotsAlbumType.boda`
- `buildPhotoArcPageFor — parejas left caption defaults to "Vuestro álbum en digital"`
- `buildPhotoArcPageFor — hijos left caption defaults to "Tu album en digital"`
- `buildPhotoArcPageFor — individuales left caption defaults to "Tu album en digital"`
- `buildPhotoArcPageFor — otros left caption defaults to "Tu album en digital"`
- `buildPhotoArcPageFor — right caption defaults to "Todos tus hitos en un lugar" for all types`
- `buildPhotoArcPageFor — qrCaptionLeftOverride wins over per-type default`
- `buildPhotoArcPageFor — qrCaptionRightOverride wins over per-type default`
- `buildPhotoArcPageFor — geometry identical for all 4 supported types given same content`
- `photo-arc rendering — produces non-empty PDF byte buffer`
- `photo-arc rendering — photo decode failure skips element and fires onPhotoFailure`
- `photo-arc rendering — sealed switch is exhaustive (dart analyze reports no errors)`
- `photo-arc rendering — produces non-empty PDF byte buffer via isolate path`
- `backwards compatibility — all slice-1/2/3/4 tests pass unchanged`
- `public API — DotsPhotoCircleElement exported from lib/dots_pdf.dart`
- `public API — DotsOvalQrElement exported from lib/dots_pdf.dart`
- `public API — AlbumPhotoArcContent exported from lib/dots_pdf.dart`
- `public API — buildPhotoArcPageFor exported from lib/dots_pdf.dart`

---

## Risks and Spec-Level Assumptions

1. **QR caption font**: the canonical spec says P22 Mackinac Book 8pt for QR captions.
   An earlier prompt suggested Inter. This spec follows the canonical source. If
   design discovers evidence of Inter at render time, the font reference is a one-field
   change in the renderer and does not break the model or scenarios.

2. **Oval border styling**: the canonical spec does not state the oval stroke color or
   width explicitly. This spec documents the renderer-side default as `0.5 pt, #9E9E9D`
   (matching the QR caption color). Design phase confirms or overrides.

3. **pageSize caller contract**: the factory cannot enforce that the caller sets
   `DotsTemplate.pageSize.width >= 406 mm`. Violation causes silent clipping of
   right-half circles. Documented as a caller obligation in R11; not a hard error in
   this slice.

4. **Diameter uniformity**: the canonical spec labels only the bottom-most circle at
   44.45 mm. The render suggests middle-arc circles may be larger. Slice 1 locked all
   10 at uniform 44.45 mm. This spec honors that decision. If the lock is later lifted,
   `kPhotoArcLayout` gains a per-entry `diameterMm` that overrides the uniform value —
   that is additive and does not break existing callers.

5. **photoPaths length enforcement site**: the proposal defers the enforcement site
   (constructor vs. factory) to spec/design. This spec resolves it as: enforcement
   occurs in the `AlbumPhotoArcContent` constructor (consistent with `RangeError`
   pattern used in slice 3's `buildPolaroidCollagePageFor`). The factory relies on
   this invariant.

6. **QR oval top-left y coordinate**: derived from "top of QR captions: 20 mm above
   page bottom" as `y = 254 - 20 - 43.127 = 190.87 mm`. Design phase should verify
   this interpretation (top of caption vs. top of QR oval) against the canonical PDF.
