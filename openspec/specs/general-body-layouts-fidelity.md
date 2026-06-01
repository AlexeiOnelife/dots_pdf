# general-body-layouts-fidelity Specification

## Purpose

Corrects `DotsLayoutSolver` to emit outer-edge-aligned, dimensionally
accurate slot rectangles for all 16 layout codes. Adds `outerMarginMm`
to `DotsPageGeometry`, a parity-aware `isLeftPage` parameter to
`solve()`, and caption slots missing from L1 / L1A / L1E. Fixes
L_hito subtitle font size and text-block width.

**Source of truth:** `docs/templates/final_templates/pdf01_general_base.pdf`.

---

## Requirements

### Requirement: R1 — `DotsPageGeometry.outerMarginMm` constant

`DotsPageGeometry` MUST expose a `final double outerMarginMm` field.
`dotbookDefault()` MUST supply `outerMarginMm = 8`. The constructor
MUST require the argument explicitly (no default) so omissions are
compile errors. `==` and `hashCode` MUST include the new field.

#### Scenario: dotbookDefault supplies 8 mm

- GIVEN `DotsPageGeometry.dotbookDefault()`
- WHEN `.outerMarginMm` is read
- THEN the value equals `8.0`

#### Scenario: constructor without argument is a compile error

- GIVEN source that constructs `DotsPageGeometry(...)` without `outerMarginMm`
- WHEN compiled
- THEN a compile-time error is produced

---

### Requirement: R2 — `solve()` requires `isLeftPage`

`DotsLayoutSolver.solve(DotsLayoutCode, DotsPageGeometry, {required bool isLeftPage})`
MUST add `isLeftPage` as a required named parameter. Every existing
call site MUST be updated:

| Call site | Value passed |
|---|---|
| `dots_renderer.dart:386` | `page.pageNumber.isOdd` |
| `isolate_synthesis.dart:245` | `page.pageNumber.isOdd` |
| `dots_template_parser.dart:459` | `isLeftPage: true` (shape-only validation; position irrelevant) |
| `dots_layout_requirements_test.dart` | `isLeftPage: true` (canonical) |

The parser call site MUST include a code comment: *"Validates slot
shape (count + kinds), not absolute position — canonical left-page
value is correct here."*

#### Scenario: solve() without isLeftPage is a compile error

- GIVEN a call to `solver.solve(code, geometry)` without `isLeftPage`
- WHEN compiled
- THEN a compile-time error is produced

#### Scenario: renderer passes page parity

- GIVEN a page with `pageNumber = 2` (even = right page)
- WHEN the renderer calls `solve()`
- THEN `isLeftPage` is `false`

---

### Requirement: R3 — `_outerAlignedX` semantics

The solver's private helper `_outerAlignedX(geometry, blockWidthMm, {required bool isLeftPage})`
MUST be the sole x-computation primitive for every photo block.

| isLeftPage | Result |
|---|---|
| `true` | `geometry.outerMarginMm` (= 8.0) |
| `false` | `geometry.pageWidthMm − geometry.outerMarginMm − blockWidthMm` |

#### Scenario: left-page x equals outerMarginMm

- GIVEN `DotsLayoutSolver.solve(l1, dotbookDefault(), isLeftPage: true)`
- WHEN inspecting the photo slot
- THEN `xMm == 8.0`

#### Scenario: right-page x mirrors correctly

- GIVEN `DotsLayoutSolver.solve(l1, dotbookDefault(), isLeftPage: false)`
- WHEN inspecting the photo slot
- THEN `xMm == 203.0 − 8.0 − 142.0 == 53.0`

---

### Requirement: R4 — Per-layout slot-rect contracts

All 16 layouts MUST emit slot rectangles matching the canonical PDF.
"x" below refers to the result of `_outerAlignedX` for the layout's
outer-aligned block. Left-page values shown; right-page mirrors via R3.

| Code | Photo dims (mm) | yMm | Notes |
|---|---|---|---|
| l1 | 142×189 | 57 | + `captionDate` above photo; + `captionBody` above date (upward, max 400 chars) |
| l1a | 113×152 | 33.5 | + `captionDate` + `captionBody` in 82mm side column (max 800 chars) |
| l1b | 175×238 | 8 (top bleed) | x via `_outerAlignedX`; bleedTop=bleedBottom=bleedLeft=bleedRight=true |
| l1c | 175×196 | 23 | Canonical centered variant; caption-driven y deferred |
| l1d | 107×107 | unchanged | x via `_outerAlignedX`; dims unchanged; marked PDF-unconfirmed |
| l1e | 107×152 | unchanged | x via `_outerAlignedX`; + `captionDate` + `captionBody` by L1A analogy; marked PDF-unconfirmed |
| l2a | 86×110 | unchanged | x via `_outerAlignedX` (2 photos side-by-side, 16mm gutter) |
| l2b | **175×107** landscape ×2 | 29 (top photo) | Gap=3mm; bottom photo y=139; REWRITE from 115.5×86 portrait |
| l2c | per current dims ×2 | unchanged | x via `_outerAlignedX`; 2-photo count unchanged |
| l3a | 60.27×82 ×3 | 86 | x via `_outerAlignedX`; replaces coincidental centering |
| l4a | **86×86** square ×2×2 | 71 | Gap=3mm; REWRITE from 86×110; x via `_outerAlignedX` |
| l4b | 86×110 ×2 stacked | 23 (upper), 136 (lower) | Canonical non-caption-driven variant; x via `_outerAlignedX` |
| l6a | 86×110 ×3 (2+1) | unchanged | x via `_outerAlignedX` |
| l7 | **86×110** ×2 panes | per pane | 7.5mm photo-to-caption gap; date ~4mm; body grows down, max 350 chars; REWRITE from 142×105 |
| l8 | 86×110 ×2 + 175×115.5 | unchanged | x via `_outerAlignedX` |
| lhito | textBlockWidth **149** | unchanged | subtitle slot widthMm 149; dateHeightMm enlarged for 24pt leading |

Scenarios (representative; full fixture list in R6):

#### Scenario: l2b left-page top photo

- GIVEN `solver.solve(l2b, dotbookDefault(), isLeftPage: true)`
- WHEN inspecting result[0]
- THEN `widthMm==175, heightMm==107, xMm==8.0, yMm==29.0`

#### Scenario: l4a left-page grid top-left

- GIVEN `solver.solve(l4a, dotbookDefault(), isLeftPage: true)`
- WHEN inspecting result[0]
- THEN `widthMm==86, heightMm==86, xMm==8.0, yMm==71.0`

#### Scenario: l4b canonical stacked upper photo

- GIVEN `solver.solve(l4b, dotbookDefault(), isLeftPage: true)`
- WHEN inspecting result[0]
- THEN `widthMm==86, heightMm==110, xMm==8.0, yMm==23.0`

#### Scenario: l4b canonical stacked lower photo

- GIVEN `solver.solve(l4b, dotbookDefault(), isLeftPage: true)`
- WHEN inspecting result[1]
- THEN `yMm==136.0`

#### Scenario: l7 rewritten photo dims

- GIVEN `solver.solve(l7, dotbookDefault(), isLeftPage: true)`
- WHEN inspecting photo slots
- THEN each has `widthMm==86, heightMm==110`

#### Scenario: l1 emits captionDate and captionBody

- GIVEN `solver.solve(l1, dotbookDefault(), isLeftPage: true)`
- WHEN inspecting slot kinds
- THEN the list contains `DotsSlotKind.photo`, `DotsSlotKind.captionDate`, `DotsSlotKind.captionBody`

#### Scenario: lhito text-block width is 149

- GIVEN `solver.solve(lhito, dotbookDefault(), isLeftPage: true)`
- WHEN inspecting the captionTitle slot
- THEN `widthMm==149.0`

---

### Requirement: R5 — L_hito subtitle font-size override

`_captionFontSizeFor(DotsSlotKind.captionDate, DotsLayoutCode.lhito)` MUST
return `20.0` in BOTH `dots_renderer.dart` and `isolate_synthesis.dart`.
The comment at both sites MUST read: *"L_hito subtitle is P22 Mackinac
Book 20pt / 24pt leading."* Both copies MUST be updated in the same commit.

#### Scenario: renderer returns 20.0 for lhito captionDate

- GIVEN the renderer processing an `lhito` layout page
- WHEN `_captionFontSizeFor(captionDate, lhito)` is called
- THEN the result is `20.0`

#### Scenario: isolate sibling also returns 20.0

- GIVEN `isolate_synthesis.dart`
- WHEN `_captionFontSizeFor(captionDate, lhito)` is called
- THEN the result is `20.0`

---

### Requirement: R6 — Test fixture regression contract

`test/render/layout/dots_layout_solver_test.dart` MUST express the
corrected coordinates for 14 of 16 layouts (l3a and lhito position
coordinates are unchanged). For each corrected layout, the test file
MUST assert BOTH left-page and right-page x coordinates. Fixture
updates MUST land in the same commit as the corresponding solver change.
The suite MUST be GREEN after the change.

`test/render/layout/dots_layout_requirements_test.dart` MUST update its
`solver.solve(...)` call to pass `isLeftPage: true`.

#### Scenario: left-right x parity is asserted for l1

- GIVEN `dots_layout_solver_test.dart`
- WHEN the l1 test group runs
- THEN separate test cases assert `xMm==8.0` for `isLeftPage: true`
  and `xMm==53.0` for `isLeftPage: false`

#### Scenario: full test suite is green

- GIVEN the updated solver and updated fixtures
- WHEN `flutter test` is run
- THEN exit code is zero

---

### Requirement: R7 — `SPECS_interior.md` corrections

`docs/templates/SPECS_interior.md` MUST be updated:

| Item | Old value | New value |
|---|---|---|
| L2B dimensions | 115.5×86 mm portrait | 175×107 mm landscape |
| L4A dimensions | 86×110 mm | 86×86 mm square |
| L7 dimensions | 142×105 mm | 86×110 mm |
| Positioning model | `AUTO` (centered) | Outer-edge-aligned 8 mm from trim edge |
| L_hito subtitle | 9pt / date slot | 20pt P22 Mackinac Book, 24pt leading |

#### Scenario: SPECS_interior.md reflects corrected L2B

- GIVEN `docs/templates/SPECS_interior.md`
- WHEN the L2B section is read
- THEN it states 175×107 mm landscape and not 115.5×86 mm

---

## Out of Scope

The following MUST NOT be implemented in Task 3:

| Deferred item | Target |
|---|---|
| Caption-driven y variants on L1C (12/23/50 mm) and L4B | Tasks 4–7 renderer logic |
| Unnamed 70.5×86mm small-photo layout (PDF pp.13–18) | Future change |
| 6-photo arrangement on PDF p.81 | Future change |
| Per-category factory bodies | Tasks 4–7 |
| L1B per-parity bleed resolution in renderer | Renderer follow-up |
| L_hito QR-width adjustment at 500 chars | Renderer heuristic |

---

## Acceptance Test List

**R1 — outerMarginMm**
- `DotsPageGeometry — dotbookDefault outerMarginMm equals 8.0`
- `DotsPageGeometry — equality includes outerMarginMm`

**R2 — isLeftPage parameter**
- `DotsLayoutSolver — solve without isLeftPage is a compile error`
- `DotsLayoutSolver — renderer passes pageNumber.isOdd as isLeftPage`

**R3 — _outerAlignedX**
- `DotsLayoutSolver — l1 left-page xMm equals 8.0`
- `DotsLayoutSolver — l1 right-page xMm equals 53.0`

**R4 — per-layout contracts (14 layouts × left + right)**
- `DotsLayoutSolver — l2b left-page: photo[0] is 175×107 at y=29 x=8`
- `DotsLayoutSolver — l2b left-page: photo[1] is at y=139`
- `DotsLayoutSolver — l4a left-page: photo[0] is 86×86 at y=71 x=8`
- `DotsLayoutSolver — l4b left-page: photo[0] at y=23, photo[1] at y=136`
- `DotsLayoutSolver — l7 left-page: photos are 86×110 with 7.5mm gap`
- `DotsLayoutSolver — l1 emits captionDate and captionBody slots`
- `DotsLayoutSolver — l1a emits captionDate and captionBody in 82mm column`
- `DotsLayoutSolver — l1e emits captionDate and captionBody slots`
- `DotsLayoutSolver — lhito title and subtitle widthMm equals 149`
- *(right-page mirrors for each layout above)*

**R5 — font-size override**
- `DotsRenderer — _captionFontSizeFor(captionDate, lhito) equals 20.0`
- `IsolateSynthesis — _captionFontSizeFor(captionDate, lhito) equals 20.0`

**R6 — fixtures**
- `DotsLayoutSolver — full suite passes after fixture updates`

**R7 — docs**
- `SPECS_interior.md — L2B entry states 175×107 mm landscape`
