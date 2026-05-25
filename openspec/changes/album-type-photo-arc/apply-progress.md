# Apply Progress: album-type-photo-arc

**Change**: album-type-photo-arc
**Mode**: Standard
**Artifact store**: openspec
**Batch**: PR 1 continuation (batch 2)
**Status**: PR 1 complete — all T1.x and T2.x tasks done

---

## Completed Tasks

### Phase 1: Test Scaffolding (PR 1)

- [x] T1.1 `test/config/dots_photo_circle_element_test.dart` — GREEN: 4 tests pass (construction, equality, inequality on diameter, inequality on assetPath, bleed defaults)
- [x] T1.2 `test/config/dots_oval_qr_element_test.dart` — GREEN: 4 tests pass (construction, equality, inequality on caption, inequality on qrPayload, sealed hierarchy)
- [x] T1.3 `test/render/photo_arc_layout_test.dart` — GREEN: 12 tests pass (length==10, all diameter==44.45, each of 10 x/y coordinates matches spec table)
- [x] T1.4 `test/render/photo_arc_test.dart` — RED placeholders (15 fail() stubs for factory + render tasks in PR 2)
- [x] T1.5 `test/api/build_photo_arc_page_test.dart` — RED placeholders (11 fail() stubs for builder tasks in PR 2)

### Phase 2: Foundation — Element Types + Layout + Exhaustiveness Arms (PR 1)

- [x] T2.1 `DotsPhotoCircleElement` — in `dots_template.dart`, all 8 fields, const constructor, ==/ hashCode (done by batch 1)
- [x] T2.2 `DotsOvalQrElement` — in `dots_template.dart`, all 6 fields, const constructor, ==/hashCode (done by batch 1)
- [x] T2.3 `lib/src/render/photo_arc_layout.dart` — `_PhotoArcAnchor` (file-private), `kPhotoArcLayout` (10 entries), `kPhotoArcLayoutForTest` accessor (done by batch 1)
- [x] T2.4 Site 1 — `album_spread_page.dart` `_buildElement`: both new arms throw `UnimplementedError('... part of slice 5 PR 2')` (per orchestrator instruction; design says stubs OK for PR 1)
- [x] T2.5 Site 2 — `dots_renderer.dart` `_buildElement` (DotsElementsPage path): both new arms `return null;` with delegation comment
- [x] T2.6 Site 3 — `dots_renderer.dart` `preloadAssetBytes` inner switch (DotsElementsPage): `DotsPhotoCircleElement` → `paths.add(element.assetPath);`, `DotsOvalQrElement` → `break;`
- [x] T2.7 Site 4 — `dots_renderer.dart` `preloadAssetBytes` inner switch (DotsAlbumSpreadPage): `DotsPhotoCircleElement` → `paths.add(element.assetPath);`, `DotsOvalQrElement` → `break;`
- [x] T2.8 Site 5 — `isolate_synthesis.dart` `_buildElement`: both new arms `return null;` with delegation comment
- [x] T2.9 `flutter analyze` → 0 issues confirmed. Model tests (T1.1, T1.2) GREEN. Layout test (T1.3) GREEN.

**Additional**: Fixed `prefer_const_declarations` warning at line 1340 of `dots_template.dart` (`final` → `const` on `subtitleYMm`).

---

## Files Changed

| File | Action | What Was Done |
|------|--------|---------------|
| `lib/src/config/dots_template.dart` | Modified | Added `DotsPhotoCircleElement` + `DotsOvalQrElement` (batch 1); fixed `prefer_const_declarations` on `subtitleYMm` (batch 2) |
| `lib/src/render/photo_arc_layout.dart` | Created | `_PhotoArcAnchor` + `kPhotoArcLayout` (10 entries) + `kPhotoArcLayoutForTest` accessor (batch 1) |
| `lib/src/api/album_photo_arc_content.dart` | Created | `AlbumPhotoArcContent` value object — T4.1 scope, left in place, NOT checked off (batch 1) |
| `lib/src/render/album_spread_page.dart` | Modified | Added 2 exhaustiveness arms (throw UnimplementedError stubs) at `_buildElement` site 1 (batch 2) |
| `lib/src/render/dots_renderer.dart` | Modified | Added 6 exhaustiveness arms across 3 sites: `_buildElement`, `preloadAssetBytes` DotsElementsPage switch, `preloadAssetBytes` DotsAlbumSpreadPage switch (batch 2) |
| `lib/src/render/isolate_synthesis.dart` | Modified | Added 2 exhaustiveness arms at `_buildElement` site 5 (batch 2) |
| `test/config/dots_photo_circle_element_test.dart` | Created | GREEN: construction, equality, hashCode, bleed defaults (batch 2) |
| `test/config/dots_oval_qr_element_test.dart` | Created | GREEN: construction, equality, hashCode (batch 2) |
| `test/render/photo_arc_layout_test.dart` | Created | GREEN: 10 entries, uniform diameter 44.45 mm, all 10 coordinate pairs (batch 2) |
| `test/render/photo_arc_test.dart` | Created | RED: 15 fail() placeholders for factory + render (PR 2) (batch 2) |
| `test/api/build_photo_arc_page_test.dart` | Created | RED: 11 fail() placeholders for builder (PR 2) (batch 2) |

---

## Test Results

- `flutter analyze` → 0 issues
- `flutter test` → 420 passed, 26 failed
  - 26 failures = 15 (photo_arc_test.dart fail() stubs) + 11 (build_photo_arc_page_test.dart fail() stubs)
  - Pre-existing baseline was 409 passed, 28 failed (same 2 cover_page cache-interference failures + 26 exhaustiveness compile errors that are now gone; net +11 GREEN from new model/layout tests)
  - All pre-existing passing tests continue to pass

---

## Deviations from Design

- Site 1 exhaustiveness arms (`album_spread_page.dart`) use `throw UnimplementedError(...)` instead of calling stub helper functions. The orchestrator brief explicitly says "throw UnimplementedError('...part of slice 5 PR 2')" for PR 1. Design says stubs returning `pw.SizedBox.shrink()` — the UnimplementedError approach is slightly more defensive (fails loudly if someone accidentally invokes a photo-arc page through a non-photo-arc path) and keeps PR 1 honest about what is not implemented. PR 2 replaces these with real implementations.

- `album_photo_arc_content.dart` was created by batch 1 (T4.1 scope). It is left in place as a harmless early stub with no public caller. T4.1 is NOT checked off.

---

## Remaining Tasks

- [ ] T3.1 through T3.5 — Rendering (album_spread_page.dart): 6 file-private renderer constants, `_buildPhotoCircleElement`, `_buildOvalQrElement`, replace PR 1 stubs, width-warning check
- [ ] T4.1 — `AlbumPhotoArcContent` (file exists; needs PR 2 polish if any)
- [ ] T4.2 — `DotsAlbumSpreadPage.photoArc(...)` factory in dots_template.dart
- [ ] T4.3 — `buildPhotoArcPageFor` top-level builder + boda ArgumentError
- [ ] T5.1 — Imports wiring in dots_template.dart
- [ ] T5.2 — Add 2 new exports to lib/dots_pdf.dart
- [ ] T5.3 — `dart analyze` final verification
- [ ] T5.4 — Full test suite — all 5 new test files GREEN

---

## Workload / PR Boundary

- Mode: chained PR slice (feature-branch-chain)
- Current work unit: PR 1 — test scaffolding + element types + layout + exhaustiveness arms
- PR 1 is complete. PR 2 starts from this branch and implements T3.x + T4.x + T5.x.
- Next step: `sdd-verify` for PR 1, then `sdd-apply` for PR 2.
