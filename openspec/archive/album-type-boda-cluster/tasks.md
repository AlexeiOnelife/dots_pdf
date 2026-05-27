# Tasks: album-type-boda-cluster (Slice 6)

**Status:** Completed
**Verdict:** All 22 task boxes checked; all 544 tests passing; 0 analyze issues

## Review Workload Forecast

| Field | Value |
|-------|-------|
| Estimated changed lines | 580–700 |
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
| 1 | Test scaffolding + enum + element + layout + 5 exhaustiveness arms (stubs) | PR 1 | Base: `add-album-type-layouts` tracker branch; compile-clean with UnimplementedError stubs |
| 2 | Rendering pipeline + cache + factory + builder + exports + GREEN | PR 2 | Base: PR 1 branch; all tests pass green |

---

## Phase 1: Test Scaffolding — RED (PR 1)

- [x] 1.1 Create `test/config/dots_cluster_photo_element_test.dart`: failing tests for constructor, all-field equality, hashCode, inequality on `assetPath`, bleed defaults, `gaussianFadeMm` default (R1 scenarios SC1–SC5).
- [x] 1.2 Create `test/config/dots_gradient_direction_test.dart`: failing tests for 4 enum values (`topToBottom`, `bottomToTop`, `leftToRight`, `rightToLeft`), exhaustiveness name strings (R1/D2).
- [x] 1.3 Create `test/render/boda_cluster_layout_test.dart`: failing tests asserting 7 entries in `kBodaClusterLayoutForTest`, each slot's mm values within ±0.001, gradient params, bleedTop only on slot 1 (R6 scenarios).
- [x] 1.4 Create `test/render/boda_cluster_render_test.dart`: failing tests for cache hit (rasterizer called once), cache miss on differing assetPath, reset-hook clears state, spread-width warning at <406 mm, `ArgumentError` on non-boda, `RangeError` on photoPaths.length != 7, isolate-parity render within 20% byte tolerance (R2, R3, R8, R9 scenarios).
- [x] 1.5 Create `test/api/build_boda_cluster_page_test.dart`: failing tests for `buildBodaClusterPageFor` returns `DotsAlbumSpreadPage`, rejects 4 non-boda types, rejects photoPaths.length != 7, default title/italic, `photoPaths` propagated, header trio, 10-element count (R4, R5, R7 scenarios).

## Phase 2: Foundation — Enum + Element + Layout + Exhaustiveness Arms (PR 1)

- [x] 2.1 Add `DotsGradientDirection` enum (4 values) to `lib/src/config/dots_template.dart` near existing public enums (D2).
- [x] 2.2 Add `DotsClusterPhotoElement` sealed class to `lib/src/config/dots_template.dart`: all fields per D1, `==`/`hashCode` covering all fields including `assetPath`, `gaussianFadeMm` default `1.764`, 4 bleed flags default `false` (R1).
- [x] 2.3 Create `lib/src/render/boda_cluster_layout.dart`: file-private `_BodaClusterAnchor`, `kBodaClusterLayout` list of 7 entries with exact mm values from extracted_coordinates.md §1, `@visibleForTesting` `BodaClusterAnchorForTest` typedef + `kBodaClusterLayoutForTest` projection (D5, R6).
- [x] 2.4 Add `DotsClusterPhotoElement` arm to `album_spread_page.dart` `_buildElement` switch — stub body: `throw UnimplementedError('DotsClusterPhotoElement not yet implemented')` (R8 exhaustiveness site 1).
- [x] 2.5 Add `DotsClusterPhotoElement` arm to `dots_renderer.dart` `_buildElement` (ElementsPage path) — body: `return null` (R8 exhaustiveness site 2).
- [x] 2.6 Add `DotsClusterPhotoElement` arm to `dots_renderer.dart` `preloadAssetBytes` for `DotsElementsPage` — body: `paths.add(element.assetPath)` (R8 exhaustiveness site 3).
- [x] 2.7 Add `DotsClusterPhotoElement` arm to `dots_renderer.dart` `preloadAssetBytes` for `DotsAlbumSpreadPage` — body: `paths.add(element.assetPath)` (R8 exhaustiveness site 4).
- [x] 2.8 Add `DotsClusterPhotoElement` arm to `isolate_synthesis.dart` `_buildElement` — body: `return null` (R8 exhaustiveness site 5).
- [x] 2.9 Verify `dart analyze` reports zero non-exhaustive pattern-match errors after all 5 arms are in place (R8 scenario: sealed switch exhaustive).

## Phase 3: Rendering Pipeline + Cache (PR 2)

- [x] 3.1 Add `_ClusterCacheKey` typedef and `_clusterPhotoCache` map to `lib/src/render/album_spread_page.dart` (separate from `_circleCache`); add `resetClusterPhotoCacheForTest()` and `clusterPhotoCacheSizeForTest()` hooks (D6, R3).
- [x] 3.2 Implement `_rasterizeClusterPhoto(...)` in `album_spread_page.dart`: decode via `bytesResolver`, resize at 300 DPI, per-pixel opacity gradient along `DotsGradientDirection`, Gaussian edge blur of `gaussianFadeMm` band, encode PNG. Short-circuit gradient pass when `opacityGradientStart == opacityGradientEnd` (D7, R2).
- [x] 3.3 Implement `_buildClusterPhotoElement(...)` in `album_spread_page.dart`: cache-key compose → cache lookup → `_rasterizeClusterPhoto` on miss → `pw.MemoryImage` in `pw.Positioned`; on failure call `onPhotoFailure` and return null. Replace UnimplementedError stub from 2.4 (D7, R2).
- [x] 3.4 Add spread-width runtime logger warning in `_buildClusterPhotoElement` when `template.pageSize.width < 406 mm` (R9, mirrors slice-5 pattern).

## Phase 4: Factory + Builder + Content (PR 2)

- [x] 4.1 Create `lib/src/api/album_boda_cluster_content.dart`: `AlbumBodaClusterContent` with `photoPaths`, `title` (default `'Antes de empezar'`), `titleItalicLine` (default `'el viaje'`), `body`; list equality on `photoPaths`; `==`/`hashCode` (D8, R4).
- [x] 4.2 Add `DotsAlbumSpreadPage.bodaCluster(...)` named factory to `lib/src/config/dots_template.dart`: `ArgumentError` for non-boda type, `RangeError` for `photoPaths.length != 7`; zip `photoPaths` against `kBodaClusterLayout`; produce 7 `DotsClusterPhotoElement` + 2 `DotsTextElement` (P22 Mackinac medium/medium-italic, 23pt/27.6pt) + 1 `DotsTextBlockElement` (Inter Book 9pt, 95 mm); set header trio + footer `'Dots. Memories'` (D3, D5, R5, R6).
- [x] 4.3 Create `lib/src/api/build_boda_cluster_page.dart`: `buildBodaClusterPageFor(type, content, {pageNumber, contextLabelValue})` with defense-in-depth `ArgumentError` + `RangeError`; delegates to `DotsAlbumSpreadPage.bodaCluster(...)` (D8, R7).

## Phase 5: Exports + Verification (PR 2)

- [x] 5.1 Add two export lines to `lib/dots_pdf.dart`: `export 'src/api/album_boda_cluster_content.dart'` and `export 'src/api/build_boda_cluster_page.dart'` (D9, R10).
- [x] 5.2 Confirm `DotsGradientDirection` and `DotsClusterPhotoElement` ride existing barrel exports without additional lines (D9).
- [x] 5.3 Run full test suite; confirm all prior slice 1–5 tests still pass (R10 backwards-compatibility scenario).
- [x] 5.4 Run `dart analyze`; confirm zero warnings/errors.
