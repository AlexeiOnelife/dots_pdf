# Tasks: album-type-boda-halo (Slice 7)

**Status:** COMPLETED
**Change:** album-type-boda-halo — boda p.4 radial photo halo title spread
**Delivery strategy:** Chained PRs (feature-branch-chain)
**Chain strategy:** feature-branch-chain
**Base branch:** `add-album-type-layouts` (tracker)
**Date Completed:** 2026-05-27

---

## Review Workload Forecast

| Field | Value |
|-------|-------|
| Estimated changed lines | 450–580 |
| 400-line budget risk | High |
| Chained PRs recommended | Yes |
| Suggested split | PR 1 (T1+T2) → PR 2 (T3+T4+T5) |
| Delivery strategy | ask-on-risk |
| Chain strategy | feature-branch-chain |

Decision needed before apply: Yes
Chained PRs recommended: Yes
Chain strategy: feature-branch-chain
400-line budget risk: High

### Suggested Work Units

| Unit | Goal | Likely PR | Notes |
|------|------|-----------|-------|
| 1 | Test scaffolding (RED) + element model + layout const + 5 exhaustiveness arms (stubs) | PR 1 | Base: `add-album-type-layouts` tracker branch; compile-clean with `UnimplementedError` stub in arm 1 |
| 2 | Rendering helper + factory + content VO + builder + exports + GREEN | PR 2 | Base: PR 1 branch; all tests pass green |

---

## Phase 1: Test Scaffolding — RED (PR 1)

Sequential within this phase. All tests fail at RED; they drive the implementation in phase 2.

- [x] 1.1 Create `test/config/dots_rotated_photo_element_test.dart`: failing tests for constructor (all fields), value equality (`==`/`hashCode`), inequality when `angleDegrees` differs, `cornerRadiusMm` default `6.0`, all 4 bleed flags default `false` (R1 scenarios S1–S5).
- [x] 1.2 Create `test/render/boda_halo_layout_test.dart`: failing tests asserting `kBodaHaloLayoutForTest` has exactly 10 entries; each slot's unrotated `x`/`y` within `±0.001 mm` of the D1 worked table; right slots carry positive angles matching `+3.2`, `+20.7`, `+37.2`, `+55.2`, `+68.3`; left slots carry mirror negatives; R5 and L5 have `bleedBottom == true`; all other slots have `bleedBottom == false` (R3 scenarios S10–S14).
- [x] 1.3 Create `test/render/boda_halo_test.dart`: failing tests for main-isolate render produces non-empty PDF (S28), worker-isolate parity (S29), `ArgumentError` on non-boda type (S21 re-applied via render path), `RangeError` on `photoPaths.length != 10` (S22), decode-failure skips element + fires `onPhotoFailure` (S9), spread-width warning emitted when `pageSize.width < 406 mm` (S32).
- [x] 1.4 Create `test/api/build_boda_halo_page_test.dart`: failing tests for `buildBodaHaloPageFor` returns `DotsAlbumSpreadPage` (S25); rejects 4 non-boda types with `ArgumentError` (S26); rejects `photoPaths.length == 9` with `RangeError` (S27); `AlbumBodaHaloContent` constructs with defaults — `titleLine1 == 'Boda de'`, overrides null (S15); list equality on `photoPaths` (S16); inequality when `photoPaths` differ (S17); factory produces 15 elements with correct type breakdown (S18); each `assetPath` matches `photoPaths[i]` (S19); header trio populated correctly (S20); `RangeError` for 11 paths (S23); QR caption overrides win over defaults (S24); `dart analyze` reports zero non-exhaustive errors after all arms added (S30); rotated photo `assetPath` appears in `preloadAssetBytes` result (S31); new symbols importable from `lib/dots_pdf.dart` (S34).

---

## Phase 2: Foundation — Element + Layout + Exhaustiveness Arms (PR 1)

Sequential within this phase. PRE-REQUISITE: Phase 1 complete (test files exist). Parallelism note: tasks 2.3 (layout file) and 2.1–2.2 (element model) can be authored in parallel if desired, but the exhaustiveness arms (2.4–2.9) MUST follow after both are in place.

- [x] 2.1 Add `DotsRotatedPhotoElement` sealed class to `lib/src/config/dots_template.dart`: fields `x`/`y` (from super), `assetPath`, `width`, `height`, `angleDegrees`, `cornerRadiusMm` (default `6.0`), 4 bleed flags (default `false`); full `==`/`hashCode` over all fields; single named constructor (D2, R1).
- [x] 2.2 Add `DotsAlbumSpreadPage.bodaHalo(...)` named factory signature to `lib/src/config/dots_template.dart` — body deferred to task 4.2; add constructor declaration now so the sealed hierarchy is complete and exhaustiveness arms can compile (D4, R5). Body may throw `UnimplementedError` at this stage.
- [x] 2.3 Create `lib/src/render/boda_halo_layout.dart`: file-private `_BodaHaloAnchor` class with `xMm`, `yMm`, `angleDegrees`, `bleedBottom`; class constants `widthMm = 33.5` / `heightMm = 46.4`; `kBodaHaloLayout` list of 10 entries using pre-computed unrotated coords from D1 worked table; `@visibleForTesting` record projection `kBodaHaloLayoutForTest` exposing the table for test assertion; dartdoc caveat noting MEDIUM confidence and deferred InDesign source verification (D3, R3).
- [x] 2.4 Add `DotsRotatedPhotoElement` arm to `album_spread_page.dart` `_buildElement` switch — stub body: `throw UnimplementedError('DotsRotatedPhotoElement render not yet implemented')` (D6 site 1, R7 exhaustiveness arm 1).
- [x] 2.5 Add `DotsRotatedPhotoElement` arm to `dots_renderer.dart` `_buildElement` (ElementsPage path, ~line 423) — body: `return null` (D6 site 2, R7 exhaustiveness arm 2).
- [x] 2.6 Add `DotsRotatedPhotoElement` arm to `dots_renderer.dart` `preloadAssetBytes` for `DotsElementsPage` (~line 57) — body: `paths.add(element.assetPath)` (D6 site 3, R7 exhaustiveness arm 3).
- [x] 2.7 Add `DotsRotatedPhotoElement` arm to `dots_renderer.dart` `preloadAssetBytes` for `DotsAlbumSpreadPage` (~line 89) — body: `paths.add(element.assetPath)` (D6 site 4, R7 exhaustiveness arm 4).
- [x] 2.8 Add `DotsRotatedPhotoElement` arm to `isolate_synthesis.dart` `_buildElement` (~line 313) — body: `return null` (D6 site 5, R7 exhaustiveness arm 5).
- [x] 2.9 Verify `dart analyze` reports zero non-exhaustive pattern-match errors after all 5 arms are in place (R7 S30). PR 1 is compile-clean at this checkpoint.

---

## Phase 3: Rendering — `_buildRotatedPhotoElement` + Spread-Width Warning (PR 2)

PRE-REQUISITE: PR 1 merged. Tasks 3.1 and 3.2 are independent and can be authored in parallel.

- [x] 3.1 Implement `_buildRotatedPhotoElement(element, template, bytesResolver, onPhotoFailure)` in `lib/src/render/album_spread_page.dart`: decode photo via `bytesResolver`; on failure call `onPhotoFailure(assetPath)` and return `null`; wrap in `pw.Positioned(left: element.x, top: element.y)` → `pw.Transform.rotate(angle: element.angleDegrees * pi / 180, alignment: pw.Alignment.center)` → `pw.ClipRRect(horizontalRadius: element.cornerRadiusMm * _kMmToPt, verticalRadius: element.cornerRadiusMm * _kMmToPt)` → `pw.Image(width: element.width, height: element.height, fit: pw.BoxFit.cover)`; replace `UnimplementedError` stub from task 2.4 with this call (D2, R2 scenarios S6–S9).
- [x] 3.2 Extend the spread-width `pageSize.width < 406 mm` logger warning in `buildAlbumSpreadPage` to include `DotsRotatedPhotoElement` in the `.any(...)` guard — mirrors slice 5/6 pattern (R8 scenario S32).

---

## Phase 4: Factory + Content VO + Builder (PR 2)

PRE-REQUISITE: Phase 3 tasks complete. Tasks 4.1 and 4.3 can be done in parallel with 4.2 since the content VO and builder don't depend on each other's internals; 4.2 (factory body) depends on 4.1 (content VO) being defined.

- [x] 4.1 Create `lib/src/api/album_boda_halo_content.dart`: `AlbumBodaHaloContent` immutable value object with `photoPaths` (`List<String>`), `titleLine1` (default `'Boda de'`), `titleLine2` (required), `dateSubtitle` (required), `qrPayloadLeft` (required), `qrPayloadRight` (required), `qrCaptionLeftOverride` (`String?`, default `null`), `qrCaptionRightOverride` (`String?`, default `null`); `==`/`hashCode` with list equality on `photoPaths` (D5, R4 scenarios S15–S17).
- [x] 4.2 Complete `DotsAlbumSpreadPage.bodaHalo(...)` factory body in `lib/src/config/dots_template.dart`: throw `ArgumentError` for `type != DotsAlbumType.boda`; throw `RangeError` if `content.photoPaths.length != 10` before constructing any element; zip `content.photoPaths` against `kBodaHaloLayout` indices 0–9; R-slots (0–4): `x = anchor.xMm * _kMmToPt + 203 * _kMmToPt`; L-slots (5–9): `x = anchor.xMm * _kMmToPt`; produce 10 `DotsRotatedPhotoElement` + 2 `DotsOvalQrElement` (left x = 176 mm − ovalWidth/2, right x = 230 mm − ovalWidth/2, y = 190.87 mm, 25.841 × 43.127 mm, caption overrides from content win over defaults) + 3 `DotsTextElement` (title line 1 P22 Mackinac Medium 23 pt at (19 mm, 43 mm); title line 2 same style 5 mm below; date subtitle P22 Mackinac Book 9 pt / 10.8 pt 5 mm below line 2); set `header.leftPageNumber = '$pageNumber'`, `header.rightPageNumber = '${pageNumber + 1}'`, `header.centerLabel = contextLabelValue` (D4, R5 scenarios S18–S24).
- [x] 4.3 Create `lib/src/api/build_boda_halo_page.dart`: top-level `buildBodaHaloPageFor(DotsAlbumType type, AlbumBodaHaloContent content, {required int pageNumber, required String contextLabelValue})` with defense-in-depth `ArgumentError` for non-boda type and `RangeError` for `photoPaths.length != 10`; delegates to `DotsAlbumSpreadPage.bodaHalo(...)` (D5, R6 scenarios S25–S27).

---

## Phase 5: Exports + Verification (PR 2)

Sequential; MUST follow phases 3 and 4.

- [x] 5.1 Add two export lines to `lib/dots_pdf.dart`: `export 'src/api/album_boda_halo_content.dart'` and `export 'src/api/build_boda_halo_page.dart'`; confirm `DotsRotatedPhotoElement` rides the existing `export 'src/config/dots_template.dart'` barrel without an additional line (D7, R9 scenario S34).
- [x] 5.2 Run full test suite; confirm all prior slice 1–6 tests pass unchanged (R9 scenario S33).
- [x] 5.3 Run `dart analyze`; confirm zero warnings/errors.

---

## Spec → Task Coverage

| Req | Scenarios | Tasks |
|-----|-----------|-------|
| R1 — DotsRotatedPhotoElement model | S1–S5 | 1.1, 2.1 |
| R2 — Rotated photo rendering | S6–S9 | 1.3, 3.1 |
| R3 — kBodaHaloLayout 10-slot const | S10–S14 | 1.2, 2.3 |
| R4 — AlbumBodaHaloContent value object | S15–S17 | 1.4, 4.1 |
| R5 — DotsAlbumSpreadPage.bodaHalo factory | S18–S24 | 1.4, 2.2, 4.2 |
| R6 — buildBodaHaloPageFor builder | S25–S27 | 1.4, 4.3 |
| R7 — Renderer dispatch (5 exhaustiveness arms) | S28–S31 | 1.3, 2.4–2.9 |
| R8 — Spread-width pageSize contract | S32 | 1.3, 3.2 |
| R9 — Backwards compatibility + public exports | S33–S34 | 5.1–5.3 |

---

## Out of Scope

- boda p.1, p.2, p.5 — separate slices.
- Anchor verification against InDesign/Illustrator source (deferred follow-up per Q3).
- Non-boda album types (covered by existing `photoArc` factory from slice 5).
- Pre-rasterization cache for halo photos (10 distinct images; no cache needed unlike slice 6 cluster pattern).
- Runtime AABB → unrotated TL conversion (hardcoded per D1; no runtime arithmetic).
