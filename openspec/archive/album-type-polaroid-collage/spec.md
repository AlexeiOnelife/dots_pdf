# Specification: album-type-polaroid-collage (slice 3 of 5)

**Status:** Complete
**Slice:** 3 of 5
**Depends on:** album-type-simple-pages (archived), album-type-foundation (archived)

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

---

### Requirement: R3 — Gradient overlay

When `DotsPolaroidElement.gradientRtl` is `true`, the renderer MUST paint a
`pw.LinearGradient` mask over the inner photo. The gradient MUST be composed
inside the un-rotated coordinate frame (before the `pw.Transform.rotate` wraps
the composition). When `gradientRtl` is `false`, no gradient is applied. The
gradient effect is: right edge (100% photo visible) fading to left edge (15%
photo visible via 85% white wash).

---

### Requirement: R4 — DotsAlbumSpreadPage.polaroidCollage factory

`DotsAlbumSpreadPage.polaroidCollage(...)` MUST accept: `type` (DotsAlbumType),
`pageNumber` (int), `contextLabelValue` (String), `photoPaths` (List\<String\>, 6–8
items), `applyOtrosGradient` (bool, default `false`), `additionalSlots`
(List\<PolaroidSlotPosition\>, default `const []`). It MUST return a
`DotsAlbumSpreadPage` whose `elements` list contains exactly
`photoPaths.length + additionalSlots.length` `DotsPolaroidElement` instances. The
first 6 elements MUST be placed at the documented polar-1…polar-6 coordinates from
the default slots table. When `applyOtrosGradient: true`, the element for
slot polar-2 MUST carry `gradientRtl: true`; all other slots MUST carry
`gradientRtl: false`.

---

### Requirement: R5 — AlbumCollageContent value object

`AlbumCollageContent` MUST be an immutable value object with fields:
`photoPaths` (List\<String\>), `applyOtrosGradient` (bool, default `false`),
`additionalSlots` (List\<PolaroidSlotPosition\>, default `const []`). It MUST
implement value equality and hashCode.

---

### Requirement: R6 — PolaroidSlotPosition value object

`PolaroidSlotPosition` MUST be an immutable value object carrying: `x`, `y`,
`width`, `height`, `angleDegrees` (all double), `gradientRtl` (bool), and the four
bleed flags (`bleedLeft`, `bleedRight`, `bleedTop`, `bleedBottom`, all bool). It
MUST implement value equality and hashCode. It has the same geometric shape as
`DotsPolaroidElement` minus `assetPath`.

---

### Requirement: R7 — buildPolaroidCollagePageFor builder

A top-level function `buildPolaroidCollagePageFor(DotsAlbumType type, AlbumCollageContent content, {required int pageNumber, required String contextLabelValue})` MUST exist and MUST return a single `DotsAlbumSpreadPage`. The returned page's `header.centerLabel` MUST equal `contextLabelValue`. The function MUST produce geometry-identical output for `individuales` and `otros` when `applyOtrosGradient` is `false`; when `applyOtrosGradient` is `true`, only slot polar-2 differs (carries `gradientRtl: true`).

---

### Requirement: R8 — Renderer dispatch

Both `dots_renderer.dart` and `isolate_synthesis.dart` MUST handle
`DotsPolaroidElement` inside the shared `buildAlbumSpreadPage` helper via a single
new `_buildPolaroidElement(...)` arm in the `_buildElement` switch. Neither
site MUST duplicate polaroid rendering logic. After adding this arm, `dart analyze`
MUST report no non-exhaustive pattern match errors.

---

### Requirement: R9 — Backwards compatibility

All slice-1 and slice-2 tests MUST pass without modification after this slice is
applied. `DotsPolaroidElement` MUST NOT affect any existing element type or switch
arm. All new public symbols MUST be re-exported from `lib/dots_pdf.dart`.

---

## Default Slot Coordinates

The implementation ships with 6 documented polaroid slot positions. Caller-supplied
`additionalSlots` can extend this to 8 or more. The default slots are:

- **polar-1**: x ≈ 21mm, y ≈ 18mm, rotation ≈ -2.5°, confidence MEDIUM
- **polar-2**: x ≈ 0mm, y ≈ 120mm, rotation ≈ +8° (bleeds left), confidence MEDIUM
- **polar-3**: x ≈ -5mm, y ≈ 18mm, rotation ≈ +4°, confidence MEDIUM
- **polar-4**: x ≈ -5mm, y ≈ 35mm, rotation ≈ -2.5°, confidence LOW (±2mm visual drift)
- **polar-5**: x ≈ 48.5mm, y ≈ 69mm, rotation ≈ -3.5°, confidence MEDIUM
- **polar-6**: x ≈ 95mm, y ≈ 120mm, rotation ≈ 0° (UNKNOWN in source; defaulted), confidence LOW

---

## Known Deferred Items

- **polar-6 true rotation** measured from InDesign source (currently 0°).
- **polar-7 and polar-8 coordinates** for the design-target 8-slot layout; callers may supply via `additionalSlots`.
- **Rendering tests for gradient parameters, isolate parity, and frame geometry** (design marked as optional but spec listed as mandatory; documented as follow-up).
- **Inter Semibold font role** (carried from slice 2).
