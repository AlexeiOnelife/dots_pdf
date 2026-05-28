# Design: page-template-chrome

## Technical Approach

Approach A (confirmed). Introduce one `@immutable` value object `DotsPageChrome` and one
pure helper `buildPageChrome(...)` that returns the chrome widgets (background + header
trio + footer wordmark) as a `List<pw.Widget>`. Every interior page builder prepends that
list to its existing `pw.Stack` children. `DotsAlbumSpreadPage` stops rendering chrome
inline and delegates to the same helper, so chrome lives in exactly one place. A nullable
`DotsTemplate.defaultChrome` field carries the resolved strings into the renderer and is
threaded into `contentHash`. All four chrome bugs are fixed inside the helper. Strings are
already resolved by the caller (task 2 owns resolution); this task only renders them.

## Architecture Decisions

### Decision: Home file for `DotsPageChrome` — `dots_template.dart`

| Option | Pro | Con | Decision |
|---|---|---|---|
| `dots_template.dart` | Sits beside `DotsSpreadHeader`/`DotsSpreadFooter`/`DotsTemplate`; `defaultChrome` references it without a new import; re-exported automatically | One more class in a large file | **Chosen** |
| New `lib/src/config/page_chrome.dart` | Smaller files | Splits the chrome-config triplet across files; needs an extra import in `dots_template.dart` and a new export line | Rejected |

Rationale: it is a config value object semantically identical to the existing spread
header/footer models, which already live in `dots_template.dart`. The *renderer* helper
(`buildPageChrome`) goes in `lib/src/render/page_chrome.dart`; the *data* goes in config.

### Decision: Background as first `pw.Stack` child (full-size container)

| Option | Pro | Con | Decision |
|---|---|---|---|
| `pw.Positioned.fill(child: pw.Container(color))` first in Stack | Zero structural change — all 4 builders already use `pw.Stack`; crop marks stay last | None material | **Chosen** |
| `PageTheme` / `buildBackground` | Idiomatic pdf-package background | Diverges from the established Stack path; complicates crop-mark ordering | Rejected |

`buildPageChrome` returns the background widget FIRST so callers prepend it before content
and crop marks remain appended last.

### Decision: Cache key — thread into `contentHash`, not `==`/`hashCode`

`DotsTemplate` has no hand-written equality; invalidation runs through
`int get contentHash => Object.hash(...)` (`dots_template.dart:1977-1983`). Add
`defaultChrome` as a new argument there. The new `DotsPageChrome` value object hand-writes
its own `==`/`hashCode` over all six fields (project `@immutable` convention), so its hash
participates correctly inside `Object.hash`.

### Decision: Parity rule — `pageNumber % 2 == 1` ⇒ left page

Set in one place per builder. Left page: page number outer-LEFT, center = dotbook name.
Right page: page number outer-RIGHT, center = context label. `buildAlbumSpreadPage` derives
`isLeftPage` from which of `leftPageNumber`/`rightPageNumber` is non-null.

### Decision: Suppression scope — layout pages only

`_buildLayoutPage` has the solved `List<DotsSlotRect>` (mm + bleed flags) before drawing
chrome; it derives suppression and overrides the chrome. `_buildElementsPage` renders chrome
unconditionally (element boxes are pt, not mm-bleed-flagged — overlap detection is out of
scope). Cover pages stay chrome-free (not driven by `defaultChrome`).

## Data Flow

    DotsTemplate.defaultChrome ──► DotsRenderer.buildPage
         │                               │
         │            ┌──────────────────┼───────────────────┐
         ▼            ▼                  ▼                   ▼
    _buildLayoutPage   _buildElementsPage    buildAlbumSpreadPage
    (derive suppress   (chrome as-is,        (DotsSpreadHeader/Footer
     + parity from      parity from           → DotsPageChrome)
     solved slots)      page.pageNumber)
         └──────────────┴──────────────────────┴── buildPageChrome(chrome, format, fontFor)
                                                          │
                                                          ▼
                                  [ background, header labels…, footer ]  (prepended to Stack)

## File Changes

| File | Action | Description |
|---|---|---|
| `lib/src/render/page_chrome.dart` | Create | `buildPageChrome` helper + chrome constants (`#fdfefd`, 9 mm header Y, 8 mm margins, fonts/sizes, column ratios) + `@visibleForTesting` constants. |
| `lib/src/config/dots_template.dart` | Modify | Add `DotsPageChrome` value object; add `defaultChrome` ctor param + field; add to `contentHash` (`:1977-1983`). |
| `lib/src/render/album_spread_page.dart` | Modify | Delete inline chrome (`:170-224`) + stale constants (`_kHeaderLeftX`,`_kHeaderY`,`_kFooterBottomMarginMm`,`_kHeaderFontSize`,`kHeaderFontSizeForTest`,`kHeaderFontRoleForTest`); build a `DotsPageChrome` from header/footer and prepend `buildPageChrome(...)`. |
| `lib/src/render/dots_renderer.dart` | Modify | `buildPage` forwards `template.defaultChrome`; `_buildLayoutPage` derives suppression+parity and prepends chrome; `_buildElementsPage` prepends chrome unconditionally. |
| `lib/dots_pdf.dart` | Modify | Export `DotsPageChrome` with dartdoc. |
| `docs/templates/SPECS_interior.md` | Modify | Footer alignment center → bottom-right (8 mm). |
| `test/render/page_chrome_test.dart` | Create | Geometry/font/parity/suppression unit tests. |
| `test/render/album_spread_page_test.dart` | Modify | Re-split R3/W3 (header = `p22MackinacBook`, footer = `interSemibold`); update import + geometry. |
| `test/render/layout_page_render_test.dart` | Modify | Chrome presence + suppression on layout pages; unconditional on elements pages. |
| `test/config/dots_template_test.dart` | Modify | `contentHash` sensitivity to `defaultChrome`. |

## Interfaces / Contracts

```dart
@immutable
class DotsPageChrome {
  const DotsPageChrome({
    this.pageNumber, this.centerLabel, this.wordmark,
    this.isLeftPage = true, this.suppressHeader = false, this.suppressFooter = false,
  });
  final String? pageNumber;   // outer-left (left page) / outer-right (right page)
  final String? centerLabel;  // dotbook name (left) | context label (right)
  final String? wordmark;     // null/empty ⇒ no footer
  final bool isLeftPage, suppressHeader, suppressFooter;
  // hand-written == / hashCode over all six fields
}

// lib/src/render/page_chrome.dart — returns background FIRST.
List<pw.Widget> buildPageChrome(
  DotsPageChrome chrome, PdfPageFormat format, pw.Font? Function(DotsFontRole) fontResolver);
```

Helper geometry (mm→pt via `2.834645669`): background `pw.Positioned.fill` `PdfColor(0xFD/255, 0xFE/255, 0xFD/255)`.
Header Y = `9 * mmToPt`, outer X = `8 * mmToPt`; columns `0.27585 / 0.4483 / 0.27585` of
`format.width` — page number in the outer column on the parity side, center label
left-aligned in the center column (`left: 0.27585*width`, `width: 0.4483*width`). Header font
`DotsFontRole.p22MackinacBook` 9 pt / `lineSpacing 9*(1.2-1)`. Footer
`DotsFontRole.interSemibold` 7 pt / `lineSpacing 7*(1.2-1)`, `right: 8*mmToPt`,
`top: format.height - 8*mmToPt`, `textAlign: right`. `suppressHeader` omits the three header
widgets; `suppressFooter` (or empty wordmark) omits the footer.

Suppression predicate (in `_buildLayoutPage`, `geometry = DotsPageGeometry.dotbookDefault()`):

```dart
suppressHeader = slots.any((s) => s.bleedTop    && s.yMm < geometry.headerBandMm);
suppressFooter = slots.any((s) => s.bleedBottom && s.yMm + s.heightMm > geometry.liveAreaBottomMm);
```

`buildAlbumSpreadPage` maps its spread chrome to the single-page model: a spread page is one
renderer page, so `pageNumber` = whichever of `leftPageNumber`/`rightPageNumber` is set,
`isLeftPage` = `leftPageNumber != null`, `centerLabel` = `header.centerLabel`,
`wordmark` = `footer.wordmark`.

## Testing Strategy

| Layer | What | Approach |
|---|---|---|
| Unit | `buildPageChrome` Y=9mm, header `p22MackinacBook` 9pt, footer `interSemibold` 7pt right-8mm, parity placement, both suppression flags | Drive via `fontResolver` spy + walk returned `pw.Positioned` list; RED first |
| Unit | Background present per page type (`#fdfefd` first child) | Build each page type with `defaultChrome`, assert first Stack child color |
| Unit | Suppression predicate over `DotsSlotRect` (`l1b` bleedTop case) | Solve a layout with a header-overlapping slot; assert header omitted |
| Unit | `contentHash` differs iff `defaultChrome` differs | Two templates equal but for chrome |
| Unit | Backward-compat: `defaultChrome == null` ⇒ no chrome | Existing fixtures unchanged |
| Unit | R3/W3 re-split | Header roles = `p22MackinacBook`; footer role = `interSemibold` |

Strict TDD: helper is pure (font resolution injected, no I/O) and testable in isolation with
`MemoryFileSystem`; tests authored RED first. `flutter analyze` must stay clean — every new
public symbol carries dartdoc (`public_member_api_docs`).

## Migration / Rollout

Additive and backward compatible: `defaultChrome` is nullable with `const` default `null`;
`const` constructor stays valid. Templates without it render identically. The only behavior
change is corrected chrome on `DotsAlbumSpreadPage` (a bug fix). Rollback = revert commits.
Likely 2-PR split at tasks phase (PR1 model+helper+RED tests; PR2 wiring+delegation+spec).

## Open Questions

- [ ] None blocking. `{tiempojuntos}` fallback and caption-displacement are deferred to task 2 (per proposal Decision 5).
