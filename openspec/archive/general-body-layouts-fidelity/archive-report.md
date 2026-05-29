# Archive report: general-body-layouts-fidelity

**Date:** 2026-05-29
**Change:** general-body-layouts-fidelity
**Series position:** Task 3 of 7 (`final-render-refinement`)
**Result:** shipped — 667 tests GREEN / 0 RED, `flutter analyze` clean

---

## What shipped

Single-PR delivery on branch `general-body-layouts-fidelity` (off Task 2's tip).
Two commits ahead of the tracker:

| SHA | Title |
|---|---|
| `14f5295` | chore(general-body-layouts-fidelity): SDD planning artifacts |
| `8b0e912` | feat(render): outer-edge layout fidelity for all 16 body layouts |

### Architectural shift

- **Outer-edge alignment**: every photo block now anchors 8 mm from the OUTER
  (non-binding) trim edge of its page. Previously every layout was
  page-centered; that matched the printed design only for L3A by coincidence.
- **`DotsLayoutSolver.solve()` gains `required bool isLeftPage`.** Renderer
  call sites pass `page.pageNumber.isOdd`; parser validation passes
  `isLeftPage: true` canonically.
- **`DotsPageGeometry.outerMarginMm = 8`** added.
- **`_outerAlignedX` helper** resolves per-page parity. Exposed via
  `@visibleForTesting outerAlignedXForTest`.

### Per-layout corrections (against PDF measurements)

- **L1** 142×189 at y=57 — now emits 3 slots (photo + captionDate + captionBody above the photo). Captions were missing before.
- **L1A** 113×152 at y=33.5 with 82 mm side-caption column; column flips to the binding side per parity.
- **L1B** outer-bleed: bleed flags now parity-resolved (binding edge never bleeds).
- **L1C** 175×196 at canonical y=23.
- **L1D** 107×107 square — outer-aligned (PDF-unconfirmed dimensions kept).
- **L1E** 107×152 with side caption (by analogy with L1A; PDF-unconfirmed).
- **L2A** 86×110 ×2 side-by-side, 16 mm gutter — outer-aligned.
- **L2B REWRITE**: 175×107 LANDSCAPE ×2 stacked (was 115.5×86 portrait — wrong orientation).
- **L2C** 65×74 ×2 stacked — outer-aligned.
- **L3A** 60.27×82 ×3 row at y=86 — same effective x (≈8 mm) but now explicit.
- **L4A REWRITE**: 86×86 **SQUARE** ×2×2 at y=71 (was 86×110 portrait — wrong height).
- **L4B REWRITE**: 86×110 stacked vertically (was side-by-side horizontal — wrong arrangement). Canonical y=23.
- **L6A** 2+1 arrangement — outer-aligned.
- **L7 REWRITE**: 86×110 panes with 7.5 mm photo-to-caption gap (was 142×105 with 1 mm gap).
- **L8** 86×110 top ×2 + 175×115.5 bottom — outer-aligned.
- **LHITO** title + subtitle widths 122 → 149 mm; subtitle font is now P22 Mackinac regular 20 pt via the `_captionFontSizeFor(captionDate, lhito)` override (was 9 pt as a date line, semantically incorrect).

### Renderer changes

`_captionFontSizeFor(captionDate, lhito)` returns 20.0 in BOTH `DotsRenderer` and `isolate_synthesis` to prevent drift between the main thread and isolate synthesis paths.

### Tests

- Rewrote `dots_layout_solver_test.dart` with outer-edge assertions for all 16 layouts.
- Added explicit left-page + right-page parity tests for L1, L4A, L8 (block mirroring) and L1B (bleed flag mirroring).
- Added `DotsLayoutSolver.outerAlignedXForTest` direct unit tests.
- Updated `dots_layout_requirements_test.dart` to pass `isLeftPage`.

### Docs

`SPECS_interior.md` corrected: replaces the old "AUTO = page-centered" convention with the outer-edge model; fixes L2B / L4A / L7 dimensions.

---

## Test delta

- Pre-change baseline: 660 tests GREEN (post-Task 2).
- Post-change: **667 tests GREEN / 0 RED**. Net +7 — the outer-edge unit tests and parity tests.

---

## Deferred work / out of scope

- Caption-driven y-variants on L1C (12/23/50 mm) and L4B (23/136 mm) — these are renderer-level layout-adjustment rules, deferred for a future task.
- The unnamed 70.5×86 mm variant on PDF pages 13–18 and the 6-photo arrangement on PDF page 81 are not yet codified; if needed they will become new layout codes.
- Per-category factory bodies (Tasks 4–7) — Task 3 fixes only the body layout solver; per-category mandatory front/back-matter spreads still ship as `DotsUnimplementedElement` stubs from Task 2.

---

## Verification

- `flutter analyze`: clean (0 warnings, 0 errors).
- `flutter test`: 667 GREEN / 0 RED.
- All 39 task items in `tasks.md` checked off.
- Spec requirements R1–R7 covered by implementation + tests.
- The 7 risk items from the spec are addressed (L4B vertical-stack interpretation confirmed by direct PDF reading of pages 49–52).
