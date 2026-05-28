# Proposal: page-template-chrome

## Intent

The new final design templates (`docs/templates/final_templates/pdf01_general_base.pdf`)
mandate a **shared page chrome** on every interior page: a `#fdfefd` background, a
three-position header trio (page number, dotbook name, context label), and a
bottom-right `Dots. Memories` footer wordmark. Today the library renders this chrome
on **exactly one** page type — `DotsAlbumSpreadPage`, via the inline path in
`buildAlbumSpreadPage` (`lib/src/render/album_spread_page.dart:170–224`). The two
page types that produce the bulk of a dotbook — `DotsLayoutPage` and
`DotsElementsPage` — render **zero chrome** (`dots_renderer.dart:338–392`): no
background, no header, no footer.

On top of the missing coverage, the one chrome path that exists is **wrong on four
counts** (all verified against current code):

1. Header Y is `8.0 mm` (`album_spread_page.dart:22`); the spec requires `9 mm`.
2. **Every** header label uses `DotsFontRole.interSemibold` 7 pt
   (`album_spread_page.dart:171`); the spec sheet annotates all three header
   positions as **P22 Mackinac *book* 9 pt / 10.8 pt line-height**. Only the footer
   wordmark stays Inter Semibold 7 pt / 8.4 pt.
3. The footer is rendered page-centered (`left: 0, right: 0, textAlign: center` —
   `album_spread_page.dart:215–221`); the spec requires bottom-**right**, 8 mm from
   the outer-right edge.
4. No page type sets the `#fdfefd` background.

This change is **task 1 of a 7-task series** that aligns PDF output with the final
templates. It is the foundation the rest depend on: it establishes a single chrome
primitive and applies it uniformly, deleting the divergent inline path. Doing it
first means tasks 2–7 build on correct, centralized chrome rather than re-deriving
it per page type.

**Success looks like:** one chrome helper, one chrome value object, the four bugs
fixed, and identical chrome on `DotsAlbumSpreadPage`, `DotsLayoutPage`, and
`DotsElementsPage` (cover excepted) — with the old inline path **deleted**, not
duplicated.

## Scope

### In Scope

- A new `@immutable` value object `DotsPageChrome` (header page number, center
  label, wordmark, `isLeftPage`, `suppressHeader`, `suppressFooter`) with
  hand-written `==`/`hashCode`.
- A new shared renderer helper `buildPageChrome(...)` in
  `lib/src/render/page_chrome.dart` that returns the chrome widgets
  (`List<pw.Widget>`) for a single page, applying the corrected geometry and fonts.
- A new optional `DotsPageChrome? defaultChrome` field on `DotsTemplate`
  (nullable, `const` default `null`, backward compatible), threaded into
  `contentHash` for cache correctness.
- Wiring `DotsRenderer.buildPage` to inject chrome into `_buildLayoutPage` and
  `_buildElementsPage`.
- Rewriting `buildAlbumSpreadPage` chrome to **delegate** to `buildPageChrome`,
  deleting the inline header/footer block (`album_spread_page.dart:170–224`).
- Applying the `#fdfefd` background to every interior page type via the chosen
  `package:pdf` mechanism.
- Fixing the four chrome bugs listed in Intent.
- Photo-overlap suppression for `DotsLayoutPage` only, derived from
  `DotsLayoutSolver.solve()` slot geometry.
- Updating `SPECS_interior.md` so its footer alignment (currently "center") matches
  the ground-truth PDF (right).
- Re-splitting the R3 / W3 regression in `album_spread_page_test.dart` (the existing
  "all header text is interSemibold" assertion is now false by design).

### Out of Scope (explicit)

- **Category mandatory front/back matter (task 2).** This task does NOT decide,
  generate, or position dedication / "Antes de empezar" / closing / per-album-type
  spreads, nor the per-type context-label *resolution* policy. `DotsPageChrome`
  carries the already-resolved strings; *who* computes them per album type is task 2.
- **Cover chrome.** `DotsAlbumSpreadPage.cover()` already builds a chrome-free page
  (header trio all-null, footer wordmark empty — verified at
  `dots_template.dart:1374–1393` and the surrounding factory). It stays chrome-free.
  It is the explicit chrome exclusion.
- **Caption-displaces-center-label** edge case (see Decision 5) — deferred.
- **`{tiempojuntos}` fallback policy** (see Decision 5) — deferred to task 2.
- Any decorative element work, layout-solver changes, or geometry-band resizing
  (`headerBandMm`/`footerBandMm` are already correct at 12 mm each —
  `dots_page_geometry.dart:21–28`).

## Approach

**Approach A (confirmed).** The exploration evaluated three approaches; A is
correct and I confirm it. B (renderer closure) loses cache coverage because the
closure is not part of `DotsTemplate.contentHash`, and the chrome state
(dotbook name, parity, suppression) would live in an untestable stateful closure.
C (reuse `DotsSpreadHeader` on every page type) is a semantic mismatch:
`DotsSpreadHeader` models three positions across a 406 mm spread, while
single-page chrome is "page number on one outer edge + one center label" — forcing
the spread model onto single pages duplicates chrome data across three type
hierarchies and forces `DotsLayoutPliego` to grow fields. A gives a single source
of truth, a dedicated testable type, cache coverage via `contentHash`, and zero
double-render risk because the old inline path is deleted.

### Public API delta

Two new public symbols, both exported from `lib/dots_pdf.dart` with dartdoc
(the `public_member_api_docs` lint is a build failure):

```dart
/// Immutable description of the shared chrome (background, header trio, footer
/// wordmark) drawn on a single interior page.
@immutable
class DotsPageChrome {
  const DotsPageChrome({
    this.pageNumber,
    this.centerLabel,
    this.wordmark,
    this.isLeftPage = true,
    this.suppressHeader = false,
    this.suppressFooter = false,
  });

  final String? pageNumber;   // outer-left on left pages, outer-right on right pages
  final String? centerLabel;  // dotbook name (left) or context label (right)
  final String? wordmark;     // "Dots. Memories"; null/empty suppresses footer
  final bool isLeftPage;
  final bool suppressHeader;
  final bool suppressFooter;
  // hand-written == / hashCode over all six fields
}
```

And one additive field on `DotsTemplate`:

```dart
const DotsTemplate({
  required this.documentId,
  required this.pageSize,
  this.albumType,
  this.defaultChrome,        // <-- NEW, nullable, default null
  this.pages = _emptyPages,
  this.pliegos = _emptyPliegos,
});

final DotsPageChrome? defaultChrome;
```

**Cache-key correction (verified against code):** `DotsTemplate` does **not** have a
hand-written `operator ==` / `hashCode`. Cache invalidation runs through the
`int get contentHash => Object.hash(...)` getter (`dots_template.dart:1977–1983`).
`defaultChrome` MUST be added to `contentHash` (not to a nonexistent `==`/`hashCode`
pair). The task brief's "add to both `==`/`hashCode`" wording referred to the
sibling models (`DotsSpreadHeader`/`DotsSpreadFooter`, which DO hand-write both);
for `DotsTemplate` the single correct site is `contentHash`. The NEW
`DotsPageChrome` value object follows the project `@immutable` convention and
hand-writes its own `==`/`hashCode`.

### Renderer wiring

`buildPageChrome` is the only place chrome is drawn. Signature mirrors the existing
renderer style (font resolution is passed in, as `buildAlbumSpreadPage` already
does):

```dart
List<pw.Widget> buildPageChrome(
  DotsPageChrome chrome,
  PdfPageFormat format,
  pw.Font? Function(DotsFontRole) fontResolver,
);
```

- `DotsRenderer.buildPage` reads `template.defaultChrome` and forwards it to
  `_buildLayoutPage` / `_buildElementsPage`.
- For `DotsLayoutPage`, the renderer already has the solved
  `List<DotsSlotRect>` before drawing chrome (`dots_renderer.dart:362`). It derives
  `suppressHeader` / `suppressFooter` from those slots and produces a derived
  `DotsPageChrome` (copy of `defaultChrome` with the suppression flags + correct
  parity). Suppression logic is O(N) over a ≤ 8-entry list.
- For `DotsElementsPage`, chrome renders unconditionally (element bounding boxes are
  in pt, not mm bleed-flagged; overlap detection would need per-element conversion —
  out of scope and not currently needed).
- `buildAlbumSpreadPage` converts its `DotsSpreadHeader`/`DotsSpreadFooter` into a
  `DotsPageChrome` and calls `buildPageChrome`, deleting lines 170–224.

### Corrected chrome geometry / fonts (applied in `buildPageChrome`)

- Background `#fdfefd` on every chrome page (see Decision 3).
- Header Y = `9 mm` from top (fixes bug 1).
- Header text font = **`DotsFontRole.p22MackinacBook`** 9 pt / 10.8 pt line-height
  for all three positions (fixes bug 2). `p22MackinacBook` verified present at
  `dots_font_bundle.dart:65`.
- Header outer X margins = 8 mm; center label left-aligned within its center column
  (columns ≈ 27.585% / 44.83% / 27.585% of page width).
- Footer wordmark = `Inter Semibold` 7 pt / 8.4 pt, bottom-right, 8 mm from bottom
  and 8 mm from right (fixes bug 3).
- Page parity drives side placement (see Decision 2).

## Affected Areas

| Area | Impact | Description |
|------|--------|-------------|
| `lib/src/render/page_chrome.dart` | **New** | `buildPageChrome` helper + corrected chrome constants. |
| `lib/src/config/dots_template.dart` | Modified | New `DotsPageChrome` value object; `defaultChrome` field on `DotsTemplate`; add to `contentHash`. |
| `lib/src/render/album_spread_page.dart` | Modified | Delete inline chrome (170–224); delegate to `buildPageChrome`. Remove now-stale chrome constants (`_kHeaderY`, etc.). |
| `lib/src/render/dots_renderer.dart` | Modified | `buildPage` threads `defaultChrome`; `_buildLayoutPage` derives suppression + parity and injects chrome; `_buildElementsPage` injects chrome unconditionally. |
| `lib/dots_pdf.dart` | Modified | Export `DotsPageChrome` (with dartdoc). |
| `docs/templates/SPECS_interior.md` | Modified | Footer alignment center → bottom-right (match PDF ground truth). |
| `test/render/album_spread_page_test.dart` | Modified | Re-split R3/W3: header roles = `p22MackinacBook`, footer role = `interSemibold`. |
| `test/render/layout_page_render_test.dart` | New tests | Chrome assertions on layout pages, incl. suppression. |
| `test/render/page_chrome_test.dart` (or equiv.) | New tests | Unit tests for `buildPageChrome` geometry/font/parity/suppression. |

## Bugs Fixed (4)

1. **Header Y off by 1 mm** — `_kHeaderY = 8.0` → `9.0` mm.
2. **Wrong header font** — all three header positions move from
   `DotsFontRole.interSemibold` 7 pt to `DotsFontRole.p22MackinacBook` 9 pt /
   10.8 pt LH. Footer stays Inter Semibold 7 pt / 8.4 pt.
3. **Footer alignment** — page-centered → bottom-right, 8 mm from the right edge.
4. **Missing background** — `#fdfefd` now drawn on every chrome page.

## Decisions (resolving the 6 required + explore open questions)

1. **Approach: A — confirmed.** `DotsPageChrome` value object + `buildPageChrome`
   helper, threaded via `DotsTemplate.defaultChrome`; old inline path deleted.
   (Rationale above.)
2. **Page-parity convention: `pageNumber % 2 == 1` ⇒ left page.** Left page:
   page number in outer-LEFT column, center = `{DotbookName}`, no right value.
   Right page (`pageNumber % 2 == 0`): center = context label, page number in
   outer-RIGHT column. The renderer sets `DotsPageChrome.isLeftPage` from this rule;
   `buildAlbumSpreadPage` sets it from its existing left/right header strings.
3. **Background implementation: full-size `pw.Container` as the first child of the
   existing `pw.Stack`.** All page types already build via
   `pw.Page(pageFormat: format, build: (ctx) => pw.Stack(children: children))`
   (verified at `dots_renderer.dart:348–351, 388–391` and
   `album_spread_page.dart:270–273`). Prepending a `pw.Positioned.fill` /
   full-size container with `#fdfefd` fits this `pw.Stack` pattern with zero
   structural change and keeps the bleed area covered. We do NOT switch to
   `PageTheme`/`buildBackground` — that would diverge from the established Stack-based
   build path used by all four page builders and complicate crop-mark ordering.
   `buildPageChrome` returns the background as the first widget so callers prepend it
   before their content.
4. **Chrome exclusions: cover only.** `DotsAlbumSpreadPage.cover()` stays
   chrome-free (verified: header all-null, footer empty). No other page type is
   excluded. (Covers are not driven by `defaultChrome`; they are pre-built factories.)
5. **`{tiempojuntos}` fallback and caption-displacement: BOTH deferred.**
   - `{tiempojuntos}` fallback for `parejas` is a context-label *resolution* concern
     owned by the album-type matter work — task 2. This task only renders the string
     it is given.
   - Caption-displaces-center-label: verified that no current layout-solver slot
     enters the header band except `l1b` (`bleedTop: true`), which is handled by
     header *suppression*, not displacement. No caption slot enters the header band
     today. We therefore DEFER the displacement edge case — explicitly out of scope
     for task 1. If a future layout introduces a header-band caption, it is a new
     change.
6. **`SPECS_interior.md` footer update: IN SCOPE.** The PDF template is ground
   truth; the doc currently says bottom-center. We update it to bottom-right (8 mm
   from right) as part of this task so the spec and the renderer agree from day one.

## Risks

| Risk | Likelihood | Mitigation |
|------|------------|------------|
| **Breaking change to `DotsTemplate`** (new `defaultChrome` field). | Low | Field is nullable with `const` default `null`; `const` constructor signature stays valid for existing callers. Existing templates parse/render identically (no chrome unless `defaultChrome` is set). |
| **`contentHash` must include `defaultChrome`** or cached artifacts go stale when chrome changes. | Medium | Add `defaultChrome` to the `Object.hash(...)` getter; add a unit test asserting two templates differing only by chrome produce different `contentHash`. |
| **R3/W3 test regression** in `album_spread_page_test.dart`: line 292 asserts every header role is `interSemibold` and line 268 asserts the single header role is `interSemibold` — both now false. | High (certain) | Re-split: header positions assert `p22MackinacBook`; add a separate footer assertion for `interSemibold`. Update `kHeaderFontRoleForTest` (or introduce a header-vs-footer pair) so the test surface matches the new two-font reality. |
| **Stale chrome constants** left in `album_spread_page.dart` after deleting the inline path (`_kHeaderY`, `kHeaderFontRoleForTest`, etc.). | Medium | Move the canonical constants into `page_chrome.dart`; delete or re-point the `@visibleForTesting` exports the spread tests import. |
| **Background covers crop marks** if drawn last instead of first. | Low | `buildPageChrome` returns background as the FIRST widget; crop marks are appended last (existing order preserved). |
| **Parity mismatch** between solver-driven layout pages and spread pages. | Low | Single `pageNumber % 2 == 1` rule applied in one place per builder; covered by unit tests. |

## Testing Strategy

The team runs **strict TDD** (`MemoryFileSystem` + `mocktail`, `flutter test` /
`flutter analyze`). Tests ship FIRST, often as RED placeholders when the series is
delivered as chained PRs.

- **`page_chrome_test.dart` (new):** unit-test `buildPageChrome` against the
  corrected spec — header Y = 9 mm, header font = `p22MackinacBook` 9 pt, footer
  font = `interSemibold` 7 pt bottom-right 8 mm, parity placement, and both
  suppression flags. Written RED first.
- **`layout_page_render_test.dart` (extend):** assert layout pages now emit
  background + header + footer; assert header/footer suppression when an `l1b`-style
  `bleedTop` slot overlaps the band; assert `DotsElementsPage` renders chrome
  unconditionally.
- **`album_spread_page_test.dart` (re-split):** the R3/W3 font assertions are split
  into header (`p22MackinacBook`) vs footer (`interSemibold`); existing geometry
  assertions updated for Y = 9 mm and right-aligned footer.
- **`DotsTemplate.contentHash` test:** two templates differing only by
  `defaultChrome` hash differently; identical chrome hashes equally.
- **Backward-compat test:** a template with `defaultChrome == null` renders no chrome
  (existing fixtures unchanged).
- `flutter analyze` must stay clean — every new public symbol (`DotsPageChrome` and
  its members, `defaultChrome`) carries dartdoc or the `public_member_api_docs` lint
  fails the build.

## Size Estimate (for the Review Workload Guard)

Rough order-of-magnitude, to inform later PR-splitting:

- `DotsPageChrome` value object + `defaultChrome` field + `contentHash`: ~70–90 LOC.
- `page_chrome.dart` helper (incl. background + corrected geometry/fonts): ~120–160
  LOC.
- `dots_renderer.dart` wiring + suppression derivation: ~50–70 LOC.
- `album_spread_page.dart` delete-and-delegate (net may be near zero or negative):
  ~−40 to +20 LOC.
- `lib/dots_pdf.dart` export + dartdoc: ~10 LOC.
- `SPECS_interior.md`: ~5 LOC.
- Tests (new + re-split): ~250–350 LOC.

**Estimated total ≈ 550–700 LOC**, test-heavy. This is **above the 400-line budget**,
so this task is a likely candidate for a chained/stacked split at the tasks phase —
e.g. PR1 = model + helper + tests (RED), PR2 = renderer wiring + spread delegation +
spec doc (GREEN). Flagging here so the Review Workload Guard can decide.

## Rollback Plan

All production changes are additive or behind the nullable `defaultChrome`. Rollback
= revert the slice commits. Templates without `defaultChrome` render exactly as
before; the only non-additive change is the corrected chrome on `DotsAlbumSpreadPage`,
which is a bug fix toward the ground-truth spec.
