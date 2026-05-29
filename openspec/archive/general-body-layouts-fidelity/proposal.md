# Proposal: general-body-layouts-fidelity

## Intent

`DotsLayoutSolver` (`lib/src/render/layout/dots_layout_solver.dart`, 579 LOC)
emits slot rectangles that are **structurally** plausible but **dimensionally
and positionally wrong** for almost every layout. Every photo block is
*page-centered*, while the canonical PDF (`docs/templates/final_templates/pdf01_general_base.pdf`,
85 pages of measurement annotations) positions every photo at a fixed
**8 mm from the outer (non-binding) trim edge** — flipped per page parity.
Three layouts are dimensionally wrong (L2B is portrait when it should be
landscape; L4A is 86×110 when it should be 86×86 square; L7's photo size and
gap are both off). Caption slots are missing from L1 / L1A / L1E. L_hito's
title and subtitle widths are clipped (122 mm vs the spec's 149 mm) and the
subtitle reserves date-sized space when it should be 20 pt.

The solver's centering math is therefore wrong in 15 of 16 layouts (L3A is
coincidentally correct because its 186.81 mm block centers at ~8.095 mm). The
explore phase ground-truthed every layout against the PDF and produced the
mismatch table. This change applies those corrections.

This is **Task 3 of 7** in the `final-render-refinement` series, after Task 1
(`page-template-chrome`, archived — already wired `isLeftPage = pageNumber.isOdd`
through the renderer at `dots_renderer.dart:394`) and Task 2
(`pliego-first-category`, archived — established the category-driven
composition pipeline). Tasks 4–7 build per-category factory bodies on top of
the now-correct solver geometry; if we ship Task 3 wrong, every downstream
factory inherits the wrong slot coordinates.

**Success looks like:** all 16 solver layouts emit slot rectangles whose
absolute coordinates match the canonical PDF on both left and right pages;
L1 / L1A / L1E expose the missing caption slots; L_hito's subtitle is the
20 pt block the spec mandates; the test suite expresses the correct
coordinates and is GREEN.

## Scope

### In Scope

- **`DotsPageGeometry.outerMarginMm = 8`** constant added (per Decision 1, lives on `DotsPageGeometry` alongside `bindingInsetMm`).
- **`DotsLayoutSolver.solve()` signature change** — adds `required bool isLeftPage`. Hard break for every internal caller; no external users known.
- **Private helper `_outerAlignedX(geometry, blockWidthMm, {required bool isLeftPage})`** returning `geometry.outerMarginMm` on a left page and `geometry.pageWidthMm - geometry.outerMarginMm - blockWidthMm` on a right page. Resolves Approach B from the explore.
- **All four `solver.solve(...)` production callers updated** (see Decision 2): `lib/src/render/dots_renderer.dart:386`, `lib/src/render/isolate_synthesis.dart:245`, `lib/src/config/dots_template_parser.dart:459`, and `test/render/layout/dots_layout_requirements_test.dart:26`. Renderer + isolate pass `page.pageNumber.isOdd`; the parser passes a fixed value because it validates shape, not position (decided in spec phase).
- **Per-layout corrections** (the heart of the change):
  - **L1**: y=57 mm; x via `_outerAlignedX`; new `captionDate` slot above the photo + `captionBody` slot above the date (grows upward, max 400 chars).
  - **L1A**: y=33.5 mm; x via `_outerAlignedX`; new side caption column (82 mm wide, max 800 chars).
  - **L1B**: x via `_outerAlignedX`. Bleed flags re-resolved per Decision 4 — only the outer edge bleeds, plus top + bottom; comment clarifies parity resolution.
  - **L1C**: y=23 mm (canonical centered variant); x via `_outerAlignedX`. Caption-driven y variants (12/50 mm) deferred — see Out of Scope.
  - **L1D**: x via `_outerAlignedX`; dimensions unchanged. Marked "best-effort, PDF-unconfirmed" per Decision 3.
  - **L1E**: x via `_outerAlignedX`; new caption slots by analogy with L1A. Marked "best-effort, PDF-unconfirmed".
  - **L2A**: x via `_outerAlignedX` (≈0.5 mm correction vs current centering).
  - **L2B**: **rewrite** — 175×107 mm landscape, two stacked, 29 mm top y, 3 mm gap, x via `_outerAlignedX`. (Was 115.5×86 mm portrait.)
  - **L2C**: keep 2 photos per Decision 5 in the explore; x via `_outerAlignedX`. The 6-photo arrangement on PDF p.81 is a different unnamed layout deferred to a later task.
  - **L3A**: x via `_outerAlignedX` (numerically equivalent to today, but explicit intent replaces the coincidence).
  - **L4A**: **rewrite** — 86×86 mm SQUARE 2×2 grid, y=71 mm, x via `_outerAlignedX`. (Was 86×110 mm.)
  - **L4B**: x via `_outerAlignedX`; canonical y picked (non-caption-driven variant — exact value committed in spec phase from PDF pp.49–52).
  - **L6A**: x via `_outerAlignedX`.
  - **L7**: **rewrite** — 86×110 mm photos, 7.5 mm photo-to-caption gap, two panes per page; date caption ~4 mm, body caption grows downward up to 350 chars. (Was 142×105 mm with 1 mm gap.)
  - **L8**: x via `_outerAlignedX`.
  - **L_hito**: text-block width 122 → **149 mm** (title and subtitle); subtitle stays a `captionDate` slot but `dateHeightMm` enlarges to hold 20 pt at ~24 pt leading (so the height matches the renderer override below).
- **Renderer change** (`lib/src/render/dots_renderer.dart` AND `lib/src/render/isolate_synthesis.dart`): `_captionFontSizeFor(captionDate, lhito)` returns **20.0** (was 9.0). The font ROLE is already correct (`p22MackinacBook` at `dots_renderer.dart:715-716` and `isolate_synthesis.dart:506-507` — verified). Both copies must change together. Comments at `dots_renderer.dart:774-777` and `isolate_synthesis.dart:_captionFontSizeFor` are rewritten to reflect "L_hito subtitle is P22 Mackinac BOOK 20 pt / 24 pt".
- **Test fixture updates** for ~14 of 16 layouts in `test/render/layout/dots_layout_solver_test.dart`. The new fixtures express the corrected coordinates per page parity. This is a regression-by-design — every existing assertion that hardcoded the page-centered x or the wrong dimensions WILL fail and MUST be updated.
- **`docs/templates/SPECS_interior.md` corrections**: L2B (115.5×86 → 175×107 landscape), L4A (86×110 → 86×86 square), L7 (142×105 → 86×110), positioning model ("AUTO" → outer-edge-aligned 8 mm), L_hito subtitle font/size.

### Out of Scope (deferred to Tasks 4–7)

- **New layout codes** — e.g. the unnamed 70.5×86 mm small-photo variant on PDF pp.13–18, or the 6-photo 2×3 grid on PDF p.81. Adding `DotsLayoutCode` values is a public-API expansion that belongs in a dedicated change.
- **Caption-driven y variants** on L1C (12 / 23 / 50 mm) and L4B (23 / 136 mm). Picking the y at render time based on caption length is a renderer-level layout-adjustment rule, not solver geometry. Deferred.
- **Per-category factory bodies** — Tasks 4–7 fill the seven factory stubs that Task 2 left as `UnimplementedError`.
- **L_hito QR width adjustment at 500 chars** (open question 4 from explore) — renderer heuristic, not solver geometry.
- **L1B outer-edge bleed wiring to the renderer suppression predicate** beyond what Task 1 already established. The bleed flags this change emits stay compatible with Task 1's predicate; richer per-parity suppression is a renderer follow-up if needed.

## Capabilities

> Researched `openspec/specs/` — directory is **empty** (verified via Glob: no `*/spec.md` files). Same situation as Task 2's proposal acknowledged. All entries below are new.

### New Capabilities

- `layout-solver-geometry`: the per-layout slot-rect contract — for each `DotsLayoutCode`, the canonical photo and caption rectangles in millimeters relative to the page origin, parameterized by `isLeftPage`. Also covers `outerMarginMm`, the outer-edge alignment helper semantics, and the L1B bleed-flag convention.

### Modified Capabilities

- None. No prior per-capability specs exist to delta against.

## Approach

**Approach B from the explore** — confirmed.

1. Add `outerMarginMm = 8` to `DotsPageGeometry` (constructor required arg with `dotbookDefault()` factory supplying 8).
2. Add a `required bool isLeftPage` parameter to `DotsLayoutSolver.solve(...)`. The solver is otherwise stateless.
3. Add a private `_outerAlignedX(geometry, blockWidthMm, {required bool isLeftPage})` helper. Use it in every private layout method that emits a photo block.
4. Replace every `(pageWidthMm - blockWidth) / 2` x-computation with `_outerAlignedX(...)`. Replace L3A's coincidental centering with the same explicit call. Update y-coordinates where they were wrong (L1 / L1A / L1C / L2B / L4A — see scope table).
5. Rewrite L2B, L4A, L7 dimensions and gaps. Add caption slots for L1 / L1A / L1E.
6. Update the L_hito `_lhito` method: text-block width 149 mm, enlarge subtitle height reservation to ~24 pt leading.
7. Update production callers and tests in lock-step.
8. Update the renderer's `_captionFontSizeFor` for the L_hito date case (in both copies — `dots_renderer.dart` and `isolate_synthesis.dart`).
9. Update `docs/templates/SPECS_interior.md` to reflect the corrected L2B / L4A / L7 dimensions and the outer-edge positioning model.

**Why not Approach A (in-place constant corrections, no helper):** the centering pattern repeats across 12 methods; fixing it 12 times duplicates the page-parity flip and risks inconsistency. Extracting `_outerAlignedX` makes outer-edge intent explicit in code and gives Tasks 4–7 a tested primitive.

**Why not Approach C (declarative spec table):** every layout has unique logic (L1B bleed, L7 pane stacking, L8 mixed rows, L_hito text blocks). A `Map<DotsLayoutCode, DotsLayoutSpec>` would over-generalize and balloon LOC.

### Public API delta

**New:**
- `DotsPageGeometry.outerMarginMm` — `final double`. Constructor adds a required arg; `dotbookDefault()` supplies 8.

**Modified:**
- `DotsLayoutSolver.solve(DotsLayoutCode code, DotsPageGeometry geometry, {required bool isLeftPage})` — adds a required named parameter. Hard break for any external caller (none expected outside this repo).
- 14 of 16 layouts emit different (correct) slot coordinates. Behavioral break for downstream callers asserting on the old coords (every solver test).
- `_captionFontSizeFor(captionDate, lhito)`: 9.0 → 20.0 (private; no public API change).

**Removed:** None.

## Affected Areas

| Area | Impact | Description |
|------|--------|-------------|
| `lib/src/render/layout/dots_page_geometry.dart` | Modified | Add `outerMarginMm` field + constructor arg + `dotbookDefault()` supplies 8; update `==`/`hashCode`. |
| `lib/src/render/layout/dots_layout_solver.dart` | Modified (heavy) | Add `isLeftPage` param to `solve(...)`; add `_outerAlignedX` helper; rewrite 14 of 16 layouts (dimensions / x / y); add caption slots for L1 / L1A / L1E; enlarge L_hito text-block width and subtitle height; clarify L1B bleed semantics. |
| `lib/src/render/dots_renderer.dart` | Modified | Pass `page.pageNumber.isOdd` to `solver.solve(...)` at line 386; update `_captionFontSizeFor` lhito case to 20.0 and rewrite comment at lines 774-777. |
| `lib/src/render/isolate_synthesis.dart` | Modified | Pass `isLeftPage` to `solver.solve(...)` at line 245 (same `pageNumber.isOdd` convention); update its sibling `_captionFontSizeFor` to match. |
| `lib/src/config/dots_template_parser.dart` | Modified | Pass `isLeftPage` to `solver.solve(...)` at line 459 — the call validates shape, not position; spec phase decides the fixed value (likely `true`/canonical) and documents why. |
| `lib/src/render/layout/dots_slot_rect.dart` | Unchanged | No new `DotsSlotKind` needed (Decision 6). |
| `lib/dots_pdf.dart` | Unchanged | `outerMarginMm` is a field on an already-exported class; no new exports. |
| `test/render/layout/dots_layout_solver_test.dart` | Modified (heavy) | New expected coords for 14 of 16 layouts; coverage of left-page and right-page x mirroring; new assertions for caption slots on L1 / L1A / L1E; L_hito subtitle height. |
| `test/render/layout/dots_layout_requirements_test.dart` | Modified | `solver.solve(...)` call updated to pass `isLeftPage`. |
| `docs/templates/SPECS_interior.md` | Modified | L2B / L4A / L7 dimension corrections; positioning model "AUTO" → outer-edge-aligned 8 mm; L_hito subtitle font and size. |

## Risks

| Risk | Likelihood | Mitigation |
|------|------------|------------|
| **`outerMarginMm` is a required constructor arg** on `DotsPageGeometry` — every consumer constructing one breaks at compile time. | Medium | Only one factory exists today (`dotbookDefault()`); analyzer surfaces the rest. Alternative considered (default value) rejected because we want explicit intent. |
| **Tests break across the board** — 14 of 16 layout expectations change. | High (by design) | This is the regression-by-design the explore flagged. Strict TDD: spec phase enumerates each new expectation, tasks phase commits to RED → GREEN. |
| **L1D and L1E are PDF-unconfirmed.** Picking exact mm values without spec evidence risks a second correction later. | Medium | Mark them in code comments as "best-effort, PDF-unconfirmed — see Task N follow-up if subsequent design pages contradict". Keep current dimensions, only fix positioning. |
| **L_hito subtitle height growth** — going from `10.8 pt` leading to `24 pt` leading enlarges `totalHeight` in `_lhito`. The current `_requireFits` may now fail on some geometries. | Medium | Verify `totalHeight` still fits `liveAreaHeightMm = 230 mm` for `dotbookDefault()` in spec phase. With 24 pt leading subtitle (~8.47 mm) replacing 3.81 mm, height grows ~4.66 mm — well within 230 mm. |
| **L1B bleed semantics carryover** — Task 1's chrome suppression predicate inspects bleed flags. Changing them per parity could shift suppression behavior. | Low | Decision 4 keeps `bleedLeft = true` AND `bleedRight = true` (so the predicate sees the same shape it does today). The clarifying comment teaches readers that only one side actually bleeds in print, but the slot model preserves the bilateral flag set. Renderer-side per-parity refinement deferred. |
| **The two `_captionFontSizeFor` copies** (renderer + isolate) drift if only one is updated. | Medium | Tasks phase requires both edits in the same commit, and a test asserts L_hito date font size = 20 pt via the renderer path (analyzer would not catch a drift in isolate sibling). |
| **`parser.dart:459` passes a fixed `isLeftPage`** — if the parser's validation later needs page-aware geometry, the fixed value misleads. | Low | Spec phase documents that parser-side `solve(...)` validates SHAPE (slot count + slot KINDS), not absolute positions. A fixed canonical value is correct for this purpose. |
| **L3A's previously coincidental correctness** disappears if `_outerAlignedX` returns a slightly different value due to floating-point. | Very Low | The arithmetic is identical: `(203 − 186.81) / 2 = 8.095` ≈ `outerMarginMm = 8.000` on a left page (≈0.095 mm drift). Acceptable — outer-edge alignment is the canonical truth, not centering. Test fixtures updated to `8.0`. |

## Rollback Plan

All changes land on the `final-render-refinement` branch as conventional commits, **single PR** per the user's removed size guardrail. Rollback = `git revert` the proposal's slice commits in reverse order. Specifically:

- `outerMarginMm` constant addition is purely additive.
- Solver signature change (`isLeftPage`) and per-layout corrections are mechanical to revert — they restore the centering math and the wrong constants.
- Renderer `_captionFontSizeFor` revert restores 9.0 for L_hito date.
- Test fixture updates revert with the production code (commit-paired).
- `SPECS_interior.md` reverts to the pre-correction state.

No cache invalidation needed — slot coordinates are computed from inputs every render, not memoized across config versions.

## Dependencies

- **Task 1 (`page-template-chrome`)** — archived 2026-05-28. Provides `isLeftPage = pageNumber.isOdd` derivation already wired through `_buildLayoutPage` at `dots_renderer.dart:394`. We piggyback on that convention; no new chrome work.
- **Task 2 (`pliego-first-category`)** — archived. Establishes the seven new factory stubs that Tasks 4–7 will fill. Independent of Task 3 because Task 2 leaves the solver untouched.
- Tasks 4–7 depend on Task 3's corrected solver geometry being stable. The spec phase locks the per-layout coordinates so Tasks 4–7 can hardcode their factory math against them.

## Success Criteria

- [ ] `DotsPageGeometry` exposes `outerMarginMm`; `dotbookDefault()` supplies 8.
- [ ] `DotsLayoutSolver.solve(...)` requires `isLeftPage`; all four production callers pass the correct value.
- [ ] `_outerAlignedX(...)` is the sole x-computation primitive for every photo block in the solver.
- [ ] All 16 layouts emit slot rectangles whose coordinates match the canonical PDF on both left and right pages (test-asserted per parity).
- [ ] L1 / L1A / L1E emit `captionDate` + `captionBody` slots; layout dimensions per the explore mismatch table.
- [ ] L2B emits 175×107 mm landscape ×2 stacked; L4A emits 86×86 mm square ×4; L7 emits 86×110 mm photos with 7.5 mm gap.
- [ ] L_hito emits 149 mm wide title + subtitle blocks; renderer sets the subtitle font size to 20 pt; subtitle height reservation accommodates 24 pt leading.
- [ ] `flutter analyze` clean and `flutter test` passes (all updated fixtures GREEN).
- [ ] `docs/templates/SPECS_interior.md` reflects the corrected dimensions and the outer-edge positioning model.

## Decisions (the 5 from the brief)

1. **`outerMarginMm` lives on `DotsPageGeometry`** as a constructor field, not a solver-private constant. Rationale: it is page-level geometry semantically siblings of `bindingInsetMm` and `headerBandMm`, and Tasks 4–7 will need to reference it from factory code outside the solver. `dotbookDefault()` factory supplies 8. Trade-off: the constructor gains a required arg (every direct instantiation breaks until updated), but there is only one factory in production today (`dotbookDefault()`) so the blast radius is bounded by `dart analyze`.

2. **Four production `solver.solve(...)` callers must update — not two.** Verified via grep: `dots_renderer.dart:386`, `isolate_synthesis.dart:245`, `dots_template_parser.dart:459`, plus the test fixture file. The brief mentioned `dots_renderer.dart:354,394` — that's incorrect; line 354 is the `_buildElementsPage` `isLeftPage` derivation (unrelated to solver), and only line 386 hosts the `_buildLayoutPage` `solve(...)` call. The renderer and isolate pass `page.pageNumber.isOdd`. The parser passes a fixed canonical value (`true`) because its `_validateLayoutPageAgainstSolver` validates slot count and kinds, not positions — spec phase documents this and adds a code comment.

3. **L1D and L1E ARE marked "best-effort, PDF-unconfirmed".** Their dimensions stay unchanged (no PDF evidence to override), but outer-edge alignment applies. The proposal explicitly flags them so a future spec-driven correction does not look like a regression. A `// PDF-unconfirmed — see Task N follow-up` comment lives next to each method.

4. **L1B bleed-flag semantics — solver emits `bleedTop=bleedBottom=bleedLeft=bleedRight=true`; the comment teaches readers that the outer edge is the only edge that physically bleeds.** The existing solver code already does this (lines 124-125 with a comment about per-parity mirroring). The change: x switches from centering to `_outerAlignedX`, and the comment is rewritten to be clearer about the renderer's responsibility. Per-parity bleed RESOLUTION (suppressing the binding-side bleed at draw time) is a renderer follow-up because Task 1's chrome predicate inspects bilateral flags today; flipping that to per-parity is a Task 1 retrospective, not Task 3.

5. **Size estimate for the Review Workload Forecast: ~700–900 LOC, test-heavy.**

| Slice | LOC estimate |
|---|---|
| `DotsPageGeometry` + `outerMarginMm` | ~15 |
| Solver: signature change + `_outerAlignedX` | ~25 |
| Solver: 14 layout corrections + caption slots for L1/L1A/L1E | ~250–350 (net; some methods grow, some shrink) |
| Solver: L_hito subtitle resize | ~10 |
| Renderer: `_captionFontSizeFor` lhito case + comment | ~10 |
| Isolate synthesis: same change | ~10 |
| Parser: pass `isLeftPage` | ~5 |
| Test fixtures: 14 layouts × ~10 LOC each + parity coverage | ~200–300 |
| Test: renderer L_hito font-size assertion | ~20 |
| `SPECS_interior.md` corrections | ~30 |
| **Total** | **~575–775 LOC** |

**Per the user's removed PR-size guardrail (single-PR delivery already chosen), no chained split required.** Tasks phase emits the Review Workload Forecast with `Chained PRs recommended: No`, `400-line budget risk: High`, `Decision needed before apply: No` (user has pre-resolved).

### Extra decision discovered during verification (worth flagging)

6. **No new `DotsSlotKind` for the L_hito subtitle.** Verified: the renderer already routes `captionDate` for `lhito` to `DotsFontRole.p22MackinacBook` (`dots_renderer.dart:715-716`; `isolate_synthesis.dart:506-507`). The only renderer change is the font SIZE (9.0 → 20.0). The brief's claim that the role override "is needed" is wrong — it already exists. Just the size and the solver's subtitle height reservation change.
