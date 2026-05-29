# category-render-fidelity-parejas-hijos Specification

## Purpose

Defines the per-spread render contract for the `parejas` and `hijos` album
categories: canonical mm coordinates, copy tokens, content model fields, and
layout-constant file contracts. This spec is the source of truth for any test
that asserts on element positions or text for these two categories.

**Source of truth:** `docs/templates/final_templates/pdf02_pareja_inicial.pdf`,
`pdf03_pareja_final.pdf`, `pdf08_hijos_inicial.pdf`, `pdf09_hijos_final.pdf`
(26 pages, fully read in `explore.md`).

---

## Requirements

### Requirement: R1 — Cover eyebrow text (both categories)

`DotsAlbumSpreadPage.cover(DotsAlbumType.parejas, ...)` and
`cover(DotsAlbumType.hijos, ...)` MUST produce an eyebrow text element whose
resolved value is `"DOTBOOK DE {PROTAGONISTA}"` when no `eyebrowOverride` is
supplied. `eyebrowOverride`, if non-null, MUST take precedence and suppress
the default. The legacy literal `'DOTBOOK'` (parejas) and token
`{NOMBREHIJO}` (hijos) MUST NOT appear in the output.

#### Scenario: parejas cover default eyebrow

- GIVEN `DotsAlbumSpreadPage.cover(DotsAlbumType.parejas, content: ...)`
  with no `eyebrowOverride`
- WHEN the spread's element list is inspected
- THEN the eyebrow `DotsTextElement.text` equals `"DOTBOOK DE {PROTAGONISTA}"`

#### Scenario: hijos cover default eyebrow

- GIVEN `DotsAlbumSpreadPage.cover(DotsAlbumType.hijos, content: ...)`
  with no `eyebrowOverride`
- WHEN the spread's element list is inspected
- THEN the eyebrow `DotsTextElement.text` equals `"DOTBOOK DE {PROTAGONISTA}"`

#### Scenario: eyebrowOverride wins

- GIVEN `DotsAlbumSpreadPage.cover(...)` with `eyebrowOverride: "CUSTOM"`
- WHEN the spread's element list is inspected
- THEN the eyebrow text equals `"CUSTOM"`

---

### Requirement: R2 — Cover coordinate geometry

The three text elements in `cover(parejas|hijos)` MUST match the canonical
PDF geometry. All values are page-local millimetres.

| Element | x (mm) | y (mm) | width (mm) |
|---|---|---|---|
| Eyebrow | 41.5 | 110.249 | 120 |
| Title | 41.5 | ~119 | 120 |
| Date line | 41.5 | ~130.7 | 120 |

The `kCoverCircleLayout` constants MUST NOT change.

#### Scenario: cover eyebrow x and y

- GIVEN `DotsAlbumSpreadPage.cover(DotsAlbumType.parejas, content: ...)`
- WHEN the eyebrow element is inspected
- THEN `xMm == 41.5` AND `yMm == 110.249` AND `widthMm == 120`

#### Scenario: cover title x position

- GIVEN `DotsAlbumSpreadPage.cover(DotsAlbumType.hijos, content: ...)`
- WHEN the title element is inspected
- THEN `xMm == 41.5` AND `widthMm == 120`

#### Scenario: cover date x position

- GIVEN `DotsAlbumSpreadPage.cover(DotsAlbumType.parejas, content: ...)`
- WHEN the date element is inspected
- THEN `xMm == 41.5` AND `widthMm == 120`

---

### Requirement: R3 — Dedication coordinate geometry (relative positioning)

`dedication(parejas|hijos)` MUST position all text elements on the right
page using these constraints. Coordinates are right-page-local.

| Constraint | Value |
|---|---|
| All text x | 50.53 mm |
| Body width | 120 mm |
| Body top | title bottom + 6.5 mm |
| Signature top | body bottom + 8 mm |

The title y is content-block-top-dependent (varies with body length).
Independent fixed constants at y=60/90/160 mm MUST NOT remain.
Signature font (Biro Script Plus 12 pt, 2°) MUST NOT change.

#### Scenario: dedication text x alignment

- GIVEN `DotsAlbumSpreadPage.dedication(DotsAlbumType.parejas, content: ...)`
- WHEN all text elements are inspected
- THEN every element has `xMm == 50.53`

#### Scenario: dedication body width

- GIVEN `DotsAlbumSpreadPage.dedication(DotsAlbumType.hijos, content: ...)`
- WHEN the body element is inspected
- THEN `widthMm == 120`

#### Scenario: dedication body is 6.5 mm below title bottom

- GIVEN `DotsAlbumSpreadPage.dedication(DotsAlbumType.parejas, content: ...)`
- WHEN title y and height are read, and body y is read
- THEN `bodyYMm == titleYMm + titleHeightMm + 6.5` (within 0.1 mm)

#### Scenario: dedication signature is 8 mm below body bottom

- GIVEN any call to `dedication(parejas|hijos)`
- WHEN body y + height and signature y are read
- THEN `signatureYMm == bodyYMm + bodyHeightMm + 8.0` (within 0.1 mm)

---

### Requirement: R4 — Closing coordinate geometry

`closing(parejas|hijos)` MUST match the canonical PDF geometry.
All values are page-local millimetres.

| Element | x (mm) | y (mm) | width (mm) |
|---|---|---|---|
| Photo | — | 71.534 | — (unchanged dims) |
| Title | 44 | photo_bottom + 5 | 115 |
| Subtitle | 44 | title_bottom + 5 | 115 |

`photo_bottom = 71.534 + photoHeightMm` (photo height unchanged at 86 mm →
bottom ≈ 157.534 mm; title y ≈ 162.534 mm; subtitle y ≈ title_y + title_h + 5).

#### Scenario: closing photo y

- GIVEN `DotsAlbumSpreadPage.closing(DotsAlbumType.parejas, content: ...)`
- WHEN the photo element is inspected
- THEN `yMm == 71.534`

#### Scenario: closing title position

- GIVEN `DotsAlbumSpreadPage.closing(DotsAlbumType.hijos, content: ...)`
- WHEN the title element is inspected
- THEN `xMm == 44.0` AND `widthMm == 115.0`

#### Scenario: closing subtitle position

- GIVEN `DotsAlbumSpreadPage.closing(DotsAlbumType.parejas, content: ...)`
- WHEN the subtitle element is inspected
- THEN `xMm == 44.0` AND `widthMm == 115.0`

#### Scenario: closing title is 5 mm below photo bottom

- GIVEN `DotsAlbumSpreadPage.closing(DotsAlbumType.parejas, content: ...)`
- WHEN photo y + height and title y are read
- THEN `titleYMm == 71.534 + photoHeightMm + 5.0` (within 0.1 mm)

#### Scenario: closing subtitle is 5 mm below title bottom

- GIVEN any call to `closing(parejas|hijos)`
- WHEN title y + height and subtitle y are read
- THEN `subtitleYMm == titleYMm + titleHeightMm + 5.0` (within 0.1 mm)

---

### Requirement: R5 — `beforeYouStart` spread layout

`DotsAlbumSpreadPage.beforeYouStart(DotsAlbumType.parejas|hijos, content: ...)`
MUST emit exactly ONE `DotsAlbumSpreadPage` covering the full 0–406 mm spread.
Chrome header MUST use `leftPageNumber: '$pageNumber'` and
`rightPageNumber: '${pageNumber + 1}'` (spread pattern, matching `photoArc`).

**Left page elements (spread-relative; left page x-origin = 0):**

| Element | Font | x (mm) | y (mm) | width (mm) |
|---|---|---|---|---|
| Title L1 | P22 Mackinac Medium 27 pt | 54.083 | 96.2 | 95 |
| Title L2 | P22 Mackinac Medium Italic 27 pt | 54.083 | 96.2 | 95 |
| Body | Inter Book 9 pt | 54.083 | 120.3 | 95 |

**Right page elements (spread-relative; right page x-origin = 203 mm):**

| Element | Font | x offset from right page | y (mm) | width (mm) |
|---|---|---|---|---|
| Protagonist label | Inter Book 9 pt | 69.168 | ~210.8 | 65 |
| CTA | P22 Mackinac Medium 15 pt | 69.168 | ~219 | 65 |

**Photo-slot grid (both pages):**

- 10 slots total; 5 per page; each 35 × 46 mm; `DotsImageElement` (no corner radius)
- Page-local x positions (mm): 8, 43, 78, 113, 148; y = 36 mm
- Spread-relative right-page x: add 203 mm to page-local x

**Per-page Q1/Q2 cluster (below photo grid, both pages):**

| Element | Font | gap above |
|---|---|---|
| NÚMERO | P22 Mackinac Medium 23 pt | 0 mm from slot bottom |
| TITULO | P22 Mackinac Medium 23 pt | 7.5 mm |
| TEXTO | Inter Book 9 pt | 5 mm |

Text-block width 93 mm; x = 55.309 mm from page outer edge.

**Per-category copy (`switch (type)`):**

| type | Body copy (left page) | Q1 title | Q2 title |
|---|---|---|---|
| `parejas` | "Encontrad un espacio donde podáis estar en calma…" | "Buscad vuestro momento" | "Escuchad vuestra historia" |
| `hijos` | "Piensa que esto no son solo fotos…" | "Busca un lugar tranquilo" | "Escucha los momentos especiales" |

Other types (individuales, otros, generalEventos) MUST fall through to the
`parejas` copy branch with a `// TODO(task-5-7): per-category copy` comment.
`boda` MUST throw `ArgumentError` (guard already exists).

#### Scenario: beforeYouStart emits one spread page

- GIVEN `DotsAlbumSpreadPage.beforeYouStart(DotsAlbumType.parejas, content: validContent)`
- WHEN the result type is inspected
- THEN it is a single `DotsAlbumSpreadPage` (not a list)

#### Scenario: beforeYouStart spread chrome uses paired page numbers

- GIVEN `DotsAlbumSpreadPage.beforeYouStart(...)` at `pageNumber: 2`
- WHEN the spread header is inspected
- THEN `leftPageNumber == '2'` AND `rightPageNumber == '3'`

#### Scenario: beforeYouStart left-page title L1 position

- GIVEN `beforeYouStart(DotsAlbumType.parejas, ...)` 
- WHEN the title L1 element is inspected
- THEN `xMm == 54.083` AND `yMm == 96.2` AND `widthMm == 95`

#### Scenario: beforeYouStart photo slots — first slot left page

- GIVEN `beforeYouStart(DotsAlbumType.hijos, content: validContent)` with 10 photo paths
- WHEN photo slot 0 (first left-page slot) is inspected
- THEN `xMm == 8` AND `yMm == 36` AND `widthMm == 35` AND `heightMm == 46`

#### Scenario: beforeYouStart has exactly 10 photo slots

- GIVEN `beforeYouStart(DotsAlbumType.parejas, ...)` with 10 photo paths
- WHEN all `DotsImageElement` instances are counted
- THEN the count equals 10

#### Scenario: beforeYouStart parejas body copy

- GIVEN `beforeYouStart(DotsAlbumType.parejas, content: validContent)`
- WHEN the body text element on the left page is inspected
- THEN it starts with `"Encontrad un espacio"`

#### Scenario: beforeYouStart hijos body copy

- GIVEN `beforeYouStart(DotsAlbumType.hijos, content: validContent)`
- WHEN the body text element on the left page is inspected
- THEN it starts with `"Piensa que esto no son solo fotos"`

#### Scenario: beforeYouStart boda type throws

- GIVEN `beforeYouStart(DotsAlbumType.boda, content: validContent)`
- WHEN called
- THEN `ArgumentError` is thrown

---

### Requirement: R6 — `closingQrSpread` left-page layout

`DotsAlbumSpreadPage.closingQrSpread(...)` MUST emit ONE `DotsAlbumSpreadPage`
covering the full spread. The LEFT page MUST render the following elements
(page-local coordinates):

| Element | Font | x (mm) | y (mm) | width (mm) |
|---|---|---|---|---|
| Title | P22 Mackinac Medium 23 pt | 30 | 50.892 | 143 |
| Body-1 | Inter Book 9 pt | 30 | 71.346 | 92 |
| QR block | — | 30 | 94.081 | 27 |
| QR caption | P22 Mackinac Medium 9 pt | 62 | 94.081 | 36.178 |
| Bottom text | Inter Book 9 pt | 30 | 229.42 | 143 |

QR block height MUST be 27 mm. The bottom text element MUST display the
`bottomTextOverride` value when non-null; otherwise MUST display the literal
string `'{Protagonistas}, disfruta de está última experiencia.'` (token
un-resolved, for debugging).

The RIGHT page MUST emit chrome only — no content elements. No decorative
circles (deferred).

#### Scenario: closingQrSpread left-page title position

- GIVEN `DotsAlbumSpreadPage.closingQrSpread(content: validContent)`
- WHEN the title element is inspected
- THEN `xMm == 30` AND `yMm == 50.892` AND `widthMm == 143`

#### Scenario: closingQrSpread QR block position and size

- GIVEN `DotsAlbumSpreadPage.closingQrSpread(content: validContent)`
- WHEN the QR block element is inspected
- THEN `xMm == 30` AND `yMm == 94.081` AND `widthMm == 27` AND `heightMm == 27`

#### Scenario: closingQrSpread bottom text default token

- GIVEN `DotsAlbumSpreadPage.closingQrSpread(content: contentWithNoBottomOverride)`
- WHEN the bottom text element is inspected
- THEN the text equals `'{Protagonistas}, disfruta de está última experiencia.'`

#### Scenario: closingQrSpread bottomTextOverride wins

- GIVEN `DotsAlbumSpreadContent` with `bottomTextOverride: "Ana y Luis, disfruta…"`
- WHEN the bottom text element is inspected
- THEN the text equals `"Ana y Luis, disfruta…"`

#### Scenario: closingQrSpread right page has no content elements

- GIVEN `DotsAlbumSpreadPage.closingQrSpread(content: validContent)`
- WHEN spread-relative elements with `xMm >= 203` are counted
- THEN the count is zero (chrome-only right page)

---

### Requirement: R7 — `AlbumBeforeYouStartContent.photoPaths`

`AlbumBeforeYouStartContent` MUST declare `photoPaths` as a `required`
`final List<String>` field. The `beforeYouStart` factory MUST assert
`photoPaths.length == 10` and throw `RangeError` if the invariant is violated.
`==` and `hashCode` MUST include `photoPaths`. The existing `titleOverride`
and `bodyOverride` fields remain optional.

#### Scenario: photoPaths is required at construction

- GIVEN source that constructs `AlbumBeforeYouStartContent` without `photoPaths`
- WHEN compiled
- THEN a compile-time error is produced

#### Scenario: factory rejects photoPaths length != 10

- GIVEN `AlbumBeforeYouStartContent(photoPaths: List.filled(9, 'a.jpg'), ...)`
- WHEN `beforeYouStart(...)` is called with this content
- THEN `RangeError` is thrown

#### Scenario: factory accepts exactly 10 paths

- GIVEN `AlbumBeforeYouStartContent(photoPaths: List.filled(10, 'a.jpg'), ...)`
- WHEN `beforeYouStart(...)` is called
- THEN no exception is thrown

#### Scenario: equality includes photoPaths

- GIVEN two `AlbumBeforeYouStartContent` instances differing only in `photoPaths`
- WHEN `==` is evaluated
- THEN the result is `false`

---

### Requirement: R8 — `AlbumQrSpreadContent.bottomTextOverride`

`AlbumQrSpreadContent` MUST add `bottomTextOverride` as an OPTIONAL `final String?`
named parameter (default `null`). `==` and `hashCode` MUST include it. No
existing constructor positional order changes.

#### Scenario: bottomTextOverride defaults to null

- GIVEN `AlbumQrSpreadContent(qrPayload: '...', placement: closing)`
  constructed without `bottomTextOverride`
- WHEN `.bottomTextOverride` is read
- THEN the value is `null`

#### Scenario: equality distinguishes bottomTextOverride values

- GIVEN two `AlbumQrSpreadContent` instances identical except `bottomTextOverride`
- WHEN `==` is evaluated
- THEN the result is `false`

---

### Requirement: R9 — Layout-constant files

`lib/src/render/before_you_start_layout.dart` MUST export:
- `kBeforeYouStartLeftLayout` — const record list with the left-page text
  element geometry (position, size, font role)
- `kBeforeYouStartRightLayout` — const record list with the right-page element
  geometry
- `kBeforeYouStartPhotoSlots` — const list of 10 `({double xMm, double yMm, double widthMm, double heightMm})` records; first 5 are left-page, last 5 are right-page

`lib/src/render/closing_qr_spread_layout.dart` MUST export:
- `kClosingQrSpreadLeftLayout` — const record list encoding title/body/QR/caption/
  bottom element geometry as shown in R6

Both files MUST be purely declarative (no factory logic). Both MUST live in
`lib/src/render/` alongside `cover_circles.dart` and `photo_arc_layout.dart`.

#### Scenario: kBeforeYouStartPhotoSlots has 10 entries

- GIVEN `kBeforeYouStartPhotoSlots`
- WHEN `.length` is read
- THEN the value equals 10

#### Scenario: slot index 0 matches canonical left-page first slot

- GIVEN `kBeforeYouStartPhotoSlots[0]`
- WHEN fields are read
- THEN `xMm == 8` AND `yMm == 36` AND `widthMm == 35` AND `heightMm == 46`

#### Scenario: kClosingQrSpreadLeftLayout QR entry

- GIVEN `kClosingQrSpreadLeftLayout` QR record
- WHEN fields are read
- THEN `xMm == 30` AND `yMm == 94.081` AND `widthMm == 27` AND `heightMm == 27`

---

### Requirement: R10 — Test fixture regression contract

Existing tests asserting on `cover` / `dedication` / `closing` literal
coordinates MUST be updated to the new expected values from R2, R3, and R4.
New test files MUST be created:

| File | Coverage |
|---|---|
| `test/config/dots_album_spread_page_cover_test.dart` | Updated — new eyebrow text + coordinate assertions for parejas AND hijos |
| `test/config/dots_album_spread_page_dedication_test.dart` | Updated — x=50.53, body width=120, relative y offsets |
| `test/config/dots_album_spread_page_closing_test.dart` | Updated — photo y=71.534, title/subtitle x=44, width=115 |
| `test/config/dots_album_spread_page_before_you_start_test.dart` | New — element count, slot positions, copy assertions for parejas + hijos |
| `test/config/dots_album_spread_page_closing_qr_spread_test.dart` | New — left-page elements, right-page chrome-only assertion |
| `test/api/album_before_you_start_content_test.dart` | Updated — photoPaths required; length-10 invariant |
| `test/api/album_qr_spread_content_test.dart` | Updated — bottomTextOverride field coverage |

Old coordinate values in these files are intentionally wrong after this change
and will fail if not updated. Fixture updates MUST pair with the corresponding
production-code commit.

#### Scenario: existing cover test suite passes after update

- GIVEN the updated `dots_album_spread_page_cover_test.dart`
- WHEN `flutter test test/config/dots_album_spread_page_cover_test.dart` runs
- THEN exit code is zero

#### Scenario: new before_you_start test covers both categories

- GIVEN `dots_album_spread_page_before_you_start_test.dart`
- WHEN inspected
- THEN test groups for `parejas` and `hijos` are both present

#### Scenario: full suite is green after all changes

- GIVEN all production-code changes and updated/new fixtures
- WHEN `flutter test` AND `flutter analyze` are run
- THEN both exit with code zero

---

## Out of Scope

The following MUST NOT be implemented in Task 4:

| Deferred item | Reason |
|---|---|
| Dedication left-page solid `#CDE7F2` background | Requires new per-page background mechanism; Decision Q2 |
| `beforeYouStart` photo-slot corner radius | `DotsImageElement` has no `cornerRadiusMm`; Decision Q6 |
| `closingQrSpread` right-page decorative circles | PDF diameters not annotated; Decision Q4 |
| `photoArc` geometry fidelity verification | Source PDF attribution unclear; cosmetic comment update only |
| `individuales` / `otros` / `boda` / `generalEventos` factory bodies | Tasks 5–7 |

---

## Acceptance Test List

**R1 — Cover eyebrow**
- `DotsAlbumSpreadPage.cover parejas — default eyebrow is DOTBOOK DE {PROTAGONISTA}`
- `DotsAlbumSpreadPage.cover hijos — default eyebrow is DOTBOOK DE {PROTAGONISTA}`
- `DotsAlbumSpreadPage.cover — eyebrowOverride suppresses default`

**R2 — Cover coordinates**
- `DotsAlbumSpreadPage.cover parejas — eyebrow xMm=41.5, yMm=110.249, widthMm=120`
- `DotsAlbumSpreadPage.cover hijos — title xMm=41.5, widthMm=120`
- `DotsAlbumSpreadPage.cover parejas — date xMm=41.5, widthMm=120`

**R3 — Dedication coordinates**
- `DotsAlbumSpreadPage.dedication parejas — all text xMm=50.53`
- `DotsAlbumSpreadPage.dedication hijos — body widthMm=120`
- `DotsAlbumSpreadPage.dedication parejas — body is 6.5mm below title bottom`
- `DotsAlbumSpreadPage.dedication — signature is 8mm below body bottom`

**R4 — Closing coordinates**
- `DotsAlbumSpreadPage.closing parejas — photo yMm=71.534`
- `DotsAlbumSpreadPage.closing hijos — title xMm=44, widthMm=115`
- `DotsAlbumSpreadPage.closing parejas — subtitle xMm=44, widthMm=115`
- `DotsAlbumSpreadPage.closing — title is 5mm below photo bottom`
- `DotsAlbumSpreadPage.closing — subtitle is 5mm below title bottom`

**R5 — beforeYouStart layout**
- `DotsAlbumSpreadPage.beforeYouStart — emits single DotsAlbumSpreadPage`
- `DotsAlbumSpreadPage.beforeYouStart — spread chrome paired page numbers`
- `DotsAlbumSpreadPage.beforeYouStart parejas — title L1 at x=54.083 y=96.2 w=95`
- `DotsAlbumSpreadPage.beforeYouStart — slot 0 at x=8 y=36 w=35 h=46`
- `DotsAlbumSpreadPage.beforeYouStart — exactly 10 DotsImageElement instances`
- `DotsAlbumSpreadPage.beforeYouStart parejas — body copy starts with Encontrad`
- `DotsAlbumSpreadPage.beforeYouStart hijos — body copy starts with Piensa que`
- `DotsAlbumSpreadPage.beforeYouStart boda — throws ArgumentError`

**R6 — closingQrSpread layout**
- `DotsAlbumSpreadPage.closingQrSpread — title at x=30 y=50.892 w=143`
- `DotsAlbumSpreadPage.closingQrSpread — QR at x=30 y=94.081 w=27 h=27`
- `DotsAlbumSpreadPage.closingQrSpread — bottom text default is literal token`
- `DotsAlbumSpreadPage.closingQrSpread — bottomTextOverride replaces default`
- `DotsAlbumSpreadPage.closingQrSpread — right page has zero content elements`

**R7 — AlbumBeforeYouStartContent.photoPaths**
- `AlbumBeforeYouStartContent — photoPaths is required (compile-time)`
- `DotsAlbumSpreadPage.beforeYouStart — 9 paths throws RangeError`
- `DotsAlbumSpreadPage.beforeYouStart — 10 paths accepted`
- `AlbumBeforeYouStartContent — equality uses photoPaths`

**R8 — AlbumQrSpreadContent.bottomTextOverride**
- `AlbumQrSpreadContent — bottomTextOverride defaults to null`
- `AlbumQrSpreadContent — equality distinguishes bottomTextOverride`

**R9 — Layout constants**
- `kBeforeYouStartPhotoSlots — length is 10`
- `kBeforeYouStartPhotoSlots[0] — x=8 y=36 w=35 h=46`
- `kClosingQrSpreadLeftLayout — QR entry x=30 y=94.081 w=27 h=27`

**R10 — Test fixtures**
- `dots_album_spread_page_cover_test — suite is green after update`
- `dots_album_spread_page_before_you_start_test — groups for parejas and hijos exist`
- `flutter test AND flutter analyze — both exit zero`
