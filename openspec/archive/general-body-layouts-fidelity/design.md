# Design: general-body-layouts-fidelity

## Technical Approach

Approach B from the explore — **`_outerAlignedX` private helper inside the solver**, with `DotsPageGeometry` gaining the `outerMarginMm` constant. The solver becomes page-parity aware via a new `required bool isLeftPage` parameter on `solve(...)`; the renderer and isolate pass `page.pageNumber.isOdd` (Task 1's convention); the parser passes a fixed canonical `true` because its validation path inspects shape, not absolute positions. Every photo block's x is now `_outerAlignedX(geometry, blockWidthMm, isLeftPage: …)`; centering math is eliminated from the solver. Dimension corrections land in lock-step with the helper migration. L_hito's text-block width grows 122 → 149 mm for title + subtitle (body stays 122 per spec), subtitle font size override flips 9.0 → 20.0 in both `_captionFontSizeFor` copies, and the subtitle slot's height reservation grows to accommodate 24 pt leading.

## Architecture Decisions

### Decision: `_outerAlignedX` lives private to `dots_layout_solver.dart`

| Option | Pro | Con | Decision |
|---|---|---|---|
| Private method on `DotsLayoutSolver` | Single owner; cohesive with the only existing caller; keeps the solver stateless | Not directly unit-testable without `@visibleForTesting` | **Chosen** |
| Public top-level function in `dots_page_geometry.dart` | Reusable, directly testable | Inflates public API for an x-arithmetic primitive that has no caller outside the solver | Rejected |
| Static method on `DotsPageGeometry` | Reusable, no new file | Couples geometry value-object to layout positioning math | Rejected |

Rationale: the helper is one line of arithmetic that the solver consumes exclusively. Adding `@visibleForTesting` is rejected — fixture-level expectations on slot `xMm` validate the helper transitively on every layout, and explicit per-parity tests on L1, L4A, L8 (see Testing Strategy) lock the mirroring math.

Signature (final):

```dart
/// Returns the x-coordinate of a block of [blockWidthMm] aligned 8 mm
/// from the outer (non-binding) trim edge. On a left page the outer
/// edge is the LEFT page edge → `geometry.outerMarginMm`. On a right
/// page the outer edge is the RIGHT page edge →
/// `pageWidthMm - outerMarginMm - blockWidthMm`. Same parity
/// convention as `dots_renderer.dart:394` (`page.pageNumber.isOdd`).
double _outerAlignedX(
  DotsPageGeometry geometry,
  double blockWidthMm, {
  required bool isLeftPage,
}) =>
    isLeftPage
        ? geometry.outerMarginMm
        : geometry.pageWidthMm - geometry.outerMarginMm - blockWidthMm;
```

### Decision: `_singlePhotoCentered` is renamed to `_singlePhotoOuterAligned`

| Option | Pro | Con | Decision |
|---|---|---|---|
| Rename `_singlePhotoCentered` → `_singlePhotoOuterAligned`; pass `isLeftPage`; all five callers (l1, l1a, l1c, l1d, l1e) update | Single helper for the L1 family; naming reflects intent; no orphan methods | All five callers change in the same commit | **Chosen** |
| Keep `_singlePhotoCentered`, add a new `_singlePhotoOuterAligned`, route per-layout | New centered helper would be dead code post-change | Two helpers with the same shape; orphan code; "centered" implies an obsolete model | Rejected |

Rationale: no layout in this task uses page-centering anymore (L3A's coincidental centering is replaced by the explicit `_outerAlignedX` call). Keeping a `_singlePhotoCentered` would mislead future readers. L_hito does not call this helper (it has its own `_lhito` method), so renaming is contained to the L1 family.

### Decision: L1B bleed flags emit bilaterally; renderer keeps suppression contract

| Option | Pro | Con | Decision |
|---|---|---|---|
| Emit `bleedTop = bleedBottom = bleedLeft = bleedRight = true`; rewrite comment to teach "outer = non-binding only physically bleeds" | Backward compatible with Task 1's chrome predicate (already inspects bilateral flags); zero risk | Code semantically says "all four bleed" while the spec says only three (outer + top + bottom) | **Chosen** |
| Emit `bleedLeft = isLeftPage, bleedRight = !isLeftPage` | Slot model literally reflects physical bleed | Task 1's `deriveSuppressHeaderForChrome` / `deriveSuppressFooterForChrome` predicates inspect bleed flags — a per-parity flip changes suppression behavior, which is a Task-1 retrospective (out of scope) | Rejected |

Rationale: Decision 4 of the proposal pins this. The x-coordinate fix flips from `(pageWidth - 175)/2 = 14` to either `8` (left page) or `pageWidth - 8 - 175 = 20` (right page). Bleed flag set is unchanged; only the comment is rewritten to explain "outer edge is the one that physically bleeds; flags stay bilateral so the renderer's bleed-aware predicate keeps the contract it had under Task 1".

### Decision: L4B picks the upper-pane y (~23 mm) as the canonical non-caption-driven variant

| Option | Pro | Con | Decision |
|---|---|---|---|
| `y = 23 mm` (upper-pane half-spread) | Matches PDF pp. 49–52 upper row; symmetric with L1C's canonical y=23 (already proposed); lets Tasks 4–7 pick the lower variant when caption length dictates | Lower-row variant deferred | **Chosen** |
| `y = 136 mm` (lower-pane half-spread) | Matches the lower row | Asymmetric default vs L1C; non-caption-driven default convention argues for upper | Rejected |
| Center between the two | Neither matches PDF | Splits the difference, matches no spread | Rejected |

Rationale: caption-driven y is explicitly deferred (proposal "Out of Scope"). Picking the upper variant matches L1C's canonical pick and the PDF's reading order on pp. 49–52. The exact value is `y = 23 mm` (block height 110 mm sits 23 mm below trim top, which matches the spec callout for the upper pane).

### Decision: L_hito text-block width grows for title + subtitle ONLY; body stays 122 mm

| Option | Pro | Con | Decision |
|---|---|---|---|
| Title + subtitle widths → 149 mm; body width stays 122 mm (per spec line 166) | Matches spec exactly | Three slots with two widths in one layout | **Chosen** |
| Title + subtitle + body → 149 mm | Uniform widths | Contradicts `SPECS_interior.md:166` ("body width 122 mm") | Rejected |

Rationale: `docs/templates/SPECS_interior.md:160-167` says title is 20 pt / 24 pt with no width callout (the PDF spec shows 149 mm), subtitle is 9 pt / 10.8 pt but the proposal grows the subtitle font size to 20 pt to match the PDF annotation, body is explicitly 122 mm. Spec phase will mark the body width unchanged; design respects spec authority on body.

`_requireFits` width is updated from `qrContainerWidthMm` (130) to `149` because `149 > 130` after the title/subtitle width grows; 149 mm fits the 203 mm live-area width comfortably.

### Decision: subtitle slot height grows to `20 * 0.352778 * 1.2 ≈ 8.467 mm` (24 pt leading)

| Option | Pro | Con | Decision |
|---|---|---|---|
| `dateHeightMm = 24 * 0.352777778` (matches subtitle leading) | Slot reservation matches the 20 pt / 24 pt subtitle | Diverges from "date" terminology — the lhito case is no longer a date line | **Chosen** |
| Keep `dateHeightMm = 10.8 * 0.352777778`; rely on renderer overflow | Avoids slot growth | `pw.Text` silently clips when font > slot height (current 9 pt fits 3.81 mm; 20 pt at 24 pt leading does not) | Rejected |
| Branch the formula per layout inside `_lhito` | Same effect | Adds a `layoutCode` parameter dependency where the method only handles one layout — dead branch | Rejected |

Rationale: `_lhito` already handles only the lhito layout; the rename of the local constant from `dateHeightMm` to `subtitleHeightMm` (with a comment "lhito subtitle is P22 Mackinac book 20 pt / 24 pt — see `_captionFontSizeFor`") clarifies intent. L_hito `_requireFits` height re-verification:

  - Old: title 16.933 + 4 + 3.810 + 4 + 60.943 + 10 + 105.5 = **205.19 mm** (fits 230).
  - New: title 16.933 + 4 + **8.467** + 4 + 60.943 + 10 + 105.5 = **209.84 mm** (fits 230).
  - Net growth: +4.66 mm. Headroom remains 230 − 209.84 = 20.16 mm.

## Data Flow

    DotsRenderer._buildLayoutPage (lib/src/render/dots_renderer.dart:377-394)
        │
        ├── isLeftPage = page.pageNumber.isOdd  (already derived)
        │
        ▼
    DotsLayoutSolver.solve(code, geometry, isLeftPage: …)
        │
        ▼
    switch (code) → _layoutMethod(geometry, isLeftPage: …)
        │
        ▼
    _outerAlignedX(geometry, blockWidthMm, isLeftPage: …)
        │
        ▼
    DotsSlotRect[] (photo + caption slots per layout)
        │
        ▼
    Renderer paints + (for captionDate on lhito) _captionFontSizeFor → 20.0

Parser-side flow (`dots_template_parser.dart:455-459`): same `solve(...)`, but `isLeftPage: true` (canonical). Slot count + kinds are what the parser validates; positions are not inspected.

## File Changes

| File | Action | Description |
|---|---|---|
| `lib/src/render/layout/dots_page_geometry.dart` | Modify | Add `final double outerMarginMm;` field + required constructor arg + `dotbookDefault()` supplies `8`; extend `==` and `hashCode` to include it. Field dartdoc: "Distance in mm from the outer (non-binding) trim edge at which body photo blocks are anchored. The canonical Dotbook value is 8 mm." |
| `lib/src/render/layout/dots_layout_solver.dart` | Modify (heavy) | (1) `solve(...)` gains `required bool isLeftPage`. (2) Add `_outerAlignedX(geometry, blockWidthMm, {required bool isLeftPage})`. (3) Rename `_singlePhotoCentered` → `_singlePhotoOuterAligned`; thread `isLeftPage`; replace x-math with helper. (4) `_verticalStack` gains `isLeftPage` param; x uses helper. (5) Per-layout method changes (see "Per-layout slot specs" below). (6) L1B comment rewritten per Decision 3. (7) L_hito text-block width 122 → 149 for title + subtitle slots; body stays 122; subtitle slot height = `24 * 0.352778`; rename local `dateHeightMm` → `subtitleHeightMm`; `_requireFits` width arg = `149`. |
| `lib/src/render/dots_renderer.dart` | Modify | Line 386: `solver.solve(page.layoutCode, geometry, isLeftPage: page.pageNumber.isOdd)`. Lines 774-778 (`_captionFontSizeFor`, `captionDate` arm): `return layoutCode == DotsLayoutCode.lhito ? 20.0 : 11.0;` + rewrite comment to "L_hito subtitle is P22 Mackinac book **20 pt / 24 pt** per `SPECS_interior.md:163` — slot height reserved by the solver matches 24 pt leading." |
| `lib/src/render/isolate_synthesis.dart` | Modify | Line 245: pass `isLeftPage: page.pageNumber.isOdd`. Lines 521-522: same `_captionFontSizeFor` flip and matching comment. |
| `lib/src/config/dots_template_parser.dart` | Modify | Line 459: pass `isLeftPage: true` with a code comment "validation inspects slot count and kinds, not absolute positions; canonical left-page parity is sufficient and stable." |
| `test/render/layout/dots_layout_solver_test.dart` | Modify (heavy) | Drop `_expectPageHorizontallyCentered` for photo blocks (replace with `_expectOuterAligned`); update every fixture to the corrected slot list per parity; add parity coverage for L1, L4A, L8 (see Testing Strategy); update L_hito assertions (title/subtitle width 149; subtitle height 8.467; total stack still vertically centered). |
| `test/render/layout/dots_layout_requirements_test.dart` | Modify | Line 26: pass `isLeftPage: true`. Add a new test case verifying `_captionFontSizeFor` for `(captionDate, lhito) → 20.0` and `(captionDate, l7) → 11.0` via the renderer path (rendered slot's pw.Text font size — see Testing Strategy). |
| `docs/templates/SPECS_interior.md` | Modify | L2.B (line 111-112): `115.5 × 86 mm` → `175 × 107 mm landscape`. L4.A (line 122-123): `86 × 110` → `86 × 86 SQUARE`. L7 (line 142-146): `142 × 105 mm` → `86 × 110 mm`, `67 mm caption columns` → `7.5 mm photo-to-date gap`. Positioning model (line 237-240): "AUTO" wording → "8 mm from the outer (non-binding) trim edge; mirrored per page parity." L_hito (line 163): subtitle row → "P22 Mackinac **book** 20 pt / 24 pt." |
| `lib/dots_pdf.dart` | Unchanged | `DotsPageGeometry` already exported (line 55); the new `outerMarginMm` field rides along. |

## Interfaces / Contracts

### `DotsPageGeometry` (modified)

```dart
@immutable
class DotsPageGeometry {
  const DotsPageGeometry({
    required this.pageWidthMm,
    required this.pageHeightMm,
    required this.bleedMm,
    required this.headerBandMm,
    required this.footerBandMm,
    required this.bindingInsetMm,
    required this.outerMarginMm,    // NEW
  });

  factory DotsPageGeometry.dotbookDefault() => const DotsPageGeometry(
        pageWidthMm: 203,
        pageHeightMm: 254,
        bleedMm: 3,
        headerBandMm: 12,
        footerBandMm: 12,
        bindingInsetMm: 23,
        outerMarginMm: 8,             // NEW
      );

  /// Distance in mm from the outer (non-binding) trim edge at which
  /// body photo blocks are anchored. The canonical Dotbook value is
  /// 8 mm; left pages anchor blocks at x = outerMarginMm, right pages
  /// anchor them at x = pageWidthMm - outerMarginMm - blockWidthMm.
  final double outerMarginMm;
  // … (==, hashCode extended to include outerMarginMm)
}
```

### `DotsLayoutSolver.solve` (modified)

```dart
List<DotsSlotRect> solve(
  DotsLayoutCode code,
  DotsPageGeometry geometry, {
  required bool isLeftPage,
}) { /* switch unchanged in shape; each branch forwards isLeftPage */ }
```

### Per-layout slot specs (canonical = left-page coordinates; right-page mirrors via `_outerAlignedX`)

| Code | Photo slot (xMm, yMm, wMm, hMm) | Caption slots (left page) | Bleed | Notes |
|---|---|---|---|---|
| l1 | `(8, 57, 142, 189)` | `captionDate (8, 57 − 7.5 − 4, 142, 4)` then `captionBody (8, 57 − 7.5 − 4 − 4 − bodyH, 142, bodyH)` where `bodyH = 10.8 * 0.352778 * 11 ≈ 42.06 mm` (400 chars / ~50 chars/line ≈ 8 lines, +3 widow lines) | none | bodyGrowsUpward |
| l1a | `(8, 33.5, 113, 152)` | side column at `(8 + 113 + 7.5, 33.5, 82, ⋯)`: `captionDate (…, …, 82, 4)` then `captionBody (…, …+4+4, 82, bodyH)` where `bodyH = 10.8 * 0.352778 * 18 ≈ 68.62 mm` (800 chars / ~44 chars/line on 82 mm ≈ 18 lines) | none | bodyGrowsDownward |
| l1b | `(8, (254−238)/2 = 8, 175, 238)` | — | T=B=L=R=true (Decision 3) | x via helper |
| l1c | `(8, 23, 175, 196)` | — | none | canonical y=23 |
| l1d | `(8, (12 + (230−107)/2 = 73.5), 107, 107)` | — | none | PDF-unconfirmed; only x changes |
| l1e | `(8, 33.5, 107, 152)` | mirrors l1a side-column shape: `(8 + 107 + 7.5, 33.5, 82, ⋯)` | none | PDF-unconfirmed |
| l2a | `(8, (12 + (230−110)/2 = 72), 86, 110)` + `(8 + 86 + 16 = 110, 72, 86, 110)` | — | none | block width 188; outer-aligned 8 |
| l2b | `(8, 29, 175, 107)` + `(8, 29 + 107 + 3 = 139, 175, 107)` | — | none | rewrite: landscape ×2 |
| l2c | `(8, (12 + (230 − (74*2+3))/2 = 49.5), 65, 74)` + `(8, 49.5 + 77 = 126.5, 65, 74)` | — | none | x via helper |
| l3a | `(8, 86, 60.27, 82)`, `(8 + 60.27 + 3 = 71.27, 86, 60.27, 82)`, `(71.27 + 60.27 + 3 = 134.54, 86, 60.27, 82)` | — | none | explicit helper call replaces coincidental centering |
| l4a | `(8, 71, 86, 86)`, `(8 + 86 + 3 = 97, 71, 86, 86)`, `(8, 71 + 86 + 3 = 160, 86, 86)`, `(97, 160, 86, 86)` | — | none | SQUARE rewrite |
| l4b | `(8, 23, 86, 110)` + `(8 + 86 + 3 = 97, 23, 86, 110)` | — | none | upper-pane canonical y (Decision 4) |
| l6a | top row `(8, startY, 86, 110)` + `(97, startY, 86, 110)`; bottom `(8, startY + 113, 86, 110)` where `startY = 12 + (230 − (110 + 3 + 110))/2 = 15.5`. **Note**: bottom row is outer-aligned, NOT page-centered — the PDF shows the bottom photo at the outer edge on each page of the spread. | — | none | bottom moves from page-center to `_outerAlignedX` |
| l7 | pane 0: photo `(8, paneTop, 86, 110)`, captionDate `(8, paneTop + 110 + 7.5, 86, 4)`, captionBody `(8, paneTop + 110 + 7.5 + 4, 86, bodyH)`; pane 1: same with `paneTop + paneH + 3`. `paneH = 110 + 7.5 + 4 + bodyH`, `bodyH = 10.8 * 0.352778 * 8 ≈ 30.50 mm` (350 chars / ~32 chars/line on 86 mm ≈ 11 lines, but capped to fit; spec sets `~30.5`). | bodyH per left | none | photo dims rewrite + 7.5 mm gap; bodyGrowsDownward |
| l8 | top row `(8, startY, 86, 110)` + `(8 + 86 + 3 = 97, startY, 86, 110)`; bottom `(8, startY + 113, 175, 115.5)`; startY centered as today. | — | none | both rows outer-aligned 8 (top block 175 = 86+3+86 matches bottom) |
| lhito | no photo; title `(textX, startY, 149, 16.933)`; subtitle `(textX, …, 149, 8.467)`; body `(bodyX, …, 122, ~60.94)`; qrCard `(qrX, qrY, 130, 105.5)`. `textX = (203 − 149)/2 = 27`; `bodyX = (203 − 122)/2 = 40.5`; `qrX = (203 − 130)/2 = 36.5`. Block still vertically centered in live area; `_requireFits` width = 149. | — | none | text-block width grows; subtitle height = 24 pt leading |

> All right-page coordinates are obtained by replacing each photo/caption block's `xMm` with `pageWidthMm − outerMarginMm − blockWidthMm` (i.e. `203 − 8 − w`). Per-layout the helper does this; spec phase enumerates the exact mirror table.

### Renderer `_captionFontSizeFor` (modified delta)

```dart
case DotsSlotKind.captionDate:
  // L_hito subtitle is P22 Mackinac book 20 pt / 24 pt per
  // SPECS_interior.md:163; the solver reserves 24 pt of leading
  // (~8.47 mm) in the slot. Everywhere else date is 11 pt.
  return layoutCode == DotsLayoutCode.lhito ? 20.0 : 11.0;
```

Identical change in `isolate_synthesis.dart:521-522` (comment intentionally duplicated; the two copies stay in lock-step).

## Testing Strategy

| Layer | What | Approach | Notes |
|---|---|---|---|
| Unit (solver) | Each of 16 layouts emits the exact `DotsSlotRect[]` for `isLeftPage: true` with `dotbookDefault()` | Direct comparison against the table above with `_tolMm = 0.001` | Replaces every existing fixture; the regression-by-design from the explore |
| Unit (solver, parity) | L1, L4A, L8 mirror x correctly for `isLeftPage: false` — `xMm == pageWidthMm − outerMarginMm − blockWidthMm` for every photo slot | Parameterized assertion per slot | Locks the `_outerAlignedX` math without `@visibleForTesting` |
| Unit (solver, captions) | L1, L1A, L1E emit the documented caption slots in the order `photo, captionDate, captionBody` (or `photo, captionDate, captionBody` mirrored for l1a/l1e side column) | Direct length + kind assertions | New |
| Unit (solver, l1b bleed) | `bleedTop = bleedBottom = bleedLeft = bleedRight = true` regardless of parity (Decision 3) | Single fixture | Updated comment, unchanged flags |
| Unit (solver, lhito) | Title widthMm = 149; subtitle widthMm = 149; subtitle heightMm ≈ 8.467; body widthMm = 122; qrCard widthMm = 130 | Direct field assertions | Updated fixture |
| Unit (solver, lhito fits) | `_requireFits(149, totalHeight ≈ 209.84)` does NOT throw for `dotbookDefault()` | Indirect (solve does not throw) | Header-room verified at design time |
| Unit (geometry) | `DotsPageGeometry.dotbookDefault().outerMarginMm == 8`; `==` and `hashCode` distinguish two geometries differing only in `outerMarginMm` | Direct | New |
| Unit (renderer) | `_captionFontSizeFor(captionDate, lhito) == 20.0`; `_captionFontSizeFor(captionDate, l7) == 11.0`; `_captionFontSizeFor(captionTitle, lhito) == 20.0` | Test-only file or extension; via a public test helper — design phase notes this pins both layouts and prevents a regression on the isolate copy | New (renderer file only; isolate copy verified by inspection) |
| Unit (parser) | Parser's `solve(..., isLeftPage: true)` call validates an L7 layout without throwing and produces 2 photo slots | Indirect via `dots_template_parser_test.dart` existing harness | Existing path; only call-site updates |
| Unit (requirements) | `dots_layout_requirements_test.dart:26` passes after `solve(...)` gains `isLeftPage: true` | Mechanical | Compile-time fix |

## Migration / Rollout

Single PR per the user's removed size guardrail (spec phase confirms via Review Workload Forecast). No data migration. `outerMarginMm` is a constructor-required new field on `DotsPageGeometry` — analyzer flushes every constructor call out; only `dotbookDefault()` exists in production today (verified via `Grep`), so the blast radius is bounded. Rollback = `git revert` slice commits in reverse order. Caches: none — slot coordinates are computed fresh per render.

## Open Questions

- [x] L4B canonical y → resolved: **23 mm (upper pane)**, see Decision 4.
- [x] L_hito `_requireFits` after width/subtitle changes → resolved: 209.84 mm of 230 mm available; 20.16 mm headroom (Decision 6 math).
- [x] `_outerAlignedX` `@visibleForTesting` → resolved: **NO** — covered transitively by fixture-level assertions and parity tests on L1/L4A/L8 (Decision 1).
- [ ] L1 caption body `bodyH` exact value — design uses 11 lines × 3.81 ≈ 42.06 mm as a conservative reserve; spec phase pins the precise value based on the 400-char / ~50 chars per line / 3-widow rule from `SPECS_interior.md:91-97`.
- [ ] L7 caption body `bodyH` — design uses 8 lines × 3.81 ≈ 30.50 mm; spec phase pins.
- [ ] L1A / L1E side-column body `bodyH` — design uses 18 lines × 3.81 ≈ 68.62 mm at 82 mm column width (~44 chars / line for 800 chars); spec phase pins.
