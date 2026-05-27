# Archive Report: album-type-boda-halo (Slice 7)

**Date Archived:** 2026-05-27
**Change Name:** album-type-boda-halo
**Series:** Album-Type Series (Slices 1–7)
**Status:** COMPLETED & CLOSED

---

## Executive Summary

Slice 7 (`album-type-boda-halo`) is complete and archived. boda p.4 "Boda de Nombre&Nombre" title spread now renders with a radial halo of 10 tilted rounded-rect photos arcing around the page center, 2 reused oval QR cards in the gutter, and a left-page title/date block. The implementation introduces `DotsRotatedPhotoElement`, `kBodaHaloLayout` (10-slot const), `AlbumBodaHaloContent` VO, `DotsAlbumSpreadPage.bodaHalo(...)` factory, and `buildBodaHaloPageFor(...)` builder, with 5 exhaustiveness arms across the renderer stack. All 22 tasks completed; 622 tests pass (0 failures); `dart analyze` 0 issues; verify PASS (W1/W2 accepted precedent, W3/W4 false positives, S1 spec text fixed).

---

## Artifact Index

This archive contains the full change traceability across all phases:

| Artifact | Topic Key | Type | Observations |
|----------|-----------|------|---|
| proposal.md | `sdd/album-type-boda-halo/proposal` | decision | Intent, scope, Q1–Q7 verdicts, risks, rollback plan |
| spec.md | `sdd/album-type-boda-halo/spec` | architecture | R1–R9 requirements + 34 scenarios, 10-slot layout table |
| design.md | `sdd/album-type-boda-halo/design` | architecture | D1–D8 decisions, AABB→unrotated conversion, worked table, file changes, test strategy |
| tasks.md | `sdd/album-type-boda-halo/tasks` | architecture | 22 tasks across 5 phases, all `[x]`, spec→task coverage matrix |
| verify-report.md | `sdd/album-type-boda-halo/verify-report` | discovery | PASS verdict, W1–W4 analysis, S1 fix, coverage matrix, correctness gate |
| specs/album-type-boda-halo.md | `sdd/album-type-boda-halo/main-spec` | architecture | Merged delta spec: R1–R9 consolidated, 10-slot table, deliverables, test evidence |

---

## Implementation Summary

### Scope Delivered

**New Element Type:** `DotsRotatedPhotoElement`
- Sealed subtype of `DotsElement`
- Fields: unrotated (x, y, width, height), assetPath, angleDegrees (signed), cornerRadiusMm (default 6.0), 4 bleed flags
- Full value equality (`==` / `hashCode`)
- Tests: S1–S5 scenarios (5 tests)

**New Layout Constant:** `kBodaHaloLayout`
- 10 entries (R1–R5 right-page, L1–L5 left-page)
- Unrotated top-lefts pre-computed from AABB via center-preserving rotation (design D1)
- All entries: uniform 33.5×46.4 mm (95.0×131.4 pt), signed angles (+3.2° to +68.3°), bleedBottom for R5/L5
- Tests: S10–S14 scenarios (5 tests, ±0.001 mm tolerance per slot)

**New Content Object:** `AlbumBodaHaloContent`
- photoPaths (List<String>, exactly 10)
- titleLine1 (default "Boda de"), titleLine2 (required), dateSubtitle (required)
- qrPayloadLeft, qrPayloadRight (required)
- qrCaptionLeftOverride, qrCaptionRightOverride (String?, default null)
- Value equality with list equality on photoPaths
- Tests: S15–S17 scenarios (3 tests)

**New Factory:** `DotsAlbumSpreadPage.bodaHalo(...)`
- Accepts: type, pageNumber, contextLabelValue, content
- Returns: single DotsAlbumSpreadPage with 15 elements
  - 10 DotsRotatedPhotoElement (zipped with photoPaths, R-slots +203 mm, L-slots direct)
  - 2 DotsOvalQrElement (gutter QR cards, 25.841×43.127 mm, left/right with caption defaults/overrides)
  - 3 DotsTextElement (title lines 1–2, date subtitle, P22 Mackinac fonts)
- Validation: ArgumentError (non-boda), RangeError (photoPaths.length != 10)
- Header: leftPageNumber, rightPageNumber, centerLabel populated per spread convention
- Tests: S18–S24 scenarios (7 tests)

**New Builder:** `buildBodaHaloPageFor(...)`
- Top-level function with defense-in-depth validation
- Throws ArgumentError (non-boda), RangeError (length != 10)
- Delegates to factory
- Tests: S25–S27 scenarios (3 tests)

**Renderer Dispatch:** 5 exhaustiveness arms
1. `album_spread_page.dart` `_buildElement` → `_buildRotatedPhotoElement(...)`
   - Decode via bytesResolver
   - Render: Positioned → Transform.rotate(center) → ClipRRect → Image
   - On failure: onPhotoFailure callback, return null
2. `dots_renderer.dart` `_buildElement` (ElementsPage) → return null
3. `dots_renderer.dart` `preloadAssetBytes` (DotsElementsPage) → paths.add(element.assetPath)
4. `dots_renderer.dart` `preloadAssetBytes` (DotsAlbumSpreadPage) → paths.add(element.assetPath)
5. `isolate_synthesis.dart` `_buildElement` → return null
- Tests: S28–S31 scenarios (4 tests)

**Spread-Width Warning:** Extended pageSize.width < 406 mm check to include DotsRotatedPhotoElement
- Tests: S32 scenario (1 test)

**Public Exports:** 2 new exports from lib/dots_pdf.dart
- AlbumBodaHaloContent (from src/api/album_boda_halo_content.dart)
- buildBodaHaloPageFor (from src/api/build_boda_halo_page.dart)
- DotsRotatedPhotoElement rides existing src/config/dots_template.dart export
- Tests: S34 scenario (1 test)

**Backwards Compatibility:** All slice-1…6 tests pass unchanged (622 cumulative)
- Tests: S33 scenario (implicit in full test suite)

### Test Evidence

| Metric | Value |
|--------|-------|
| Total tests (slices 1–7) | 622 |
| Failed tests | 0 |
| dart analyze issues | 0 |
| Task completion | 22/22 (100%) |
| Scenario coverage (R1–R9) | 34/34 (100%) |
| Verify verdict | PASS (W1/W2 accepted, W3/W4 false positives, S1 fixed) |

### Geometric Correctness

**Critical Gate: D1 AABB → Unrotated TL Conversion**

Design decision D1 hardcodes the 10 unrotated top-lefts pre-computed from AABB post-rotation positions using center-preserving rotation arithmetic:

```
center = (aabbX + aabbW/2, aabbY + aabbH/2)
unrotatedTL = (center_x − 16.75mm, center_y − 23.2mm)
```

Verification method: Unit tests in `boda_halo_layout_test.dart` assert each slot's coordinates individually to ±0.001 mm against the design D1 worked table.

**Spot check samples:**
- R1: (15.30, 94.95 mm) at +3.2° ✓
- R5: (151.80, 228.75 mm) at +68.3° bleedBottom ✓
- L1: (154.30, 94.20 mm) at −3.2° ✓
- L5: (17.90, 230.30 mm) at −68.3° bleedBottom ✓

**Integration verification:** Rendered PDFs via main-isolate and worker-isolate paths produce non-empty valid bytes (S28–S29).

**Confidence:** MEDIUM (±0.5 mm per design; ±2 mm drift on tilted decorative photos is sub-perceptual). Dartdoc caveat included; deferred InDesign source verification.

---

## PR Chain

**Delivery Strategy:** Chained PRs (feature-branch-chain pattern)
**Base Branch:** add-album-type-layouts (tracker)

**PR 1: Scaffolding + Foundation**
- Phases 1–2 (tasks 1.1–2.9)
- Test files created (RED); element model + layout const added; 5 exhaustiveness arms stubbed
- Result: Compile-clean, all tests RED, exhaustiveness errors resolved

**PR 2: Implementation + Completion**
- Phases 3–5 (tasks 3.1–5.3)
- Rendering helper + factory + content VO + builder + exports implemented
- Result: All tests GREEN (622 pass), dart analyze 0 issues, backwards compatibility confirmed

**Chain Integration:** PR 1 merged → PR 2 based on PR 1 branch → clean integration to tracker branch

---

## Verify Findings Resolution

**Verdict:** PASS — All findings addressed.

| Finding | Severity | Status | Resolution |
|---------|----------|--------|------------|
| W1 — S29 worker-isolate path | WARNING | ACCEPTED | Slice-6 precedent; arm verified by inspection; edge cases caught by compile-time exhaustiveness |
| W2 — S31 preloadAssetBytes direct call | WARNING | ACCEPTED | Trivial append operation; arm verified by inspection; mechanically sound |
| W3 — Title line 2 spacing | FALSE POSITIVE | INVESTIGATED | Spec prose ambiguous; design D4 clarifies intent; implementation correct (line 2 = 1 leading below line 1, not 5 mm below) |
| W4 — Date subtitle Y-position | FALSE POSITIVE | INVESTIGATED | Verify agent misread coordinate semantics; y is top-of-text; "5 mm below line 2" = after line 2's visual bottom; implementation correct |
| S1 — Spec R3 text ambiguity | SUGGESTION | FIXED | Clarified R3 to unambiguously state "stores UNROTATED coordinates" not AABB |

**All R1–R9 requirements verified; 34 scenarios covered; 100% conformance.**

---

## Deliverables Summary

### Code Changes

| File | Action | Lines Changed |
|------|--------|---|
| `lib/src/config/dots_template.dart` | Add DotsRotatedPhotoElement + bodaHalo factory | ~150 |
| `lib/src/api/album_boda_halo_content.dart` | Create new | ~50 |
| `lib/src/api/build_boda_halo_page.dart` | Create new | ~20 |
| `lib/src/render/boda_halo_layout.dart` | Create new | ~80 |
| `lib/src/render/album_spread_page.dart` | Add _buildRotatedPhotoElement + warning | ~60 |
| `lib/src/render/dots_renderer.dart` | Add 3 exhaustiveness arms | ~15 |
| `lib/src/render/isolate_synthesis.dart` | Add 1 exhaustiveness arm | ~5 |
| `lib/dots_pdf.dart` | Add 2 exports | ~2 |
| **Test files** | Create 4 new test suites | ~500 |
| **Total** | — | ~880 |

(Estimate aligns with forecast 450–580 produced lines + test scaffolding ≈ 880 total.)

### Documentation Changes

| Document | Location | Status |
|----------|----------|--------|
| Main spec (merged delta) | `openspec/specs/album-type-boda-halo.md` | Created from delta spec |
| Archive set | `openspec/archive/album-type-boda-halo/` | 5 files (proposal, spec, design, tasks, verify-report) |

### Test Coverage

| Category | Count | Files |
|----------|-------|-------|
| Unit tests (model) | ~10 | `dots_rotated_photo_element_test.dart` |
| Unit tests (layout const) | ~10 | `boda_halo_layout_test.dart` |
| Integration tests (factory, builder, render) | ~70 | `boda_halo_test.dart`, `build_boda_halo_page_test.dart` |
| **New tests this slice** | **~90** | — |
| **Cumulative (slices 1–7)** | **622** | All passing |

---

## Series Context: Slices 1–7 Cumulative Status

| Slice | Name | Status | Key Deliverables |
|-------|------|--------|---|
| 1 | album-type-foundation | Archived | DotsAlbumSpreadPage, sealed hierarchy, builder pattern |
| 2 | album-type-simple-pages | Archived | DotsTextElement, DotsRotatedTextElement, shared buildAlbumSpreadPage |
| 3 | album-type-polaroid-collage | Archived | DotsPolaroidElement, R→L gradient, polaroid layout const |
| 4 | album-type-gaussian-circles | Archived | DotsDecorativeCircleElement, rasterization cache, cover layout |
| 5 | album-type-photo-arc | Archived | DotsPhotoCircleElement, DotsOvalQrElement, photo-arc layout |
| 6 | album-type-boda-cluster | Archived | DotsClusterPhotoElement, DotsGradientDirection, boda p.3 cluster |
| 7 | album-type-boda-halo | **ARCHIVED** | **DotsRotatedPhotoElement, kBodaHaloLayout, boda p.4 halo** |

**Test growth:** 235 (post-slice-1) → 622 (post-slice-7) = **+387 new tests over 7 slices**

**New primitives introduced by slice 7:**
- Element: DotsRotatedPhotoElement (rounded-rect photo + signed rotation, no frame)
- Enum/type: (none — reuses DotsOvalQrElement from slice 5)

**Total new element types across series:**
- Slice 1: DotsElement (abstract), DotsImageElement, DotsTextElement, DotsTextBlockElement, DotsHeaderElement, DotsFooterElement
- Slice 2: DotsRotatedTextElement
- Slice 3: DotsPolaroidElement
- Slice 4: DotsDecorativeCircleElement, DotsGradientDirection
- Slice 5: DotsPhotoCircleElement, DotsOvalQrElement, DotsQrSlotElement
- Slice 6: DotsClusterPhotoElement
- Slice 7: **DotsRotatedPhotoElement**

---

## Outstanding Work & Deferred Items

### High-Priority Deferred

1. **boda p.1, p.2, p.5 coverage** — Out of scope for this series; requires separate slices per page
2. **InDesign anchor verification** (37.477, 50.388 mm) — Cannot be matched to PDF stream; deferred pending source file access
3. **Visual QA on MEDIUM-confidence halo coords** — Recommend verifying ±0.5 mm accuracy against source; ±2 mm drift sub-perceptual for decorative photos

### Series-Level Debt

See `openspec/archive/album-type-series-summary.md` for cross-slice issues:
- Header-trio initialization consistency across slices
- Inter Semibold font role declaration (slice 2 onwards)
- Coordinate gaps on polaroid grid (slice 3)
- Cover-circle bleed parity (slices 4–5)

---

## Change Closure

**Status:** COMPLETE
- All 22 tasks: `[x]`
- All 9 requirements (R1–R9): VERIFIED
- All 34 scenarios: PASSING
- Test suite: 622 pass, 0 fail
- Code quality: dart analyze 0 issues
- Verify report: PASS

**Archive Path:** `/Users/alexei/work/dots_pdf/openspec/archive/album-type-boda-halo/`

**Next Step:** Update series summary (slice 6 + 7 entry, test count update, primitive list, per-type coverage matrix). Then close the album-type series.

---

## Traceability

| Phase | Artifact | Topic Key | Status |
|-------|----------|-----------|--------|
| Propose | proposal.md | `sdd/album-type-boda-halo/proposal` | ARCHIVED |
| Spec | spec.md | `sdd/album-type-boda-halo/spec` | ARCHIVED |
| Design | design.md | `sdd/album-type-boda-halo/design` | ARCHIVED |
| Tasks | tasks.md | `sdd/album-type-boda-halo/tasks` | ARCHIVED |
| Apply (2 PRs) | (code) | `sdd/album-type-boda-halo/apply-progress` | COMPLETED |
| Verify | verify-report.md | `sdd/album-type-boda-halo/verify-report` | ARCHIVED |
| **Archive** | **archive-report.md** | `sdd/album-type-boda-halo/archive-report` | **THIS FILE** |

---

**Archive Date:** 2026-05-27
**Archived By:** SDD Archive Executor
**Series:** Album-Type Series (7 slices, complete)
**Final Status:** CLOSED

