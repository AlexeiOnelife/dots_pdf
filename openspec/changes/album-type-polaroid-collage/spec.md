# Specification: album-type-polaroid-collage (slice 3 of 5)

**Status:** Draft
**Slice:** 3 of 5
**Depends on:** album-type-simple-pages (completed and archived), album-type-foundation (completed and archived)

## Purpose

Delivers the polaroid collage spread for `individuales` and `otros` p.6: a
2-page spread of 6–8 tilted white-framed photo cards with an optional
right-to-left opacity gradient on slot polar-2. Introduces `DotsPolaroidElement`,
`AlbumCollageContent`, `PolaroidSlotPosition`, and `buildPolaroidCollagePageFor`.

---

## Requirements

### Requirement: R1 — DotsPolaroidElement model

`DotsPolaroidElement` MUST be a sealed subtype of `DotsElement` with the following
fields: `x` (double, from super), `y` (double, from super), `assetPath` (String),
`width` (double), `height` (double), `angleDegrees` (double), `gradientRtl` (bool,
default `false`), `bleedLeft` (bool, default `false`), `bleedRight` (bool, default
`false`), `bleedTop` (bool, default `false`), `bleedBottom` (bool, default `false`).
The type MUST implement value equality (`==` and `hashCode`) based on all fields. It
MUST be constructible using named parameters in a single `const` constructor.

#### Scenario: DotsPolaroidElement constructs with all fields

- GIVEN `DotsPolaroidElement(x: 59.5, y: 51.0, assetPath: 'a.jpg', width: 306.14, height: 379.84, angleDegrees: -2.5, gradientRtl: false, bleedLeft: false, bleedRight: false, bleedTop: false, bleedBottom: false)`
- WHEN constructed
- THEN no exception is thrown
- AND all field values are accessible and equal to the supplied values

#### Scenario: DotsPolaroidElement equality and hashCode

- GIVEN two `DotsPolaroidElement` instances constructed with identical field values
- WHEN compared with `==`
- THEN they are equal
- AND their `hashCode` values are equal

#### Scenario: DotsPolaroidElement inequality when fields differ

- GIVEN two `DotsPolaroidElement` instances that differ only in `angleDegrees`
- WHEN compared with `==`
- THEN they are NOT equal

---

### Requirement: R2 — Polaroid frame rendering

For any `DotsPolaroidElement` in a `DotsAlbumSpreadPage.elements` list, the renderer
MUST compose: a white outer container at `element.width × element.height`; an inner
photo at dimensions `(element.width − 11 mm) × (element.height − 12 mm)` offset
(5.5 mm, 5.5 mm) from the outer container's top-left; the whole composition wrapped
in `pw.Transform.rotate` with angle `element.angleDegrees * pi / 180` around the
geometric centre (`pw.Alignment.center`). Frame border widths (left/right/top = 5.5 mm,
bottom = 6.5 mm) and outer fill color (white) are renderer-side constants and MUST NOT
be configurable via `DotsPolaroidElement` fields.

#### Scenario: rotation angle is applied correctly

- GIVEN a `DotsPolaroidElement(angleDegrees: -2.5, ...)`
- WHEN rendered
- THEN the produced `pw.Transform.rotate` angle equals `-2.5 * pi / 180.0` (radians)

#### Scenario: inner photo dimensions match frame constants

- GIVEN a `DotsPolaroidElement(width: 306.14, height: 379.84, ...)`  (108 mm × 134 mm in pt)
- WHEN rendered
- THEN the inner photo widget is sized `(306.14 − 11 mm in pt) × (379.84 − 12 mm in pt)`
- AND it is positioned at offset `(5.5 mm in pt, 5.5 mm in pt)` within the outer container

#### Scenario: outer container is white

- GIVEN any `DotsPolaroidElement`
- WHEN rendered
- THEN the outer container carries a white fill color

---

### Requirement: R3 — Gradient overlay

When `DotsPolaroidElement.gradientRtl` is `true`, the renderer MUST paint a
`pw.LinearGradient` mask over the inner photo with: `begin: Alignment.centerRight`,
`end: Alignment.centerLeft`, colors `[fully opaque, 15%-opaque]`. The gradient MUST
be composed inside the un-rotated coordinate frame (before the `pw.Transform.rotate`
wraps the composition). When `gradientRtl` is `false`, no gradient is applied.

#### Scenario: gradient applied when gradientRtl is true

- GIVEN a `DotsPolaroidElement(gradientRtl: true, ...)`
- WHEN rendered
- THEN the inner photo decoration includes a `pw.LinearGradient` from right (100% opacity) to left (15% opacity)

#### Scenario: no gradient when gradientRtl is false

- GIVEN a `DotsPolaroidElement(gradientRtl: false, ...)`
- WHEN rendered
- THEN no gradient decoration is applied to the inner photo

---

### Requirement: R4 — DotsAlbumSpreadPage.polaroidCollage factory

`DotsAlbumSpreadPage.polaroidCollage(...)` MUST accept: `type` (DotsAlbumType),
`pageNumber` (int), `contextLabelValue` (String), `photoPaths` (List\<String\>, 6–8
items), `applyOtrosGradient` (bool, default `false`), `additionalSlots`
(List\<PolaroidSlotPosition\>, default `const []`). It MUST return a
`DotsAlbumSpreadPage` whose `elements` list contains exactly
`photoPaths.length + additionalSlots.length` `DotsPolaroidElement` instances. The
first 6 elements MUST be placed at the documented polar-1…polar-6 coordinates from
`extracted_coordinates.md` § 3. When `applyOtrosGradient: true`, the element for
slot polar-2 MUST carry `gradientRtl: true`; all other slots MUST carry
`gradientRtl: false`.

#### Scenario: 6 photoPaths produces 6 elements

- GIVEN `DotsAlbumSpreadPage.polaroidCollage(type: DotsAlbumType.individuales, pageNumber: 6, contextLabelValue: '2024', photoPaths: [p1, p2, p3, p4, p5, p6])`
- WHEN built
- THEN `elements` has length 6
- AND every element is a `DotsPolaroidElement`

#### Scenario: polar-2 carries gradientRtl true when applyOtrosGradient is true

- GIVEN `DotsAlbumSpreadPage.polaroidCollage(type: DotsAlbumType.otros, ..., photoPaths: [6 paths], applyOtrosGradient: true)`
- WHEN built
- THEN `elements[1].gradientRtl` is `true`  (slot polar-2, index 1)
- AND all other elements have `gradientRtl == false`

#### Scenario: additionalSlots extend the elements list

- GIVEN `DotsAlbumSpreadPage.polaroidCollage(..., photoPaths: [6 paths], additionalSlots: [PolaroidSlotPosition(...), PolaroidSlotPosition(...)])`
- WHEN built
- THEN `elements` has length 8

#### Scenario: individuales and otros produce identical coordinates

- GIVEN two calls to `polaroidCollage` — one with `type: individuales` and one with `type: otros` — using identical photoPaths and `applyOtrosGradient: false`
- WHEN both are built
- THEN the `x`, `y`, `width`, `height`, and `angleDegrees` fields of corresponding elements are equal

---

### Requirement: R5 — AlbumCollageContent value object

`AlbumCollageContent` MUST be an immutable value object with fields:
`photoPaths` (List\<String\>), `applyOtrosGradient` (bool, default `false`),
`additionalSlots` (List\<PolaroidSlotPosition\>, default `const []`). It MUST
implement value equality and hashCode.

#### Scenario: AlbumCollageContent equality

- GIVEN two `AlbumCollageContent` instances with identical field values
- WHEN compared with `==`
- THEN they are equal and share the same hashCode

---

### Requirement: R6 — PolaroidSlotPosition value object

`PolaroidSlotPosition` MUST be an immutable value object carrying: `x`, `y`,
`width`, `height`, `angleDegrees` (all double), `gradientRtl` (bool), and the four
bleed flags (`bleedLeft`, `bleedRight`, `bleedTop`, `bleedBottom`, all bool). It
MUST implement value equality and hashCode. It has the same geometric shape as
`DotsPolaroidElement` minus `assetPath`.

#### Scenario: PolaroidSlotPosition constructs with all fields

- GIVEN `PolaroidSlotPosition(x: 95.0, y: 120.0, width: 306.14, height: 379.84, angleDegrees: 0, gradientRtl: false, bleedLeft: false, bleedRight: false, bleedTop: false, bleedBottom: false)`
- WHEN constructed
- THEN no exception is thrown and all fields are accessible

---

### Requirement: R7 — buildPolaroidCollagePageFor builder

A top-level function `buildPolaroidCollagePageFor(DotsAlbumType type, AlbumCollageContent content, {required int pageNumber, required String contextLabelValue})` MUST exist and MUST return a single `DotsAlbumSpreadPage`. The returned page's `header.centerLabel` MUST equal `contextLabelValue`. The function MUST produce geometry-identical output for `individuales` and `otros` when `applyOtrosGradient` is `false`; when `applyOtrosGradient` is `true`, only slot polar-2 differs (carries `gradientRtl: true`).

#### Scenario: builder returns a DotsAlbumSpreadPage with correct header

- GIVEN `buildPolaroidCollagePageFor(DotsAlbumType.individuales, AlbumCollageContent(photoPaths: [6 paths]), pageNumber: 6, contextLabelValue: '2024')`
- WHEN called
- THEN the result is a `DotsAlbumSpreadPage`
- AND `result.header.centerLabel` equals `'2024'`

#### Scenario: builder output for individuales and otros is geometry-identical

- GIVEN two calls to `buildPolaroidCollagePageFor` with `individuales` and `otros` and identical content except `applyOtrosGradient: false`
- WHEN both are called
- THEN corresponding elements have equal `x`, `y`, `width`, `height`, and `angleDegrees`

---

### Requirement: R8 — Renderer dispatch

Both `dots_renderer.dart` and `isolate_synthesis.dart` MUST handle
`DotsPolaroidElement` inside the shared `buildAlbumSpreadPage` helper via a single
new `_buildPolaroidElement(...)` arm in the `_buildElement` switch. Neither
site MUST duplicate polaroid rendering logic. After adding this arm, `dart analyze`
MUST report no non-exhaustive pattern match errors.

#### Scenario: polaroid page renders without error via main isolate path

- GIVEN a `DotsAlbumSpreadPage` built via `polaroidCollage(...)` rendered through `useIsolate: false`
- WHEN the generator is called
- THEN it produces a non-empty valid PDF byte buffer without throwing

#### Scenario: polaroid page renders without error via worker isolate path

- GIVEN the same page rendered through `useIsolate: true`
- WHEN the generator is called
- THEN it produces a non-empty valid PDF byte buffer without throwing

#### Scenario: sealed switch remains exhaustive after adding DotsPolaroidElement

- GIVEN the sealed `DotsElement` hierarchy updated with `DotsPolaroidElement`
- WHEN `dart analyze` is run
- THEN no non-exhaustive pattern match errors are reported

#### Scenario: both isolate paths produce output of comparable size

- GIVEN the same `DotsAlbumSpreadPage.polaroidCollage(...)` rendered through both paths
- WHEN both byte buffers are compared
- THEN both are valid PDFs
- AND their sizes are within 20% of each other

---

### Requirement: R9 — Backwards compatibility

All slice-1 and slice-2 tests MUST pass without modification after this slice is
applied. `DotsPolaroidElement` MUST NOT affect any existing element type or switch
arm. All new public symbols MUST be re-exported from `lib/dots_pdf.dart`.

#### Scenario: all slice-1 and slice-2 tests pass unchanged

- GIVEN the test suites from album-type-foundation and album-type-simple-pages
- WHEN run after slice 3 is applied
- THEN all tests pass without modification

#### Scenario: new symbols are exported from dots_pdf.dart

- GIVEN `import 'package:dots_pdf/dots_pdf.dart'`
- WHEN code references `DotsPolaroidElement`, `AlbumCollageContent`, `PolaroidSlotPosition`, and `buildPolaroidCollagePageFor`
- THEN no import error is produced

---

## Acceptance Test List

**DotsPolaroidElement model** (`test/config/dots_polaroid_element_test.dart`):
- `DotsPolaroidElement — constructs with all fields and exposes them correctly`
- `DotsPolaroidElement — two instances with same fields are equal`
- `DotsPolaroidElement — two instances with same fields have equal hashCode`
- `DotsPolaroidElement — instances differing in angleDegrees are not equal`
- `DotsPolaroidElement — gradientRtl defaults to false`

**Rendering** (`test/render/polaroid_collage_test.dart`):
- `PolaroidCollage — rotation angle equals angleDegrees * pi / 180`
- `PolaroidCollage — inner photo dimensions derived from hardcoded 5.5/5.5/5.5/6.5 mm borders`
- `PolaroidCollage — outer container fill is white`
- `PolaroidCollage — gradientRtl=true applies LinearGradient right→left 100%→15%`
- `PolaroidCollage — gradientRtl=false applies no gradient`
- `PolaroidCollage — useIsolate=false produces a valid PDF`
- `PolaroidCollage — useIsolate=true produces a valid PDF`
- `PolaroidCollage — both isolate paths produce output within 20% size tolerance`

**Factory and builder** (`test/api/build_polaroid_collage_page_test.dart`):
- `polaroidCollage — 6 photoPaths produces 6 DotsPolaroidElement instances`
- `polaroidCollage — additionalSlots extends elements list to 8`
- `polaroidCollage — polar-2 gradientRtl=true when applyOtrosGradient=true`
- `polaroidCollage — polar-2 gradientRtl=false when applyOtrosGradient=false`
- `polaroidCollage — all other slots have gradientRtl=false when applyOtrosGradient=true`
- `polaroidCollage — individuales and otros produce identical element coordinates`
- `buildPolaroidCollagePageFor — returns DotsAlbumSpreadPage with header.centerLabel equal to contextLabelValue`
- `buildPolaroidCollagePageFor — individuales and otros geometry is identical when applyOtrosGradient=false`

**Value objects** (`test/api/build_polaroid_collage_page_test.dart`):
- `AlbumCollageContent — two instances with same fields are equal`
- `PolaroidSlotPosition — constructs with all fields and exposes them correctly`

**Backwards compatibility**:
- `dart analyze — sealed DotsElement switch remains exhaustive after DotsPolaroidElement`
- `DotsAlbumSpreadPage — slice-1 and slice-2 tests pass unmodified`

---

## Known Gaps and Deferred Items

- **polar-4 and polar-6 coordinates** are LOW-confidence approximations (±2 mm visual drift). Documented in dartdoc with confidence caveat.
- **polar-7 and polar-8** have no documented coordinates. The default ships 6 slots; callers who measure the source files MAY supply them via `additionalSlots`. The design target of 8 slots requires caller-supplied data.
- **Bleed handling for polar-2** (`bleedLeft: true` at +8°): the rotated AABB extends past the left trim edge. Correct rendering relies on the page format including the 3 mm bleed band; no additional spec behavior is defined here.
