# page-template-chrome Specification

## Purpose

Establishes a single shared page-chrome primitive (`DotsPageChrome` + `buildPageChrome`) applied
uniformly to every interior page type, fixing four confirmed bugs in the existing spread-page
chrome path and adding chrome to the two page types that currently render none.

---

## Requirements

### Requirement: R1 — Page background on all interior pages

Every interior page (`DotsLayoutPage`, `DotsElementsPage`, `DotsAlbumSpreadPage` non-cover) MUST
render a full-bleed background of color `#fdfefd` as the FIRST child of the page stack.
Cover pages (`DotsAlbumSpreadPage.cover()`) MUST NOT receive a background from the chrome helper.

#### Scenario: layout page receives background

- GIVEN a `DotsTemplate` with a non-null `defaultChrome`
- WHEN `DotsRenderer` renders a `DotsLayoutPage`
- THEN the first widget in the page stack has fill color `#fdfefd`

#### Scenario: elements page receives background

- GIVEN a `DotsTemplate` with a non-null `defaultChrome`
- WHEN `DotsRenderer` renders a `DotsElementsPage`
- THEN the first widget in the page stack has fill color `#fdfefd`

#### Scenario: spread page receives background

- GIVEN a `DotsAlbumSpreadPage` (non-cover) with header and footer supplied
- WHEN `buildAlbumSpreadPage` is called
- THEN the first widget in the page stack has fill color `#fdfefd`

#### Scenario: cover page stays chrome-free

- GIVEN a page built with `DotsAlbumSpreadPage.cover()`
- WHEN the page is rendered
- THEN no `#fdfefd` background widget is present in the page stack

#### Scenario: null defaultChrome produces no background

- GIVEN a `DotsTemplate` where `defaultChrome` is `null`
- WHEN `DotsRenderer` renders any page
- THEN no background color widget is added by the chrome layer

---

### Requirement: R2 — Header geometry and typography

When chrome is active and not suppressed, every interior page MUST render a header text band with:
- Y position: `9 mm` from the top edge.
- Box height: `3 mm`.
- Outer (left or right) X margin: `8 mm` from the page edge.
- Column layout: outer-left ≈ 27.585%, center ≈ 44.83%, outer-right ≈ 27.585% of page width.
- Font: `DotsFontRole.p22MackinacBook`, `9 pt`, line-height `10.8 pt`, left-aligned text within each cell.

#### Scenario: header Y position is 9 mm (regression — was 8 mm)

- GIVEN `buildPageChrome` is called with a chrome instance where `suppressHeader` is false
- WHEN the returned widget list is inspected
- THEN the header positioned widget has a top offset of `9 * _kMmToPt` points

#### Scenario: header font is P22 Mackinac Book 9 pt (regression — was Inter Semibold 7 pt)

- GIVEN `buildPageChrome` is called with a non-null `pageNumber` and `centerLabel`
- WHEN the returned widgets are inspected
- THEN every header text widget uses `DotsFontRole.p22MackinacBook` at `9 pt`
- AND no header text widget uses `DotsFontRole.interSemibold`

---

### Requirement: R3 — Page parity and header position assignment

Page parity MUST be determined by `pageNumber % 2 == 1` (1-based, odd = left page).
On a left page, `DotsPageChrome.pageNumber` MUST appear in the outer-LEFT column and
`DotsPageChrome.centerLabel` MUST contain `{DotbookName}` (supplied by caller), with no
right-column text. On a right page, `DotsPageChrome.pageNumber` MUST appear in the
outer-RIGHT column and `DotsPageChrome.centerLabel` MUST contain the context label
(supplied by caller), with no left-column text.

`DotsPageChrome.isLeftPage` MUST be set by the renderer from `pageNumber % 2 == 1` for
`DotsLayoutPage` and `DotsElementsPage`. `buildAlbumSpreadPage` MUST set `isLeftPage`
from its existing left/right header string presence.

#### Scenario: odd page number produces left-page layout

- GIVEN a `DotsPageChrome` with `isLeftPage: true`, `pageNumber: "3"`, `centerLabel: "Mi álbum"`
- WHEN `buildPageChrome` renders the header
- THEN the outer-LEFT column contains `"3"`
- AND the center column contains `"Mi álbum"`
- AND the outer-RIGHT column is empty

#### Scenario: even page number produces right-page layout

- GIVEN a `DotsPageChrome` with `isLeftPage: false`, `pageNumber: "4"`, `centerLabel: "2024"`
- WHEN `buildPageChrome` renders the header
- THEN the outer-RIGHT column contains `"4"`
- AND the center column contains `"2024"`
- AND the outer-LEFT column is empty

---

### Requirement: R4 — Footer geometry and typography

When chrome is active and not suppressed, the footer wordmark MUST be rendered:
- Position: bottom-RIGHT corner of the page, `8 mm` from the bottom edge, `8 mm` from the right edge.
- Font: `DotsFontRole.interSemibold`, `7 pt`, line-height `8.4 pt`.
- Alignment: right-aligned within its positioned container.
- Content: the value of `DotsPageChrome.wordmark` (typically `"Dots. Memories"`). A null or empty
  `wordmark` MUST suppress the footer entirely.

#### Scenario: footer is bottom-right at 8 mm margin (regression — was page-centered)

- GIVEN `buildPageChrome` is called with `wordmark: "Dots. Memories"` and `suppressFooter: false`
- WHEN the returned widgets are inspected
- THEN the footer positioned widget has `right: 8 * _kMmToPt` and `bottom: 8 * _kMmToPt`
- AND the text alignment is right-aligned

#### Scenario: footer uses Inter Semibold 7 pt

- GIVEN `buildPageChrome` is called with a non-null `wordmark`
- WHEN the footer text widget is inspected
- THEN it uses `DotsFontRole.interSemibold` at `7 pt`

#### Scenario: null wordmark suppresses footer

- GIVEN a `DotsPageChrome` with `wordmark: null`
- WHEN `buildPageChrome` renders the page
- THEN no footer widget is present in the returned list

---

### Requirement: R5 — Photo-overlap suppression for DotsLayoutPage

When rendering a `DotsLayoutPage`, the renderer MUST derive suppression flags from the solved
`List<DotsSlotRect>` BEFORE constructing the `DotsPageChrome` instance passed to `buildPageChrome`:

```
suppressHeader = slots.any((s) => s.bleedTop && s.yMm < geometry.headerBandMm)
suppressFooter = slots.any((s) => s.bleedBottom &&
                   (s.yMm + s.heightMm) > geometry.liveAreaBottomMm)
```

When `suppressHeader` is true, all header text widgets MUST be omitted. When `suppressFooter`
is true, the footer wordmark widget MUST be omitted. The background MUST still be rendered
regardless of suppression flags. `DotsElementsPage` renders chrome unconditionally (no suppression).

#### Scenario: bleedTop slot suppresses header text

- GIVEN a `DotsLayoutPage` whose solved slots include one with `bleedTop: true` and `yMm < 12`
- WHEN the page is rendered
- THEN no header text widgets appear in the page stack
- AND the `#fdfefd` background is still present

#### Scenario: bleedBottom slot suppresses footer

- GIVEN a `DotsLayoutPage` whose solved slots include one with `bleedBottom: true`
  and `yMm + heightMm > liveAreaBottomMm`
- WHEN the page is rendered
- THEN no footer wordmark widget appears in the page stack
- AND the `#fdfefd` background is still present

#### Scenario: no bleed slots — header and footer both render

- GIVEN a `DotsLayoutPage` whose solved slots have no bleed flags
- WHEN the page is rendered
- THEN both header text widgets and the footer wordmark are present

#### Scenario: elements page always renders chrome

- GIVEN a `DotsElementsPage` with a non-null `defaultChrome` on the template
- WHEN the page is rendered
- THEN header and footer are both rendered unconditionally

---

### Requirement: R6 — DotsPageChrome value object

`DotsPageChrome` MUST be an `@immutable` value object with hand-written `==` and `hashCode`
covering all six fields: `pageNumber`, `centerLabel`, `wordmark`, `isLeftPage`,
`suppressHeader`, `suppressFooter`. All fields are nullable or have bool defaults.
The class MUST be exported from `lib/dots_pdf.dart` with dartdoc on every public member
(required by `public_member_api_docs` lint).

#### Scenario: two identical chrome instances are equal

- GIVEN two `DotsPageChrome` instances constructed with identical field values
- WHEN `==` is evaluated
- THEN the result is `true` and both `hashCode` values match

#### Scenario: chrome instances differing on any field are not equal

- GIVEN two `DotsPageChrome` instances that differ in exactly one field
- WHEN `==` is evaluated
- THEN the result is `false`

---

### Requirement: R7 — DotsTemplate.defaultChrome field and contentHash participation

`DotsTemplate` MUST expose a nullable `DotsPageChrome? defaultChrome` field with `const` default
`null`. Adding this field MUST NOT break any existing `DotsTemplate` constructor call. The field
MUST be included in the `int get contentHash` computation so that templates differing only by
chrome produce different hash values.

#### Scenario: defaultChrome participates in contentHash

- GIVEN two otherwise-identical `DotsTemplate` instances where one has `defaultChrome` set
  and the other has `defaultChrome: null`
- WHEN `contentHash` is read on each
- THEN the two values differ

#### Scenario: identical chrome produces identical contentHash

- GIVEN two `DotsTemplate` instances with identical `defaultChrome`
- WHEN `contentHash` is read on each
- THEN the two values are equal

#### Scenario: null defaultChrome is backward-compatible

- GIVEN an existing `DotsTemplate` constructed without the `defaultChrome` argument
- WHEN it is rendered
- THEN the output is identical to output produced before this change (no chrome added)

---

### Requirement: R8 — buildPageChrome API surface

A top-level function `buildPageChrome` MUST exist in `lib/src/render/page_chrome.dart`
with signature:

```dart
List<pw.Widget> buildPageChrome(
  DotsPageChrome chrome,
  PdfPageFormat format,
  pw.Font? Function(DotsFontRole) fontResolver,
);
```

It MUST return the background widget as the FIRST element of the list so callers prepend
it before other content widgets. It MUST be the ONLY place in the codebase that draws
chrome (the inline chrome block in `album_spread_page.dart` lines 170–224 MUST be deleted).

#### Scenario: background is always the first returned widget

- GIVEN any `DotsPageChrome` instance
- WHEN `buildPageChrome` is called
- THEN `result[0]` is the full-bleed `#fdfefd` background widget

#### Scenario: old inline chrome path no longer exists

- GIVEN the file `lib/src/render/album_spread_page.dart`
- WHEN its source is inspected
- THEN there is no inline header/footer drawing block (lines 170–224 of the original are deleted)
- AND `buildAlbumSpreadPage` delegates to `buildPageChrome`

---

### Requirement: R9 — Album-spread page delegation (regression re-split)

`buildAlbumSpreadPage` MUST convert its `DotsSpreadHeader`/`DotsSpreadFooter` into a
`DotsPageChrome` and delegate to `buildPageChrome`. The existing test assertions in
`album_spread_page_test.dart` for R3/W3 MUST be re-split:
header positions assert `p22MackinacBook` (9 pt); footer asserts `interSemibold` (7 pt);
header Y asserts `9 mm`.

#### Scenario: spread page header uses P22 Mackinac Book (regression — was Inter Semibold)

- GIVEN a `DotsAlbumSpreadPage` with a non-null left or right page-number header
- WHEN the rendered page widgets are inspected
- THEN all header text widgets use `DotsFontRole.p22MackinacBook`

#### Scenario: spread page footer uses Inter Semibold

- GIVEN a `DotsAlbumSpreadPage` with a non-null wordmark footer
- WHEN the rendered page widgets are inspected
- THEN the footer text widget uses `DotsFontRole.interSemibold`

---

### Requirement: R10 — Backwards compatibility

Templates with `defaultChrome == null` MUST render identically before and after this change.
No existing test fixture MUST require modification due to this change (only the
R3/W3 font + geometry re-split in `album_spread_page_test.dart` is expected, as that test
previously asserted the wrong font).

#### Scenario: existing fixtures pass unchanged

- GIVEN any existing `DotsTemplate` fixture that does not set `defaultChrome`
- WHEN rendered with the updated renderer
- THEN all widget outputs are identical to those produced by the previous renderer

---

## Out of Scope

The following are explicitly EXCLUDED from this change and MUST NOT be implemented here:

- **Category-driven mandatory front/back matter** (dedication pages, "Antes de empezar",
  closing spreads, per-album-type spreads) — task 2.
- **`{tiempojuntos}` fallback resolution policy for parejas** — task 2.
- **Caption-displaces-center-label edge case** — deferred; no current layout solver slot
  places a caption in the header band.
- **Cover page chrome** — `DotsAlbumSpreadPage.cover()` stays chrome-free.
- **`DotsElementsPage` overlap suppression** — unconditional chrome; pt-to-mm conversion
  per element is out of scope.
- **Layout-solver geometry changes** — `headerBandMm: 12` / `footerBandMm: 12` are correct
  and unchanged.

---

## Acceptance Test List

The following test names MUST exist in `test/` to satisfy this spec:

- `buildPageChrome — background is first widget and has color #fdfefd`
- `buildPageChrome — header Y is 9 mm from top`
- `buildPageChrome — header font is p22MackinacBook at 9 pt`
- `buildPageChrome — left page: page number in outer-left, center label in center`
- `buildPageChrome — right page: page number in outer-right, center label in center`
- `buildPageChrome — footer font is interSemibold at 7 pt`
- `buildPageChrome — footer is positioned bottom-right at 8 mm from right and bottom`
- `buildPageChrome — null wordmark produces no footer widget`
- `buildPageChrome — suppressHeader omits header text widgets (background remains)`
- `buildPageChrome — suppressFooter omits footer widget (background remains)`
- `DotsLayoutPage render — chrome present: background + header + footer`
- `DotsLayoutPage render — bleedTop slot suppresses header; background present`
- `DotsLayoutPage render — bleedBottom slot suppresses footer; background present`
- `DotsLayoutPage render — no bleed slots: header and footer both render`
- `DotsElementsPage render — chrome always present unconditionally`
- `DotsPageChrome — equal instances satisfy == and share hashCode`
- `DotsPageChrome — differing instances do not satisfy ==`
- `DotsTemplate — defaultChrome null is backward-compatible; no chrome rendered`
- `DotsTemplate — defaultChrome participates in contentHash`
- `DotsTemplate — identical defaultChrome produces equal contentHash`
- `album_spread_page — header text uses p22MackinacBook (re-split R3)`
- `album_spread_page — footer text uses interSemibold (re-split W3)`
- `album_spread_page — header Y is 9 mm (regression)`
- `album_spread_page — footer is bottom-right 8 mm from edge (regression)`
- `album_spread_page — cover page has no background widget`
