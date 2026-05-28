# Exploration: Base Page Template (Chrome) — page-template-chrome

**Date:** 2026-05-27
**Change:** page-template-chrome
**Phase:** explore
**Status:** complete

---

## Current State

Chrome rendering today exists ONLY in `DotsAlbumSpreadPage`.

`lib/src/render/album_spread_page.dart` — function `buildAlbumSpreadPage` (lines 159–274) —
renders the header trio and footer wordmark. Key constants (lines 19–33):

```dart
const double _kHeaderLeftX  = 8.0 * _kMmToPt;   // 8 mm from outer edge
const double _kHeaderY      = 8.0 * _kMmToPt;   // 8 mm from top — WRONG (spec: 9 mm)
const double _kFooterBottomMarginMm = 8.0;       // 8 mm from bottom — correct
const double _kHeaderFontSize = 7.0;             // 7 pt — correct for pg-num/footer
// DotsFontRole.interSemibold used for ALL labels — WRONG for center labels
```

Footer is rendered at `left: 0, right: 0, textAlign: center` — WRONG (spec: bottom-right,
8 mm from right edge).

No page background color is set on any page type (`#fdfefd` required by spec on all pages).

**The two other page types render ZERO chrome:**

- `DotsRenderer._buildLayoutPage` (`lib/src/render/dots_renderer.dart` lines 354–392):
  photo + caption slots + crop marks only. No header, no footer, no background color.
- `DotsRenderer._buildElementsPage` (lines 338–352): explicit element widgets + crop marks only.

**`DotsPageGeometry.dotbookDefault()`** (`lib/src/render/layout/dots_page_geometry.dart` lines 21–28)
already reserves `headerBandMm: 12` and `footerBandMm: 12`, and `DotsLayoutSolver` places all
slots within `[liveAreaTopMm=12mm, liveAreaBottomMm=242mm]`. The live area is correct; the chrome
is simply never rendered into the header/footer bands for layout and elements pages.

**`DotsSpreadHeader` model** (`lib/src/config/dots_template.dart` lines 1031–1060) has three
nullable string fields: `leftPageNumber`, `centerLabel`, `rightPageNumber`. It does NOT distinguish
left-page `{DotbookName}` from right-page context label — callers supply the correct string per page.

**`DotsAlbumType` and `DotsAlbumTypeContext`** (`lib/src/api/dots_album_type.dart`) already encode
the context label per type:
- boda / hijos → `{Protagonistas}`
- parejas → `{tiempojuntos}`
- individuales / otros → `{Año}`

`DotsLayoutPage` and `DotsElementsPage` carry NO chrome data (no DotbookName, no album type, no
context label field). This data must come from the template or a new side-channel.

---

## Spec Sheet Verified Values (PDF page 1 of `docs/templates/final_templates/pdf01_general_base.pdf`)

| Property | Spec | Current Code | Gap |
|---|---|---|---|
| Page background | `#fdfefd` all pages | None (white) | YES — missing |
| Header Y from top | 9 mm | 8 mm | YES — 1 mm off |
| Header outer X margins | 8 mm | 8 mm | Match |
| Header box height | 3 mm | Not enforced | Minor |
| **ALL header text** (pg-num + DotbookName + Año) | **P22 Mackinac Book 9 pt / 10.8 pt LH** | Inter Semibold 7 pt | YES — wrong font for every header label |
| Footer font | Inter Semibold 7 pt / 8.4 pt LH | Inter Semibold 7 pt | Match |
| Footer box height | 2.392 mm | Not enforced | Minor |
| Footer alignment | Bottom-right (8 mm from right) | Center-aligned | YES — conflict with old spec |
| Footer Y from bottom | 8 mm | 8 mm | Match |

**Header column widths** (from spread percentage annotations): 27.585% / 44.83% / 27.585%.
On a 203 mm page: outer columns ≈ 56 mm each, center column ≈ 91 mm.
The center label is left-aligned within its column — NOT page-centered.

**Footer conflict:** `SPECS_interior.md` says "bottom-center wordmark". The final template PDF
clearly shows bottom-right with 8 mm right margin. The PDF template is the ground truth.
`SPECS_interior.md` must be updated.

**Single-page chrome layout (from PDF pages 2–4):**
- Left page: outer-left = Nº página, center = `{DotbookName}`, no right-center.
- Right page: center = context label (type-dependent), outer-right = Nº página.
- Page numbering: use `pageNumber % 2 == 1` for left pages (odd pages in 1-based scheme).

---

## Confirmed Bugs in Current `buildAlbumSpreadPage` Chrome

These four bugs exist today and must be fixed in the extraction:

1. **Header Y off by 1 mm:** `_kHeaderY = 8.0 * _kMmToPt` → must be `9.0 * _kMmToPt`.
2. **ALL header labels use the wrong font:** every header label (page numbers, `{DotbookName}`,
   `{Año}`) currently uses `DotsFontRole.interSemibold` 7 pt. The spec sheet annotates ALL THREE
   header text positions as **P22 Mackinac *book* 9 pt / 10.8 pt line-height** (`Altura caja: 3 mm`,
   `Align-text: left`). The footer wordmark is the ONLY chrome text that stays Inter Semibold 7 pt /
   8.4 pt. Verify `DotsFontRole.p22MackinacBook` exists (P22 Mackinac *book*, not *medium*).
3. **Footer wrong alignment:** Currently `left: 0, right: 0, textAlign: center`.
   Must be `right: 8.0 * _kMmToPt, textAlign: right` (right-aligned, 8 mm from outer-right).
4. **Missing page background:** No `#fdfefd` background on any page type.

---

## Affected Areas

| File | Role | Change needed |
|---|---|---|
| `lib/src/render/album_spread_page.dart` | Current chrome source | Extract chrome to shared helper; fix 4 bugs |
| `lib/src/render/dots_renderer.dart` | `_buildLayoutPage`, `_buildElementsPage`, `buildPage` | Inject chrome for layout + elements pages |
| `lib/src/render/layout/dots_page_geometry.dart` | Chrome geometry | May add chrome geometry constants |
| `lib/src/config/dots_template.dart` | `DotsTemplate`, page models | Add `defaultChrome` field OR leave pages unchanged (per approach) |
| `lib/dots_pdf.dart` | Public API | Export any new chrome model |
| `test/render/album_spread_page_test.dart` | Chrome tests R3 | Split R3 assertion (pg-num font ≠ center font) |
| `test/render/layout_page_render_test.dart` | Layout rendering | Add chrome assertions |

---

## Photo-Overlap Suppression

`DotsLayoutSolver.solve()` returns `List<DotsSlotRect>` (mm coords, bleed flags). The renderer
already has this list before drawing chrome. Suppression logic:

```
suppressHeader = slots.any(
  (s) => s.bleedTop && s.yMm < geometry.headerBandMm   // e.g. l1b oversized-bleed
);
suppressFooter = slots.any(
  (s) => s.bleedBottom && (s.yMm + s.heightMm) > geometry.liveAreaBottomMm
);
```

This is O(N) over a list that is always ≤ 8 entries. When `suppressHeader` is true, the header
text widgets are omitted (per spec: "texts are omitted when a photo covers their zone"). When
`suppressFooter` is true, the footer wordmark is omitted.

Currently no layout code produces `bleedTop: true` slots except `l1b`
(`yMm ≈ 8mm, heightMm = 238mm, bleedTop: true`). The header starts at 9mm
so the l1b slot's top edge overlaps the header band.

Scope: suppression applies to `DotsLayoutPage` only (solver output is available). `DotsElementsPage`
renders chrome unconditionally (element bounding boxes are not in mm and overlap detection would
require pt conversion per element).

---

## Approaches

### Approach A — Shared `DotsPageChrome` Model + `buildPageChrome` Function (RECOMMENDED)

Define `@immutable class DotsPageChrome` with:
- `String? pageNumber` — rendered in outer-left (left pages) or outer-right (right pages)
- `String? centerLabel` — DotbookName (left pages) or context label (right pages)
- `String? wordmark` — "Dots. Memories" or null to suppress
- `bool suppressHeader` — suppresses all header widgets when true
- `bool suppressFooter` — suppresses footer when true
- `bool isLeftPage` — drives which side page-number and center label appear on

Extract chrome rendering into `lib/src/render/page_chrome.dart`:
```dart
List<pw.Widget> buildPageChrome(DotsPageChrome chrome, PdfPageFormat format,
    pw.Font? Function(DotsFontRole) fontResolver);
```

Add `DotsPageChrome? defaultChrome` to `DotsTemplate` (nullable, optional field with
`const` default `null` — backward compatible).

`DotsRenderer.buildPage` passes `template.defaultChrome` to `_buildLayoutPage` and
`_buildElementsPage`. For layout pages, the renderer derives `suppressHeader`/`suppressFooter`
from the solved slots and passes a derived `DotsPageChrome` override.

`buildAlbumSpreadPage` converts `DotsSpreadHeader`/`DotsSpreadFooter` into a `DotsPageChrome`
and delegates to `buildPageChrome` — removing the old inline chrome path entirely.

**Pros:** Single source of truth. Centrally testable. Clean `@immutable` model. Cache covers chrome
via `DotsTemplate.hashCode`. No double-render risk (old path deleted).

**Cons:** `DotsTemplate` gains a field (minor). Callers constructing `DotsLayoutPage`/`DotsElementsPage`
must populate `defaultChrome` on the template to get chrome — opt-in but requires awareness.

**Effort:** Medium.

---

### Approach B — Chrome Resolver Callback on `DotsRenderer`

Add `DotsPageChrome? Function(DotsPage page)? chromeResolver` to `DotsRenderer`. Exclude
`DotsAlbumSpreadPage` from the callback path (it has its own chrome). `renderPagesToFile` calls
the resolver per page before `buildPage`.

**Pros:** Zero changes to `DotsTemplate` or page models. Fully opt-in.

**Cons:** Closure is stateful (needs DotbookName, album type, page parity). Not captured in cache
hash. Less discoverable. Harder to test in isolation.

**Effort:** Medium-Low wiring, Medium-High design.

---

### Approach C — `DotsSpreadHeader?` / `DotsSpreadFooter?` Fields on `DotsLayoutPage` and `DotsElementsPage`

Reuse the existing model. Add `header`/`footer` fields to `DotsLayoutPage` and `DotsElementsPage`.

**Pros:** Consistent pattern with spread pages. Hash coverage automatic.

**Cons:** `DotsSpreadHeader` is designed for spread chrome (3 positions across a spread). Single-page
chrome needs different semantics (outer-left OR outer-right, one center). Model is misaligned. Chrome
data duplicated across 3 type hierarchies. `DotsLayoutPliego` must grow fields.

**Effort:** Medium.

---

### Comparison Table

| Criterion | Approach A | Approach B | Approach C |
|---|---|---|---|
| Model clarity | High (dedicated type) | Low (closure) | Medium (reuse spread model) |
| Cache correctness | Via template hash | External — not in hash | Via page hashCode |
| Backward compatibility | Template field addition | Full opt-in | Page model addition |
| Double-render risk | None (old path deleted) | Explicit exclusion | Null-check |
| Overlap suppression | Clean (pre-chrome pass) | In resolver closure | In `_buildLayoutPage` |
| Testability | High | Medium | High |
| Effort | Medium | Medium | Medium |

**Recommendation: Approach A.**

---

## Open Questions for Proposal/Spec

1. `DotsTemplate.defaultChrome` field vs `renderPagesToFile` side-channel? (Template field
   preferred for cache correctness.)
2. Left/right page parity convention: `pageNumber % 2 == 1` = left page? Confirm.
3. `{tiempojuntos}` fallback for parejas: caller responsibility or library rule?
4. Caption text displacing center label: is any current layout solver slot ever in the header
   band? (Current answer: only `l1b` with `bleedTop:true`; caption slots never enter header band.)
   Scope deferred or active?
5. Exact background color implementation: `pw.Page` background decoration vs full-size
   `pw.Container` in stack?
6. Chrome on `DotsElementsPage`: unconditional (scoped to layout pages for overlap suppression)?
7. Which page types are EXCLUDED from chrome: cover pages (`DotsAlbumSpreadPage.cover()`),
   any others?
8. `SPECS_interior.md` footer alignment must be updated to match PDF template (center → right).
   Include in this task or separate doc-only task?

---

## Ready for Proposal

Yes — complete. All affected files identified with line numbers, 4 bugs confirmed in current code,
2+ approaches evaluated, recommendation made, open questions listed, test regression mapped.
