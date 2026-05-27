# Specification: album-type-gaussian-circles (Slice 4 of 5)

**Status:** Implemented
**Slice:** 4 of 5
**Depends on:** album-type-foundation (archived), album-type-simple-pages (archived), album-type-polaroid-collage (archived)
**Archive Date:** 2026-05-25

## Purpose

Delivers the decorative 14-circle cover page for `DotsAlbumType.parejas` and
`DotsAlbumType.hijos`. Introduces `DotsDecorativeCircleElement`, `AlbumCoverContent`,
`DotsAlbumSpreadPage.cover(...)`, and `buildCoverPageFor(...)`.

---

## Requirements

### Requirement: R1 — DotsDecorativeCircleElement model

`DotsDecorativeCircleElement` MUST be a sealed subtype of `DotsElement` with fields:
`x` (double, in pt), `y` (double, in pt), `diameter` (double, in pt), `colorHex`
(String), `gaussianFadeMm` (double, in mm), `bleedLeft` (bool, default `false`),
`bleedRight` (bool, default `false`), `bleedTop` (bool, default `false`),
`bleedBottom` (bool, default `false`). The type MUST implement value equality
(`==` and `hashCode`) based on all fields. It MUST be constructible using named
parameters in a single constructor.

#### Scenario: DotsDecorativeCircleElement constructs with all fields

- GIVEN `DotsDecorativeCircleElement(x: 22.68, y: 121.89, diameter: 133.23, colorHex: '#CDE7F2', gaussianFadeMm: 1.764, bleedLeft: false, bleedRight: false, bleedTop: false, bleedBottom: false)`
- WHEN constructed
- THEN no exception is thrown
- AND all field values are accessible and equal to the supplied values

#### Scenario: DotsDecorativeCircleElement equality and hashCode

- GIVEN two `DotsDecorativeCircleElement` instances constructed with identical field values
- WHEN compared with `==`
- THEN they are equal AND their `hashCode` values are equal

#### Scenario: DotsDecorativeCircleElement inequality when fields differ

- GIVEN two `DotsDecorativeCircleElement` instances that differ only in `diameter`
- WHEN compared with `==`
- THEN they are NOT equal

#### Scenario: bleed flags default to false

- GIVEN `DotsDecorativeCircleElement(x: 0, y: 0, diameter: 45.0, colorHex: '#CDE7F2', gaussianFadeMm: 1.764)`
- WHEN constructed without explicit bleed flag values
- THEN all four bleed flags (`bleedLeft`, `bleedRight`, `bleedTop`, `bleedBottom`) are `false`

---

### Requirement: R2 — Decorative-circle rendering

For any `DotsDecorativeCircleElement` in a `DotsAlbumSpreadPage.elements` list,
the renderer MUST draw a filled circle of `diameter` centered at
`(x + diameter/2, y + diameter/2)`, filled with `colorHex`, with a Gaussian edge
fade band of width `gaussianFadeMm`. The fade MUST create a soft edge where the
circle's boundary transitions from opaque to transparent. When a bleed flag is set,
the texture MUST extend past the page boundary on that edge without clipping at the
element layer.

#### Scenario: circle rendered at correct center position

- GIVEN a `DotsDecorativeCircleElement` with `x: 0.0`, `y: 0.0`, `diameter: 133.23`
- WHEN rendered
- THEN the circle center is placed at `(66.615, 66.615)` in pt

#### Scenario: bleedRight circle extends past page boundary

- GIVEN a `DotsDecorativeCircleElement` with `x` = `mm_to_pt(210)` (≈595 pt), `diameter: 133.23`, `bleedRight: true`, on a 203 mm-wide page
- WHEN rendered
- THEN the circle texture extends past the 203 mm right edge without clipping

#### Scenario: circle fill color matches colorHex

- GIVEN a `DotsDecorativeCircleElement` with `colorHex: '#CDE7F2'`
- WHEN rendered
- THEN the circle is filled with the RGB color corresponding to `#CDE7F2`

---

### Requirement: R3 — Pre-rasterization caching

The renderer MUST maintain a process-wide cache keyed by `(diameter, colorHex, gaussianFadeMm)`.
The cache MUST be populated lazily on first render of a unique key combination.
Rendering N circles with the same `(diameter, colorHex, gaussianFadeMm)` MUST produce
exactly ONE rasterization, not N. A `@visibleForTesting` reset hook MUST exist that
clears the cache, allowing tests to isolate rendering state between runs.

#### Scenario: cache hit for identical diameter/color/fade

- GIVEN the cache reset hook has been called
- AND two `DotsDecorativeCircleElement` instances with identical `(diameter, colorHex, gaussianFadeMm)` but different `(x, y)` positions
- WHEN both are rendered in the same process
- THEN the rasterization function is invoked exactly once (cache hit on second render)

#### Scenario: cache miss for different diameter

- GIVEN the cache reset hook has been called
- AND two `DotsDecorativeCircleElement` instances that differ only in `diameter`
- WHEN both are rendered
- THEN the rasterization function is invoked twice (two distinct cache entries)

#### Scenario: cache reset hook clears state between tests

- GIVEN the cache has been populated by a prior render
- WHEN the `@visibleForTesting` reset hook is called
- THEN a subsequent render of the same element triggers a fresh rasterization

---

### Requirement: R4 — AlbumCoverContent value object

`AlbumCoverContent` MUST be an immutable value object with fields: `title` (String),
`dateLine` (String), `eyebrowOverride` (String?, default `null`). It MUST implement
value equality (`==` and `hashCode`) based on all three fields.

#### Scenario: AlbumCoverContent constructs with required fields

- GIVEN `AlbumCoverContent(title: 'Mi álbum', dateLine: '01/01/2024 | 31/12/2024')`
- WHEN constructed
- THEN `title` equals `'Mi álbum'`, `dateLine` equals `'01/01/2024 | 31/12/2024'`, and `eyebrowOverride` is `null`

#### Scenario: AlbumCoverContent equality

- GIVEN two `AlbumCoverContent` instances with identical field values
- WHEN compared with `==`
- THEN they are equal AND their `hashCode` values are equal

#### Scenario: AlbumCoverContent inequality when eyebrowOverride differs

- GIVEN two instances where one has `eyebrowOverride: null` and the other `eyebrowOverride: 'CUSTOM'`
- WHEN compared with `==`
- THEN they are NOT equal

---

### Requirement: R5 — DotsAlbumSpreadPage.cover factory

`DotsAlbumSpreadPage.cover(type, pageNumber, content)` MUST accept a `DotsAlbumType`,
an `int pageNumber`, and an `AlbumCoverContent`. It MUST return a `DotsAlbumSpreadPage`
whose `elements` list contains exactly 17 entries: 14 `DotsDecorativeCircleElement`
instances (positions derived from `kCoverCircleLayout`) plus 3 text elements
(eyebrow line, title, date line) centered on the page. The `header` trio fields
(leftPageNumber, centerLabel, rightPageNumber) MUST all be `null`, and the `footer`
wordmark MUST be empty — cover pages carry no page-number trio and no footer label.

#### Scenario: cover page has exactly 17 elements

- GIVEN `DotsAlbumSpreadPage.cover(type: DotsAlbumType.parejas, pageNumber: 1, content: AlbumCoverContent(title: 'T', dateLine: 'D'))`
- WHEN constructed
- THEN `page.elements.length` equals `17`
- AND exactly 14 elements are `DotsDecorativeCircleElement` instances
- AND exactly 3 elements are text elements

#### Scenario: cover page header trio fields are null and footer wordmark is empty

- GIVEN a cover page constructed via `DotsAlbumSpreadPage.cover(...)`
- WHEN `page.header` and `page.footer` are read
- THEN `header.leftPageNumber`, `header.centerLabel`, and `header.rightPageNumber` are all `null`
- AND `footer.wordmark` is an empty string

#### Scenario: cover page circle elements match kCoverCircleLayout

- GIVEN `DotsAlbumSpreadPage.cover(type: DotsAlbumType.parejas, pageNumber: 1, content: ...)`
- WHEN the `elements` list is inspected
- THEN the 14 `DotsDecorativeCircleElement` instances have positions and diameters matching the canonical `kCoverCircleLayout` constant (3 diameter tiers: 47 mm, 28 mm, 16 mm; 5 circles at 47 mm, 4 at 28 mm, 5 at 16 mm)

---

### Requirement: R6 — Per-type eyebrow resolution

`buildCoverPageFor` MUST resolve the eyebrow text as follows: if
`AlbumCoverContent.eyebrowOverride` is non-null, the override value wins; otherwise
the per-type default applies: `parejas` → `"DOTBOOK"`, `hijos` →
`"DOTBOOK DE {NOMBREHIJO}"` (literal — caller substitutes the token via the slice-1
`variables` mechanism). Token substitution for `{NOMBREHIJO}` is the caller's
responsibility; the library emits the literal token string when no override is set.

#### Scenario: parejas default eyebrow

- GIVEN `buildCoverPageFor(DotsAlbumType.parejas, AlbumCoverContent(title: 'T', dateLine: 'D'), pageNumber: 1)`
- WHEN executed
- THEN the eyebrow text element in the returned page has value `"DOTBOOK"`

#### Scenario: hijos default eyebrow

- GIVEN `buildCoverPageFor(DotsAlbumType.hijos, AlbumCoverContent(title: 'T', dateLine: 'D'), pageNumber: 1)`
- WHEN executed
- THEN the eyebrow text element has value `"DOTBOOK DE {NOMBREHIJO}"`

#### Scenario: eyebrowOverride wins over per-type default

- GIVEN `buildCoverPageFor(DotsAlbumType.parejas, AlbumCoverContent(title: 'T', dateLine: 'D', eyebrowOverride: 'CUSTOM'), pageNumber: 1)`
- WHEN executed
- THEN the eyebrow text element has value `"CUSTOM"`

#### Scenario: eyebrowOverride works for hijos too

- GIVEN `buildCoverPageFor(DotsAlbumType.hijos, AlbumCoverContent(title: 'T', dateLine: 'D', eyebrowOverride: 'MI LIBRO'), pageNumber: 1)`
- WHEN executed
- THEN the eyebrow text element has value `"MI LIBRO"`

---

### Requirement: R7 — buildCoverPageFor builder

A top-level function `buildCoverPageFor(DotsAlbumType type, AlbumCoverContent content, {required int pageNumber})` MUST exist and MUST return a single `DotsAlbumSpreadPage`.
It MUST support `DotsAlbumType.parejas` and `DotsAlbumType.hijos` only. Calling it
with any other `DotsAlbumType` value MUST throw an `ArgumentError`.

#### Scenario: buildCoverPageFor returns a DotsAlbumSpreadPage

- GIVEN `buildCoverPageFor(DotsAlbumType.parejas, AlbumCoverContent(title: 'T', dateLine: 'D'), pageNumber: 1)`
- WHEN executed
- THEN the return type is `DotsAlbumSpreadPage`

#### Scenario: buildCoverPageFor throws ArgumentError for unsupported type

- GIVEN `buildCoverPageFor(DotsAlbumType.individuales, AlbumCoverContent(title: 'T', dateLine: 'D'), pageNumber: 1)`
- WHEN executed
- THEN an `ArgumentError` is thrown

#### Scenario: buildCoverPageFor throws ArgumentError for boda

- GIVEN `buildCoverPageFor(DotsAlbumType.boda, AlbumCoverContent(title: 'T', dateLine: 'D'), pageNumber: 1)`
- WHEN executed
- THEN an `ArgumentError` is thrown

#### Scenario: geometry identical for parejas and hijos (same content)

- GIVEN `buildCoverPageFor(DotsAlbumType.parejas, AlbumCoverContent(title: 'T', dateLine: 'D'), pageNumber: 1)`
- AND `buildCoverPageFor(DotsAlbumType.hijos, AlbumCoverContent(title: 'T', dateLine: 'D'), pageNumber: 1)`
- WHEN the two returned pages are compared structurally
- THEN all 14 circle elements have identical positions and diameters
- AND all text element positions are identical
- AND only the eyebrow text value differs

---

### Requirement: R8 — Renderer dispatch

The shared `buildAlbumSpreadPage` helper MUST handle `DotsDecorativeCircleElement`
via a single new arm in `_buildElement`. The arm MUST call a private
`_buildDecorativeCircleElement(...)` helper. Neither the main-isolate nor
the worker-isolate path MUST duplicate decorative-circle rendering logic. After
adding this arm, `dart analyze` MUST report no non-exhaustive pattern match errors.

#### Scenario: cover page renders to a non-empty PDF buffer

- GIVEN a cover page produced by `buildCoverPageFor(DotsAlbumType.parejas, ...)`
- WHEN rendered via `buildAlbumSpreadPage`
- THEN the output is a non-empty valid PDF byte buffer

#### Scenario: no header trio drawn on cover

- GIVEN a cover page with `header == null`
- WHEN rendered
- THEN no page-number text and no center-label text appear in the rendered output

---

### Requirement: R9 — Backwards compatibility and public exports

All slice-1, slice-2, and slice-3 tests MUST pass without modification after this
slice is applied. `DotsDecorativeCircleElement` MUST NOT affect any existing element
type or switch arm. All new public symbols (`DotsDecorativeCircleElement`,
`AlbumCoverContent`, `buildCoverPageFor`) MUST be re-exported from `lib/dots_pdf.dart`.

#### Scenario: existing tests pass unchanged

- GIVEN the slice-4 changes applied to the codebase
- WHEN all slice-1/2/3 test files are run without modification
- THEN all tests pass

#### Scenario: new symbols exported from lib/dots_pdf.dart

- GIVEN the public API barrel file `lib/dots_pdf.dart`
- WHEN inspected for exports
- THEN `DotsDecorativeCircleElement`, `AlbumCoverContent`, and `buildCoverPageFor` are all exported

---

## 14-Circle Canonical Layout (kCoverCircleLayout)

Source: parejas p.4 table. Coordinates in mm from top-left of the 203 mm-wide page.
Color for all circles: `#CDE7F2`. GaussianFadeMm for all: `1.764`.

| # | diameter (mm) | x (mm) | y (mm) | bleedLeft | bleedRight | bleedTop | bleedBottom |
|---|---------------|--------|--------|-----------|------------|----------|-------------|
| 1 | 47            | 8      | 43     | false     | false      | false    | false       |
| 2 | 47            | 141    | 4      | false     | false      | true     | false       |
| 3 | 47            | 210    | 33     | false     | true       | false    | false       |
| 4 | 47            | -13    | 169    | true      | false      | false    | false       |
| 5 | 47            | 200    | 240    | false     | true       | false    | true        |
| 6 | 28            | 36     | 109    | false     | false      | false    | false       |
| 7 | 28            | 176    | 91     | false     | false      | false    | false       |
| 8 | 28            | 49     | 193    | false     | false      | false    | false       |
| 9 | 28            | 138    | 225    | false     | false      | false    | true        |
| 10| 16            | 70     | 48     | false     | false      | false    | false       |
| 11| 16            | 124    | 68     | false     | false      | false    | false       |
| 12| 16            | 170    | 140    | false     | false      | false    | false       |
| 13| 16            | 109    | 181    | false     | false      | false    | false       |
| 14| 16            | 50     | 273    | false     | false      | false    | true        |

Bleed assignment notes:
- Circle #3 (x=210 mm, diameter=47 mm → right edge at 257 mm) bleeds off the 203 mm page right.
- Circle #4 (x=-13 mm) bleeds off the left.
- Circle #5 (x=200 mm, y=240 mm, diameter=47 mm → bottom at 287 mm, right at 247 mm) bleeds bottom-right; page height is 254 mm.
- Circle #2 (y=4 mm, diameter=47 mm, top edge at 4 mm — top bleed flag set as a spec assumption).
- Circle #9 (y=225 mm + 28 mm = 253 mm ≈ page bottom), circle #14 (y=273 mm), and circle #5 bottom flags follow the same logic.

---

## Acceptance Tests

The following tests are confirmed GREEN in the implementation:

- DotsDecorativeCircleElement — constructs with all named fields
- DotsDecorativeCircleElement — equality: identical instances are equal
- DotsDecorativeCircleElement — equality: differs when diameter changes
- DotsDecorativeCircleElement — equality: differs when colorHex changes
- DotsDecorativeCircleElement — bleed flags default to false
- AlbumCoverContent — constructs with title and dateLine; eyebrowOverride defaults to null
- AlbumCoverContent — equality: identical instances are equal
- AlbumCoverContent — inequality when eyebrowOverride differs
- DotsAlbumSpreadPage.cover — elements list has exactly 17 entries
- DotsAlbumSpreadPage.cover — exactly 14 elements are DotsDecorativeCircleElement
- DotsAlbumSpreadPage.cover — exactly 3 elements are text elements
- DotsAlbumSpreadPage.cover — header is null (all trio fields null)
- DotsAlbumSpreadPage.cover — footer wordmark is empty
- DotsAlbumSpreadPage.cover — circle layout matches kCoverCircleLayout
- buildCoverPageFor — parejas eyebrow resolves to DOTBOOK
- buildCoverPageFor — hijos eyebrow resolves to DOTBOOK DE {NOMBREHIJO}
- buildCoverPageFor — eyebrowOverride wins over per-type default
- buildCoverPageFor — throws ArgumentError for DotsAlbumType.individuales
- buildCoverPageFor — throws ArgumentError for DotsAlbumType.boda
- buildCoverPageFor — throws ArgumentError for DotsAlbumType.otros
- buildCoverPageFor — geometry identical for parejas and hijos given same content
- cover page rendering — produces non-empty PDF byte buffer
- cover page rendering — cache: single rasterization for 14 circles of same diameter/color/fade
- cover page rendering — cache reset hook clears rasterization state
- backwards compatibility — all slice-1/2/3 tests pass unchanged
- public API — DotsDecorativeCircleElement exported from lib/dots_pdf.dart
- public API — AlbumCoverContent exported from lib/dots_pdf.dart
- public API — buildCoverPageFor exported from lib/dots_pdf.dart
