# Exploration: general-body-layouts-fidelity

**Date:** 2026-05-29
**Change:** general-body-layouts-fidelity
**Phase:** explore
**Status:** complete
**Series position:** Task 3 of 7 (`final-render-refinement`), building on Tasks 1 (`page-template-chrome`, archived) and 2 (`pliego-first-category`, archived).

---

## Current State

### 1. The Solver — One Switch, Hardcoded Constants

`lib/src/render/layout/dots_layout_solver.dart` (579 lines) is a stateless class with a single `solve(DotsLayoutCode code, DotsPageGeometry geometry)` switch dispatching to 16 private methods. Two positioning strategies:

- `_singlePhotoCentered(geometry, widthMm, heightMm)` — l1, l1a, l1c, l1d, l1e. `x = (pageWidthMm - widthMm) / 2`, `y = liveAreaTopMm + (liveAreaHeightMm - heightMm) / 2`.
- `_verticalStack(...)` — l2b, l2c. Same centering math.
- Inline page-centering for l2a, l4a, l4b, l6a, l7, l8.

**The solver has no concept of outer-edge alignment.** Every layout is page-centered. The canonical PDF template uses outer-edge alignment (8 mm from the outer trim edge) consistently across ALL photo layouts.

### 2. DotsPageGeometry

`lib/src/render/layout/dots_page_geometry.dart`:
- `pageWidthMm = 203`, `pageHeightMm = 254`, `bleedMm = 3`
- `headerBandMm = 12`, `footerBandMm = 12`, `bindingInsetMm = 23`
- `liveAreaTopMm = 12`, `liveAreaBottomMm = 242`, `liveAreaHeightMm = 230`

`bindingInsetMm = 23` is defined but never consumed by the solver. Photo blocks are centered within the 203mm full width.

### 3. DotsLayoutCode — 16 values

`l1, l1a, l1b, l1c, l1d, l1e, l2a, l2b, l2c, l3a, l4a, l4b, l6a, l7, l8, lhito`.

### 4. Task 1 Chrome Integration

Task 1's `DotsPageChrome` suppression predicate inspects slot bleed flags. The suppression logic touches l1b (bleedTop=true, bleedBottom=true). Any bleed-flag corrections in this task flow into the suppression predicate.

### 5. Source of Truth

`docs/templates/final_templates/pdf01_general_base.pdf` (85 pages). All ground-truth measurements below extracted directly from the PDF's measurement annotations.

---

## Positioning Convention (All Layouts)

The PDF consistently positions photos at:
- **8 mm from the outer (non-binding) trim edge** — the side away from the spine.
- **20 mm from the binding edge** on the same page.

For a right-hand page: outer = right edge. For a left-hand page: outer = left edge. The solver's centering math is almost always wrong. The single exception is **L3A**: its 186.81mm block leaves `(203 - 186.81)/2 = 8.095mm ≈ 8mm` — a coincidence.

---

## PDF Page → Layout Map

| PDF pages | Layout code | Notes |
|---|---|---|
| 1 | Chrome spec | Task 1 |
| 2–8 | L1 + EJEMPLO variants | 142×189 mm, y=57 mm |
| 9–12 | L1A + EJEMPLO | 113×152 mm, y=33.5 mm |
| 13–18 | Unnamed small-photo variant | 70.5×86 mm — no matching code today |
| 19–20 | L1B | 175×238 mm full-outer-bleed |
| 21–28 | L1C + EJEMPLO (3 y-variants) | 175×196 mm; y=12/23/50 mm |
| 29–36 | L1E (probable) + EJEMPLO | 107×152 mm, unconfirmed label |
| 37–44 | L2B + EJEMPLO | 175×107 mm landscape ×2 stacked |
| 45–48 | L7 region | 86×110 mm ×2 per page, 7.5 mm gap |
| 49–52 | L4B variants | 86×110 mm ×2 |
| 53–60 | L6A + EJEMPLO | 2+1 arrangement, 86×110 mm |
| 61–66 | L3A + EJEMPLO | 60.27×82 mm ×3, y=86 mm |
| 67–72 | L4A + EJEMPLO | **86×86 mm SQUARE** ×4, y=71 mm |
| 73–74 | L7 full-spread EJEMPLO | captions confirmed |
| 75–76 | L8 EJEMPLO | 2×86×110 top + 1×175×115.5 bottom |
| 77–78 | L2B confirmed | landscape ×2 |
| 79–80 | L8 spread view | |
| 81 | L2C 6-photo view | 65×74 mm ×6 (2×3 grid) — count ambiguous |
| 82 | L4A spec sheet | 86×86 mm SQUARE explicitly annotated |
| 83–85 | L_hito spec + EJEMPLO ×2 | Title 149mm, P22 Mackinac regular subtitle 20pt |

---

## Per-Layout Mismatch Summary

| Code | Severity | Dimensions | x-position | y-position | Bleed | Captions |
|---|---|---|---|---|---|---|
| l1 | HIGH | OK | WRONG | WRONG | — | Missing |
| l1a | HIGH | OK | WRONG | WRONG | — | Missing (side column) |
| l1b | MEDIUM | OK | WRONG | OK | Binding-edge flag wrong | — |
| l1c | MEDIUM | OK | WRONG | WRONG | — | — |
| l1d | UNKNOWN | Unverified | Unverified | Unverified | — | — |
| l1e | UNKNOWN | Unverified | Unverified | Unverified | — | Missing (probable) |
| l2a | LOW | OK | ≈0.5mm off | WRONG | — | — |
| l2b | CRITICAL | WRONG (portrait↔landscape) | WRONG | WRONG | — | — |
| l2c | HIGH | OK | WRONG | WRONG | — | Count ambiguous |
| l3a | OK | OK | OK (coincidental) | OK | — | — |
| l4a | CRITICAL | Height WRONG (110→86) | WRONG | VERY WRONG | — | — |
| l4b | MEDIUM | OK | WRONG | WRONG | — | — |
| l6a | MEDIUM | OK | WRONG | WRONG | — | — |
| l7 | CRITICAL | Both dims WRONG | WRONG | WRONG | — | Gap 1mm→7.5mm |
| l8 | LOW | OK | WRONG | OK | — | — |
| lhito | MEDIUM | Title/subtitle widths wrong | OK | OK | — | Subtitle font wrong |

Layouts fully correct: **l3a only.**

---

## Critical Specifics

### L2B — portrait → landscape (CRITICAL)

Solver: 115.5×86mm portrait, two stacked. PDF: 175×107mm landscape, two stacked, 3mm gap, 8mm outer x, 29mm top y. Full math: `29 + 107 + 3 + 107 + 8 = 254mm` (fills page height).

### L4A — 110 → 86 mm height (CRITICAL)

Solver: 86×110mm portrait, 2×2 grid. PDF: 86×86mm SQUARE, 2×2 grid. y=71mm. Full math: `71 + 86 + 3 + 86 + 8 = 254mm`. Solver's y=15.5mm collides with the header band.

### L7 — both dimensions wrong (CRITICAL)

Solver: 142×105mm with 1mm photo-to-caption gap. PDF: 86×110mm with 7.5mm gap. Structurally correct (date + body below each photo) but the gap and dimensions need a full rewrite.

### L1B — bleed-flag semantics (MEDIUM)

Solver: bleedLeft=bleedRight=true. PDF: only the outer (non-binding) edge bleeds, plus top+bottom. The fix requires the solver (or renderer) to know which edge is the binding side.

### L_hito subtitle (MEDIUM)

Solver emits `captionDate` (small font implied). PDF annotates the subtitle as P22 Mackinac REGULAR **20pt / 24pt** — same font size as the title. NOT a small date line.

### Caption slots missing (HIGH)

The solver emits caption slots only for l7 and lhito. PDF requires caption slots for **l1, l1a, l1e** too:

| Layout | Required slots |
|---|---|
| l1 | captionDate (above photo) + captionBody (grows upward, max 400 chars) |
| l1a | captionDate + captionBody (82mm side column) |
| l1e | captionDate + captionBody (probable) |

---

## Affected Files

| File | Why affected |
|---|---|
| `lib/src/render/layout/dots_layout_solver.dart` | All constant corrections, new caption slots, outer-edge positioning |
| `lib/src/render/layout/dots_page_geometry.dart` | Add `outerMarginMm = 8` constant |
| `lib/src/render/layout/dots_slot_rect.dart` | No structural change; possibly a new `DotsSlotKind` for hito subtitle |
| `lib/dots_pdf.dart` | Re-export new public types if any |
| `test/render/layout/dots_layout_solver_test.dart` | Updated expected coordinates for ~14 of 16 layouts |
| `docs/templates/SPECS_interior.md` | L2B and L7 dimensions wrong; positioning model "AUTO" needs correction to outer-edge-aligned |

---

## Approaches

### Approach A — In-Place Constant Corrections

Fix constants and positioning formula inside each private method. Replace `(pageWidthMm - blockWidth) / 2` with `outerMarginMm` (8mm). Add caption slots. Correct L2B dimensions. Correct L4A height.

**Pros:** Minimal API change. Localized to one 579-line file.
**Cons:** Centering pattern duplicated across 12 methods — fixing it 12 times risks inconsistency. Conceptual error (page-centering vs outer-alignment) remains structurally.
**Effort:** Medium.

### Approach B — Extract `_outerAlignedX` Helper (RECOMMENDED)

Same as A, but extract `_outerAlignedX(geometry, blockWidthMm)` returning `geometry.outerMarginMm`. The renderer (already page-parity-aware via Task 1 chrome) mirrors x-coordinates for right pages.

**Pros:** Outer-edge intent explicit in code. Reduces future regression risk. Solver stays stateless.
**Cons:** Need to resolve `isLeftPage` semantics — does the solver emit canonical left-page coords and renderer mirrors? Most likely yes.
**Effort:** Medium.

### Approach C — Declarative Spec Table

Replace switch with `Map<DotsLayoutCode, DotsLayoutSpec>`.

**Pros:** Canonical data table.
**Cons:** Every layout has unique logic (l1b bleed, l7 pane stacking, l8 mixed rows, lhito text blocks). High over-generalization risk. >400 lines.
**Effort:** High.

**Recommendation: Approach B.**

---

## Open Questions

1. **Left/right parity in `solve()`.** Does the solver emit canonical left-page coords + renderer mirrors? Or does `solve()` need `isLeftPage: bool`? Investigate `DotsRenderer._buildLayoutPage` for current handling.
2. **L2C count.** Solver says 2, PDF page 81 shows 6. Resolve.
3. **L_hito subtitle font.** New `DotsSlotKind.captionSubtitle`, or renderer override?
4. **L_hito QR width at 500 chars.** Solver-side slot rule or renderer heuristic?
5. **L1B outer-edge bleed.** Solver emits `bleedOuterEdge: true` semantically and renderer resolves to bleedLeft/Right per page parity?
6. **L1C caption-driven y variants.** Three y positions (12/23/50mm) caption-content-driven. Solver-side or renderer-side?
7. **L1D and L1E verification.** Unconfirmed in PDF; flag for confirmation before correction.
8. **SPECS_interior.md corrections** in this task or separate?
9. **`outerMarginMm` constant location** — `DotsPageGeometry` (preferred) or solver-private?

---

## Risks

1. L4A and L2B dimensional changes are behaviorally breaking for downstream code that assumes the old dimensions.
2. Caption slot additions for L1/L1A add new `DotsSlotRect` entries — callers iterating slots and expecting only `photo` entries break (spec-compliant but behaviorally new).
3. L1B bleed semantics require renderer parity awareness.
4. Budget likely >400 lines — but per user direction "remove the limits in PR size", single PR is acceptable.
5. L3A's "accidental correctness" must be preserved through any refactor.

---

## Scope Note

In scope:
- All 16 `DotsLayoutSolver` methods — constant corrections, outer-edge positioning, bleed fix.
- Caption slot additions for l1, l1a, l1e (verify).
- L_hito subtitle font/width fix.
- `DotsPageGeometry.outerMarginMm = 8` constant.
- Test fixture updates.
- `SPECS_interior.md` corrections.

Out of scope (Tasks 4–7):
- Per-category factory bodies (Tasks 4–7 fill those).
- New layouts (e.g., the unnamed 70.5×86mm variant on PDF pages 13–18) — defer.
- Renderer-level layout-variant logic (caption-driven y on L1C).

**Ready for Proposal:** Yes, with open questions 1 (parity), 2 (L2C count), 3 (hito subtitle kind) resolved before spec.
