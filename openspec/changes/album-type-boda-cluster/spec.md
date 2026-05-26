# Specification: album-type-boda-cluster (Slice 6)

**Status:** In Progress
**Slice:** 6 (boda p.3 — "Antes de empezar el viaje")
**Depends on:** slices 1–5 (all archived)

---

## Purpose

Delivers the "Antes de empezar el viaje" decorative cluster spread for
`DotsAlbumType.boda` (p.3). Introduces `DotsClusterPhotoElement`,
`AlbumBodaClusterContent`, `DotsAlbumSpreadPage.bodaCluster(...)`, and
`buildBodaClusterPageFor(...)`. The 7-photo cluster layout is library-locked;
photo content is caller-supplied.

---

## Requirements

### Requirement: R1 — DotsClusterPhotoElement model

`DotsClusterPhotoElement` MUST be a sealed subtype of `DotsElement` with fields:
`x` (double, pt), `y` (double, pt), `assetPath` (String), `width` (double, pt),
`height` (double, pt), `opacityGradientStart` (double, 0.0–1.0),
`opacityGradientEnd` (double, 0.0–1.0), `opacityGradientDirection`
(enum — design chooses; covers at minimum `bottomToTop` and `topToBottom`),
`gaussianFadeMm` (double, default `1.764`), `bleedLeft` (bool, default `false`),
`bleedRight` (bool, default `false`), `bleedTop` (bool, default `false`),
`bleedBottom` (bool, default `false`). The type MUST implement value equality
(`==` and `hashCode`) based on all fields, including `assetPath`. It MUST be
constructible via named parameters in a single constructor.

#### Scenario: DotsClusterPhotoElement constructs with all fields

- GIVEN `DotsClusterPhotoElement(x: 268.3, y: -22.1, assetPath: 'photo1.jpg', width: 77.9, height: 96.0, opacityGradientStart: 1.0, opacityGradientEnd: 0.1, opacityGradientDirection: GradientDirection.bottomToTop, gaussianFadeMm: 1.764, bleedLeft: false, bleedRight: false, bleedTop: true, bleedBottom: false)`
- WHEN constructed
- THEN no exception is thrown AND all field values are accessible and equal to supplied values

#### Scenario: DotsClusterPhotoElement equality and hashCode

- GIVEN two `DotsClusterPhotoElement` instances constructed with identical field values
- WHEN compared with `==`
- THEN they are equal AND their `hashCode` values are equal

#### Scenario: DotsClusterPhotoElement inequality when assetPath differs

- GIVEN two `DotsClusterPhotoElement` instances that differ only in `assetPath`
- WHEN compared with `==`
- THEN they are NOT equal

#### Scenario: gaussianFadeMm defaults to 1.764

- GIVEN `DotsClusterPhotoElement(x: 0, y: 0, assetPath: 'a.jpg', width: 50.0, height: 60.0, opacityGradientStart: 1.0, opacityGradientEnd: 1.0, opacityGradientDirection: GradientDirection.topToBottom)` without explicit `gaussianFadeMm`
- WHEN constructed
- THEN `gaussianFadeMm` equals `1.764`

#### Scenario: bleed flags default to false

- GIVEN `DotsClusterPhotoElement` constructed without explicit bleed flag values
- WHEN constructed
- THEN all four bleed flags are `false`

---

### Requirement: R2 — Cluster photo rendering

For any `DotsClusterPhotoElement` in a `DotsAlbumSpreadPage.elements` list, the
renderer MUST:
1. Decode the photo from `assetPath` via `bytesResolver`.
2. Apply an opacity gradient from `opacityGradientStart` to `opacityGradientEnd`
   along `opacityGradientDirection`.
3. Apply a Gaussian edge fade of width `gaussianFadeMm` around the photo boundary.
4. Position the result at `(x, y)` in PDF pt, sized `width × height`.

On decode failure, the renderer MUST silently skip the element and invoke the
`onPhotoFailure` callback with the failing `assetPath`.

#### Scenario: cluster element rendered at correct position and size

- GIVEN a `DotsClusterPhotoElement` with `x: 268.3`, `y: -22.1`, `width: 77.9`, `height: 96.0`
- WHEN rendered
- THEN the element is placed at `(268.3, -22.1)` pt, sized `77.9 × 96.0` pt

#### Scenario: slot 1 renders with bottom-to-top gradient 100%→10%

- GIVEN a `DotsClusterPhotoElement` with `opacityGradientStart: 1.0`, `opacityGradientEnd: 0.1`, `opacityGradientDirection: bottomToTop`
- WHEN rendered
- THEN the bottom edge is at full opacity and the top edge is at 10% opacity

#### Scenario: slots 2/3/4 render at full opacity (no gradient)

- GIVEN a `DotsClusterPhotoElement` with `opacityGradientStart: 1.0`, `opacityGradientEnd: 1.0`
- WHEN rendered
- THEN the photo renders at uniform full opacity with no gradient visible

#### Scenario: decode failure skips element and fires onPhotoFailure

- GIVEN a `DotsClusterPhotoElement` whose `assetPath` cannot be decoded
- WHEN the page is rendered
- THEN no widget is emitted for that element
- AND `onPhotoFailure` is called with the failing `assetPath`
- AND all other elements on the page continue to render

---

### Requirement: R3 — Pre-rasterization cache for cluster photos

The renderer MUST maintain a process-wide cache for cluster photo rasterizations,
keyed by `(assetPath, width, height, opacityGradientStart, opacityGradientEnd,
opacityGradientDirection, gaussianFadeMm)`. Rendering N cluster elements with
the same key combination MUST produce exactly ONE rasterization. A
`@visibleForTesting` reset hook MUST exist (`resetClusterPhotoCacheForTest` or
equivalent) that clears the cache, allowing tests to isolate state between runs.

#### Scenario: cache hit for identical key tuple

- GIVEN the cluster photo cache has been reset
- AND two `DotsClusterPhotoElement` instances with identical `(assetPath, width, height, opacityGradientStart, opacityGradientEnd, opacityGradientDirection, gaussianFadeMm)` but different `(x, y)` positions
- WHEN both are rendered in the same process
- THEN the rasterization function is invoked exactly once

#### Scenario: cache miss when assetPath differs

- GIVEN the cache has been reset
- AND two `DotsClusterPhotoElement` instances that differ only in `assetPath`
- WHEN both are rendered
- THEN the rasterization function is invoked twice

#### Scenario: cache reset hook clears state between tests

- GIVEN the cache has been populated by a prior render
- WHEN the reset hook is called
- THEN a subsequent render of the same element triggers a fresh rasterization

---

### Requirement: R4 — AlbumBodaClusterContent value object

`AlbumBodaClusterContent` MUST be an immutable value object with fields:
`photoPaths` (`List<String>`, exactly 7 items enforced at factory),
`title` (String, default `"Antes de empezar"`),
`titleItalicLine` (String, default `"el viaje"`),
`body` (String). It MUST implement value equality (`==` and `hashCode`) based on
all fields, using list equality on `photoPaths`.

#### Scenario: AlbumBodaClusterContent constructs with defaults

- GIVEN `AlbumBodaClusterContent(photoPaths: [7 paths], body: 'lorem')`
- WHEN constructed
- THEN `title` equals `"Antes de empezar"` AND `titleItalicLine` equals `"el viaje"`

#### Scenario: AlbumBodaClusterContent equality including list equality on photoPaths

- GIVEN two `AlbumBodaClusterContent` instances with identical field values and identical photoPaths lists
- WHEN compared with `==`
- THEN they are equal AND their `hashCode` values are equal

#### Scenario: AlbumBodaClusterContent inequality when photoPaths differ

- GIVEN two `AlbumBodaClusterContent` instances that differ only in one entry of `photoPaths`
- WHEN compared with `==`
- THEN they are NOT equal

---

### Requirement: R5 — DotsAlbumSpreadPage.bodaCluster factory

`DotsAlbumSpreadPage.bodaCluster(type, pageNumber, contextLabelValue, content)`
MUST accept a `DotsAlbumType`, an `int pageNumber`, a `String contextLabelValue`,
and an `AlbumBodaClusterContent`. It MUST return a `DotsAlbumSpreadPage` whose
`elements` list contains exactly 10 entries:
- 7 `DotsClusterPhotoElement` instances, each with `assetPath` matching the
  corresponding `content.photoPaths[i]`, geometry from `kBodaClusterLayout[i]`,
  and per-slot gradient parameters from `kBodaClusterLayout[i]`.
- 2 `DotsTextElement` instances: title line 1 (`content.title`, P22 Mackinac
  medium 23pt/27.6pt) and title line 2 (`content.titleItalicLine`, P22 Mackinac
  medium italic 23pt/27.6pt).
- 1 `DotsTextBlockElement` for `content.body` (Inter Book 9pt, 95 mm wide).

The `header.leftPageNumber` MUST equal `'$pageNumber'`.
The `header.rightPageNumber` MUST equal `'${pageNumber + 1}'`.
The `header.centerLabel` MUST equal `contextLabelValue`.

The factory MUST throw `ArgumentError` for any `type != DotsAlbumType.boda`.
The factory MUST throw `RangeError` if `content.photoPaths.length != 7`, before
any element is constructed.

#### Scenario: bodaCluster factory produces 10 elements

- GIVEN `DotsAlbumSpreadPage.bodaCluster(type: DotsAlbumType.boda, pageNumber: 3, contextLabelValue: 'Ana & Luis', content: AlbumBodaClusterContent(photoPaths: [7 valid paths], body: 'lorem'))`
- WHEN constructed
- THEN `page.elements.length` equals `10`
- AND exactly 7 elements are `DotsClusterPhotoElement` instances
- AND exactly 2 elements are `DotsTextElement` instances
- AND exactly 1 element is a `DotsTextBlockElement`

#### Scenario: each cluster element assetPath matches photoPaths[i]

- GIVEN `bodaCluster` called with `photoPaths: ['p0.jpg', 'p1.jpg', ..., 'p6.jpg']`
- WHEN the `elements` list is inspected
- THEN `clusterElements[i].assetPath` equals `photoPaths[i]` for every i in 0..6

#### Scenario: header conforms to spread convention

- GIVEN `bodaCluster(pageNumber: 3, contextLabelValue: 'Ana & Luis', ...)`
- WHEN `page.header` is read
- THEN `header.leftPageNumber` equals `'3'`
- AND `header.rightPageNumber` equals `'4'`
- AND `header.centerLabel` equals `'Ana & Luis'`

#### Scenario: factory throws ArgumentError for non-boda type

- GIVEN `DotsAlbumSpreadPage.bodaCluster(type: DotsAlbumType.parejas, ...)`
- WHEN called
- THEN an `ArgumentError` is thrown

#### Scenario: factory throws RangeError for photoPaths length != 7

- GIVEN `AlbumBodaClusterContent(photoPaths: [6 paths], body: 'lorem')`
- WHEN `bodaCluster` is called with this content
- THEN a `RangeError` is thrown before any element is constructed

#### Scenario: factory throws RangeError for 8 photoPaths

- GIVEN `AlbumBodaClusterContent(photoPaths: [8 paths], body: 'lorem')`
- WHEN `bodaCluster` is called with this content
- THEN a `RangeError` is thrown

---

### Requirement: R6 — kBodaClusterLayout per-slot gradient table

The library-private constant `kBodaClusterLayout` MUST carry per-slot geometry
and gradient parameters for exactly 7 slots derived from `extracted_coordinates.md`
§1. Each slot's parameters MUST conform to:

| Slot | x (mm)  | y (mm) | w (mm) | h (mm) | gradientStart | gradientEnd | gradientDirection | bleedTop |
|------|---------|--------|--------|--------|---------------|-------------|-------------------|----------|
| 1    | 94.6    | −7.8   | 27.5   | 33.9   | 1.0           | 0.1         | bottomToTop       | true     |
| 2    | 86.3    | 59.6   | 5.0    | 5.8    | 1.0           | 1.0         | topToBottom       | false    |
| 3    | 90.0    | 31.4   | 20.3   | 24.7   | 1.0           | 1.0         | topToBottom       | false    |
| 4    | 87.4    | 71.3   | 12.8   | 15.2   | 1.0           | 1.0         | topToBottom       | false    |
| 5    | 103.1   | 88.9   | 13.7   | 16.2   | 1.0           | 0.3         | topToBottom       | false    |
| 6    | 90.4    | 103.3  | 9.0    | 10.6   | 1.0           | 0.3         | topToBottom       | false    |
| 7    | 103.1   | 116.6  | 7.8    | 9.2    | 1.0           | 0.0         | topToBottom       | false    |

All slots: `gaussianFadeMm = 1.764`. Coordinates are right-page-relative (gutter
origin); factory translates to spread coordinates by adding 203 mm to each x.

#### Scenario: slot 1 gradient matches kBodaClusterLayout

- GIVEN a `DotsAlbumSpreadPage` produced by `bodaCluster(...)`
- WHEN the first cluster element is inspected
- THEN `opacityGradientStart` equals `1.0`, `opacityGradientEnd` equals `0.1`, `opacityGradientDirection` is `bottomToTop`
- AND `bleedTop` is `true`

#### Scenario: slot 5 gradient is top-to-bottom 100%→30%

- GIVEN a `DotsAlbumSpreadPage` produced by `bodaCluster(...)`
- WHEN cluster element at index 4 is inspected
- THEN `opacityGradientStart` equals `1.0`, `opacityGradientEnd` equals `0.3`, `opacityGradientDirection` is `topToBottom`

#### Scenario: slot 7 gradient fades to full transparency

- GIVEN a `DotsAlbumSpreadPage` produced by `bodaCluster(...)`
- WHEN cluster element at index 6 is inspected
- THEN `opacityGradientEnd` equals `0.0`

#### Scenario: slots 2/3/4 have no gradient (full opacity both ends)

- GIVEN cluster elements at indices 1, 2, 3
- WHEN `opacityGradientStart` and `opacityGradientEnd` are read
- THEN both equal `1.0` for each of those three elements

#### Scenario: all slots have gaussianFadeMm of 1.764

- GIVEN all 7 cluster elements from a `bodaCluster` page
- WHEN `gaussianFadeMm` is read on each
- THEN all 7 equal `1.764`

---

### Requirement: R7 — buildBodaClusterPageFor builder

A top-level function `buildBodaClusterPageFor(DotsAlbumType type, AlbumBodaClusterContent content, {required int pageNumber, required String contextLabelValue})` MUST exist and MUST return a single `DotsAlbumSpreadPage`. It MUST throw `ArgumentError` for any `type != DotsAlbumType.boda` (defense-in-depth). It MUST throw `RangeError` if `content.photoPaths.length != 7` (defense-in-depth).

#### Scenario: buildBodaClusterPageFor returns DotsAlbumSpreadPage for boda

- GIVEN `buildBodaClusterPageFor(DotsAlbumType.boda, AlbumBodaClusterContent(photoPaths: [7 paths], body: 'lorem'), pageNumber: 3, contextLabelValue: 'A & B')`
- WHEN called
- THEN the return type is `DotsAlbumSpreadPage`

#### Scenario: builder throws ArgumentError for each non-boda type

- GIVEN each of `DotsAlbumType.parejas`, `hijos`, `individuales`, `otros`
- WHEN `buildBodaClusterPageFor` is called with any of these types
- THEN an `ArgumentError` is thrown

#### Scenario: builder throws RangeError for photoPaths length mismatch

- GIVEN `AlbumBodaClusterContent(photoPaths: [6 paths], body: 'x')`
- WHEN `buildBodaClusterPageFor(DotsAlbumType.boda, content, ...)` is called
- THEN a `RangeError` is thrown

---

### Requirement: R8 — Renderer dispatch

The shared `buildAlbumSpreadPage` helper's `_buildElement` switch MUST gain one
new arm for `DotsClusterPhotoElement` that calls a private
`_buildClusterPhotoElement(...)` helper. The 4 additional exhaustiveness sites
(`dots_renderer.dart` `_buildElement` for ElementsPage, `dots_renderer.dart`
`preloadAssetBytes` for ElementsPage and AlbumSpreadPage, and
`isolate_synthesis.dart` `_buildElement`) MUST each gain a `DotsClusterPhotoElement`
arm using the delegation pattern (return null or add assetPath, per site).
After all 5 arms are added, `dart analyze` MUST report no non-exhaustive pattern
match errors.

#### Scenario: bodaCluster page renders without error via main-isolate path

- GIVEN a `DotsAlbumSpreadPage` built via `buildBodaClusterPageFor(DotsAlbumType.boda, ...)` rendered through `useIsolate: false`
- WHEN the generator is called
- THEN it produces a non-empty valid PDF byte buffer without throwing

#### Scenario: bodaCluster page renders without error via worker-isolate path

- GIVEN the same page rendered through `useIsolate: true`
- WHEN the generator is called
- THEN it produces a non-empty valid PDF byte buffer without throwing

#### Scenario: sealed switch is exhaustive after adding DotsClusterPhotoElement

- GIVEN the sealed `DotsElement` hierarchy extended with `DotsClusterPhotoElement`
- WHEN `dart analyze` is run
- THEN no non-exhaustive pattern match errors are reported

#### Scenario: cluster assetPath is preloaded via preloadAssetBytes

- GIVEN a `DotsAlbumSpreadPage` containing `DotsClusterPhotoElement` instances
- WHEN `preloadAssetBytes` is called on the page
- THEN each `element.assetPath` is added to the paths list

---

### Requirement: R9 — Spread-width pageSize contract

The boda cluster page renders as a single `pw.Page` whose format width MUST be at
least 406 mm (the spread width). Callers MUST set `DotsTemplate.pageSize.width >= 406 mm`.
A render-time logger warning MUST be emitted if this contract is violated. This
mirrors the slice-5 photo-arc pattern.

#### Scenario: render-time warning emitted when pageSize.width < 406 mm

- GIVEN a boda cluster page rendered with `DotsTemplate.pageSize.width` set to 203 mm
- WHEN the generator is called
- THEN a logger warning is emitted indicating the insufficient page width

---

### Requirement: R10 — Backwards compatibility and public exports

All slice-1/2/3/4/5 tests MUST pass without modification after this slice is
applied. `DotsClusterPhotoElement` MUST NOT affect any existing element type or
switch arm. All new public symbols MUST be re-exported from `lib/dots_pdf.dart`:
`DotsClusterPhotoElement`, `AlbumBodaClusterContent`, `buildBodaClusterPageFor`.

#### Scenario: all prior slice tests pass unchanged

- GIVEN the slice-6 changes applied to the codebase
- WHEN all slice-1/2/3/4/5 test files are run without modification
- THEN all tests pass

#### Scenario: new symbols exported from lib/dots_pdf.dart

- GIVEN `import 'package:dots_pdf/dots_pdf.dart'`
- WHEN code references `DotsClusterPhotoElement`, `AlbumBodaClusterContent`, and `buildBodaClusterPageFor`
- THEN no import error is produced

---

## 7-Slot Canonical Layout (kBodaClusterLayout)

Source: `extracted_coordinates.md` §1. Coordinates are right-page-relative (gutter
= x 0). Factory adds 203 mm to each x when composing spread coordinates.
All slots: `gaussianFadeMm = 1.764`, rotation = 0°.

| Slot | x (mm) | y (mm) | w (mm) | h (mm) | gradientStart | gradientEnd | direction    | bleedTop |
|------|--------|--------|--------|--------|---------------|-------------|--------------|----------|
| 1    | 94.6   | −7.8   | 27.5   | 33.9   | 1.0           | 0.1         | bottomToTop  | true     |
| 2    | 86.3   | 59.6   | 5.0    | 5.8    | 1.0           | 1.0         | topToBottom  | false    |
| 3    | 90.0   | 31.4   | 20.3   | 24.7   | 1.0           | 1.0         | topToBottom  | false    |
| 4    | 87.4   | 71.3   | 12.8   | 15.2   | 1.0           | 1.0         | topToBottom  | false    |
| 5    | 103.1  | 88.9   | 13.7   | 16.2   | 1.0           | 0.3         | topToBottom  | false    |
| 6    | 90.4   | 103.3  | 9.0    | 10.6   | 1.0           | 0.3         | topToBottom  | false    |
| 7    | 103.1  | 116.6  | 7.8    | 9.2    | 1.0           | 0.0         | topToBottom  | false    |
