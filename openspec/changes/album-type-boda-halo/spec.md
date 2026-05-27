# Specification: album-type-boda-halo (Slice 7)

**Status:** Draft
**Slice:** 7 (boda p.4 — "Boda de Nombre&Nombre" title spread)
**Depends on:** slices 1–6 (all archived)

---

## Purpose

Delivers the "Boda de Nombre&Nombre" radial halo title spread for
`DotsAlbumType.boda` (p.4). Introduces `DotsRotatedPhotoElement`,
`kBodaHaloLayout` (10-slot library-private const), `AlbumBodaHaloContent`,
`DotsAlbumSpreadPage.bodaHalo(...)`, and `buildBodaHaloPageFor(...)`. Reuses
`DotsOvalQrElement` from slice 5 for the 2 gutter QR cards.

---

## Requirements

### Requirement: R1 — DotsRotatedPhotoElement model

`DotsRotatedPhotoElement` MUST be a sealed subtype of `DotsElement` with the
following fields:

- `x` (double, pt) — unrotated top-left x (from super)
- `y` (double, pt) — unrotated top-left y (from super)
- `assetPath` (String) — photo asset path
- `width` (double, pt) — unrotated bounding width
- `height` (double, pt) — unrotated bounding height
- `angleDegrees` (double) — clockwise rotation in degrees (signed; positive = clockwise)
- `cornerRadiusMm` (double, default `6.0`) — corner radius in mm applied via rounded-rect clip
- `bleedLeft` (bool, default `false`)
- `bleedRight` (bool, default `false`)
- `bleedTop` (bool, default `false`)
- `bleedBottom` (bool, default `false`)

The type MUST implement value equality (`==` and `hashCode`) over all fields. It
MUST be constructible via named parameters in a single constructor.

#### Scenario: S1 — DotsRotatedPhotoElement constructs with all fields

- GIVEN `DotsRotatedPhotoElement(x: 37.4, y: 266.5, assetPath: 'a.jpg', width: 95.0, height: 131.4, angleDegrees: 3.2, cornerRadiusMm: 6.0, bleedLeft: false, bleedRight: false, bleedTop: false, bleedBottom: false)`
- WHEN constructed
- THEN no exception is thrown
- AND all field values are accessible and equal to the supplied values

#### Scenario: S2 — DotsRotatedPhotoElement equality and hashCode

- GIVEN two `DotsRotatedPhotoElement` instances constructed with identical field values
- WHEN compared with `==`
- THEN they are equal
- AND their `hashCode` values are equal

#### Scenario: S3 — DotsRotatedPhotoElement inequality when angleDegrees differs

- GIVEN two `DotsRotatedPhotoElement` instances that differ only in `angleDegrees`
- WHEN compared with `==`
- THEN they are NOT equal

#### Scenario: S4 — cornerRadiusMm defaults to 6.0

- GIVEN `DotsRotatedPhotoElement(x: 0, y: 0, assetPath: 'a.jpg', width: 95.0, height: 131.4, angleDegrees: 20.7)` without explicit `cornerRadiusMm`
- WHEN constructed
- THEN `cornerRadiusMm` equals `6.0`

#### Scenario: S5 — bleed flags default to false

- GIVEN `DotsRotatedPhotoElement` constructed without explicit bleed flag values
- WHEN constructed
- THEN all four bleed flags are `false`

---

### Requirement: R2 — Rotated photo rendering

For any `DotsRotatedPhotoElement` in a `DotsAlbumSpreadPage.elements` list, the
renderer MUST:

1. Decode the photo from `assetPath` via `bytesResolver`.
2. Clip the photo to a rounded rectangle via `pw.ClipRRect` with `borderRadius`
   derived from `element.cornerRadiusMm` converted to pt.
3. Wrap the clipped photo in `pw.Transform.rotate` with angle
   `element.angleDegrees * pi / 180` around `pw.Alignment.center`.
4. Position the resulting widget at `(element.x, element.y)` in PDF pt, sized
   `element.width × element.height`.

On decode failure, the renderer MUST silently skip the element and invoke the
`onPhotoFailure` callback with the failing `assetPath`.

The element MUST NOT apply any white frame or outer border. There is no gradient
or opacity effect on this element type.

#### Scenario: S6 — rotation angle applied correctly

- GIVEN a `DotsRotatedPhotoElement(angleDegrees: 68.3, ...)`
- WHEN rendered
- THEN the produced `pw.Transform.rotate` angle equals `68.3 * pi / 180.0` radians (approximately 1.1920 radians)

#### Scenario: S7 — negative angle applied correctly

- GIVEN a `DotsRotatedPhotoElement(angleDegrees: -37.2, ...)`
- WHEN rendered
- THEN the produced `pw.Transform.rotate` angle equals `-37.2 * pi / 180.0` radians (approximately −0.6492 radians)

#### Scenario: S8 — corner radius applied as rounded-rect clip

- GIVEN a `DotsRotatedPhotoElement(cornerRadiusMm: 6.0, width: 95.0, height: 131.4, ...)`
- WHEN rendered
- THEN the photo is clipped via `pw.ClipRRect` with a border radius corresponding to `6.0 mm` in pt

#### Scenario: S9 — decode failure skips element and fires onPhotoFailure

- GIVEN a `DotsRotatedPhotoElement` whose `assetPath` cannot be decoded
- WHEN the page is rendered
- THEN no widget is emitted for that element
- AND `onPhotoFailure` is called with the failing `assetPath`
- AND all other elements on the page continue to render

---

### Requirement: R3 — kBodaHaloLayout 10-slot const

The library-private constant `kBodaHaloLayout` MUST contain exactly 10 entries,
each carrying the unrotated top-left `(x, y)` in pt, uniform unrotated dimensions
`width = 95.0 pt` (33.5 mm) and `height = 131.4 pt` (46.4 mm), a signed
`angleDegrees`, and per-slot bleed flags.

Slots R1–R5 are right-page-relative (x measured from gutter); the factory translates
them by adding 203 mm to each x when composing spread coordinates. Slots L1–L5 are
left-page-relative (x measured from left-page left trim edge); they are used without
translation in spread coordinates.

Right-page slots MUST carry positive `angleDegrees` matching the extracted post-rotation
AABB table (§2, `extracted_coordinates.md`). Left-page slots MUST carry the corresponding
negated angles (mirror of R-slots).

The AABB positions stored in the layout are the post-rotation axis-aligned bounding-box
top-left coordinates derived from the PDF content stream. The element receives these as
its `(x, y)` fields; the renderer positions the widget at those coordinates and then
applies the rotation around the geometric center. This is MEDIUM-confidence data
(accuracy ±0.5 mm); a dartdoc caveat MUST be included on the constant noting the
MEDIUM confidence and deferred InDesign source verification.

Slot R5 and its mirror L5 MUST set `bleedBottom: true` (both extend below the page trim).

The conformant per-slot parameters are:

| Slot | Page | x (pt) | y (pt) | angleDegrees | bleedBottom |
|------|------|--------|--------|--------------|-------------|
| R1   | right | 37.4   | 266.2  | +3.2         | false |
| R2   | right | 157.1  | 303.8  | +20.7        | false |
| R3   | right | 264.7  | 386.1  | +37.2        | false |
| R4   | right | 345.5  | 507.0  | +55.2        | false |
| R5   | right | 398.2  | 648.1  | +68.3        | true  |
| L1   | left  | 431.4  | 260.0  | −3.2         | false |
| L2   | left  | 314.7  | 295.6  | −20.7        | false |
| L3   | left  | 184.8  | 377.7  | −37.2        | false |
| L4   | left  | 37.7   | 497.5  | −55.2        | false |
| L5   | left  | 18.7   | 651.0  | −68.3        | true  |

Note: pt values above are derived from the mm AABB values in `extracted_coordinates.md`
§2 using the 2.834645669 pt/mm conversion. Design phase MUST verify or refine these
conversions and compute the precise unrotated top-left from AABB + angle.

#### Scenario: S10 — kBodaHaloLayout has exactly 10 entries

- GIVEN `kBodaHaloLayout`
- WHEN its length is read
- THEN it equals `10`

#### Scenario: S11 — all halo slots have uniform unrotated dimensions

- GIVEN all 10 entries in `kBodaHaloLayout`
- WHEN `width` and `height` are read on each entry
- THEN every entry has `width` equal to `95.0` pt and `height` equal to `131.4` pt

#### Scenario: S12 — right-page slots carry positive angles

- GIVEN the first 5 entries in `kBodaHaloLayout` (R1–R5)
- WHEN `angleDegrees` is read on each
- THEN all values are strictly positive
- AND the values match `+3.2`, `+20.7`, `+37.2`, `+55.2`, `+68.3` in order

#### Scenario: S13 — left-page slots carry negated mirror angles

- GIVEN the last 5 entries in `kBodaHaloLayout` (L1–L5)
- WHEN `angleDegrees` is read on each
- THEN the values match `−3.2`, `−20.7`, `−37.2`, `−55.2`, `−68.3` in order

#### Scenario: S14 — R5 and L5 carry bleedBottom true

- GIVEN entries at indices 4 (R5) and 9 (L5) in `kBodaHaloLayout`
- WHEN `bleedBottom` is read
- THEN both are `true`
- AND all other entries have `bleedBottom` equal to `false`

---

### Requirement: R4 — AlbumBodaHaloContent value object

`AlbumBodaHaloContent` MUST be an immutable value object with the following fields:

- `photoPaths` (`List<String>`, exactly 10 items enforced at factory)
- `titleLine1` (String, default `'Boda de'`)
- `titleLine2` (String) — e.g. "Nombre&Nombre"
- `dateSubtitle` (String)
- `qrPayloadLeft` (String)
- `qrPayloadRight` (String)
- `qrCaptionLeftOverride` (String?, default `null`)
- `qrCaptionRightOverride` (String?, default `null`)

It MUST implement value equality (`==` and `hashCode`) over all fields, using list
equality on `photoPaths`.

#### Scenario: S15 — AlbumBodaHaloContent constructs with defaults

- GIVEN `AlbumBodaHaloContent(photoPaths: [10 paths], titleLine2: 'Ana & Luis', dateSubtitle: '12 de octubre de 2024', qrPayloadLeft: 'https://a.co/l', qrPayloadRight: 'https://a.co/r')`
- WHEN constructed
- THEN `titleLine1` equals `'Boda de'`
- AND `qrCaptionLeftOverride` is `null`
- AND `qrCaptionRightOverride` is `null`

#### Scenario: S16 — AlbumBodaHaloContent equality including list equality on photoPaths

- GIVEN two `AlbumBodaHaloContent` instances with identical field values and identical `photoPaths` lists
- WHEN compared with `==`
- THEN they are equal
- AND their `hashCode` values are equal

#### Scenario: S17 — AlbumBodaHaloContent inequality when photoPaths differ

- GIVEN two `AlbumBodaHaloContent` instances that differ only in one entry of `photoPaths`
- WHEN compared with `==`
- THEN they are NOT equal

---

### Requirement: R5 — DotsAlbumSpreadPage.bodaHalo factory

`DotsAlbumSpreadPage.bodaHalo(type, pageNumber, contextLabelValue, content)` MUST
accept a `DotsAlbumType`, an `int pageNumber`, a `String contextLabelValue`, and an
`AlbumBodaHaloContent`. It MUST return a `DotsAlbumSpreadPage` whose `elements`
list contains exactly 15 entries:

- 10 `DotsRotatedPhotoElement` instances, each with `assetPath` matching the
  corresponding `content.photoPaths[i]` and geometry from `kBodaHaloLayout[i]`.
  R-slots (indices 0–4) have their x translated by +203 mm (converted to pt) to
  spread coordinates before assignment.
- 2 `DotsOvalQrElement` instances for the gutter QR cards, positioned at the
  bottom-center of the spread (left QR: 27 mm left of gutter center, right QR:
  27 mm right of gutter center; both using the 25.841 × 43.127 mm oval dimensions
  from slice 5). Left QR defaults to caption `'Vuestro álbum en digital'`, right QR
  defaults to caption `'Escanea el QR para volver a ver el álbum y los vídeos'`.
  Caption overrides from `content.qrCaptionLeftOverride` / `content.qrCaptionRightOverride`
  MUST win over defaults when non-null.
- 3 `DotsTextElement` instances:
  - Title line 1: `content.titleLine1` — P22 Mackinac medium 23pt / 27.6pt leading,
    ranged left, positioned at approximately x = 19 mm, y = 43 mm on the left page.
  - Title line 2: `content.titleLine2` — P22 Mackinac medium 23pt / 27.6pt leading,
    ranged left, 5 mm below title line 1.
  - Date subtitle: `content.dateSubtitle` — P22 Mackinac book 9pt / 10.8pt, 5 mm
    below title line 2.

The `header.leftPageNumber` MUST equal `'$pageNumber'`.
The `header.rightPageNumber` MUST equal `'${pageNumber + 1}'`.
The `header.centerLabel` MUST equal `contextLabelValue`.

The factory MUST throw `ArgumentError` for any `type != DotsAlbumType.boda`.
The factory MUST throw `RangeError` if `content.photoPaths.length != 10`, before
any element is constructed.

#### Scenario: S18 — bodaHalo factory produces 15 elements

- GIVEN `DotsAlbumSpreadPage.bodaHalo(type: DotsAlbumType.boda, pageNumber: 4, contextLabelValue: 'Ana & Luis', content: AlbumBodaHaloContent(photoPaths: [10 valid paths], titleLine2: 'Ana & Luis', dateSubtitle: '12 oct 2024', qrPayloadLeft: 'l', qrPayloadRight: 'r'))`
- WHEN constructed
- THEN `page.elements.length` equals `15`
- AND exactly 10 elements are `DotsRotatedPhotoElement` instances
- AND exactly 2 elements are `DotsOvalQrElement` instances
- AND exactly 3 elements are `DotsTextElement` instances

#### Scenario: S19 — each halo element assetPath matches photoPaths[i]

- GIVEN `bodaHalo` called with `photoPaths: ['p0.jpg', 'p1.jpg', ..., 'p9.jpg']`
- WHEN the `elements` list is inspected
- THEN `rotatedPhotoElements[i].assetPath` equals `photoPaths[i]` for every i in 0..9

#### Scenario: S20 — header conforms to spread convention

- GIVEN `bodaHalo(pageNumber: 4, contextLabelValue: 'Ana & Luis', ...)`
- WHEN `page.header` is read
- THEN `header.leftPageNumber` equals `'4'`
- AND `header.rightPageNumber` equals `'5'`
- AND `header.centerLabel` equals `'Ana & Luis'`

#### Scenario: S21 — factory throws ArgumentError for non-boda type

- GIVEN `DotsAlbumSpreadPage.bodaHalo(type: DotsAlbumType.parejas, ...)`
- WHEN called
- THEN an `ArgumentError` is thrown

#### Scenario: S22 — factory throws RangeError for 9 photoPaths

- GIVEN `AlbumBodaHaloContent(photoPaths: [9 paths], ...)`
- WHEN `bodaHalo` is called with this content
- THEN a `RangeError` is thrown before any element is constructed

#### Scenario: S23 — factory throws RangeError for 11 photoPaths

- GIVEN `AlbumBodaHaloContent(photoPaths: [11 paths], ...)`
- WHEN `bodaHalo` is called with this content
- THEN a `RangeError` is thrown

#### Scenario: S24 — QR caption overrides win over defaults

- GIVEN `AlbumBodaHaloContent(..., qrCaptionLeftOverride: 'Custom left', qrCaptionRightOverride: null)`
- WHEN the factory is called and QR elements are inspected
- THEN the left `DotsOvalQrElement.caption` equals `'Custom left'`
- AND the right `DotsOvalQrElement.caption` equals the default `'Escanea el QR para volver a ver el álbum y los vídeos'`

---

### Requirement: R6 — buildBodaHaloPageFor builder

A top-level function `buildBodaHaloPageFor(DotsAlbumType type, AlbumBodaHaloContent content, {required int pageNumber, required String contextLabelValue})` MUST exist and MUST return a single `DotsAlbumSpreadPage`. It MUST throw `ArgumentError` for any `type != DotsAlbumType.boda` (defense-in-depth). It MUST throw `RangeError` if `content.photoPaths.length != 10` (defense-in-depth).

#### Scenario: S25 — buildBodaHaloPageFor returns DotsAlbumSpreadPage for boda

- GIVEN `buildBodaHaloPageFor(DotsAlbumType.boda, AlbumBodaHaloContent(photoPaths: [10 paths], titleLine2: 'A & B', dateSubtitle: 'x', qrPayloadLeft: 'l', qrPayloadRight: 'r'), pageNumber: 4, contextLabelValue: 'A & B')`
- WHEN called
- THEN the return type is `DotsAlbumSpreadPage`

#### Scenario: S26 — builder throws ArgumentError for each non-boda type

- GIVEN each of `DotsAlbumType.parejas`, `hijos`, `individuales`, `otros`
- WHEN `buildBodaHaloPageFor` is called with any of those types
- THEN an `ArgumentError` is thrown

#### Scenario: S27 — builder throws RangeError for photoPaths length mismatch

- GIVEN `AlbumBodaHaloContent(photoPaths: [9 paths], ...)`
- WHEN `buildBodaHaloPageFor(DotsAlbumType.boda, content, ...)` is called
- THEN a `RangeError` is thrown

---

### Requirement: R7 — Renderer dispatch

The shared `buildAlbumSpreadPage` helper's `_buildElement` switch MUST gain one
new arm for `DotsRotatedPhotoElement` that calls a private
`_buildRotatedPhotoElement(...)` helper. The 4 additional exhaustiveness sites
(`dots_renderer.dart` `_buildElement` for `ElementsPage`, `dots_renderer.dart`
`preloadAssetBytes` for `ElementsPage` and `AlbumSpreadPage`, and
`isolate_synthesis.dart` `_buildElement`) MUST each gain a
`DotsRotatedPhotoElement` arm following the established delegation pattern:
- `preloadAssetBytes` sites: add `element.assetPath` to the paths list.
- Renderer `_buildElement` for `ElementsPage` and `isolate_synthesis.dart`: return `null`.

`DotsOvalQrElement` is already handled at all 5 sites from slice 5 and requires no
new arms.

After all 5 arms for `DotsRotatedPhotoElement` are added, `dart analyze` MUST
report no non-exhaustive pattern match errors.

#### Scenario: S28 — bodaHalo page renders without error via main-isolate path

- GIVEN a `DotsAlbumSpreadPage` built via `buildBodaHaloPageFor(DotsAlbumType.boda, ...)` rendered through `useIsolate: false`
- WHEN the generator is called
- THEN it produces a non-empty valid PDF byte buffer without throwing

#### Scenario: S29 — bodaHalo page renders without error via worker-isolate path

- GIVEN the same page rendered through `useIsolate: true`
- WHEN the generator is called
- THEN it produces a non-empty valid PDF byte buffer without throwing

#### Scenario: S30 — sealed switch is exhaustive after adding DotsRotatedPhotoElement

- GIVEN the sealed `DotsElement` hierarchy extended with `DotsRotatedPhotoElement`
- WHEN `dart analyze` is run
- THEN no non-exhaustive pattern match errors are reported

#### Scenario: S31 — rotated photo assetPath is preloaded via preloadAssetBytes

- GIVEN a `DotsAlbumSpreadPage` containing `DotsRotatedPhotoElement` instances
- WHEN `preloadAssetBytes` is called on the page
- THEN each `element.assetPath` is added to the paths list

---

### Requirement: R8 — Spread-width pageSize contract

When a `DotsAlbumSpreadPage` containing `DotsRotatedPhotoElement` instances is
rendered, and `DotsTemplate.pageSize.width` is less than 406 mm (the spread width),
the renderer MUST emit a logger warning. This mirrors the slice-5 and slice-6 pattern.

#### Scenario: S32 — render-time warning emitted when pageSize.width < 406 mm

- GIVEN a boda halo page rendered with `DotsTemplate.pageSize.width` set to 203 mm
- WHEN the generator is called
- THEN a logger warning is emitted indicating the insufficient page width

---

### Requirement: R9 — Backwards compatibility and public exports

All slice-1/2/3/4/5/6 tests MUST pass without modification after this slice is
applied. `DotsRotatedPhotoElement` MUST NOT affect any existing element type or
switch arm. All new public symbols MUST be re-exported from `lib/dots_pdf.dart`:

- `DotsRotatedPhotoElement`
- `AlbumBodaHaloContent`
- `buildBodaHaloPageFor`

#### Scenario: S33 — all prior slice tests pass unchanged

- GIVEN the slice-7 changes applied to the codebase
- WHEN all slice-1/2/3/4/5/6 test files are run without modification
- THEN all tests pass

#### Scenario: S34 — new symbols exported from lib/dots_pdf.dart

- GIVEN `import 'package:dots_pdf/dots_pdf.dart'`
- WHEN code references `DotsRotatedPhotoElement`, `AlbumBodaHaloContent`, and `buildBodaHaloPageFor`
- THEN no import error is produced

---

## 10-Slot Canonical Layout (kBodaHaloLayout)

Source: `extracted_coordinates.md` §2. Confidence: **MEDIUM** (±0.5 mm) for all 10
slots. Right-page slot x-coordinates are page-relative from the gutter; factory adds
203 mm when composing spread coordinates. Left-page slot x-coordinates are from the
left-page left trim edge; used without translation.

All slots: unrotated `w = 33.5 mm` (95.0 pt), `h = 46.4 mm` (131.4 pt),
`cornerRadiusMm = 6.0`.

**AABB (post-rotation) positions from content stream:**

| Slot | Page  | x (mm, AABB TL) | y (mm, AABB TL) | angleDegrees | bleedBottom |
|------|-------|-----------------|-----------------|--------------|-------------|
| R1   | right | 13.2            | 93.9            | +3.2         | false       |
| R2   | right | 55.4            | 107.2           | +20.7        | false       |
| R3   | right | 93.4            | 136.2           | +37.2        | false       |
| R4   | right | 121.8           | 178.8           | +55.2        | false       |
| R5   | right | 140.5           | 228.6           | +68.3        | true        |
| L1   | left  | 152.2           | 91.7            | −3.2         | false       |
| L2   | left  | 111.0           | 104.2           | −20.7        | false       |
| L3   | left  | 65.2            | 133.2           | −37.2        | false       |
| L4   | left  | 13.3            | 175.5           | −55.2        | false       |
| L5   | left  | 6.6             | 229.6           | −68.3        | true        |

Design phase MUST convert these AABB mm values to pt and derive the unrotated
top-left offsets from the AABB positions using each slot's angle and the uniform
33.5 × 46.4 mm unrotated dimensions. The final `(x, y)` stored in `kBodaHaloLayout`
entries are the unrotated top-left in pt.

---

## Known Deferred Items

- **AABB → unrotated TL conversion** — geometric derivation is a design-phase concern
  (not a spec concern). The AABB coordinates from §2 are given here for reference;
  the constant stores the computed unrotated top-left values.
- **Anchor verification** — the InDesign anchor `(x = 37.477, y = 50.388 mm)` cannot
  be matched to the PDF stream. Deferred pending access to the source Illustrator/InDesign
  file. A dartdoc caveat on `kBodaHaloLayout` MUST document this discrepancy.
- **boda p.1, p.2, p.5** — separate work, not in scope.
