# Tasks: general-body-layouts-fidelity

## Review Workload Forecast

| Field | Value |
|-------|-------|
| Estimated changed lines | ~575–775 (production ~275–375, tests ~300–400) |
| 400-line budget risk | High |
| Chained PRs recommended | Yes by SDD heuristic, but user accepted size:exception |
| Suggested split | Single PR — size:exception accepted by user |
| Delivery strategy | single-pr |
| Chain strategy | size:exception |

Decision needed before apply: No
Chained PRs recommended: No
Chain strategy: size:exception
400-line budget risk: High

### Suggested Work Units

| Unit | Goal | PR | Notes |
|------|------|----|-------|
| 1 | All phases — geometry constant, solver signature, per-layout corrections, renderer font fix, tests, docs | Single PR | size:exception accepted; branch `general-body-layouts-fidelity` already cut |

---

## Phase 1 — Foundation: `DotsPageGeometry.outerMarginMm` (R1)

**Strict TDD: write test first (RED), then implementation (GREEN).**

- [ ] **T1.1** `test/render/layout/dots_layout_solver_test.dart` — add geometry group with two RED tests:
  - `DotsPageGeometry — dotbookDefault outerMarginMm equals 8.0`
  - `DotsPageGeometry — equality includes outerMarginMm` (two geometries differing only in `outerMarginMm` must not be equal)
  File: `test/render/layout/dots_layout_solver_test.dart`. Satisfies R1.

- [ ] **T1.2** `lib/src/render/layout/dots_page_geometry.dart` — add `final double outerMarginMm` as required named constructor param (no default → compile error on omission). Dartdoc: `"Distance in mm from the outer (non-binding) trim edge at which body photo blocks are anchored. The canonical Dotbook value is 8 mm."` Supply `outerMarginMm: 8` in `dotbookDefault()`. Extend `==` (line 66) and `hashCode` (line 76) to include the new field. `lib/dots_pdf.dart` needs no change (already exports this file). Satisfies R1.
  Commit: `feat(geometry): add outerMarginMm required field to DotsPageGeometry`

- [ ] **T1.3** Run `flutter analyze` — must be clean. Run `flutter test test/render/layout/dots_layout_solver_test.dart` — T1.1 geometry tests GREEN (no other tests should break yet; `dotbookDefault()` is the only production constructor call site per codebase search).

---

## Phase 2 — `solve()` Signature + `_outerAlignedX` Helper (R2, R3)

**Tests precede signature change.**

- [ ] **T2.1** `test/render/layout/dots_layout_requirements_test.dart` line 26 — update `solver.solve(code, geometry)` to `solver.solve(code, geometry, isLeftPage: true)`. Add comment per spec: `"Validates slot count and kinds, not absolute positions; canonical left-page parity is correct here."` Satisfies R2 (requirements test call site). This test goes RED (compile error) until T2.2.

- [ ] **T2.2** `lib/src/render/layout/dots_layout_solver.dart` line 25 — change `solve(DotsLayoutCode code, DotsPageGeometry geometry)` to `solve(DotsLayoutCode code, DotsPageGeometry geometry, {required bool isLeftPage})`. This makes the three production call sites compile errors (surfacing T2.3–T2.5). Satisfies R2.

- [ ] **T2.3** `lib/src/render/dots_renderer.dart` line 386 — update call to `solver.solve(page.layoutCode, geometry, isLeftPage: page.pageNumber.isOdd)`. `isLeftPage` is already derived at line 394 in the same method; pass `page.pageNumber.isOdd` directly at the solve call. Satisfies R2.

- [ ] **T2.4** `lib/src/render/isolate_synthesis.dart` line 245 — update call to `solver.solve(page.layoutCode, geometry, isLeftPage: page.pageNumber.isOdd)`. Satisfies R2.

- [ ] **T2.5** `lib/src/config/dots_template_parser.dart` line 459 — update call to `solver.solve(layoutCode, geometry, isLeftPage: true)`. Add comment: `"Validates slot shape (count + kinds), not absolute position — canonical left-page value is correct here."` Satisfies R2.

- [ ] **T2.6** `lib/src/render/layout/dots_layout_solver.dart` — add private method `_outerAlignedX(DotsPageGeometry geometry, double blockWidthMm, {required bool isLeftPage})` returning `isLeftPage ? geometry.outerMarginMm : geometry.pageWidthMm - geometry.outerMarginMm - blockWidthMm`. Place immediately before `_singlePhotoCentered`. Add dartdoc as per design signature. Satisfies R3. No `@visibleForTesting` — covered transitively by fixture assertions.

- [ ] **T2.7** `lib/src/render/layout/dots_layout_solver.dart` — rename `_singlePhotoCentered` → `_singlePhotoOuterAligned`; add `{required bool isLeftPage}` param; replace `final double x = (geometry.pageWidthMm - widthMm) / 2` with `final double x = _outerAlignedX(geometry, widthMm, isLeftPage: isLeftPage)`. Thread `isLeftPage` from `solve()` switch to each of the five L1-family callers (l1, l1a, l1c, l1d, l1e). Satisfies R3.

- [ ] **T2.8** `test/render/layout/dots_layout_solver_test.dart` — update helper `_expectPageHorizontallyCentered` → rename to `_expectOuterAligned(slot, geometry, {required bool isLeftPage})`; replace centering math with: left-page → `expect(slot.xMm, closeTo(geometry.outerMarginMm, _tolMm))`; right-page → `expect(slot.xMm, closeTo(geometry.pageWidthMm - geometry.outerMarginMm - slot.widthMm, _tolMm))`. Update every existing call site in the file. Satisfies R3, R6.

- [ ] **T2.9** `test/render/layout/dots_layout_solver_test.dart` — add explicit left-vs-right parity test cases for L1, L4A, L8 (three representative layouts per design Testing Strategy):
  - L1 left: `solve(l1, g, isLeftPage: true)` → photo `xMm == 8.0`
  - L1 right: `solve(l1, g, isLeftPage: false)` → photo `xMm == closeTo(203 − 8 − 142, _tolMm)` (53.0)
  - L4A left: `solve(l4a, g, isLeftPage: true)` → photo[0] `xMm == 8.0`
  - L4A right: photo[0] `xMm == closeTo(203 − 8 − 86, _tolMm)` (109.0)
  - L8 left: `solve(l8, g, isLeftPage: true)` → top-row photo[0] `xMm == 8.0`
  - L8 right: top-row photo[0] `xMm == closeTo(203 − 8 − 86, _tolMm)`
  Satisfies R6 (parity coverage).

  Commit: `refactor(solver): add isLeftPage param + _outerAlignedX helper; rename _singlePhotoCentered`

---

## Phase 3 — Per-Layout Solver Corrections (R4)

**Each sub-task: update fixture test first (RED), then solver method (GREEN). All commits atomic per layout group.**

- [ ] **T3.1** L1 — `dots_layout_solver_test.dart`: update l1 fixture to expect 3 slots (`photo`, `captionDate`, `captionBody`); assert photo `(xMm=8, yMm=57, w=142, h=189)`; captionDate above photo; captionBody above date (grows upward). `dots_layout_solver.dart` `_singlePhotoOuterAligned` for l1: change routing in `solve()` switch to call a new `_l1(geometry, isLeftPage)` private method (or extend `_singlePhotoOuterAligned` with optional caption params); emit photo `yMm=57`, captionDate slot `(x=outerAlignedX, y=57−7.5−4, w=142, h=4)`, captionBody slot `(x, y=57−7.5−4−4−bodyH, w=142, h=bodyH)` where `bodyH ≈ 42.06` (11 lines × `10.8*0.352778`). Satisfies R4 (l1).

- [ ] **T3.2** L1A — `dots_layout_solver_test.dart`: update l1a fixture to expect photo `(8, 33.5, 113, 152)` + side-column `captionDate` + `captionBody` at `xMm = 8+113+7.5 = 128.5`. `dots_layout_solver.dart`: update `_singlePhotoOuterAligned` routing for l1a (or dedicated method); fix `yMm=33.5`; add caption slots in 82 mm column; `bodyH ≈ 68.62`. Satisfies R4 (l1a).

- [ ] **T3.3** L1B — `dots_layout_solver_test.dart`: update l1b fixture; `xMm` via `_outerAlignedX` (left=8, right=20); bleed flags all true. `dots_layout_solver.dart` `_l1bOversizedBleed`: add `isLeftPage` param; replace `x = (pageWidthMm − 175)/2` with `_outerAlignedX(geometry, 175, isLeftPage: isLeftPage)`; rewrite bleed comment per Decision 3 (flags stay bilateral; outer edge is physical bleed side). `yMm` unchanged `(254−238)/2 = 8`. Satisfies R4 (l1b).

- [ ] **T3.4** L1C — `dots_layout_solver_test.dart`: update l1c fixture; photo `(8, 23, 175, 196)` left-page. `dots_layout_solver.dart`: `_singlePhotoOuterAligned` for l1c passes `yMm=23` (canonical Decision 4 analogy). Satisfies R4 (l1c).

- [ ] **T3.5** L1D — `dots_layout_solver_test.dart`: update l1d fixture; photo `xMm=8` (only x changes; dims and y unchanged). `dots_layout_solver.dart`: thread `isLeftPage` to l1d. Marked PDF-unconfirmed. Satisfies R4 (l1d).

- [ ] **T3.6** L1E — `dots_layout_solver_test.dart`: update l1e fixture; photo `(8, 33.5, 107, 152)`; side-column caption slots at `xMm = 8+107+7.5 = 122.5`. `dots_layout_solver.dart`: add captions by L1A analogy; thread `isLeftPage`. Marked PDF-unconfirmed. Satisfies R4 (l1e).

- [ ] **T3.7** L2A — `dots_layout_solver_test.dart`: update l2a fixture; photo[0] `xMm=8`, photo[1] `xMm=8+86+16=110`; y unchanged `(12 + (230−110)/2 = 72)`. `dots_layout_solver.dart` `_l2aSideBySide`: add `isLeftPage`; replace `startX` centering with `_outerAlignedX(geometry, 188, isLeftPage)` for block start. Satisfies R4 (l2a).

- [ ] **T3.8** L2B — `dots_layout_solver_test.dart`: rewrite l2b fixture; 2 landscape slots `(175×107)`, photo[0] `(8, 29, 175, 107)`, photo[1] `(8, 139, 175, 107)`. `dots_layout_solver.dart` `_l2bStacked`: full rewrite from portrait `115.5×86` to landscape `175×107`; `gap=3`; y0=29, y1=139; `xMm = _outerAlignedX(geometry, 175, isLeftPage)`. Satisfies R4 (l2b — rewrite).

- [ ] **T3.9** L2C — `dots_layout_solver_test.dart`: update l2c fixture; `xMm` via `_outerAlignedX` (block width per current dims). `dots_layout_solver.dart` `_l2cStacked`: thread `isLeftPage`; replace centering x with helper. Satisfies R4 (l2c).

- [ ] **T3.10** L3A — `dots_layout_solver_test.dart`: update l3a fixture; photo[0] `xMm=8`, photo[1] `xMm=71.27`, photo[2] `xMm=134.54`; `yMm=86`. `dots_layout_solver.dart` `_l3aRow`: thread `isLeftPage`; replace coincidental centering x with `_outerAlignedX(geometry, blockWidth, isLeftPage)` where `blockWidth = 3*60.27 + 2*3 = 186.81`. Satisfies R4 (l3a).

- [ ] **T3.11** L4A — `dots_layout_solver_test.dart`: rewrite l4a fixture; 4 square `86×86` slots at `(8,71)`, `(97,71)`, `(8,160)`, `(97,160)`; gap=3. `dots_layout_solver.dart` `_l4aGrid`: full rewrite from `86×110` portrait 4-grid to `86×86` square 4-grid; outer x=`_outerAlignedX(geometry, 86*2+3, isLeftPage)`. Satisfies R4 (l4a — rewrite).

- [ ] **T3.12** L4B — `dots_layout_solver_test.dart`: update l4b fixture; 2-column pair `(8,23,86,110)` and `(97,23,86,110)`; canonical y=23 (upper-pane, Decision 4). `dots_layout_solver.dart` `_l4bHalfSpread`: thread `isLeftPage`; set `y=23`; replace x centering with `_outerAlignedX`. Satisfies R4 (l4b).

- [ ] **T3.13** L6A — `dots_layout_solver_test.dart`: update l6a fixture; top-row `xMm=8` and `xMm=97`; bottom photo `xMm = _outerAlignedX` (not page-centered). `dots_layout_solver.dart` `_l6aHalfSpread`: thread `isLeftPage`; fix bottom-row x to use helper (not page center). Satisfies R4 (l6a).

- [ ] **T3.14** L7 — `dots_layout_solver_test.dart`: rewrite l7 fixture; 2 panes each with photo `86×110`, `captionDate` at `paneTop+110+7.5`, `captionBody` below date; `bodyH ≈ 30.50`. `dots_layout_solver.dart` `_l7HalfSpread`: full rewrite from `142×105` to `86×110`; 7.5 mm photo-to-date gap; bodyGrowsDownward; `xMm = _outerAlignedX(geometry, 86, isLeftPage)`. Satisfies R4 (l7 — rewrite).

- [ ] **T3.15** L8 — `dots_layout_solver_test.dart`: update l8 fixture; top-row photos `xMm=8` and `xMm=97`; bottom photo `(8, startY+113, 175, 115.5)` with `xMm=8`. `dots_layout_solver.dart` `_l8HalfSpread`: thread `isLeftPage`; replace centering x with `_outerAlignedX` for top block and bottom slot. Satisfies R4 (l8).

- [ ] **T3.16** L_hito — `dots_layout_solver_test.dart`: update lhito fixture; assert `title.widthMm == 149`, `subtitle.widthMm == 149`, `subtitle.heightMm ≈ 8.467` (`closeTo(24 * 0.352778, _tolMm)`), `body.widthMm == 122`. `dots_layout_solver.dart` `_lhito`: update title + subtitle width 122 → 149; rename `dateHeightMm` → `subtitleHeightMm`; set `subtitleHeightMm = 24 * 0.352778`; update `_requireFits` width arg 130 → 149; add comment `"lhito subtitle is P22 Mackinac book 20 pt / 24 pt — see _captionFontSizeFor"`. Satisfies R4 (lhito).

  Commit: `feat(solver): per-layout outer-edge alignment and dimension corrections`

---

## Phase 4 — Renderer Font-Size Override (R5)

**Drift risk mitigated by updating both copies in the same commit.**

- [ ] **T4.1** `test/render/layout/dots_layout_requirements_test.dart` — add two new test cases (can be in a new `_captionFontSizeFor` group via a test-accessible helper or by inspecting a rendered `_buildCaptionSlot` path):
  - `DotsRenderer — _captionFontSizeFor(captionDate, lhito) equals 20.0`
  - `DotsRenderer — _captionFontSizeFor(captionDate, l7) equals 11.0`
  Use a `@visibleForTesting` wrapper or expose via a thin test-only extension (design Testing Strategy: "test-only file or extension; via a public test helper"). These go RED until T4.2. Satisfies R5.

- [ ] **T4.2** `lib/src/render/dots_renderer.dart` lines 774–778 — change `captionDate` arm of `_captionFontSizeFor`:
  ```dart
  case DotsSlotKind.captionDate:
    // L_hito subtitle is P22 Mackinac book 20 pt / 24 pt per
    // SPECS_interior.md:163; the solver reserves 24 pt of leading
    // (~8.47 mm) in the slot. Everywhere else date is 11 pt.
    return layoutCode == DotsLayoutCode.lhito ? 20.0 : 11.0;
  ```
  Satisfies R5 (renderer copy).

- [ ] **T4.3** `lib/src/render/isolate_synthesis.dart` lines 521–522 — apply identical change to `_captionFontSizeFor` `captionDate` arm with the same comment (intentionally duplicated). Satisfies R5 (isolate copy).

  Commit: `feat(renderer): lhito subtitle font size 9pt → 20pt in both captionFontSizeFor copies`

---

## Phase 5 — Documentation (R7)

- [ ] **T5.1** `docs/templates/SPECS_interior.md` — make exactly five targeted corrections:
  1. L2.B dimensions: `115.5 × 86 mm portrait` → `175 × 107 mm landscape`
  2. L4.A dimensions: `86 × 110` → `86 × 86 SQUARE`
  3. L7 dimensions: `142 × 105 mm` → `86 × 110 mm`; caption column note → `7.5 mm photo-to-date gap`
  4. Positioning model section: replace `AUTO` centering wording → `"8 mm from the outer (non-binding) trim edge; mirrored per page parity (isLeftPage = pageNumber.isOdd)."`
  5. L_hito subtitle row: `9 pt / 10.8 pt` → `P22 Mackinac book 20 pt / 24 pt`
  Satisfies R7.

  Commit: `docs(specs): update L2B, L4A, L7 dims, positioning model, lhito subtitle`

---

## Phase 6 — Final Verification (R6)

- [ ] **T6.1** Run `flutter analyze` — zero warnings or errors. Confirm:
  - No `public_member_api_docs` violations on `outerMarginMm` and `_outerAlignedX` dartdoc.
  - Exhaustive `switch (code)` in `solve()` still covers all 16 `DotsLayoutCode` values.
  - No dangling call to the old `_singlePhotoCentered` name.

- [ ] **T6.2** Run `flutter test` — ALL tests GREEN. Confirm:
  - Geometry tests (T1.1) GREEN.
  - Requirements test file (T2.1) GREEN.
  - All 16 layout fixtures in `dots_layout_solver_test.dart` GREEN (corrected values).
  - Parity tests for L1, L4A, L8 (T2.9) GREEN.
  - L_hito font-size tests (T4.1) GREEN.
  - Full pre-existing suite unbroken.

  Commit: `test(layout): verify all fixtures green post outer-edge alignment`

---

## Dependency Graph

```
T1.1 → T1.2 → T1.3                        (geometry constant before solver)
T2.1 → T2.2 → T2.3, T2.4, T2.5           (signature change breaks all call sites)
T2.2 → T2.6 → T2.7 → T2.8                (helper before rename)
T2.8 → T3.1 … T3.16 (sequential per layout; can batch)
T3.1 … T3.16 → T4.1 → T4.2, T4.3        (solver must be correct before font override tests)
T4.2, T4.3 → T5.1 (independent, can parallel)
T5.1 → T6.1 → T6.2
```

---

## Risks

| Risk | Tasks | Mitigation |
|------|-------|------------|
| `outerMarginMm` required constructor arg breaks any external callers of `DotsPageGeometry(...)` beyond `dotbookDefault()` | T1.2 | Codebase search confirms `dotbookDefault()` is the sole production constructor call; `T1.3` runs analyzer immediately after T1.2 to surface any missed site. |
| `_captionFontSizeFor` drift between renderer and isolate — one copy updated, other missed | T4.2, T4.3 | Both files updated in the same commit; T4.1 adds a test for the renderer path; design calls this out explicitly as drift risk. |
| L1B per-parity bleed resolution in renderer is deferred — bilateral flags may look odd on right pages if renderer inspects them differently later | T3.3 | Decision 3 is documented in the solver comment; out-of-scope per spec. Flag for renderer follow-up. |
| L1 / L1A / L1E `bodyH` values use conservative line-count estimates; real renders may overflow or under-fill | T3.1, T3.2, T3.6 | Design's open question; values are intentional conservative reserves. Add a comment in each solver case noting the derivation. |
| L7 `_l7HalfSpread` rewrite is the most complex (two panes + captions each); fixture may miss a sub-slot | T3.14 | Fixture asserts slot count + kind list explicitly before asserting coordinates. |
| Size:exception accepted — single large PR is harder to review | all | User direction; mitigated by work-unit commit discipline (one commit per phase). |

---

## Requirement Coverage Matrix

| Requirement | Tasks |
|-------------|-------|
| R1 — `DotsPageGeometry.outerMarginMm` | T1.1, T1.2, T1.3 |
| R2 — `solve()` `isLeftPage` parameter | T2.1, T2.2, T2.3, T2.4, T2.5 |
| R3 — `_outerAlignedX` semantics | T2.6, T2.7, T2.8, T2.9 |
| R4 — Per-layout slot-rect contracts (16 layouts) | T3.1–T3.16 |
| R5 — L_hito subtitle font-size override | T4.1, T4.2, T4.3 |
| R6 — Test fixture regression contract | T2.1, T2.8, T2.9, T3.1–T3.16, T6.1, T6.2 |
| R7 — `SPECS_interior.md` corrections | T5.1 |
