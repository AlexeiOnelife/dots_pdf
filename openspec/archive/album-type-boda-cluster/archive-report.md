# Archive Report: album-type-boda-cluster (Slice 6)

**Date Archived:** 2026-05-26
**Status:** COMPLETED
**Change:** album-type-boda-cluster (Slice 6 of boda body-page series)

---

## Executive Summary

Boda p.3 "Antes de empezar el viaje" decorative cluster spread is complete and archived. The slice introduces `DotsClusterPhotoElement` with per-photo opacity gradients + Gaussian edge fades, a library-locked 7-slot cluster layout, and caller-supplied photo content. All 22 tasks completed, 544 tests passing, 0 analyze issues. All 4 verify findings (W1, W2, S1, S2) addressed in polish pass.

---

## Implementation Summary

### What Was Delivered

**Slice 6** completes boda p.3 (the "Antes de empezar el viaje" spread), adding one major visual primitive:

**`DotsClusterPhotoElement`** — A sealed `DotsElement` subtype carrying:
- Per-photo placement (x, y in pt)
- Caller-supplied asset path (String)
- Geometry (width, height in pt)
- Per-photo opacity gradient (start value 0–1, end value 0–1, direction: topToBottom / bottomToTop / leftToRight / rightToLeft)
- Gaussian edge fade (default 1.764 mm, matching slice 4's decorative circles)
- Bleed flags (top/bottom/left/right, for trim-edge handling)
- Full value equality (`==`, `hashCode`) over all 13 fields including `assetPath`

**7-Slot Canonical Layout** (`kBodaClusterLayout`):
- Slot 1: 94.6 × -7.8 mm, 27.5 × 33.9 mm, gradient bottomToTop 100%→10%, bleeds above trim
- Slot 2: 86.3 × 59.6 mm, 5.0 × 5.8 mm, full opacity
- Slot 3: 90.0 × 31.4 mm, 20.3 × 24.7 mm, full opacity
- Slot 4: 87.4 × 71.3 mm, 12.8 × 15.2 mm, full opacity
- Slot 5: 103.1 × 88.9 mm, 13.7 × 16.2 mm, gradient topToBottom 100%→30%
- Slot 6: 90.4 × 103.3 mm, 9.0 × 10.6 mm, gradient topToBottom 100%→30%
- Slot 7: 103.1 × 116.6 mm, 7.8 × 9.2 mm, gradient topToBottom 100%→0%

**Caller-Supplied Content** (`AlbumBodaClusterContent`):
- `photoPaths`: List<String>, exactly 7 paths (enforced; throws RangeError if length differs)
- `title`: String, default "Antes de empezar"
- `titleItalicLine`: String, default "el viaje"
- `body`: String, rendered as Inter Book 9pt, 95 mm wide

**Factory & Builder**:
- `DotsAlbumSpreadPage.bodaCluster(...)` — named factory that validates type (throws ArgumentError for non-boda), validates photoPaths.length (throws RangeError), zips photos against layout, produces 10 elements: 7 cluster + 2 title (medium + medium-italic, P22 Mackinac 23pt) + 1 body block.
- `buildBodaClusterPageFor(type, content, pageNumber, contextLabelValue)` — top-level builder with defense-in-depth error checking, mirrors slice 5's photo-arc builder for API symmetry.

**New Public Enum** (`DotsGradientDirection`):
- `topToBottom`
- `bottomToTop`
- `leftToRight`
- `rightToLeft`
- Separate from slice 3's `DotsPolaroidElement.gradientRtl: bool` (which is a primitive-specific bool, not a direction enum).

**Rendering Pipeline**:
- Pre-rasterization cache (separate from slice 4's circle cache) keyed by (assetPath, width, height, gradientStart, gradientEnd, direction, gaussianFadeMm).
- Per-photo rendering: decode → resize @ 300 DPI → apply per-pixel opacity gradient → apply Gaussian blur → encode PNG → position in spread.
- Failure handling: silent skip + onPhotoFailure callback per element.

**Exhaustiveness Coverage** (5 sites):
1. `album_spread_page.dart` `_buildElement` → `_buildClusterPhotoElement` (rendering)
2. `dots_renderer.dart` `_buildElement` (ElementsPage) → `return null`
3. `dots_renderer.dart` `preloadAssetBytes` (ElementsPage) → `paths.add(element.assetPath)`
4. `dots_renderer.dart` `preloadAssetBytes` (AlbumSpreadPage) → `paths.add(element.assetPath)`
5. `isolate_synthesis.dart` `_buildElement` → `return null`

**Public Exports** (added to `lib/dots_pdf.dart`):
- `DotsClusterPhotoElement` (via existing barrel export from `dots_template.dart`)
- `DotsGradientDirection` (via existing barrel export from `dots_template.dart`)
- `AlbumBodaClusterContent` (new export)
- `buildBodaClusterPageFor` (new export)

---

## Test Metrics

| Category | Result |
|---|---|
| Unit Tests | 544 passed, 0 failed |
| Static Analysis | 0 issues (dart analyze) |
| Backwards Compatibility | All slice 1–5 tests pass unchanged |
| Task Completion | 22/22 boxes checked |

### Test Coverage by Requirement

- **R1 (Model)**: Constructor, all-field equality, inequality on assetPath, bleed/fade defaults.
- **R2 (Rendering)**: Decode → gradient → blur pipeline, position/size correctness, failure handling.
- **R3 (Cache)**: Hit/miss on key, reset hook isolation, size introspection.
- **R4 (Content)**: Default values, list equality on photoPaths, value equality.
- **R5 (Factory)**: 10-element count, element type distribution, assetPath propagation, header/footer population.
- **R6 (Layout)**: 7-slot table verification within ±0.001 mm, gradient parameters, bleedTop only on slot 1.
- **R7 (Builder)**: Type rejection (4 non-boda types), photoPaths length rejection.
- **R8 (Dispatch)**: All 5 exhaustiveness arms confirmed, sealed switch exhaustive per dart analyze.
- **R9 (PageSize)**: Warning fires when template.pageSize.width < 406 mm.
- **R10 (Exports)**: All 4 symbols accessible from `dots_pdf.dart`, prior test suite unaffected.

---

## Verification Findings (All Addressed)

### W1: Spread-width warning fired 7× per page

**Issue**: Warning emitted once per cluster element instead of once per page.
**Fix**: Moved check to page-level `elements.any(...)` guard in `buildAlbumSpreadPage`, removed per-element check from `_buildClusterPhotoElement`.
**Status**: Fixed in polish pass.

### W2: design.md D1 rationale had wrong values

**Issue**: Documentation stated incorrect gradient sentinels; code was correct.
**Fix**: Updated design.md D1 to match implementation: slot 1 = (1.0, 0.1, bottomToTop); slots 5/6 = (1.0, 0.3, topToBottom); slot 7 = (1.0, 0.0, topToBottom).
**Status**: Fixed in polish pass.

### S1: Warning message clarity

**Issue**: Message didn't specify which elements were at risk.
**Fix**: Improved message text to clarify condition.
**Status**: Fixed in polish pass.

### S2: Intermediate mm round-trip in factory

**Issue**: Factory did unnecessary pt→mm→pt conversion.
**Fix**: Refactored to work in pt throughout.
**Status**: Fixed in polish pass.

---

## Locked Design Decisions

| Decision | Rationale | Impact |
|---|---|---|
| **D1: Sealed element subtype** | Mirrors slices 3/4/5 (one subtype per primitive); keeps switch hygiene clean; assetPath on element matches slice 3/5 patterns. | +5 exhaustiveness sites, but expected cost for the series. |
| **D2: DotsGradientDirection enum (4 values)** | Separate from slice 3's bool to avoid breaking API; future-proofs for 4-direction expansion; slice 6 only needs topToBottom/bottomToTop today. | Public API surface; chosen conservatively. |
| **D3: Title at 23pt** | Inline spec callout takes precedence over table hypothesis; visual QA is deferred; future change possible without model touch. | Locked pending visual review; D3 documents the conflict. |
| **D4: Slot 1 top bleed** | `pw.Stack` does not clip, so negative y paints naturally into bleed/past-trim space; matches slice 4 circle approach; PDF viewers crop to MediaBox. | Slot 1 paints 4.8 mm past trim edge; acceptable per design. |
| **D5: Separate boda_cluster_layout.dart** | Mirrors slice 4/5 pattern; keeps render module focused; coordinates are spread-relative; factory adds 203 mm to convert from right-page source. | File organization; coordinates have single translation point. |
| **D6: Separate _clusterPhotoCache** | Different growth model than slice 4's circle cache (per-photo vs per-diameter); type-safe keys; orthogonal reset hooks. | Two focused caches; no unification benefit. |
| **D7: Pre-rasterization rendering** | Supports both opacity gradient AND Gaussian edge fade (PDF-level gradient overlay cannot do both); slice 4 pattern already proven; 300 DPI acceptable per slice 4. | Heavier than PDF-native but pixel-accurate and proven. |
| **D8: Immutable AlbumBodaClusterContent + builder** | Matches slice 5 `buildPhotoArcPageFor` pattern; symmetric API; single public builder entry point. | API consistency; list equality on photoPaths required for value semantics. |

---

## Outstanding Follow-ups (Out of Scope)

These were explicitly deferred from slice 6 and remain for future work:

1. **boda p.4 radial halo** — Slice 7 (separate proposal). 10 halo slots, MEDIUM confidence on rotation anchors. Depends on this slice.
2. **boda p.1 (intro single page), p.2 (instructions spread), p.5 (closing page)** — Separate future work; requires coordinate extraction.
3. **Title size 27pt vs 23pt** — Visual QA only; locked at 23pt per inline callout. If visual review favors 27pt, builder can be updated without model touch (D3).
4. **Slot 1 bleed edge clipping** — Accepted design choice per D4. If viewer feedback indicates clipping is unwanted, explicit clip logic can be added to `_buildClusterPhotoElement` without model change.
5. **Inter Semibold visual fidelity at small sizes** — Carried forward from earlier slices; affects all body text, not boda-specific.

---

## PR Delivery (2-PR Chained Split)

### PR 1: Test Scaffolding + Foundation
- **Base**: `add-album-type-layouts` tracker branch
- **Changes**: Test files (5 new), enum + element + layout (with 5 exhaustiveness stubs)
- **State**: Compile-clean, tests RED, all prior tests still pass
- **Size**: ~400 lines

### PR 2: Rendering + Builder + Exports
- **Base**: PR 1 branch
- **Changes**: Rendering pipeline (album_spread_page.dart), factory (dots_template.dart), content + builder (new files), exports (dots_pdf.dart), exhaustiveness implementations
- **State**: All tests GREEN, 0 analyze issues
- **Size**: ~280 lines

**Chain strategy**: feature-branch-chain (PR 1 → PR 2 → main via tracker branch)

---

## File Artifacts

### Created (Archive)
- `/Users/alexei/work/dots_pdf/openspec/archive/album-type-boda-cluster/proposal.md`
- `/Users/alexei/work/dots_pdf/openspec/archive/album-type-boda-cluster/spec.md`
- `/Users/alexei/work/dots_pdf/openspec/archive/album-type-boda-cluster/design.md`
- `/Users/alexei/work/dots_pdf/openspec/archive/album-type-boda-cluster/tasks.md`
- `/Users/alexei/work/dots_pdf/openspec/archive/album-type-boda-cluster/verify-report.md`
- `/Users/alexei/work/dots_pdf/openspec/archive/album-type-boda-cluster/archive-report.md` (this file)

### Created (Main Spec)
- `/Users/alexei/work/dots_pdf/openspec/specs/album-type-boda-cluster.md` (normative spec for future reference/slices)

### Source Folder (to be cleaned up by orchestrator)
- `/Users/alexei/work/dots_pdf/openspec/changes/album-type-boda-cluster/` (contains proposal.md, spec.md, design.md, tasks.md, verify-report.md)

---

## Requirements Traceability

**All R1–R10 from delta spec are satisfied:**

- **R1** ✓ DotsClusterPhotoElement with 13 fields, value equality, all defaults
- **R2** ✓ Rendering pipeline: decode, gradient, blur, position
- **R3** ✓ Pre-rasterization cache with reset hook
- **R4** ✓ AlbumBodaClusterContent with list equality on photoPaths
- **R5** ✓ bodaCluster factory: type/length validation, 10-element composition
- **R6** ✓ kBodaClusterLayout table verified ±0.001 mm, all gradient params
- **R7** ✓ buildBodaClusterPageFor builder with defense-in-depth validation
- **R8** ✓ All 5 exhaustiveness arms, sealed switch confirmed exhaustive
- **R9** ✓ Spread-width runtime warning for <406 mm pages
- **R10** ✓ Backwards compatibility (all prior tests pass), 4 public exports

**All scenarios in spec are covered by test cases.**

---

## Change Closure

This slice is **COMPLETE** and **ARCHIVED**.

- Source folder: `/Users/alexei/work/dots_pdf/openspec/changes/album-type-boda-cluster/` → mark for deletion (orchestrator will remove)
- Archive folder: `/Users/alexei/work/dots_pdf/openspec/archive/album-type-boda-cluster/` → contains full artifact trail
- Main spec: `/Users/alexei/work/dots_pdf/openspec/specs/album-type-boda-cluster.md` → live reference for future slices
- Implementation: merged to `add-album-type-layouts` tracker branch via 2-PR chain (stacked-to-main strategy)

Next slice (boda p.4 radial halo) can begin independently; this slice is closed and will not be reopened.

---

## Observation IDs (for traceability)

Archive report artifacts reference:
- Proposal (delta): `openspec/changes/album-type-boda-cluster/proposal.md`
- Spec (delta): `openspec/changes/album-type-boda-cluster/spec.md`
- Design (delta): `openspec/changes/album-type-boda-cluster/design.md`
- Tasks (delta): `openspec/changes/album-type-boda-cluster/tasks.md`
- Verify Report (delta): `openspec/changes/album-type-boda-cluster/verify-report.md`

Archived copies:
- Proposal (archive): `openspec/archive/album-type-boda-cluster/proposal.md`
- Spec (archive): `openspec/archive/album-type-boda-cluster/spec.md`
- Design (archive): `openspec/archive/album-type-boda-cluster/design.md`
- Tasks (archive): `openspec/archive/album-type-boda-cluster/tasks.md`
- Verify Report (archive): `openspec/archive/album-type-boda-cluster/verify-report.md`

Main spec (for future reference):
- `openspec/specs/album-type-boda-cluster.md`
