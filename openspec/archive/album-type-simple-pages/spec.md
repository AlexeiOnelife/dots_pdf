# Specification: album-type-simple-pages (slice 2 of 5)

**Status:** Draft
**Slice:** 2 of 5
**Depends on:** album-type-foundation (completed and archived)

## Purpose

Makes `DotsAlbumSpreadPage` renderable for the two simplest album-type pages —
dedication and closing single page — plus the header/footer trio that every
album-type spread requires. Introduces two new `DotsElement` subtypes for
rotated text and constrained multi-line text blocks, a typed page-set builder,
and a shared rendering helper that replaces `UnimplementedError` in both the
main-isolate and worker-isolate renderer paths.

---

## Requirements

### Requirement: R1 — Dedication page rendering

`DotsAlbumSpreadPage.dedication(type, title, body, signature)` MUST produce a
page whose rendered output contains all three text fields. The TITLE MUST appear
at the top of the content block, centered, in P22 Mackinac Medium at 23pt / 27.6pt
line height, constrained to a maximum of 50 characters and 2 lines. The BODY MUST
appear below TITLE, centered within a 102 mm wide column, in Inter Book at
9pt / 10.8pt line height. The SIGNATURE MUST appear below the body and MUST be
visually rotated by 2°. The content block as a whole MUST respect an 86 mm bottom
margin. The Biro Script Plus Regular face MUST be used for the signature at
12pt / 14.4pt line height.

#### Scenario: dedication page contains all three text regions

- GIVEN `DotsAlbumSpreadPage.dedication(type: DotsAlbumType.parejas, title: 'Nuestro viaje', body: 'Un año de amor.', signature: 'Blanqui')`
- WHEN the page is rendered to a PDF byte buffer
- THEN the produced PDF page contains the text "Nuestro viaje"
- AND the produced PDF page contains the text "Un año de amor."
- AND the produced PDF page contains the text "Blanqui"

#### Scenario: signature is rendered with 2° rotation

- GIVEN a dedication page constructed with `signature: 'Blanqui'`
- WHEN the page is rendered
- THEN the widget tree of the rendered page contains a `DotsRotatedTextElement`
  with `angleDegrees` equal to `2.0`
- OR the rendered PDF byte stream encodes a rotation transform of 2° on the
  signature text run

#### Scenario: title font and body font are distinct

- GIVEN a dedication page with title 'Foo' and body 'Bar'
- WHEN the page is rendered
- THEN the title text widget carries the P22 Mackinac Medium font reference
- AND the body text widget carries the Inter Book font reference

#### Scenario: body is constrained to 102 mm width

- GIVEN a dedication page with a multi-line body
- WHEN the page is rendered
- THEN the body text block is contained within a 102 mm wide layout constraint

#### Scenario: dedication page for individuales

- GIVEN `DotsAlbumSpreadPage.dedication(type: DotsAlbumType.individuales, ...)`
- WHEN the page is rendered
- THEN the page renders without error
- AND the output is structurally equivalent to a parejas dedication page
  (same geometry — only header labels differ per R5)

---

### Requirement: R2 — Closing single page rendering

`DotsAlbumSpreadPage.closing(type, photoPath, title, subtitle)` MUST produce a page
with a 66 × 86 mm rounded-rectangle photo slot centered on the page. The TITLE MUST
appear below the photo slot. The SUBTITLE MUST appear below the TITLE. Title font is
P22 Mackinac Medium; subtitle font is P22 Mackinac Book at 9pt / 10.8pt, 2 lines.
The TITLE font size MUST vary by album type: 12pt / 14pt for `DotsAlbumType.boda`;
20pt / 24pt for all other types (`parejas`, `hijos`, `individuales`, `otros`).

#### Scenario: closing page for parejas uses 20pt title

- GIVEN `DotsAlbumSpreadPage.closing(type: DotsAlbumType.parejas, photoPath: 'photo.jpg', title: 'Vivid together', subtitle: 'Ana y Luis')`
- WHEN the page is rendered
- THEN the title text widget carries font size 20pt

#### Scenario: closing page for boda uses 12pt title

- GIVEN `DotsAlbumSpreadPage.closing(type: DotsAlbumType.boda, photoPath: 'photo.jpg', title: 'Que la vida siga reencontrándoos', subtitle: '')`
- WHEN the page is rendered
- THEN the title text widget carries font size 12pt

#### Scenario: closing page for hijos uses 20pt title

- GIVEN `DotsAlbumSpreadPage.closing(type: DotsAlbumType.hijos, ...)`
- WHEN the page is rendered
- THEN the title text widget carries font size 20pt

#### Scenario: closing page for individuales uses 20pt title

- GIVEN `DotsAlbumSpreadPage.closing(type: DotsAlbumType.individuales, ...)`
- WHEN the page is rendered
- THEN the title text widget carries font size 20pt

#### Scenario: closing page with missing photo path renders without error

- GIVEN `DotsAlbumSpreadPage.closing(type: DotsAlbumType.parejas, photoPath: null, title: 'Title', subtitle: 'Sub')`
- WHEN the page is rendered
- THEN the page is produced without throwing
- AND no photo slot image is drawn (slot is silently skipped, consistent with
  existing photo-slot failure handling)

#### Scenario: closing page contains photo slot geometry

- GIVEN a closing page with a valid `photoPath`
- WHEN the page is rendered
- THEN the rendered layout contains a photo element sized 66 × 86 mm
- AND that element is horizontally centered on the page

---

### Requirement: R3 — Header and footer drawing

For any `DotsAlbumSpreadPage` whose `header` has a non-null `leftPageNumber`,
`centerLabel`, or `rightPageNumber`, and/or whose `footer` has a non-null
`wordmark`, the renderer MUST draw those values at the canonical positions:
top-left page number, top-center context label, top-right page number, and
bottom-center wordmark. All four labels MUST use Inter Semibold at 7pt / 8.4pt
line height.

#### Scenario: all four header/footer labels are drawn

- GIVEN a `DotsAlbumSpreadPage` constructed with `header.leftPageNumber: '5'`,
  `header.centerLabel: 'tiempojuntos'`, `header.rightPageNumber: '6'`,
  `footer.wordmark: 'Dots. Memories'`
- WHEN the page is rendered
- THEN the rendered page contains the text "5", "tiempojuntos", "6", and
  "Dots. Memories"

#### Scenario: header labels use Inter Semibold 7pt

- GIVEN any album-spread page with a non-null header
- WHEN the page is rendered
- THEN each drawn header/footer text widget carries the Inter Semibold font
  reference at 7pt

#### Scenario: null header fields are omitted without error

- GIVEN a `DotsAlbumSpreadPage` with `header.leftPageNumber: null` and
  all other header/footer fields null
- WHEN the page is rendered
- THEN the page renders without throwing
- AND no header text is drawn

---

### Requirement: R4 — DotsRotatedTextElement

A new sealed subtype `DotsRotatedTextElement` of `DotsElement` MUST exist that
carries a text value, font specification, and a rotation angle in degrees. The
renderer MUST apply the specified rotation when drawing this element. The subtype
MUST be usable for any rotated text in the elements list, not only the dedication
signature.

#### Scenario: rotated text element is rendered at the specified angle

- GIVEN a `DotsAlbumSpreadPage` with an `elements` list containing a
  `DotsRotatedTextElement(value: 'Hello', angleDegrees: 45.0)`
- WHEN the page is rendered
- THEN the produced layout contains a rotation transform of 45° applied to
  the text "Hello"

#### Scenario: sealed switch remains exhaustive after adding DotsRotatedTextElement

- GIVEN the sealed `DotsElement` hierarchy updated with `DotsRotatedTextElement`
- WHEN `dart analyze` is run
- THEN no non-exhaustive pattern match errors are reported

---

### Requirement: R5 — DotsTextBlockElement

A new sealed subtype `DotsTextBlockElement` of `DotsElement` MUST exist that
carries a text value, a max width in mm, a maximum character count, and a maximum
line count (counted by newline-separated segments). The renderer MUST render the
element within the specified width constraint. When the body text exceeds
`maxChars` (default 1000) or the line count exceeds `maxLines` (default 32), the
renderer MUST emit a warning via the injected `DotsLogger` — including the page
number and the offending count — but MUST still render the full text without
throwing an exception.

Widow rule (minimum 3 words on the last line) and no-word-break rules are
intentionally deferred and are NOT required by this spec.

#### Scenario: body within limits renders without warning

- GIVEN a `DotsTextBlockElement` with a body of 100 characters and 5 lines
- WHEN the page is rendered
- THEN no warning is emitted on `DotsLogger`
- AND the page is produced

#### Scenario: body exceeding 1000 characters triggers warning

- GIVEN a `DotsTextBlockElement` with a body of 1001 characters
- WHEN the page is rendered
- THEN `DotsLogger` receives exactly one warning
- AND the warning message references the character count
- AND the page is still produced (no exception thrown)

#### Scenario: body exceeding 32 newline-separated lines triggers warning

- GIVEN a `DotsTextBlockElement` with a body containing 33 newline-separated lines
- WHEN the page is rendered
- THEN `DotsLogger` receives exactly one warning
- AND the warning message references the line count
- AND the page is still produced (no exception thrown)

#### Scenario: body exceeding both limits triggers at least one warning

- GIVEN a `DotsTextBlockElement` with 1001 characters AND 33 newline-separated lines
- WHEN the page is rendered
- THEN `DotsLogger` receives at least one warning
- AND the page is still produced

---

### Requirement: R6 — Album-type page-set builder

A top-level function `buildSimplePagesFor(DotsAlbumType, AlbumSimpleContent, {required int firstPageNumber})` MUST exist and MUST return the dedication and closing pages for the given album type, in that order. `AlbumSimpleContent` is an immutable value object carrying optional dedication fields (title, body, signature) and optional closing fields (photoPath, title, subtitle). Pages whose content fields are entirely absent MUST be omitted from the returned list.

For `DotsAlbumType.boda`, `buildSimplePagesFor` MUST return only the closing page
(boda has no dedication page in the design spec). For all other types, it MUST
return dedication first, then closing, when both are supplied.

Each returned page MUST carry a `header.centerLabel` equal to the
`contextLabelToken` resolved from slice 1's `DotsAlbumTypeContext` extension,
and `header.leftPageNumber` / `header.rightPageNumber` populated from
`firstPageNumber`.

#### Scenario: buildSimplePagesFor(parejas) returns 2 pages in correct order

- GIVEN `buildSimplePagesFor(DotsAlbumType.parejas, AlbumSimpleContent(dedication: ..., closing: ...), firstPageNumber: 5)`
- WHEN executed
- THEN the result has length 2
- AND result[0] is a dedication page
- AND result[1] is a closing page

#### Scenario: buildSimplePagesFor(boda) returns only the closing page

- GIVEN `buildSimplePagesFor(DotsAlbumType.boda, AlbumSimpleContent(closing: ...), firstPageNumber: 5)`
- WHEN executed
- THEN the result has length 1
- AND result[0] is a closing page (not a dedication page)

#### Scenario: buildSimplePagesFor(hijos) sets header.centerLabel to {Protagonistas}

- GIVEN `buildSimplePagesFor(DotsAlbumType.hijos, content, firstPageNumber: 5)`
- WHEN executed
- THEN every page in the result has `header.centerLabel` equal to `'{Protagonistas}'`

#### Scenario: buildSimplePagesFor(individuales) sets header.centerLabel to {Año}

- GIVEN `buildSimplePagesFor(DotsAlbumType.individuales, content, firstPageNumber: 2)`
- WHEN executed
- THEN every page in the result has `header.centerLabel` equal to `'{Año}'`

#### Scenario: buildSimplePagesFor with missing closing content omits closing page

- GIVEN `buildSimplePagesFor(DotsAlbumType.parejas, AlbumSimpleContent(dedication: ..., closing: null), firstPageNumber: 1)`
- WHEN executed
- THEN the result has length 1
- AND result[0] is a dedication page

---

### Requirement: R7 — Renderer dispatch consolidation

Both `dots_renderer.dart:buildPage` and `isolate_synthesis.dart:buildPage` MUST
delegate `DotsAlbumSpreadPage` rendering to a single shared pure helper
`buildAlbumSpreadPage(...)`. Neither site MUST throw `UnimplementedError` after
this slice. The shared helper MUST be the single authoritative path for header,
footer, and element rendering — the two call sites MUST NOT duplicate rendering
logic.

#### Scenario: rendering via main isolate path produces a valid PDF

- GIVEN a `DotsAlbumSpreadPage.dedication(...)` rendered through `useIsolate: false`
- WHEN the generator is called
- THEN it produces a non-empty valid PDF byte buffer without throwing

#### Scenario: rendering via worker isolate path produces a valid PDF

- GIVEN a `DotsAlbumSpreadPage.dedication(...)` rendered through `useIsolate: true`
- WHEN the generator is called
- THEN it produces a non-empty valid PDF byte buffer without throwing

#### Scenario: both isolate paths produce output of comparable size

- GIVEN the same `DotsAlbumSpreadPage` instance rendered through both paths
- WHEN both byte buffers are compared
- THEN both are valid PDFs
- AND their sizes are within a reasonable tolerance (within 20% of each other)

---

### Requirement: R8 — Backwards compatibility

All `DotsAlbumSpreadPage` constructions from slice 1 (without elements, or with
an empty elements list) MUST remain constructible. Slice 1's tests MUST pass
without modification. The sealed `DotsElement` switch in the renderer MUST remain
exhaustive after adding `DotsRotatedTextElement` and `DotsTextBlockElement`.

#### Scenario: empty DotsAlbumSpreadPage constructs without error

- GIVEN `DotsAlbumSpreadPage` constructed as in slice 1 (empty elements, with
  header and footer values)
- WHEN constructed
- THEN no exception is thrown
- AND `dart analyze` reports no errors

#### Scenario: all slice 1 tests still pass

- GIVEN the test suite from the album-type-foundation slice
- WHEN run after this slice is applied
- THEN all tests pass without modification

---

### Requirement: R9 — Public API export

All new public symbols introduced by this slice MUST be re-exported from
`lib/dots_pdf.dart`. This includes `AlbumSimpleContent`, `buildSimplePagesFor`,
`DotsRotatedTextElement`, and `DotsTextBlockElement`.

---

## Acceptance Test List

The following tests MUST exist in `test/` to satisfy this spec:

**Dedication rendering** (`test/render/album_spread_page_test.dart`):
- `AlbumSpreadPage — dedication page renders title, body, and signature for parejas`
- `AlbumSpreadPage — dedication page renders title, body, and signature for hijos`
- `AlbumSpreadPage — dedication page renders title, body, and signature for individuales`
- `AlbumSpreadPage — dedication page renders title, body, and signature for otros`
- `AlbumSpreadPage — dedication signature is rendered via DotsRotatedTextElement at 2°`
- `AlbumSpreadPage — dedication body is constrained to 102 mm width`

**Closing page rendering** (`test/render/album_spread_page_test.dart`):
- `AlbumSpreadPage — closing page title is 12pt for boda`
- `AlbumSpreadPage — closing page title is 20pt for parejas`
- `AlbumSpreadPage — closing page title is 20pt for hijos`
- `AlbumSpreadPage — closing page title is 20pt for individuales`
- `AlbumSpreadPage — closing page title is 20pt for outros`
- `AlbumSpreadPage — closing page with null photoPath renders without error`
- `AlbumSpreadPage — closing page photo slot is 66×86 mm`

**Header and footer drawing** (`test/render/album_spread_page_test.dart`):
- `AlbumSpreadPage — header labels (left, center, right) and footer wordmark are drawn`
- `AlbumSpreadPage — header labels use Inter Semibold 7pt`
- `AlbumSpreadPage — null header fields are omitted without error`

**DotsTextBlockElement warnings** (`test/render/album_spread_page_test.dart`):
- `DotsTextBlockElement — body within limits emits no warning`
- `DotsTextBlockElement — body exceeding 1000 chars emits a warning and renders`
- `DotsTextBlockElement — body exceeding 32 newline-separated lines emits a warning and renders`

**Isolate dispatch** (`test/render/album_spread_page_test.dart`):
- `AlbumSpreadPage — useIsolate=false path produces a valid PDF`
- `AlbumSpreadPage — useIsolate=true path produces a valid PDF`
- `AlbumSpreadPage — both isolate paths produce output of comparable size`

**Page-set builder** (`test/api/build_simple_pages_test.dart`):
- `buildSimplePagesFor — parejas returns [dedication, closing] in order`
- `buildSimplePagesFor — hijos returns [dedication, closing] in order`
- `buildSimplePagesFor — individuales returns [dedication, closing] in order`
- `buildSimplePagesFor — otros returns [dedication, closing] in order`
- `buildSimplePagesFor — boda returns [closing] only (no dedication)`
- `buildSimplePagesFor — hijos header.centerLabel equals {Protagonistas}`
- `buildSimplePagesFor — individuales header.centerLabel equals {Año}`
- `buildSimplePagesFor — otros header.centerLabel equals {Año}`
- `buildSimplePagesFor — parejas header.centerLabel equals {tiempojuntos}`
- `buildSimplePagesFor — boda header.centerLabel equals {Protagonistas}`
- `buildSimplePagesFor — missing closing content omits closing page`
- `buildSimplePagesFor — missing dedication content omits dedication page`

**Backwards compatibility**:
- `DotsAlbumSpreadPage — empty elements list constructs without error (slice 1 compat)`
- `dart analyze — sealed DotsElement switch remains exhaustive after new subtypes`

---

## Known gaps and deferred items

- **Widow rule**: minimum 3 words on the last line of `DotsTextBlockElement` is
  deferred. The `pdf` package does not expose post-layout glyph positions;
  implementation requires a custom line-breaker or post-layout inspection.
- **No-word-break rule**: deferred for the same reason.
- **boda dedication**: boda has no dedication page in the design spec. The
  `.dedication(...)` named constructor MUST still be usable for other types;
  `buildSimplePagesFor(boda, ...)` simply omits it.
- **Line-count detection**: the spec requires warning on >32 newline-separated
  lines. This is approximated via `value.split('\n').length` because the `pdf`
  package does not expose layout-time glyph line breaks. The warn is best-effort.
- **Character-per-line heuristic**: not required by this spec; only the raw
  `value.length > 1000` check is required for the character warning.
